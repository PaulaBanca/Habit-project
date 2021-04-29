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
  local noReward=daycounter.getPracticeDay()>20
  local order=_.shuffle({1,2})
  for i=1, #order do
    local track=order[i]
    local img=stimuli.getStimulus(track)
    scene.view:insert(img)
    img.x=display.contentCenterX-(img.contentWidth/2)*(i*2-3)
    img.y=display.contentCenterY
    img:scale(0.5,0.5)
    local practice=practicelogger.getPractices(track)
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
        rewardType=noReward and "none" or
            ((track+self.modeSelect)%2+1==1 and "timed" or "random"),
        isScheduledPractice=true,
        practice=practice,
        mode="practice",
        iterations=self.iterations}
      })
    end
    img:addEventListener("tap")
    local text=display.newText({
      text=i18n("practice_select.practice_count",{count = practice}),
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