local M={}
deadmansswitch=M

local i18n = require ("i18n.init")
local display=display
local next=next
local assert=assert
local system=system

setfenv(1,M)

local instructionGroup
function start(startFunc,noTouchesFunc)
  assert(not instructionGroup,"deadmansswitch: group not null")

  instructionGroup=display.newGroup()
  if system.getInfo("environment")=="simulator" then
    function instructionGroup:finalize(event)
      instructionGroup=nil
    end
    instructionGroup:addEventListener("finalize")

    return display.newGroup(),instructionGroup
  end
  instructionGroup.isHitTestable=true
  local instruction=display.newText({
    parent=instructionGroup,
    text=i18n("deadmans_switch.warning"),
    width=display.actualContentWidth-40,
    align="center",
    fontSize=24
  })
  instruction:setFillColor(1)
  local bg=display.newRect(instructionGroup, 0, 0, instruction.width+40,instruction.height+40)
  bg:toBack()
  bg:setFillColor(0, 0.6)

  local hitSensor=display.newRect(
    display.contentCenterX,
    display.contentCenterY,
    display.actualContentWidth,
    display.actualContentHeight)
  hitSensor.isHitTestable=true
  hitSensor.isVisible=false

  instructionGroup:translate(display.contentCenterX, display.contentCenterY)
  local restingTouches={}
  local listener=function(event)
    if event.phase=="began" then
      local first=next(restingTouches)==nil
      if not first then
        return false
      end
      restingTouches[event.id]=true
      startFunc()
      display.getCurrentStage():setFocus(hitSensor,event.id)
      instructionGroup.isVisible=false
      return true
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
  function instructionGroup:finalize(event)
    display.remove(hitSensor)
    instructionGroup=nil
  end
  instructionGroup:addEventListener("finalize")
  return hitSensor,instructionGroup
end

function stop()
  if not instructionGroup then
    return
  end
  instructionGroup:removeSelf()
  instructionGroup=nil
end

return M