local composer=require "composer"
local scene=composer.newScene()

local server=require "server"
local events=require "events"
local servertest=require "servertest"
local tunedetector=require "tunedetector"
local serpent=require "serpent"
local tunes=require "tunes"
local tunemanager=require "tunemanager"
local stimuli=require "stimuli"
local sound=require "sound"
local winnings=require "winnings"
local countdown=require "ui.countdown"
local progress=require "ui.progress"
local keyeventslisteners=require "util.keyeventslisteners"
local logger=require "util.logger"
local vischedule=require "util.vischedule"
local jsonreader=require "util.jsonreader"
local rewardtext=require "util.rewardtext"
local _=require "util.moses"
local transition=transition
local timer=timer
local display=display
local system=system
local table=table
local pairs=pairs
local math=math
local print=print
local assert=assert
local tonumber=tonumber
local easing=easing
local os=os
local Runtime=Runtime

setfenv(1,scene)

function setup(leftTune,rightTune,leftReward,rightReward,chests)
  local lx,rx=display.contentCenterX-50,display.contentCenterX+50
  local leftChest,rightChest
  if chests then 
    local function open(chest)
      local group=display.newGroup()
      chest.parent:insert(group)
      local top=display.newImage(group,"img/chest_open_top.png")
      top:scale(2,2)
      local bottom=display.newImage(group,"img/chest_open_bottom.png")
      bottom:scale(2,2)
      bottom.anchorY=1
      top.y=-bottom.contentHeight-top.contentHeight/2

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

  -- if doors then
  --   leftMeter:translate(0, -45)
  --   rightMeter:translate(0, -45)
  -- end

  scene.leftMeter=leftMeter
  scene.rightMeter=rightMeter

  return left,right
end

function scene:startTimer(time,page)
  local counter=countdown.create(time,80)
  counter:translate(display.contentCenterX,display.contentHeight-counter.height)
  counter:start()
  self.view:insert(counter)
  timer.performWithDelay(time, function()
    composer.gotoScene("scenes.practiceintro",{params={page=page}})
  end)

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
  
  local function inc()
    count.text=tonumber(count.text)+1
  end
  return tuneCount,inc
end

