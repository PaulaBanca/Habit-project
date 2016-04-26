local composer=require "composer"
local scene=composer.newScene()

local tunemanager=require "tunemanager"
local vischedule=require "util.vischedule"
local winnings=require "winnings"
local rewardtext=require "util.rewardtext"
local sound=require "sound"
local logger=require "util.logger"
local transition=transition
local display=display
local native=native
local timer=timer
local math=math
local os=os

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
  self.view:insert(matched)
  self.view:insert(notMatched)
  
  local payout=vischedule.reward(event.params.side)
  local amount= payout and matched.reward or 0
  self.logger("date",os.date())
  self.logger("won",amount)
  self.logger("selected",matched.tune)
  self.logger("not selected",notMatched.tune)
  
  local function createPayoutText(icon,wasChosen)
    local msg=(wasChosen  and "You got: " or "Not Chosen: ")
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

  if chest then
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
  scene.total=scene.total+amount
  winnings.add(amount)

  -- createPayoutText(notMatched,false)
      
  timer.performWithDelay(1500, event.params.onClose)
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