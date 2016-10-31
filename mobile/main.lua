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
    -- composer.gotoScene("scenes.pleasure",{params={melody=1}})
    composer.gotoScene("scenes.setup")
  end)
end

function login(force)
  user.setup(function(newUser)
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
