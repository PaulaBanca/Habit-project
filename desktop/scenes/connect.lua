local composer=require "composer"
local scene=composer.newScene()

local display=display
local print=print

local server=require "server"

setfenv(1,scene)

function scene:show(event)
  if event.phase=="did" then
    return
  end
  
  local button=display.newCircle(self.view,display.contentCenterX, display.contentCenterY, 100)
  button:setFillColor(0, 0.59, 1)
  local circleText=display.newText({
    parent=self.view,
    text="Connect",
    fontSize=48,
  })
  circleText:translate(button.x, button.y)
  local done=false
  local cancel
  server.create(function (hasClient)
    if done or not hasClient then
      return false
    end
    done=true
    composer.gotoScene("scenes.doors")
    if cancel then
      cancel()
    end
  end)

  local ipText=display.newText({
    text="IP: " ..server.getIP(),
    fontSize=48,
  })
  ipText.anchorX=0
  ipText.anchorY=0

  ipText:translate(10,10)
  ipText:setFillColor(0)

  function button:tap()
    if cancel then
      cancel()
      cancel=nil
      circleText.text="Connect"
      return
    end
    cancel=server.advertiseServer(function()
      circleText.text="Retry"
      cancel=nil
    end)
    circleText.text="Cancel"
  end
  button:addEventListener("tap")
end

scene:addEventListener("show")

return scene