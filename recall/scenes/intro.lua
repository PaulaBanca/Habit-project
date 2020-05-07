local composer=require "composer"
local scene=composer.newScene()

local phasemanager=require "phasemanager"
local events=require "events"
local _=require "util.moses"
local serpent=require "serpent"
local i18n = require ("i18n.init")
local display=display
local type=type
local math=math
local timer=timer

local print=print

setfenv(1,scene)

function scene:create()
  events.addEventListener('phase change',function()
    self.page=1
  end)
  self.page=1
end
scene:addEventListener('create')

local instructions
function setTask(_instructions)
  instructions = _instructions
end

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local phaseInstructions=_.select(instructions,function(_,v)
    return v.phase==phasemanager.getPhase()
  end)
  local step=phaseInstructions[self.page or 1]
  if not step then
    return
  end

  if step.onShow then
    step.onShow()
  end

  local function nextPage()
    self.page=self.page+1
    if step.onComplete then
      step.onComplete()
    end
    composer.gotoScene(step.scene and step.scene or "scenes.intro",{
      params=step.params
    })
  end
  if step.seamless then
    return timer.performWithDelay(1,nextPage)
  end

  local obj
  local y = step.y or display.contentWidth
  if step.text then
    obj=display.newText({
      parent=self.view,
      x=display.contentCenterX,
      y=y + 20,
      width=step.width or display.contentWidth/2,
      text=step.text,
      align="center",
      fontSize=step.fontSize or 20
    })
    obj.anchorY=0
    local bg=display.newRect(
      self.view,
      obj.x,
      obj.y+obj.height/2,
      display.contentWidth,
      obj.height+20
    )
    bg:setFillColor(0.2)
    obj:toFront()

    y = bg.contentBounds.yMax + 20
  end

  if step.img then
    local img
    if type(step.img)=='string' then
      img=display.newImage(self.view,step.img,display.contentCenterX,y)
    else
      img=step.img()
      self.view:insert(img)
      img:translate(
        obj.x or display.contentCenterX,
        y)
    end
    img.anchorY=0
    if img.width>display.actualContentWidth-40 then
      img.xScale=(display.actualContentWidth-40)/img.width
      img.yScale=img.xScale
    end
    if img.contentHeight+70>display.actualContentHeight then
      local scale=(display.actualContentHeight-70)/img.contentHeight
      img:scale(scale,scale)
    end
  end
  if obj and not step.noButton then
    local bottom=0
    for i=1, self.view.numChildren do
      bottom=math.max(self.view[i].contentBounds.yMax,bottom)
    end

    local bg=display.newRect(
      self.view,
      display.contentCenterX,
      bottom+20,
      100,
      30)
    bg:setFillColor(83/255, 148/255, 250/255)
    display.newText({
      parent=self.view,
      x=bg.x,
      y=bg.y,
      text=i18n("buttons.next"),
      align="center"
    })

    bg:addEventListener("tap", nextPage)
  end
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