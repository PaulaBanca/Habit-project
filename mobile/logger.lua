local M={}
logger=M

local user=require "user"
local json=require "json"
local serpent=require "serpent"
local unsent=require "database.unsent"
local _=require "util.moses"
local i18n = require ("i18n.init")
local print=print
local assert=assert
local tostring=tostring
local pairs=pairs
local display=display
local network=network

setfenv(1,M)

local blockSyncing = false

local additionalData={}
local validKeys={
  modesDropped="setModesDropped",
  iterations="setIterations",
  modeIndex="setModeIndex",
  score="setScore",
  bank="setBank",
  isPractice="setIsScheduled",
  intro="setIntro",
  practices="setPractices",
  attempt="setAttempts",
  mistakes="setTotalMistakes",
  track="setTrack",
  mode="setMode",
  lives="setLives",
  deadmanSwitchRelease="setDeadmansSwitchID",
  practiceProgress="setProgress"
}

function set(key,value)
  assert(validKeys[key],tostring(key) .. " not recognised")
  additionalData[key]=value
end

function get(key)
  assert(validKeys[key],tostring(key) .. " not recognised")
  return additionalData[key]
end

for k,v in pairs(validKeys) do
  M[v]=_.bind(set,k)
  M[v:gsub("set","get")]=_.bind(get,k)
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


function sendRows(rows,doneFunc)
  local quitOut
  local function doneWrapper(serverHappy)
    assert(not quitOut,"Done Wrapper called twice!")
    quitOut=true
    doneFunc(serverHappy)
  end
  local listener=function(event)
    if event.isError then
        print("Network error: ", event.response, " Status " , event.status)
        doneWrapper(false)
        return
    else
      if event.phase=="progress" then
        print ((event.bytesTransferred*100/event.bytesEstimated).."%")
      elseif event.phase=="ended" then
        local isSuccess=false
        if event.status>=200 and event.status<=201 then
          isSuccess=event.response=="OK"
        else
          print("Network error: ", event.response, " Status " , event.status)
        end
        doneWrapper(isSuccess)
      end
    end
  end

  local params={}
  params.progress="upload"
  params.body=json.encode(rows)
  network.request("http://habitproject2017.herokuapp.com/submit", "POST", listener, params)
  -- network.request("http://localhost:8080/submit", "POST", listener, params)
end

function getRows(tableName,getFunc)
  local rows={}
  getFunc(tableName,function(row,done)
    if done then
      return
    end
    for k,v in pairs(row) do
      if v=="NULL" then
        row[k]=nil
      end
    end
    rows[#rows+1]=row
  end)
  return rows
end

local stop
function stopCatchUp()
  stop=true
end

local syncMessage
function startCatchUp()
  if blockSyncing then
    return
  end
  if syncMessage then
    return
  end
  if not syncMessage then
    syncMessage=display.newText({
      text=i18n("logger.saving"),
      fontSize=15,
    })
    syncMessage.anchorX=0
    syncMessage.anchorY=0
    syncMessage.x=10
    syncMessage.y=10
    syncMessage:setTextColor(1, 0, 0)
  end

  stop=false
  syncMessage.text=i18n("logger.syncing")
  syncMessage:setTextColor(1)
  local tables=unsent.getTableNames()
  local cur=1
  local process
  process=function(complete)
    if stop then
      syncMessage:removeSelf()
      syncMessage=nil
      return
    end
    if complete then
      cur=cur+1
      if cur>#tables then
        syncMessage:removeSelf()
        syncMessage=nil
        return
      end
    end
    local table=tables[cur]
    local rows=getRows(table,unsent.getData)
    if #rows==0 then
      return process(true)
    end

    sendRows(rows,function(sendSuccesful)
      if sendSuccesful then
        unsent.clearDataUpTo(table,rows[#rows].ID)
      end
      process(false)
    end)
  end
  process()
end

return M