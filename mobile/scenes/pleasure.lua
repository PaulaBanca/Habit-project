local composer=require "composer"
local scene=composer.newScene()

local stimuli=require "stimuli"
local button=require "ui.button"
local logger=require "logger"
local display=display
local math=math    

setfenv(1, scene)

local LABELWIDTH=display.contentWidth/8
local PADDING=20

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local width=display.contentWidth-80
  local scaleWidth=width-PADDING*2-LABELWIDTH*2

  local touchArea=display.newRect(display.contentCenterX,display.contentCenterY,scaleWidth,PADDING*2)
  scene.view:insert(touchArea)

  local line=display.newLine(display.contentCenterX-scaleWidth/2,display.contentCenterY,display.contentCenterX+scaleWidth/2,display.contentCenterY)
  line:setStrokeColor(0)
  line.strokeWidth=2
  scene.view:insert(line)

  local labelLeft=display.newText({
    text="Very boring",
    fontSize=15,
    width=LABELWIDTH,
    align="right"
  })
  labelLeft.anchorX=1
  labelLeft:translate(display.contentCenterX-scaleWidth/2-PADDING/2, display.contentCenterY)
  scene.view:insert(labelLeft)

  local labelRight=display.newText({
    text="Very pleasurable",
    fontSize=15,
    width=LABELWIDTH,
    align="left"
  })
  labelRight.anchorX=0
  labelRight:translate(display.contentCenterX+scaleWidth/2+PADDING/2, display.contentCenterY)
  scene.view:insert(labelRight)

  local done
  local sensor
  local numTouches=0
  function touchArea:tap(event)
    if sensor then
      sensor:removeSelf()
    end

    sensor=display.newGroup()
    scene.view:insert(sensor)
    local touchSensor=display.newCircle(sensor,0, 0, PADDING*2)
    touchSensor.isHitTestable=true
    touchSensor.isVisible=false
    local dial=display.newCircle(sensor,0, 0, PADDING/2)
    dial:setStrokeColor(0)
    dial.strokeWidth=4
    dial:setFillColor(0,1,0)
    done.isVisible=true
    local x=scene.view:contentToLocal(event.x,0)
    sensor:translate(x,self.y)

    numTouches=numTouches+1
    function sensor:writeValue()
      -- local v=values[i]
      -- v.value=math.abs((touchArea.x-touchArea.width/2-self.x)*100/touchArea.width)
      -- v.startTime=v.startTime or system.getTimer()-vasStart
      -- v.endTime=system.getTimer()-vasStart
      -- v.touches=numTouches
      -- v.minValue=v.minValue and math.min(v.minValue,v.value) or v.value
      -- v.maxValue=v.maxValue and math.max(v.maxValue,v.value) or v.value
    end
    sensor:writeValue()

    local lx=0
    function touchSensor:touch(event)
      if event.phase=="began" then
        lx=event.x
        display.getCurrentStage():setFocus(self)
        numTouches=numTouches+1
        return true
      end
      if event.phase=="ended" or event.phase=="cancelled" then
        display.getCurrentStage():setFocus(nil)
      end

      if event.phase=="moved" then
        sensor.x=sensor.x+event.x-lx
        lx=event.x
        sensor.x=math.max(sensor.x,touchArea.x-touchArea.width/2)
        sensor.x=math.min(sensor.x,touchArea.x+touchArea.width/2)
        sensor:writeValue()
        return true
      end
    end
    touchSensor:addEventListener("touch")
  end

  touchArea:addEventListener("tap")
  done=button.create("Done","change",function()
    local data=event.params.data or {}
    data["pleasure_melody_" .. event.params.melody]=math.abs((touchArea.x-touchArea.width/2-sensor.x)*100/touchArea.width)
    sensor:removeSelf()
    sensor=nil

    for i=self.view.numChildren,1,-1 do
      self.view[i]:removeSelf()
    end
    composer.gotoScene("scenes.confidence",{params={melody=event.params.melody,rounds=event.params.rounds,data=data}})
  end)
  done.isVisible=false
  done.anchorChildren=true
  done.anchorY=1
  done:translate(display.contentCenterX, display.contentHeight*3/4)
  scene.view:insert(done)


  local query=display.newText({
    text="How much did you enjoy playing this sequence?",
    fontSize=20,
    width=display.contentWidth/2,
    align="center"
  })
  query.anchorY=1
  query:translate(display.contentCenterX, display.contentCenterY-touchArea.height/2-PADDING)
  scene.view:insert(query)

  local img=stimuli.getStimulus(event.params.melody)
  scene.view:insert(img)
  img.anchorY=1
  img.x=display.contentCenterX
  img.y=query.y-query.contentHeight
  local scale=img.y/img.height
  img:scale(scale,scale)
end

scene:addEventListener("show")

return scene