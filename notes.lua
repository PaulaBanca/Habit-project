local M={}
notes=M

local math=math
local tonumber=tonumber

setfenv(1,M)

local notes={"c","d","e","f","g","a","b",}
local colours={{69.8, 98.8, 22.7},{92.9, 7.1, 43.5},{98.4, 97.6, 21.6},{31.8, 67.8, 93.3},{51.8, 22.7, 98.8},{98.8, 51.8, 22.7},{98.8, 22.7, 31.8}}
for i=1,#colours do
  for c=1,#colours[i] do
    colours[i][c]=colours[i][c]/100
  end
end

function getColour(index)
  return colours[index]
end

function getIndex(note)
  for i=1,#notes do
    if notes[i]==note then
      return i
    end
  end
end

function toNotePitch(note)
  return note:sub(1,1),math.pow(2.0, (tonumber(note:sub(2,2))*12)*1.0/12.0)/16
end

return M