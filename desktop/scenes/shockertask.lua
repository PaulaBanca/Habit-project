local composer=require "composer"
local scene=composer.newScene()

local transition=transition
local display=display
local Runtime=Runtime
local tunemanager=require "tunemanager"
local trialorder=require "util.trialorder"
local findfile=require "util.findfile"
local shocker=require "shocker.shockermessager"
local stimuli=require "stimuli"
local logger=require "util.logger"
local _=require "util.moses"
local math=math
local timer=timer
local type=type
local print=print
local table=table
local os=os

setfenv(1,scene)

local debugShocker=function(side)
  local c
  if side=="right" then
    c=display.newCircle(display.contentCenterX+200,display.contentCenterY,80)
    c:setFillColor(1, 0, 0) 
  else
    c=display.newCircle(display.contentCenterX-200,display.contentCenterY,80)
    c:setFillColor(0, 0, 1)
  end
  transition.to(c, {alpha=0,onComplete=function(obj) obj:removeSelf() end})
end

local shockerCalls={}
shockerCalls["preferred"]=function() debugShocker("left") end
shockerCalls["discarded"]=function() debugShocker("left") end
shockerCalls[3]=function() debugShocker("right") end

local trials=trialorder.generate({{value="discarded",n=40},{value="preferred",n=40},{value=3,n=40}},12)
function start(config)
  local count=0
  local logField=logger.create(config.taskLogFile,{"date","sequence","sequences completed","mistakes","shock"})
        
  function run()
    local tune=table.remove(trials)
    if not tune then
      local nextScene,nextParams=config.nextScene,config.nextParams
      if nextScene=="scenes.shockertask" then
        nextParams={scene=nextScene,params=nextParams}
        nextScene="scenes.reload"
      end
      return composer.gotoScene(nextScene,{params=nextParams})
    end
    count=count+1
    local opts={}
    opts.logInputFilename=config.inputLogFile
    opts.onComplete=function(shock,sequencesCompleted,mistakes)
      if shock and config.enableShocks then
        shockerCalls[tune]()
      end
      logField("sequence",tune)
      logField("sequences completed",sequencesCompleted)
      logField("mistakes",mistakes)
      logField("date",os.date())
      logField("shock",shock and config.enableShocks)
      
      local itTime=config.itTime
      composer.gotoScene("scenes.iti",{params={time=itTime}})
      local t
      if not config.trialLimit or count<config.trialLimit then
        t=timer.performWithDelay(itTime,run)
      else
        t=timer.performWithDelay(itTime,function()
          composer.gotoScene("scenes.break",{params={scene=config.nextScene,params=config.nextParams}})
        end)
      end
      -- local keyListener
      -- keyListener=function(event) 
      --   if event.keyName=="space" and event.phase=="down" then
      --     Runtime:removeEventListener("key",keyListener)
      --     timer.cancel(t)
      --     run()
      --   end 
      -- end
      -- Runtime:addEventListener("key",keyListener)
    end
    opts.tune=tunemanager.getID(tune)
    opts.time=config.taskTime
    composer.gotoScene("scenes.playtune",{params=opts})
  end
  run()
end

local pageSetup={
  {text="Please wait... initialising equipment",
    noKeys=true,
    onShow=function()
      local path=findfile.find("arduino-serial-server")
      assert(path,"arduino-serial-server not found. Please make sure it is in your Home directory.")
      shocker.startServer(path,function(left,right)
        shockerCalls["preferred"]=left
        shockerCalls["discarded"]=left
        shockerCalls[3]=right
        composer.gotoScene("scenes.reload",{params={scene="scenes.shockertask",params={page=2}}})
      end)
    end},

  {text="When you see a symbol play it once without mistakes. If you make a mistake or keep playing you will get shocked.",
    onKeyPress=function() start({taskTime=5000,itTime=8000,nextScene="scenes.shockertask",nextParams={page=3},trialLimit=60,enableShocks=true,inputLogFile="shocker-inputs-1",taskLogFile="shocker-summary-task1-prebreak"}) end
  },
  {text="The next set",
    onKeyPress=function() start({taskTime=5000,itTime=8000,nextScene="scenes.shockertask",nextParams={page=4},trialLimit=nil,enableShocks=true,inputLogFile="shocker-inputs-1",taskLogFile="shocker-summary-task1-postbreak"}) end
  },
  {text="Now when you see a symbol keep playing it as much as possible in order not to be shocked."},
  {text="But there are new rules: only do the first 5 steps for this symbol, then start again. Do not play the last part.",img=function()
    return stimuli.getStimulus(tunemanager.getID("preferred",5))
    end},
  {text="For this symbol only do the first 3 steps. Then follow it up with any 3 presses of your choice.\n\nJust make sure they are different from what you would normally do.",img=function()
    return stimuli.getStimulus(tunemanager.getID("discarded",3))
    end},
  { 
    text="Now lets start!",
    onShow=function() trials=trialorder.generate({{value=tunemanager.getID("discarded",3),n=20},{value=tunemanager.getID("preferred",5),n=20},{value=3,n=20}},12) end,
    onKeyPress=function() start({taskTime=20000,itTime=8000,nextScene="scenes.thankyou",nextParams=nil,trialLimit=nil,enableShocks=false,inputLogFile="shocker-inputs-2",taskLogFile="shocker-summary-task2"}) end
  }
}

local nextScene
function scene:show(event)
  local page=event.params and event.params.page or 1
  local setup=pageSetup[page]
  if event.phase=="did" then
    if nextScene then
      Runtime:removeEventListener("key", nextScene)
      nextScene=nil
    end
    scene.keyTimer=not setup.noKeys and timer.performWithDelay(500, function()
      nextScene=function(event)
        if event.phase=="up" and event.keyName~="=" then
          if nextScene then
            Runtime:removeEventListener("key", nextScene)
            nextScene=nil
            if not setup.onKeyPress then
              composer.gotoScene("scenes.shockertask",{params={page=page+1}})
            else
              setup.onKeyPress()
            end
          end
        end
      end
      Runtime:addEventListener("key", nextScene)
    end)
    return
  end
  local img
  if setup.img then
    if type(setup.img)=="string" then
      img=display.newImage(self.view,setup.img)
    else
      img=setup.img()
      self.view:insert(img)
    end
    img.x=display.contentCenterX
  end
  local text=display.newText({
    parent=self.view,
    text=setup.text,
    x=display.contentCenterX,
    y=display.contentCenterY,
    width=display.actualContentWidth*3/4,
    align="center",
    fontSize=48})
  text:setFillColor(0)

  if img then
    local h=text.height+img.height+20
    img.anchorY=0
    img.y=display.contentCenterY-h/2
    text.anchorY=1
    text.y=display.contentCenterY+h/2
  end

  local any=display.newText({
    parent=self.view,
    text="Press any key",
    x=display.contentCenterX,
    y=display.actualContentHeight-20,
    align="center",
    fontSize=40})
  any.anchorY=1
  any:setFillColor(0)

  if setup.onShow then
    setup.onShow()
  end
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    for i=self.view.numChildren,1,-1 do
      self.view[i]:removeSelf()
    end
    if self.keyTimer then
      timer.cancel(self.keyTimer)
      self.keyTimer=nil
    end
    if nextScene then
      Runtime:removeEventListener("key", nextScene)
      nextScene=nil
    end
  end
end

scene:addEventListener("hide")

return scene