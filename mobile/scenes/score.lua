local composer=require "composer"
local scene=composer.newScene()

local stimuli=require "stimuli"
local jsonreader=require "jsonreader"
local daycounter=require "daycounter"
local practicelogger=require "practicelogger"
local incompletetasks=require "incompletetasks"
local i18n = require ("i18n.init")
local user=require "user"
local coins=require("mobileconstants").coins
local display=display
local system=system
local native=native
local tonumber=tonumber
local Runtime=Runtime
local math=math
local timer=timer

setfenv(1,scene)

local path=system.pathForFile("score.json",system.DocumentsDirectory)

function scene:isTouchingCoin(c)
  for k = #self.coins, 1, -1 do
    local dx = c.x - self.coins[k].x
    local dy = c.y - self.coins[k].y

    if dx * dx + dy * dy < (c.contentWidth/2) ^ 2 then
      return true
    end
  end
  return false
end

function scene:isOutsideOfBowl(c)
  local dx = c.x - display.contentCenterX
  local dy = c.y - display.contentCenterY

  local elipseWidth = self.coinBounds.xMax - self.coinBounds.xMin
  local elipseHeight = self.coinBounds.yMax - self.coinBounds.yMin
  return (dx * dx)/((elipseWidth/2 - c.contentWidth/2 - 8)^2) +
        (dy * dy)/((elipseHeight/2 - c.contentHeight/2 - 8)^2) > 1
end

function scene:addCoin(animate,track)
  local c = display.newImage(self.view, coins[track])
  c:scale(0.5,0.5)
  if animate then
    c:translate(
      display.contentCenterX + math.random(c.contentWidth * 4) - c.contentWidth * 2,
        - c.height
    )
    local v = 0

    local fallAnimation
    fallAnimation = function(event)
      c.y = c.y + v
      v = v + 1
      if self:isTouchingCoin(c) or c.y > display.contentCenterY and self:isOutsideOfBowl(c) then
         while self:isOutsideOfBowl(c) do
          local dx = c.x - display.contentCenterX
          local dy = c.y - display.contentCenterY
          c.x = c.x + (dx > 0 and -1 or 1)

          c.y = c.y + (dy > 0 and -1 or 1)
        end
        Runtime:removeEventListener("enterFrame", fallAnimation)
      end
    end
    Runtime:addEventListener("enterFrame", fallAnimation)

    c:addEventListener("finalize", function()
      Runtime:removeEventListener("enterFrame", fallAnimation)
    end)
    return
  else
    c:translate(display.contentCenterX, self.coinBounds.yMax - c.contentHeight/2)
  end
  repeat
    local touching = self:isTouchingCoin(c)

    if touching then
      c:translate((math.random() > 0.5 and -c.contentWidth or c.contentWidth) * math.random(),-2)
    end
  until not touching

  self.coins[#self.coins + 1] = c

  while self:isOutsideOfBowl(c) do
    local dx = c.x - display.contentCenterX
    local dy = c.y - display.contentCenterY
    c.x = c.x + (dx > 0 and -1 or 1)

    c.y = c.y + (dy > 0 and -1 or 1)
  end
end

function scene:show(event)
  if event.phase=="did" then
    return
  end

  if event.params.score then
    local back = display.newImage(
      self.view,
      "img/pot_back.png")

    local front = display.newImage(
      self.view,
      "img/pot_front.png")

    back:translate(display.contentCenterX, display.contentCenterY)
    front:translate(display.contentCenterX, display.contentCenterY)

    local bounds = front.contentBounds
    self.coinBounds = bounds
    self.coins = {}

    local rewards = user.get("rewards_earned") or {0,0}
    local track = event.params.track
    for i = 1, rewards[track] do
       self:addCoin(false, track)
     end

    for i = 1, event.params.score do
      timer.performWithDelay(400 * i, function()
        self:addCoin(true, track)
        front:toFront()
      end)
    end

    rewards[track] = rewards[track] + event.params.score
    user.store("rewards_earned", rewards)

    front.alpha = 0.5
    front:toFront()

  else
     local text=display.newText({
      text=i18n("score.well_done"),
      fontSize=20,
      font=native.systemFont,
      parent=scene.view
    })
    text.x=display.contentCenterX
    text.y=display.contentCenterY*0.5
  end

  local bg=display.newRect(self.view,display.contentCenterX,display.contentHeight-30,120,50)
  bg:setFillColor(83/255, 148/255, 250/255)

  display.newText({
    parent=self.view,
    text=i18n("buttons.done"),
    fontSize=20
  }):translate(bg.x, bg.y)

  local d=daycounter.getPracticeDay()
  local practiced=daycounter.getPracticed(d)
  local quizzed=user.get("quizzed") or {}
  local qd=quizzed[d] or {}
  local candiate
  for i=1,2 do
    if not qd[i] and practiced[i] and practiced[i]>=2 then
      candiate=i
      break
    end
  end
  local scn,params="scenes.schedule"
  if candiate then
    scn,params="scenes.pleasure",{
      track=candiate,
      practice=practicelogger.getPractices(candiate),
      practiceDay=d
    }
    incompletetasks.push(scn,params)
  end
  bg:addEventListener("tap", function()
    composer.gotoScene(scn,{params=params})
  end)
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