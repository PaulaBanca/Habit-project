local M={}
keys=M

local key=require "key"
local particles=require "particles"
local sound=require "sound"
local notes=require "notes"
local playlayout=require "playlayout"
local clientloop=require "clientloop"
local logger=require "logger"
local keylayout=require "keylayout"
local serpent=require "serpent"
local _=require "util.moses"
local os=os
local display=display
local system=system
local type=type
local math=math
local timer=timer
local pairs=pairs
local print=print
local tostring=tostring
local next=next
local transition=transition
local assert=assert
local NUM_KEYS=NUM_KEYS

setfenv(1,M)

local noChords=system.getInfo("environment")=="simulator"

local function configureSparks(colour)
  local json=particles.load("CorrectNote")
  json.finishColorRed=colour[1]
  json.startColorRed=colour[1]
  json.finishColorGreen=colour[2]
  json.startColorGreen=colour[2]
  json.finishColorBlue=colour[3]
  json.startColorBlue=colour[3]
  return json
end

function create(allReleasedFunc,mistakeFunc,releaseFunc,networked,noLogging)
  local group=display.newGroup()
  networked=networked or false
  local keys={}
  local complete
  local currentlyPressedKeys={}
  local targetKeys={}
  local noFeedback=networked
  local logData=not noLogging

  for i=1,NUM_KEYS do
    local keyInstance=key.create()
    keys[i]=keyInstance
    keyInstance.index=i
    group:insert(keyInstance)
    local x,y=playlayout.layout(i)
    keyInstance:translate(x,y)
    local h=keyInstance:getHighlight()
    h:translate(keyInstance:localToContent(0,0))
    group:insert(h)

    local headerY=y-keyInstance.contentHeight/2+10
    local touchLine=display.newLine(group,x,headerY,x,headerY-30)
    touchLine.strokeWidth=20

    local oldHighlight=keyInstance.highlight
    keyInstance.highlight=function(keyInstance,on)
      oldHighlight(keyInstance,on)
      touchLine.isVisible=on
    end

    function keyInstance:startSparks()
      if self.sparks or not self.colour then
        return
      end

      local e=display.newEmitter(configureSparks(self.colour))
      group:insert(e)
      e:translate(self.x,self.y)
      self.sparks=e
    end

    function keyInstance:stopSparks()
      if not self.sparks or not self.sparks.stop then
        return
      end
      self.sparks:stop()
      transition.to(self.sparks,{alpha=0,onComplete=function(obj) display.remove(obj) end})
      self.sparks=nil
    end

    local wasCorrect=false
    local img=keyInstance.getTouchImg()
    img.tap=function(self,event)
      return wasCorrect
    end
    local endedLoggingTable
    local stepID
    img.touch=function(self,event)
      if event.phase=="began" then
        display.getCurrentStage():setFocus(event.target,event.id)
        wasCorrect=targetKeys[i] and not currentlyPressedKeys[i] or networked
        currentlyPressedKeys[i]=true
        stepID=keyInstance.stepID
        self.touchID=event.id
        local data
        if logData then
          data=logger.createLoggingTable()
          data.touchPhase=event.phase
          data.x=event.x
          data.y=event.y
          data.time=os.date("%T")
          data.date=os.date("%F")
          data.appMillis=event.time
          data.timeIntoSequence=event.time-group.setupTime
          data.delay=keyInstance.time and (event.time-keyInstance.time)
          data.wasCorrect=wasCorrect
          data.complete=complete
          data.instructionIndex=keyInstance.instructionIndex
          data.keyIndex=keyInstance.index
        end

        if keyInstance.onPress then
          keyInstance.onPress(wasCorrect)
        end

        if networked then
          clientloop.sendEvent({type="key played",note=keyInstance.index})
        end

        if wasCorrect then
          if not noFeedback then
            keyInstance:startSparks()
          end

          complete=_.isEqual(targetKeys,currentlyPressedKeys)
        else
          mistakeFunc(false,stepID,data)
        end
        local note=keyInstance.note
        if note then
          if not noFeedback then
            sound.playSound(note.." note",nil,keyInstance.octave)
          end
          keyInstance.setPressed(true)
        end

        if data then
          logger.log("touch",data)
          endedLoggingTable=_.clone(data,true)
        end
        return true
      end
      if self.touchID~=event.id then
        return
      end
      if event.phase=="ended" or event.phase=="cancelled" then
        display.getCurrentStage():setFocus(event.target,nil)
        currentlyPressedKeys[i]=nil
        self.touchID=nil

        if networked then
          clientloop.sendEvent({type="key released",note=keyInstance.
            index})
        end

        local data
        if logData then
          data=endedLoggingTable
          assert(data, "keys.lua: endedLoggingTable is nil")
          data.touchPhase=event.phase
          data.x=event.x
          data.y=event.y
          data.time=os.date("%T")
          data.date=os.date("%F")
          data.appMillis=event.time
          data.timeIntoSequence=event.time-group.setupTime
          data.delay=keyInstance.time and (event.time-keyInstance.time)
          data.wasCorrect=wasCorrect
          data.complete=complete
          data.keyIndex=keyInstance.index
          endedLoggingTable=nil
          releaseFunc(data)
        end

        if not next(currentlyPressedKeys) then
          if wasCorrect and not complete then
            mistakeFunc(true,stepID,data)
          end
          allReleasedFunc(stepID,data)
          complete=false
        end

        if data then
          logger.log("touch",data)
        end

        timer.performWithDelay(100, function()
          keyInstance:stopSparks()
          keyInstance.setPressed(false)
        end)
        return true
      end
    end
  end

  function group:setup(instruction,noAid,_noFeedback,noHighlight,index,stepID)
    self:clear()
    if noAid then
      for i=1,#keys do
        keys[i]:highlight(not noHighlight)
      end
    end

    if index==1 then
      self.setupTime=system.getTimer()
    end
    assert(self.setupTime,"Setup time is nil. Index is " .. tostring(index))

    noFeedback=_noFeedback
    targetKeys={}
    local function setNote(key,scientificNote)
      targetKeys[key.index]=true
      local note,octave=notes.toNotePitch(scientificNote)
      key:setNote(note,noAid)
      key:setOctave(octave)
      key:highlight(not noHighlight)
      key.time=system.getTimer()
      key.instructionIndex=index
      key.stepID=stepID
      key.scientificNote=scientificNote
    end

    if noChords and type(instruction)=="table" then
      for i=1, #instruction.chord do
        local c=instruction.chord[i]
        if c~="none" then
          instruction=c
          break
        end
      end
    end
    local notes=keylayout.layout(instruction)
    for k,v in pairs(notes) do
      setNote(keys[k],v)
    end

    return targetKeys
  end

  function group:hasPendingInstruction()
    for i=1, #keys do
      if keys[i].highlighted then
        return
      end
    end
  end

  function group:clear(keepChanged)
    if not keepChanged then
      keylayout.reset()
    end
    complete=false
    for i=1,#keys do
      local k=keys[i]
      k:clear()
      k.time=nil
      k.instructionIndex=nil
      k.time=nil
      k.stepID=nil

      k:highlight(false)
      k.scientificNote=nil
      if k.sparks then
        display.remove(k.sparks)
        k.sparks=nil
      end
    end
  end

  function group:getKeyHeight()
    return keys[1].contentHeight
  end

  local enabled=false
  function group:disable()
    if not enabled then
      return
    end
    currentlyPressedKeys={}
    enabled=false
    for i=1, #keys do
      local img=keys[i].getTouchImg()
      img:removeEventListener("touch")
      img:removeEventListener("tap")
    end
  end

  function group:enable()
    if enabled then
      return
    end
    enabled=true
    currentlyPressedKeys={}
    for i=1, #keys do
      local img=keys[i].getTouchImg()
      img:addEventListener("tap")
      img:addEventListener("touch")
    end
  end

  function group:setLogData(on)
    logData=on
  end

  return group
end

return M