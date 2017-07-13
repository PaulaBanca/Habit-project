local M={}
playlayout=M

local math=math
local display=display
local system=system

setfenv(1,M)

CX,CY=display.contentWidth/2, display.contentHeight
local isMiniScale=(system.getInfo("model")=="iPad" and display.pixelWidth==768) and  0.6 or 1
RADIUS=(math.min(130*display.contentScaleX,display.contentWidth/8)*1.7)*isMiniScale
ELIPSE_XSCALE=3

function layout(i)
  local t=((math.pi-math.pi/2.25)*(i-1)/4)+math.pi+math.pi/3.5
  return math.cos(t)*RADIUS*ELIPSE_XSCALE+CX,math.sin(t)*RADIUS+CY
end
   
return M