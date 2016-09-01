local M={}
logger=M

local jsonreader=require "jsonreader"
local parse = require('plugin.parse')
local user=require "user"
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

setfenv(1,M)

function createLoginCallback(callback)
  local sessionToken
  return function(ok,res,info)
    if not ok then
      print('err', type (res)=="table" and serpent.block(res) or res )
      callback(false,res)
    else
      sessionToken=res.sessionToken
      if not sessionToken then
        return callback(false,res.error)
      end
      callback(true)
    end
  end
end

function create(userid,password,callback)
  parse.request(parse.User.create)
    :data({username=userid, password=password})
    :response(createLoginCallback(callback))
end

function login(userid,password,callback)
  parse.request(parse.User.login)
    :options({username=userid, password=password})
    :response(createLoginCallback(callback))
end

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

function setSequenceTime(timeIntoSequence)
  additionalData["timeIntoSequence"]=timeIntoSequence
end

function setPractices(practices)
  additionalData["practices"]=practices
end

function setTotalMistakes(mistakes)
  additionalData["mistakes"]=mistakes
end 

function log(t)
  t.userid=user.getID()
  if not t.pleasure_melody_1 then
    for k, v in pairs(additionalData) do
      t[k]=v    
    end
  end
  unsent.log(t)
end

function send(getFunc,clearFunc,doneFunc,dataName)
  local b
  local lastID
  getFunc(function(col,done)
    if done then
      if not b then
        return
      end
      parse.request(parse.Object.batch)
        :data(b.getBatch())
        :response(function(ok, res)
        if ok then 
          clearFunc(lastID)
        else
          print ("Err ",type(res)=="table" and serpent.block(res) or res)
        end
        doneFunc()
      end)
      return
    end
    if not b then
      b=parse.batch.new()
    end
    b.create(dataName, col)
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
      nothingToSync=nothingToSync and send(unsent.getTouches,unsent.clearUpTo,sendData,"TestingData")
      nothingToSync=nothingToSync and send(unsent.getQs,unsent.clearQsUpTo,sendData,"TestingData")

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