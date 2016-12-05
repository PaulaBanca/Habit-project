local M={}
sessionlogger=M

local jsonreader=require "jsonreader"
local system=system
local os=os

setfenv(1,M)

local path=system.pathForFile("session.json",system.DocumentsDirectory)

local practicesStarted=0
local practicesCompleted=0

function logPracticeStarted()
  practicesStarted=practicesStarted+1
  logSessionEnd("update")
end

function logPracticeCompleted()
  practicesCompleted=practicesCompleted+1
  logSessionEnd("update")
end

function logSessionEnd(type)
  jsonreader.store(path,{
    time=os.date("%T"),
    date=os.date("%F"),
    appMillis=system.getTimer(),
    type=type,
    practicesStarted=practicesStarted,
    practicesCompleted=practicesCompleted,
  })
end

function getPreviousSession()
  return jsonreader.load(path)
end

function clearHistory()
  jsonreader.store(path,{})
end

return M