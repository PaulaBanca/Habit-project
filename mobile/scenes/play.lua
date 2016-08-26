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

setfenv(1,scene)

local song
local maxLearningLength=10
local learningLength=maxLearningLength
local track=1
local modes={"learning","recall","blind","invisible"}
local modeIndex=1
local isStart=false
local headless=false
local rewardType="none"
local modesDropped=0
local state
local intervalTime=5000
local intervalSpread=3000
local nextRewardTime
local roundStart

local startInstructions={
  "c4",
  "a4",
  "d4",
  "g4",
  {chord={"c3","e4","g4","c4"},forceLayout=true},
  {chord={"a3","c4","e4","a4"},forceLayout=true},
  {chord={"f3","a4","c4","f4"},forceLayout=true},
}

function setMaxLearningLength(v)
  maxLearningLength=v
  learningLength=maxLearningLength
end

local function switchSong(newTrack)
  if scene.img then
    scene.img:removeSelf()
  end
  track=newTrack or (track%2)+1
  local songs=tunes.getTunes()
  song=songs[track]
  local index=tunes.getStimulus(song)
  local img=stimuli.getStimulus(index)
  scene.view:insert(img)
  img.anchorY=0
  img:translate(display.contentCenterX, 0)
  img:scale(0.5,0.5)
  scene.img=img
  state=playstate.create()
  modesDropped=0
  logger.setScore(0)
  logger.setIterations(state.get("iterations"))
  logger.setBank(0)
  logger.setModesDropped(modesDropped)
    
  learningLength=maxLearningLength
  nextKey()
end

local function getIndex()
  return state.get("count")%#song+1
end

local function restart()
  if state.get("mistakes")>3 and modeIndex>1 and not headless then
    state:pushState()
    modeIndex=modeIndex-1
    scene.progress.isVisible=false
    scene.bg:setColour(modeIndex)
    
    learningLength=3
    modesDropped=modesDropped+1
    logger.setModesDropped(modesDropped)
    logger.setModeIndex(modeIndex)
    scene.keys:disable()
    scene.keys:clear()
    transition.to(scene.keys,{y=-scene.keys.height,
      onComplete=function(obj)
      obj:removeSelf() 
    end})
    scene.keys=nil
    scene:createKeys()
    scene.keys.alpha=0
    transition.to(scene.keys,{alpha=1})
  end

   if scene.bank then
    scene.bank.isVisible=false
    scene.bank:setScore(0)
    if scene.rewardPoints then
      scene.rewardPoints:removeSelf()
      scene.rewardPoints=nil
    end
  end

  roundStart=system.getTimer()
  state.restart()
  scene.keys:clear()
  nextKey()
end

local lastMistakeTime=0
local function madeMistake(bg)
  sound.playSound("wrong")
  local time=system.getTimer()
  if time-lastMistakeTime>500 then
    state.increment("mistakes")
    state.increment("total mistakes")
    logger.setTotalMistakes(state.get("total mistakes"))
    lastMistakeTime=time
  end
  state.startTimer()
  bg:toFront()
  bg.alpha=1
  transition.to(bg,{alpha=0})
  timer.performWithDelay(250,restart)
end

