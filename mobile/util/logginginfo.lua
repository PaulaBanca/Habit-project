local M={}
logginginfo=M

local unset=require "database.unsent"
local display=display
local Runtime=Runtime
local math=math

setfenv(1,M)

local group=display.newGroup()
local inDB=display.newText({
  parent=group,
  text="DB: ",
  fontSize=30,
  align="left",
})

local inTable=display.newText({
  parent=group,
  text="Table: ",
  fontSize=30,
  align="left",
})

local dbNum=display.newText({
  parent=group,
  text="-",
  fontSize=30,
  align="left",
})
local tableNum=display.newText({
  parent=group,
  text="-",
  fontSize=30,
  align="left",
})

local width=math.max(inDB.width,inTable.width)

inDB.x=20
inTable.x=20
for i=1,group.numChildren do
  group[i].anchorX=0
  group[i].anchorY=1
end
inTable.y=display.contentHeight-20
inDB.y=display.contentHeight-20-inTable.height
dbNum.x=width+20
tableNum.x=width+20
dbNum.y=inDB.y
tableNum.y=inTable.y

Runtime:addEventListener("enterFrame",function(event)
  group:toFront()
  tableNum.text=#unset.getUnsent()
  dbNum.text=unset.count("touch")
end)

return M