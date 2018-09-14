local M={}
keys=M

local key=require "key"
local sound=require "sound"
local notes=require "notes"
local playlayout=require "playlayout"
local logger=require "logger"
local keylayout=require "keylayout"
local user=require "user"
local serpent=require "serpent"
local _=require "util.moses"
local keysparks=require "ui.keysparks"
local keypattern=require "keypattern"
local os=os
local display=display
local system=system
local type=type
local timer=timer
local pairs=pairs
local print=print
local tostring=tostring
local next=next
local assert=assert
local NUM_KEYS=NUM_KEYS

setfenv(1,M)

local noChords=system.getInfo("environment")=="simulator"

function create(listenerFunctions,noLogging)
  local group=display.newGroup()
  local keys={}
  local complete
  local currentlyPressedKeys={}
  local targetKeys={}
  local noFeedback=false
  local logData=not noLogging
  keysparks.clear()

  for i=1,NUM_KEYS do
    local keyInstance=key.create()
    keys[i]=keyInstance
    keyInstance.index=i
    group:insert(keyInstance)
    local x,y=playlayout.layout(user.get("left handed") and (NUM_KEYS-i+1) or i)
    keyInstance:translate(x,y)
    local h=keyInstance:getHighlight()
    h:translate(keyInstance:localToContent(0,0))
    group:insert(h)

    local headerY=y-keyInstance.contentHeight/2+10
    local touchLine=display.newLine(group,x,headerY,x,headerY-30)
    touchLine.strokeWidth=20

    local oldHighlight=keyInstance.highlight
    keyInstance.highlight=function(self,on)
      oldHighlight(self,on)
      touchLine.isVisible=on
    end

    local wasCorrect=false
    local img=keyInstance.getTouchImg()
    img.tap=function()
      return wasCorrect or noFeedback
    end
    local endedLoggingTable
    local stepID
    img.touch=function(self,event)
      if event.phase=="began" then
        display.getCurrentStage():setFocus(event.target,event.id)
        wasCorrect=targetKeys[i] and not currentlyPressedKeys[i]
        currentlyPressedKeys[i]=true
        stepID=keyInstance.stepID
        self.touchID=event.id
        local data
        if logData then
          data=logger.createLoggingTable()
          data.touchPhase=event.phase
          data.x=event.x
          data.y=event.y
          data.keyPattern=keypattern.create(currentlyPressedKeys)
          data.time=os.date("%T")
          data.date=os.date("%F")
          data.appMillis=event.time
          data.timeIntoSequence=event.time-group.setupTime
          data.delay=keyInstance.time and (event.time-keyInstance.time)
          data.wasCorrect=wasCorrect
          data.complete=complete
          data.instructionIndex=keyInstance.instructionIndex
          data.keyIndex=keyInstance.index
          if listenerFunctions.onKeyPress then
            listenerFunctions.onKeyPress(data)
          end
        end

        if keyInstance.onPress then
          keyInstance.onPress(wasCorrect)
        end

        if wasCorrect then
          if not noFeedback then
            keysparks.startSparks(i,keyInstance.colour,keyInstance.x,keyInstance.y)
          end

          complete=_.isEqual(targetKeys,currentlyPressedKeys)
        else
          listenerFunctions.onMistake(false,stepID,data)
        end
        local note=keyInstance.note
        if note then
          if not noFeedback then
            sound.playSound(note.." note",nil,keyInstance.octave)
          end
          keyInstance.setPressed(true)
        elseif noFeedback then
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

        local data
        if logData then
          data=endedLoggingTable
          assert(data, "keys.lua: endedLoggingTable is nil")
          data.touchPhase=event.phase
          data.x=event.x
          data.y=event.y
          data.keyPattern=keypattern.create(currentlyPressedKeys)
          data.time=os.date("%T")
          data.date=os.date("%F")
          data.appMillis=event.time
          data.timeIntoSequence=event.time-group.setupTime
          data.delay=keyInstance.time and (event.time-keyInstance.time)
          data.wasCorrect=wasCorrect
          data.complete=complete
          data.keyIndex=keyInstance.index
          endedLoggingTable=nil
          listenerFunctions.onKeyRelease(data)
        end

        if not next(currentlyPressedKeys) then
          if wasCorrect and not complete then
            listenerFunctions.onMistake(true,stepID,data)
          end
          listenerFunctions.onAllReleased(stepID,data)
          complete=false
        end

        if data then
          logger.log("touch",data)
        end

        if keyInstance.sparkTimer then
          timer.cancel(keyInstance.sparkTimer)
        end
        keyInstance.sparkTimer=timer.performWithDelay(100, function()
          keyInstance.sparkTimer=nil
          keysparks.stopSparks(i)
          keyInstance.setPressed(false)
        end)
        return true
      end
    end
  end

  function group:setup(instruction,noAid,_noFeedback,noHighlight,index,stepID,forceNotes)
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
    local keyNotes=keylayout.layout(instruction)
    for k,v in pairs(keyNotes) do
      local key=keys[k]
      setNote(key,v)
      targetKeys[key.index]=true
    end

    if forceNotes then
      noAid=true
      noHighlight=true
      local unused=notes.getUnusedNotes(keyNotes)
      local ni
      for i=1, #keys do
        if not keys[i].note then
          repeat
            ni=next(unused,ni)
          until ni
          setNote(keys[i],unused[ni]..'4')
        end
      end
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
    for i=1,NUM_KEYS do
      local k=keys[i]
      k:clear()
      k.time=nil
      k.instructionIndex=nil
      k.time=nil
      k.stepID=nil

      k:highlight(false)
      k.scientificNote=nil

      if k.sparkTimer then
        timer.cancel(k.sparkTimer)
        k.sparkTimer=nil
      end
      k.setPressed(false)
      keysparks.stopSparks(i)
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