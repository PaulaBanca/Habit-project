local M={}
averagetimes=M

local database=require "database.database"
local sqlite3=require "sqlite3"
local serpent=require "serpent"
local tostring=tostring
local print=print

setfenv(1,M)

local createTableCmd=[[
CREATE TABLE IF NOT EXISTS completion (
  ID INTEGER PRIMARY KEY ASC AUTOINCREMENT,
  startMillis INTEGER NOT NULL,
  endMillis INTEGER NOT NULL,
  track INTEGER NOT NULL,
  userid TEXT NOT NULL,
  mistake INTEGER NOT NULL
);
]]

database.runSQLQuery(createTableCmd)

local preparedCompletion=database.prepare([[INSERT INTO completion (startMillis,endMillis,track,userid,mistake) VALUES (:startMillis,:endMillis,:track,:userid,:mistake);]])

local preparedCount = {}
local preparedAvg = {}
for i = 1, 2 do
  preparedAvg[i] = database.prepare(([[SELECT avg(dt) FROM (SELECT endMillis - startMillis AS dt FROM completion WHERE track = %d ORDER BY ID DESC limit 20);]]):format(i))
  preparedCount[i] = database.prepare(([[SELECT COUNT(*) FROM completion WHERE track = %d]]):format(i))
end

local function preparedHandler(stmt,t)
  stmt:bind_names(t)
  database.step(stmt)
end

function log(t)
  t.mistake = t.mistake or 0
  preparedHandler(preparedCompletion, t)
  return database.lastRowID()
end

function getAveragesForTrack(track, callback)
  local stmt = preparedAvg[track]
  stmt:reset()
  database.stepSelect(stmt, function(t) callback(t["avg(dt)"]) end)
end

function getNumAverages(track, callback)
  local stmt = preparedCount[track]
  stmt:reset()
  database.stepSelect(stmt, function(t)
    callback(t["COUNT(*)"])
  end)
end

return M