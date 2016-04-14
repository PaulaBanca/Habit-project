local M={}
countdown=M

local display=display
local system=system
local Runtime=Runtime
local math=math
local print=print

setfenv(1,M)

function fixedTimeStep(func, timestep)
  local lastCall=system.getTimer()
  local accumulator=0

  return function(event) 
    local dt=event.time-lastCall
    lastCall=event.time
    accumulator=accumulator+dt

    while accumulator>=timestep do
      func(event.time)
      accumulator=accumulator-timestep
    end
  end 
end

function create(time,fontSize)
  local group=display.newGroup()
  local digits=math.max(2,math.floor(math.log10(time/1000)+1))
  local numbers=display.newGroup()
  local w=0
  for i=1,digits do
    local dig=display.newText({
      parent=group,
      text="0",
      fontSize=fontSize or 40,
      align="right"
    })
    dig:setFillColor(0)
    w=w+dig.width
  end

  local period=display.newText({
    parent=group,
    text=".",
    fontSize=fontSize or 40,
    align="center"
  })
  period:setFillColor(0)
  w=w+period.width  

  for i=1,2 do
    local dig=display.newText({
      parent=group,
      text="0",
      fontSize=fontSize or 40,
      align="right"
    })
    dig:setFillColor(0)
    w=w+dig.width
  end

  local x=-w/2
  for i=1,group.numChildren do
    group[i].anchorX=1
    group[i].x=x+group[i].width
    x=x+group[i].width
  end

  for i=group.numChildren,1,-1 do
    if group[i]~=period then
      numbers:insert(group[i])
    end
  end
  group:insert(numbers)

  local start=system.getTimer()
  local period=time
  local func=fixedTimeStep(function(time)
    if not numbers.numChildren then
      group:stop()
      return
    end

    local t=(period-(time-start))/1000
    if t<=0 then
      t=0
    end

    for i=1,numbers.numChildren do
      local base=10^((numbers.numChildren-2)-i)
      numbers[numbers.numChildren+1-i].text=math.floor(t/base)%10
    end
    if t==0 then
      group:stop()
    end
  end,1000/30)

  function group:start()
    Runtime:addEventListener("enterFrame",func)
  end

  function group:stop()
    Runtime:removeEventListener("enterFrame",func)
  end

  return group
end


return M