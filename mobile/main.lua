require "constants"
require "effects.effects"
display.setStatusBar(display.HiddenStatusBar)
system.activate("multitouch")

local logger=require "logger"
local user=require "user"

function logSessionStart(type)
  logger.log("session",{
    time=os.date("%T"),
    date=os.date("%F"),
    appMillis=system.getTimer(),
    userid=user.getID(),
    type=type
  })
end

function start()
  local key=require "key"
  native.setActivityIndicator(true)
  key.createImages(function() 
    native.setActivityIndicator(false)
    local composer=require "composer"
    composer.gotoScene("scenes.setup")
  end)
end

function login(force)
  user.setup(function(newUser)
    if newUser then
      logSessionStart("new user")
    end
    local seet=require "seed"
    seed.setup(function()
      local logger=require "logger"
      local func=newUser and logger.create or logger.login
      func(user.getID(),user.getPassword(),function (ok,err)
      logger.startCatchUp()
        if not ok then
          if type(err) == "table" then
            err=err.error
            if err == "network error" then
              start()
              return 
            end
          end
          native.showAlert("Problem creating user", "Error: " .. err .. ". Enter new user id?", {"OK","No"}, function(event)
            if event.action == "clicked" then
              login(event.index==1)
            end
          end)
        else
          start()
        end
      end)
    end)
  end,force)
end
login()

local sessionlogger=require "sessionlogger"
Runtime:addEventListener("system", function(event)
  if not user.getID() then 
    return
  end

  if event.type=="applicationResume" or event.type=="applicationStart" then
    local prev=sessionlogger.getPreviousSession()
    if prev and next(prev) then
      logger.log("session",prev)
      sessionlogger.clearHistory()
    end
    logSessionStart(event.type)
  end
  if event.type=="applicationSuspend" or event.type=="applicationExit" then
    sessionlogger.logSessionEnd(event.type)
  end
end)

-- local randompoints=require "ui.randompoints"
-- local countdownpoints=require "ui.countdownpoints"

-- function computeRound()
--   local delays={math.random(500),math.random(500),math.random(500),math.random(500),math.random(500),math.random(500)}
--   local left=#delays
--   local randomScore=0
--   local timedScore=0
--   local r=randompoints.create(500,1000)
--   local c=countdownpoints.create(100,1000)
--   for i=1,#delays do
--     timer.performWithDelay(delays[i], function() 
--       left=left-1
--       randomScore=randomScore+r:getPoints()
--       timedScore=timedScore+c:getPoints()
--       r:remove()
--       if left==0 then
--         print (randomScore,timedScore)
--         return computeRound()
--       end
--     end)
--   end
-- end
-- computeRound()
