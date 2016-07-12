local M={}
keys=M

local key=require "key"
local json=require "json"
local particles=require "particles"
local sound=require "sound"
local notes=require "notes"
local playlayout=require "playlayout"
local clientloop=require "clientloop"
local logger=require "logger"
local keylayout=require "keylayout"
local serpent=require "serpent"
local os=os
local display=display
local system=system
local type=type
local math=math
local timer=timer
local pairs=pairs
local print=print
local tostring=tostring
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

function create(eventFunc,networked,noLogging)
  local group=display.newGroup()
  
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

    local wasCorrect=false
    local img=keyInstance.getTouchImg()
    img.tap=function(self,event)
      return wasCorrect
    end
    img.touch=function(self,event) 
      if event.phase=="began" then
        wasCorrect=targetKeys[i] and not currentlyPressedKeys[i] or networked
        if wasCorrect==nil then
          wasCorrect=false
        end
        currentlyPressedKeys[i]=true    
        if keyInstance.onPress then
          keyInstance.onPress(wasCorrect)
        end
        
        if networked then
          clientloop.sendEvent({type="key played",note=keyInstance.index})
        end
  
        if wasCorrect then
          if not keyInstance.sparks and not noFeedback and keyInstance.colour then
            local e=display.newEmitter(configureSparks(keyInstance.colour))
            e:translate(keyInstance.x,keyInstance.y)
            keyInstance.sparks=e
          end

          complete=true
          local notesPlayed={}
          for k=1,#keys do
            if targetKeys[k]~=currentlyPressedKeys[k] then
              complete=false
              break
            end
            notesPlayed[#notesPlayed+1]=keys[k].scientificNote
          end
        else
          eventFunc(false or networked)
        end
        local note=keyInstance.note
        if note then
          if not noFeedback then
            sound.playSound(note.." note",nil,keyInstance.octave)
          end
          keyInstance.setPressed(true)
        end
        if logData then
          logger.log({touchPhase=event.phase,x=event.x,y=event.y,date=os.date(), time=event.time,delay=keyInstance.time and (event.time-keyInstance.time), wasCorrect=wasCorrect,complete=complete,track=keyInstance.track,instructionIndex=keyInstance.instructionIndex,keyIndex=keyInstance.index})
        end

        display.getCurrentStage():setFocus(event.target,event.id)
        return true
      end
      if event.phase=="ended" or event.phase=="cancelled" then
        display.getCurrentStage():setFocus(nil,event.id)
        currentlyPressedKeys[i]=nil
        if networked then
          clientloop.sendEvent({type="key released",note=keyInstance. 
            index})
        end
        local data={touchPhase=event.phase,x=event.x,y=event.y,date=os.date(), time=event.time,delay=keyInstance.time and (event.time-keyInstance.time), wasCorrect=wasCorrect,complete=complete,track=keyInstance.track,instructionIndex=keyInstance.instructionIndex,keyIndex=keyInstance.index}
        if wasCorrect and not complete then
          eventFunc(false or networked)
        end
        timer.performWithDelay(100, function() 
          if complete then
            complete=false
            eventFunc(true)
          end
          if logData then
            logger.log(data)
          end
          
          if keyInstance.sparks then
            keyInstance.sparks:stop()
            keyInstance.sparks=nil
          end
          keyInstance.setPressed(false)
        end)
        return true
      end
    end
    img:addEventListener("tap")
    img:addEventListener("touch")
  end

  function group:setup(instruction,noAid,_noFeedback,track,index)  
    self:clear()
    if noAid then
      for i=1,#keys do
        keys[i]:highlight(true)
      end
    end
    noFeedback=_noFeedback
    targetKeys={}
    local function setNote(key,scientificNote)
      targetKeys[key.index]=true
      local note,octave=notes.toNotePitch(scientificNote)  
      key:setNote(note,noAid) 
      key:setOctave(octave) 
      key:highlight(true)
      key.time=system.getTimer()
      key.track=track
      key.instructionIndex=index
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
      keys[i]:clear()
      keys[i].time=nil
      key.track=nil
      key.instructionIndex=nil
      key.time=nil
     
      keys[i]:highlight(false)
      keys[i].scientificNote=nil
      if keys[i].sparks then
        keys[i].sparks:stop()
        keys[i].sparks=nil
      end
    end
  end

  function group:getKeyHeight()
    return keys[1].contentHeight
  end

  function group:disable()
    for i=1, #keys do 
      keys[i].getTouchImg():removeEventListener("touch")
    end
  end

  function group:addCoin(callback)
    local i=math.random(NUM_KEYS)
    local k=keys[i]
    k:addCoin()
    k.onPress=function(correct)
      if k:hasCoin() then
        k:clearCoin()
        if correct then
          callback(k:localToContent(0,0))
        end
      end
      k.onPress=nil
    end
  end

  return group
end

return M