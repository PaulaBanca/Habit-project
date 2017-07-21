local M={}
recalloptions=M

local composer=require "composer"

setfenv(1,M)

function create()
  local options={
    {label="Recall Order",options={"A","B"},selectFunc=function(v)
      composer.setVariable("first test", v=="A" and 1 or 2)
      composer.setVariable("second test", v=="A" and 2 or 1)
    end},
    {label="Handedness",options={"Left","Right"},selectFunc=function(v) composer.setVariable("left handed",v=="Left") end,debugSelection=2},
  }
  return options
end

return M