local composer=require "composer"
local scene=composer.newScene()

local user=require "user"
local display=display
local system=system

setfenv(1,scene)

composer.loadScene("scenes.select")
local options={
  {label="Melody Setup",options={"A","B"},selectFunc=function(v)
    local c=composer.getScene("scenes.select")
    c:setup(v=="A" and 0 or 1)
    user.store("melody setup",v)
  end},
  {label="Left Handed",options={"Yes","No"},selectFunc=function(v)
    user.store("left handed",v=="Yes")
  end},
}

function scene:create()
  local y=20
  local button
  for i=1,#options do
    local opt=options[i]
    local t=display.newText({
      parent=self.view,
      text=opt.label,
      fontSize=34
    })
    t.x=display.contentCenterX
    t.y=y
    y=y+t.height
    y=y+20

    local optWidth=(display.contentWidth*3/4-(20*#opt.options))/#opt.options
    local bgs={}
    for k=1,#opt.options do
      local bg=display.newRect(self.view,display.contentWidth/8+optWidth/2+(optWidth+20)*(k-1),y,optWidth,50)
      bg:setFillColor(83/255, 148/255, 250/255)
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
        for i=1,#bgs do
          bgs[i].strokeWidth=0
        end
        button.isVisible=true
        opt.selectFunc(opt.options[k])
        bg.strokeWidth=8
      end)
    end
    y=y+70
  end

  button=display.newGroup()
  button.isVisible=false
  self.view:insert(button)
  local bg=display.newRect(button,display.contentCenterX,y,display.contentWidth/8,50)
  bg:setFillColor(83/255, 148/255, 250/255)

  display.newText({
    parent=button,
    text="Done",
    fontSize=20
  }):translate(bg.x, bg.y)

  bg:addEventListener("tap", function()
    if system.getInfo("environment")=="simulator" then
      composer.gotoScene("scenes.debug")
    else
      composer.gotoScene("scenes.intro")
    end
  end)
end
scene:addEventListener("create")

function scene:show(event)
  if event.phase=="will" then
    if user.get("melody setup") then
      local c=composer.getScene("scenes.select")
      c:setup(user.get("melody setup")=="A" and 0 or 1)
      if system.getInfo("environment")=="simulator" then
        composer.gotoScene("scenes.debug")
      else
        composer.gotoScene("scenes.intro")
      end

      return
    end
  end
end
scene:addEventListener("show")

return scene