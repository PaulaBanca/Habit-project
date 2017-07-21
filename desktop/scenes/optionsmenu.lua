local composer=require "composer"
local scene=composer.newScene()

local _=require "util.moses"
local display=display

setfenv(1,scene)

function scene:show(event)
  if event.phase=="will" then
    return
  end
  local options=event.params.options
  local nextScene=event.params.nextScene
  local y=20
  local selected=_.rep(false,#options)
  local button
  for i=1,#options do
    local opt=options[i]
    local t=display.newText({
      parent=self.view,
      text=opt.label,
      fontSize=34
    })
    t:setFillColor(0)
    t.x=display.contentCenterX
    t.y=y
    y=y+t.height
    y=y+20

    local optWidth=(display.contentWidth*3/4-(20*#opt.options))/#opt.options
    local bgs={}
    for k=1,#opt.options do
      local bg=display.newRect(self.view,display.contentWidth/8+optWidth/2+(optWidth+20)*(k-1),y,optWidth,50)
      bg:setFillColor(83/255, 148/255, 250/255)
      bg:setStrokeColor(0)
      if k==opt.default then
        bg.strokeWidth=8
      end
      bgs[k]=bg

      display.newText({
        parent=self.view,
        text=opt.options[k],
        fontSize=20
      }):translate(bg.x, bg.y)

      bg:addEventListener("tap", function()
        for b=1,#bgs do
          bgs[b].strokeWidth=0
        end
        selected[i]=true
        button.isVisible=not _.contains(selected,false)
        opt.selectFunc(opt.options[k])
        bg.strokeWidth=8
      end)
    end
    y=y+70
  end

  button=display.newRect(self.view,display.contentCenterX,y,display.contentWidth/8,50)
  button:setFillColor(83/255, 148/255, 250/255)
  button.isVisible=false
  display.newText({
    parent=self.view,
    text="Done",
    fontSize=20
  }):translate(button.x, button.y)

  button:addEventListener("tap", function()
    composer.gotoScene(nextScene)
  end)
end
scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    return
  end
  for i=self.view.numChildren, 1, -1 do
    self.view[i]:removeSelf()
  end
end
scene:addEventListener("hide")

return scene