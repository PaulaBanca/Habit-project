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
local usertimes=require "util.usertimes"
local _=require "util.moses"
local timer=timer
local assert=assert
local type=type
local table=table
local os=os
local math=math
local serpent=require "serpent"

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
shockerCalls[tunemanager.getID("preferred")]=function() debugShocker("left") end
shockerCalls[tunemanager.getID("discarded")]=function() debugShocker("right") end
shockerCalls[tunemanager.getID("preferred",5)]=function() debugShocker("left") end
shockerCalls[tunemanager.getID("discarded",5)]=function() debugShocker("right") end
shockerCalls[4]=function() end

for i=1, 200 do
  usertimes.addTime(tunemanager.getID("preferred"),math.random(2000)+1000)
  usertimes.addTime(tunemanager.getID("discarded"),math.random(2000)+1000)
end

local trials={}
function start(config)
  local count=0
  local logField=logger.create(config.taskLogFile,{"date","sequence","sequences completed","mistakes","shock"})
  config.trialLimit=3
  local nextScene,nextParams=config.nextScene,config.nextParams
  local run
  run=function()
    local tune=table.remove(trials)
    if not tune then
      return composer.gotoScene(nextScene,{params=nextParams})
    end
    count=count+1
    local opts={}
    opts.logInputFilename=config.inputLogFile
    opts.onComplete=function(shock,sequencesCompleted,mistakes)
      if shock and config.enableShocks or config.forceShock then
        shockerCalls[tunemanager.getID(tune)]()
      end
      logField("sequence",tune)
      logField("sequences completed",sequencesCompleted)
      logField("mistakes",mistakes)
      logField("date",os.date())
      logField("shock",shock and config.enableShocks)

      local itTime=config.itTime
      if not itTime then
        return run()
      end
      itTime=itTime()
      composer.gotoScene("scenes.iti",{params={time=itTime}})
      if not config.trialLimit or count<config.trialLimit then
        timer.performWithDelay(itTime,run)
      else
        timer.performWithDelay(10,function() composer.gotoScene(nextScene,{params=nextParams}) end)
      end
    end
    opts.tune=tunemanager.getID(tune)
    opts.time=config.getTaskTime()
    composer.gotoScene("scenes.playtune",{params=opts})
  end
  run()
end

