local composer=require "composer"
local scene=composer.newScene()

local _=require "util.moses"
local display=display
local system=system
local math=math
local print=print

setfenv(1,scene)

composer.setVariable("preferencetest",{})

local function setSwitch(index,v)
  local opts=composer.getVariable("preferencetest")
  opts[index]={switch=v=="Yes"}
  composer.setVariable("preferencetest",opts)
end
local options={
  {label="Practice Order",options={"A","B"},selectFunc=function(v) 
    composer.setVariable("firstpractice", v=="A" and 1 or 2)
    composer.setVariable("secondpractice", v=="A" and 2 or 1)
  end},
  {label="Switch sides - Preference 1",options={"No","Yes"},selectFunc=function(v) setSwitch(1,v) end},
  {label="Switch sides - Preference 2",options={"No","Yes"},selectFunc=function(v) setSwitch(2,v) end},
  {label="Switch sides - Preference 3",options={"No","Yes"},selectFunc=function(v) setSwitch(3,v) end},
  {label="Switch sides - Preference 4",options={"No","Yes"},selectFunc=function(v) setSwitch(4,v) end},
  {label="Switch sides - Preference 5",options={"No","Yes"},selectFunc=function(v) setSwitch(5,v) end},
}

function scene:create()
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
        for i=1,#bgs do
          bgs[i].strokeWidth=0
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
    composer.gotoScene("scenes.practiceintro")
  end)
end
scene:addEventListener("create")

function scene:show(event)
  if event.phase=="will" then
    return
  end
  if system.getInfo("environment")=="simulator" then
    for i=1,#options do
      local row=options[i]
      local select=math.random(#row.options)
      local selection=row.options[select]
      row.selectFunc(selection)
    end
    composer.gotoScene("scenes.practiceintro")
  end
end

scene:addEventListener("show")

return scene