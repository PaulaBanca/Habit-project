local M={}
seed=M

local jsonreader=require "jsonreader"
local user=require "user"
local tonumber=tonumber
local display=display
local native=native
local print=print
local math=math
local tonumber=tonumber

setfenv(1,M)

function setup(whenDone)
  if false and user.get("seed") then
    math.randomseed(user.get("seed"))
    return whenDone()
  end

  local instruction=display.newText({
    text="Enter the Seed",
    fontSize=48,
  })
  instruction:translate(display.contentCenterX, display.contentCenterY-100)

  local textField
  local function textListener(event)
    if event.phase == "submitted" then
      local text=textField.text
      local function onComplete( event )
        if event.action == "clicked" then
          local i = event.index
          if i == 1 then
            return setup(whenDone,force)
          elseif i == 2 then
            user.store("seed",tonumber(text))
            math.randomseed(user.get("seed"))
            whenDone(true)
          end
        end
      end

      -- Show alert with two buttons
      local alert = native.showAlert("Confirm", "Set User Seed to " .. text .. ". This controlls the symbols and melodies the user will see", { "Cancel", "Okay" }, onComplete )

      instruction:removeSelf()
      textField:removeSelf()
    end
  end

  textField = native.newTextField(display.contentCenterX, display.contentCenterY-40, display.contentWidth-20, 50)
  textField:addEventListener("userInput", textListener)
end

return M