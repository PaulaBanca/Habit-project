local composer=require "composer"
local scene=composer.newScene()

local events=require "events"
local transition=transition
local timer=timer
local display=display

setfenv(1,scene)
function scene:create()
  local text=display.newText({
    parent=self.view, 
    text="Interval\n\nTake a break before continuing\n\nPress a button to continue",
    x=display.contentCenterX,
    y=display.contentCenterY,
    width=display.contentWidth-40,
    align="center",
    fontSize=60})

  text:setFillColor(0)
end
scene:addEventListener("create")

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local onPlay
  onPlay=function()
    events.removeEventListener("key played",onPlay)
    composer.gotoScene(event.params.scene,{params=event.params.params})
  end
  events.addEventListener("key played",onPlay)
end
scene:addEventListener("show")

return scene