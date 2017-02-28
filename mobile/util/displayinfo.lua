local M={}
displayinfo=M

local composer=require "composer"
local display=display
local Runtime=Runtime
local math=math

setfenv(1,M)

local group=display.newGroup()
local inDisplay=display.newText({
  parent=group,
  text="Total: ",
  fontSize=30,
  align="left",
})

local inScene=display.newText({
  parent=group,
  text="Scene: ",
  fontSize=30,
  align="left",
})

local totalNum=display.newText({
  parent=group,
  text="-",
  fontSize=30,
  align="left",
})
local sceneNum=display.newText({
  parent=group,
  text="-",
  fontSize=30,
  align="left",
})

local width=math.max(inDisplay.width,inScene.width)

inDisplay.x=20
inScene.x=20
for i=1,group.numChildren do
  group[i].anchorX=0
  group[i].anchorY=1
end
inScene.y=display.contentHeight-20
inDisplay.y=display.contentHeight-20-inScene.height
totalNum.x=width+20
sceneNum.x=width+20
totalNum.y=inDisplay.y
sceneNum.y=inScene.y

local function getNumChildren(group)
  local total=group.numChildren
  for i=1, group.numChildren do
    if group[i].numChildren then
      total=total+getNumChildren(group[i])
    end
  end
  return total
end

Runtime:addEventListener("enterFrame",function(event)
  group:toFront()
  local cur=composer.getScene(composer.getSceneName("current"))
  if not cur then
    sceneNum.text="-"
  else
    sceneNum.text=getNumChildren(cur.view)
  end

  totalNum.text=getNumChildren(display.getCurrentStage())
end)

return M