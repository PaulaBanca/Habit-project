local composer=require "composer"
local scene=composer.newScene()

local stimuli=require "stimuli"
local bubblechoice=require "ui.bubblechoice"
local logger=require "logger"
local incompletetasks=require "incompletetasks"
local practicelogger=require "practicelogger"
local daycounter=require "daycounter"
local user=require "user"
local i18n = require ("i18n.init")
local display=display
local os=os
local math=math
-- luacheck: ignore serpent
local serpent=require "serpent"
-- luacheck: ignore print
local print=print

setfenv(1, scene)

local PADDING=20

function markQuestionnaireCompleted(track, day)
  local completedQuestionnaires=user.get("quizzed") or {}
  completedQuestionnaires[day]=completedQuestionnaires[day] or {}
  completedQuestionnaires[day][track]=true
  user.store("quizzed",completedQuestionnaires)
end

function playSwitchTest(day)
  local practiced=daycounter.getPracticed(day)
  local completedQuestionnaires=user.get("quizzed") or {}
  for i=1,2 do
    if not completedQuestionnaires[day][i] or not practiced[i] or practiced[i]<2 then
      return false
    end
  end
  return true
end

function logData(data, track, practice, value)
  local key = "confidence_melody_" .. track
  data[key] = value
  data["date"]=os.date("%F")
  data["time"]=os.date("%T")
  data["practice"]=practice
  data["track"]=track
  logger.log("questionnaire",data)
end


function gotoNextScene(track,day,resumed)
  if resumed then
    incompletetasks.lastCompleted()
  else
    incompletetasks.removeLast("scenes.pleasure")
  end

  local difficulty=math.ceil(practicelogger.getPractices(track)/3)
  logger.stopCatchUp()
  local scene,params="scenes.message",{
    text=i18n("confidence.instruction"),
    nextScene="scenes.play",
    nextParams={
      nextScene="scenes.schedule",
      track=track,
      iterations=5,
      rounds=1,
      difficulty=difficulty,
      mode="timed",
      noQuit=true,
    }
  }
  incompletetasks.push(scene,params)

  if playSwitchTest(day) then
    local scene,params="scenes.message",{
      text=i18n("switch.instruction"),
      nextScene="scenes.play",
      nextParams={
        nextScene="scenes.schedule",
        track="random",
        iterations=10,
        rounds=1,
        difficulty=difficulty,
        mode="switch",
        noQuit=true,
      }
    }
    incompletetasks.push(scene,params)
  end

  incompletetasks.getNext()
end

function scene:purge()
  for i=self.view.numChildren,1,-1 do
    self.view[i]:removeSelf()
  end
end

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local width=display.contentWidth-80

  local data=event.params.data
  local bubbles = bubblechoice.create({
    width = width,
    labels = {
      i18n("confidence.label_no_confidence"),
      i18n("confidence.label_not_confident"),
      i18n("confidence.label_some_confidence"),
      i18n("confidence.label_confident"),
    },
    labelTextColour = {1},
    labelColour = {0.5},
    lineStrokeWidth = 6,
    labelStrokeColour = {0.3},
    labelSize = width /4 * 0.8,
    labelFontSize = 15,
    labelStrokeWidth = 6
  }, function(i)
    local track=event.params.track
    local v = i / 4

    logData(data, track, event.params.practice, v)

    local day = event.params.practiceDay
    markQuestionnaireCompleted(track,day)
    self:purge()
    gotoNextScene(track,day,event.params.resumed)
  end)

  self.view:insert(bubbles)

  local query=display.newText({
    text=i18n("confidence.question"),
    fontSize=20,
    width=display.contentWidth*3/4,
    align="center"
  })
  query.anchorY=1
  query:translate(display.contentCenterX, display.contentCenterY-PADDING)
  scene.view:insert(query)
  bubbles:translate(display.contentCenterX, query.contentBounds.yMax + bubbles.height/2 + PADDING)

  local img=stimuli.getStimulus(event.params.track)
  scene.view:insert(img)
  img.anchorY=1
  img.x=display.contentCenterX
  img.y=query.y-query.contentHeight
  local scale=img.y/img.height
  img:scale(scale,scale)
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    return
  end
 self:purge()
end
scene:addEventListener("hide")

return scene