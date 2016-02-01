local composer=require "composer"
local scene=composer.newScene()

local display=display
local tunes=require "tunes"
local play=require "scenes.play"

setfenv(1,scene)

local options={
  {label="Melody Length",options={6,5,4,3},default=1,selectFunc=function(v) tunes.setMaxLength(v) end},
  {label="Phase Length",options={10,8,6,4},default=1,selectFunc=function(v)
    play.setMaxLearningLength(v)
   end},
}

function scene:create()
  local y=20
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
        opt.selectFunc(opt.options[k])
        bg.strokeWidth=8
      end)
    end
    y=y+70
  end

  local bg=display.newRect(self.view,display.contentCenterX,y,display.contentWidth/8,50)
  bg:setFillColor(83/255, 148/255, 250/255)
  
  display.newText({
    parent=self.view,
    text="Done",
    fontSize=20
  }):translate(bg.x, bg.y)

  bg:addEventListener("tap", function()
    composer.gotoScene("scenes.intro")
  end)
end
scene:addEventListener("create")

return scene