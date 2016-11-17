local composer=require "composer"
local scene=composer.newScene()

local sound=require "sound"
local particles=require "particles"
local clientloop=require "clientloop"
local tunes=require "tunes"
local stimuli=require "stimuli"
local progress=require "ui.progress"
local keys=require "keys"
local playlayout=require "playlayout"
local practicelogger=require "practicelogger"
local chordbar=require "ui.chordbar"
local countdownpoints=require "ui.countdownpoints"
local randompoints=require "ui.randompoints"
local background=require "ui.background"
local playstate=require "playstate"
local daycounter=require "daycounter"
local logger=require "logger"
local deadmansswitch=require "ui.deadmansswitch"
local _=require "util.moses"
local unpack=unpack
local display=display
local math=math
local print=print
local transition=transition
local system=system
local timer=timer
local tostring=tostring
local table=table
local easing=easing
local tonumber=tonumber
local Runtime=Runtime
local pairs=pairs

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
local totalMistakes=0
local modesDropped=0
local state
local intervalTime=5000
local intervalSpread=3000
local nextRewardTime
local nextScene

local startInstructions={
  {chord={"c4","none","none","none"},forceLayout=true},
  {chord={"none","a4","none","none"},forceLayout=true},
  {chord={"none","none","d4","none"},forceLayout=true},
  {chord={"none","none","none","g4"},forceLayout=true},
  {chord={"c3","e4","g4","c4"},forceLayout=true},
  {chord={"a3","c4","e4","a4"},forceLayout=true},
  {chord={"f3","a4","c4","f4"},forceLayout=true},
}

local modeProgressionSequence={
  {chord={"c4","none","none","none"},forceLayout=true},
  {chord={"none","a4","none","none"},forceLayout=true},
  {chord={"none","none","d4","none"},forceLayout=true},
  {chord={"none","none","none","g4"},forceLayout=true},
}

local function switchSong(newTrack)
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
  img:translate(display.contentCenterX, 0)
  img:scale(0.5,0.5)
  scene.img=img
  logger.setTrack(track)
end

local function roundCompleteAnimation()
  local p=display.newEmitter(particles.load("sequenceright"))
  p.blendMode="add"
  p:translate(display.contentCenterX, display.contentCenterY)
  sound.playSound("correct")
  transition.to(p, {time=2000,alpha=0,onComplete=function() 
    p:removeSelf()
  end})
end

local function keyChangeAnimation()
  scene.keys:disable()
  scene.keyLayers:switchTo(modeIndex)
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
  if scene.rewardPoints then
    scene.rewardPoints:removeSelf()
    scene.rewardPoints=nil
  end
end

local function shouldDropModeDown()
  return state.get("mistakes")>3 and modeIndex>1 and not headless and not isStart
end

local function dropModeDown()
  state.clear("mistakes")
  lastMistakeTime=system.getTimer()
  state:pushState()
  modeIndex=modeIndex-1
  scene.progress.isVisible=false
  
  learningLength=3
  modesDropped=modesDropped+1
  logger.setModesDropped(modesDropped)
  logger.setModeIndex(modeIndex)
  logger.setIterations(state.get("iterations"))

  scene.keys:disable()
  keyChangeAnimation()
end

local function restart()
  resetBank()

  state.restart()
  scene.keys:clear()
end

local countMistakes
local lastMistakeTime=system.getTimer()
local function madeMistake(bg)
  sound.playSound("wrong")
  local time=system.getTimer()
  if time-lastMistakeTime>500 then 
    state.increment("mistakes")
    lastMistakeTime=time
  end
  if countMistakes then
    countMistakes=false
    totalMistakes=totalMistakes+1
    logger.setTotalMistakes(totalMistakes)
  end
  state.startTimer()
  
  bg:toFront()
  bg.alpha=1
  transition.to(bg,{alpha=0})

  local modesDropped=shouldDropModeDown()
  if modesDropped then
    dropModeDown()
  end

  restart()
  return modesDropped
end

local function processBank()
  if rewardType=="none" then
    return
  end
  local earned=tonumber(scene.bank:getScore())
  if rewardType=="random" and math.random(100)>37 then
    earned=0
  end

  logger.setScore(tonumber(scene.points.text)+earned)
  local t=display.newText({
    parent=scene.view,
    text=earned,
    fontSize=40,
    align="center",
    font="Chunkfive.otf",
  })
  t:scale(4,4)
  t:setFillColor(0.478,0.918,0)
  t.x=scene.img.x
  t.y=scene.img.y+scene.img.height/2
  
  scene.bank:setScore(0)
  scene.bank.isVisible=false

  transition.to(t,{xScale=1,yScale=1,x=scene.points.x,y=scene.points.y,anchorX=1,onComplete=function(obj)
    obj:removeSelf()
    if scene.points then
      scene.points.text=tonumber(scene.points.text)+earned
    end
  end})
