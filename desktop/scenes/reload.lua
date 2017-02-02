local composer=require "composer"
local scene=composer.newScene()

local _=require "util.moses"

local print=print
setfenv(1, scene)

function scene:show(event)
  if event.phase~="will" then
    return
  end
  composer.removeScene(event.params.scene, false)
  local params=event.params.params and _.clone(event.params.params,false)
  composer.gotoScene(event.params.scene,{params=params})
end

scene:addEventListener("show")

return scene