local pageSetup={
  {text="In the next task, your goal is to avoid getting shocks on your wrists\n\nThe symbol will tell you which sequence to play.\n\nTo avoid being shocked, you have to play the sequence once, without making mistakes and before the time runs out",
  },
  {text="These are the symbols you will see",img=function()
    local group=display.newGroup()
    local images={tunemanager.getID("preferred"),tunemanager.getID("discarded"),4}
    local width=0
    for i=1,#images do
      local img=stimuli.getStimulus(images[i])
      group:insert(img)
      img.anchorX=i/2-0.5
      width=width+img.contentWidth
    end
    group[1].x=-width/2
    group[3].x=width/2
    return group
  end},
  {text="For these symbol you will get a shock on your LEFT wrist if you make mistakes or if you are not fast enough.",img=function()
    return stimuli.getStimulus(tunemanager.getID("preferred"))
  end},
  {text="For this symbol you will get a shock on your RIGHT wrist if you make mistakes or if you are not fast enough.",img=function()
    return stimuli.getStimulus(tunemanager.getID("discarded"))
  end},
  {text="You will never be shocked when you see this symbol. You do not need play anything",img=function()
    return stimuli.getStimulus(4)
  end},
  {
    text="Please wait... initialising equipment",
    noKeys=true,
    onShow=function()
      local path=findfile.find("arduino-serial-server")
      assert(path,"arduino-serial-server not found. Please make sure it is in your Home directory.")
      -- shocker.startServer(path,function(left,right)
      --   shockerCalls[tunemanager.getID("preferred")]=left
      --   shockerCalls[tunemanager.getID("discarded")]=right
      --   shockerCalls[tunemanager.getID("preferred",5)]=left
      --   shockerCalls[tunemanager.getID("discarded",5)]=right
      --   shockerCalls[4]=function() end
      timer.performWithDelay(500,function()
        composer.gotoScene("scenes.shockertask",{params={page=7}})
         end)
      -- end)
    end},
  {text="Practice the corresponding sequence a few times.\n\nPlay the sequence once each time you see it.",img=function()
    return stimuli.getStimulus(tunemanager.getID("preferred"))
  end,
  onKeyPress=function()
    local tune=tunemanager.getID("preferred")
    local average=usertimes.getAverage(tune)
    local sd=usertimes.getStandardDeviation(tune)
    trials={tune,tune,tune}
    start({itTime=function() return 2000 end,getTaskTime=function()
      return average+math.random(sd*2)
    end,nextScene="scenes.shockertask",nextParams={page=8},enableShocks=true,inputLogFile="shocker-inputs-practice-preferred",taskLogFile="shocker-summary-practice-preferred"})
  end
  },
  {text="Practice the corresponding sequence a few times",img=function()
    return stimuli.getStimulus(tunemanager.getID("discarded"))
  end,
  onKeyPress=function()
    local tune=tunemanager.getID("discarded")
    local average=usertimes.getAverage(tune)
    local sd=usertimes.getStandardDeviation(tune)
    trials={tune,tune,tune}
    start({itTime=function() return 2000 end,getTaskTime=function()
      return average+math.random(sd*2)
    end,nextScene="scenes.shockertask",nextParams={page=9},enableShocks=true,inputLogFile="shocker-inputs-practice-discarded",taskLogFile="shocker-summary-practice-discarded"})
  end
  },
  {text="Let’s do the task now!\n\nPress a button to continue.",
    onKeyPress=function()
      trials=trialorder.generate({
        {value="discarded",n=5},
        {value="preferred",n=5},
        {value=4,n=5}},5)
      local maxAverage=math.max(usertimes.getAverage(tunemanager.getID("discarded")),usertimes.getAverage(tunemanager.getID("preferred")))

      local sd=math.max(usertimes.getStandardDeviation(tunemanager.getID("discarded")),usertimes.getStandardDeviation(tunemanager.getID("preferred")))

      start({getTaskTime=function() return maxAverage+math.random(4*sd)-2*sd  end,itTime=function() return 8000+math.random(2000) end,nextScene="scenes.shockertask",nextParams={page=10},enableShocks=true,inputLogFile="shocker-inputs-over-training-1",taskLogFile="shocker-summary-over-training-1"})
    end
 },
 {text="When the symbol looks like this, you must only play the first 5 moves of the sequence. Do NOT press the last move!\n\nLet's practice it now",img=function()
    return stimuli.getStimulus(tunemanager.getID("preferred",5))
    end,
    onKeyPress=function()
      local tune=tunemanager.getID("preferred")
      local average=usertimes.getAverage(tune)
      local sd=usertimes.getStandardDeviation(tune)
      tune=tunemanager.getID("preferred",5)
      trials={tune,tune,tune}
      start({getTaskTime=function()
        return average+math.random(sd)*2
      end,itTime=function() return 2000 end,nextScene="scenes.shockertask",nextParams={page=11},enableShocks=true,inputLogFile="shocker-inputs-practice-preferred5",taskLogFile="shocker-summary-practice-preferred5"})
    end
  },
  {text="Let’s do the task now!\n\nPress a button to continue.",
    onKeyPress=function()
      trials=trialorder.generate({{value="discarded",n=10},{value=tunemanager.getID("preferred",5),n=10},{value=4,n=10}},6)
      local maxAverage=math.max(usertimes.getAverage(tunemanager.getID("discarded")),usertimes.getAverage(tunemanager.getID("preferred")))

      local sd=math.max(usertimes.getStandardDeviation(tunemanager.getID("discarded")),usertimes.getStandardDeviation(tunemanager.getID("preferred")))

      start({getTaskTime=function() return maxAverage+math.random(4*sd)-2*sd  end,itTime=function() return 8000+math.random(2000) end,nextScene="scenes.shockertask",nextParams={page=12},enableShocks=true,inputLogFile="shocker-inputs-breaking-habit-1",taskLogFile="shocker-summary-breaking-habit-1"})
    end
  },
  {text="Now, let’s start again with the old symbols. Your goal remains to avoid getting shocks on your wrists.\n\nThe symbol will tell you which sequence to play.\n\nTo avoid being shocked, you have to play the sequence once, without making mistakes and before the time runs out."},
  {text="These are the symbols you will see",img=function()
    local group=display.newGroup()
    local images={tunemanager.getID("preferred"),tunemanager.getID("discarded"),4}
    local width=0
    for i=1,#images do
      local img=stimuli.getStimulus(images[i])
      group:insert(img)
      img.anchorX=i/2-0.5
      width=width+img.contentWidth
    end
    group[1].x=-width/2
    group[3].x=width/2
    return group
  end},
  {text="Let’s do the task now!\n\nPress a button to continue.",
    onKeyPress=function()
      trials=trialorder.generate({{value="discarded",n=30},{value="preferred",n=30},{value=4,n=30}},15)
      local maxAverage=math.max(usertimes.getAverage(tunemanager.getID("discarded")),usertimes.getAverage(tunemanager.getID("preferred")))

      local sd=math.max(usertimes.getStandardDeviation(tunemanager.getID("discarded")),usertimes.getStandardDeviation(tunemanager.getID("preferred")))

      start({getTaskTime=function() return maxAverage+math.random(4*sd)-2*sd  end,itTime=function() return 8000+math.random(2000) end,nextScene="scenes.shockertask",nextParams={page=15},enableShocks=true,inputLogFile="shocker-inputs-over-training-2",taskLogFile="shocker-summary-over-training-2"})
    end
  },
  {text="When the symbol looks like this, you must only play the first 5 moves of the sequence. Do NOT press the last move!\n\nLet's practice it now",img=function()
    return stimuli.getStimulus(tunemanager.getID("discarded",5))
    end,
    onKeyPress=function()
      local tune=tunemanager.getID("discarded")
      local average=usertimes.getAverage(tune)
      local sd=usertimes.getStandardDeviation(tune)
      tune=tunemanager.getID("discarded",5)
      trials={tune,tune,tune}
      start({getTaskTime=function()
        return average+math.random(sd)
      end,itTime=function() return 2000 end,nextScene="scenes.shockertask",nextParams={page=16},enableShocks=true,inputLogFile="shocker-inputs-practice-discarded5",taskLogFile="shocker-summary-practice-discarded5"})
    end
  },
  {text="Let’s do the task now!\n\nPress a button to continue.",
    onKeyPress=function()
      trials=trialorder.generate({
        {value=tunemanager.getID("discarded",5),n=15},
        {value="preferred",n=15},
        {value=4,n=15}},9)
      local maxAverage=math.max(usertimes.getAverage(tunemanager.getID("discarded")),usertimes.getAverage(tunemanager.getID("preferred")))

      local sd=math.max(usertimes.getStandardDeviation(tunemanager.getID("discarded")),usertimes.getStandardDeviation(tunemanager.getID("preferred")))

      start({getTaskTime=function() return maxAverage+math.random(4*sd)-2*sd  end,itTime=function() return 8000+math.random(2000) end,nextScene="scenes.shockertask",nextParams={page=17},enableShocks=true,inputLogFile="shocker-inputs-breaking-habit-2",taskLogFile="shocker-summary-breaking-habit-2"})
    end
  },
  {text="The experimenter will now disconnect your LEFT wrist from the shocker.\n\nYou can no longer be shocked to your LEFT wrist"},
  {text="Previously, a slow or incorrect sequence for this symbol led to a shock in your LEFT wrist. Now, because the shocker is NOT connected anymore, you can no longer be shocked on your left wrist. Therefore, you no longer need to play the sequence for this symbol.",
    img=function()
      return stimuli.getStimulus(tunemanager.getID("preferred"))
    end
  },
  {text="You will never be shocked when you see this symbol. You do not need play anything",img=function()
    return stimuli.getStimulus(4)
  end},
  {text="Don’t forget you still need to avoid being shocked to your RIGHT wrist. You still need to play the other sequence, according the new rule, very fast and without mistakes!\n\nGood luck!",
    img=function()
      return stimuli.getStimulus(tunemanager.getID("discarded"))
    end,
    onShow=function() trials=trialorder.generate({{value=tunemanager.getID("discarded"),n=5},{value=tunemanager.getID("preferred"),n=5},{value=4,n=5}},5) end,
    onKeyPress=function()
      local maxAverage=math.max(usertimes.getAverage(tunemanager.getID("discarded")),usertimes.getAverage(tunemanager.getID("preferred")))

      local sd=math.max(usertimes.getStandardDeviation(tunemanager.getID("discarded")),usertimes.getStandardDeviation(tunemanager.getID("preferred")))

      start({getTaskTime=function() return maxAverage+math.random(4*sd)-2*sd  end,itTime=function() return 8000+math.random(2000) end,nextScene="scenes.thankyou",nextParams=nil,trialLimit=nil,enableShocks=false,inputLogFile="shocker-inputs-disconnected",taskLogFile="shocker-summary-disconnected"}) end
  }
}

local nextScene
function scene:show(event)
  local page=event.params and event.params.page or 1
  local setup=pageSetup[page]
  if event.phase=="did" then
    if scene.keyTimer then
      timer.cancel(scene.keyTimer)
      scene.keyTimer=nil
    end
    if nextScene then
      Runtime:removeEventListener("key", nextScene)
      nextScene=nil
    end
    if setup.noKeys then
      return
    end
    scene.keyTimer=timer.performWithDelay(500, function()
      scene.keyTimer=nil
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