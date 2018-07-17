local M={}
seed=M

local jsonreader=require "jsonreader"
local user=require "user"
local stimuli=require "stimuli"
local tunes=require "tunes"
local button=require "ui.button"
local tonumber=tonumber
local display=display
local native=native
local print=print
local math=math
local tonumber=tonumber

setfenv(1,M)

local function configure()
  math.randomseed(user.get("seed"))
  stimuli.generateSeeds()
  tunes.generateTunes()
  tunes.extendTunes()
end

function setup(whenDone,forceEnter)
  if user.get("seed") and not forceEnter then
    configure()
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
            configure()

            local group=display.newGroup()
            for i=1, 3 do
              local s=stimuli.getStimulus(i)
              group:insert(s)
              s:scale(0.5,0.5)
              s.y=display.contentCenterY
              s.x=display.contentCenterX+(s.contentWidth+20)*(i-2)
            end

            local back,okay
            function close()
              group:removeSelf()
              back:removeSelf()
              okay:removeSelf()
            end
            back=button.create("Back","abort",function()
              close()
              setup(whenDone)
            end)
            okay=button.create("Okay","use",function()
              close()
              whenDone(true)
            end)
            back.y=group[1].y+group[1].contentHeight/2+20+back.height/2
            back.x=display.contentCenterX-back.width/2-20
            okay.y=back.y
            okay.x=display.contentCenterX+okay.width/2+20
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
  textField.inputType='UIKeyboardTypeNumbersAndPunctuation'
  textField.autocorrectionType='UITextAutocorrectionTypeNo'
  textField.spellCheckingType = "UITextSpellCheckingTypeNo"
end

return M