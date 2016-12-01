local M={}
unsent=M

local database=require "database.database"
local sqlite3=require "sqlite3"
local serpent=require "serpent"
local tostring=tostring
local print=print
local pairs=pairs
local tonumber=tonumber
local math=math
local table=table
local timer=timer
local native=native

setfenv(1,M)

local createTableCmd=[[
CREATE TABLE IF NOT EXISTS touch (
  ID INTEGER PRIMARY KEY ASC AUTOINCREMENT,
  touchPhase TEXT NOT NULL,
  x INTEGER NOT NULL,
  y INTEGER NOT NULL,
  date TEXT NOT NULL,
  time TEXT NOT NULL,
  appMillis INTEGER NOT NULL,
  delay INTEGER,
  wasCorrect TEXT NOT NULL,
  complete TEXT,
  track INTEGER,
  instructionIndex INTEGER,
  modesDropped INTEGER,
  iterations INTEGER,
  modeIndex INTEGER,
  key INTEGER,
  bank INTEGER,
  score INTEGER,
  practices INTEGER,
  isPractice TEXT,
  attempt INTEGER,
  userid TEXT NOT NULL,
  timeIntoSequence INTEGER NOT NULL,
  intro TEXT NOT NULL,
  mistakes INTEGER NOT NULL,
  deadmanSwitchRelease INTEGER,
  FOREIGN KEY(deadmanSwitchRelease) REFERENCES switchreleases(ID)
);
]]

database.runSQLQuery(createTableCmd)

local createTableCmd=[[
CREATE TABLE IF NOT EXISTS questionnaires (
  ID INTEGER PRIMARY KEY ASC AUTOINCREMENT,
  date TEXT NOT NULL,
  time TEXT NOT NULL,
  confidence_melody_1 INTEGER,
  confidence_melody_2 INTEGER,
  pleasure_melody_1 INTEGER,
  pleasure_melody_2 INTEGER,
  practice INTEGER,
  track INTEGER,
  userid TEXT NOT NULL
);
]]
database.runSQLQuery(createTableCmd)

local createTableCmd=[[
CREATE TABLE IF NOT EXISTS switchreleases (
  ID INTEGER PRIMARY KEY ASC AUTOINCREMENT,
  date TEXT NOT NULL,
  time TEXT NOT NULL,
  appMillis INTEGER NOT NULL,
  practice INTEGER,
  track INTEGER,
  releaseTime INTEGER,
  userid TEXT NOT NULL
);
]]
database.runSQLQuery(createTableCmd)

local insertQuestionnaireCmd=[[INSERT INTO questionnaires (confidence_melody_1,confidence_melody_2,pleasure_melody_1,pleasure_melody_2,practice,track,date,time,userid) VALUES (%s,%s,%s,%s,%s,%s,"%s","%s","%s");]]

local preparedSwitchRelease=database.prepare([[INSERT INTO switchreleases (releaseTime,practice,track,date,time,appMillis,userid) VALUES (:releaseTime,:practice,:track,:date,:time,:appMillis,:userid);]])

local preparedInsert=database.prepare([[INSERT INTO touch (touchPhase,x,y,date,time,appMillis,delay,wasCorrect,complete,track,instructionIndex,modesDropped,iterations,modeIndex,key,bank,score,practices,isPractice,attempt,userid,timeIntoSequence,intro,mistakes,deadmanSwitchRelease) VALUES (:touchPhase,:x,:y,:date,:time,:appMillis,:delay,:wasCorrect,:complete,:track,:instructionIndex,:modesDropped,:iterations,:modeIndex,:keyIndex,:bank,:score,:practices,:isPractice,:attempt,:userid,:timeIntoSequence,:intro,:mistakes,:deadmanSwitchRelease);]])


