local composer=require "composer"
local scene=composer.newScene()

local events=require "events"
local serpent=require "serpent"
local tunes=require "tunes"
local countdown=require "ui.countdown"
local keyeventslisteners=require "util.keyeventslisteners"
local notes=require "notes"
local keylayout=require "keylayout"
local tunemanager=require "tunemanager"
local progress=require "ui.progress"
local sound=require "sound"
local transition=transition
local display=display
local pairs=pairs
local print=print
local timer=timer
local tonumber=tonumber
local unpack=unpack
local NUM_KEYS=NUM_KEYS

setfenv(1,scene)

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local tuneLearning=event.params.tune
  local logFile=event.params.logInputFilename or "learntune"
  local startAdvanced=event.params.advanced
  local nextScene=event.params.nextScene or "scenes.practiceintro"
  local iterations=event.params.iterations or 20
  local img=tunemanager.getImg(tuneLearning)
  local noMistakes=event.params.noMistakes
  local discreteSequences=event.params.discreteSequences
  local corrections= not event.params.noCorrections
  local countSequences=not event.params.countAttempts
  local allowRestarts=event.params.canRestart

  scene.view:insert(img)
  img.anchorY=1
  img.x=display.contentCenterX
  img.y=display.contentCenterY-60

  local start=display.newText({
    parent=self.view,
    text="Get Ready!",
    fontSize=69,
    x=display.contentCenterX,
    y=img and (img.y-img.height-200) or display.contentCenterY
  })
  start:setFillColor(0)

  local counter=countdown.create(3*1000,80)
  counter:translate(display.contentCenterX,start.y+counter.height)
  counter:start()

  local circles={}
  do
    local cr=80
    local cpadding=50
    local ctw=cr*2*NUM_KEYS+cpadding*(NUM_KEYS-1)
    local x=display.contentCenterX-ctw/2+cr
    for i=1, NUM_KEYS do
      circles[i]=display.newCircle(scene.view,x,display.contentCenterY,cr)
      x=x+cr*2+cpadding
      circles[i]:setFillColor(0.2)
      circles[i]:setStrokeColor(0,1,0)

      local q=display.newText({
        parent=self.view,
        text="?",
        fontSize=200,
        x=circles[i].x,
        y=circles[i].y
      })
      circles[i].questionMark=q
      q.isVisible=false
    end
  end

  local tuneSteps=tunes.getTunes()[tuneLearning]
  local function highlightKeys(index,noLights,hints)
    if index==1 then
      keylayout.reset()
    end
    for i=1, NUM_KEYS do
      circles[i]:setFillColor(0.2)
      circles[i].strokeWidth=0
      circles[i].questionMark.isVisible=noLights
    end
    local instructions=tuneSteps[index]
    local scientficNotes=keylayout.layout(instructions)

    if noLights and not hints[index] then
      return
    end
    hints[index]=false
    local reverseKeys=composer.getVariable("left handed")
    for k,v in pairs(scientficNotes) do
      local note=notes.toNotePitch(v)
      local index=k
      if reverseKeys then
        index=NUM_KEYS-index+1
      end
      circles[index]:setFillColor(unpack(notes.getColour(notes.getIndex(note))))
      circles[index].strokeWidth=6
    end
  end

  transition.to(counter,{alpha=0,delay=2500,time=500,onComplete=function(obj) obj:removeSelf() end})

  self.timer=timer.performWithDelay(3000, function()
    self.timer=nil
    start.text="Go!"
    transition.to(start,{
      alpha=0,
      xScale=5,
      yScale=5,
      time=200,
      onComplete=display.remove
    })
    
    local meter=progress.create(img.contentWidth,60,{6})
    meter.x=display.contentCenterX
    meter.y=img.y-img.contentHeight-60
    self.view:insert(meter)

    local tuneCount=display.newGroup()
    self.view:insert(tuneCount)
    local t=display.newText({
      text=countSequences and "Completed Sequences:" or "Attempts Made:",
      fontSize=60,
      parent=tuneCount,
      x=display.contentCenterX,
      y=circles[1].y+circles[1].height/2+20
    })
    t.anchorY=0
    t:setFillColor(0)

    local count=display.newText({
      text=0,
      fontSize=100,
      parent=tuneCount,
      x=display.contentCenterX,
      y=t.y+t.height+10
    })
    count.anchorY=0
    count:setFillColor(0)

    local steps=1
    local advancedMode=startAdvanced
    local hints={}
    highlightKeys(steps,advancedMode,hints)
    local reset
    local canEnterSequence=not discreteSequences
    local function madeMistake()
      reset()
      sound.playSound("wrong")
      meter:reset()
      if corrections then
        hints[steps]=true
      end
      steps=1
      highlightKeys(steps,advancedMode,hints)
      local t=display.newText({
        text=canEnterSequence and "Mistake, start again!" or "Press space to start sequence",
        fontSize=120,
        parent=self.view,
        x=display.contentCenterX,
        y=count.y+count.height/2+10
      })
      t.anchorY=0
      t:setFillColor(1,0,0)
      local delete=function(obj)
        obj:removeSelf()
      end
      transition.to(t, {tag="mistake",alpha=0,onComplete=delete,onCancel=delete})
      canEnterSequence=not discreteSequences
    end

    local function checkEndOfTask(completed)
      if advancedMode and (
        (startAdvanced and completed==iterations) or
        (not startAdvanced and completed==iterations*2)) then
        composer.gotoScene(nextScene,{params={page=event.params.page}})
      elseif completed>=iterations then
        advancedMode=true
      end
    end

    local resetMeterTimer
    local function tuneCompleted(tune)
      canEnterSequence=not discreteSequences
      sound.playSound("correct")
      local n=tonumber(count.text)+1
      count.text=n
      steps=1

      checkEndOfTask(n)
     
      meter:mark(6,true)
      resetMeterTimer=timer.performWithDelay(250, function()
        resetMeterTimer=nil
        if meter.numChildren then
          meter:reset()
        end
      end)
      highlightKeys(steps,advancedMode,hints)
    end    

    local onPlay,onRelease,_r=keyeventslisteners.create({
      logName=logFile,
      allowWildCard=noMistakes,
      onTuneComplete=function(tune)
        if tune~=tuneLearning then
          madeMistake()
        else
          tuneCompleted(tune)
        end
      end,
      onMistake=madeMistake,
      onGoodInput=function(event)
        if not canEnterSequence then
          madeMistake()
          return
        end
        if resetMeterTimer then
          meter:reset()
          timer.cancel(resetMeterTimer)
          resetMeterTimer=nil
        end
        local isValid=noMistakes or event.complete
        if isValid and event.phase=="released" and event.allReleased then
          meter:mark(steps,true)
          steps=steps+1
          if steps>6 then
            if noMistakes then
              tuneCompleted(tuneLearning)
            end
            steps=1
          end
          highlightKeys(steps,advancedMode,hints)
        end
      end,
      getSelectedTune=function() return tuneLearning end,
    })
    reset=_r
    self.onRelease=onRelease
    self.onPlay=onPlay
    events.addEventListener("key played",onPlay)
    events.addEventListener("key released",onRelease)  
 
    if discreteSequences then
      self.onStartSequence=function()
        if not allowRestarts and steps>1 then
          return
        end
        if steps>1 and not countSequences then
          local n=tonumber(count.text)+1
          count.text=n
          checkEndOfTask(n)
        end
        canEnterSequence=true
        reset()
        meter:reset()
        steps=1
      end
      events.addEventListener("start sequence input", self.onStartSequence)
    end
  end)
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    if self.timer then
      timer.cancel(self.timer)
      self.timer=nil
    end
    if self.onPlay then
      events.removeEventListener("key played",self.onPlay)
      events.removeEventListener("key released",self.onRelease)
      self.onPlay=nil
      self.onRelease=nil
    end
  else
    for i=self.view.numChildren,1,-1 do
      self.view[i]:removeSelf()
    end
  end
end

scene:addEventListener("hide")

return scene