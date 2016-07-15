local M={}
serverkeylistener=M

local events=require "events"
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

local down={}
Runtime:addEventListener("key", function(event)
  local key=tonumber(event.keyName)
  key=key or arrowMapping[event.keyName]
  if not key or type (key)=="number" and key<1 or key>NUM_KEYS then
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