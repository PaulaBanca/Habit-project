local M={}
serverkeylistener=M

local events=require "events"
local composer=require "composer"
local NUM_KEYS=NUM_KEYS
local Runtime=Runtime
local tonumber=tonumber
local print=print
local type=type

setfenv(1,M)

local arrowMapping={
  up=1,
  right=2,
  down=3,
  left=4
}

local reverseMapping={
  up="left",
  right="down",
  down="right",
  left="up",
  ["1"]=4,
  ["2"]=3,
  ["3"]=2,
  ["4"]=1
}

local down={}
Runtime:addEventListener("key", function(event)
  local reverseKeys=composer.getVariable("left handed")
  local keyName=event.keyName
  if reverseKeys then
    keyName=reverseMapping[keyName]
  end
  local key=tonumber(keyName)
  key=key or arrowMapping[keyName]
  if not key or type (key)=="number" and key<1 or key>NUM_KEYS then
    if event.keyName=="space" and event.phase=="up" then
      events.fire({
        type="start sequence input"
      })
    end
    return false
  end
  if event.phase=="down" and not down[key] then
    down[key]=true
    events.fire({
      type="key played",
      note=key
    })
  end
  if event.phase=="up" and down[key] then
    down[key]=false
    events.fire({
      type="key released",
      note=key
    })
  end
end)

return M