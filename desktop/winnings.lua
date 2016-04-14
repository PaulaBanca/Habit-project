local M={}
winnings=M

setfenv(1,M)

local total=0
function add(amt)
  total=total+amt
end

function get()
  return total
end
return M