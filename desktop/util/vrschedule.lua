local M={}
vrschedule=M

local system=system
local math=math
local print=print
local table=table
local pairs=pairs
local serpent=require "serpent"

setfenv(1,M)

local schedules

local function normRand()
  return math.sqrt(-2 * math.log(math.random())) * math.cos(2 * math.pi * math.random()) / 2
end

local function generateVR(averageGap,deviation,steps)
  local rd={} 
  local final={}
  local lastGap=0
  for m=1,steps do
    final[m]=false
    if m==lastGap+averageGap then
      rd[m]=true
      lastGap=m
    end
  end
  for k,v in pairs(rd) do
    local offset=math.floor(normRand()*deviation+0.5)
    final[k+offset]=true
  end
  return final
end

function setup(n,averageGap,deviation,steps)
  schedules=schedules or {}
  local vr=generateVR(averageGap,deviation,steps)
  schedules[n]=vr
end

function start()
end

function reward(i)
  return table.remove(schedules[i])
end

return M