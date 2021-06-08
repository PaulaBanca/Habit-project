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
local sides=require("mobileconstants").coinsSides
local physics = require "physics"
local display=display
local system=system
local native=native
local tonumber=tonumber
local Runtime=Runtime
local math=math
local timer=timer
local print=print
local unpack = unpack
local transition=transition

setfenv(1,scene)

local coinScale = 0.5

local pots = {
  {
    front = "img/pot_front.png",
    lid = "img/pot_lid.png"
  },
  {
    front = "img/pot_front_orange.png",
    lid = "img/pot_lid_orange.png"
  }
}

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

function scene:addCoin(track, position, static)
  local c = display.newImage(self.coins, sides[track])
  c:scale(coinScale,coinScale)
  c:translate(position.x, position.y)

  -- if self:isOutsideOfBowl(c) then
  --   local dx = c.x - display.contentCenterX
  --   local dy = c.y - display.contentCenterY
  --   local ehh = (self.coinBounds.yMax - self.coinBounds.yMin) * 0.25

  --   local invMag = ehh / ((dx * dx + dy * dy) ^ 0.5)

  --   c.x = dx * invMag + display.contentCenterX
  --   c.y = dy * invMag + display.contentCenterY
  -- end

  c.rotation = position.rotation
  if static then
  else
    physics.addBody(c, {density = 10, friction = 0.5, box = {angle = c.rotation, halfWidth = c.contentWidth/2, halfHeight = c.contentHeight/2}})
  end
  return c
end

function scene:addFallingCoin(track)
  local c = display.newImage(self.coins, coins[track])
  c:scale(coinScale,coinScale)
  c:translate(
    display.contentCenterX + math.random(c.contentWidth) - c.contentWidth/2,
      - c.height
  )
  c.isFalling = true
  local r = c.contentWidth/2
  c.rotation = math.random(360)
  physics.addBody(c, {radius = r, bounce = 0.2})

  local detectStop
  local function fall(event)
    Runtime:removeEventListener("enterFrame", detectStop)

    transition.to(c, {yScale = 0.00001, y = c.y + 10, onComplete=display.remove})
    local side = scene:addCoin(track, {x = c.x, y = c.y + c.contentHeight*0.3})
    c:toFront()
    physics.removeBody(c)

    side:scale(1, 2)
    transition.to(side,{yScale = 1, onComplete = function() display.remove(c) end})
  end

  timer.performWithDelay(1000, function()
    local collided
    c:addEventListener("collision", function()
      if collided then
        return
      end
      collided = true
      timer.performWithDelay(1, fall)
    end)
  end)

  local threshold = 2 * 2
  detectStop = function(event)
    local vx, vy = c:getLinearVelocity()
    if vx * vx + vy * vy > threshold then
      return
    end
    fall()
  end
  Runtime:addEventListener("enterFrame", detectStop)
  c.finalize = function(self,event)
    Runtime:removeEventListener("enterFrame", detectStop)
  end
  c:addEventListener("finalize")
