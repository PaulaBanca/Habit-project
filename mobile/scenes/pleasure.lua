local composer=require "composer"
local scene=composer.newScene()

local stimuli=require "stimuli"
local bubblechoice=require "ui.bubblechoice"
local display=display

setfenv(1, scene)

local PADDING=20

function logData(data, track, value)
    local key="pleasure_melody_" .. track
    data[key]=value
end

function scene:purge()
  for i=self.view.numChildren,1,-1 do
    self.view[i]:removeSelf()
  end
end

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local width=display.contentWidth-80

  local data = event.params.data or {}
  local bubbles = bubblechoice.create({
    width = width,
    labels = {
      "not enjoyable at all",
      "not very enjoyable",
      "fairly enjoyable",
      "very enjoyable"
    },
    labelTextColour = {1},
    labelColour = {0.5},
    lineStrokeWidth = 6,
    labelStrokeColour = {0.3},
    labelSize = width /4 * 0.8,
    labelFontSize = 15,
    labelStrokeWidth = 6
  }, function(i)
    local track=event.params.track
    local v = i / 4

    logData(data, track, v)

    self:purge()
    composer.gotoScene("scenes.confidence",{
      params={
        data=data,
        resumed=event.params.resumed,
        practice=event.params.practice,
        track=event.params.track,
        practiceDay=event.params.practiceDay
      }
    })
  end)
  self.view:insert(bubbles)

  local query=display.newText({
    text="How much did you enjoy playing this sequence?",
    fontSize=20,
    width=display.contentWidth/2,
    align="center"
  })
  query.anchorY=1
  query:translate(display.contentCenterX, display.contentCenterY-PADDING)
  scene.view:insert(query)
  bubbles:translate(display.contentCenterX, query.contentBounds.yMax + bubbles.height/2 + PADDING)


  local img=stimuli.getStimulus(event.params.track)
  scene.view:insert(img)
  img.anchorY=1
  img.x=display.contentCenterX
  img.y=query.y-query.contentHeight
  local scale=img.y/img.height
  img:scale(scale,scale)
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    return
  end
  self:purge()
end
scene:addEventListener("hide")

return scene