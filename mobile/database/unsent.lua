local M={}
unsent=M

local database=require "database.database"
local tostring=tostring
local print=print
local pairs=pairs
local serpent=require "serpent"
local tonumber=tonumber
local math=math

setfenv(1,M)

local createTableCmd=[[
CREATE TABLE IF NOT EXISTS touch (
  ID INTEGER PRIMARY KEY ASC AUTOINCREMENT,
  touchPhase TEXT NOT NULL,
  x INTEGER NOT NULL,
  y INTEGER NOT NULL,
  date TEXT NOT NULL,
  time INTEGER NOT NULL,
  delay INTEGER,
  wasCorrect INTEGER NOT NULL,
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
  userid TEXT NOT NULL
);
]]

database.runSQLQuery(createTableCmd)

local createTableCmd=[[
CREATE TABLE IF NOT EXISTS questionnaires (
  ID INTEGER PRIMARY KEY ASC AUTOINCREMENT,
  confidence_melody_1 INTEGER,
  confidence_melody_2 INTEGER,
  pleasure_melody_1 INTEGER,
  pleasure_melody_2 INTEGER,
  date TEXT NOT NULL,
  userid TEXT NOT NULL
);
]]
database.runSQLQuery(createTableCmd)

local insertTouchCmd=[[INSERT INTO touch (touchPhase,x,y,date,time,delay,wasCorrect,complete,track,instructionIndex,modesDropped,iterations,modeIndex,key,bank,score,practices,userid) VALUES ("%s",%d,%d,"%s",%d,%s,"%s","%s",%s,%s,%s,%s,%s,%s,%s,%s,%d,"%s");]]
local insertQuestionnaireCmd=[[INSERT INTO questionnaires (confidence_melody_1,confidence_melody_2,pleasure_melody_1,pleasure_melody_2,date,userid) VALUES (%s,%s,%s,%s,"%s","%s");]]


function log(t)
  if t.touchPhase then
    database.runSQLQuery(insertTouchCmd:format(t.touchPhase,t.x,t.y,t.date,t.time,tostring(t.delay or "NULL"),tostring(t.wasCorrect or "NULL"),tostring(t.complete),tostring(t.track or "NULL"),tostring(t.instructionIndex or "NULL"),tostring(t.modesDropped or "NULL"), tostring(t.iterations or "NULL"),tostring(t.modeIndex or "NULL"), tostring(t.keyIndex or "NULL"),tostring(t.bank or "NULL"),tostring(t.score or "NULL"),t.practices,t.userid))
  else
    database.runSQLQuery(insertQuestionnaireCmd:format(tostring(t.confidence_melody_1 or "NULL"),tostring(t.confidence_melody_2 or "NULL"),tostring(t.pleasure_melody_1 or "NULL"),tostring(t.pleasure_melody_2 or "NULL"),t.date,t.userid))
  end
  return database.lastRowID()
end

local countCmd="select count(ID) from touch limit 50;"
local getTouchesCmd=[[SELECT * FROM touch ORDER BY ID ASC limit 50;]]
local countQCmd="select count(ID) from questionnaires limit 50;"
local getQuestionnairesCmd=[[SELECT * FROM questionnaires ORDER BY ID ASC limit 50;]]

function get(callback)
  database.runSQLQuery(countCmd,function(udata,cols,values,names)
    local count=math.min(50,values[1])
    database.runSQLQuery(getTouchesCmd,function(udata,cols,values,names)
      count=count-1
      local col={}
      for i=1,#names do
        col[names[i]]=values[i]
      end
      callback(col,count==0)
      return 0
    end)
    return 0
  end)
end

local removeSentCmd=[[DELETE FROM touch WHERE ID <= %d;]]
function clearUpTo(id)
  database.runSQLQuery(removeSentCmd:format(id))
end

function getQs(callback)
  database.runSQLQuery(countQCmd,function(udata,cols,values,names)
    local count=math.min(50,values[1])
    database.runSQLQuery(getQuestionnairesCmd,function(udata,cols,values,names)
      count=count-1
      local col={}

      for i=1,#names do
        col[names[i]]=(names[i]~="userid" and tonumber(values[i])) or values[i]
      end
      callback(col,count==0)
      return 0
    end)
    return 0
  end)
end

local removeSentQsCmd=[[DELETE FROM questionnaires WHERE ID <= %d;]]
function clearQsUpTo(id)
  database.runSQLQuery(removeSentQsCmd:format(id))
end


return M