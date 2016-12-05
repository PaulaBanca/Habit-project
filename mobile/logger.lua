local M={}
logger=M

local jsonreader=require "jsonreader"
local user=require "user"
local json=require "json"
local serpent=require "serpent"
local unsent=require "database.unsent"
local system=system
local print=print
local assert=assert
local timer=timer
local table=table
local tostring=tostring
local error=error
local pairs=pairs
local ipairs=ipairs
local display=display
local type=type
local network=network

setfenv(1,M)

local additionalData={}
function setModesDropped(modes)
  additionalData["modesDropped"]=modes
end

function setIterations(iterations)
  additionalData["iterations"]=iterations
end

function setModeIndex(modeIndex)
  additionalData["modeIndex"]=modeIndex
end

function setScore(score)
  additionalData["score"]=score
end

function setBank(bank)
  additionalData["bank"]=bank
end

function setIsScheduled(scheduled)
  additionalData["isPractice"]=scheduled
end

function setIntro(intro)
  additionalData["intro"]=intro
end

function setPractices(practices)
  additionalData["practices"]=practices
end

function setAttempts(attempts)
  additionalData["attempt"]=attempts
end

function setTotalMistakes(mistakes)
  additionalData["mistakes"]=mistakes
end 

function setTrack(track)
  additionalData["track"]=track
end 

function setMode(mode)
  additionalData["mode"]=mode
end 

function setDeadmansSwitchID(id)
  additionalData["deadmanSwitchRelease"]=id
end

function createLoggingTable()
  local t={}
  for k, v in pairs(additionalData) do
    t[k]=v    
  end
  return t
end

function log(type,t)
  t.userid=user.getID()
  return unsent.log(type,t)
end

function send(tableName,getFunc,clearFunc,doneFunc)
  local b
  local lastID
  local rows={}
  getFunc(tableName,function(row,done)
    if done then
      if #rows==0 then
        return doneFunc(true)
      end

      local quitOut
      local function doneWrapper()
        assert(not quitOut,"Done Wrapper called twice!")
        quitOut=true
        doneFunc(false)
      end
      local listener=function(event)
        if event.isError then
            print("Network error: ", event.response, " Status " , event.status)
            doneWrapper()
            return
        else 
          if event.phase=="progress" then
            print ((event.bytesTransferred*100/event.bytesEstimated).."%")
          elseif event.phase=="ended" then
            if event.status>=200 and event.status<=201 then
              if event.response=="OK" then
                clearFunc(tableName,lastID)
              end
            else
              print("Network error: ", event.response, " Status " , event.status)
            end
            doneWrapper()
          end
        end
      end

      local params={}
      params.progress="upload"
      params.body=json.encode(rows)
      network.request("http://multipad-server.herokuapp.com/submit", "POST", listener, params)
      -- network.request("http://localhost:8080/submit", "POST", listener, params)
      
      return
    end
    for k,v in pairs(row) do
      if v=="NULL" then
        row[k]=nil
      end
    end
    rows[#rows+1]=row
    lastID=row.ID
  end)
end

local syncMessage
function startCatchUp()
  if syncMessage then
    return
  end
  if not syncMessage then
    syncMessage=display.newText({
      text="Saving do not close!",
      fontSize=15,
    })
    syncMessage.anchorX=0
    syncMessage.anchorY=0
    syncMessage.x=10
    syncMessage.y=10
    syncMessage:setTextColor(1, 0, 0)
  end

  unsent.flushQueuedCommands(function()
    syncMessage.text="Background Syncing..."
    syncMessage:setTextColor(1)
    local tables=unsent.getTableNames()
    local cur=1
    local process
    process=function(complete)
      if complete then
        cur=cur+1
        if cur>#tables then
          syncMessage:removeSelf()
          syncMessage=nil
          return
        end
      end
      local table=tables[cur]
      send(table,unsent.getData,unsent.clearDataUpTo,process)
    end
    process()
  end)
end

return M