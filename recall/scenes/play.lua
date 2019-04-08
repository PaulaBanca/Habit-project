local composer=require "composer"
local scene=composer.newScene()

local sound=require "sound"
local particles=require "particles"
local tunes=require "tunes"
local stimuli=require "stimuli"
local keys=require "keys"
local playlayout=require "playlayout"
local chordbar=require "ui.chordbar"
local background=require "ui.background"
local playstate=require "playstate"
local logger=require "logger"
local keysparks=require "ui.keysparks"
local button=require "ui.button"
local progress=require "ui.progress"
local _=require "util.moses"
local events=require "events"
local serpent=require "serpent"
local display=display
local transition=transition
local easing=easing
local system=system
local timer=timer
local table=table
local print=print
local NUM_KEYS=NUM_KEYS

setfenv(1,scene)

local sequence
local maxLearningLength=10
local rounds=2
local track=1
local headless=false
local state
local nextScene
local isScheduledPractice
local trackList
local stimulusScale=0.35
local lastMistakeIndex

local function switchSong(newTrack)
  local x,y=display.contentCenterX, 53
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
  scene:itiScreen(function() end)
end

local function roundCompleteAnimation()
  local p=display.newEmitter(particles.load("sequenceright"))
  p.blendMode="add"
  scene.view:insert(p)
  p:translate(display.contentCenterX, display.contentCenterY)
  sound.playSound("correct")

  local t=transition.to(p, {time=2000,alpha=0,onComplete=function()
    p:removeSelf()
  end})
  function p:finalize()
    transition.cancel(t)
  end
  p:addEventListener("finalize")
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

local function restart(onReady)
  state.restart()
  scene.keys:clear()
  scene.stepProgresBar:reset()
  scene:setRestartButtonVisibility(false)
  logger.setProgress("restart")

  scene:itiScreen(onReady)
end

local function madeMistake()
  local index=getIndex()
  if index==lastMistakeIndex then
    return
  end
  lastMistakeIndex=index
  scene.highlight[index]=true
  state.increment("mistakes")
  events.fire({type='mistake',total=state.get('mistakes')})
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

  lastMistakeIndex=nil

  state.increment("rounds")
  local rounds=state.get("rounds")
  if rounds==maxLearningLength then
    logger.setProgress("midpoint")
  end

  state.startTimer()

  state.increment("iterations")
  state.clear("mistakes")

  scene.keys:clear()
  scene:setRestartButtonVisibility(false)

  logger.setIterations(state.get("iterations"))
  roundCompleteAnimation()
end

function proceedToNextStep()
  scene.keys:clear(true)
  state.increment()
end

function hasCompletedTask()
  return state.get("rounds")==maxLearningLength*rounds
end

