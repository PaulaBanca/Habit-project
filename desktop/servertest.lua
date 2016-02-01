local M={}
servertest=M

local events=require "events"
local NUM_KEYS=NUM_KEYS
local Runtime=Runtime
local tonumber=tonumber

setfenv(1,M)

Runtime:addEventListener("key", function(event)
  local key=tonumber(event.keyName)
  if not key or key<1 or key>NUM_KEYS then
    return false
  end
  if event.phase=="down" then
    events.fire({
      type="key played",
      note=key
    })
  end
  if event.phase=="up" then
    events.fire({
      type="key released",
      note=key
    })
  end
end)

return M