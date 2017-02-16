local composer=require "composer"
local scene=composer.newScene()

local events=require "events"
local serverkeylistener=require "serverkeylistener"
local tunemanager=require "tunemanager"
local sound=require "sound"
local winnings=require "winnings"
local countdown=require "ui.countdown"
local progress=require "ui.progress"
local keyeventslisteners=require "util.keyeventslisteners"
local logger=require "util.logger"
local rewardtext=require "util.rewardtext"
local _=require "util.moses"
local transition=transition
local timer=timer
local display=display
local system=system
local table=table
local math=math
local tonumber=tonumber
local os=os
local Runtime=Runtime

setfenv(1,scene)

function setup(leftTune,rightTune,leftReward,rightReward,chests)
  local lx,rx=display.contentCenterX-50,display.contentCenterX+50
  local leftChest,rightChest
  if chests then
    local function open(chest,hasTreasure)
      local group=display.newGroup()
      chest.parent:insert(group)
      local top=display.newImage(group,"img/chest_open_top.png")
      top:scale(2,2)
      local bottom=display.newImage(group,"img/chest_open_bottom.png")
      bottom:scale(2,2)
      bottom.anchorY=1
      top.y=-bottom.contentHeight-top.contentHeight/2

      if hasTreasure then
        local treasure=display.newImage(group,"img/chest_open_treasure.png")
        treasure:scale(2,2)
        treasure.anchorY=1
        treasure.y=-bottom.contentHeight
      end

      group.x,group.y=chest.x,chest.y+chest.contentHeight/2
      group.anchorX=chest.anchorX
      group.anchorY=1
      group.anchorChildren=true
      chest:removeSelf()
    end

    leftChest=display.newImage(scene.view,"img/chest_closed.png")
    leftChest:scale(2,2)
    leftChest.x=display.contentCenterX-15
    leftChest.y=display.contentCenterY-40
    leftChest.anchorX=1
    leftChest.open=open
    lx=leftChest.x-leftChest.contentWidth/2
    rightChest=display.newImage(scene.view,"img/chest_closed.png")
    rightChest:scale(2,2)
    rightChest.x=display.contentCenterX+15
    rightChest.y=display.contentCenterY-40
    rightChest.anchorX=0
    rightChest.open=open
    rx=rightChest.x+rightChest.contentWidth/2
  end

  local left=tunemanager.getImg(leftTune)
  left.anchorX=chests and 0.5 or 1
  left.x=lx
  left.y=display.contentCenterY
  left.tune=tunemanager.getID(leftTune)
  left.reward=leftReward
  left.door=leftChest
  local right=tunemanager.getImg(rightTune)
  right.anchorX=chests and 0.5 or 0
  right.x=rx
  right.y=display.contentCenterY
  right.tune=tunemanager.getID(rightTune)
  right.reward=rightReward
  right.door=rightChest
  scene.view:insert(left)
  scene.view:insert(right)

  local leftMeter,rightMeter
  leftMeter=progress.create(240,60,{left.tune~=-3 and 6 or 3})
  scene.view:insert(leftMeter)
  leftMeter.x=left.x-(chests and 0 or left.contentWidth/2)

  rightMeter=progress.create(240,60,{right.tune~=-3 and 6 or 3})
  scene.view:insert(rightMeter)
  rightMeter.x=right.x+(chests and 0.5 or right.contentWidth/2)
  local metery=math.max(left.y-left.contentHeight/2,right.y-right.contentHeight/2)-60
  leftMeter.y=metery
  rightMeter.y=metery

  scene.leftMeter=leftMeter
  scene.rightMeter=rightMeter

  return left,right
end

function scene:flashMessage(message,y)
  local t=display.newText({
    text=message,
    fontSize=120,
    parent=self.view,
    x=display.contentCenterX,
    y=y
  })
  t:translate(0, 400)
  t.anchorY=0
  t:setFillColor(1,0,0)
  transition.to(t, {tag="mistake",alpha=0,onComplete=display.remove,onCancel=display.remove})
end

