local M={}
unsent=M

local database=require "database.database"
local sqlite3=require "sqlite3"
local serpent=require "serpent"
local tostring=tostring
local print=print
local pairs=pairs
local timer=timer
local native=native
local table = table
local assert = assert

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
  lives INTEGER,
  userid TEXT NOT NULL,
  timeIntoSequence INTEGER NOT NULL,
  intro TEXT NOT NULL,
  mode TEXT NOT NULL,
  mistakes INTEGER NOT NULL,
  deadmanSwitchRelease INTEGER,
  practiceProgress TEXT,
  viAverage INTEGER,
  rewardTarget INTEGER,
  rewardsEarnt INTEGER,
  rewardsExtinguished TEXT,
  scheduleType TEXT,
  scheduleParameter INTEGER,
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
  pressedTime TEXT NOT NULL,
  releaseTime TEXT NOT NULL,
  appMillis INTEGER NOT NULL,
  practice INTEGER,
  track INTEGER,
  releaseDuration INTEGER,
  userid TEXT NOT NULL
);
]]
database.runSQLQuery(createTableCmd)

local createTableCmd=[[
CREATE TABLE IF NOT EXISTS sessions (
  ID INTEGER PRIMARY KEY ASC AUTOINCREMENT,
  date TEXT NOT NULL,
  time TEXT NOT NULL,
  appMillis INTEGER NOT NULL,
  type TEXT NOT NULL,
  practicesStarted INTEGER,
  practicesCompleted INTEGER,
  userid TEXT NOT NULL
);
]]
database.runSQLQuery(createTableCmd)

local preparedQuestionnaire=database.prepare([[INSERT INTO questionnaires (confidence_melody_1,confidence_melody_2,pleasure_melody_1,pleasure_melody_2,practice,track,date,time,userid) VALUES (:confidence_melody_1,:confidence_melody_2,:pleasure_melody_1,:pleasure_melody_2,:practice,:track,:date,:time,:userid);]])

local preparedSwitchRelease=database.prepare([[INSERT INTO switchreleases (releaseDuration,practice,track,date,pressedTime,releaseTime,appMillis,userid) VALUES (:releaseDuration,:practice,:track,:date,:pressedTime,:releaseTime,:appMillis,:userid);]])

local preparedInsert=database.prepare([[INSERT INTO touch (touchPhase,x,y,date,time,appMillis,delay,wasCorrect,complete,track,instructionIndex,modesDropped,iterations,modeIndex,key,bank,score,practices,isPractice,attempt,userid,timeIntoSequence,intro,mistakes,deadmanSwitchRelease,mode,practiceProgress,lives,viAverage,rewardTarget,rewardsEarnt,rewardsExtinguished,scheduleType,scheduleParameter) VALUES (:touchPhase,:x,:y,:date,:time,:appMillis,:delay,:wasCorrect,:complete,:track,:instructionIndex,:modesDropped,:iterations,:modeIndex,:keyIndex,:bank,:score,:practices,:isPractice,:attempt,:userid,:timeIntoSequence,:intro,:mistakes,:deadmanSwitchRelease,:mode,:practiceProgress,:lives,:viAverage,:rewardTarget,:rewardsEarnt,:rewardsExtinguished,:scheduleType,:scheduleParameter);]])

local preparedSession=database.prepare([[INSERT INTO sessions (type,practicesStarted,practicesCompleted,date,time,appMillis,userid) VALUES (:type,:practicesStarted,:practicesCompleted,:date,:time,:appMillis,:userid);]])

local function getNullColumns(tablename)
  local nullColumns={}
  database.runSQLQuery(([[PRAGMA table_info("%s");]]):format(tablename),function(udata,cols,values,names)
      for i=1,#names do
        if names[i]=="notnull" and values[i]=="0" then
          for k=1,#names do
            if names[k]=="name" and values[k]~="ID" then
              nullColumns[values[k]]="NULL"
            end
          end
        end
      end
      return 0
  end)
  return nullColumns
end

local nullValues={}
local tableNames={}

local function readTableNamesFromDatabase()
  database.runSQLQuery([[SELECT name FROM sqlite_master WHERE type='table';]],function(udata,cols,values,names)
    if values[1]~="sqlite_sequence" then
      tableNames[#tableNames+1]=values[1]
    end
    return 0
  end)
  for i=1, #tableNames do
    nullValues[tableNames[i]]=getNullColumns(tableNames[i])
  end
end

readTableNamesFromDatabase()

local blacklist = {rewards = true}

for i = #tableNames, 1, -1 do
  local name=tableNames[i]
  if blacklist[name] then
    assert(name == table.remove(tableNames, i))
  end
end

nullValues["touch"]["delay"]=-1
nullValues["touch"]["wasCorrect"]=false
nullValues["touch"]["mistakes"]=0
nullValues["touch"]["viAverage"]=-1
nullValues["touch"]["scheduleParameter"]=-1

local function fillInNulls(tablename,t)
  for k,v in pairs(nullValues[tablename]) do
    if t[k]==nil then
      t[k]=v
    end
  end
  for k,v in pairs(t) do
    t[k]=tostring(v)
  end
end

local function preparedHandler(stmt,t)
  stmt:bind_names(t)
  database.step(stmt)
end

local logHandler={
  touch=function(t)
    fillInNulls("touch", t)
    preparedHandler(preparedInsert,t)
  end,
  switchRelease=function(t)
    fillInNulls("switchreleases", t)
    preparedHandler(preparedSwitchRelease,t)
  end,
  session=function(t)
    fillInNulls("sessions", t)
    preparedHandler(preparedSession,t)
  end,
  questionnaire=function(t)
    fillInNulls("questionnaires", t)
    preparedHandler(preparedQuestionnaire,t)
  end
}

function log(type,t)
  logHandler[type](t)
  return database.lastRowID()
end

local hasDataCmd={}
local getDataCmd={}
local deleteDataCmd={}
local countDataCmd={}

for i=1, #tableNames do
  local table=tableNames[i]
  hasDataCmd[table]=("select exists (select 1 from %s); "):format(table)
  getDataCmd[table]=database.prepare(([[SELECT * FROM %s ORDER BY ID ASC limit 50;]]):format(table))
  deleteDataCmd[table]=([[DELETE FROM %s WHERE ID <= %s;]]):format(table,"%s")
  countDataCmd[table]=([[SELECT COUNT(*) FROM %s;]]):format(table)
end

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

function getTableNames()
  return tableNames
end

function getData(tablename,callback)
  fetch50(getDataCmd[tablename],callback)
end

function clearDataUpTo(tablename,id)
  database.runSQLQuery(deleteDataCmd[tablename]:format(id))
end

function hasDataToSend()
  for k,v in pairs(hasDataCmd) do
    local foundData=false
    database.runSQLQuery(v,function(udata,cols,values,names)
      foundData=foundData or values[1]>0
      return 0
    end)
    if foundData then
      return true
    end
  end
  return false
end

function count(tablename)
  local num
  database.runSQLQuery(countDataCmd[tablename],function(udata,cols,values,names)
    num=values[1]
    return 0
  end)
  return num
end

return M