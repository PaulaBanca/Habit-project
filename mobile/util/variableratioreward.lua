local M = {}
variableratioreward = M

local table = table
local math = math
local print = print
local _ = require ("util.moses")

setfenv(1, M)

local rewardTrial = {}

local function maxGap()
	local gap = 0
	local curGap = 0
	for i = 1, #rewardTrial do
		if rewardTrial[i] then
			curGap = 0
		else
			curGap = curGap + 1
		end
		gap = math.max(gap, curGap)
	end

	return gap
end

function setup(trials, rewards)
	local ratio = trials / rewards
	local count = 0
	repeat
		rewardTrial = _.shuffle(
				_.append(
					_.rep(true, rewards),
					_.rep(false, trials - rewards)
				)
			)
		count = count + 1
	until maxGap() < ratio * 2 or count > 500
end

function trialHasReward()
	return table.remove(rewardTrial)
end

return M