function scene:setupUserInput(left,right,logChoicesFilename,logInputFilename,onTuneCompleteFunc,onTuneCompleteEndFunc,getTuneSelected,getWinnings)
  local logField=logger.create(logChoicesFilename,{"date","sequence selected","round","input time","mistakes","left choice","right choice","winnings"})

  local steps=0
  local mistakes=0
  local reset
  local inMistakeStreak
  local function madeMistake(force)
    if not force and getTuneSelected() and getTuneSelected()<0 then
      return
    end
    sound.playSound("wrong")
    reset(true)
    if not inMistakeStreak then
      mistakes=mistakes+1
      inMistakeStreak=true
    end
    self:flashMessage(not getTuneSelected() and "Select side first" or "Mistake, start again!",left.y-left.height/2-10)
  end

  local function getWildCardLength()
    if left.tune==-3 or right.tune==-3 then
      return 3
    end
    return 6
  end

  local function testMatch(matchingTunes,tune,meter)
    if tune~=getTuneSelected() then
      return false
    end
    local match=matchingTunes[tune]
    if match then
      for i=1,match.step do
        meter:mark(i,true)
      end
      inMistakeStreak=false
    else
      meter:reset()
    end
    return true
  end

  local function resetMeters()
    self.leftMeter:reset()
    self.rightMeter:reset()
  end

  local start=system.getTimer()
  local meterResetTimer
  local function tuneCompleted(tune)
    steps=0
    reset(false)
    inMistakeStreak=false
    sound.playSound("correct")
    if onTuneCompleteEndFunc then
      events.removeEventListener("key played",self.onPlay)
      events.removeEventListener("key released",self.onRelease)
    end

    local matched,notMatched
    if tune==left.tune or left.tune<0 and right.tune~=tune then
      matched=left
      notMatched=right
    else
      matched=right
      notMatched=left
    end
    local side=matched==left and 1 or 2
    onTuneCompleteFunc(side)

    meterResetTimer=timer.performWithDelay(500, function()
      meterResetTimer=nil
      if not self.leftMeter.numChildren then
        return
      end
      resetMeters()
      left:unselect()
      right:unselect()
      if onTuneCompleteEndFunc then
        onTuneCompleteEndFunc(matched,notMatched,side)
      end
    end)

    logField("date",os.date())
    logField("sequence selected",tune)
    logField("round",round)
    logField("input time",system.getTimer()-start)
    logField("mistakes",mistakes)
    logField("left choice",left.tune)
    logField("right choice",right.tune)
    logField("winnings",getWinnings())
    start=system.getTimer()

    matched:setSelected()
    transition.to(matched, {strokeWidth=0})
    if matched.door then
      transition.to(notMatched.door, {alpha=0})
    end
  end

  local onPlay,onRelease
  onPlay,onRelease,reset=keyeventslisteners.create(logInputFilename,function(tune)
    if tune~=getTuneSelected() then
      madeMistake(getTuneSelected()<0 and tune<=3)
      return
    end
    steps=0
    if tune~=left.tune and tune~=right.tune then
      resetMeters()
      madeMistake()
      return
    end
    local meter=left.tune==tune and self.leftMeter or self.rightMeter
    meter:mark(tune<0 and -tune or 6,true)
    tuneCompleted(tune)
  end,madeMistake,function(event)
    if not left or not getTuneSelected() then
      if not getTuneSelected() then
        madeMistake()
      end
      return
    end
    if meterResetTimer then
      timer.cancel(meterResetTimer)
      meterResetTimer=nil
      resetMeters()
    end
    if event.phase~="released" or not event.allReleased then
      return
    end
    local matchingTunes=event.matchingTunes
    if matchingTunes and getTuneSelected()>0 then
      if not matchingTunes[getTuneSelected()] then
        return madeMistake()
      end
      if testMatch(matchingTunes, left.tune,self.leftMeter) or
         testMatch(matchingTunes,right.tune,self.rightMeter) then
        return
      end
    else
      if getTuneSelected()>0 then
        return madeMistake()
      end
      if left.tune>0 then
        self.leftMeter:reset()
      end
      if right.tune>0 then
        self.rightMeter:reset()
      end
    end

    steps=steps+1
    if getTuneSelected()>0 then
      return
    end

    local good=true
    if matchingTunes then
      for i=1, 3 do
        if matchingTunes[i] and matchingTunes[i].step==steps then
          good=false
        end
      end
    end

    local wildMeter=left.tune<0 and self.leftMeter or self.rightMeter
    if steps>0 then
      wildMeter:mark(steps,good)
      inMistakeStreak=false
    else
      wildMeter:reset()
    end

    if steps==getWildCardLength() then
      steps=0
      if good then
        tuneCompleted(left.tune<right.tune and left.tune or right.tune)
      elseif getTuneSelected()<0 then
        madeMistake(true)
        wildMeter:reset()
      end
    end
  end,getTuneSelected,true,getWildCardLength)

  reset=_.wrap(reset,function(f,clearMeters)
    if clearMeters then
      resetMeters()
    end
    f()
    steps=0
  end)

  events.addEventListener("key played",onPlay)
  events.addEventListener("key released",onRelease)
  self.onRelease=onRelease
  self.onPlay=onPlay
end

