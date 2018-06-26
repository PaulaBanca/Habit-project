local composer=require "composer"
local scene=composer.newScene()

local progress=require "ui.progress"
local _=require "util.moses"

local display=display
local transition=transition
local easing=easing
local table=table
local NUM_KEYS=NUM_KEYS

setfenv(1,scene)

function scene:show(event)
  if event.phase=='did' then
    return
  end

  local feedback=event.params.feedback

  local temp=display.newImage('img/pad.png')
  local keyWidth=temp.width
  local keyHeight=temp.height
  temp:removeSelf()
  local width=keyWidth*NUM_KEYS
  local keyScale=1
  if width>display.viewableContentWidth then
    local idealWidth=display.viewableContentWidth/NUM_KEYS
    keyScale=idealWidth/keyWidth
    keyWidth=idealWidth
    keyHeight=keyHeight*keyScale
    width=idealWidth*NUM_KEYS
  end

  local bg=display.newRect(
    self.view,
    display.contentCenterX,
    display.contentCenterY,
    display.contentWidth,
    display.contentHeight)
  bg:setFillColor(0)

  bg:addEventListener('tap', function() return true end)

  local barWidth=150
  local barHeight=40

  local prog=progress.create(barWidth,barHeight,{6})
  local x,y=display.contentCenterX,13
  prog:translate(x, y+barHeight/2)
  self.view:insert(prog)
  local step=0
  local function nextKeys()
    local keys=table.remove(feedback, 1)
    if not keys then
      event.params.onComplete()
      return composer.hideOverlay()
    end

    step=step+1
    local group=display.newGroup()
    self.view:insert(group)
    for i=1, NUM_KEYS do
      local x=i*width/NUM_KEYS-width/2-keyWidth/2+display.contentCenterX
      local key=display.newImage(group,'img/pad.png')
      key:scale(keyScale,keyScale)
      key:translate(x, display.contentCenterY)
      prog:mark(step,true)
      key.alpha=(keys[i]==false) and 1 or 0.4
      if keys[i]==false then
        display.newImage(group,'img/wrongpress.png',x,display.contentCenterY)
      end
    end

    if _.include(keys,true) then
      local ratio=_.count(keys,true)/_.count(keys)
      local tickGroup=display.newGroup()
      local back=display.newImage(
        tickGroup,
        'img/correct.png')
      back.alpha=0.5
      local container=display.newContainer(tickGroup, back.width, back.height*ratio)
      container.anchorY=1
      container:translate(0,back.y+back.height/2)
      display.newImage(
        container,
        'img/correct.png',
        container:contentToLocal(
          0,
          0)
        )
      if ratio<1 then
        local tickBg=display.newRoundedRect(
          tickGroup,
          0,
          0,
          back.width+20,
          back.height+20,
          20)
        container:toFront()
        tickBg:setFillColor(0,0.7)
        tickBg.strokeWidth=8
        tickGroup:translate(display.contentCenterX,display.viewableContentHeight+tickGroup.height/2)
        transition.to(tickGroup,{
          y=display.contentCenterY,
          delay=500,
          onComplete=function()
            transition.to(tickGroup,{
              delay=500,
              y=-tickGroup.height,
              onComplete=display.remove
            })
          end})
      else
        group:insert(tickGroup)
        tickGroup:translate(display.contentCenterX,display.contentCenterY)
      end
    end

    group.y=display.viewableContentHeight
    transition.to(group,{
      transition=easing.outQuart,
      y=0,
      onComplete=function()
        transition.to(group,{
          delay=1000,
          transition=easing.inQuart,
          y=-group.y-display.viewableContentHeight/2,
          onComplete=function()
            display.remove(group)
            nextKeys()
          end
        })
      end
    })
 end

  nextKeys()
end
scene:addEventListener('show')

function scene:hide(event)
  if event.phase=='will' then
    return
  end

  for i=self.view.numChildren,-1 do
    self.view[i]:removeSelf()
  end
end
scene:addEventListener('hide')

return scene