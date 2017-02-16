local M={}
winnings=M

local _=require "util.moses"

setfenv(1,M)

local lastTotals={}
local totals={}
function add(type,amt)
  totals[type]=(totals[type] or 0) + amt
end

function get(type)
  return (totals[type] or 0)
end

function startTracking()
  lastTotals=_.clone(totals)
end

function getSinceLastTrack(type)
  return get(type)-(lastTotals[type] or 0)
end

return M