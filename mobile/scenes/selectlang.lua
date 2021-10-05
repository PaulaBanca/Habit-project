local composer=require "composer"
local scene=composer.newScene()

local i18n = require ("i18n.init")
local languages = require ("languages")
local user=require "user"
local display=display
local system=system
local ipairs = ipairs

setfenv(1,scene)

function scene:create()

  local options = {
    {
      label = "img/noun_Language_2001997.png",
      labelIsImg = true,
      selectFunc=function(v)
        i18n.setLocale(v)
        user.store("language", v)
      end,
      choices = {}
    }
  }

  local choices = options[1].choices

  for _,lang in ipairs(languages.getLanguages()) do
    choices[#choices + 1] = lang
  end

  local y=20
  local button
  for i=1,#options do
    local opt=options[i]
    local label = display.newImageRect(self.view, opt.label,150,150)
    label.x=display.contentCenterX
    label.y=y
    label.anchorY = 0
    y=y+label.height
    y=y+20

    local choices = opt.choices
    local optWidth=(display.contentWidth*3/4-(20*#choices))/#choices
    local bgs={}
    for k=1, #choices do
      local bg=display.newRect(
        self.view,
        display.contentWidth/8+optWidth/2+(optWidth+20)*(k-1),
        y,
        optWidth,
        50)

      bg:setFillColor(83/255, 148/255, 250/255)
      if k==opt.default then
        bg.strokeWidth=8
      end
      bgs[k]=bg

      display.newText({
        parent=self.view,
        text=choices[k],
        fontSize=20
      }):translate(bg.x, bg.y)

      bg:addEventListener("tap", function()
        for i=1,#bgs do
          bgs[i].strokeWidth=0
        end
        button.isVisible=true
        opt.selectFunc(choices[k])
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

  display.newImageRect(button,
    "img/correct.png", bg.height-10, bg.height-10)
    :translate(bg.x, bg.y)

  bg:addEventListener("tap", function()
    composer.gotoScene("scenes.setup")
  end)
end
scene:addEventListener("create")

function scene:show(event)
  if event.phase=="will" then
    if user.get("language") then

      i18n.setLocale(user.get("language"))
      composer.gotoScene("scenes.intro")

      return
    end
  end
end
scene:addEventListener("show")

return scene