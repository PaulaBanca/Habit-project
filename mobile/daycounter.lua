local M={}
daycounter=M

local jsonreader=require "jsonreader"
local os=os
local system=system
local math=math
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
  return math.ceil(secs/60/60/24)
end

function getDaysMissed()
  if not lastDate then
    return nil
  end
  local diffsecs=os.difftime(os.time(today), os.time(lastDate))
  return secsToDays(diffsecs)
end

function getDayCount()
  local diffsecs=os.difftime(os.time(today), os.time(data.start))
  return secsToDays(diffsecs)
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