end

local function shouldChangeModeUp()
  return state.get("iterations")>=learningLength
end  

local function changeModeUp()
  state.pullState()
  state.clear("mistakes")

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
    scene.progress.isVisible=true
    modesDropped=0
  end 
  learningLength=modesDropped==0 and maxLearningLength or 3
  logger.setModesDropped(modesDropped)
  logger.setModeIndex(modeIndex)
  keyChangeAnimation()
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

  if not isStart and modesDropped==0 then
    state.increment("rounds")
    local rounds=state.get("rounds")
    if rounds<maxLearningLength*2 then
      scene.progress:mark(rounds,state.get("mistakes")==0)
    end
    processBank()
  end

  roundCompleteAnimation()
  state.startTimer()

  state.increment("iterations")
  state.clear("mistakes")
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
      daycounter.completedPractice(track)
    end
    timer.performWithDelay(600, function()
      composer.gotoScene(nextScene,{params={
        score=rewardType~="none" and tonumber(scene.points.text),
        track=track}
      })
      composer.hideOverlay()
    end)
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
end

function setUpReward()
  if rewardType=="none" then
    return 
  end
  scene.rewardPoints=rewardType=="timed" and countdownpoints.create(100,1000) or countdownpoints.create(200,1000)
  scene.rewardPoints.isVisible=false
  scene.rewardPoints:translate(scene.img.x,scene.img.y+scene.img.contentHeight/2+35)
  scene.view:insert(scene.rewardPoints)
  scene.redBackground:toFront()
  if modesDropped>0 then 
    scene.rewardPoints.isVisible=false
  end
end

function bankPoints()
  if headless or isStart or not scene.rewardPoints 
    or not scene.bank or modesDropped>0 then
    return
  end
  local amount=tonumber(scene.rewardPoints:getPoints())
  if amount>0 then
    scene.bank:setScore(tonumber(scene.bank:getScore())+amount)
    scene.rewardPoints:removeSelf()
    scene.rewardPoints=nil
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
      obj:removeSelf()
    end})
  end)

  local cross=display.newImage(self.view,"img/cross.png")
  cross.anchorX=1
  cross.anchorY=0
  cross.x=display.contentWidth-20
  cross.y=20
  cross:scale(0.5,0.5)

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
end

function scene:createKeys()
  local mistakeInLastTouches=false
  local group=display.newGroup()
  local ks=keys.create(function(stepID,data)
    if stepID and stepID~=state.get("stepID") then
      return
    end
    if not mistakeInLastTouches then
      if getIndex()==1 then
        countMistakes=true 
      end
      bankPoints()
      if hasCompletedRound() then
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
    if data then
      if rewardType~="none" then
        data.bank=tonumber(scene.bank:getScore())
      end
    end
    setupNextKeys()
  end,function(allReleased,stepID,data)
    if madeMistake(self.redBackground) then
      mistakeInLastTouches=false
      setupNextKeys()
    else
      mistakeInLastTouches=true
    end
    if data then
      data.mistakes=totalMistakes
      if rewardType~="none" then
        data.bank=tonumber(scene.bank:getScore())
      end
    end  
  end,headless,isStart)
  
  local keyBounds=display.newGroup()
  group:insert(keyBounds)
  local xmin=ks.contentBounds.xMin
  local xmax=ks.contentBounds.xMax
  display.newRect(keyBounds,xmin/2,display.contentCenterY,xmin,display.contentHeight)
  local rw=display.contentWidth-xmax
  display.newRect(keyBounds,xmax+rw/2,display.contentCenterY,rw,display.contentHeight)
  keyBounds:toBack()

  for i=1, keyBounds.numChildren do
    keyBounds[i].fill.effect="generator.custom.stripes"
    keyBounds[i].blendMode="multiply"
  end
  group:insert(ks)

  function group:getKeys()
    return ks
  end
  return group
end

