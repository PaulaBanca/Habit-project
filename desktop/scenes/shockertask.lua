local composer=require "composer"
local scene=composer.newScene()
local transition=transition
local display=display
local Runtime=Runtime
local tunemanager=require "tunemanager"
local trialorder=require "util.trialorder"
local findfile=require "util.findfile"
local shocker=require "shocker.shockermessenger"
local biopac=require "biopac.biopacmessenger"
local stimuli=require "stimuli"
local logger=require "util.logger"
local usertimes=require "util.usertimes"
local _=require "util.moses"
local identifyarduinos=require "util.identifyarduinos"
local timer=timer
local assert=assert
local type=type
local table=table
local os=os
local math=math
local system=system
local native=native
local print=print
local tostring=tostring
local unpack=unpack
local serpent=require "serpent"

setfenv(1,scene)

composer.setVariable("shockerpreferred","Left")

local connectArduinos
function queryMissingArduino(arduinoName,continueFunc)
  local function onComplete(event)
    if event.action == "clicked" then
      local i=event.index
      timer.performWithDelay(1,i==1 and connectArduinos or continueFunc)
      return
    end
  end

  local warning=arduinoName .. " could not be found. Would you like to continue?"
  native.showAlert("Arduino Not Found",warning, { "Retry", "Yes" }, onComplete)
end

local dontCare={}
local function checkArduinoDeviceFiles(arduinos)
  if not dontCare["Arduino-Controller"] and not arduinos["Arduino-Controller"] then
    queryMissingArduino("Shocker Controller",function()
      dontCare["Arduino-Controller"]=true
      connectArduinos()
    end)
    return false
  elseif not dontCare["BIOPAC-Controller"] and not arduinos["BIOPAC-Controller"] then
    queryMissingArduino("BIOPac Controller",function()
      dontCare["BIOPAC-Controller"]=true
      connectArduinos()
    end)
    return false
  end
  return true
end

local function getArduinoDeviceFiles(onComplete)
  local path=findfile.find("arduino-serial")
  local arduinos=identifyarduinos.createControllerTable(path)
  if checkArduinoDeviceFiles(arduinos) then
    onComplete(arduinos)
  end
end

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
local sendBIOPacSignal=function(v)
  local group=display.newGroup()
  group:translate(display.contentCenterX,display.contentCenterY)
  local c=display.newCircle(group,0,0,80)
  c:setFillColor(0)
  display.newText({
    parent=group,
    text=tostring(v),
    fontSize=60,
  })
  transition.to(group, {alpha=0,onComplete=function(obj)
    obj:removeSelf()
  end})
end

local SAFE_ID=6
connectArduinos=function()
  local serialpath=findfile.find("arduino-serial-server")

  assert(serialpath,"arduino-serial-server not found. Please make sure it is in your Home directory.")
  local function mapShockerFuctions(activateLeftShocker,activateRightShocker)
    local sides={left=activateLeftShocker,right=activateRightShocker}
    local setup={}
    local opposite={left="right",right="left"}
    setup.preferred=composer.getVariable("shockerpreferred"):lower()
    setup.discarded=assert(opposite[setup.preferred])
    setup=_.map(setup,function(_,v)
      return assert(sides[v])
    end)
    shockerCalls[tunemanager.getID("preferred")]=setup.preferred
    shockerCalls[tunemanager.getID("discarded")]=setup.discarded
    shockerCalls[tunemanager.getID("preferred",5)]=setup.preferred
    shockerCalls[tunemanager.getID("discarded",5)]=setup.discarded
    shockerCalls[SAFE_ID]=function() end
  end
  getArduinoDeviceFiles(function(arduinos)
    if not arduinos["Arduino-Controller"] then
      mapShockerFuctions(
        function() debugShocker("left") end,
        function() debugShocker("right") end
      )
    else
      shocker.connect(serialpath,arduinos["Arduino-Controller"],
        function(activateLeftShocker,activateRightShocker)
        mapShockerFuctions(activateLeftShocker,activateRightShocker)
      end)
    end
    if arduinos["BIOPAC-Controller"] then
      biopac.connect(serialpath,arduinos["BIOPAC-Controller"],
        function(sendSignal)
        sendBIOPacSignal=sendSignal 
      end)
    end
    composer.gotoScene("scenes.shockertask",{params={page=4}})
  end)
end

local REACTION_TIME=0.25*1000
local TASK_SIGNAL=1
local SHOCK_SIGNAL=2

