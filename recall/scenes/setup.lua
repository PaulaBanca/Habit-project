local composer=require "composer"
local scene=composer.newScene()

local user=require "user"
local display=display
local i18n = require ("i18n.init")
local intro = require ("scenes.intro")
local _ = require ("util.moses")
local require = require
local widget = require ("widget")

setfenv(1,scene)

local options={
  {
    label=i18n("configuration.task"),
    options={
      i18n("configuration.task_eeg"),
      i18n("configuration.task_standard")
    },
    selectFunc=function(v)
      local task
      if v == i18n("configuration.task_eeg") then
        task = "eegrecall"
      else
        task = "standardrecall"
      end
      local config = require ("tasks." .. task)
      intro.setTask(config)
    end
  },
  {
    label=i18n("configuration.handedness"),
    options={
      i18n("configuration.handedness_is_left"),
      i18n("configuration.handedness_is_not_left")
    },
    selectFunc=function(v)
      user.store("left handed",v==i18n("handedness_is_left"))
    end
  }
}

function scene:create()
  local y=20
  local button
  local optionSelected = _.rep(false,#options)

  local scroll = widget.newScrollView({
    top = 0,
    left = 0,
    width = display.contentWidth,
    height = display.contentHeight,
    horizontalScrollDisabled = true,
    verticalScrollDisabled = false,
    hideBackground = true
  })

  self.view:insert(scroll)

  for i=1,#options do
    local opt=options[i]
    local t=display.newText({
      text=opt.label,
      fontSize=34
    })
    scroll:insert(t)
    t.x=display.contentCenterX
    t.y=y
    y=y+t.height
    y=y+20

    local optWidth=(display.contentWidth*3/4-(20*#opt.options))/#opt.options
    local bgs={}
    for k=1,#opt.options do
      local bg=display.newRect(
        display.contentWidth/8+optWidth/2+(optWidth+20)*(k-1),
        y,
        optWidth,
        50)
      scroll:insert(bg)
      bg:setFillColor(83/255, 148/255, 250/255)
      if k==opt.default then
        bg.strokeWidth=8
      end
      bgs[k]=bg

      local label = display.newText({
        text=opt.options[k],
        fontSize=20
      })
      label:translate(bg.x, bg.y)
      scroll:insert(label)

      bg:addEventListener("tap", function()
        for i=1,#bgs do
          bgs[i].strokeWidth=0
        end
        optionSelected[i] = true
        button.isVisible=_.all(optionSelected, function(_k,v) return v end)
        opt.selectFunc(opt.options[k])
        bg.strokeWidth=8
      end)
    end
    y=y+70
  end

  button=display.newGroup()
  button.isVisible=false
  scroll:insert(button)
  local bg=display.newRect(button,display.contentCenterX,y,display.contentWidth/8,50)
  bg:setFillColor(83/255, 148/255, 250/255)

  display.newText({
    parent=button,
    text=i18n("buttons.done"),
    fontSize=20
  }):translate(bg.x, bg.y)
  bg:addEventListener("tap", function()
    composer.gotoScene("scenes.selectpreferred")
  end)

  scroll:setIsLocked(bg.contentBounds.yMax < display.contentHeight,"vertical")
end
scene:addEventListener("create")

function scene:show(event)
  if event.phase=="did" then
    return
  end
end
scene:addEventListener('show')

return scene