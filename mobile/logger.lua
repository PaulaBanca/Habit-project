local M={}
logger=M

local jsonreader=require "jsonreader"
local system=system
local parse = require('plugin.parse')
local user=require "user"
local serpent=require "serpent"
local unsent=require "database.unsent"
local print=print
local assert=assert
local timer=timer
local table=table
local tostring=tostring
local error=error
local pairs=pairs
local ipairs=ipairs
local display=display

setfenv(1,M)

function createLoginCallback(callback)
  local sessionToken
  return function(ok,res,info)
    if not ok then
      print('err', res )
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

function setPractices(practices)
  additionalData["practices"]=practices
end

function log(t)
  t.userid=user.getID()
  if not t.pleasure_melody_1 then
    for k, v in pairs(additionalData) do
      t[k]=v    
    end
  end
  parse.request(parse.Object.create, "Data")
    :data(t)
    :response(function(ok, res)
      if ok then
      else
        unsent.log(t)
      end
  end)
end

local catchUp
local syncMessage
function startCatchUp()
  catchUp=timer.performWithDelay(1000, function()
    local b
    local nothingToSync=true
    unsent.get(function(col,done)
      nothingToSync=false
      if not b then 
        b=parse.batch.new()
      end
      b.create("Data", col)

      if done then
        parse.request(parse.Object.batch)
          :data(b.getBatch())
          :response(function(ok, res)
          if ok then 
            unsent.clearUpTo(col.ID)
          end
        end)
      end
    end)

    b=nil
    unsent.getQs(function(col,done)
      nothingToSync=false
      if not b then 
        b=parse.batch.new()
      end
      b.create("Data", col)
      
      if done then
        parse.request(parse.Object.batch)
          :data(b.getBatch())
          :response(function(ok, res)
          if ok then 
            for _, result in ipairs(res) do
              if result.success then
                print (result.success.createdAt)
              else
                print(result.error.error, result.error.code)
              end
            end
            unsent.clearQsUpTo(col.ID)
          end
        end)
      end
    end)
    if nothingToSync then 
      if syncMessage then
        syncMessage:removeSelf()
        syncMessage=nil
      end
    elseif not syncMessage and unsent.hasDataToSend() then
      syncMessage=display.newText({
        text="Background syncing...",
        fontSize=15,
      })
      syncMessage.anchorX=0
      syncMessage.anchorY=0
      syncMessage.x=10
      syncMessage.y=10
    end
  end,-1)
end

function stopCatchUp()
  timer.cancel(catchUp)
end

return M