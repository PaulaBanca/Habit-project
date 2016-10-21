local composer=require "composer"
local scene=composer.newScene()

local stimuli=require "stimuli"
local practicelogger=require "practicelogger"
local daycounter=require "daycounter"
local logger=require "logger"
local display=display
local native=native
local math=math
local print=print

setfenv(1,scene)

scene.modeSelect=0

function scene:setup(s)
  self.modeSelect=s
end

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local text=display.newText({
    text="Pick a melody to practice",
    fontSize=20,
    font=native.systemFont,
    parent=scene.view
  })
  text.x=display.contentCenterX
  text.y=display.contentCenterY*0.5
  local noReward=daycounter.getPracticeDay()>20
  for i=1, 2 do
    local img=stimuli.getStimulus(i)
    scene.view:insert(img)
    img.x=display.contentCenterX-(img.contentWidth/2)*(i*2-3)
    img.y=display.contentCenterY
    img:scale(0.5,0.5)
    local track=i
    local practice=practicelogger.getPractices(i)
    img.tap=function() 
      img:removeEventListener("tap")
      logger.setPractices(practice)
      practicelogger.logAttempt(track)
      logger.setAttempts(practicelogger.getAttempts(track))
      composer.gotoScene("scenes.play",{params={
        track=track,
        difficulty=math.ceil(practice/3),
        rewardType=noReward and "none" or 
            ((i+self.modeSelect)%2+1==1 and "timed" or "random"),
        isScheduledPractice=true,
        iterations=self.iterations}
      })
    end
    img:addEventListener("tap")
    local text=display.newText({
      text="Practiced\n" ..practice .. " " .. (practice~=1 and "times" or "time"),
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