local M={}
events=M

local assert=assert
local ipairs=ipairs
local table=table
local print=print

setfenv(1,M)

local listenersByType={}

function addEventListener(type,listener)
  if not listenersByType[type] then 
    listenersByType[type]={}
  end
  local listeners=listenersByType[type]
  listeners[#listeners+1]=listener
end

function removeEventListener(type,listener)
  local listeners=listenersByType[type]
  for k,v in ipairs(listeners) do 
    if v==listener then
      table.remove(listeners,k)
      return
    end
  end
end

function fire(event)
  if not listenersByType[event.type] then
    print ("events.lua: WARNING event type with no listener "..event.type)
    return
  end
  for k,v in ipairs(listenersByType[event.type]) do
    v(event)
  end
end

return M