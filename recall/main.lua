FLAGS={
  NO_SOUND=false,
  QUICK_ROUNDS=true
}

if system.getInfo('environment')=='device' then
  for k,_ in pairs(FLAGS) do
    FLAGS[k]=false
  end
end
require ("languages")

require "constants"
require "effects.effects"
display.setStatusBar(display.HiddenStatusBar)
native.setProperty("prefersHomeIndicatorAutoHidden", true)

system.activate("multitouch")
local user=require "user"

local events = require ("events")
events.addEventListener("lang set", function()
  local detectdata = require ("detectdata")
  if detectdata.hasDataFiles() then
    local function onComplete( event )
      if event.action ~= "clicked" then
          return
      end
      if event.index == 2 then
        local emailcsv = require ("emailcsv")
        emailcsv.send(user.getID())
      end
    end

    local i18n = require ("i18n.init")
    native.showAlert(i18n("email.title"), i18n("email.message"),{
      i18n("buttons.cancel"),
      i18n("buttons.ok")},
      onComplete)
  end
end)


function start()
  local key=require "key"
  native.setActivityIndicator(true)
  key.createImages(function()
    native.setActivityIndicator(false)
    local composer=require "composer"
    composer.gotoScene("scenes.selectlang")
  end)
end

function login(force)
  user.setup(function(newUser)
    local seed=require "seed"
    seed.setup(function()
      local tunes=require "tunes"
      tunes.printKeys()

      start()
    end,true)
  end,force)
end
login(true)
