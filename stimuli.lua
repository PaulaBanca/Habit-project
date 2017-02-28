local M={}
stimuli=M

local display=display
local palstyleshapes=require "palstyleshapes.palstyleshapes"
local math=math
local os=os
local assert=assert
local _=require "util.moses"

setfenv(1,M)

local seeds={}

local wildImg={
  [3]="img/stimuli/wildcard3.png",
  [6]="img/stimuli/wildcard6.png",
}

function generateSeeds()
  seeds={
    math.random(0xFFFFFFF),
    math.random(0xFFFFFFF),
    math.random(0xFFFFFFF),
  }
  if #_.unique(seeds)~=#seeds then
    generateSeeds()
  end
end

function getStimulus(n)
  if n<0 then
    return getWildcardSimuli(-n)
  end
  local truncated=n-3
  if truncated>0 then
    n=n%2+1
    truncated=truncated>2 and 5 or 3
  else
    truncated=nil
  end
  math.randomseed(seeds[n])
  local group=display.newGroup()
  local strokeWidth=8
  local bg=display.newRect(group,0, 0, 238, 238)
  bg.strokeWidth=8
  bg:setFillColor(0.3)
  local shape=palstyleshapes.create(238-strokeWidth/2,238-strokeWidth/2)
  group:insert(shape)
  group.anchorChildren=true
  math.randomseed(os.time())

  if truncated then
    assert(truncated==3 or truncated==5)
    display.newImage(group, "img/"..(truncated==3 and "three.png" or "five.png")).blendMode="add"
    display.newImage(group, "img/"..(truncated==3 and "three.png" or "five.png"))
  end
  function group:setSelected()
    bg.strokeWidth=16
    bg:setStrokeColor(0,1,0)
  end
  function group:unselect()
    bg.strokeWidth=strokeWidth
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