local composer=require "composer"
local scene=composer.newScene()

local display=display
local Runtime=Runtime
local tunemanager=require "tunemanager"
local doorschedule=require "doorschedule"
local vischedule=require "util.vischedule"
local vrschedule=require "util.vrschedule"
local stimuli=require "stimuli"
local winnings=require "winnings"
local _=require "util.moses"
local math=math
local timer=timer
local pairs=pairs
local type=type
local print=print

setfenv(1,scene)

local pageSetup={
  {text="Welcome back!\n\nLet's see how good you are at performing the sequences you have been practising.\n\nPlay each one, as fast as you can, for 1 minute.\n\nLet's start with the first sequence.",onKeyPress=function() composer.gotoScene("scenes.practicetune",{params={logInputFilename="practice_tune_"..composer.getVariable("firstpractice"),tune=composer.getVariable("firstpractice"),page=2,nextScene="scenes.practiceintro"}})
    end},
  {text="Well done!\n\nNow let's play the other sequence.",onKeyPress=function() composer.gotoScene("scenes.practicetune",{params={logInputFilename="practice_tune_"..composer.getVariable("secondpractice"),tune=composer.getVariable("secondpractice"),page=3,nextScene="scenes.practiceintro"}})
    end},
  {
    text="Now you will be given 2 sequences to choose from. You can play either of them and switch as you go.\n\nSelect the sequences using the left and right pads.",
    onKeyPress=function()
      local options={leftTune=tunemanager.getID("discarded"),rightTune="preferred"}
      local switch=composer.getVariable("preferencetest")[3].switch
      if switch then options.leftTune,options.rightTune=options.rightTune,options.leftTune end
      composer.gotoScene("scenes.tuneselection",{params={iterations=15,logChoicesFilename="preferencetest-choices-1",logInputFilename="preferencetest-inputs-1",leftTune=options.leftTune,rightTune=options.rightTune,page=4}}) end
  },
  {
    text="Which one is your preferred sequence?\n\nOn the next screen, select it using the left and right pads and play it once.",
    onKeyPress=function()
      local options={leftTune=composer.getVariable("firstpractice"),rightTune=composer.getVariable("secondpractice")}
      composer.gotoScene("scenes.tuneselection",{params={logChoicesFilename="select_preferred",logInputFilename="select_preferred_inputs",leftTune=options.leftTune,rightTune=options.rightTune,onTuneComplete=function(matched,notMatched,side)
        tunemanager.setPreferred(matched.tune)
        tunemanager.setDiscarded(notMatched.tune)
        composer.gotoScene("scenes.practiceintro",{params={page=5}})
      end}})
    end
  },
  {text="In the following task, you will need to choose between 2 chests. Pick a chest using the left and right pads and play the matching sequence to open it.\n\nOpen any chest you want.\n\nOne of the chests may reward you more than the other. You will receive your winnings at the end of the study.\n\nTry to win as much as you can!\n\nMake your choices as quickly as possible.",
    onKeyPress=function()
      doorschedule.start()

      local createReward={
        [tunemanager.getID("discarded")]=function() return 8+math.random(4) end,
        [tunemanager.getID("preferred")]=function() return 3+math.random(4) end,
      }
      winnings.startTracking()
      local round=0
      function run()
        local opts=doorschedule.nextRound()
        if not opts then
          composer.gotoScene("scenes.gemconversion",{params={nextScene="scenes.practiceintro",nextParams={page=6}}})
          return
        end
        round=round+1
        opts.round=round
        opts.logChoicesFilename="doors-choices-1"
        opts.logInputFilename="doors-inputs-1"
        opts.doors=true
        opts.onTuneComplete=function(matched,notMatched,side)
          local stage=display.getCurrentStage()
          stage:insert(matched)
          stage:insert(notMatched)
          stage:insert(matched.door)
          matched.reward=createReward[matched.tune]()
          notMatched.reward=createReward[notMatched.tune]()
          local payout=true

          composer.gotoScene("scenes.doorresult",{params={time=1000,matched=matched,notMatched=notMatched,payout=payout,chest=matched.door,onClose=run,gems=true,loggerFieldTask="door-1"}})
        end
        composer.gotoScene("scenes.tuneselection",{params=opts})
      end
      run()
    end},
  {text="In the following task, you will see several shapes appearing and disappearing on the screen.\n\nYou just need to count how many stars appear.\n\nThey come and go quickly so pay attention to avoid missing them!",onKeyPress=function()
      composer.gotoScene("scenes.practicetune",{params={moreStars=true,tune=nil,page=7,countShapes=true,nextScene="scenes.practiceintro"}})
    end},
   {text="Next you will need to play one of the sequences as fast as you can AND, at the same time, count the number of stars that appear!\n\nYou need to be very good at both tasks.\n\nGood luck!",onKeyPress=function()
      composer.gotoScene("scenes.practicetune",{params={logInputFilename="countshapes_tune_"..tunemanager.getID("preferred"),tune=tunemanager.getID("preferred"),page=8,countShapes=true,nextScene="scenes.practiceintro"}})
      end},
  {text="Now you can play any sequence of your choice made up of 6 moves, apart from the 2 sequences which you practised at home.\n\nYou can repeat the sequence you create or make up different ones as you go. You may press one or more keys at once if you want.\n\nPress the left or right pads to start playing the sequence\n\nDon’t think too much! GO FAST!",img="img/stimuli/wildcard6.png",onKeyPress=function() composer.gotoScene("scenes.practicetune", {params={logInputFilename="practice_tune_any6",tune=tunemanager.getID("wildcard6"),page=9,iterations=15,forceSelection=true,nextScene="scenes.practiceintro"}})
  end},
  {
    text="Now you will be given 2 sequences to choose from. You can play either of them and switch as you go.\n\nSelect the sequences using the left and right pads.",
    onKeyPress=function()
      local options={leftTune=tunemanager.getID("preferred"),rightTune="wildcard6"}
      local switch=composer.getVariable("preferencetest")[1].switch
      if switch then options.leftTune,options.rightTune=options.rightTune,options.leftTune end
      composer.gotoScene("scenes.tuneselection",{params={hideCounter=true,iterations=15,logChoicesFilename="preferencetest-choices-1",logInputFilename="preferencetest-inputs-1",leftTune=options.leftTune,rightTune=options.rightTune,page=10}}) end
  },
  {
    text="Now, let's do the same again but with different sequences to choose from.",
    onKeyPress=function()
      local options={leftTune=tunemanager.getID("preferred"),rightTune="wildcard3"}
      local switch=composer.getVariable("preferencetest")[2].switch
      if switch then options.leftTune,options.rightTune=options.rightTune,options.leftTune end
      composer.gotoScene("scenes.tuneselection",{params={hideCounter=true,iterations=15,logChoicesFilename="preferencetest-choices-2",logInputFilename="preferencetest-inputs-2",leftTune=options.leftTune,rightTune=options.rightTune,page=11}}) end
  },
  {
    text="Now, your performance will be rewarded and you will receive your winnings by the end of the study.",
    onKeyPress=function()
      local options={leftTune=tunemanager.getID("preferred"),rightTune="wildcard6"}
      local switch=composer.getVariable("preferencetest")[4].switch
      local rewards={left=0.05,right=0.05}
      if switch then
        options.leftTune,options.rightTune=options.rightTune,options.leftTune
        rewards.left,rewards.right=rewards.right,rewards.left
      end
      composer.gotoScene("scenes.tuneselection",{params={hideCounter=true,iterations=15,logChoicesFilename="preferencetest-choices-3",logInputFilename="preferencetest-inputs-3",leftTune=options.leftTune,rightTune=options.rightTune,leftReward=rewards.left,rightReward=rewards.right,titrate="preferred",page=12}}) end
  },
  {
    text="Same thing again but the options have changed.",
    onKeyPress=function()
      local options={leftTune=tunemanager.getID("preferred"),rightTune="wildcard6"}
      local switch=composer.getVariable("preferencetest")[5].switch
      local rewards={left=0.05,right=0.05}
      if switch then
        options.leftTune,options.rightTune=options.rightTune,options.leftTune
        rewards.left,rewards.right=rewards.right,rewards.left
      end
      composer.gotoScene("scenes.tuneselection",{params={hideCounter=true,iterations=15,logChoicesFilename="preferencetest-choices-4",logInputFilename="preferencetest-inputs-4",leftTune=options.leftTune,rightTune=options.rightTune,leftReward=rewards.left,rightReward=rewards.right,titrate="wildcard6",page=13}}) end
  },
  {text="Now you will learn a new sequence.\n\nFollow the lights, memorize it, and play yourself!",img=function()
    return stimuli.getStimulus(3)
  end,onKeyPress=function() composer.gotoScene("scenes.learntune", {params={tune=tunemanager.getID(3),page=14}})
  end},
  {text="In the following task, you will need to choose between 2 chests. Pick a chest using the left and right pads and play the matching sequence to open it.\n\nOpen any chest you want.\n\nYou may be rewarded more often for some sequences. You will receive your winnings at the end of the study.\n\nTry to win as much as you can!\n\nTry to make your choices as quickly as possible.",
    onKeyPress=function()
      doorschedule.start()
      winnings.startTracking()
      composer.gotoScene("scenes.practiceintro",{params={page=15}})
    end},
    {text="Get Ready!",
      onKeyPress=function()
        local viMapping={
        [tunemanager.getID("preferred")]=1,
        [tunemanager.getID("wildcard6")]=2,
        [tunemanager.getID("wildcard3")]=2,
      }
      local round=0
      function run()
        local opts=doorschedule.nextRound()

        if not opts then
          local result=winnings.getSinceLastTrack("gems")
          composer.gotoScene("scenes.gemconversion",{params={winnings=result,nextScene="scenes.practiceintro",nextParams={page=16}}})
          return
        end
        round=round+1
        opts.round=round
        opts.logChoicesFilename="doors-choices-2"
        opts.logInputFilename="doors-inputs-2"
        opts.doors=true
        opts.timed=30*1000

        local overLayIsOpen
        opts.onTimerComplete=function()
          timer.performWithDelay(100,function(event)
            if overLayIsOpen then
              return
            end
            timer.cancel(event.source)
            composer.gotoScene("scenes.practiceintro",{params={page=15}})
          end,-1)
        end

        vischedule.setup(1,2000,1000)
        vischedule.setup(2,2000,1000)
        vischedule.start()

        opts.onTuneSelect=function()
          vischedule.pause()
        end

        opts.onTuneComplete=function(matched,notMatched,side,resume)
          local stage=display.getCurrentStage()
          local params={"x","y","xScale","yScale","parent","isVisible","alpha","anchorX","anchorY"}
          local images={matched.door,matched,notMatched}
          local savedParams={}
          for i=1,#images do
            local img=images[i]
            savedParams[i]={}
            for p=1,#params do
              local v=params[p]
              savedParams[i][v]=img[v]
            end
            stage:insert(img)
          end

          local payout=vischedule.reward(viMapping[tunemanager.getID(matched.tune)])
          overLayIsOpen=true
          composer.showOverlay("scenes.doorresult",{params={time=1000,matched=matched,notMatched=notMatched,payout=payout,chest=matched.door,loggerFieldTask="door-2",gems=true,onClose=function()
            if images[1].removeSelf then
              for i=1,#images do
                local img=images[i]
                local saved=savedParams[i]
                for k,v in pairs(saved) do
                  if k=="parent" then
                    v:insert(img)
                  else
                    img[k]=v
                  end
                end
                if img.close then
                  img:close()
                end
              end
              matched.door:toBack()
            end
            composer.hideOverlay()
            overLayIsOpen=false

            vischedule.resume()

            resume()
          end}})
        end
        composer.gotoScene("scenes.tuneselection",{params=opts})
      end
      run()
      end
    },
    {text="Now the chests always contain gems. However, there are bigger rewards in some chests than others.\n\nRemember: the more gems you get the more money you will earn at the end of the task.\n\nTry to win as much as you can.",
    onKeyPress=function()
      doorschedule.start()

      local highReward=function() return 8+math.random(7) end
      local lowReward=function() return math.random(7) end
      local createReward={
        [tunemanager.getID("discarded")]=highReward,
        [tunemanager.getID("preferred")]=lowReward,
        [tunemanager.getID("wildcard6")]=highReward,
        [tunemanager.getID("wildcard3")]=lowReward,
        [tunemanager.getID(3)]=highReward
      }
      winnings.startTracking()
      local round=0
      function run()
        local opts=doorschedule.nextRound()
        if not opts then
          composer.gotoScene("scenes.gemconversion",{params={nextScene="scenes.winnings"}})
          return
        end
        round=round+1
        opts.round=round
        opts.logChoicesFilename="doors-choices-3"
        opts.logInputFilename="doors-inputs-3"
        opts.doors=true
        opts.onTuneComplete=function(matched,notMatched,side)
          local stage=display.getCurrentStage()
          stage:insert(matched)
          stage:insert(notMatched)
          stage:insert(matched.door)

          matched.reward=createReward[matched.tune]()
          notMatched.reward=createReward[notMatched.tune]()
          local payout=true

          composer.gotoScene("scenes.doorresult",{params={time=1000,gems=true,matched=matched,notMatched=notMatched,chest=matched.door,payout=payout,onClose=run,loggerFieldTask="door-3"}})
        end
        composer.gotoScene("scenes.tuneselection",{params=opts})
      end
      run()
    end}
}

