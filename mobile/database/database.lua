local M={}
database=M

require "database.sqlite3constants"
local sqlite3constants=sqlite3constants

local sqlite3=require "sqlite3"
local system=system
local Runtime=Runtime
local string=string
local error=error
local print=print

setfenv(1,M)

local path=system.pathForFile("data.db",system.DocumentsDirectory)
local db=sqlite3.open(path)

function runSQLQuery(sql,callback,user_data)
  local code=db:exec(sql,callback,user_data)
  if code~=sqlite3.OK then 
    local errorCode=sqlite3constants.getLookupCode(code)
    local msg=string.format("Error Accessing Database: %s.\n Command '%s' returned %s",path,sql,errorCode)
    error (msg)
  end
end

function prepare(sql)
  local s=db:prepare(sql)
  if not s then
    error(db:errmsg())
  end
  return s
end

function step(prepared)
  local res
  while true do
    res=prepared:step()
    if res==sqlite3.DONE then
      break
    end
    if res==sqlite3.ERROR then
      error(db:errmsg())
    end
  end
  prepared:reset()
end

function lastRowID()
  return db:last_insert_rowid()
end

local function onSystemEvent( event )
  if event.type=="applicationExit" then
    if db and db:isopen() then
      db:close()
    end
  end
end
Runtime:addEventListener("system",onSystemEvent)

return M