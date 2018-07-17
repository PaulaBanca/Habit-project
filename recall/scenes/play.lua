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
local display=display
local transition=transition
local system=system
local timer=timer
local table=table

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
  scene:switchOnStartButton()
  scene.sequenceStartMillis=system.getTimer()
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

local lastMistakeTime=system.getTimer()
local function restart()
  state.restart()
  scene.keys:clear()
  scene:switchOnStartButton()
  scene.stepProgresBar:reset()
end

local countMistakes
local function madeMistake()
  scene.highlight[getIndex()]=true
  local time=system.getTimer()
  if time-lastMistakeTime>500 then
    state.increment("mistakes")
    lastMistakeTime=time
    events.fire({type='mistake',total=state.get('mistakes')})
  end
  if countMistakes then
    countMistakes=false
  end
end

function hasCompletedRound()
  local index=getIndex()
  return index==#sequence and state.get("count")>0
end


function completeRound()
  if scene.keys:hasPendingInstruction() then
    return
  end
  if headless then
    return
  end
  if not hasCompletedRound() then
    return
  end

  state.increment("rounds")
  local rounds=state.get("rounds")
  if rounds==maxLearningLength then
    logger.setProgress("midpoint")
  end

  state.startTimer()

  state.increment("iterations")
  state.clear("mistakes")
  logger.setLives(3-state.get("mistakes"))

  scene.keys:clear()

  logger.setIterations(state.get("iterations"))
  scene:switchOnStartButton()
  roundCompleteAnimation()
  scene.sequenceStartMillis=system.getTimer()
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
      events.fire({type='phase finished'})
      composer.gotoScene(nextScene,{params={
        track=track}
      })
      composer.hideOverlay()
    end)
    return true
  end
end

function setupNextKeys()
  if scene.keys:hasPendingInstruction() or headless then
    return
  end

  scene.keys:enable()
  state.increment("stepID")
  local index=getIndex()
  local nextIntruction=sequence[index]
  local noAid,noFeedback,noHighlight=true,true,true
  local sequencesPlayed=state.get("rounds")
  if scene.phase=='B' and sequencesPlayed>=maxLearningLength then
    noFeedback=false
  end
  if scene.phase=='C' then
    noFeedback=false
    noAid=not scene.highlight[getIndex()]
    noHighlight=noAid
  end

  local targetKeys=scene.keys:setup(nextIntruction,noAid,noFeedback,noHighlight,index,state.get("stepID"),true)

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
    if self.startButton.isVisible then
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
  self.startButton=button.create('Start','use',function()
    self.startButton.isVisible=false
    self.bg:toBack()
    self.sequenceStartMillis=system.getTimer()
    return true
  end)
  self.startButton:translate(display.contentCenterX,display.contentCenterY/2)
  self.view:insert(self.startButton)

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
        data.phase=self.phase
      end
      local roundComplete=hasCompletedRound()
      if not mistakeInLastTouches then
        self.presses[getIndex()]=self.presses[getIndex()] or {}
        self.highlight[getIndex()]=false
        self.stepProgresBar:mark(getIndex(),true)
        if getIndex()==1 then
          countMistakes=true
        end
        if roundComplete then
          if data then
            data["practiceProgress"]="sequence completed"
          end

          completeRound()
          scene.stepProgresBar:reset()

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
      if scene.phase=='B' and roundComplete then
        composer.showOverlay('scenes.feedbacksimple',{
          params={
            feedback=scene.presses,
            onComplete=function()
              setupNextKeys()
              self.presses={}
            end
          }
        })
      else
        setupNextKeys()
      end
    end,
    onMistake=function(allReleased,stepID,data)
      madeMistake()
      if data then
        data.instructionIndex=getIndex()
      end
      if self.phase=='B' then
        local setPresses=self.presses[getIndex()] or {}
        setPresses[data.keyIndex]=false
        self.presses[getIndex()]=setPresses
      end
      if self.phase~='C' then
        return
      end
      scene.stepProgresBar:reset()

      if data then
        data.mistakes=state.get("mistakes")
        data.lives=3-state.get("mistakes")
      end

      mistakeAnimation(self.redBackground)
      restart()

      mistakeInLastTouches=true
    end,
    onKeyRelease=function (data)
      data.mistakes=state.get("mistakes")
      data.lives=3-state.get("mistakes")
      data.millisSinceStart=system.getTimer()-self.sequenceStartMillis
    end,
    onKeyPress=function(data)
      if not data then
        return
      end
      local setPresses=self.presses[getIndex()] or {}
      setPresses[data.keyIndex]=data.wasCorrect
      self.presses[getIndex()]=setPresses
      data.phase=self.phase
      data.millisSinceStart=system.getTimer()-self.sequenceStartMillis
      data.hint=self.phase=='C' and self.highlight[getIndex()]
    end
  },
  false)

  group:insert(ks)

  function group:getKeys()
    return ks
  end
  return group
end

function scene:switchOnStartButton()
  if self.hasStartButton then
    self.startButton.isVisible=true
    self.bg:toFront()
    self.startButton:toFront()
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
  countMistakes=true

  startModeProgression=params.modeProgression
  headless=params.headless
  self.onClose=params.onClose
  rewardType=params.rewardType or "none"
  nextScene=params.nextScene or "scenes.score"
  isScheduledPractice=params.isScheduledPractice
  self.hasStartButton=params.requireStartButton
  self.startButton.isVisible=self.hasStartButton
  logger.setIsScheduled(isScheduledPractice or false)
  self.phase=params.phase

  local setTrack=params.track

  self.highlight={}
  self.presses={}

  state=playstate.create()
  state.startTimer()
  logger.setScore(0)
  logger.setIterations(state.get("iterations"))
  logger.setTotalMistakes(state.get("mistakes"))
  logger.setLives(3-state.get("mistakes"))

  logger.setBank(0)
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

  switchSong(setTrack)

  restart()
  setupNextKeys()
end

function scene:hide(event)
  scene.startButton:toFront()
  if event.phase=="will" then
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