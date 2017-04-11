local M={}
seed=M

local tonumber=tonumber
local display=display
local native=native
local print=print
local math=math
local tonumber=tonumber

setfenv(1,M)

function setup(whenDone)
  local instruction=display.newText({
    text="Enter the Seed",
    fontSize=48,
  })
  instruction:translate(display.contentCenterX, display.contentCenterY-100)
  instruction:setFillColor(0)

  local textField
  local bg
  local function textListener(event)
    if event.phase == "submitted" then
      local text=textField.text

      if not tonumber(text) then
        local function onComplete( event )
          if event.action == "clicked" then
            return setup(whenDone,force)
          end
        end
        local alert = native.showAlert("Invalid Seed", text .. " is not a number", {"Okay" }, onComplete)
      else       

        local function onComplete( event )
          if event.action == "clicked" then
            local i = event.index
            if i == 1 then
              return setup(whenDone,force)
            elseif i == 2 then
              math.randomseed(tonumber(text))
              whenDone()
            end
          end
        end

        local alert = native.showAlert("Confirm", "Set User Seed to " .. text .. ". This controlls the symbols and melodies the user will see", { "Cancel", "Okay" }, onComplete)
      end
      bg:removeSelf()
      instruction:removeSelf()
      textField:removeSelf()
    end
  end

  textField = native.newTextField(display.contentCenterX, display.contentCenterY-40, display.contentWidth-20, 50)
  textField:addEventListener("userInput", textListener)
  textField.inputType="number"
  bg=display.newRect(textField.x, textField.y, textField.width+8, textField.height+8)
  bg:setFillColor(0)
end

return M