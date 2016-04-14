local M={}
doorschedule=M

local jsonreader=require "util.jsonreader"
local _=require "util.moses"
local system=system
local table=table

setfenv(1,M)

local round=0
local schedules={jsonreader.load(system.pathForFile("data/schedule1.json",system.ResourceDirectory))}

do 
  local SCHEDULE2_BLOCKS=4
  local blocks={}
  local order=_.shuffle(_.range(1,SCHEDULE2_BLOCKS))
  for i=1, SCHEDULE2_BLOCKS do
    local block=jsonreader.load(system.pathForFile(("data/schedule2_block%d.json"):format(i),system.ResourceDirectory))
    blocks[order[i]]=block
  end
  blocks=_.flatten(blocks,true)
  schedules[#schedules+1]=blocks
end

local schedule
function start()
  schedule=table.remove(schedules,1)
  round=0
end

function nextRound()
  round=round+1
  local setup=schedule[round]
  if not setup then
    schedule=nil
    return
  end
  return {leftTune=setup.tunes[1],rightTune=setup.tunes[2],leftReward=setup.rewards[1],rightReward=setup.rewards[2]}
end

return M