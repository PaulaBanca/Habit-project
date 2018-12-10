local M={}
keylayout=M

local type=type
local pairs=pairs
local NUM_KEYS=NUM_KEYS

setfenv(1,M)

local lastChanged=0
function layout(instruction)
  local notes={}
  if type (instruction)=="table" then
    if instruction.forceLayout then
      for i=1, #instruction.chord do
        local scientificNote=instruction.chord[i]
        if scientificNote~="none" then
          notes[i]=scientificNote
        end
      end
    else
      local chord={}
      for i=1, #instruction.chord do
        local scientificNote=instruction.chord[i]
        if scientificNote then
          chord[scientificNote]=true
        end
      end

      local availablePositions={}
      for i=1, NUM_KEYS do
        availablePositions[i]=true
      end

      local function nextSpareKey()
        for i=0,NUM_KEYS-1 do
          local k=(lastChanged+i)%NUM_KEYS+1
          if availablePositions[k] then
            availablePositions[k]=nil
            lastChanged=k
            return k
          end
        end
      end
      for scientificNote,_ in pairs(chord) do
        local spareKeyIndex=nextSpareKey()
        notes[spareKeyIndex]=scientificNote
      end
    end
    notes.invert=instruction.chord.invert
  else
    local scientificNote=instruction
    local found=false

    lastChanged=lastChanged+1
    if lastChanged>NUM_KEYS then
      lastChanged=1
    end
    notes[lastChanged]=scientificNote
  end

  return notes
end

function reset()
  lastChanged=0
end

return M