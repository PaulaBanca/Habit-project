local M={}
training=M

local math=math

setfenv(1,M)
-- [[
--   Player plays N interations of the same tune
--   each iteration the highlight fades a little until the last Y are played without highlight

--   if the user makes a mistake the highlight at that sequence become moore visible next time
-- ]]

local opacities={}
function start(length)
  for i=1, length do
    opacities[i]=1
  end
end

function getHighlightOpacity(index)
  local a=opacities[index]
  opacities[index]=opacities[index]*0.9
  return a
end

function logMistake(index) 
  opacities[index]=math.min(1,opacities[index]*4)
end

return M