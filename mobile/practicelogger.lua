local M={}
practicelogger=M

local jsonreader=require "jsonreader"
local system=system

setfenv(1,M)

local path=system.pathForFile("practices",system.DocumentsDirectory)
local data=jsonreader.load(path) or {practices={},attempts={}}

function logPractice(track)
  data.practices[track]=getPractices(track)+1
  jsonreader.store(path,data)
end

function getPractices(track)
  return data.practices[track] or 0
end

function logAttempt(track)
  data.attempts[track]=getAttempts(track)+1
  jsonreader.store(path,data)
end

function getAttempts(track)
  return data.attempts[track] or 0
end

return M