local M={}
stimuli=M

local display=display
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
  local bg=display.newRect(group,0, 0, 238, 238)
  bg.strokeWidth=8
  bg:setFillColor(0.3)
  local shape=palstyleshapes.create(238,238)
  group:insert(shape)
  group.anchorChildren=true
  math.randomseed(os.time())
  function group:setSelected()
    bg.strokeWidth=16
    bg:setStrokeColor(0,1,0)
  end
  function group:unselect()
    bg.strokeWidth=8
    bg:setStrokeColor(1,1,1)
  end
  return group 
end

function getWildcardSimuli(presses)
  local img=display.newImage(wildImg[presses])
  function img:setSelected()
    self.strokeWidth=16
    self:setStrokeColor(0,1,0)
  end

  function img:unselect()
    self.strokeWidth=0
  end

  return img 
end

return M