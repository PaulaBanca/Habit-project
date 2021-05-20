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
local countdownpoints=require "util.countdownpoints"
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
local vr = require ("util.variableratioreward")
local unpack=unpack
local easing = easing
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

setfenv(1,scene)

local sequence
local maxLearningLength=10
local rounds=2
local learningLength=maxLearningLength
local track=1
local modes={"learning","recall","blind","invisible"}
local modeIndex=1
local isStart=false
local startModeProgression=false
local headless=false
local rewardType="none"
local mistakesPerMode=_.rep(0,#modes)
local modesDropped=0
local state
local nextScene
local isScheduledPractice
local trackList
local stimulusScale=0.35
local mistakesMadeThisRound = 0

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
  local x,y=display.contentCenterX, scene.progress.iconY
  if scene.img then
    scene.img:removeSelf()
  end
  track=newTrack or (track%2)+1
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
  -- local p=display.newEmitter(particles.load("sequenceright"))
  -- p.blendMode="add"
  -- scene.view:insert(p)
  -- p:translate(display.contentCenterX, display.contentCenterY)

  -- local t=transition.to(p, {time=2000,alpha=0,onComplete=function()
  --   p:removeSelf()
  -- end})
  -- function p:finalize()
  --   transition.cancel(t)
  -- end
  -- p:addEventListener("finalize")
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

local function resetBank()
  if not scene.bank then
    return
  end
  scene.bank.isVisible=false
  scene.bank:setScore(0)
  scene.calcReward=nil
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
  scene.progress.isVisible=false
  if scene.points then
    scene.points.isVisible=false
  end
  learningLength=3
  modesDropped=modesDropped+1
  logger.setModesDropped(modesDropped)
  logger.setModeIndex(modeIndex)
  logger.setIterations(state.get("iterations"))
  logger.setTotalMistakes(mistakesPerMode[modeIndex])
  scene.keys:disable()
  keyChangeAnimation()
end

local function restart()
  --resetBank()

  state.restart()
  scene.keys:clear()
end

local countMistakes
local function madeMistake()
  local time=system.getTimer()
  mistakesMadeThisRound = mistakesMadeThisRound + 1
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

local function processBank()
  if rewardType=="none" then
    return
  end

  if not vr.trialHasReward() then
    return
  end

  local p=display.newEmitter(particles.load("reward"))
  scene.view:insert(p)
  p:translate(display.contentCenterX, display.contentCenterY)
  sound.playSound("reward")
  timer.performWithDelay(1000, function()
    display.remove(p)
  end)

  local c = display.newImage("img/coin.png")
  scene.view:insert(c)
  c:translate(display.contentCenterX, display.contentCenterY)
  c:scale(0.0001, 0.0001)
  transition.to(c, {xScale = 1, yScale = 1, transition = easing.outElastic, onComplete = function()
    transition.to(c, {y = -c.height, onComplete=display.remove, easing.outQuart})
  end})
end

local function shouldChangeModeUp()
  return state.get("iterations")>=learningLength
end

local function changeModeUp()
  state.pullState()
  state.clear("mistakes")
  logger.setLives(3-state.get("mistakes"))

  modeIndex=modeIndex+1
  if modeIndex>#modes then
    modeIndex=#modes
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
    scene.progress.isVisible=not isStart
    if scene.points then
      scene.points.isVisible=scene.progress.isVisible
    end
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
  mistakesMadeThisRound = 0
  if updateMistakeDisplay then
   updateMistakeDisplay(mistakesMadeThisRound)
  end
  mistakeThisRound = false
  roundCompleteAnimation()
  if modesDropped==0 then
    state.increment("rounds")
    local rounds=state.get("rounds")
    if rounds==maxLearningLength then
      mistakesPerMode=_.rep(0,#modes)
      logger.setTotalMistakes(mistakesPerMode[modeIndex])
      logger.setProgress("midpoint")
    end
    if rounds<=maxLearningLength*2 then
      scene.progress:mark(rounds,state.get("mistakes")==0)
    end
    processBank()
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
  return modesDropped==0 and state.get("rounds")==maxLearningLength*rounds
end

function completeTask()
  if not hasCompletedTask() then
    return
  end
  if state.get("rounds")==maxLearningLength*rounds then
    scene.keys:removeSelf()
    if isScheduledPractice then
      practicelogger.logPractice(track)
      practicelogger.resetAttempts(track)

      daycounter.completedPractice(track)
      sessionlogger.logPracticeCompleted()
    end
    timer.performWithDelay(600, function()
      incompletetasks.lastCompleted()
      composer.gotoScene(nextScene,{params={
        score= 0, --rewardType~="none" and tonumber(scene.points.text),
        track=track}
      })
      composer.hideOverlay()
    end)
    return true
  end
end

function setupNextKeys()
  if headless then
    return
  end

  scene.keys:enable()
  state.increment("stepID")
  local index=getIndex()
  local nextIntruction=sequence[index]
  local targetKeys=scene.keys:setup(nextIntruction,modeIndex>1,modeIndex>2,modeIndex>3,index,state.get("stepID"))

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

function setUpReward()
  if rewardType=="none" then
    return
  end
  scene.calcReward=rewardType=="timed" and countdownpoints.create(100,1000) or countdownpoints.create(200,1000)
end

function bankPoints()
  if headless or isStart or not scene.calcReward
    or not scene.bank or modesDropped>0 then
    return
  end
  local amount=scene.calcReward()
  scene.calcReward=nil
  if amount>0 then
    scene.bank:setScore(tonumber(scene.bank:getScore())+amount)
  end
end


function showMistakes()
  if updateMistakeDisplay then
    return
  end
  local group = display.newGroup()
  scene.view:insert(group)
  local t=display.newText({
    parent=group,
    text="Mistakes:",
    fontSize=30,
    align="center",
    font="Chunkfive.otf",
  })
  t.anchorX = 1
  t.x = -5
  t:setFillColor(0.478,0.918,0)

  t=display.newText({
    parent=group,
    text=0,
    fontSize=30,
    align="center",
    font="Chunkfive.otf",
  })
  t.anchorX = 0
  t.x = 5
  t:setFillColor(0.478,0.918,0)
  group.anchorChildren = true
  group.anchorX = 0
  group.anchorY = 0
  group:translate(5,5)

  function updateMistakeDisplay(num)
    t.text = num
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
        -- if rewardType~="none" then
          -- data.bank=tonumber(scene.bank:getScore())
        -- end
      end
      if not mistakeInLastTouches then
        if getIndex()==1 then
          countMistakes=true
        end
        bankPoints()
        if hasCompletedRound() then
          if data then
            data["practiceProgress"]="sequence completed"
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
      setUpReward()
      setupNextKeys()
    end,
    onMistake=function(allReleased,stepID,data)
      madeMistake()
      mistakeAnimation(self.redBackground)

      if data then
        data.mistakes=mistakesPerMode[modeIndex]
        data.lives=3-state.get("mistakes")
        -- if rewardType~="none" then
        --   data.bank=tonumber(scene.bank:getScore())
        -- end
        data.bank = 0
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

        -- if rewardType~="none" then
        --   data.bank=tonumber(scene.bank:getScore())
        -- end
        data.bank = 0
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
    local colour={0.25 * (i-1),0.125,0.125}

    for c = 1, #colour do
      colour[c] = (colour[c] + (c == (track + 1) and 1 or 0)) /2
    end

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

function scene:createProgressBar(totalRounds,barWidth,barHeight,strokeWidth)
  if self.progress then
    self.progress:removeSelf()
  end
  self.progress=display.newGroup()
  self.view:insert(self.progress)

  local x,y=display.contentCenterX,13
  self.progress.iconY=y+barHeight-strokeWidth

  local bg=display.newRect(self.progress,x,y,barWidth-strokeWidth,barHeight-strokeWidth)
  bg:setFillColor(0)
  bg:setStrokeColor(1)
  bg.strokeWidth=strokeWidth
  bg.anchorY=0
  local bg=display.newRect(self.progress,x,y+strokeWidth,barWidth-strokeWidth*2-2,barHeight-strokeWidth*4)
  bg:setFillColor(0)
  bg.strokeWidth=strokeWidth
  bg.anchorY=0

  local innerX=x-barWidth/2+bg.strokeWidth
  local innerY=bg.strokeWidth/2+y
  local innerWidth=barWidth-bg.strokeWidth*2
  for i=0,rounds-1 do
    local bar=display.newRect(self.progress,innerX+i*innerWidth/rounds,innerY,innerWidth/rounds,barHeight-bg.strokeWidth*2)
    bar:setFillColor(0.2*i)
    bar.anchorX=0
    bar.anchorY=0
  end

  local bar=display.newRect(self.progress,innerX,innerY,innerWidth,barHeight-bg.strokeWidth*2)
  bar:setFillColor(0,1,0)
  bar.anchorX=0
  bar.anchorY=0
  bar.isVisible=false

  self.progress.pointsY=bar.y+bar.height/2+4
  function self.progress:mark(i)
    bar.isVisible=true
    bar.xScale=i/totalRounds
  end

  for i=1, totalRounds do
    local line=display.newLine(self.progress, innerX+i*innerWidth/totalRounds, bar.y, innerX+i*innerWidth/totalRounds, bar.y+bar.height-bar.strokeWidth*3)
    line.strokeWidth=1
    line:setStrokeColor(0)
    line.alpha=0.4
  end

  for i=1,rounds-1 do
    local line=display.newLine(self.progress, innerX+i*innerWidth/rounds, bar.y, innerX+i*innerWidth/rounds, bar.y+bar.height-bar.strokeWidth*3)
    line.strokeWidth=3
    line:setStrokeColor(0.4)
  end
end

function scene:setUpPoints()
  self.points=display.newText({
    parent=self.view,
    text=0,
    fontSize=30,
    font="Chunkfive.otf",
  })
  self.points.anchorY=0.5
  self.points.x=self.img.x
  self.points.y=self.progress.pointsY
  self.points:toFront()

  if rewardType~="none" then
    self.bank=display.newGroup()
    self.view:insert(self.bank)
    self.bank:translate(self.img.x,self.img.y+self.img.contentHeight/2)
    self.bank.isVisible=false
    local text=display.newText({
      parent=self.bank,
      text=0,
      fontSize=30,
      font="Chunkfive.otf",
    })
    text:setFillColor(0.478,0.918,0)
    local bg=display.newImage(self.bank,"img/blurbox.png")
    bg:scale(1.4,1.4)
    text:toFront()

    function self.bank:setScore(v)
      logger.setBank(v)
      text.text=v
    end
    function self.bank:getScore()
      return text.text
    end
  end
end

function scene:show(event)
  if event.phase~="did" then
    return
  end
  rounds=event.params.rounds or 2
  maxLearningLength=event.params.iterations or 10
  learningLength=maxLearningLength
  -- composer.showOverlay("scenes.dataviewer")
  mistakesPerMode=_.rep(0,#modes)
  countMistakes=true

  isStart=event.params and event.params.intro
  startModeProgression=event.params and event.params.modeProgression
  headless=event.params and event.params.headless
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
  modeIndex=math.max(1,math.min(#modes,event.params and event.params.difficulty or 1))
  if headless then
    modeIndex=3
  else
    logger.setModeIndex(modeIndex)
  end

  self:setUpKeyLayers()
  self.cross:toFront()
  self.cross.isVisible=not isStart and not event.params.noQuit
  self.keyLayers:switchTo(modeIndex,true)

  local setTrack=event.params and event.params.track
  if setTrack=="random" then
    trackList=_.shuffle(_.append(_.rep(1,maxLearningLength/2),_.rep(2,maxLearningLength/2)))
    setTrack=table.remove(trackList, 1)
  else
    trackList=nil
  end

  vr.setup(20, 6)

  state=playstate.create()
  state.startTimer()
  modesDropped=0
  mistakesMadeThisRound = 0
  logger.setScore(0)
  logger.setIterations(state.get("iterations"))
  logger.setTotalMistakes(mistakesPerMode[modeIndex])
  logger.setLives(3-state.get("mistakes"))

  logger.setBank(0)
  logger.setModesDropped(modesDropped)
  logger.setProgress("start")

  if system.getInfo("environment")~="simulator" then
    self.keys:disable()
  end

  local practice=event.params and event.params.practice
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
  do
    local totalRounds=maxLearningLength*rounds
    local temp=stimuli.getStimulus(1)
    temp:scale(stimulusScale,stimulusScale)
    local barWidth=temp.contentWidth*2
    temp:removeSelf()
    local barHeight=40
    self:createProgressBar(totalRounds,barWidth,barHeight,2)
    self.progress.isVisible=not isStart
  end

  if isStart then
    if startModeProgression then
      sequence=modeProgressionSequence
    else
      sequence=startInstructions
    end
    logger.setTrack(-1)
  else
    switchSong(setTrack)
    -- if rewardType~="none" then
      -- self:setUpPoints()
    -- end
  end

  restart()
  setupNextKeys()
  setUpReward()

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
    self.points=nil
    self.deadMansSwitchGroup=nil
    self.deadSensor=nil
    self.calcReward=nil
    self.bank=nil
    self.progress=nil
    self.hint=nil
    updateMistakeDisplay = nil
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