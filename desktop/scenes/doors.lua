local composer=require "composer"
local scene=composer.newScene()

local server=require "server"
local events=require "events"
local servertest=require "servertest"
local tunedetector=require "tunedetector"
local serpent=require "serpent"
local tunes=require "tunes"
local tunemanager=require "tunemanager"
local stimuli=require "stimuli"
local winnings=require "winnings"
local keyeventslisteners=require "util.keyeventslisteners"
local vischedule=require "util.vischedule"
local jsonreader=require "util.jsonreader"
local logger=require "util.logger"
local _=require "util.moses"
local transition=transition
local display=display
local system=system
local table=table
local pairs=pairs
local math=math
local print=print
local os=os

setfenv(1,scene)


function nextRound()

  local left=tunemanager.getImg(setup.tunes[1])
  left.anchorX=1
  left.x=display.contentCenterX-10
  left.y=display.contentCenterY
  left.tune=tunemanager.getID(setup.tunes[1])
  local right=tunemanager.getImg(setup.tunes[2])
  right.anchorX=0
  right.x=display.contentCenterX+10
  right.y=display.contentCenterY
  right.tune=tunemanager.getID(setup.tunes[2])
  scene.view:insert(left)
  scene.view:insert(right)

  if setup.rewards then
    left.reward=setup.rewards[1]
    right.reward=setup.rewards[2]
  end
  return left,right
end

function scene:show(event)
  if event.phase=="did" then
    return
  end
  
  if not schedule then
    vischedule.setup(#schedule[1].tunes,30000,1000)
    vischedule.start()
  end

  local left,right=nextRound()
  if not left then
    winnings.add(event.params.total)
    composer.gotoScene("scenes.doorstotal",{params={winnings=event.params.total,nextScene=event.params.nextScene,nextParams=event.params.nextParams}})
    return
  end

  local logField=logger.create("doorsselections",{"date","sequence selected","round","input time","mistakes","left choice","right choice"})

  local steps=0

  local presses=0
  local start=system.getTimer()
  local function tuneCompleted(tune)
    local matched,notMatched
    if tune==left.tune or left.tune<0 and right.tune~=tune then
      matched=left
      notMatched=right
    else
      matched=right
      notMatched=left
    end

    logField("date",os.date())
    logField("sequence selected",tune)
    logField("round",round)
    logField("input time",system.getTimer()-start)
    logField("mistakes",mistakes)
    logField("left choice",left.tune)
    logField("right choice",right.tune)
 
    transition.to(notMatched,{alpha=0,onComplete=function(obj) obj:removeSelf() end})
    transition.to(matched,{anchorX=0.5,x=display.contentCenterX,alpha=0,xScale=2,yScale=2,onComplete=function(obj)
      obj:removeSelf()
      composer.gotoScene("scenes.doorresult",{params={reward=matched.reward,track=matched.tune,side=matched==left and 1 or 2,nextScene=event.params.nextScene,nextParams=event.params.nextParams}})
    end})
  end

  local function noWildCard()
    return left.tune>0 and right.tune>0
  end

  local function numberOfSteps()
    if left.tune==-3 or right.tune==-3 then 
      return 3
    end 
    return 6
  end

  local completeChain=0
  local onPlay,onRelease=keyeventslisteners.create("doors",function(tune)
    if not left then
      return
    end
    if noWildCard() and tune~=left.tune and tune~=right.tune then
      madeMistake()
    else
      tuneCompleted(tune)
    end
    left,right=nil,nil
  end,function()
    if not left then
      return
    end
    
   end ,function(event)
    if not left then 
      return
    end
    if event.phase=="released" and event.allReleased then
      if not noWildCard() then
        if event.complete then
          completeChain=completeChain+1
          if completeChain==numberOfSteps() then
            steps=-1
            completeChain=1
          end
        end
        steps=steps+1
        if steps==numberOfSteps() then
          tuneCompleted(left.tune<right.tune and left.tune or right.tune)
        end
      end
    end
  end,nil,not noWildCard())

  events.addEventListener("key played",onPlay)
  events.addEventListener("key released",onRelease)
  self.onRelease=onRelease
  self.onPlay=onPlay
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    events.removeEventListener("key played",self.onPlay)
    events.removeEventListener("key released",self.onRelease)
  end
end

scene:addEventListener("hide")

return scene