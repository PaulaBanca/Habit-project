local M={}
findfile=M

local jsonreader=require "util.jsonreader"
local system=system
local os=os
local io=io
local print=print
local assert=assert
local timer=timer

setfenv(1,M)

local path=system.pathForFile("found_files.json",system.DocumentsDirectory)
local temp=system.pathForFile(nil,system.TemporaryDirectory).."/found_files"
local database=jsonreader.load(path) or {}
local findfile=[[find %s -name "%s" > '%s']]
local fileExists=[[if [ -f "%s" ] ; then return 1; fi]]

function find(name)
  if database[name] then
    if os.execute(fileExists:format(database[name]))~=0 then
      return database[name]
    end
  end

  os.execute(findfile:format("~",name,temp))
  local file=assert(io.open(temp))
  database[name]=file:read()
  io.close(file)

  jsonreader.store(path,database)
  return database[name]
end

return M