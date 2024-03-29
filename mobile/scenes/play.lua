local composer=require "composer"
local scene=composer.newScene()

local sound=require "sound"
local particles=require "particles"
local tunes=require "tunes"
local stimuli=require "stimuli"
local keys=require "keys"
local playlayout=require "playlayout"
local practicelogger=require "practicelogger"
local chordbar=require "ui.chordbar"
local background=require "ui.background"
local playstate=require "playstate"
local daycounter=require "daycounter"
local logger=require "logger"
local sessionlogger=require "sessionlogger"
local deadmansswitch=require "ui.deadmansswitch"
local keysparks=require "ui.keysparks"
local i18n = require ("i18n.init")
local _=require "util.moses"
local serpent = require ("serpent")
local incompletetasks = require ("incompletetasks")
local averagetimes = require ("database.averagetimes")
local variableratioreward = require ("util.variableratioreward")
local replayreward = require ("util.replayreward")
local rewardtimes = require("database.rewardtimes")
local user = require "user"
local coins=require("mobileconstants").coins
local easing = easing
local unpack=unpack
local display=display
local math=math
local print=print
local transition=transition
local system=system
local timer=timer
local tostring=tostring
local table=table
local tonumber=tonumber
local Runtime=Runtime
local os=os
local pairs=pairs
local ipairs=ipairs
local NUM_KEYS=NUM_KEYS
local assert=assert

setfenv(1,scene)

