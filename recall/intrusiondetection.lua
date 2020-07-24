local M={}
intrusiondetection=M

local tunes=require "tunes"
local keylayout=require "keylayout"
local serpent=require "serpent"
local _=require "util.moses"
local print=print
local math=math
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
  for index,_ in pairs(keysRequired) do
    if index~="invert" then
      if not keysPressed[index] then
        return true
      end
    end
  end
end

local function matchesTuneAtStep(tune,index,keysDown)
  local keys=tuneKeys[tune][math.min(index,#tuneKeys[tune])]
  if pressedWrongKey(keysDown,keys) then
    return keys.invert and "complete" or "none"
  end
  if missingCorrectKey(keysDown,keys) then
    return "partial"
  end

  return keys.invert and "none" or "complete"
end

function matchAgainstTunes(keysDown, tunes)
  local matches={}

  for i=1, #tunes do
    local tune = tunes[i]
    local keys = tuneKeys[tune]

    for m=1, #keys do
      local type=matchesTuneAtStep(tune,m, keysDown)
      if type=="complete" then
        matches[#matches + 1] = {type = type, step = m, tune = tune}
      end
    end
  end
  return matches
end

return M