local nextScene
function scene:show(event)
  local setup=pageSetup[event.params and event.params.page or 1]
  if event.phase=="did" then
    if nextScene then
      Runtime:removeEventListener("key", nextScene)
      nextScene=nil
    end
    scene.keyTimer=timer.performWithDelay(500, function()
      nextScene=function(event)
        if event.phase=="up" and event.keyName=="enter" then
          if nextScene then
            Runtime:removeEventListener("key", nextScene)
            nextScene=nil
            setup.onKeyPress()
          end
        end
      end
      Runtime:addEventListener("key", nextScene)
    end)
    return
  end
  local img
  if setup.img then
    if type(setup.img)=="string" then
      img=display.newImage(self.view,setup.img)
    else
      img=setup.img()
      self.view:insert(img)
    end
    img.x=display.contentCenterX
  end
  local text=display.newText({
    parent=self.view,
    text=setup.text,
    x=display.contentCenterX,
    y=display.contentCenterY,
    width=display.actualContentWidth*3/4,
    align="center",
    fontSize=48})
  text:setFillColor(0)

  if img then
    local h=text.height+img.height+20
    img.anchorY=0
    img.y=display.contentCenterY-h/2
    text.anchorY=1
    text.y=display.contentCenterY+h/2
  end

  local any=display.newText({
    parent=self.view,
    text="Press enter to continue",
    x=display.contentCenterX,
    y=display.actualContentHeight-20,
    align="center",
    fontSize=40})
  any.anchorY=1
  any:setFillColor(0)
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    for i=self.view.numChildren,1,-1 do
      self.view[i]:removeSelf()
    end
    if self.keyTimer then
      timer.cancel(self.keyTimer)
      self.keyTimer=nil
    end
    if nextScene then
      Runtime:removeEventListener("key", nextScene)
      nextScene=nil
    end
  end
end

scene:addEventListener("hide")

return scene