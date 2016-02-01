local M={}
randompoints=M

local display=display
local math=math
local Runtime=Runtime
local system=system
local tonumber=tonumber

setfenv(1,M)

function create(points,interval)
  local group=display.newGroup()

  local icon=display.newImage(group,"img/dice.png")

  local textOpts={
    parent=group,
    text=points,
    fontSize=30,
    align="right",
  }
  local t=display.newText(textOpts)
  t.anchorX=1
  t.x=icon.width/2+t.width
  
  display.newRoundedRect(group,group.width/2-icon.width/2, 0, group.width+4, icon.height+4,icon.height/2):setFillColor(0.5,0.3)
  t:toFront()
  icon:toFront()

  local w=group.width-icon.width
  for i=1, group.numChildren do
    group[i].x=group[i].x-w/2
  end
  
  if math.random(100)>15 then
    t.text=0
  else
    local time=system.getTimer()
    local lastPoints
    local animate=function(event)
      local r=math.max(0,1-(event.time-time)/interval)
      if r<=0 or not t.removeSelf then
        r=0
        Runtime:removeEventListener("enterFrame", animate)
      end
      local p=math.ceil(points*r/100)*100
      if p==lastPoints then
        return
      end
      t.text=p
      lastPoints=p
    end

    Runtime:addEventListener("enterFrame", animate)
  end
  function group:getPoints()
    return tonumber(t.text)
  end

  function group:clonePoints()
    local nt=display.newText(textOpts)
    nt.anchorX=t.anchorX
    nt.text=t.text
    nt.x=t.x
    return nt
  end

  return group
end

return M