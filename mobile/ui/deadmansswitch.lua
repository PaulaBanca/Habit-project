local M={}
deadmansswitch=M

local display=display
local next=next
local Runtime=Runtime
local assert=assert
local system=system

setfenv(1,M)

local instructionGroup
function start(noTouchesFunc)
  assert(not instructionGroup,"deadmansswitch: group not null")

  instructionGroup=display.newGroup()
  if system.getInfo("environment")=="simulator" then
    return
  end
  instructionGroup.isHitTestable=true
  local instruction=display.newText({
    parent=instructionGroup,
    text="Please keep a digit from your inactive hand touching the screen throughout the practice",
    width=display.actualContentWidth-40,
    align="center",
    fontSize=24
  })
  instruction:setFillColor(1)
  local bg=display.newRect(instructionGroup, 0, 0, instruction.width+40,instruction.height+40)
  bg:toBack()
  bg:setFillColor(0, 0.6)

  local hitSensor=display.newRect(instructionGroup,0,0,display.actualContentWidth,display.actualContentHeight)
  hitSensor.isHitTestable=true
  hitSensor.isVisible=false

  instructionGroup:translate(display.contentCenterX, display.contentCenterY)
  local restingTouches={}
  
  local listener=function(event)
    if event.phase=="began" then
      restingTouches[event.id]=true
      local first=instructionGroup.isVisible
      if first then 
        display.getCurrentStage():setFocus(hitSensor,event.id)
      end
      instructionGroup.isVisible=false
      return first
    end
    if event.phase=="cancelled" or event.phase=="ended" then
      restingTouches[event.id]=nil
      if not next(restingTouches) then
        instructionGroup.isVisible=true
        noTouchesFunc()
      end
    end
  end
  hitSensor:addEventListener("touch", listener)
end

function stop()
  instructionGroup:removeSelf()
  instructionGroup=nil
end

return M