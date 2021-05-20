local M = {}
variableratioreward = M

local table = table
local _ = require ("util.moses")

setfenv(1, M)

local rewardTrial = {}

function setup(trials, rewards)
	rewardTrial = _.shuffle(
				_.append(
					_.rep(true, rewards),
					_.rep(false, trials - rewards)
				)
			)
end

function trialHasReward()
	return table.remove(rewardTrial)
end

return M