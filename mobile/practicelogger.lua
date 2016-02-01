local M={}
practicelogger=M

local jsonreader=require "jsonreader"
local system=system

setfenv(1,M)

local path=system.pathForFile("practices",system.DocumentsDirectory)
local data=jsonreader.load(path) or {}

function logPractice(track)
  data[track]=getPractices(track)+1
  jsonreader.store(path,data)
end

function getPractices(track)
  return data[track] or 0
end

return M