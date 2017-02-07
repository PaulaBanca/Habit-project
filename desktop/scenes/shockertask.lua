local composer=require "composer"
local scene=composer.newScene()
local transition=transition
local display=display
local Runtime=Runtime
local tunemanager=require "tunemanager"
local trialorder=require "util.trialorder"
local findfile=require "util.findfile"
local shocker=require "shocker.shockermessager"
local stimuli=require "stimuli"
local logger=require "util.logger"
local _=require "util.moses"
local timer=timer
local assert=assert
local type=type
local table=table
local os=os

setfenv(1,scene)

local debugShocker=function(side)
  local c
  if side=="right" then
    c=display.newCircle(display.contentCenterX+200,display.contentCenterY,80)
    c:setFillColor(1, 0, 0)
  else
    c=display.newCircle(display.contentCenterX-200,display.contentCenterY,80)
    c:setFillColor(0, 0, 1)
  end
  transition.to(c, {alpha=0,onComplete=function(obj) obj:removeSelf() end})
end

local shockerCalls={}
shockerCalls["preferred"]=function() debugShocker("left") end
shockerCalls["discarded"]=function() debugShocker("left") end
shockerCalls[tunemanager.getID("preferred",5)]=function() debugShocker("left") end
shockerCalls[tunemanager.getID("discarded",3)]=function() debugShocker("left") end
shockerCalls[3]=function() debugShocker("right") end

local trials=trialorder.generate({{value="discarded",n=40},{value="preferred",n=40},{value=3,n=40}},12)
function start(config)
  local count=0
  local logField=logger.create(config.taskLogFile,{"date","sequence","sequences completed","mistakes","shock"})

  local nextScene,nextParams=config.nextScene,config.nextParams
  if nextScene=="scenes.shockertask" then
    nextParams={scene=nextScene,params=nextParams}
    nextScene="scenes.reload"
  end
  local run
  run=function()
    local tune=table.remove(trials)
    if not tune then
      return composer.gotoScene(nextScene,{params=nextParams})
    end
    count=count+1
    local opts={}
    opts.logInputFilename=config.inputLogFile
    opts.onComplete=function(shock,sequencesCompleted,mistakes)
      if shock and config.enableShocks or config.forceShock then
        shockerCalls[tune]()
      end
      logField("sequence",tune)
      logField("sequences completed",sequencesCompleted)
      logField("mistakes",mistakes)
      logField("date",os.date())
      logField("shock",shock and config.enableShocks)

      local itTime=config.itTime
      if not itTime then
        return run()
      end
      composer.gotoScene("scenes.iti",{params={time=itTime}})
      if not config.trialLimit or count<config.trialLimit then
        timer.performWithDelay(itTime,run)
      else
        timer.performWithDelay(10,function() composer.gotoScene(nextScene,{params=nextParams}) end)
      end
    end
    opts.tune=tunemanager.getID(tune)
    opts.time=config.taskTime
    composer.gotoScene("scenes.playtune",{params=opts})
  end
  run()
end

