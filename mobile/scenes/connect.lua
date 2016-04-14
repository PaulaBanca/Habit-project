local composer=require "composer"
local scene=composer.newScene()

local display=display
local print=print
local transition=transition

local client=require "client"
local clientloop=require "clientloop"

setfenv(1,scene)

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local cross=display.newImage(self.view,"img/cross.png")
  cross.anchorX=1
  cross.anchorY=0
  cross.x=display.contentWidth-20
  cross.y=20
  cross:scale(0.5,0.5)

  cross:addEventListener("tap",function() 
    composer.gotoScene("scenes.schedule")
  end)

   local ipText=display.newText({
    text="IP: " ..client.getIP(),
    fontSize=48,
    parent=scene.view
  })
  ipText.anchorX=0
  ipText.anchorY=0

  ipText:translate(10,10)
  

  local button=display.newCircle(scene.view,display.contentCenterX, display.contentCenterY, 100)
  button:setFillColor(0, 0.59, 1)
  local circleText=display.newText({
    text="Connect",
    fontSize=48,
    parent=scene.view
  })
  circleText:translate(button.x, button.y)

  local cancel
  function button:tap()
    if cancel then
      cancel()
      cancel=nil
      circleText.text="Connect"
      return
    end
    cancel=client.findServer(function (server)
      cancel=nil
      if not server then
        circleText.text="Retry"
      else
        button:removeEventListener("tap")
        circleText.text="Connected"
        transition.to(button, {alpha=0,onComplete=function (obj)
          obj:removeSelf()
          circleText:removeSelf()
          local stop=clientloop.start(server)
          composer.gotoScene("scenes.play",{effect="fade",params={headless=true,onClose=stop}})
        end})
      end
    end)
    circleText.text="Cancel"

  end
  button:addEventListener("tap")
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    return
  end
  for i=self.view.numChildren,1,-1 do
    self.view[i]:removeSelf()
  end
end
scene:addEventListener("hide")

return scene