FLAGS={
  NO_SOUND=false,
  QUICK_ROUNDS=true
}

if system.getInfo('environment')=='device' then
  for k,v in pairs(FLAGS) do
    FLAGS[k]=false
  end
end

require "constants"
require "effects.effects"
display.setStatusBar(display.HiddenStatusBar)
system.activate("multitouch")


local user=require "user"

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
    local seed=require "seed"
    seed.setup(function()
      local tunes=require "tunes"
      tunes.printKeys()

      start()
    end,true)
  end,force)
end
login()
