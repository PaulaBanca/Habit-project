local M={}
phasemanager=M
local events=require "events"
local tunemanager=require "tunemanager"
local _=require "util.moses"
local table=table
local print=print

-- listens for mistakes and gets phase
-- must also get track
-- must also progress to next phase if mistakes made.
-- needs to know when a play session is correct

setfenv(1,M)

local phases

function setPhases(phs)
  phases = phs
end

function getPhase()
  return phases[1].phase
end

function getCurrentStimulus()
  return tunemanager.getImg(getCurrentTrack())
end

function getCurrentTrack()
  return phases[1].track
end

local mistakes=0
events.addEventListener('mistake',function()
  mistakes=mistakes+1
end)

events.addEventListener('phase finished',function()
  if mistakes==0 and phases[1].allowSkipForwards then
    local curTrack=phases[1].track
    phases=_.reject(phases,function(_,v)
      return v.track==curTrack
    end)
  else
    table.remove(phases, 1)
  end
  mistakes=0
  events.fire({type='phase change'})
end)

return M