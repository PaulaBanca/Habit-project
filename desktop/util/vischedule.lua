local M={}
vischedule=M

local system=system
local math=math
local print=print
local table=table
local serpent=require "serpent"

setfenv(1,M)

local schedules

local function generateVI(intervalMillis,steps)
  local rd={}
  for m=1,steps do
    local interval
    if m==steps then
      interval=intervalMillis*(1+(math.log(steps)))
    else
      interval=intervalMillis*(1+math.log(steps)+(steps-m)*math.log(steps-m)-(steps-m+1)*math.log(steps-m+1))
    end

    local order
    repeat
      order=math.random(steps)
    until not rd[order]
    rd[order]=interval
  end
  return rd
end

function setup(n,intervalMillis,steps)
  schedules=schedules or {}
  local vi=generateVI(intervalMillis,steps)
  schedules[n]=vi
end

local lastTime={}
function start()
  for i=1,#schedules do
    lastTime[i]=system.getTimer()
  end
end

local pauseTime
function pause()
  pauseTime=system.getTimer()
end

function resume()
  if not pauseTime then
    return
  end
  local interval=system.getTimer()-pauseTime
  pauseTime=nil
  for i=1,#schedules do
    lastTime[i]=lastTime[i]+interval
  end
end

function reward(i)
  if pauseTime then
    resume()
  end
  local t=system.getTimer()-lastTime[i]
  local nextT=schedules[i][1]
  if t>=nextT then
    lastTime[i]=system.getTimer()
    table.remove(schedules[i], 1)
    return true
  end
end

return M