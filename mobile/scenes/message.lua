local composer=require "composer"
local scene=composer.newScene()

local display=display
local table=table
local system=system
local keys=require "keys"
local chordbar=require "ui.chordbar"
local jsonreader=require "jsonreader"

setfenv(1,scene)

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local text=display.newText({
    parent=scene.view,
    x=display.contentCenterX,
    y=event.params.textY or display.contentCenterY,
    width=event.params.textWidth or display.contentWidth/2,
    text=event.params.text,
    align="center",
    fontSize=event.params.fontSize or 20
  })
  text.anchorY=0

  local bg=display.newRect(scene.view,display.contentCenterX, text.y+text.height+20,100 ,30)
  bg:setFillColor(83/255, 148/255, 250/255)
  display.newText({
    parent=scene.view,
    x=bg.x,
    y=bg.y,
    text="Next",
    align="center"
  }) 

  local nextScene,nextParams=event.params.nextScene,event.params.nextParams
  bg:addEventListener("tap", function (event)
    for i=scene.view.numChildren,1,-1 do
      scene.view[i]:removeSelf()
    end
    composer.gotoScene(nextScene,{params=nextParams})
  end)

end
scene:addEventListener("show")

return scene