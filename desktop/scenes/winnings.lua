local composer=require "composer"
local scene=composer.newScene()

local winnings=require "winnings"
local rewardtext=require "util.rewardtext"
local display=display
local native=native
local Runtime=Runtime
local os=os

setfenv(1,scene)

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local text=display.newText({
    text="Your total winnings are:\n\n" .. rewardtext.create(winnings.get("money")).."\n\nTap to continue",
    fontSize=60,
    width=display.actualContentWidth/2,
    font=native.systemFont,
    parent=scene.view,
    align="center"
  })
  text:setFillColor(0)
  text.x=display.contentCenterX
  text.y=display.contentCenterY*0.5

  local any=display.newText({
    parent=self.view,
    text="Press any key to close",
    x=display.contentCenterX,
    y=display.contentHeight-20,
    align="center",
    fontSize=40})
  any.anchorY=1
  any:setFillColor(0)

  local nextScene
  nextScene=function(event)
    if event.phase=="up" then
      Runtime:removeEventListener("key", nextScene)
      composer.gotoScene("scenes.shockertask")
    end
  end
  Runtime:addEventListener("key", nextScene)
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