function scene:setupWinnings(left,right,leftReward,rightReward,titrateTune)
  local lx=left.x+left.contentWidth/2-(left.contentWidth*left.anchorX)-left.contentWidth/2
  local rx=right.x+right.contentWidth/2-(right.contentWidth*right.anchorX)+right.contentWidth/2
  local ly=left.y+left.contentHeight/2-(left.contentHeight*left.anchorY)+left.contentHeight/2
  local ry=right.y+right.contentHeight/2-(right.contentHeight*right.anchorY)+right.contentHeight/2
  local y=math.max(ly,ry)+50

  local lr=display.newText({
    parent=self.view,
    text=rewardtext.create(leftReward),
    fontSize=80
  })
  lr:setFillColor(0)
  lr.anchorX=1
  lr.x=lx-10
  lr.y=y

  local rr=display.newText({
    parent=self.view,
    text=rewardtext.create(rightReward),
    fontSize=80
  })
  rr:setFillColor(0)
  rr.anchorX=0
  rr.x=rx+10
  rr.y=y

  local wonLabel=display.newText({
    parent=self.view,
    text="Won:",
    fontSize=60
  })
  wonLabel:setFillColor(0)
  wonLabel.x=display.contentCenterX
  wonLabel.y=left.y-left.contentHeight/2-490

  local won=0
  local cash=display.newText({
    parent=self.view,
    text=rewardtext.create(won),
    fontSize=80
  })
  cash:setFillColor(0)
  cash.x=display.contentCenterX
  cash.y=wonLabel.y+wonLabel.height

  local leftTally,rightTally,total=0,0,0
  local count=0

  local leftCoins={}
  for i=1, math.floor(leftReward*100) do
    leftCoins[i]=display.newImage(self.view,"img/coin.png",lr.x-60,y-60-i*40)
  end

  local rightCoins={}
  for i=1, math.floor(rightReward*100) do
    rightCoins[i]=display.newImage(self.view,"img/coin.png",rr.x+60,y-60-i*40)
  end

  return function(side)
    total=total+1
    if side==1 then
      leftTally=leftTally+1
    else
      rightTally=rightTally+1
    end
    if side==1 then
      won=won+leftReward
      cash.text=rewardtext.create(won)
      winnings.add("money",leftReward)
      if tunemanager.getID(titrateTune)==left.tune then
        count=count+1
        if count==2 then
          count=0
          leftReward=math.max(0,leftReward-0.01)
          lr.text=rewardtext.create(leftReward)
          if #leftCoins>0 then
            transition.to(table.remove(leftCoins),{x=0,onComplete=function(obj) obj:removeSelf() end})
          end
        end
      end
    else
      won=won+rightReward
      cash.text=rewardtext.create(won)
      winnings.add("money",rightReward)
      if tunemanager.getID(titrateTune)==right.tune then
        count=count+1
        if count==2 then
          count=0
          rightReward=math.max(0,rightReward-0.01)
          rr.text=rewardtext.create(rightReward)
          if #rightCoins>0 then
            transition.to(table.remove(rightCoins),{x=display.actualContentWidth,onComplete=function(obj) obj:removeSelf() end})
          end
        end
      end
    end
    return won
  end
end

function scene:startTimer(time,page)
  local counter=countdown.create(time,80)
  counter:translate(display.contentCenterX,display.contentHeight-counter.height)
  counter:start()
  self.view:insert(counter)
  timer.performWithDelay(time, function()
    composer.gotoScene("scenes.practiceintro",{params={page=page}})
  end)
end

function scene:startCounting(iterations,page)
  local tuneCount=display.newGroup()
  self.view:insert(tuneCount)
  local t=display.newText({
    text="Completed Sequences:",
    fontSize=60,
    parent=tuneCount,
    x=display.contentCenterX,
    y=0
  })
  t:setFillColor(0)

  local count=display.newText({
    text=0,
    fontSize=100,
    parent=tuneCount,
    x=display.contentCenterX,
    y=t.y+t.height/2+10
  })
  count.anchorY=0
  count:setFillColor(0)

  return tuneCount,function()
    local n=tonumber(count.text)+1
    count.text=n
    if n==iterations then
      composer.gotoScene("scenes.practiceintro",{params={page=page}})
    end
  end
end

