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
local type=type
local print=print

setfenv(1,scene)

local pageSetup={
  {text="Welcome back!\n\nLets see how good you are at performing the sequences you have been practicing.\n\nPlay each one as fast as you can for 1 minute.\n\nLets start with the first sequence.",onKeyPress=function() composer.gotoScene("scenes.practicetune",{params={logInputFilename="practice_tune_"..composer.getVariable("firstpractice"),tune=composer.getVariable("firstpractice"),page=2,nextScene="scenes.practiceintro"}})
    end},
  {text="Well done!\n\nNow lets play the other sequence.",onKeyPress=function() composer.gotoScene("scenes.practicetune",{params={logInputFilename="practice_tune_"..composer.getVariable("secondpractice"),tune=composer.getVariable("secondpractice"),page=3,nextScene="scenes.practiceintro"}})
    end},
  {
    text="Now you will be given 2 sequences to choose from. You can play either of them and switch as you go.\n\nSelect the sequences using the left and right pads.",
    onKeyPress=function()
      local options={leftTune=tunemanager.getID("discarded"),rightTune="preferred"}
      local switch=composer.getVariable("preferencetest")[3].switch
      if switch then options.leftTune,options.rightTune=options.rightTune,options.leftTune end
      composer.gotoScene("scenes.tuneselection",{params={iterations=30,logChoicesFilename="preferencetest-choices-1",logInputFilename="preferencetest-inputs-1",leftTune=options.leftTune,rightTune=options.rightTune,page=4}}) end
  },
  {
    text="Which one is your preferred sequence? On the next screen, select it using the left and right pads and play it once.",
    onKeyPress=function()
      local options={leftTune=composer.getVariable("firstpractice"),rightTune=composer.getVariable("secondpractice")}
      composer.gotoScene("scenes.tuneselection",{params={logChoicesFilename="select_preferred",logInputFilename="select_preferred_inputs",leftTune=options.leftTune,rightTune=options.rightTune,onTuneComplete=function(matched,notMatched,side)
        tunemanager.setPreferred(matched.tune)
        tunemanager.setDiscarded(notMatched.tune)
        composer.gotoScene("scenes.practiceintro",{params={page=5}})
      end}})
    end
  },
  {text="In the following task, you will need to choose between 2 chests. Pick a chest using the left and right pads and play the matching sequence to open it.\n\nOpen any chest you want.\n\nYou may be rewarded more often for some sequences. You will receive your winnings at the end of the study.\n\nTry to win as much as you can!\n\nTry to make your choices as quickly as possible.",
    onKeyPress=function()
      doorschedule.start()

      local createReward={
        [tunemanager.getID("discarded")]=function() return 8+math.random(7) end,
        [tunemanager.getID("preferred")]=function() return math.random(7) end,
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

          composer.gotoScene("scenes.doorresult",{params={matched=matched,notMatched=notMatched,payout=payout,chest=matched.door,onClose=run,gems=true}})
        end
        composer.gotoScene("scenes.tuneselection",{params=opts})
      end
      run()
    end},

  {text="In the following task, you will see several shapes appearing and disappearing on the screen.\n\nYou just need to count how many stars appear.\n\nThey come and go quickly so pay attention to avoid missing them!",onKeyPress=function()
      composer.gotoScene("scenes.practicetune",{params={moreStars=true,tune=nil,page=7,countShapes=true,nextScene="scenes.practiceintro"}})
    end},
   {text="Next you will need to play one of the sequences as fast as you can AND, at the same time, count the number of stars that appear!\n\nYou need to be very good at both tasks to proceed to the next stage. Good luck!",onKeyPress=function()
      composer.gotoScene("scenes.practicetune",{params={logInputFilename="countshapes_tune_"..tunemanager.getID("preferred"),tune=tunemanager.getID("preferred"),page=8,countShapes=true,nextScene="scenes.practiceintro"}})
      end},
  {text="Now you can play any sequence of your choice made up of 6 different moves, apart from the 2 sequences which you practiced at home.\n\nYou can repeat the sequence or play different ones as you like. You may press one or more keys at once if you want.\n\nUse the left or right buttons a sequence\n\nDon’t think too much! GO FAST!",img="img/stimuli/wildcard6.png",onKeyPress=function() composer.gotoScene("scenes.practicetune", {params={logInputFilename="practice_tune_any6",tune=tunemanager.getID("wildcard6"),page=9,iterations=20,forceSelection=true,nextScene="scenes.practiceintro"}})
  end},
  {
    text="Now you will be given 2 sequences to choose from. You can play either of them and switch as you go.\n\nSelect the sequences using the left and right pads.",
    onKeyPress=function()
      local options={leftTune=tunemanager.getID("preferred"),rightTune="wildcard6"}
      local switch=composer.getVariable("preferencetest")[1].switch
      if switch then options.leftTune,options.rightTune=options.rightTune,options.leftTune end
      composer.gotoScene("scenes.tuneselection",{params={hideCounter=true,iterations=30,logChoicesFilename="preferencetest-choices-1",logInputFilename="preferencetest-inputs-1",leftTune=options.leftTune,rightTune=options.rightTune,page=10}}) end
  },
  {
    text="Now, lets do the same again but with different sequences to choose from.",
    onKeyPress=function()
      local options={leftTune=tunemanager.getID("preferred"),rightTune="wildcard3"}
      local switch=composer.getVariable("preferencetest")[2].switch
      if switch then options.leftTune,options.rightTune=options.rightTune,options.leftTune end
      composer.gotoScene("scenes.tuneselection",{params={hideCounter=true,iterations=30,logChoicesFilename="preferencetest-choices-2",logInputFilename="preferencetest-inputs-2",leftTune=options.leftTune,rightTune=options.rightTune,page=11}}) end
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
      composer.gotoScene("scenes.tuneselection",{params={hideCounter=true,iterations=20,logChoicesFilename="preferencetest-choices-3",logInputFilename="preferencetest-inputs-3",leftTune=options.leftTune,rightTune=options.rightTune,leftReward=rewards.left,rightReward=rewards.right,titrate="preferred",page=12}}) end
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
      composer.gotoScene("scenes.tuneselection",{params={hideCounter=true,iterations=20,logChoicesFilename="preferencetest-choices-4",logInputFilename="preferencetest-inputs-4",leftTune=options.leftTune,rightTune=options.rightTune,leftReward=rewards.left,rightReward=rewards.right,titrate="wildcard6",page=13}}) end
  },
  {text="Now you will learn a new sequence.\n\nFollow the lights, memorize it, and play yourself!",img=function()
    return stimuli.getStimulus(3)
  end,onKeyPress=function() composer.gotoScene("scenes.learntune", {params={tune=tunemanager.getID(3),page=14}})
  end},
  {text="In the following task, you will need to choose between 2 chests. Pick a chest using the left and right pads and play the matching sequence to open it.\n\nOpen any chest you want.\n\nYou may be rewarded more often for some sequences. You will receive your winnings at the end of the study.\n\nTry to win as much as you can!\n\nTry to make your choices as quickly as possible.",
    onKeyPress=function()
      doorschedule.start()
      vischedule.setup(1,30000,1000)
      vischedule.setup(2,30000,1000)
      vischedule.start()
      winnings.startTracking()
      local round=0
      function run()
        local opts=doorschedule.nextRound()
        if not opts then
          local result=winnings.getSinceLastTrack("money")
          composer.gotoScene("scenes.doorstotal",{params={winnings=result,nextScene="scenes.practiceintro",nextParams={page=15}}})
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
          local payout=vischedule.reward(side)

          composer.gotoScene("scenes.doorresult",{params={matched=matched,notMatched=notMatched,payout=payout,chest=matched.door,onClose=run}})
        end
        composer.gotoScene("scenes.tuneselection",{params=opts})
      end
      run()
    end},
    {text="This is the last part of the experiment! This time the choices come in blocks, so it may be easier to find the more rewarding sequences.",
    onKeyPress=function()
      doorschedule.start()

      local highReward=function() return 8+math.random(7) end
      local lowReward=function() return math.random(7) end
      local createReward={
        [tunemanager.getID("discarded")]=highReward,
        [tunemanager.getID("preferred")]=lowReward,
        [tunemanager.getID("wildcard6")]=highReward,
        [tunemanager.getID("wildcard3")]=lowReward,
        [tunemanager.getID("3")]=highReward
      }
      winnings.startTracking()
      local round=0
      function run()
        local opts=doorschedule.nextRound()
        if not opts then
          composer.gotoScene("scenes.gemconversion",{params={nextScene="scenes.thankyou"}})
          return
        end
        round=round+1
        opts.round=round
        opts.logChoicesFilename="doors-choices-2"
        opts.logInputFilename="doors-inputs-2"
        opts.doors=true
        opts.onTuneComplete=function(matched,notMatched,side)
          local stage=display.getCurrentStage()
          stage:insert(matched)
          stage:insert(notMatched)
          stage:insert(matched.door)

          matched.reward=createReward[matched.tune]()
          notMatched.reward=createReward[notMatched.tune]()
          local payout=true

          composer.gotoScene("scenes.doorresult",{params={gems=true,matched=matched,notMatched=notMatched,chest=matched.door,payout=payout,onClose=run}})
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
        if event.phase=="up" and event.keyName~="=" then
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
    text="Press any key",
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