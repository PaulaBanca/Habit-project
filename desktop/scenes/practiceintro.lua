local composer=require "composer"
local scene=composer.newScene()

local transition=transition
local display=display
local Runtime=Runtime
local tunemanager=require "tunemanager"
local doorschedule=require "doorschedule"
local vischedule=require "util.vischedule"
local winnings=require "winnings"
local _=require "util.moses"
local math=math
local timer=timer
local print=print

setfenv(1,scene)

local pageSetup={
  {text="Welcome back!\n\nLets see how good you are at performing the sequences you have been practicing.\n\nPlay each one as fast as you can for 1 minute.\n\nLets start with the first sequence.",onKeyPress=function() composer.gotoScene("scenes.practicetune",{params={logName="practice_tune_"..composer.getVariable("firstpractice"),tune=composer.getVariable("firstpractice"),page=2}})
    end},
  {text="Well done!\n\nNow lets play the other sequence.",onKeyPress=function() composer.gotoScene("scenes.practicetune",{params={logName="practice_tune_"..composer.getVariable("secondpractice"),tune=composer.getVariable("secondpractice"),page=3}})
    end},
  {text="In the following task, you will see several shapes appearing and disappearing on the screen.\n\nYou just need to count how many stars appear.\n\nThey come and go quickly so pay attention to avoid missing them!",onKeyPress=function()
      local one=composer.getScene("scenes.practicetune").getBestFor(1) or 0
      local two=composer.getScene("scenes.practicetune").getBestFor(2) or 0
      local preferred,discarded
      while one==two do
        one=one+math.random(3)-2
      end
      if one<two then
        discarded=1
        preferred=2
      else
        discarded=2
        preferred=1
      end
      tunemanager.setPreferred(preferred)
      tunemanager.setDiscarded(discarded)
      composer.gotoScene("scenes.practicetune",{params={tune=nil,page=4,countShapes=true}})
    end},
   {text="Next you will need to play one of the sequences as fast as you can AND, at the same time, count the number of stars that appear!\n\nYou need to be very good at both tasks to proceed to the next stage. Good luck!",onKeyPress=function()
      composer.gotoScene("scenes.practicetune",{params={logName="countshapes_tune_"..tunemanager.getID("preferred"),tune=tunemanager.getID("preferred"),page=5,countShapes=true}})
      end},
  {text="Now you must invent new sequences.\n\nYou can play anything you like, apart from playing the Moon or Star sequence which you practiced at home.\n\nYou can repeat the sequence or play different ones as you like. You may press single or several keys at once if you want.\n\nDon’t think too much! GO FAST!",img="img/stimuli/wildcard6.png",onKeyPress=function() composer.gotoScene("scenes.practicetune", {params={logName="practice_tune_any6",tune=tunemanager.getID("wildcard6"),page=6,iterations=20}})
  end},
  {
    text="Now for the next minute you can play either of the two indicated sequences.\n\nSelect the sequence using the left and right buttons\n\nYou can switch as you go, if you want",
    onKeyPress=function() 
      local options={leftTune=tunemanager.getID("preferred"),rightTune="wildcard6"}
      local switch=composer.getVariable("preferencetest")[1].switch
      if switch then options.leftTune,options.rightTune=options.rightTune,options.leftTune end
      composer.gotoScene("scenes.tuneselection",{params={timed=60*1000,logChoicesFilename="preferencetest-choices-1",logInputFilename="preferencetest-inputs-1",leftTune=options.leftTune,rightTune=options.rightTune,page=7}}) end
  },
  {
    text="Now, lets do the same again but with different sequences to choose from.",
    onKeyPress=function() 
      local options={leftTune=tunemanager.getID("preferred"),rightTune="wildcard3"}
      local switch=composer.getVariable("preferencetest")[2].switch
      if switch then options.leftTune,options.rightTune=options.rightTune,options.leftTune end
      composer.gotoScene("scenes.tuneselection",{params={timed=60*1000,logChoicesFilename="preferencetest-choices-2",logInputFilename="preferencetest-inputs-2",leftTune=options.leftTune,rightTune=options.rightTune,page=8}}) end
  },
  {
    text="And again with a new set of options.",
    onKeyPress=function() 
      local options={leftTune=tunemanager.getID("discarded"),rightTune="wildcard6"}
      local switch=composer.getVariable("preferencetest")[3].switch
      if switch then options.leftTune,options.rightTune=options.rightTune,options.leftTune end
      composer.gotoScene("scenes.tuneselection",{params={timed=60*1000,logChoicesFilename="preferencetest-choices-1",logInputFilename="preferencetest-inputs-1",leftTune=options.leftTune,rightTune=options.rightTune,page=9}}) end
  },
  
  {
    text="Now, your performance will be rewarded and you will receive your winnings by the end of the study.",
    onKeyPress=function() 
      local options={leftTune=tunemanager.getID("preferred"),rightTune="wildcard6"}
      local switch=composer.getVariable("preferencetest")[4].switch
      local rewards={left=0.1,right=0.1}
      if switch then 
        options.leftTune,options.rightTune=options.rightTune,options.leftTune
        rewards.left,rewards.right=rewards.right,rewards.left
      end
      local total
      local tally={left=0,right=0}
      composer.gotoScene("scenes.tuneselection",{params={timed=30*1000,logChoicesFilename="preferencetest-choices-3",logInputFilename="preferencetest-inputs-3",leftTune=options.leftTune,rightTune=options.rightTune,leftReward=rewards.left,rightReward=rewards.right,titrate="preferred",page=10}}) end
  },
  {
    text="Same thing again but the options have changed.",
    onKeyPress=function() 
      local options={leftTune=tunemanager.getID("preferred"),rightTune="wildcard6"}
      local switch=composer.getVariable("preferencetest")[5].switch
      local rewards={left=0.1,right=0.1}
      if switch then 
        options.leftTune,options.rightTune=options.rightTune,options.leftTune
        rewards.left,rewards.right=rewards.right,rewards.left
      end
      composer.gotoScene("scenes.tuneselection",{params={timed=30*1000,logChoicesFilename="preferencetest-choices-4",logInputFilename="preferencetest-inputs-4",leftTune=options.leftTune,rightTune=options.rightTune,leftReward=rewards.left,rightReward=rewards.right,titrate="wildcard6",page=11}}) end
  },
  {text="Now you will learn a new sequence called Venus.\n\nFollow the lights, memorize it, and play yourself!",img="img/stimuli/3.png",onKeyPress=function() composer.gotoScene("scenes.learntune", {params={tune=tunemanager.getID(3),page=12}})
  end},
  {text="In the following task, you will need to choose between 2 chests. You open chests by selecting it using the arrows keys and playing the sequence that matches the symbol on it.\n\nFeel free to open the chests you prefer.\n\nThere are rewards in some of them. You will receive your winnings by the end of the study.\n\nTry to win as much as you can!\n\nTry to make your choices as quickly as possible.",
    onKeyPress=function()
      doorschedule.start()
      vischedule.setup(1,30000,1000)
      vischedule.setup(2,30000,1000)
      vischedule.start()
      function run()
        local opts=doorschedule.nextRound()
        if not opts then
          local result=composer.getScene("scenes.doorresult").total
          winnings.add(result)
          composer.gotoScene("scenes.doorstotal",{params={winnings=result,nextScene="scenes.practiceintro",nextParams={page=13}}})
          return
        end

        opts.logChoicesFilename="doors-choices-1"
        opts.logInputFilename="doors-inputs-1"
        opts.doors=true
        opts.onTuneComplete=function(matched,notMatched,side)
          local stage=display.getCurrentStage()
          stage:insert(matched)
          stage:insert(notMatched)
          stage:insert(matched.door)
          composer.gotoScene("scenes.doorresult",{params={matched=matched,notMatched=notMatched,side=side,chest=matched.door,onClose=run}})
        end
        composer.gotoScene("scenes.tuneselection",{params=opts})
      end
      run()
    end},
    {text="In this last task, you also need to choose between 2 chests. You open chests by playing the sequence that matches the symbol on it.\n\nSome symbols or chests will reward you more often than the others.\n\nRemember you are playing for real money! You will receive your winnings by the end of the study.\n\nTry to win as much as you can!",
    onKeyPress=function()
      doorschedule.start()
      vischedule.setup(1,30000,1000)
      vischedule.setup(2,30000,1000)
      vischedule.setup(3,15000,1000)
      vischedule.start()
      function run()
        local opts=doorschedule.nextRound()
        if not opts then
          composer.gotoScene("scenes.thankyou")
          return
        end

        opts.logChoicesFilename="doors-choices-2"
        opts.logInputFilename="doors-inputs-2"
        opts.doors=true
        local vischeduleMap={
          [tunemanager.getID("preferred")]=1,
          [tunemanager.getID("wildcard3")]=2,
          [tunemanager.getID("wildcard6")]=3,
          [tunemanager.getID("discarded")]=3,
          [tunemanager.getID(3)]=3
        }
        opts.onTuneComplete=function(matched,notMatched,side)
          local stage=display.getCurrentStage()
          stage:insert(matched)
          stage:insert(notMatched)
          stage:insert(matched.door)
          
          local vi=vischeduleMap[matched.tune]
          composer.gotoScene("scenes.doorresult",{params={matched=matched,notMatched=notMatched,chest=matched.door,side=vi,onClose=run}})
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
    img=display.newImage(self.view,setup.img)
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