local trials={}
function start(config)
  local count=0
  local logField=logger.create(config.taskLogFile,{"date","sequence","sequences completed","mistakes","shock","time limit", "round time","debug",
    "sequence time"})
  local nextScene,nextParams=config.nextScene,config.nextParams
  local run

  local function showFixationCross()
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

  run=function()
    local tune=table.remove(trials)
    if not tune then
      return composer.gotoScene(nextScene,{params=nextParams})
    end
    sendBIOPacSignal(TASK_SIGNAL)
    local startTime=system.getTimer()
    count=count+1
    local opts={}
    opts.logInputFilename=config.inputLogFile
    local time=config.getTaskTime()+REACTION_TIME
    opts.time=time
    opts.onComplete=function(shock,sequencesCompleted,mistakes,sequenceTimes)
      local biopacCmd=TASK_SIGNAL
      if shock and config.enableShocks or config.forceShock then
        if not shockerCalls[tunemanager.getID(tune)] then
          print (tune,tunemanager.getID(tune),serpent.block(shockerCalls,{comment=false}))
        end
        biopacCmd=biopacCmd+SHOCK_SIGNAL
        shockerCalls[tunemanager.getID(tune)]()
      end
      logField("sequence",tune)
      logField("sequences completed",sequencesCompleted)
      logField("mistakes",mistakes)
      logField("date",os.date())
      logField("shock",shock and config.enableShocks)
      logField("time limit",time)
      logField("round time", system.getTimer()-startTime)
      logField("sequence time",#sequenceTimes>0 and math.min(unpack(sequenceTimes)))
      logField("debug", usertimes.toString())
      sendBIOPacSignal(biopacCmd)
      showFixationCross()
    end
    opts.tune=tunemanager.getID(tune)
    composer.gotoScene("scenes.playtune",{params=opts})
  end
  showFixationCross()
end

local pageSetup={
  {text="In the next task, your goal is to avoid getting shocks on your wrists.\n\nThe symbol will tell you which sequence to play.\n\nTo avoid being shocked, you have to play the sequence once, without making mistakes and before the time runs out.",
  },
  {
    text="When you see the fixation cross, do not play anything.\n\nJust wait until the next symbol comes up.",
    img=function()
      local group=display.newGroup()
      local cx,cy=0,0
      local w,h=200,200
      local hw,hh=w/2,h/2
      local hline=display.newLine(group, cx-hw, cy, cx+hw,cy)
      local vline=display.newLine(group, cx, cy-hh, cx,cy+hh)
      hline:setStrokeColor(0)
      vline:setStrokeColor(0)
      hline.strokeWidth=10
      vline.strokeWidth=10
      return group
    end
  },
  {
    text="Please wait... initialising equipment",
    noKeys=true,
    onShow=function()
      connectArduinos()
    end},
  {text="These are the symbols you will see",img=function()
    local group=display.newGroup()
    local images={tunemanager.getID("preferred"),tunemanager.getID("discarded"),SAFE_ID}
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
  {
    symbol="preferred",
    text="Play the sequence once each time you see this symbol.\n\nFor this symbol, you will get a shock on your %s wrist if you make mistakes or if you are not fast enough.\n\nLet’s practice!",img=function()
    return stimuli.getStimulus(tunemanager.getID("preferred")) end,
    onKeyPress=function()
      local tune=tunemanager.getID("preferred")
      local average=usertimes.getAverage(tune)
      local sd=usertimes.getStandardDeviation(tune)
      trials={tune,tune,tune}
      start({itTime=function() return 2000 end,getTaskTime=function()
        return average+sd*2
      end,nextScene="scenes.shockertask",nextParams={page=6},enableShocks=true,inputLogFile="shocker-inputs-practice-preferred",taskLogFile="shocker-summary-practice-preferred"})
    end
  },
  {
    symbol="discarded",
    text="Play the sequence once each time you see this symbol.\n\nFor this symbol, you will get a shock on your %s wrist if you make mistakes or if you are not fast enough.\n\nLet’s practice!",img=function()
    return stimuli.getStimulus(tunemanager.getID("discarded")) end,
    onKeyPress=function()
      local tune=tunemanager.getID("discarded")
      local average=usertimes.getAverage(tune)
      local sd=usertimes.getStandardDeviation(tune)
      trials={tune,tune,tune}
      start({itTime=function() return 2000 end,getTaskTime=function()
        return average+sd*2
      end,nextScene="scenes.shockertask",nextParams={page=7},enableShocks=true,inputLogFile="shocker-inputs-practice-discarded",taskLogFile="shocker-summary-practice-discarded"})
    end
  },
  {text="This is a SAFE symbol. You will NEVER be shocked when you seen this symbol.\n\nYou do NOT need to play anything.",img=function()
    return stimuli.getStimulus(SAFE_ID)
  end},
  {text="Let’s do the task now!\n\nPress a button to continue.",
    onKeyPress=function()
      trials=trialorder.generate({
        {value="discarded",n=5},
        {value="preferred",n=5},
        {value=SAFE_ID,n=5}},5)
      local maxAverage=math.max(usertimes.getAverage(tunemanager.getID("discarded")),usertimes.getAverage(tunemanager.getID("preferred")))

      local sd=math.max(usertimes.getStandardDeviation(tunemanager.getID("discarded")),usertimes.getStandardDeviation(tunemanager.getID("preferred")))

      start({getTaskTime=function() return maxAverage+2*sd end,itTime=function() return 8000+math.random(2000) end,nextScene="scenes.shockertask",nextParams={page=9},enableShocks=true,inputLogFile="shocker-inputs-over-training-1",taskLogFile="shocker-summary-over-training-1"})
    end
 },
 {
  symbol="preferred",
  text="One of the sequences and its symbol is now changed.\n\nWhen the symbol looks like this, you must ONLY play the first 5 moves of the sequence. Do NOT press the last move!\n\nIf you do it wrong or too slow, you will be shocked in your %s wrist.\n\nLet’s practice it now.",img=function()
    return stimuli.getStimulus(tunemanager.getID("preferred",5))
    end,
    onKeyPress=function()
      local tune=tunemanager.getID("preferred")
      local average=usertimes.getAverage(tune)
      local sd=usertimes.getStandardDeviation(tune)
      tune=tunemanager.getID("preferred",5)
      trials={tune,tune,tune}
      start({getTaskTime=function()
        return average+sd*2
      end,itTime=function() return 2000 end,nextScene="scenes.shockertask",nextParams={page=10},enableShocks=true,inputLogFile="shocker-inputs-practice-preferred5",taskLogFile="shocker-summary-practice-preferred5"})
    end
  },
  {
    text="The remaining 2 symbols are kept the same. Play exactly as you did before."
  },
  {
    symbol="discarded",
    text="For the above symbol, you need to play the corresponding sequence to avoid a shock to your %s wrist.",
    img=function() return stimuli.getStimulus(tunemanager.getID("discarded")) end
  },
  {
    text="The SAFE symbol remains SAFE. You do NOT need to play anything.",
    img=function() return stimuli.getStimulus(SAFE_ID) end
  },
  {text="Let’s do the task now!\n\nPress a button to continue.",
    onKeyPress=function()
      trials=trialorder.generate({{value="discarded",n=10},{value=tunemanager.getID("preferred",5),n=10},{value=SAFE_ID,n=10}},6)
      local maxAverage=math.max(usertimes.getAverage(tunemanager.getID("discarded")),usertimes.getAverage(tunemanager.getID("preferred")))

      local sd=math.max(usertimes.getStandardDeviation(tunemanager.getID("discarded")),usertimes.getStandardDeviation(tunemanager.getID("preferred")))

      start({getTaskTime=function() return maxAverage+2*sd end,itTime=function() return 8000+math.random(2000) end,nextScene="scenes.shockertask",nextParams={page=14},enableShocks=true,inputLogFile="shocker-inputs-breaking-habit-1",taskLogFile="shocker-summary-breaking-habit-1"})
    end
  },
  {text="Interval\n\nTake a break!\n\nPress a button to continue."},
  {text="Now, let’s start again with the old symbols. Your goal remains to avoid getting shocks on your wrists.\n\nThe symbol will tell you which sequence to play.\n\nTo avoid being shocked, you have to play the sequence once, without making mistakes and before the time runs out."},
  {text="These are the symbols you will see",img=function()
    local group=display.newGroup()
    local images={tunemanager.getID("preferred"),tunemanager.getID("discarded"),SAFE_ID}
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
  {text="Let’s do the task again!\n\nPress a button to continue.",
    onKeyPress=function()
      trials=trialorder.generate({
        {value="discarded",n=30},
        {value="preferred",n=30},
        {value=SAFE_ID,n=30}},15)
      local maxAverage=math.max(usertimes.getAverage(tunemanager.getID("discarded")),usertimes.getAverage(tunemanager.getID("preferred")))

      local sd=math.max(usertimes.getStandardDeviation(tunemanager.getID("discarded")),usertimes.getStandardDeviation(tunemanager.getID("preferred")))

      start({getTaskTime=function() return maxAverage+2*sd end,itTime=function() return 8000+math.random(2000) end,nextScene="scenes.shockertask",nextParams={page=18},enableShocks=true,inputLogFile="shocker-inputs-over-training-2",taskLogFile="shocker-summary-over-training-2"})
    end
  },
  {
    symbol="discarded",
    text="Now the other sequence and its symbol has changed.\n\nWhen the symbol looks like this, you must ONLY play the first 5 moves of the sequence. Do NOT press the last move!\n\nIf you do it wrong or too slow, you will be shocked in your %s wrist.\n\nLet’s practice it now.",img=function()
    return stimuli.getStimulus(tunemanager.getID("discarded",5))
    end,
    onKeyPress=function()
      local tune=tunemanager.getID("discarded")
      local average=usertimes.getAverage(tune)
      local sd=usertimes.getStandardDeviation(tune)
      tune=tunemanager.getID("discarded",5)
      trials={tune,tune,tune}
      start({getTaskTime=function()
        return average+2*sd
      end,itTime=function() return 2000 end,nextScene="scenes.shockertask",nextParams={page=19},enableShocks=true,inputLogFile="shocker-inputs-practice-discarded5",taskLogFile="shocker-summary-practice-discarded5"})
    end
  },
  {
    text="The remaining 2 symbols are kept the same. Play exactly as you did before."
  },
  {
    symbol="preferred",
    text="For the above symbol, you need to play the corresponding sequence to avoid a shock to your %s wrist.",
    img=function() return stimuli.getStimulus(tunemanager.getID("preferred")) end
  },
  {
    text="The SAFE symbol remains SAFE. You do NOT need to play anything.",
    img=function() return stimuli.getStimulus(SAFE_ID) end
  },
  {text="Let’s do the task now!\n\nPress a button to continue.",
    onKeyPress=function()
      trials=trialorder.generate({
        {value=tunemanager.getID("discarded",5),n=15},
        {value="preferred",n=15},
        {value=SAFE_ID,n=15}},9)
      local maxAverage=math.max(usertimes.getAverage(tunemanager.getID("discarded")),usertimes.getAverage(tunemanager.getID("preferred")))

      local sd=math.max(usertimes.getStandardDeviation(tunemanager.getID("discarded")),usertimes.getStandardDeviation(tunemanager.getID("preferred")))

      start({getTaskTime=function() return maxAverage+2*sd end,itTime=function() return 8000+math.random(2000) end,nextScene="scenes.shockertask",nextParams={page=23},enableShocks=true,inputLogFile="shocker-inputs-breaking-habit-2",taskLogFile="shocker-summary-breaking-habit-2"})
    end
  },
  {text="Interval\n\nTake a break!\n\nPress a button to continue."},
  {
    symbol="preferred",
    text="The experimenter will now disconnect your %s wrist from the shocker.\n\nYou can no longer be shocked to your %s wrist"},
  {
    symbol="preferred",
    text="Previously, a slow or incorrect sequence for this symbol led to a shock in your %s wrist. Now, because the shocker is NOT connected anymore, you can no longer be shocked on your %s wrist. Therefore, you no longer need to play the sequence for this symbol.",
    img=function()
      return stimuli.getStimulus(tunemanager.getID("preferred"))
    end
  },
  {
    symbol="discarded",
    text="Don’t forget you still need to avoid being shocked to your %s wrist. You still need to play the other sequence very fast and without mistakes!\n\nGood luck!",
    img=function()
      return stimuli.getStimulus(tunemanager.getID("discarded"))
    end
  },
  {text="This symbol remains a SAFE. You will never be shocked when you see it. You do NOT need to play anything.",img=function()
    return stimuli.getStimulus(SAFE_ID)
  end},
  {
    text="Let’s do the task now!\n\nPress a button to continue.",
    onShow=function() trials=trialorder.generate({{value=tunemanager.getID("discarded"),n=5},{value=tunemanager.getID("preferred"),n=5},{value=SAFE_ID,n=5}},5) end,
    onKeyPress=function()
      local maxAverage=math.max(usertimes.getAverage(tunemanager.getID("discarded")),usertimes.getAverage(tunemanager.getID("preferred")))

      local sd=math.max(usertimes.getStandardDeviation(tunemanager.getID("discarded")),usertimes.getStandardDeviation(tunemanager.getID("preferred")))

      start({getTaskTime=function() return maxAverage+2*sd end,itTime=function() return 8000+math.random(2000) end,nextScene="scenes.thankyou",nextParams=nil,trialLimit=nil,enableShocks=false,inputLogFile="shocker-inputs-disconnected",taskLogFile="shocker-summary-disconnected"}) end
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
        if event.phase=="up" and event.keyName=="enter" then
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

  local side
  if setup.symbol then
    side=composer.getVariable("shockerpreferred"):lower()
    if setup.symbol=="discarded" then
      local opposite={left="right",right="left"}
      side=opposite[side]
    end
    side=side:upper()
  end
  local text=display.newText({
    parent=self.view,
    text=setup.text:format(side,side),
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
    text="Press enter to continue",
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