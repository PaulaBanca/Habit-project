local M={}
unsent=M

local database=require "database.database"
local tostring=tostring
local print=print
local pairs=pairs
local serpent=require "serpent"
local tonumber=tonumber
local math=math
local table=table
local timer=timer

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
  userid TEXT NOT NULL,
  timeIntoSequence INTEGER NOT NULL,
  intro TEXT NOT NULL,
  mistakes INTEGER NOT NULL
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

local insertTouchCmd=[[INSERT INTO touch (touchPhase,x,y,date,time,delay,wasCorrect,complete,track,instructionIndex,modesDropped,iterations,modeIndex,key,bank,score,practices,userid,timeIntoSequence,intro,mistakes) VALUES ("%s",%d,%d,"%s",%d,%s,"%s","%s",%s,%s,%s,%s,%s,%s,%s,%s,%d,"%s","%s","%s",%d);]]
local insertQuestionnaireCmd=[[INSERT INTO questionnaires (confidence_melody_1,confidence_melody_2,pleasure_melody_1,pleasure_melody_2,date,userid) VALUES (%s,%s,%s,%s,"%s","%s");]]

local queuedCommands={}
function log(t)
  if t.touchPhase then
    queuedCommands[#queuedCommands+1]=insertTouchCmd:format(
      t.touchPhase,
      t.x,
      t.y,
      t.date,
      t.time,
      tostring(t.delay or "NULL"),
      tostring(t.wasCorrect or "false"),
      tostring(t.complete),
      tostring(t.track or "NULL"),
      tostring(t.instructionIndex or "NULL"),
      tostring(t.modesDropped or "NULL"),
      tostring(t.iterations or "NULL"),
      tostring(t.modeIndex or "NULL"),
      tostring(t.keyIndex or "NULL"),
      tostring(t.bank or "NULL"),
      tostring(t.score or "NULL"),
      t.practices,
      t.userid,
      t.timeIntoSequence,
      tostring(t.intro),
      (t.mistakes or 0)
    )
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

function flushQueuedCommands(onComplete)
  local total=#queuedCommands
  if total==0 then
    return onComplete()
  end
  timer.performWithDelay(1,function(event)
    database.runSQLQuery(table.remove(queuedCommands,1))
    if event.count==total then
      onComplete()
    end
  end,total)
end

function hasDataToSend()
  local total=0
  database.runSQLQuery(countQCmd,function(udata,cols,values,names)
    local count=math.min(50,values[1])
    total=total+count
    return 0
  end)
  database.runSQLQuery(countCmd,function(udata,cols,values,names)
    local count=math.min(50,values[1])
    total=total+count
    return 0
  end)

  return total~=0
end

return M