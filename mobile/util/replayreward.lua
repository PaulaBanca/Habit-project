local M = {}
replayreward = M

local table = table
local _ = require ("util.moses")
local print = print
local math = math

setfenv(1, M)

local intervals = {}
local lastReward

function setup(rt)
	intervals[1] = rt[1]
	local last = rt[1]

	for i = 2, #rt do
		intervals[i] = rt[i] - last
		last = rt[i]
	end
end

function trialHasReward(time)
	if #intervals == 0 then
		return
	end
	if time < lastReward + intervals[1] then
		return
	end
	lastReward = time
	table.remove(intervals, 1)
	return true
end

function nextReward()
	return lastReward + intervals[1]
end

return M