local delete=function(obj) 
  if obj.removeSelf then
    obj:removeSelf()
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
    transition.to(counter,{alpha=0,delay=2500,time=500,onComplete=delete})
      
    local h=start.height+counter.height
    local r=display.newRect(self.view,display.contentCenterX,(start.y+counter.y)/2,start.contentWidth,h)
    r.alpha=0.5
    start:toFront()
    counter:toFront()
    transition.to(r,{alpha=0,delay=2500,time=500,onComplete=delete})
  end

  local markTune
  if event.params.titrate then
    local lx=left.x+left.contentWidth/2-(left.contentWidth*left.anchorX)-left.contentWidth/2
    local rx=right.x+right.contentWidth/2-(right.contentWidth*right.anchorX)+right.contentWidth/2
    local ly=left.y+left.contentHeight/2-(left.contentHeight*left.anchorY)+left.contentHeight/2
    local ry=right.y+right.contentHeight/2-(right.contentHeight*right.anchorY)+right.contentHeight/2
    local y=math.max(ly,ry)+50
    -- local line=display.newLine(self.view,lx,y,rx,y)
    -- line.strokeWidth=8
    -- line:setStrokeColor(0)
    -- local c=display.newCircle(self.view,display.contentCenterX,y,20)
    -- c:setFillColor(1,0,0)
    -- c.strokeWidth=8
    -- c:setStrokeColor(0)

    local rightReward,leftReward=event.params.rightReward,event.params.leftReward
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

    -- local function currentReward(percent)
    --   local dr=rightReward-leftReward
    --   return leftReward+dr*percent/100
    -- end

    -- local cr=display.newText({
    --   parent=self.view,
    --   text=rewardtext.create(currentReward(50)),
    --   fontSize=32
    -- })
    -- cr:setFillColor(0)
    -- cr.x=c.x
    -- cr.anchorY=0
    -- cr.y=c.y+c.contentHeight/2+10
    -- c:toFront()

    local total=display.newText({
      parent=self.view,
      text="Won:",
      fontSize=60
    })
    total:setFillColor(0)
    total.x=display.contentCenterX
    total.y=left.y-left.contentHeight/2-420

    local won=0
    local cash=display.newText({
      parent=self.view,
      text=rewardtext.create(won),
      fontSize=80
    })
    cash:setFillColor(0)
    cash.x=display.contentCenterX
    cash.y=total.y+total.height

    local leftTally,rightTally,total=0,0,0
    local count=0
    markTune=function(side)
      total=total+1
      if side==1 then
        leftTally=leftTally+1
      else
        rightTally=rightTally+1
      end
      if side==1 then
        won=won+leftReward
        cash.text=rewardtext.create(won)
        winnings.add(leftReward)
        if tunemanager.getID(event.params.titrate)==left.tune then
          count=count+1
          if count==2 then
            count=0 
            leftReward=math.max(0,leftReward-0.01)
            lr.text=rewardtext.create(leftReward)
          end
        end
      else
        won=won+rightReward
        cash.text=rewardtext.create(won)
        winnings.add(rightReward)
        if tunemanager.getID(event.params.titrate)==right.tune then
          count=count+1
          if count==2 then
            count=0 
            rightReward=math.max(0,rightReward-0.01)
            rr.text=rewardtext.create(rightReward)
          end
        end
      end

      -- local r=1-leftTally/total
      -- cr.text=rewardtext.create(currentReward(r*100))
      -- local dx=rx-lx
      -- local nx=lx+dx*r
      -- transition.cancel("slide")
      -- transition.to(c,{tag="slide",x=nx,onCancel=function()
      --   c.x=nx
      -- end})
      -- transition.to(cr,{tag="slide",x=nx,onCancel=function()
      --   cr.x=nx
      -- end})
    end
  end

  self.timer=timer.performWithDelay(event.params.timed and 3000 or 0, function()
    self.timer=nil
    local logField=logger.create(event.params.logChoicesFilename,{"date","sequence selected","round","input time","mistakes","left choice","right choice"})

    local incrementCount
    if event.params.timed then
      start.text="Go!"
      transition.to(start,{alpha=0,xScale=5,yScale=5,time=200,onComplete=delete})
      local timerGroup
      timerGroup,incrementCount=self:startTimer(event.params.timed,event.params.page)
      timerGroup.y=start.y-50
    else
      incrementCount=function() end 
    end

    local total=0
    local steps=0
    local mistakes=0
    local reset
    local tuneSelected
    local inMistakeStreak
    local function madeMistake()
      if tuneSelected and tuneSelected<0 then
        return
      end
      sound.playSound("wrong")
      reset()
      if not inMistakeStreak then
        mistakes=mistakes+1
        inMistakeStreak=true
      end
      local t=display.newText({
        text=not tuneSelected and "Select side first" or "Mistake, start again!",
        fontSize=120,
        parent=self.view,
        x=display.contentCenterX,
        y=left.y-left.height/2-10
      })
      t:translate(0, 400)
      t.anchorY=0
      t:setFillColor(1,0,0)
      transition.to(t, {tag="mistake",alpha=0,onComplete=delete,onCancel=delete})
    end

    local start=system.getTimer()
    local meterResetTimer
    local function tuneCompleted(tune)
      steps=0
      reset()
      inMistakeStreak=false
      sound.playSound("correct")
      if event.params.onTuneComplete then
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
      if markTune then
        markTune(side)
      end
      meterResetTimer=timer.performWithDelay(500, function()
        meterResetTimer=nil
        if not self.leftMeter.numChildren then
          return
        end
        self.leftMeter:reset()
        self.rightMeter:reset()
        left:unselect()
        right:unselect()
        if event.params.onTuneComplete then
          event.params.onTuneComplete(matched,notMatched,side)
        end
      end)

      logField("date",os.date())
      logField("sequence selected",tune)
      logField("round",round)
      logField("input time",system.getTimer()-start)
      logField("mistakes",mistakes)
      logField("left choice",left.tune)
      logField("right choice",right.tune)
      start=system.getTimer()
     
      matched:setSelected()
      transition.to(matched, {strokeWidth=0})
      if matched.door then
        transition.to(notMatched.door, {alpha=0})
      end
      incrementCount()
    end

    local function numberOfSteps()
      if left.tune==-3 or right.tune==-3 then 
        return 3
      end 
      return 6
    end

    local completeChain=0
    local onPlay,onRelease
    onPlay,onRelease,reset=keyeventslisteners.create(event.params.logInputFilename,function(tune)
      if tune~=tuneSelected then
        madeMistake()
        return
      end
      completeChain=0
      steps=0
      if tune~=left.tune and tune~=right.tune then
        self.leftMeter:reset()
        self.rightMeter:reset()
        madeMistake()
        return
      end
      local normalMeter=left.tune==tune and self.leftMeter or self.rightMeter
      normalMeter:mark(6,true)
      tuneCompleted(tune)
    end,madeMistake,function(event)
      if not left or not tuneSelected then
        if not tuneSelected then
          madeMistake()
        end
        return
      end
      if meterResetTimer then
        timer.cancel(meterResetTimer)
        meterResetTimer=nil
        self.leftMeter:reset()
        self.rightMeter:reset()
      end    

      if event.phase~="released" or not event.allReleased then
        return
      end
      if event.matchingTunes and tuneSelected>0 then
        if not event.matchingTunes[tuneSelected] then
          return madeMistake()
        end 
        if left.tune==tuneSelected then
          local leftMatch=event.matchingTunes[left.tune]
          if leftMatch then
            for i=1,leftMatch.step do
              self.leftMeter:mark(i,true)
            end
            inMistakeStreak=false
          else
            self.leftMeter:reset()
          end
          return
        end
        if right.tune==tuneSelected then
          local rightMatch=event.matchingTunes[right.tune]
          if rightMatch then
            for i=1,rightMatch.step do
              self.rightMeter:mark(i,true)
            end
            inMistakeStreak=false
          else 
            self.rightMeter:reset()
          end
          return
        end
      else
        if tuneSelected>0 then
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
      local good=true
      if event.matchingTunes then
        for i=1, 3 do
          if event.matchingTunes[i] and event.matchingTunes[i].step==steps then
            good=false            
          end
        end
      end
      if left.tune>0 and right.tune>0 then 
        return
      end
      local wildMeter=left.tune<0 and self.leftMeter or self.rightMeter
      if steps>0 then
        wildMeter:mark(steps,good)
        inMistakeStreak=false
      else
        wildMeter:reset()
      end
     
      if steps==numberOfSteps() then
        steps=0
        completeChain=0
        if good then
          tuneCompleted(left.tune<right.tune and left.tune or right.tune)
        else
          wildMeter:reset()
        end
      end
    end,nil,true,numberOfSteps)
    events.addEventListener("key played",onPlay)
    events.addEventListener("key released",onRelease)
    self.onRelease=onRelease
    self.onPlay=onPlay

    reset=_.wrap(reset,function(f,args)
      self.leftMeter:reset()
      self.rightMeter:reset()
      f()
      steps=0
      completeChain=0
    end)

    local maxWidth=math.max(left.width,scene.leftMeter.width,right.width,scene.rightMeter.width)
    local yMin=math.min(scene.leftMeter.contentBounds.yMin,scene.rightMeter.contentBounds.yMin)
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
    
    local lastPress
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
    self.keyListener=function(event)
      if event.phase=="down" and validKeys[event.keyName] then
        tuneSelected=tunes[event.keyName]
        validKeys[event.keyName]=nil
        validKeys[opposite[event.keyName]]=true
        arrows[event.keyName].alpha=0.3
        arrows[opposite[event.keyName]].alpha=1
        transition.to(selection,{x=xpos[event.keyName]})
        if not selection.isVisible then
          selection.isVisible=true
          selection.alpha=0
          transition.to(selection,{alpha=1})
        end
      end
    end
    Runtime:addEventListener("key",self.keyListener)
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