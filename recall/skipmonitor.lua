local M = {}
skipmonitor = M

local pairs=pairs
local keylayout=require "keylayout"
local serpent = require ("serpent")
local print = print
local NUM_KEYS=NUM_KEYS

setfenv(1, M)

local keyPattern
local positionMonitored

function reset()
	positionMonitored = nil
end

function monitor(sequence, position)
	positionMonitored = position
	keylayout.reset()
	local notes
	for i =1, position do
		notes = keylayout.layout(sequence[i])
	end
	keylayout.reset()

	keyPattern = {}
	for k,_ in pairs(notes) do
      keyPattern[k]=true
    end

    return keyPattern
end

function checkKeysPressed(keys, step)
	if step ~= positionMonitored then
		return false
	end

	local patternMatch = true
	local pressedKeyMatch = false
	for i=1, NUM_KEYS do
		local unmonitoredKey = keys[i] and not keyPattern[i]
		if unmonitoredKey then
			return false
		end
		local pressedMatch = keys[i] and keyPattern[i]
		pressedKeyMatch = pressedKeyMatch or pressedMatch
		local blankMatch = not keys[i] and not keyPattern[i]
		local keyMatch = pressedMatch or blankMatch
		patternMatch = patternMatch and keyMatch
	end
	return patternMatch or (pressedKeyMatch and "partial" or false)
end

return M