end

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local delayButton = 0
  if event.params.score then
    physics.start()

    local back = display.newImage(
      self.view,
      "img/pot_back.png")

    local ewh = back.contentWidth/2
    local ehh = back.contentHeight/2
    local chain = {}
    local ci = 1
    for i = 1, 20 * 2, 2 do
      local t = (i/2 * math.pi * 2) / 20
      if i <= 28 or i > 31 then
        chain[ci  ] = math.cos(t) * ewh
        chain[ci+1] = math.sin(t) * ehh
        ci = ci + 2
      elseif i == 29 then
        local topx = math.cos(t) * ewh
        local topy = math.sin(t) * ehh
        chain[ci  ] = topx - 400
        chain[ci+1] = topy - 100
        ci = ci + 2

        chain[ci  ] = topx - 400
        chain[ci+1] = topy + ehh * 2
        ci = ci + 2

        chain[ci  ] = topx + 800 + ewh * 2
        chain[ci+1] = topy + ewh * 2
        ci = ci + 2

        chain[ci  ] = topx - 100 + 200 + ewh * 2
        chain[ci+1] = topy - 100
        ci = ci + 2
      end
    end
    physics.addBody(back, "static",
        {
            chain=chain,
            connectFirstAndLastChainVertex = true
        }
    )

    local track = event.params.track
    local front = display.newImage(
      self.view,
      pots[track].front)

    back:translate(display.contentCenterX, display.contentCenterY)
    front:translate(display.contentCenterX, display.contentCenterY)

    local bounds = back.contentBounds
    self.coinBounds = bounds
    self.coins = {}

    local rewards = user.get("rewards_earned") or {0,0}
    local symbol = stimuli.getStimulus(track)
    self.view:insert(symbol)
    symbol:scale(0.35,0.35)
    symbol:translate(front.x, front.y + 50)
    symbol[1].blendMode = "add"
    symbol[1].alpha = 0.2

    if event.params.full then
      local lid = display.newImage(self.view, pots[track].lid)
      lid:translate(display.contentCenterX, display.contentCenterY - 60)
    else

      local coinGroup = display.newGroup()
      self.view:insert(coinGroup)
      self.coins = coinGroup
      local positions =  user.get("coin_positions") or {{}, {}}
      local shapes = {}

      local function rotate(dx, dy, r)
        return dx * math.cos(r) - dy * math.sin(r),
               dx * math.sin(r) + dy * math.cos(r)
      end
      for i = 1, #positions[track] do
         local c = self:addCoin(track, positions[track][i],true)
         local rd = math.rad(c.rotation)
         local hw = c.width * c.xScale * 0.5
         local hh = c.height * c.yScale * 0.5
         local tlx,tly = rotate(-hw, -hh, rd)
         local trx,try = rotate( hw, -hh, rd)
         local brx,bry = rotate( hw,  hh, rd)
         local blx,bly = rotate(-hw,  hh, rd)
         shapes[i] = {shape = {
            c.x+tlx,c.y+tly,
            c.x+trx,c.y+try,
            c.x+brx,c.y+bry,
            c.x+blx,c.y+bly
          }
        }
      end

      physics.addBody(display.newCircle(self.view,0,0,1), "static", unpack(shapes))

      if not event.params.extinguished then
        for i = 1, event.params.score do
          timer.performWithDelay(400 * (i - 1), function()
            self:addFallingCoin(track)
          end)
        end
        delayButton = 400 * event.params.score
      end
      front:toFront()
      symbol:toFront()
    end

    rewards[track] = rewards[track] + event.params.score
    user.store("rewards_earned", rewards)

    front.alpha = event.params.extinguished and 1 or 0.5
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

  local d=daycounter.getPracticeDay()
  local practiced=daycounter.getPracticed(d)
  local scn,params="scenes.schedule"
  if practiced then
    local quizzed=user.get("quizzed") or {}
    local qd=quizzed[d] or {}
    local candiate
    for i=1,2 do
      if not qd[i] and practiced[i] and practiced[i]>=2 then
        candiate=i
        break
      end
    end
    if candiate then
      scn,params="scenes.pleasure",{
        track=candiate,
        practice=practicelogger.getPractices(candiate),
        practiceDay=d
      }
      incompletetasks.push(scn,params)
    end
  end

  local button = display.newGroup()
  self.view:insert(button)
  local bg=display.newRect(button,display.contentCenterX,display.contentHeight-30,120,50)
  bg:setFillColor(83/255, 148/255, 250/255)
  bg.tap = function()
    local positions = user.get("coin_positions") or {{},{}}
    if self.coins.numChildren then
      for i = 1, self.coins.numChildren do
        local c = self.coins[i]
        positions[event.params.track][i] = {x = c.x, y = c.y, rotation = c.rotation}
      end
      user.store("coin_positions", positions)
    end
    composer.gotoScene(scn,{params=params})
  end

  display.newText({
    parent=button,
    text=i18n("buttons.done"),
    fontSize=20
  }):translate(bg.x, bg.y)


  if delayButton > 0 then
    button.isVisible = false
    timer.performWithDelay(delayButton, function()
      local checkFalling
      checkFalling = timer.performWithDelay(100, function()
        for i = self.coins.numChildren, 1, -1 do
          if self.coins[i].getLinearVelocity then
            local vx, vy = self.coins[i]:getLinearVelocity()
            if vx * vx + vy * vy > 5 * 5
             then
              return
            end
          end
        end
        button.isVisible = true
        timer.cancel(checkFalling)
      end, -1)
    end)
  end

  bg:addEventListener("tap")
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="did" then
    for i=self.view.numChildren,1,-1 do
      self.view[i]:removeSelf()
    end
  end
end

scene:addEventListener("hide")

return scene