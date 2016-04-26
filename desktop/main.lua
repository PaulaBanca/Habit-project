require "constants"
local composer=require "composer"
local logger=require "util.logger"
logger.setUserID("test")
display.setDefault("background", 1, 1, 1)
local function start()
  -- local doorschedule=require "doorschedule"
  -- doorschedule.start()
  -- function run()
  --   local opts=doorschedule.nextRound()
  --   local opts=doorschedule.nextRound()
  --   opts.logChoicesFilename="doors-choices"
  --   opts.logInputFilename="doors-inputs"
  --   opts.doors=true
  --   opts.onTuneComplete=function(tune,reward,side)
  --     composer.gotoScene("scenes.doorresult",{params={reward=reward,track=tune,side=side,onClose=run,[[nextScene=event.params.nextScene,nextParams=event.params.nextParams]]}})
  --   end

  --   composer.gotoScene("scenes.tuneselection",{params=opts})
  -- end
  -- local vischedule=require "util.vischedulen"
  -- vischedule.setup(2,30000,1000)
  -- vischedule.start()

  -- run()
  local seed=require "scenes.seed"
  seed.setup(function()
    composer.gotoScene("scenes.setup")
    local stimuli=require "stimuli"
    local tunemanager=require "tunemanager"
    local tunes=require "tunes"
    tunes.printKeys()
    tunemanager.setPreferred(1)
    tunemanager.setDiscarded(2)
  end)
  local page=1
  Runtime:addEventListener("key",function(event)
    if event.phase=="up" and event.keyName=="=" then
      page=page+1
      composer.gotoScene("scenes.practiceintro",{params={page=page}})
    end
   end)
end

Runtime:addEventListener("resize", function (event)
  if not start then
    return
  end
  timer.performWithDelay(500,start)
  start=nil
end)
if system.getInfo("environment")=="simulator" then
  start()
  start=nil
  local servertest=require "servertest"
end

