local M={}
tunemanager=M

local tunes=require "tunes"
local stimuli=require "stimuli"
local type=type

setfenv(1,M)

local tns=tunes.getTunes()
local stim={}
for i=1,#tns do
  stim[i]=tunes.getStimulus(tns[i])
end

local discarded
function setDiscarded(index)
  discarded=index
end

local preferred
function setPreferred(index)
  preferred=index
end

function getID(param)
  if param=="discarded" then
    return discarded
  end
  if param=="preferred" then
    return preferred
  end
  if param=="wildcard3" then
    return -3
  end
  if param=="wildcard6" then
    return -6
  end
  return param
end

function getTune(t)
  local i=getID(t)
  return i>0 and tns[i]
end

function getImg(t)
  local i=getID(t)
  if i<0 then
    return stimuli.getWildcardSimuli(-i)
  else
    return stimuli.getStimulus(i==t and t or i)
  end
end


return M