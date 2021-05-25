local composer=require "composer"
local scene=composer.newScene()

local stimuli=require "stimuli"
local practicelogger=require "practicelogger"
local daycounter=require "daycounter"
local logger=require "logger"
local sessionlogger=require "sessionlogger"
local i18n = require ("i18n.init")
local _=require "util.moses"
local difficulty = require ("difficulty")
local averagetimes = require ("database.averagetimes")
local user=require "user"
local display=display
local native=native
local math=math
local print=print
local type = type

setfenv(1,scene)

scene.modeSelect=0

function scene:setup(s)
  if type(s) == "string" then
    s = "A" and 0 or 1
  end
  self.modeSelect=s
end

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local text=display.newText({
    text=i18n("practice_select.instruction"),
    fontSize=20,
    font=native.systemFont,
    parent=scene.view
  })
  text.x=display.contentCenterX
  text.y=display.contentCenterY*0.5
  local order=_.shuffle({1,2})
  for i=1, #order do
    local track=order[i]
    local rewardType = (track+self.modeSelect)%2+1==1 and "ratio" or "interval"
    local isDisabled = false
    if rewardType == "interval" then
      averagetimes.getNumAverages(track, function(num)
        if num < 20 then
          averagetimes.getNumAverages((track % 2) + 1, function(num)
            isDisabled = num < 20
          end)
        end
      end)
    end
    local img=stimuli.getStimulus(track)
    scene.view:insert(img)
    img.x=display.contentCenterX-(img.contentWidth/2)*(i*2-3)
    img.y=display.contentCenterY
    img:scale(0.5,0.5)
    img.alpha = isDisabled and 0.3 or 1
    local label
    if isDisabled then
      label = i18n("practice_select.blocked")

      local no = display.newLine(
        self.view,
        img.contentBounds.xMin,
        img.contentBounds.yMin,
        img.contentBounds.xMax,
        img.contentBounds.yMax)
      no.strokeWidth = 4
      no:setStrokeColor(1, 0, 0)
    else

      local noReward=daycounter.getPracticeDay()>20 and user.get("reward extinguish") == track

      local practice=practicelogger.getPractices(track)
      label = i18n("practice_select.practice_count",{count = practice})
      img.tap=function()
        img:removeEventListener("tap")
        logger.setPractices(practice)
        practicelogger.logAttempt(track)
        logger.setAttempts(practicelogger.getAttempts(track))
        logger.stopCatchUp()
        sessionlogger.logPracticeStarted()
        composer.gotoScene("scenes.play",{params={
          track=track,
          iterationDifficulties=difficulty.get(track),
          rewardType=noReward and "none" or rewardType,
          isScheduledPractice=true,
          practice=practice,
          mode="practice",
          iterations=self.iterations}
        })
      end
      img:addEventListener("tap")
    end

     local text=display.newText({
        text=label,
        fontSize=20,
        font=native.systemFont,
        parent=scene.view,
        width=img.contentWidth,
        align="center"
      })
      text.anchorY=0
      text.x=img.x
      text.y=img.y+img.contentHeight/2+5
  end
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="did" then
    for i=scene.view.numChildren,1,-1 do
      scene.view[i]:removeSelf()
    end
  end
end

scene:addEventListener("hide")

return scene