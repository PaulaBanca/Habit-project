local M={}
logger=M

local csv=require "csv"
local user=require "user"
local _=require "util.moses"
local assert=assert
local tostring=tostring
local pairs=pairs
local os=os
local system=system
local setmetatable=setmetatable
local type=type
local print=print
local table=table

setfenv(1,M)

local additionalData={}
local validKeys={
  iterations="setIterations",
  mistakes="setTotalMistakes",
  track="setTrack",
  practiceProgress="setProgress",
  restartForced="setRestartForced",
  correctKeyPattern="setCorrectKeys",
  feedbackPattern="setFeedbackPattern",
  moveSuppressed="setMoveSuppressed",
  matchesSuppressedMove="setMatchesSuppressedMove",
  monitoredKeyPattern = "setMonitoredKeyPattern",
  matchesPattern = "setMatchesPattern",
  indexBeingSkipped = "setIndexBeingSkipped",
  playedSuppressedMove = "setPlayedSuppressedMove",
  mistakeDuringMove = "setMistakeDuringMove",
  intrudedSequence = "setIntrudedSequence",
  intrudedStep = "setIntrudedStep",
}

local defaultValues={
  complete=false,
  wasCorrect=false
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

  t=setmetatable(t,{
    __index=function(t,k)
      if defaultValues[k] then
        return defaultValues[k]
      end
      return ''
    end
  })
  return t
end

local csvWriter
function log(_type,t)
  if not csvWriter then
    local filename=('%s-recall-%s.csv'):format(user.getID(),os.date('%T_%F'))
    filename=filename:gsub(':','·')
    csvWriter=csv.create(system.pathForFile(filename,system.DocumentsDirectory),_.keys(t))
  end
  t.userid=user.getID()
  csvWriter(t)
end

return M