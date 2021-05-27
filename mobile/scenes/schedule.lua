local composer=require "composer"
local scene=composer.newScene()

local widget=require "widget"
local daycounter=require "daycounter"
local user=require "user"
local i18n = require ("i18n.init")
local display=display
local math=math
local print=print

setfenv(1,scene)

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local scroll=widget.newScrollView({
    width=display.contentWidth,
    height=70,
    verticalScrollDisabled=true,
    hideBackground=true
  })
  scroll:translate(0, display.contentCenterY-scroll.height/2)
  self.view:insert(scroll)

  local title=display.newText({
    parent=scene.view,
    x=display.contentCenterX,
    y=scroll.y-scroll.height/2-5,
    text=i18n("schedule.title"),
    align="center",
    fontSize=20
  })
  title.anchorY=1

  local seed=display.newText({
    parent=scene.view,
    x=10,
    y=10,
    text=user.get("seed"),
    align="right",
    fontSize=20
  })
  seed.anchorX=0
  seed.anchorY=0

  local dates=daycounter.getDayCount()
  local step=60
  local datePoints=math.max(dates+3+1,10)
  local line=display.newLine(0,scroll.height/2,(datePoints+1)*step,scroll.height/2)
  line.strokeWidth=2
  scroll:insert(line)
  line:setStrokeColor(0.6)
  local today=dates+1
  local practiceDate
  for i=1, datePoints do
    local x=i*step

    local c=display.newCircle(self.view,x,scroll.height/2, 16)
    scroll:insert(c)
    c.strokeWidth=2
    if i~=today then
      c:setFillColor(0.6, 0.2)
      c:setStrokeColor(0.6, 0.5)
      if i>today then
        c.alpha=2*(datePoints==10 and 1 or 0.3)/(i-today)
      end
      if i<today then
       c:setFillColor(230/255, 180/255, 41/255)
     end

    else
      c:setFillColor(0.6, 0.2)
      c:setStrokeColor(1)
      c.strokeWidth=4
    end

    local day=display.newText({
      x=c.x,
      y=c.y,
      text=(i~=today and i or i18n("schedule.today")),
      align="center",
      fontSize=i~=today and 20 or 10
    })
    day.alpha=c.alpha
    scroll:insert(day)

    if i==today then
      local t=display.newCircle(self.view,x,scroll.height/2, 30)
      scroll:insert(t)
      if not practiceDate then
        t:setFillColor(83/255, 148/255, 250/255)
        local day=i
        t:addEventListener("tap", function()
          daycounter.setPracticeDay(day)
          composer.gotoScene("scenes.select")
        end)
        t.strokeWidth=3
      else
        t:setFillColor(250/255, 41/255, 41/255)
      end
      if not practiceDate then
        practiceDate=i
      end
      t:toBack()
    end
  end
  scroll:scrollToPosition({x=practiceDate and (-practiceDate*step+scroll.width/2) or -scroll.width/2})

  if not practiceDate then
    local t=display.newText({
      parent=self.view,
      text=i18n("schedule.completed"),
      x=display.contentCenterX,
      y=display.contentCenterY,
      fontSize=64
    })
    local bg=display.newRect(self.view, t.x, t.y, t.width+20, t.height+20)
    t:toFront()
    bg:setFillColor(0,0.5,0.2, 0.8)
  end
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    return
  end
  for i=scene.view.numChildren, 1, -1 do
    scene.view[i]:removeSelf()
  end
end
scene:addEventListener("hide")

return scene