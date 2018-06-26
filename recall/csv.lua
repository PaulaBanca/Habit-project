local M={}
csv=M

local table=table
local tostring=tostring

local ipairs=ipairs
local io=io
local assert=assert

setfenv(1,M)

local function testFileExists(path)
  local fh,err=io.open(path,"r")
  if fh then
    fh:close()
  end
  return fh~=nil
end

local function appendToFile(path,line)
  local fh=assert(io.open(path,"a+"))
  fh:write(line.."\n")
  fh:close()
end

function create(path,headers)
  if not testFileExists(path) then
    local s=table.concat(headers, ", ")
    appendToFile(path,s)
  end

  return function (t)
    local temp={}
    for k, v in ipairs(headers) do
      temp[k]=tostring(t[v] or 'false')
    end

    appendToFile(path,table.concat(temp, ", "))
  end
end

return M