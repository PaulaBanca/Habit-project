local M={}
incompletetasks=M

local composer=require "composer"
local jsonreader=require "jsonreader"
local system=system
local table=table
local assert=assert
local _=require "util.moses"

setfenv(1,M)

local path=system.pathForFile("incomplete.json",system.DocumentsDirectory)
local data=jsonreader.load(path) or {}

local lastDest
function getNext()
  if #data==0 then
    return false
  end
  local dest=_.clone(data[1])
  lastDest=dest
  composer.gotoScene(dest.scene,{params=dest.params})
  return true
end

function lastCompleted()
  for i=1,#data do
    if lastDest==data[i] then
      assert(table.remove(data, i)==lastDest)
      jsonreader.store(path,data)
      lastDest=nil
      return
    end
  end
  assert(not lastDest, "incompletetasks.lua: lastDest does not match entry in data file")
end

function push(scene,params)
  params=params or {}
  params.resumed=true
  data[#data+1]={scene=scene,params=params}
  jsonreader.store(path,data)
  params.resumed=nil
end

function removeLast(scene)
  for i=#data,1,-1 do
    if data[i].scene==scene then
      assert(table.remove(data, i).scene==scene)
      break
    end
  end
  jsonreader.store(path,data)
end

function removeFirst(scene)
  for i=1,#data do
    if data[i].scene==scene then
      assert(table.remove(data, i).scene==scene)
      break
    end
  end
  jsonreader.store(path,data)
end

return M