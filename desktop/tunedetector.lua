local M={}
tunedetector=M

local tunes=require "tunes"
local keylayout=require "keylayout"
local serpent=require "serpent"
local _=require "util.moses"
local print=print
local table=table
local assert=assert
local math=math
local pairs=pairs

setfenv(1,M)

local tuneKeys={}
local matchesAll={}
do
  local t=tunes.getTunes()
  for i=1,#t do
    matchesAll[i]={type="complete",step=1}
    local instructions=t[i]
    local keys={}
    keylayout.reset()
    for k=1, #instructions do
      keys[k]=keylayout.layout(instructions[k])
    end 
    tuneKeys[i]=keys
  end

  local function findLongestOverlap(a,b)
    local longest=0
    for offset=-#a+1,0 do
      local streak=0
      for i=1,#b do
        local bkeys=b[i]
        local akeys=a[(offset+i)%#a+1]
        if _.sameKeys(akeys,bkeys) then
          streak=streak+1
          longest=math.max(streak,longest)
        else
          streak=0
        end
      end
    end
    return longest
  end

  for i=1, #tuneKeys do
    local keys=tuneKeys[i]
    for k=i+1, #tuneKeys do
      assert(findLongestOverlap(keys,tuneKeys[k])==1)
    end
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
  local keys=tuneKeys[tune][math.min(index,#tuneKeys[tune])]
  if pressedWrongKey(keysDown,keys) then
    return "none"
  end
  if missingCorrectKey(keysDown,keys) then
    return "partial"
  end
  
  return "complete"
end


local candidates
function matchAgainstTunes(keysDown,released)
  local matches=nil
  function addMatch(tune,c)
    matches=matches or {}
    c.released=released
    matches[tune]=c
  end
  if released then
    if not candidates then
      return nil,nil
    end
    local allReleased=not _.contains(keysDown,true)
    local tuneCompleted
    for k,v in pairs(candidates) do
      if v.type=="partial" then
        candidates[k]=nil
      elseif v.type=="complete" then
        addMatch(k,v)
        if allReleased then
          v.step=v.step+1
          if v.step==#tuneKeys[k] then
            tuneCompleted=k
            candidates=nil
            break
          end
        end
      end
    end
    if not matches then
      candidates=nil
    end
    return tuneCompleted,matches
  end

  if not candidates then
    candidates=matchesTuneStart(keysDown)
    for k,v in pairs(candidates) do
      if v=="none" then
        candidates[k]=nil
      else
        candidates[k]={type=v, step=0}
        addMatch(k,candidates[k])
      end
    end
  else
    local starts=matchesTuneStart(keysDown)
    for k,v in pairs(starts) do
      if not candidates[k] then
        candidates[k]={type=v, step=0}
        addMatch(k,candidates[k])
      end
    end   
    for k,v in pairs(candidates) do
      local type=matchesTuneAtStep(k,v.step+1,keysDown)
      if type=="none" then  
        candidates[k]=nil
      else
        candidates[k]={type=type,step=v.step}
        addMatch(k,candidates[k])
     end
    end
  end
  if not matches then
    candidates=nil
  end
 
  return nil,matches
end

function reset()
  candidates=nil
end

return M