local queuedCommands={}
function log(t)
  if t.touchPhase then
    t.delay=tostring(t.delay or "-1")
    t.wasCorrect =tostring(t.wasCorrect or "false")
    t.complete=tostring(t.complete)
    t.track =tostring(t.track or "NULL")
    t.instructionIndex =tostring(t.instructionIndex or "NULL")
    t.modesDropped =tostring(t.modesDropped or "NULL")
    t.iterations =tostring(t.iterations or "NULL")
    t.modeIndex =tostring(t.modeIndex or "NULL")
    t.keyIndex =tostring(t.keyIndex or "NULL")
    t.bank =tostring(t.bank or "NULL")
    t.score =tostring(t.score or "NULL")
    t.intro=tostring(t.intro)
    t.mistakes=(t.mistakes or 0)
    t.isPractice=tostring(t.isPractice)
    t.deadmanSwitchRelease=t.deadmanSwitchRelease or "NULL"
    queuedCommands[#queuedCommands+1]=t
  elseif t.releaseTime then
    preparedSwitchRelease:bind_names(t)
    database.step(preparedSwitchRelease)
  else
    database.runSQLQuery(insertQuestionnaireCmd:format(tostring(t.confidence_melody_1 or "NULL"),tostring(t.confidence_melody_2 or "NULL"),tostring(t.pleasure_melody_1 or "NULL"),tostring(t.pleasure_melody_2 or "NULL"),t.practice,t.track,t.date,t.time,t.userid))
  end
  return database.lastRowID()
end

local hasTouchesCmd="select exists (select 1 from touch); "
local preparedGetTouches=database.prepare([[SELECT * FROM touch ORDER BY ID ASC limit 50;]])
local hasQuestionnairesCmd="select exists (select 1 from questionnaires); "
local preparedGetQuestionnaires=database.prepare([[SELECT * FROM questionnaires ORDER BY ID ASC limit 50;]])
local hasSwitchReleasesCmd="select exists (select 1 from switchreleases); "
local preparedGetSwitchReleases=database.prepare([[SELECT * FROM switchreleases ORDER BY ID ASC limit 50;]])

function fetch50(preparedStmt,callback)
  preparedStmt:reset()
  while true do
    local res=preparedStmt:step()
    if res==sqlite3.DONE then
      return callback(nil,true)
    end
    if res==sqlite3.ERROR then
      error(db:errmsg())
    end
    if res==sqlite3.ROW then
      callback(preparedStmt:get_named_values())
    end
  end
end

function getTouches(callback)
  fetch50(preparedGetTouches,callback)
end

local removeSentCmd=[[DELETE FROM touch WHERE ID <= %d;]]
function clearUpTo(id)
  database.runSQLQuery(removeSentCmd:format(id))
end

function getQs(callback)
  fetch50(preparedGetQuestionnaires,callback)
end

local removeSentQsCmd=[[DELETE FROM questionnaires WHERE ID <= %d;]]
function clearQsUpTo(id)
  database.runSQLQuery(removeSentQsCmd:format(id))
end

function getSwitchReleases(callback)
  fetch50(preparedGetSwitchReleases,callback)
end

local removeSentSwitchReleasesCmd=[[DELETE FROM switchreleases WHERE ID <= %d;]]
function clearSwitchReleasedUpTo(id)
  database.runSQLQuery(removeSentSwitchReleasesCmd:format(id))
end


function flushQueuedCommands(onComplete)
  local total=#queuedCommands
  if total==0 then
    return onComplete()
  end
  native.setActivityIndicator(true)
  timer.performWithDelay(1, function()
    database.runSQLQuery("BEGIN TRANSACTION;")
    for i=1, #queuedCommands do
      preparedInsert:bind_names(queuedCommands[i])
      database.step(preparedInsert)
    end
    database.runSQLQuery("END TRANSACTION;")
    queuedCommands={}
    native.setActivityIndicator(false)
    onComplete()
  end)
end

function hasDataToSend()
  local hasData=false
  database.runSQLQuery(hasQuestionnairesCmd,function(udata,cols,values,names)
    hasData=hasData or values[1]>0
    return 0
  end)
  if hasData then
    return true
  end
  database.runSQLQuery(hasTouchesCmd,function(udata,cols,values,names)
    hasData=hasData or values[1]>0
    return 0
  end)
  if hasData then
    return true
  end
  database.runSQLQuery(hasSwitchReleasesCmd,function(udata,cols,values,names)
    hasData=hasData or values[1]>0
    return 0
  end)

  return hasData
end

function getUnsent()
  return queuedCommands
end

return M