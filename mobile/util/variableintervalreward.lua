local M = {}
variableintervalreward = M

local table = table
local _ = require ("util.moses")
local print = print
local math = math

setfenv(1, M)

local rewardTimes = {}

function setup(totalTime, rewards)
	local avg = (totalTime * 0.9) / rewards
	local t = 0
	for i = 1, rewards do
		local interval = math.gaussian(avg, 500)
		t = t + math.min(interval, avg * 2)
		rewardTimes[i] = t
	end
end

function trialHasReward(time)
	if #rewardTimes == 0 then
		return
	end
	if time < rewardTimes[1] then
		return
	end
	table.remove(rewardTimes, 1)
	return true
end

return M