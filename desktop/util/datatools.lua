local M={}
datatools=M

local math=math
local table=table
local _=require "util.moses"

setfenv(1,M)

function getQuartiles(list)
  table.sort(list)
  local len=#list
  local medianIndex=math.floor((len+1)/2)
  local lowerQuartileIndex=math.floor((len+1-medianIndex)/2)
  local upperQuartileIndex=medianIndex+math.floor((len+1-medianIndex)/2)
  local q1=list[lowerQuartileIndex]
  local q3=list[upperQuartileIndex]
  return list[q1],list[medianIndex],list[q3]
end

function removeOutliers(list)
  local lowerBounds,upperBounds
  do
    local q1,_,q3=getQuartiles(list)
    local iqRange=q3-q1
    lowerBounds=q1-1.5*iqRange
    upperBounds=q3+1.5*iqRange
  end
  return _.reject(list,function(_,v)
    return v<lowerBounds or v>upperBounds
  end)
end


return M