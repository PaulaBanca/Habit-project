local M={}
keypattern=M

local NUM_KEYS=NUM_KEYS
local table=table

setfenv(1,M)

function create(keysDown)
  local pattern={}
  for i=1, NUM_KEYS do
    pattern[i]=keysDown[i] and "1" or "0"
  end
  return table.concat(pattern, "")
end

return M