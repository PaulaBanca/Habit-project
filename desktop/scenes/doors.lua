local composer=require "composer"
local scene=composer.newScene()

local server=require "server"
local events=require "events"
local servertest=require "servertest"
local tunedetector=require "tunedetector"
local serpent=require "serpent"
local tunes=require "tunes"
local stimuli=require "stimuli"
local transition=transition
local display=display
local table=table
local pairs=pairs
local print=print
local next=next
local NUM_KEYS=NUM_KEYS

setfenv(1,scene)

local round=0
local schedule={
  {tunes={1,2}},
  {tunes={2,1}},
  {tunes={1,2}},
  {tunes={1,2}},
  {tunes={2,2}},
  {tunes={1,2}},
  {tunes={2,2}}
}

local tns=tunes.getTunes()
local stim={}
for i=1,#tns do
  stim[i]=tunes.getStimulus(tns[i])
end

function nextRound()
  round=round+1
  local setup=schedule[round]
  if not setup then
    return
  end

  local left=stimuli.getStimulus(stim[setup.tunes[1]])
  left.anchorX=1
  left.x=display.contentCenterX-10
  left.y=display.contentCenterY
  left.tune=setup.tunes[1]
  local right=stimuli.getStimulus(stim[setup.tunes[2]])
  right.anchorX=0
  right.x=display.contentCenterX+10
  right.y=display.contentCenterY
  right.tune=setup.tunes[2]
  scene.view:insert(left)
  scene.view:insert(right)
  return left,right
end

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local circles={}
  for i=1, NUM_KEYS do
    circles[i]=display.newCircle(scene.view,display.contentWidth/2*i/NUM_KEYS+display.contentWidth/8+20,display.contentCenterY,20)
    circles[i]:setFillColor(0)
    circles[i].alpha=0.2
  end

  local left,right=nextRound()

  local matches=0
  local keysDown={}
  events.addEventListener("key played",function(event) 
    if keysDown[event.note] then
      return
    end
    
    keysDown[event.note]=true
    circles[event.note].alpha=1

    local tune=tunedetector.matchAgainstTunes(keysDown)
    if tune then
      local matched
      local notMatched
      if tune==left.tune then
        matched=left
        notMatched=right
      elseif tune==right.tune then
        matched=right
        notMatched=left
      end
      transition.to(matched, {anchorX=0.5,x=display.contentCenterX,xScale=1.2,yScale=1.2,onComplete=function() 
        left:removeSelf()
        right:removeSelf()
        composer.gotoScene("scenes.score",{params={winnings=10,track=matched.tune}})
      end})
      transition.to(notMatched, {alpha=0})
    end
  end)

  events.addEventListener("key released",function(event)
    keysDown[event.note]=false
    circles[event.note].alpha=0.2
  end)
end

scene:addEventListener("show")

return scene