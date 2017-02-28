local M={}
countdownpoints=M

local math=math
local system=system

setfenv(1,M)

function create(points,interval)
  local time=system.getTimer()
  return function ()
    local r=math.max(0,1-(system.getTimer()-time)/interval)
    if r<=0 then
      r=0
    end
    return math.ceil(points*r/10)*10
  end
end

return M