local M={}
backgrounds=M

local display=display
local unpack=unpack

setfenv(1,M)

local modeColours={
  {17,20,22},
  {51,59,67},
  {68,78,90},
  {85,98,112}
}

for i=1, #modeColours do
  for k=1,#modeColours[i] do
    modeColours[i][k]=modeColours[i][k]/255
  end
end

function create()
  local bg=display.newRect(display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)

  function bg:setColour(modeIndex)
    bg:setFillColor(unpack(modeColours[modeIndex]))
  end

  return bg
end

return M