function nextKey()
  if scene.keys:hasPendingInstruction() then
    return
  end
  scene.keys:clear(true)
  if headless then
    return
  end
  
  state.increment()
  local index=getIndex()
  if index==1 and state.get("count")>0 then
    if not isStart and modesDropped==0 then
      state.increment("rounds")
      local rounds=state.get("rounds")
      if rounds<maxLearningLength*2 then
        scene.progress:mark(rounds,state.get("mistakes")==0)
      end
      
      if rewardType~="none" then
        local earned=tonumber(scene.bank:getScore())+tonumber(scene.rewardPoints:getPoints())
        if rewardType=="random" and math.random(100)>37 then
          earned=0
        end
     
        logger.setScore(tonumber(scene.points.text)+earned)
        logger.setSequenceTime(state.getTime())
        local t=display.newText({
          parent=scene.view,
          text=earned,
          fontSize=40,
        })
        t:setFillColor(0.478,0.918,0)
        t.x=scene.bank.x
        t.y=scene.bank.y
        
        scene.bank:setScore(0)
        scene.bank.isVisible=false
        if scene.rewardPoints then
          scene.rewardPoints:removeSelf()
          scene.rewardPoints=nil
        end
      
        transition.to(t,{xScale=1,yScale=1,x=scene.points.x,y=scene.points.y,anchorX=1,onComplete=function(obj)
          obj:removeSelf()
          if scene.points then
            scene.points.text=tonumber(scene.points.text)+earned
          end
        end})
      end
    end
    local p=display.newEmitter(particles.load("sequenceright"))
    p.blendMode="add"
    p:translate(display.contentCenterX, display.contentCenterY)
    sound.playSound("correct")
    transition.to(p, {time=2000,alpha=0,onComplete=function() 
      p:removeSelf()
    end})
    if state.get("rounds")==maxLearningLength*2 then
      practicelogger.logPractice(track)
      daycounter.completedPractice(track)
      timer.performWithDelay(600, function()
        composer.gotoScene("scenes.score",{params={score=tonumber(scene.points.text),track=track}})
      end)
      return 
    end
    if isStart then
      composer.gotoScene("scenes.schedule")
      return 
    else
      state.increment("iterations")
    end

    scene.keys:clear()
    if state.get("iterations")>=learningLength then
      state.clear("iterations")
      state.pullState()
      modeIndex=modeIndex+1
      if modeIndex>#modes then
        modeIndex=#modes
      end
      scene.bg:setColour(modeIndex)
    
      modesDropped=modesDropped-1
      if modesDropped<=0 then
        scene.progress.isVisible=true
        modesDropped=0
      end
      learningLength=modesDropped==0 and maxLearningLength or 3
      logger.setModesDropped(modesDropped)
      logger.setModeIndex(modeIndex)
      scene.keys:disable()
      transition.to(scene.keys,{y=display.contentHeight+scene.keys.height,
        onComplete=function(obj) 
        if obj.removeSelf then
          obj:removeSelf()
        end
      end})
      scene:createKeys()
      scene.keys.alpha=0
      transition.to(scene.keys,{alpha=1})
    end
    logger.setIterations(state.get("iterations"))
    state.clear("mistakes")
  end

  local nextIntruction=song[index]
  local targetKeys=scene.keys:setup(nextIntruction,modeIndex>1,modeIndex>2,track,index)

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

  if not headless and not isStart then
    if scene.rewardPoints then
      local amount=tonumber(scene.rewardPoints:getPoints())
      if scene.bank and amount>0 and modesDropped==0 then
        scene.bank:setScore(tonumber(scene.bank:getScore())+amount)
        
        -- scene.bank.isVisible=true
        -- local t=scene.rewardPoints:clonePoints()
        -- local x,y=t:localToContent(t.width/2, 0)
        -- scene.view:insert(t)
        -- t.x,t.y=x,y
        -- transition.to(t,{anchorX=0.5,xScale=2,yScale=2,x=scene.bank.x,y=scene.bank.y,alpha=0,onComplete=function(obj) 
        --   obj:removeSelf()
        -- end})
        -- timer.performWithDelay(1, function() t:toFront() end)
      end
      scene.rewardPoints:removeSelf()
    end
    if rewardType~="none" then
      scene.rewardPoints=rewardType=="timed" and countdownpoints.create(100,1000) or countdownpoints.create(200,1000)
      scene.rewardPoints.isVisible=false
      scene.rewardPoints:translate(scene.img.x,scene.img.y+scene.img.contentHeight/2+35)
      scene.view:insert(scene.rewardPoints)
      scene.redBackground:toFront()
      if modesDropped>0 then 
        scene.rewardPoints.isVisible=false
      end
    end
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
  if self.keyBounds then
    self.keyBounds:removeSelf()
  end
  local keys=keys.create(function(wasCorrect)
    if not wasCorrect then
      madeMistake(self.redBackground)
    else
      nextKey()
    end
  end,headless,isStart)
  if self.keys then
    self.keys:removeSelf()
  end
  self.view:insert(keys)
  self.keys=keys

  self.keyBounds=display.newGroup()
  self.view:insert(self.keyBounds)
  local xmin=self.keys.contentBounds.xMin
  local xmax=self.keys.contentBounds.xMax
  display.newRect(self.keyBounds,xmin/2,display.contentCenterY,xmin,display.contentHeight)
  local rw=display.contentWidth-xmax
  display.newRect(self.keyBounds,xmax+rw/2,display.contentCenterY,rw,display.contentHeight)
  self.keyBounds:toBack()

  for i=1, self.keyBounds.numChildren do
    self.keyBounds[i].fill.effect="generator.custom.stripes"
    self.keyBounds[i].blendMode="multiply"
  end
  self.bg:toBack()

  self.keys.isVisible=modeIndex<=3
  self.keys.isHitTestable=modeIndex>3
end

function scene:show(event)
  if event.phase=="did" then
    logger.stopCatchUp()
    isStart=event.params and event.params.intro
    headless=event.params and event.params.headless
    self.onClose=event.params and event.params.onClose
    rewardType=event.params and event.params.rewardType or "none"
    if headless then
      rewardType="none"
    end
    modeIndex=math.max(1,math.min(#modes,event.params and event.params.difficulty or 1))
    if headless then
      modeIndex=3
    else
      logger.setModeIndex(modeIndex)
    end
    scene.bg:setColour(modeIndex)
    scene:createKeys()

    learningLength=maxLearningLength
    switchSong(event.params and event.params.track)
    song=isStart and startInstructions or song
    if isStart or headless then
      scene.img.isVisible=false
      scene.progress.isVisible=false
    end

    logger.setIntro(isStart or false)
    logger.setSequenceTime(0)

    restart()
    if not isStart and rewardType~="none" then
      scene.points=display.newText({
        parent=scene.view,
        text=0,
        x=display.contentWidth*3/4,
        y=20,
        fontSize=40
      })
      scene.points.anchorX=1

      if rewardType~="none" then
        scene.bank=display.newGroup()
        scene.view:insert(scene.bank)
        scene.bank:translate(scene.img.x,scene.img.y+scene.img.contentHeight/2)
        scene.bank.isVisible=false
        local text=display.newText({
          parent=scene.bank,
          text=0,
          fontSize=40,
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
    state=playstate.create()
    local p=progress.create(200,40,{maxLearningLength,maxLearningLength})
    p.anchorChildren=true
    p.anchorX=0
    p.anchorY=0
    p:translate(20,20)
    self.view:insert(p)
    self.progress=p
  end
end

function scene:hide(event)
  if event.phase=="did" then
    logger.startCatchUp()
    
    self.progress:removeSelf()
    self.progress=nil
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

return scene