local M={}
logger=M

local csv=require "util.csv"
local lfs=require "lfs"
local _=require "util.moses"
local serpent=require "serpent"
local assert=assert
local pairs=pairs
local print=print
local os=os

setfenv(1,M)

local userid
function setUserID(id)
  userid=id
end

function create(filename,headers)
  local folder=("Data - User %s"):format(userid)
  local folderPath=os.getenv ("HOME").."/Multipad Server"
  if not lfs.chdir(folderPath) then
    assert(lfs.mkdir(folderPath))
  end
  folderPath=folderPath.."/"..folder
  if not lfs.chdir(folderPath) then
    assert(lfs.mkdir(folderPath))
  end

  local path=folderPath.."/"..filename..".csv"

  assert(userid,"logger.lua: no userid set")
  headers[#headers+1]="id"
  local addLine=csv.create(path,headers)

  local line
  local function blankLine()
    line={}
    for i=1,#headers do
      line[headers[i]]=""
    end
    line["id"]=userid
    return line
  end

  local set=function (k,v,force)
    assert(addLine,"logger.lua: Call create before set")
    line=line or blankLine()

    assert(line[k]~=nil,"logger.lua: No key '"..k.."' expected"..serpent.line(line,{comment=false}))
    assert(line[k]=="" or force,"logger.lua: Key '"..k.."' already has value")
    line[k]=v
    local full=true
    for k,v in pairs(line) do
      if k and v=="" then
        full=false
        break
      end
    end
    if full then
      addLine(line)
      line=nil
    end
  end
  return set
end

return M