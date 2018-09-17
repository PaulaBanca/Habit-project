local composer=require "composer"
local scene=composer.newScene()

local _=require "util.moses"

local display=display
local transition=transition
local easing=easing
local table=table
local os=os
local system=system
local logger=require "logger"

setfenv(1,scene)

local function logFeedbackPattern(pattern)
  logger.setFeedbackPattern(table.concat(pattern, ""))
  local feedbackRow=logger.createLoggingTable()
  feedbackRow.time=os.date("%T")
  feedbackRow.date=os.date("%F")
  feedbackRow.appMillis=system.getTimer()
  logger.log("touch",feedbackRow)
  logger.setFeedbackPattern('n/a')
end

function scene:show(event)
  if event.phase=='did' then
    return
  end

  local feedback=event.params.feedback

  local bg=display.newRect(
    self.view,
    display.contentCenterX,
    display.contentCenterY,
    display.contentWidth,
    display.contentHeight)
  bg:setFillColor(0)

  bg:addEventListener('tap', function() return true end)

  bg:addEventListener('touch', function()
    return true
  end)

  local padding=40
  local cellWidth=(display.contentWidth-padding*2)/#feedback

  local group=display.newGroup()
  self.view:insert(group)
  local feedbackPattern={}
  for i=1,#feedback do
    local keys=feedback[i]
    local img
    if _.include(keys,false) or not _.include(keys,true) then
      img=display.newImage(group,'img/wrongpress.png')
      feedbackPattern[i]='0'
    else
      img=display.newImage(group,'img/correct.png')
      feedbackPattern[i]='1'
    end
    local scale=cellWidth/img.width
    img:scale(scale,scale)
    img.x=padding+i*cellWidth-cellWidth/2
    img.y=display.contentCenterY
  end

  group.y=display.viewableContentHeight
    transition.to(group,{
      transition=easing.outQuart,
      y=0,
      onComplete=function()
        logFeedbackPattern(feedbackPattern)
        transition.to(group,{
          delay=1000,
          transition=easing.inQuart,
          y=-group.y-display.viewableContentHeight,
          onComplete=function()
           event.params.onComplete()
           composer.hideOverlay()
          end
        })
    end
  })
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