function scene:setupSideSelector(left,right,setSelection)
  local maxWidth=math.max(left.width,self.leftMeter.width,right.width,self.rightMeter.width)
  local yMin=math.min(self.leftMeter.contentBounds.yMin,self.rightMeter.contentBounds.yMin)
  local yMax=math.min(left.contentBounds.yMax,right.contentBounds.yMax)

  local padding=30
  local selection=display.newRect(self.view,display.contentCenterX,(yMax-yMin)/2+yMin,maxWidth+padding,yMax-yMin+padding)
  selection:setFillColor(0,0,1, 0.4)
  selection:setStrokeColor(0,0,1)
  selection.strokeWidth=16
  selection.isVisible=false
  selection:toBack()

  if left.door then
    left.door:toBack()
    right.door:toBack()
  end

  local validKeys={
    left=true,
    right=true
  }
  local opposite={
    left="right",
    right="left"
  }
  local xpos={
    left=left.x-(left.door and 0 or left.width/2),
    right=right.x+(right.door and 0 or right.width/2)
  }

  local leftArrow=display.newText({
    parent=self.view,
    text="←",
    x=display.contentCenterX-selection.width/2,
    y=selection.y+selection.height/2+padding,
    fontSize=120})
  leftArrow:setFillColor(0)

  local rightArrow=display.newText({
    parent=self.view,
    text="→",
    x=display.contentCenterX+selection.width/2,
    y=selection.y+selection.height/2+padding,
    fontSize=120})
  rightArrow:setFillColor(0)

  local arrows={
    left=leftArrow,
    right=rightArrow
  }
  local tunes={
    left=left.tune,
    right=right.tune
  }

  local translate={
    space="right",
    tap="left"
  }

  self.keyListener=function(event)
    local kn=translate[event.keyName or "tap"]
    if not kn then
      return
    end
    if (event.phase=="down" or not event.phase) and validKeys[kn] then
      setSelection(tunes[kn])
      validKeys[kn]=nil
      validKeys[opposite[kn]]=true
      arrows[kn].alpha=0.3
      arrows[opposite[kn]].alpha=1
      if not selection.isVisible then
        selection.isVisible=true
        selection.alpha=0
      end
      transition.to(selection,{alpha=1,x=xpos[kn]})
    end
  end
  Runtime:addEventListener("key",self.keyListener)
  Runtime:addEventListener("tap",self.keyListener)

  return function()
    transition.to(selection, {alpha=0,x=display.contentCenterX})
    setSelection(nil)
    validKeys.left=true
    validKeys.right=true
    arrows.left.alpha=1
    arrows.right.alpha=1
  end
end

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local left,right=setup(event.params.leftTune,event.params.rightTune,event.params.leftReward,event.params.rightReward,event.params.doors)
  local start
  if event.params.timed then
    start=display.newText({
      parent=self.view,
      text="Get Ready!",
      fontSize=69,
      x=display.contentCenterX,
      y=self.leftMeter.y-self.leftMeter.height-120
    })
    start:setFillColor(0)

    local counter=countdown.create(3*1000,80)
    counter:translate(display.contentCenterX,start.y+counter.height)
    self.view:insert(counter)
    counter:start()
    transition.to(counter,{alpha=0,delay=2500,time=500,onComplete=display.remove})

    local h=start.height+counter.height
    local r=display.newRect(self.view,display.contentCenterX,(start.y+counter.y)/2,start.contentWidth,h)
    r.alpha=0.5
    start:toFront()
    counter:toFront()
    transition.to(r,{alpha=0,delay=2500,time=500,onComplete=display.remove})
  end

  local updateWinnings
  if event.params.titrate then
    local leftReward=event.params.leftReward
    local rightReward=event.params.rightReward
    local titrateTune=event.params.titrate
    updateWinnings=self:setupWinnings(left,right,leftReward,rightReward,titrateTune)
  end

  self.timer=timer.performWithDelay(event.params.timed and 3000 or 0, function()
    self.timer=nil

    local incrementCount
    if start then
      start.text="Go!"
      transition.to(start,{alpha=0,xScale=5,yScale=5,time=200,onComplete=display.remove})
    end
    if event.params.timed then
      self:startTimer(event.params.timed,event.params.page)
    end
    if event.params.iterations then
      local timerGroup
      timerGroup,incrementCount=self:startCounting(event.params.iterations,event.params.page)
      timerGroup.y=start and start.y-90 or self.leftMeter.y-self.leftMeter.height-120
    end

    local tuneSelected
    local resetSelection=self:setupSideSelector(left,right,function(tune)
      tuneSelected=tune
    end)

    if event.params.noPlay then
      return
    end
    local currentWinnings="n/a"
    self:setupUserInput(left,right,
      event.params.logChoicesFilename,
      event.params.logInputFilename,
      function(side)
        resetSelection()
        if incrementCount then
          incrementCount()
        end
        if updateWinnings then
          currentWinnings=updateWinnings(side)
        end
      end,
      event.params.onTuneComplete,
      function() return tuneSelected end,
      function() return currentWinnings end)
  end)
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    if self.onPlay then
      events.removeEventListener("key played",self.onPlay)
      events.removeEventListener("key released",self.onRelease)
      self.onPlay,self.onRelease=nil,nil
    end
    if self.keyListener then
      Runtime:removeEventListener("key", self.keyListener)
      Runtime:removeEventListener("tap", self.keyListener)
    end
    if self.timer then
      timer.cancel(self.timer)
      self.timer=nil
    end
  else
    for i=self.view.numChildren,1,-1 do
      self.view[i]:removeSelf()
    end
  end
end

scene:addEventListener("hide")

return scene