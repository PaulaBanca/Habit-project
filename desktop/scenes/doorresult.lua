local composer=require "composer"
local scene=composer.newScene()

local tunemanager=require "tunemanager"
local vischedule=require "util.vischedule"
local winnings=require "winnings"
local rewardtext=require "util.rewardtext"
local sound=require "sound"
local transition=transition
local display=display
local native=native
local timer=timer
local math=math

setfenv(1,scene)

function scene:create()
  scene.total=0
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
    text.anchorY=0
    text:setFillColor(1)
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
      
      chest:open()
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