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

function createLoggingTable()
  local t={}
  for k, v in pairs(additionalData) do
    t[k]=v    
  end
  return t
end

function log(t)
  t.userid=user.getID()
  unsent.log(t)
end

local params={}
params.progress="upload"
params.body=json.encode({dataField,dataField,dataField})

function send(getFunc,clearFunc,doneFunc)
  local b
  local lastID
  local cols={}
  getFunc(function(col,done)
    if done then
      if #cols==0 then
        return
      end

      local quitOut
      local function doneWrapper()
        assert(not quitOut,"Done Wrapper called twice!")
        quitOut=true
        doneFunc()
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
                clearFunc(lastID)
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
      params.body=json.encode(cols)
      network.request("http://multipad-server.herokuapp.com/submit", "POST", listener, params)
      return
    end
    for k,v in pairs(col) do
      if v=="NULL" then
        col[k]=nil
      end
    end
    cols[#cols+1]=col
    lastID=col.ID
  end)
  return true
end

local syncMessage
local paused
function startCatchUp()
  paused=false

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
    local sendData
    sendData=function()
      if paused then 
        return
      end
      local nothingToSync=true
      nothingToSync=nothingToSync and send(unsent.getTouches,unsent.clearUpTo,sendData)
      nothingToSync=nothingToSync and send(unsent.getQs,unsent.clearQsUpTo,sendData)

      if nothingToSync and syncMessage then
        syncMessage:removeSelf()
        syncMessage=nil
      end
    end
    sendData()
  end)
end

function stopCatchUp()
  paused=true
end

return M