function completeTask()
  if not hasCompletedTask() then
    return
  end
  if state.get("rounds")==maxLearningLength*rounds then
    scene.keys:removeSelf()
    if isScheduledPractice then

    end
    timer.performWithDelay(600, function()

      local function gotoNextScene()
        events.fire({type='phase finished'})
        composer.gotoScene(nextScene,{params={
          track=track}
        })
        composer.hideOverlay()
      end

      if scene.phase:sub(1,1)=='B' then
        composer.showOverlay('scenes.feedbacksimple',{
          params={
            feedback=scene.presses,
            onComplete=gotoNextScene
          }
        })
      else
        gotoNextScene()
      end
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
  logger.setTotalMistakes(state.get("mistakes"))

  local index=getIndex()
  local nextIntruction=sequence[index]
  local noAid,noFeedback,noHighlight=true,true,true

  if scene.phase=='B2' then
    noFeedback=false
  end
  if scene.phase:sub(1,1)=='C' then
    noFeedback=false
    noAid=not scene.highlight[getIndex()]
    noHighlight=noAid
  end

  local targetKeys=scene.keys:setup(nextIntruction,noAid,noFeedback,noHighlight,index,state.get("stepID"),true)

  do
    local pattern={}
    for i=1, NUM_KEYS do
      pattern[i]=targetKeys[i] and "1" or "0"
    end
    logger.setCorrectKeys(table.concat(pattern, ""))
  end

  display.remove(scene.chordBar)
  scene.chordBar=nil

  local createChordBar=not noAid
  if createChordBar then
    local chordBar=chordbar.create(targetKeys)
    if chordBar then
      chordBar:translate(0,-scene.keys:getKeyHeight()/2)
      scene.chordBar=chordBar
      scene.view:insert(chordBar)
      chordBar:toBack()
    end
  end
end

function scene:create(event)
  local bg=background.create()
  bg:setColour(1)
  scene.view:insert(bg)
  scene.bg=bg

  bg:addEventListener("tap",function(event)
    if self.startButtonTimer then
      return true
    end
    local wrong=display.newCircle(scene.view,event.x,event.y,10)
    wrong:setFillColor(1,0,0)
    wrong:toBack()
    bg:toBack()
    transition.to(wrong,{alpha=0,delay=500,onComplete=display.remove})
  end)

  bg:addEventListener('touch', function()
    return true
  end)

  local circle=display.newCircle(self.view, playlayout.CX, playlayout.CY, playlayout.RADIUS)
  circle:setFillColor(1,1,1, 0.2)
  circle.xScale=playlayout.ELIPSE_XSCALE

  local redBackground=display.newRect(
    scene.view,
    display.contentCenterX,
    display.contentCenterY,
    display.contentWidth,
    display.contentHeight)
  redBackground.fill.effect="generator.custom.pattern"
  redBackground:setFillColor(1,0,0)
  redBackground.alpha=0
  self.redBackground=redBackground
  self:createRestartButton()
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
      self:setRestartButtonVisibility(self.allowRestarts)
      logger.setProgress('')
      if data then
        data.phase=self.phase
      end
      local roundComplete=hasCompletedRound()
      if not mistakeInLastTouches then
        self.presses[getIndex()]=self.presses[getIndex()] or {}
        self.highlight[getIndex()]=false
        self.stepProgresBar:mark(getIndex(),true)
        if roundComplete then
          if data then
            data["practiceProgress"]="sequence completed"
          end

          completeRound()

          scene.stepProgresBar:toFront()
          transition.to(scene.stepProgresBar,{
            delay=100,
            time=200,
            xScale=0,
            transition=easing.inOutQuart,
            onComplete=function()
              scene.stepProgresBar:reset()
              scene.stepProgresBar:toBack()
              scene.stepProgresBar.xScale=1
            end
          })

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
        proceedToNextStep()
      end
      mistakeInLastTouches=false
      if scene.phase:sub(1,1)=='B' and roundComplete then
        composer.showOverlay('scenes.feedbacksimple',{
          params={
            feedback=scene.presses,
            onComplete=function()
              scene:itiScreen(function(feedback)
                setupNextKeys()
                self.presses={}
              end)
            end
          }
        })
      elseif roundComplete then
        scene:itiScreen(setupNextKeys)
      else
        setupNextKeys()
      end
    end,
    onMistake=function(allReleased,stepID,data)
      madeMistake()
      if data then
        data.instructionIndex=getIndex()
        data.mistakes=state.get("mistakes")
      end

      if self.phase:sub(1,1)=='B' then
        local setPresses=self.presses[getIndex()] or {}
        setPresses[data.keyIndex]=false
        self.presses[getIndex()]=setPresses
      end
      if self.phase:sub(1,1)~='C' then
        return
      end
      scene.stepProgresBar:reset()
      logger.setRestartForced('mistake')
      logger.setProgress('restart')
      mistakeAnimation(self.redBackground)
      restart(function() end)

      mistakeInLastTouches=true
    end,
    onKeyRelease=function (data)
      data.mistakes=state.get("mistakes")
      data.millisSincePhaseStart=system.getTimer()-self.phaseStartMillis
    end,
    onKeyPress=function(data)
      if not data then
        return
      end
      local setPresses=self.presses[getIndex()] or {}

      setPresses[data.keyIndex]=data.wasCorrect
      self.presses[getIndex()]=setPresses
      data.phase=self.phase
      data.millisSincePhaseStart=system.getTimer()-self.phaseStartMillis
      data.hint=self.phase:sub(1,1)=='C' and self.highlight[getIndex()] or false
      data.mistakes=state.get("mistakes")
      logger.setRestartForced(false)
    end
  },
  false)

  group:insert(ks)

  function group:getKeys()
    return ks
  end
  return group
