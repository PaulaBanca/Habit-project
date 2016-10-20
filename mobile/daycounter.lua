local M={}
daycounter=M

local jsonreader=require "jsonreader"
local os=os
local system=system
local math=math
local pairs=pairs
local type=type

setfenv(1,M)

local path=system.pathForFile("days.json",system.DocumentsDirectory)
local data=jsonreader.load(path) or {start=os.date("*t"),practices={}}
local lastDate=data.last
local today=os.date("*t")

if not data.version then
  for i=1,#data.practices do
    if type(data.practices[i])=="number" then
      data.practices[i]={[data.practices[i]]=true}
    end
  end
  data.version=1
elseif data.version==1 then
  for i=1,#data.practices do
    for k=1,2 do
      if type(data.practices[i][k])=="boolean" then
        data.practices[i][k]=1
      end
    end
  end
  data.version=2
end  

local function secsToDays(secs)
  return math.floor(secs/60/60/24)
end


local function getDayStartDate(d)
  local n={}
  for k,v in pairs(d) do
    n[k]=v
  end
  n.hour=0
  n.min=0
  n.sec=0
  return n
end

function getDaysDiff(d1,d2)
  local diffsecs=os.difftime(os.time(getDayStartDate(d1)), os.time(getDayStartDate(data.start)))
  return secsToDays(diffsecs)
end

function getDaysMissed()
  if not lastDate then
    return nil
  end
  return getDaysDiff(today,lastDate)
end

function getDayCount()
  return getDaysDiff(today,data.start)
end

local practiceDay
function setPracticeDay(day)
  practiceDay=day
end

function getPracticeDay()
  return practiceDay
end

function completedPractice(track)
  data.last=today
  if not data.practices[practiceDay] then
    data.practices[practiceDay]={}
  end
  data.practices[practiceDay][track]=(data.practices[practiceDay][track] and 1 or 0) +1
  jsonreader.store(path,data)
end

function getPracticed(day)
  return data.practices[day]
end

return M