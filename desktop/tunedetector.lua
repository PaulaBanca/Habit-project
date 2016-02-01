local M={}
tunedetector=M

local tunes=require "tunes"
local keylayout=require "keylayout"
local serpent=require "serpent"
local print=print
local pairs=pairs

setfenv(1,M)

local tuneKeys={}
do
  local t=tunes.getTunes()
  for i=1,#t do
    local instructions=t[i]
    local keys={}
    keylayout.reset()
    for k=1, #instructions do
      keys[k]=keylayout.layout(instructions[k])
    end 
    tuneKeys[i]=keys
    print (serpent.block(keys,{comment=false}))
  end
end

local function pressedWrongKey(keysPressed,keysRequired)
  for index,pressed in pairs(keysPressed) do
    if pressed and not keysRequired[index] then
      return true
    end
  end 
end

local function missingCorrectKey(keysPressed,keysRequired)
  for index,required in pairs(keysRequired) do
    if not keysPressed[index] then
      return true
    end
  end 
end


local function matchesTuneStart(keysDown)
  local candidates={}
  for i=1,#tuneKeys do
    local keys=tuneKeys[i]
    if not pressedWrongKey(keysDown,keys[1]) then
      candidates[i]=missingCorrectKey(keysDown,keys[1]) and "partial" or "complete"
    else
      candidates[i]="none"
    end
  end
  return candidates
end

local function matchesTuneAtStep(tune,index,keysDown)
  local keys=tuneKeys[tune][index]
  if pressedWrongKey(keysDown,keys) then
    return "none"
  end
  if missingCorrectKey(keysDown,keys) then
    return "partial"
  end
  
  return "complete"
end


local candidates
function matchAgainstTunes(keysDown)
  local match=false
  local tuneCompleted
  if not candidates then
    candidates=matchesTuneStart(keysDown)
    for k,v in pairs(candidates) do
      if v=="none" then
        candidates[k]=nil
      else
        candidates[k]=v=="partial" and 0 or 1
        match=true
      end
    end
  else
    for k,v in pairs(candidates) do
      local type=matchesTuneAtStep(k,v+1,keysDown)
      if type=="none" then  
        candidates[k]=nil
      elseif type=="complete" then
        match=true
        candidates[k]=v+1
        if candidates[k]==#tuneKeys[k] then
          tuneCompleted=k
          candidates=nil
        end
      else
        match=true
      end
    end
  end
  if not match then
    candidates=nil
  end
  return tuneCompleted
end

return M