end

function scene:createRestartButton()
  self.restartButton=display.newImage(self.view,'img/restart.png')
  self.restartButton:scale(0.25,0.25)
  self.restartButton.anchorX=1
  self.restartButton.anchorY=0
  self.restartButton.x=display.contentWidth-20
  self.restartButton.y=20
  self.restartButton.isVisible=false

  self.restartSensor=display.newCircle(
    self.view,
    self.restartButton.x-self.restartButton.contentWidth/2,
    self.restartButton.y+self.restartButton.contentHeight/2,
    self.restartButton.contentHeight)
  self.restartSensor.isVisible=false
  self.restartSensor.isHitTestable=false

  self.restartSensor:addEventListener('tap', function()
    state.clear("mistakes")
    lastMistakeIndex=nil
    logger.setRestartForced(true)
    restart(setupNextKeys)
  end)
end

function scene:setRestartButtonVisibility(bool)
  self.restartButton.isVisible=bool
  self.restartSensor.isHitTestable=bool
end

function scene:itiScreen(onEnd)
  if self.hasStartButton then
    self.bg:toFront()
    if self.stepProgresBar then
      self.stepProgresBar:toFront()
    end
    self.startButtonTimer=timer.performWithDelay(1000, function()
      self.startButtonTimer=nil
      self.bg:toBack()
      onEnd()
    end)
  end
end

function scene:show(event)
  if event.phase~="did" then
    return
  end

  local params=event.params or {}

  rounds=params.rounds or 2
  maxLearningLength=params.iterations or 10
  learningLength=maxLearningLength
  -- composer.showOverlay("scenes.dataviewer")

  startModeProgression=params.modeProgression
  headless=params.headless
  self.onClose=params.onClose
  rewardType=params.rewardType or "none"
  nextScene=params.nextScene or "scenes.score"
  isScheduledPractice=params.isScheduledPractice
  self.hasStartButton=params.requireStartButton
  self.loggingPhase=params.loggingPhase
  self.phase=params.phase

  self.allowRestarts=params.allowRestarts

  local setTrack=params.track

  self.highlight={}
  self.presses={}

  state=playstate.create()
  state.startTimer()
  logger.setIterations(state.get("iterations"))
  logger.setTotalMistakes(state.get("mistakes"))
  logger.setRestartForced(false)

  logger.setProgress("start")

  local keyGroup=self:createKeys()
  self.view:insert(keyGroup)
  self.keys=keyGroup:getKeys()
  if system.getInfo("environment")~="simulator" then
    self.keys:disable()
  end

  self.keys:enable()
  do
    local temp=stimuli.getStimulus(1)
    temp:scale(stimulusScale,stimulusScale)
    temp:removeSelf()
    local barWidth=temp.contentWidth*2
    local barHeight=40
    display.remove(self.stepProgresBar)
    self.stepProgresBar=progress.create(barWidth,barHeight,{6})
    local x,y=display.contentCenterX,13
    self.stepProgresBar:translate(x, y+barHeight/2)
    self.view:insert(self.stepProgresBar)
  end

  self.phaseStartMillis=system.getTimer()
  switchSong(setTrack)
  restart(setupNextKeys)
  logger.setProgress('phase start')
  logger.setFeedbackPattern('n/a')
end

function scene:hide(event)
  if event.phase=="will" then
    if self.startButtonTimer then
      timer.cancel(self.startButtonTimer)
    end
  end
  if event.phase=="did" then
    keysparks.clear()
    for i=self.view.numChildren,1,-1 do
      if not self.view[i].doNotRemoveOnHide then
        self.view[i]:removeSelf()
      end
    end
    self.keyLayers=nil
    self.keys=nil
    self.img=nil
    self.progress=nil
    self.chordBar=nil
  end
end

scene:addEventListener("create")
scene:addEventListener("show")
scene:addEventListener("hide")

return scene