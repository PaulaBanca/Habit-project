local composer=require "composer"
local scene=composer.newScene()

local server=require "server"
local events=require "events"
local serpent=require "serpent"
local tunes=require "tunes"
local stimuli=require "stimuli"
local countdown=require "ui.countdown"
local tunemanager=require "tunemanager"
local sound=require "sound"
local keyeventslisteners=require "util.keyeventslisteners"
local logger=require "util.logger"
local progress=require "ui.progress"
local transition=transition
local display=display
local table=table
local pairs=pairs
local print=print
local timer=timer
local tonumber=tonumber
local next=next
local native=native
local os=os
local system=system
local math=math
local NUM_KEYS=NUM_KEYS

setfenv(1,scene)

local bestPractices={}

function getBestFor(tune)
  return bestPractices[tune]
end

function scene:create()
end
scene:addEventListener("create")

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local tunePracticing=event.params.tune
  if tunePracticing then
    local img=tunemanager.getImg(tunePracticing)
    scene.view:insert(img)
    img.anchorY=1
    img.x=display.contentCenterX
    img.y=display.contentCenterY-60
    composer.setVariable("iconbounds", img.contentBounds)
    self.meter=progress.create(img.contentWidth,60,{6})
    self.view:insert(self.meter)
    self.meter.x=display.contentCenterX
    self.meter.y=img.y-img.contentHeight-60
  end

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
  local function delete(obj)
    if obj.removeSelf then
      obj:removeSelf()
    end
  end
  transition.to(counter,{alpha=0,delay=2500,time=500,onComplete=delete})
  
  if event.params.countShapes then
    local shapeIntro=display.newGroup()
    self.view:insert(shapeIntro)
    composer.loadScene("scenes.shapecounter",true)
    local shape=composer.getScene("scenes.shapecounter"):getCountShape()
    shapeIntro:insert(shape)
    shape.anchorY=1
    shape.x=display.contentCenterX
    shape.y=start.y-start.height/2-20

    local start=display.newText({
      parent=shapeIntro,
      text="Count all the stars!",
      fontSize=69,
      x=display.contentCenterX,
      y=shape.y-shape.height-20
    })
    start:setFillColor(0)
    start.anchorY=1
    transition.to(shapeIntro,{delay=2500,alpha=0,onComplete=delete})
  end

  self.timer=timer.performWithDelay(3000, function()
    self.timer=nil
    start.text="Go!"
    transition.to(start,{alpha=0,xScale=5,yScale=5,time=200,onComplete=delete})
    if event.params.countShapes then
      composer.showOverlay("scenes.shapecounter")
    end
    local tuneCount
    local mistakes=0
    local completedSequences=0
    if not event.params.iterations then
      local counter=countdown.create(60*1000,80)
      counter:translate(display.contentCenterX,display.contentHeight-counter.height)
      counter:start()
      self.view:insert(counter)
      self.timer=timer.performWithDelay(60*1000, function()
        self.timer=nil
        local logField=logger.create(event.params.countShapes and "shapecounter" or "practice_tune_summary",{"shapes","user counted","date","sequence","sequences completed","mistakes"})
        logField("sequence",tunePracticing or "n/a")
        logField("sequences completed",tunePracticing and completedSequences or "n/a")
        logField("mistakes",tunePracticing and mistakes or "n/a")
        logField("date",os.date())
              
        if event.params.countShapes then
          composer.hideOverlay("scenes.shapecounter")
          if tuneCount then
            transition.to(tuneCount, {alpha=0})
          end
          local defaultField
          local instruction
          local page=event.params.page
          local function textListener(event)
            if event.phase == "began" then
            elseif event.phase == "ended" or event.phase == "submitted" and tonumber(event.target.text) then
              logField("user counted",event.target.text,true)
              logField("shapes",composer.getVariable("shapes"),true)
                         
              defaultField:removeSelf()
              composer.gotoScene("scenes.practiceintro",{params={page=page}}) 
            elseif event.phase == "editing" then
              instruction.text="Press Enter to submit"
            end
          end

          -- Create text field
          defaultField = native.newTextField(display.contentCenterX, display.contentCenterY, 180, 80)

          defaultField:addEventListener("userInput", textListener)
          instruction=display.newText({
            parent=self.view,
            text="How many stars did you count?",
            fontSize=69,
            x=display.contentCenterX,
          })
          instruction.anchorY=1
          instruction.y=display.contentCenterY-40-20
          instruction:setFillColor(0)
          display.newRect(self.view,display.contentCenterX, display.contentCenterY, 184, 84 ):setFillColor(0)

       else
          logField("user counted","n/a")
          logField("shapes","n/a")
          
          composer.gotoScene("scenes.practiceintro",{params={page=event.params.page}}) 
       end
      end)
    end

    if tunePracticing then
      tuneCount=display.newGroup()
      self.view:insert(tuneCount)
      local t=display.newText({
        text="Completed Sequences:",
        fontSize=60,
        parent=tuneCount,
        x=display.contentCenterX,
        y=display.contentCenterY
      })
      t:setFillColor(0)

      local count=display.newText({
        text=0,
        fontSize=100,
        parent=tuneCount,
        x=display.contentCenterX,
        y=display.contentCenterY+t.height/2+10
      })
      count.anchorY=0
      count:setFillColor(0)

      local timeField=logger.create("practice_tune_times",{"sequence","date","time to complete"})
     
      local steps=0
      local reset
      local inMistakeStreak
      local time=system.getTimer()
      local function madeMistake(notunes)
        steps=0
        self.meter:reset()
        reset()
        sound.playSound("wrong")
        time=system.getTimer()
        
        if not inMistakeStreak then
          mistakes=mistakes+1
          inMistakeStreak=true
        end
        local t=display.newText({
          text=notunes and "No trained sequences!" or "Mistake, start again!",
          fontSize=120,
          parent=self.view,
          x=display.contentCenterX,
          y=count.y+count.height/2+10
        })
        t.anchorY=0
        t:setFillColor(1,0,0)
        local delete=function(obj) 
          if obj.removeSelf then
            obj:removeSelf()
          end
        end
        transition.to(t, {tag="mistake",alpha=0,onComplete=delete,onCancel=delete})
      end

      local MAX_ITER=event.params.iterations
      local PAGE_N=event.params.page
      local clearMeterTimer
      local function markCompleted()
        reset()
        sound.playSound("correct")
        clearMeterTimer=timer.performWithDelay(250, function()
          clearMeterTimer=nil
          if not self.meter.numChildren then
            return
          end
          self.meter:reset()
        end)
        local n=tonumber(count.text)+1
        completedSequences=n
        count.text=n

        timeField("sequence",tunePracticing)
        timeField("date",os.date())
        timeField("time to complete",system.getTimer()-time)
        time=system.getTimer()

        if not bestPractices[tunePracticing] or n>bestPractices[tunePracticing] then
          bestPractices[tunePracticing]=n
        end
      end
      local onPlay,onRelease,_r=keyeventslisteners.create(event.params.logName,function(tune)
        if tune~=tunePracticing then
          madeMistake(MAX_ITER~=nil)
        else
          inMistakeStreak=false
          self.meter:mark(6,true)
          markCompleted() 
          if MAX_ITER==tonumber(count.text) then
            composer.gotoScene("scenes.practiceintro",{params={page=PAGE_N}}) 
          end
          steps=0    
        end
      end,madeMistake,function(event)
       if not event.phase=="released" or not event.allReleased then
          return
        end
        if clearMeterTimer then
          timer.cancel(clearMeterTimer)
          self.meter:reset()
          clearMeterTimer=nil
        end
        if tunePracticing>0 then
          if event.complete then
            local completed=event.matchingTunes[tunePracticing].step
            self.meter:mark(completed,true)
            inMistakeStreak=false
          end
        elseif tunePracticing<1 then 
          steps=steps+1
          local good=true
          if event.matchingTunes then
            for i=1, 3 do
              if event.matchingTunes[i] and event.matchingTunes[i].step==steps then
                good=false            
              end
            end
          end
          inMistakeStreak=false
          self.meter:mark(steps,good)
        elseif event.allReleased and event.complete then
          transition.cancel("mistake")
        end
      end,function() return tunePracticing end,tunePracticing<0,function() return math.abs(tunePracticing) end)
      reset=_r
      events.addEventListener("key played",onPlay)
      events.addEventListener("key released",onRelease)
      self.onRelease=onRelease
      self.onPlay=onPlay
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
    composer.hideOverlay("scenes.shapecounter")
  else
    for i=self.view.numChildren,1,-1 do
      self.view[i]:removeSelf()
    end
  end
end

scene:addEventListener("hide")

return scene