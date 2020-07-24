local M = {}
intrusions = M

local serpent = require "serpent"
local print = print

local intrusiondetection = require ("intrusiondetection")
local _=require "util.moses"
local tunes = require "tunes"

setfenv(1, M)

local lastFullPattern
local lastPress

local function checkMatches()
	if not lastFullPattern then
		return
	end

	local matches = {}
	local count = 0
	for i = 1, #lastPress do
		local tune = lastPress[i].tune
		for k = 1, #lastFullPattern do
			if lastFullPattern[k].tune == tune then
				local ds = lastPress[k].step - lastFullPattern[k].step
				local wrapArround = lastPress[k].step == 1 and lastFullPattern[k].step == tunes.getTuneLength(tune)
				if ds == 1 or wrapArround then
					count = count +1
					matches[#matches + 1] = lastFullPattern[k]
				end
			end
		end
	end

	return matches
end

local lockPattern = true

function onKeyPress(pressed)
	local matches = intrusiondetection.matchAgainstTunes(pressed, {1,2})
	lastPress = matches
	return checkMatches()
end

function onKeyRelease(pressed)
	if lockPattern then
		lastFullPattern = lastPress
		lockPattern = false
	end
	local allReleased=_.count(pressed,true) == 0
	if allReleased then
		lockPattern = true
	end
	local matches = intrusiondetection.matchAgainstTunes(pressed, {1,2})
	lastPress = matches

	return checkMatches()
end

function reset()
	lockPattern = true
	lastFullPattern = nil
	lastPress = nil
end

return M