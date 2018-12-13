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
    local seed=require "seed"
    seed.setup(function()
      local logger=require "logger"
      logger.startCatchUp()
      start()
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
    sessionlogger.reset()
    logSessionStart(event.type)
  end
  if event.type=="applicationSuspend" or event.type=="applicationExit" then
    sessionlogger.logSessionEnd(event.type)
  end
end)