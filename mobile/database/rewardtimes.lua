local M={}
rewardtimes=M

local database=require "database.database"
local sqlite3=require "sqlite3"
local sqlite3constants=require "database.sqlite3constants"
local serpent=require "serpent"
local tostring=tostring
local print=print

setfenv(1,M)

local createTableCmd=[[
CREATE TABLE IF NOT EXISTS rewards (
  ID INTEGER PRIMARY KEY ASC AUTOINCREMENT,
  rewardTime INTEGER NOT NULL,
  track INTEGER NOT NULL,
  userid TEXT NOT NULL,
  practice INTEGER NOT NULL,
  day INTEGER NOT NULL
);
]]

database.runSQLQuery(createTableCmd)

local preparedInsert=database.prepare([[INSERT INTO rewards (rewardTime,track,userid,practice,day) VALUES (:rewardTime,:track,:userid,:practice,:day);]])

local preparedCount = {}
local preparedAvg = {}
for i = 1, 2 do
  preparedAvg[i] = database.prepare(([[SELECT rewardTime FROM rewards WHERE track = %d AND practice = :practice AND day = :day ORDER BY ID ASC;]]):format(i))
    preparedCount[i] = database.prepare(([[SELECT COUNT(*) FROM rewards]]):format(i))

end

local function preparedHandler(stmt,t)
  local code = stmt:bind_names(t)
  print(sqlite3constants.getLookupCode(code))
  database.step(stmt)
end

function log(t)
  print (serpent.block(t))
  preparedHandler(preparedInsert, t)
  return database.lastRowID()
end

function getRewardTimesForTrack(track, day, practice, callback)
  local stmt = preparedAvg[track]
  stmt:reset()
  local code = stmt:bind_names({
    practice = practice,
    day = day
  })
  print(sqlite3constants.getLookupCode(code))
  local times = {}
  database.stepSelect(stmt, function(t) times[#times + 1] = t.rewardTime end)
  callback(times)
end

function getCount(track, callback)
  local stmt = preparedCount[track]
  stmt:reset()
  database.stepSelect(stmt, function(t)
    callback(t["COUNT(*)"])
  end)
end
return M