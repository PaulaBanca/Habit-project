local composer=require "composer"
local scene=composer.newScene()

local server=require "server"
local events=require "events"
local serpent=require "serpent"
local tunes=require "tunes"
local stimuli=require "stimuli"
local countdown=require "ui.countdown"
local keyeventslisteners=require "util.keyeventslisteners"
local notes=require "notes"
local keylayout=require "keylayout"
local tunemanager=require "tunemanager"
local progress=require "ui.progress"
local sound=require "sound"
local transition=transition
local display=display
local table=table
local pairs=pairs
local print=print
local timer=timer
local tonumber=tonumber
local next=next
local unpack=unpack
local NUM_KEYS=NUM_KEYS

setfenv(1,scene)

local tns=tunes.getTunes()
local stim={}
for i=1,#tns do
  stim[i]=tunes.getStimulus(tns[i])
end

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local tuneLearning=event.params.tune
  local img=tunemanager.getImg(tuneLearning)
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
    for k,v in pairs(scientficNotes) do
      local note=notes.toNotePitch(v)
      circles[k]:setFillColor(unpack(notes.getColour(notes.getIndex(note))))
      circles[k].strokeWidth=6
    end
  end

  transition.to(counter,{alpha=0,delay=2500,time=500,onComplete=function(obj) obj:removeSelf() end})
  
  self.timer=timer.performWithDelay(3000, function()
    self.timer=nil
    start.text="Go!"
    transition.to(start,{alpha=0,xScale=5,yScale=5,time=200,onComplete=function(obj) obj:removeSelf() end})
    local meter=progress.create(img.contentWidth,60,{6})
    meter.x=display.contentCenterX
    meter.y=img.y-img.contentHeight-60
    self.view:insert(meter)

    local tuneCount=display.newGroup()
    self.view:insert(tuneCount)
    local t=display.newText({
      text="Completed Sequences:",
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
    local advancedMode=false
    local hints={}
    highlightKeys(steps,advancedMode,hints)
    local reset
    local function madeMistake()
      reset()
      sound.playSound("wrong")
      meter:reset()
      hints[steps]=true
      steps=1
      highlightKeys(steps,advancedMode,hints)
      local t=display.newText({
        text="Mistake, start again!",
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
    end
    local resetMeterTimer
    local onPlay,onRelease,_r=keyeventslisteners.create("learntune",function(tune)
      if tune~=tuneLearning then
        madeMistake()
      else
        sound.playSound("correct")
        local n=tonumber(count.text)+1
        count.text=n
        steps=1

        if n==40 then
          composer.gotoScene("scenes.practiceintro",{params={page=event.params.page}})
        elseif n>=20 then
          advancedMode=true
        end
        meter:mark(6,true)
        resetMeterTimer=timer.performWithDelay(250, function()
          resetMeterTimer=nil
          if meter.numChildren then
            meter:reset()
          end
        end)
        highlightKeys(steps,advancedMode,hints)
      end
    end,madeMistake,function(event)
      if resetMeterTimer then
        meter:reset()
        timer.cancel(resetMeterTimer)
        resetMeterTimer=nil
      end
      if event.complete and event.phase=="released" and event.allReleased then 
        meter:mark(steps,true)
        steps=steps+1
        if steps>6 then
          steps=1
        end
        highlightKeys(steps,advancedMode,hints)
      end
    end,function() return tuneLearning end)
    reset=_r

    events.addEventListener("key played",onPlay)
    events.addEventListener("key released",onRelease)
    self.onRelease=onRelease
    self.onPlay=onPlay
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