local pageSetup={
  {text="In the next task, your goal is to avoid getting shocks on your wrists\n\nThe symbol will tell you which sequence to play.\n\nTo avoid being shocked, you have to play the sequence once, without making mistakes and before the time runs out",
  },
  {text="These are the symbols you will see\n\nFor each symbol, practice the corresponding sequence a few times.",img=function()
    local group=display.newGroup()
    local images={tunemanager.getID("preferred"),tunemanager.getID("discarded"),3}
    local width=0
    for i=1,#images do
      local img=stimuli.getStimulus(images[i])
      group:insert(img)
      img.anchorX=i/2-0.5
      width=width+img.contentWidth
    end
    group[1].x=-width/2
    group[3].x=width/2
    return group
  end},
  {text="For these symbols you will get a shock on your LEFT wrist if you make mistakes or if you are not fast enough.",img=function()
    local group=display.newGroup()
    local images={tunemanager.getID("preferred"),tunemanager.getID("discarded")}

    local width=0
    for i=1,#images do
      local img=stimuli.getStimulus(images[i])
      group:insert(img)
      img.anchorX=i-1
      width=width+img.contentWidth
    end
    group[1].x=-width/2
    group[2].x=width/2
    return group
  end},
  {text="For this symbol you will get a shock on your RIGHT wrist if you make mistakes or if you are not fast enough.",img=function()
    return stimuli.getStimulus(3)
  end},
  {text="Please wait... initialising equipment",
    noKeys=true,
    onShow=function()
      local path=findfile.find("arduino-serial-server")
      assert(path,"arduino-serial-server not found. Please make sure it is in your Home directory.")
      shocker.startServer(path,function(left,right)
        shockerCalls["preferred"]=left
        shockerCalls["discarded"]=left
        shockerCalls[tunemanager.getID("preferred",5)]=left
        shockerCalls[tunemanager.getID("discarded",3)]=left
        shockerCalls[3]=right
        composer.gotoScene("scenes.shockertask",{params={page=6}})
      end)
    end},
  {
    text="Let’s do the task now!\n\nPress a button to continue.",
    onKeyPress=function() start({taskTime=5000,itTime=8000,nextScene="scenes.shockertask",nextParams={page=7},trialLimit=60,enableShocks=true,inputLogFile="shocker-inputs-1",taskLogFile="shocker-summary-task1-prebreak"}) end
  },
  {text="Interval\n\nTake a break!\n\nPress a button to continue",
    onKeyPress=function() start({taskTime=5000,itTime=8000,nextScene="scenes.shockertask",nextParams={page=8},trialLimit=nil,enableShocks=true,inputLogFile="shocker-inputs-1",taskLogFile="shocker-summary-task1-postbreak"}) end
  },
  {text="There are new rules now.\n\nFor this symbol below, which you know already, you now have to play ONLY the first 5 moves. Do NOT press the last move!",img=function()
    return stimuli.getStimulus(tunemanager.getID("preferred",5))
    end},
  {text="Keep playing the sequence without stopping while the symbol is on the screen.\n\nComplete as many sequences as you can.\n\nTo avoid shocks on your LEFT wrist, you need to make as few mistakes as you can.\n\nYour performance will be assessed. You will be shocked on your left wrist if you do not perform well enough."},
  {text="Let’s try it now\n\nDo as many as you can before the times runs out to avoid being shocked",img=function()
    return stimuli.getStimulus(tunemanager.getID("preferred",5))
    end,onKeyPress=function()
      trials={tunemanager.getID("preferred",5)}
      start({taskTime=10000,nextScene="scenes.shockertask",nextParams={page=11},enableShocks=true,forceShock=true,inputLogFile="shocker-inputs-practice-preferred5",taskLogFile="shocker-summary-practice-preferred5"})
  end},
  {text="For this symbol below, which you know already, you need to play the first 3 moves of the sequence. Then replace the second half with different moves (anything you want as you did for the any 3 sequence)",img=function()
      local images={tunemanager.getID("discarded",3),tunemanager.getID("discarded"),tunemanager.getID("wildcard3")}
      local group=display.newGroup()
      local width=0
      for i=1,#images do
        local img=stimuli.getStimulus(images[i])
        group:insert(img)
        img.anchorX=i/2-0.5
        width=width+img.contentWidth
      end

      local eq=display.newText({
        fontSize=120,
        text="=",
        parent=group,
      })
      eq:setFillColor(0)
      eq.anchorX=0
      local ps=display.newText({
        fontSize=120,
        text="+",
        parent=group,
      })
      ps:setFillColor(0)
      ps.anchorX=1

      eq.x=-width/4-20
      group[1].x=-width/2-eq.width-20
      group[3].x=width/2+ps.width+20
      ps.x=width/4+20

      return group
    end},
  {text="Keep playing the sequence without stopping while the symbol is on the screen.\n\nThe new moves don’t have to be the same all the time\n\nComplete as many sequences as you can.\n\nTo avoid shocks on your LEFT wrist, you need to make as few mistakes as you can.\n\nYour performance will be assessed. You will be shocked in your left wrist if you do not perform well enough.",onKeyPress=function()
      trials={tunemanager.getID("discarded",3)}
      start({taskTime=10000,nextScene="scenes.shockertask",nextParams={page=13},enableShocks=true,forceShock=true,inputLogFile="shocker-inputs-practice-discarded3",taskLogFile="shocker-summary-practice-discarded3"})
  end},
  {text="The experimenter will now disconnect your right wrist from the shocker.\n\nYou can no longer be shocked to your RIGHT wrist\n\nPreviously, a slow or incorrect sequence for this symbol led to a shock in your right wrist. Now, because the shocker is NOT connected anymore, you no longer need to play the sequence for this symbol.",img=function()
    return stimuli.getStimulus(tunemanager.getID(3))
    end},
  {
    text="Don’t forget you still need to avoid being shocked to your LEFT wrist. You need to play the sequences, according the new rules, very fast and without mistakes!\n\nGood luck!",
    onShow=function() trials=trialorder.generate({{value=tunemanager.getID("discarded",3),n=20},{value=tunemanager.getID("preferred",5),n=20},{value=3,n=20}},12) end,
    onKeyPress=function() start({taskTime=20000,itTime=8000,nextScene="scenes.thankyou",nextParams=nil,trialLimit=nil,enableShocks=false,inputLogFile="shocker-inputs-2",taskLogFile="shocker-summary-task2"}) end
  }
}

local nextScene
function scene:show(event)
  local page=event.params and event.params.page or 1
  local setup=pageSetup[page]
  if event.phase=="did" then
    if nextScene then
      Runtime:removeEventListener("key", nextScene)
      nextScene=nil
    end
    scene.keyTimer=not setup.noKeys and timer.performWithDelay(500, function()
      nextScene=function(event)
        if event.phase=="up" and event.keyName~="=" then
          if nextScene then
            Runtime:removeEventListener("key", nextScene)
            nextScene=nil
            if not setup.onKeyPress then
              composer.gotoScene("scenes.reload",{params={scene="scenes.shockertask",params={page=page+1}}})
            else
              setup.onKeyPress()
            end
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

  if setup.onShow then
    setup.onShow()
  end
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