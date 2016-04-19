local M={}
stimuli=M

local display=display
require "palstyleshapes.init"
local palstyleshapes=require "palstyleshapes.palstyleshapes"
local math=math
local os=os

setfenv(1,M)

local seeds={
  math.random(0xFFFFFFF),
  math.random(0xFFFFFFF),
  math.random(0xFFFFFFF),
}

local wildImg={
  [3]="img/stimuli/wildcard3.png",
  [6]="img/stimuli/wildcard6.png",
}

function getStimulus(n)
  math.randomseed(seeds[n])
  local group=display.newGroup()
  local bg=display.newRect(group,0, 0, 200, 200)
  bg.strokeWidth=8
  bg:setFillColor(0.3)
  local shape=palstyleshapes.create(200,200)
  group:insert(shape)
  math.randomseed(os.time())
  return group 
end

function getWildcardSimuli(presses)
  return display.newImage(wildImg[presses])
end

return M