local composer=require "composer"
local scene=composer.newScene()

local stimuli=require "stimuli"
local display=display
local native=native
local timer=timer

setfenv(1,scene)

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local text=display.newText({
    text="You won: " .. event.params.winnings,
    fontSize=60,
    font=native.systemFont,
    parent=scene.view
  })
  text:setFillColor(0)
  text.x=display.contentCenterX
  text.y=display.contentCenterY*0.5
  
  local track=event.params.track
  local img=stimuli.getStimulus(track)
  scene.view:insert(img)
  img.x=display.contentCenterX
  img.y=display.contentCenterY
  img:scale(0.5,0.5)

  timer.performWithDelay(1000,function() composer.gotoScene("scenes.doors") end)
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