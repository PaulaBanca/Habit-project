local M={}
rewardtext=M

local math=math

setfenv(1,M)

function create(amt)
  amt=math.floor(amt*100+0.5)/100
  if amt>=1 then
    local addZero=amt-math.floor(amt)>0 and math.floor(amt*100)%10==0
    return "£"..amt .. (addZero and "0" or "")
  else
    return (amt*100).."p"
  end
end

return M