local numRewardsEarned = 0
local targetRewards = 0
local sequence
local maxLearningLength=10
local rounds=2
local learningLength=maxLearningLength
local track=1
local modes={"learning","blind"}
local modeIndex=1
local isStart=false
local startModeProgression=false
local headless=false
local rewardType="none"
local mistakesPerMode=_.rep(0,#modes)
local targetModeIndex
local roundModes
local modesDropped=0
local state
local nextScene
local isScheduledPractice
local trackList
local stimulusScale=0.35
local practiceStart
local hideRewards
local practice

local startInstructions={
  {chord={"c4","none","none","none"},forceLayout=true},
  {chord={"none","a4","none","none"},forceLayout=true},
  {chord={"none","none","d4","none"},forceLayout=true},
  {chord={"none","none","none","g4"},forceLayout=true},
  {chord={"c3","none","g4","none"},forceLayout=true},
  {chord={"none","c4","e4","a4"},forceLayout=true},
  {chord={"f3","none","none","c4"},forceLayout=true},
}

if system.getInfo("environment")=="simulator" then
  for _,v in ipairs(startInstructions) do
    v.chord = {"c4", "none", "none", "none"}
  end
end

local modeProgressionSequence={
  {chord={"c4","none","none","none"},forceLayout=true},
  {chord={"none","a4","none","none"},forceLayout=true},
  {chord={"none","none","d4","none"},forceLayout=true},
  {chord={"none","none","none","g4"},forceLayout=true},
}

if NUM_KEYS==3 then
  table.remove(modeProgressionSequence, #modeProgressionSequence)
  for i=1, #modeProgressionSequence do
    local chord=modeProgressionSequence[i].chord
    table.remove(chord,#chord)
  end

  table.remove(startInstructions, 4)
  for i=1, #startInstructions do
    local chord=startInstructions[i].chord
    table.remove(chord,#chord)
  end
end

local function switchSong(newTrack)
  local x,y=display.contentCenterX, 0
  if scene.img then
    scene.img:removeSelf()
  end
  track=newTrack or (track%2)+1
  scene:setUpKeyLayers()
  scene.keyLayers:switchTo(modeIndex,true)
  local songs=tunes.getTunes()
  sequence=songs[track]
  local index=tunes.getStimulus(sequence)
  local img=stimuli.getStimulus(index)
  scene.view:insert(img)
  img.anchorY=0
  img:translate(x,y)
  img:scale(stimulusScale,stimulusScale)
  scene.img=img
  logger.setTrack(track)
end

local function roundCompleteAnimation()
  sound.playSound("correct")
end

local function keyChangeAnimation()
  scene.keys:disable()
  scene.keyLayers:switchTo(modeIndex)
end

local function mistakeAnimation(bg)
  sound.playSound("wrong")
  bg:toFront()
  bg.alpha=1
  transition.to(bg,{alpha=0})
end

local function getIndex()
  return state.get("count")%#sequence+1
end

local function shouldDropModeDown()
  return state.get("mistakes")>3 and modeIndex>1 and not headless and not isStart
end

local lastMistakeTime=system.getTimer()
local function dropModeDown()
  state.clear("mistakes")
  logger.setLives(3-state.get("mistakes"))

  lastMistakeTime=system.getTimer()
  state:pushState()
  modeIndex=modeIndex-1
  learningLength=1
  modesDropped=modesDropped+1
  logger.setModesDropped(modesDropped)
  logger.setModeIndex(modeIndex)
  logger.setIterations(state.get("iterations"))
  logger.setTotalMistakes(mistakesPerMode[modeIndex])
  scene.keys:disable()
  keyChangeAnimation()
  scene.cross:toFront()
end

local function restart()
  state.restart()
  scene.keys:clear()
end

local countMistakes
local mistakeThisRound
local function madeMistake()
  mistakeThisRound = true
  local time=system.getTimer()
  if time-lastMistakeTime>500 then
    state.increment("mistakes")
    logger.setLives(3-state.get("mistakes"))
    lastMistakeTime=time
  end
  if countMistakes then
    countMistakes=false
    mistakesPerMode[modeIndex]=mistakesPerMode[modeIndex]+1
    logger.setTotalMistakes(mistakesPerMode[modeIndex])
  end
end

local function collectReward()
  if rewardType=="none" then
    return
  end

  local timeIntoPractice = system.getTimer() - practiceStart
  local rewardFunc = {
    ratio = function() return variableratioreward.trialHasReward() end,
    interval = function()
      return replayreward.trialHasReward(timeIntoPractice)
    end
  }

  local earnedCoin = rewardFunc[rewardType]()
  if earnedCoin then
    if rewardType == "interval" then
      logger.setScheduleParameter(replayreward.nextReward())
    end
    numRewardsEarned = numRewardsEarned + 1
    logger.setRewardsEarned(numRewardsEarned)
    local day = daycounter.getPracticeDay()
    rewardtimes.log({
      track = track,
      userid = user.getID(),
      rewardTime = timeIntoPractice,
      practice = daycounter.getLastCompletedPractice(track, day) + 1,
      day = day,
    })
  end

  if hideRewards then
    return
  end

  local rewardGraphic
  if earnedCoin then
    local reward = display.newEmitter(particles.load("reward"))
    reward:scale(2,2)
    scene.view:insert(reward)
    reward:translate(display.contentCenterX, display.contentCenterY)

    timer.performWithDelay(1000, function()
      display.remove(reward)
    end)

    local coin = display.newImage(scene.view, coins[track])
    coin:scale(2,2)
    rewardGraphic = coin

    sound.playSound("reward")
  else
    local group = display.newGroup()
    local bg = display.newCircle(group, 0, 0 , 60)
    bg.strokeWidth = 8
    bg:setFillColor(0.4)
    bg:setStrokeColor(0.5)
    display.newImage(group, "img/0.png")
    rewardGraphic = group
  end

  rewardGraphic:translate(display.contentCenterX, display.contentCenterY)

    local t = transition.to(rewardGraphic, {
      y = -rewardGraphic.height/2,
      transition = easing.inQuad,
      onComplete = display.remove
    })

    function rewardGraphic.finalize()
      transition.cancel(t)
    end
    rewardGraphic:addEventListener("finalize")

end

local function shouldChangeModeUp()
  return state.get("iterations")>=learningLength
end

local function changeModeUp()
  state.pullState()
  state.clear("mistakes")
  logger.setLives(3-state.get("mistakes"))

  if modesDropped > 0 then
    modeIndex=modeIndex+1
    if modeIndex>#modes then
      modeIndex=#modes
    end
  else
    modeIndex = targetModeIndex
  end

  if modesDropped==0 then
    state.clear("iterations")
  else
    while not hasCompletedRound() do
      state.increment()
    end
  end
  modesDropped=modesDropped-1
  if modesDropped<=0 then
    modesDropped=0
  end
  learningLength=modesDropped==0 and maxLearningLength or 3
  logger.setModesDropped(modesDropped)
  logger.setModeIndex(modeIndex)
  logger.setTotalMistakes(mistakesPerMode[modeIndex])
  keyChangeAnimation()
end

function hasCompletedRound()
  local index=getIndex()
  return index==#sequence and state.get("count")>0
end

function completeRound()
  if headless then
    return
  end
  if not hasCompletedRound() then
    return
  end
  mistakeThisRound = false
  roundCompleteAnimation()
  if not isStart and modesDropped==0 then
    state.increment("rounds")
    local rounds=state.get("rounds")
    if rounds==maxLearningLength then
      mistakesPerMode=_.rep(0,#modes)
      logger.setTotalMistakes(mistakesPerMode[modeIndex])
      logger.setProgress("midpoint")
      targetModeIndex = table.remove(roundModes, 1) or targetModeIndex
    end
    collectReward()
  end

  state.startTimer()

  state.increment("iterations")
  state.clear("mistakes")
  logger.setLives(3-state.get("mistakes"))

  scene.keys:clear()

  if shouldChangeModeUp() then
    changeModeUp()
  end

  logger.setIterations(state.get("iterations"))
end

function proceedToNextStep()
  scene.keys:clear(true)
  state.increment()
end

function hasCompletedTask()
  if rewardType ~= "none" then
    return numRewardsEarned == targetRewards
  end

  return modesDropped==0 and state.get("rounds")==maxLearningLength*rounds
end

function completeTask()
  if not hasCompletedTask() then
    return
  end
  scene.keys:removeSelf()
  if isScheduledPractice then
    practicelogger.logPractice(track)
    practicelogger.resetAttempts(track)

    daycounter.completedPractice(track)
    sessionlogger.logPracticeCompleted()
  end
  user.store("reward of last completed practice", rewardType)
  timer.performWithDelay(1000, function()
    incompletetasks.lastCompleted()
    composer.gotoScene(nextScene,{params={
        score=numRewardsEarned,
        extinguished = hideRewards,
        full = hideRewards and user.get("reward extinguish") == track,
        track=track
      }
    })
    composer.hideOverlay()
  end)
  return true
end

function setupNextKeys()
  if headless then
    return
  end

  scene.keys:enable()
  state.increment("stepID")
  local index=getIndex()
  local nextIntruction=sequence[index]
  local targetKeys=scene.keys:setup(nextIntruction,modeIndex>1,modeIndex>1,modeIndex>1,index,state.get("stepID"))

  if scene.hint then
    scene.hint:removeSelf()
    scene.hint=nil
  end
  if modeIndex==1 then
    local hint=chordbar.create(targetKeys)
    if hint then
      hint:translate(0,-scene.keys:getKeyHeight()/2)
      scene.hint=hint
      scene.view:insert(hint)
      hint:toBack()
    end
  end
  if scene.deadSensor then
    scene.deadSensor:toFront()
  end
end

function setUpReward(numRewards)
  if rewardType == "interval" then
    local otherTrack = (track + 2) % 2 + 1
    local copyFromDay = daycounter.getPracticeDay()
    while not daycounter.hasCompletedPractice(otherTrack, copyFromDay) do
      copyFromDay = copyFromDay - 1
      assert(copyFromDay >= 1, "setting up replay reward, could not go back far enough")
    end

    local copyFromPactice = daycounter.getLastCompletedPractice(otherTrack, copyFromDay)
    rewardtimes.getRewardTimesForTrack(otherTrack, copyFromDay, copyFromPactice, function(t)
      assert(t and #t > 0, "Setting up replay reward, no rewards to copy")

      replayreward.setup(t)
      logger.setScheduleParameter(replayreward.nextReward())
      numRewards = #t
      targetRewards = numRewards
      logger.setTotalRewards(numRewards)
    end)
  end

  if rewardType=="ratio" then
    logger.setScheduleParameter(-1)
    variableratioreward.setup(20, numRewards)
    targetRewards = numRewards
    logger.setTotalRewards(numRewards)
  end
end

function scene:create(event)
  local bg=background.create()
  scene.view:insert(bg)
  scene.bg=bg

  bg:addEventListener("tap",function(event)
    local wrong=display.newCircle(scene.view,event.x,event.y,10)
    wrong:setFillColor(1,0,0)
    transition.to(wrong,{alpha=0,delay=500,onComplete=function(obj)
      display.remove(obj)
    end})
  end)

  local temp=stimuli.getStimulus(1)
  temp:scale(stimulusScale,stimulusScale)
  local cross=display.newImage(self.view,"img/cross.png")
  cross.anchorX=0
  cross.anchorY=0
  cross.x=display.contentCenterX+temp.contentWidth+20
  cross.y=20
  cross:scale(0.5,0.5)
  temp:removeSelf()

  cross:addEventListener("tap",function()
    if self.onClose then
      self.onClose()
      self.onClose=nil
    end
    composer.gotoScene("scenes.schedule")
  end)
  self.cross=cross

  local circle=display.newCircle(self.view, playlayout.CX, playlayout.CY, playlayout.RADIUS)
  circle:setFillColor(1,1,1, 0.2)
  circle.xScale=playlayout.ELIPSE_XSCALE

  local redBackground=display.newRect(scene.view,display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
  redBackground.fill.effect="generator.custom.pattern"
  redBackground:setFillColor(1,0,0)
  redBackground.alpha=0
  self.redBackground=redBackground
  for i=1, self.view.numChildren do
    self.view[i].doNotRemoveOnHide=true
  end
end

function scene:createKeys()
  local mistakeInLastTouches=false
  local group=display.newGroup()
  local ks=keys.create({
    onAllReleased=function(stepID,data)
      if stepID and stepID~=state.get("stepID") then
        return
      end
      logger.setProgress(nil)
      if data then
        data.mistakes=mistakesPerMode[modeIndex]
        if rewardType~="none" then
          data.bank=numRewardsEarned
        end
      end
      if not mistakeInLastTouches then
        if getIndex()==1 then
          countMistakes=true
        end
        if hasCompletedRound() then
          -- if not trainingMode and mistakeThisRound then
          --   mistakeAnimation(self.redBackground)
          -- end
          if data then
            data["practiceProgress"]="sequence completed"
            averagetimes.log({
              startMillis = data["appMillis"] - data["timeIntoSequence"],
              endMillis = data["appMillis"],
              track = tonumber(data["track"]),
              userid = data["userid"],
              mistake = mistakeThisRound and 1 or 0
            })
          end
          completeRound()
          if completeTask() then
            return
          end
          if trackList then
            switchSong(table.remove(trackList))
            if #trackList==0 then
              trackList=nil
            end
          end
        end
        if isStart and getIndex()==#sequence then
          targetModeIndex = table.remove(roundModes, 1) or targetModeIndex
          local done=modeIndex==startModeProgression
          changeModeUp()
          sequence=startModeProgression and modeProgressionSequence or startInstructions
          restart()
          if done or not startModeProgression then
            composer.hideOverlay()
            composer.gotoScene(nextScene)
          end
        else
          proceedToNextStep()
        end
      end
      mistakeInLastTouches=false
      setupNextKeys()
    end,
    onMistake=function(allReleased,stepID,data)
      madeMistake()
      mistakeAnimation(self.redBackground)

      if data then
        data.mistakes=mistakesPerMode[modeIndex]
        data.lives=3-state.get("mistakes")
        if rewardType~="none" then
          data.bank=numRewardsEarned
        end
      end

      local modesDropped=shouldDropModeDown()
      restart()
      if modesDropped then
        dropModeDown()
        mistakeInLastTouches=false
        setupNextKeys()
      else
        mistakeInLastTouches=true
      end
     end,
     onKeyRelease=function (data)
        data.mistakes=mistakesPerMode[modeIndex]
        data.lives=3-state.get("mistakes")

        if rewardType~="none" then
          data.bank=numRewardsEarned
        end
      end
    },isStart)

  group:insert(ks)

  function group:getKeys()
    return ks
  end
  return group
end

function scene:setUpKeyLayers()
  if self.keyLayers then
    self.keyLayers:removeSelf()
    self.keys=nil
  end
  local layers=display.newGroup()
  self.view:insert(layers)
  self.keyLayers=layers

  for i=1,#modes do
    local group=display.newContainer(layers, display.actualContentWidth, display.actualContentHeight)
    group.anchorChildren=true
    local strokeWidth=8
    local bg=display.newRect(group,0,0,display.actualContentWidth-strokeWidth,display.actualContentHeight-strokeWidth)
    local colour={0.15,0.15,0.15}
    colour[track + 1] = 0.5  - 0.1 * i

    bg:setFillColor(unpack(colour))
    bg.strokeWidth=8
    bg:setStrokeColor(1)

    local bg=display.newRect(group,5,5,display.actualContentWidth-strokeWidth,display.actualContentHeight-strokeWidth)
    bg:setFillColor(0, 0)
    bg.strokeWidth=strokeWidth
    bg:setStrokeColor(0)
    bg:toBack()

    local num=display.newText({
      parent=group,
      text=i,
      fontSize=47,
      font="Chunkfive.otf",
      x=display.actualContentWidth/2-20,
      y=-display.actualContentHeight/4
    })
    num:setFillColor(0.4)
    num.anchorX=1
    num.blendMode="add"

    local text=display.newText({
      parent=group,
      text=i18n("game.level") .. " ",
      font="Chunkfive.otf",
      fontSize=32,
      x=num.x-num.width,
      y=-display.actualContentHeight/4
    })
    text:setFillColor(0.4)
    text.anchorX=1
    text.blendMode="add"

    local ks=scene:createKeys()
    function group:getKeys()
      return ks:getKeys()
    end
    group.yOff=ks.contentBounds.yMax-display.actualContentHeight
    group:insert(ks)
    ks:translate(-display.actualContentWidth/2, -display.actualContentHeight/2)
    local offset=#modes-i
    group.anchorChildren=true
    group.anchorX=1
    group.anchorY=1
    group:translate(display.actualContentWidth+offset*-10, display.actualContentHeight+offset*-10+group.yOff)
  end

  function layers:switchTo(layer,noAnim)
    if scene.keys then
      scene.keys:disable()
    end
    local count=0
    for i=layer+1,self.numChildren do
      local l=self[i]
      l.anchorChildren=true
      local offset=i-layer
      l:getKeys():disable()
      local delay=count*250
      local opts={
        time=200,
        anchorX=1,
        anchorY=1,
        x=display.actualContentWidth+offset*-10,
        y=display.actualContentHeight+offset*-10,
      }
      if noAnim then
        opts.time=nil
        opts.rotation=90
        opts.alpha=0
        for k,v in pairs(opts) do
          l[k]=v
        end
      else
        opts.onComplete=function()
          transition.to(l,{rotation=90,delay=delay,alpha=0})
        end

        transition.to(l,opts)
      end
      count=count+1
    end

    count=0
    for i=1,layer do
      local l=self[i]
      l.anchorChildren=true
      local offset=layer-i
      local delay=count*250
      local opts={
        time=200,
        anchorX=1,
        anchorY=1,
        x=display.actualContentWidth+offset*-10,
        y=display.actualContentHeight+offset*-10,
      }
      if noAnim then
        opts.time=nil
        opts.rotation=0
        opts.alpha=1
        for k,v in pairs(opts) do
          l[k]=v
        end
      else
        opts.onComplete=function()
          transition.to(l,{rotation=0,delay=delay,alpha=1})
        end
        transition.to(l,opts)
      end
      if l.rotation~=0 then
        count=count+1
      end
    end
    scene.keys=self[layer]:getKeys()
    scene.keys:enable()
  end
end

function scene:show(event)
  if event.phase~="did" then
    return
  end
  numRewardsEarned = 0
  practiceStart = system.getTimer()
  rounds=event.params.rounds or 2
  maxLearningLength=event.params.iterations or 10
  learningLength=maxLearningLength
  -- composer.showOverlay("scenes.dataviewer")
  mistakesPerMode=_.rep(0,#modes)
  countMistakes=true

  isStart=event.params and event.params.intro
  startModeProgression=event.params and event.params.modeProgression
  headless=event.params and event.params.headless
  hideRewards = event.params and event.params.hideRewards
  self.onClose=event.params and event.params.onClose
  rewardType=event.params and event.params.rewardType or "none"
  nextScene=event.params and event.params.nextScene or "scenes.score"
  isScheduledPractice=event.params and event.params.isScheduledPractice
  logger.setIsScheduled(isScheduledPractice or false)
  logger.setMode(event.params and event.params.mode)
  if not isScheduledPractice then
    logger.setPractices(-1)
    logger.setAttempts(-1)
  end
  if headless then
    rewardType="none"
  end
  roundModes=event.params and event.params.iterationDifficulties or {1}
  modeIndex = table.remove(roundModes, 1)
  targetModeIndex = modeIndex
  if headless then
    modeIndex=3
  else
    logger.setModeIndex(modeIndex)
  end

  local setTrack=event.params and event.params.track
  if setTrack=="random" then
    trackList=_.shuffle(_.append(_.rep(1,maxLearningLength/2),_.rep(2,maxLearningLength/2)))
    setTrack=table.remove(trackList, 1)
  else
    trackList=nil
  end

  state=playstate.create()
  state.startTimer()
  modesDropped=0
  logger.setRewardsEarned(numRewardsEarned)
  logger.setScheduleType(rewardType)
  logger.setRewardsExtinguished(hideRewards)
  logger.setScore(user.get("reward extinguish"))
  logger.setIterations(state.get("iterations"))
  logger.setTotalMistakes(mistakesPerMode[modeIndex])
  logger.setLives(3-state.get("mistakes"))

  logger.setBank(0)
  logger.setModesDropped(modesDropped)
  logger.setProgress("start")

  practice=event.params and event.params.practice
  logger.setDeadmansSwitchID(nil)
  local releaseTimeMillis,releaseTime
  local deadSensor,deadMansSwitchGroup=deadmansswitch.start(function()
    self.keys:enable()
    self.keys:setLogData(not isStart)
    if not releaseTime or isStart then
      return
    end

    local rowid=logger.log("switchRelease",{
      releaseDuration=system.getTimer()-releaseTimeMillis,
      releaseTime=releaseTime,
      pressedTime=os.date("%T"),
      date=os.date("%F"),
      appMillis=system.getTimer(),
      practice=practice,
      track=track,
    })
    logger.setDeadmansSwitchID(rowid)
    releaseTime=nil
  end,function()
    self.keys:setLogData(false)
    if hasCompletedTask() then
      self.keys:disable()
      return
    end
    releaseTimeMillis=system.getTimer()
    releaseTime=os.date("%T")
    mistakeAnimation(self.redBackground)
    restart()
    setupNextKeys()
    self.keys:disable()
  end)
  self.view:insert(deadSensor)
  self.deadSensor=deadSensor
  self.view:insert(deadMansSwitchGroup)
  self.deadMansSwitchGroup=deadMansSwitchGroup

  if isStart then
    if startModeProgression then
      sequence=modeProgressionSequence
    else
      sequence=startInstructions
    end
    logger.setTrack(-1)
    self:setUpKeyLayers()
    self.keyLayers:switchTo(modeIndex,true)
  else
    switchSong(setTrack)
  end

  if system.getInfo("environment")~="simulator" then
    self.keys:disable()
  end

  restart()
  setupNextKeys()
  setUpReward(math.floor(math.gaussian(5, 0.5) + 0.5))
  self.cross:toFront()
  self.cross.isVisible=not isStart and not event.params.noQuit

  logger.setIntro(isStart or false)

  deadMansSwitchGroup:toFront()
  if event.params.noSwitch then
    deadMansSwitchGroup:removeSelf()
    self.deadMansSwitchGroup=nil
    self.keys:enable()
    self.deadSensor:removeSelf()
    self.deadSensor=nil
  end
end

function scene:hide(event)
  if event.phase=="will" then
    deadmansswitch.stop()
  end
  if event.phase=="did" then
    logger.startCatchUp()
    keysparks.clear()
    for i=self.view.numChildren,1,-1 do
      if not self.view[i].doNotRemoveOnHide then
        self.view[i]:removeSelf()
      end
    end
    self.keyLayers=nil
    self.keys=nil
    self.img=nil
    self.deadMansSwitchGroup=nil
    self.deadSensor=nil
    self.calcReward=nil
    self.hint=nil
  end
end

scene:addEventListener("create")
scene:addEventListener("show")
scene:addEventListener("hide")

Runtime:addEventListener("system", function (event)
  if event.type=="applicationResume" and not isStart then
    composer.gotoScene("scenes.schedule")
    logger.startCatchUp()
  end
end)

return scene