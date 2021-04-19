local M = {}
difficulty = M
local daycounter=require "daycounter"
local setmetatable=setmetatable
local _ = require ("util.moses")

setfenv(1, M)

local dayDifficulties = {
  {1,1},
  {1,2},
  {2,2}
}

setmetatable(dayDifficulties, {
  __index = function()
    return {3,3}
  end
})

function get()
	local day=daycounter.getPracticeDay()
	return _.clone(dayDifficulties[day])
end

return M



