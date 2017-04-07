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
    local stimuli=require "stimuli"
    local tunes=require "tunes"
    stimuli.generateSeeds()
    tunes.generateTunes()
    composer.gotoScene("scenes.setup")
    local tunemanager=require "tunemanager"
    tunes.printKeys()
    tunemanager.setPreferred(1)
    tunemanager.setDiscarded(2)
  end)
  local page=0
  local skipTool={}
  skipTool[1]=function()
    page=page+1
    if page==17 then
      page=0
      return true
    end
    composer.gotoScene("scenes.practiceintro",{params={page=page}})
  end
  skipTool[2]=function()
    page=page+1

    if page==3 then
      page=0
      return true
    end
    if page==2 then
      return
    end
    composer.gotoScene("scenes.gemconversion",{params={nextScene="scenes.winnings"}})
  end
  skipTool[3]=function()
    page=page+1
    composer.gotoScene("scenes.shockertask",{params={page=page}})
  end

  Runtime:addEventListener("key",function(event)
    if event.phase=="up" then
      if event.keyName=="=" then
        if skipTool[1]() then
          table.remove(skipTool,1)
          skipTool[1]()
        end
      end
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
local serverkeylistener=require "serverkeylistener"
if system.getInfo("environment")=="simulator" then
  start()
  start=nil
end

