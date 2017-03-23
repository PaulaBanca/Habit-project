local composer=require "composer"
local scene=composer.newScene()

local events=require "events"
local transition=transition
local timer=timer
local display=display

setfenv(1,scene)
function scene:create()
  local cx,cy=display.contentCenterX,display.contentCenterY
  local w,h=200,200
  local hw,hh=w/2,h/2
  local hline=display.newLine(self.view, cx-hw, cy, cx+hw,cy)
  local vline=display.newLine(self.view, cx, cy-hh, cx,cy+hh)
  hline:setStrokeColor(0)
  vline:setStrokeColor(0)
  hline.strokeWidth=10
  vline.strokeWidth=10

  local text=display.newText({
    parent=self.view,
    text="Wait for next symbol!",
    x=cx,
    y=cy-hh-20,
    fontSize=60})
  text:setFillColor(1,0,0)
  text.anchorY=1
  text.alpha=0
  self.warning=text
end
scene:addEventListener("create")

function scene:show(event)
  if event.phase=="did" then
    return
  end
  self.timer=timer.performWithDelay(event.params.time, function()
    self.timer=nil
  end)

  local fade
  self.onPlay=function()
    if fade then
      transition.cancel(fade)
    end
    self.warning.alpha=1
    fade=transition.to(self.warning,{alpha=0})
  end
  events.addEventListener("key played",self.onPlay)
end
scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    if self.timer then
      timer.cancel(self.timer)
      self.timer=nil
    end
    if self.onPlay then
      events.removeEventListener("key played",self.onPlay)
      self.onPlay=nil
    end
  end
end

scene:addEventListener("hide")

return scene