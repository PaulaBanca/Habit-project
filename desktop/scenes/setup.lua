local composer=require "composer"
local scene=composer.newScene()

local logger=require "util.logger"
local native=native
local display=display
local system=system

setfenv(1,scene)

function scene:show(event)
  if event.phase=="will" then
    return
  end

  if system.getInfo("environment")=="simulator" then
    logger.setUserID("test")
    composer.gotoScene("scenes.counterbalance")   
    return 
  end
  local userIDField
  local instruction
  local function textListener(event)
    if event.phase == "began" then
    elseif event.phase == "ended" or event.phase == "submitted" and event.target.text~="" then
      logger.setUserID(event.target.text)
      native.showAlert("Confirm", "Log data for User ID: "..(event.target.text or ""), {"Yes","No"},function(event)
        if event.action == "clicked" then
          if event.index==1 then
            userIDField:removeSelf()
            composer.gotoScene("scenes.counterbalance")
          end
        end
      end)
    elseif event.phase == "editing" then
      instruction.text="Press Enter to submit"
    end
  end

  -- Create text field
  userIDField = native.newTextField(display.contentCenterX, display.contentCenterY, 180, 80)

  userIDField:addEventListener("userInput", textListener)
  instruction=display.newText({
    parent=self.view,
    text="Enter User ID for logging:",
    fontSize=69,
    x=display.contentCenterX,
  })
  instruction.anchorY=1
  instruction.y=display.contentCenterY-40-20
  instruction:setFillColor(0)
  display.newRect(self.view,display.contentCenterX, display.contentCenterY, 184, 84 ):setFillColor(0)
end

scene:addEventListener("show")
return scene
