local M = {}
difficulty = M
local practicelogger=require "practicelogger"
local daycounter=require "daycounter"
local setmetatable=setmetatable
local _ = require ("util.moses")
local print = print
local math=math

setfenv(1, M)

local dayDifficulties = {
  {{1,1},{2,2}}
}

setmetatable(dayDifficulties, {
  __index = function()
    return {{2,2}, {2,2}}
  end
})

function get(track)
	local practice=math.min(2, (practicelogger.getPractices(track) + 1))
	local day=daycounter.getPracticeDay()
  return _.clone(dayDifficulties[day][practice])
end

return M