function scene:setUpKeyLayers()
  local layers=display.newGroup()
  self.view:insert(layers)
  for i=1,#modes do
    local group=display.newContainer(layers, display.actualContentWidth, display.actualContentHeight)
    group.anchorChildren=true
    local strokeWidth=8
    local bg=display.newRect(group,0,0,display.actualContentWidth-strokeWidth,display.actualContentHeight-strokeWidth)
    local colour={0.5,0.5,0.5}
    if i>#colour then
      colour={0,0.5,0} 
    else
      colour[i]=0
    end
    bg:setFillColor(unpack(colour))
    bg.blendMode="multiply"
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
      text="Layer ",
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
  rounds=event.params.rounds or 2
  maxLearningLength=event.params.iterations or 10
    
  if event.phase=="did" then
    -- composer.showOverlay("scenes.dataviewer")
    totalMistakes=0
    countMistakes=true

    isStart=event.params and event.params.intro
    startModeProgression=event.params and event.params.modeProgression
    headless=event.params and event.params.headless
    self.onClose=event.params and event.params.onClose
    rewardType=event.params and event.params.rewardType or "none"
    nextScene=event.params and event.params.nextScene or "scenes.score"
    isScheduledPractice=event.params and event.params.isScheduledPractice
    logger.setIsScheduled(isScheduledPractice or false)
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

    scene:setUpKeyLayers()
    if self.progress then
      self.progress:toFront()
    end
    self.cross:toFront()
    self.cross.isVisible=not isStart
    scene.keyLayers:switchTo(modeIndex,true)
   
    local setTrack=event.params and event.params.track
    if setTrack=="random" then
      trackList=_.shuffle(_.append(_.rep(1,maxLearningLength/2),_.rep(2,maxLearningLength/2)))
      setTrack=table.remove(trackList, 1)
    end
    switchSong(setTrack)

    state=playstate.create()
    state.startTimer()
    modesDropped=0
    totalMistakes=0
    logger.setScore(0)
    logger.setIterations(state.get("iterations"))
    logger.setTotalMistakes(totalMistakes)
    logger.setBank(0)
    logger.setModesDropped(modesDropped)

    if isStart then
      if startModeProgression then
        sequence=modeProgressionSequence
      else
        sequence=startInstructions
      end
    end
    if isStart or headless then
      scene.img.isVisible=false
      scene.progress.isVisible=false
    end

    logger.setIntro(isStart or false)

    restart()
    setupNextKeys()
    setUpReward()

    deadmansswitch.start(function() 
      if hasCompletedTask() then
        return
      end
      madeMistake(self.redBackground)
      setupNextKeys()
    end)
    if not isStart and rewardType~="none" then
      scene.points=display.newText({
        parent=scene.view,
        text=0,
        x=display.contentWidth-self.cross.width,
        y=20,
        fontSize=40,
        font="Chunkfive.otf",
      })
      scene.points.anchorX=1
      scene.points:translate(0, 16)

      if rewardType~="none" then
        scene.bank=display.newGroup()
        scene.view:insert(scene.bank)
        scene.bank:translate(scene.img.x,scene.img.y+scene.img.contentHeight/2)
        scene.bank.isVisible=false
        local text=display.newText({
          parent=scene.bank,
          text=0,
          fontSize=40,
          font="Chunkfive.otf",
        })
        text:setFillColor(0.478,0.918,0)
        local bg=display.newImage(scene.bank,"img/blurbox.png")
        bg:scale(1.4,1.4)
        text:toFront()

        function scene.bank:setScore(v)
          logger.setBank(v)
          text.text=v
        end
        function scene.bank:getScore()
          return text.text
        end
      end
    end
  else
    local p=progress.create(200,40,_.rep(maxLearningLength,rounds))
    p.anchorChildren=true
    p.anchorX=0
    p.anchorY=0
    p:translate(20,20)
    self.view:insert(p)
    self.progress=p
  end
end

function scene:hide(event)
  if event.phase=="will" then
    deadmansswitch.stop()
  end
  if event.phase=="did" then
    logger.startCatchUp()
    
    self.progress:removeSelf()
    self.progress=nil
    self.keyLayers:removeSelf()
    self.keyLayers=nil
    self.keys=nil
    if self.points then
      self.points:removeSelf()
      self.points=nil
    end
    if self.rewardPoints then
      self.rewardPoints:removeSelf()
      self.rewardPoints=nil
    end
    if self.bank then
      self.bank:removeSelf()
      self.bank=nil
    end
  end
end

scene:addEventListener("create")
scene:addEventListener("show")
scene:addEventListener("hide")

Runtime:addEventListener("system", function (event)
  if event.type=="applicationResume" then
    composer.gotoScene("scenes.schedule")
    logger.startCatchUp()
  end
end)

return scene