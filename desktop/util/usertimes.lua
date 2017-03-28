local M={}
usertimes=M

local display=display
local Runtime=Runtime

setfenv(1,M)

local times={}

function addTime(tune,time)
  times[tune]=times[tune] or {}
  local list=times[tune]
  list[#list+1]=time
end

function getAverage(tune)
  local total=0
  local list=times[tune]
  if not list then 
    return nil
  end
  for i=1,#list do
    total=total+list[i]
  end

  return total/#list
end

function getStandardDeviation(tune)
  local mean=getAverage(tune)
  local list=times[tune]
  if not list then
    return nil
  end
  local total=0
  for i=1,#list do
    local off=mean-list[i]
    total=total+off*off
  end

  return (total/#list)^0.5
end

function startDebugDisplay()
  local group=display.newGroup()
  local meanStr="Means: %.1f\t%.1f"
  local meanTimes=display.newText({
    parent=group,
    text=meanStr:format(0,0),
    fontSize=30,
    align="left",
  })

  local sdStr="S.D: %.1f\t%.1f"
  local sd=display.newText({
    parent=group,
    text=sdStr:format(0,0),
    fontSize=30,
    align="left",
  }) 
  meanTimes.anchorX=0
  meanTimes.anchorY=0
  sd.anchorX=0
  sd.anchorY=0
  meanTimes:setFillColor(0)
  sd:setFillColor(0)
  meanTimes.x=20
  meanTimes.y=20
  sd.x=20
  sd.y=20+meanTimes.height+20

  Runtime:addEventListener("enterFrame",function(event)
    group:toFront()
    meanTimes.text=meanStr:format((getAverage(1) or 0)/1000,(getAverage(2) or 0)/1000)
    sd.text=sdStr:format((getStandardDeviation(1) or 0)/1000,(getStandardDeviation(2) or 0)/1000)
  end)
end

return M