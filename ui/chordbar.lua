local M={}
chordbar=M

local playlayout=require "playlayout"

local unpack=unpack
local display=display
local math=math
local NUM_KEYS=NUM_KEYS
local print=print
setfenv(1,M)

function create(targetKeys)
  local mini=NUM_KEYS
  local maxi=1
  for i=1, NUM_KEYS do
    if targetKeys[i] then
      mini=math.min(i,mini)
      maxi=math.max(i,maxi)
    end
  end
  if maxi==mini then
    return
  end
  local points={}
  for i=mini,maxi,0.25 do
    local x,y=playlayout.layout(i)
    if i==mini then
      points[#points+1]=x
      points[#points+1]=y
    end
    points[#points+1]=x
    points[#points+1]=y-20
    if i==maxi then
      points[#points+1]=x
      points[#points+1]=y
    end
  end
  local hint=display.newLine(unpack(points))
  hint.strokeWidth=20
  return hint
end

return M