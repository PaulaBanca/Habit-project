local M={}
datatools=M

local math=math
local table=table
local _=require "util.moses"

setfenv(1,M)

function removeOutliers(list)
  local len=#list
  local medianIndex=math.floor((len+1)/2)
  table.sort(list)
  local lowerQuartileIndex=math.floor((len+1-medianIndex)/2)
  local upperQuartileIndex=medianIndex+math.floor((len+1-medianIndex)/2)
  local q1=list[lowerQuartileIndex]
  local q3=list[upperQuartileIndex]
  local iqRange=q3-q1

  local lowerBounds=q1-1.5*iqRange
  local upperBounds=q3+1.5*iqRange

  return _.reject(list,function(_,v)
    return v<lowerBounds or v>upperBounds
  end)
end


return M