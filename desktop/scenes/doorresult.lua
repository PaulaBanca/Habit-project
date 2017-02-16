local composer=require "composer"
local scene=composer.newScene()

local winnings=require "winnings"
local rewardtext=require "util.rewardtext"
local sound=require "sound"
local logger=require "util.logger"
local _=require "util.moses"
local transition=transition
local display=display
local easing=easing
local native=native
local timer=timer
local os=os
local math=math
local print=print

setfenv(1,scene)

function scene:create()
  self.total=0
  self.logger=logger.create("winnings",{"date","won","selected","not selected"})
end
scene:addEventListener("create")

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local matched=event.params.matched
  local notMatched=event.params.notMatched
  local chest=event.params.chest
  local useGems=event.params.gems
  self.view:insert(matched)
  self.view:insert(notMatched)

  local payout=event.params.payout
  local amount=payout and matched.reward or 0
  self.logger("date",os.date())
  self.logger("won",amount)
  self.logger("selected",matched.tune)
  self.logger("not selected",notMatched.tune)
  local function createPayoutText(icon,wasChosen)
    local msg=(wasChosen  and "You got: " or "Not Chosen: ")
    if useGems then
      local base,baseWidth,iconWidth,iconHeight
      do
        local triangleNumbers=_(_.range(1,math.max(2,icon.reward))):mapReduce(function(state,value)
          return state+value
        end,0):value()
        for i=1,#triangleNumbers do
          base=i
          if triangleNumbers[i]>=icon.reward then
            break
          end
        end
        local temp=display.newImage("img/gem.png")
        temp:scale(0.4,0.4)
        iconWidth,iconHeight=temp.contentWidth,temp.contentHeight
        temp:removeSelf()
        baseWidth=iconWidth*base
      end

      local y=chest.contentBounds.yMax
      local col=0
      for i=1, icon.reward do
        local group=display.newGroup()
        self.view:insert(group)
        local img=display.newImage(group, "img/gem.png")
        img.alpha=1
        display.newImage(group, "img/gem.png").blendMode="add"
        group:scale(0.01,0.01)
        group.x=chest.x
        group.y=chest.y-chest.height
        group.rotation=math.random(360)
        group.anchorChildren=true
        transition.to(group, {
          delay=i*100,
          xScale=0.4,
          yScale=0.4,
          time=700,
          rotation=0,
          anchorY=1,
          x=chest.x-baseWidth/2+col*iconWidth+iconWidth/2,
          y=y,
          transition=easing.outBounce
        })
        group:addEventListener("finalize", function()
          transition.cancel(group)
        end)
        col=col+1
        if col==base then
          base=base-1
          baseWidth=base*iconWidth
          y=y-iconHeight
          col=0
        end
      end
      local text=display.newText({text=icon.reward,fontSize=160,parent=self.view})
      text:setFillColor(0)
      text.x,text.y=chest.x,chest.y+chest.height/4
      return
    end
    local text=display.newText({
      text=msg,
      fontSize=90,
      font=native.systemFont,
      parent=scene.view
    })
    text:setFillColor(1)
    text.anchorY=1
    text.x=icon.x+icon.contentWidth/2-(icon.anchorX*icon.contentWidth)
    text.y=chest.y-chest.height-20

    local text=display.newText({
      text=rewardtext.create(payout and icon.reward or 0),
      fontSize=120,
      font=native.systemFont,
      parent=scene.view
    })
    text.strokeWidth=4
    text.anchorY=0
    text:setFillColor(amount>0 and 0 or 1)
    text.x=display.contentCenterX
    text.y=chest.y-chest.height-20
  end

  local screenTime=1500
  if chest then
    screenTime=amount*100+3000
    self.view:insert(chest)
    matched:toFront()
    transition.to(matched, {time=250,anchorX=0.5,x=display.contentCenterX})
    transition.to(chest,{time=250,anchorX=0.5,x=display.contentCenterX,onComplete=function()

      if amount==0 then
        sound.playSound("failed")
      elseif amount>=10 then
        sound.playSound("win big")
      else
        sound.playSound("win small")
      end

      chest:open(amount>0)
      createPayoutText(matched,true)
    end})
  end
  winnings.add(useGems and "gems" or "money",amount)

  -- createPayoutText(notMatched,false)

  timer.performWithDelay(screenTime, event.params.onClose)
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="did" then
    for i=scene.view.numChildren,1,-1 do
      scene.view[i]:removeSelf()
    end
  end
end

scene:addEventListener("hide")

return scene