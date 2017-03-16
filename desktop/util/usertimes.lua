local M={}
usertimes=M

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

  return total/#list
end

return M