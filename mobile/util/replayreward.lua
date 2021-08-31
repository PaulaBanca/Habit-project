local M = {}
replayreward = M

local table = table
local _ = require ("util.moses")
local print = print
local math = math

setfenv(1, M)

local rewardTimes = {}

function setup(rt)
	rewardTimes = rt
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

function nextReward()
	return rewardTimes[0]
end

return M