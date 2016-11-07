local composer=require "composer"
local scene=composer.newScene()

local display=display
local table=table
local system=system
local keys=require "keys"
local chordbar=require "ui.chordbar"
local jsonreader=require "jsonreader"

setfenv(1,scene)

local instructions={
  {text="Welcome\nThis app will help you learn 2 sequences of finger presses",y=display.contentCenterY-40},
  {text="You'll tap the sequences out on circles like the ones below.\nIn the example below you should tap 3 fingers at once",y=5,width=display.contentWidth*7/8,fontSize=15,onShow=function() 
    local k=keys.create(function() end,false,true) 
    scene.view:insert(k)
    k:toBack()
    k:enable()
    local targetKeys=k:setup({chord={"a3","f4","c4"}},false,false,false,1)
    local hint=chordbar.create(targetKeys)
    if hint then
      hint:translate(0,-k:getKeyHeight()/2)
      scene.view:insert(hint)
    end
  end},
  {text="Colours will guide you until you learn the sequences. After a while they will be removed",y=5,width=display.contentWidth*7/8,onShow=function() 
    local k=keys.create(function() end,false,true)
    scene.view:insert(k)
    k:toBack()
    k:enable()
    local targetKeys=k:setup({chord={"c3","g4"}},false,false,false,1)
    local hint=chordbar.create(targetKeys)
    if hint then
      hint:translate(0,-k:getKeyHeight()/2)
      scene.view:insert(hint)
    end
  end},
  {text="Now lets practice a simple melody a few times",y=display.contentCenterY-40}
}

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local path=system.pathForFile("intro.json",system.DocumentsDirectory)
  local loaded=jsonreader.load(path)
  local step=table.remove(instructions,1)
  if not step or loaded then
    jsonreader.store(path,{done=true})
    return composer.gotoScene(loaded and "scenes.schedule" or "scenes.play",{params={intro=true}})
  end

  if step.onShow then
    step.onShow()
  end

  local text=display.newText({
    parent=scene.view,
    x=display.contentCenterX,
    y=step.y or display.contentCenterY,
    width=step.width or display.contentWidth/2,
    text=step.text,
    align="center",
    fontSize=step.fontSize or 20
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

  bg:addEventListener("tap", function (event)
    for i=scene.view.numChildren,1,-1 do
      scene.view[i]:removeSelf()
    end
    composer.gotoScene("scenes.intro")
  end)

end
scene:addEventListener("show")

return scene