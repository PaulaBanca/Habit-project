local M={}
servertest=M

local logger=require "logger"
local unsent=require "database.unsent"
local timer=timer
local os=os
local system=system

setfenv(1,M)

function createTouches(num)
  for i=1, num do
    local v=i
    logger.setModesDropped(v)
    logger.setIterations(v)
    logger.setModeIndex(v)
    logger.setScore(v)
    logger.setBank(v)
    logger.setIntro(false)
    logger.setSequenceTime(v)
    logger.setPractices(v)
    logger.setTotalMistakes(v)
    logger.setTrack(v)
    logger.log({
      touchPhase="began",
      x=v,
      y=v,
      date=os.date("%F"),
      time=os.date("%T"),
      appMillis=system.getTimer(),
      delay=nil,
      wasCorrect=true,
      complete=false,
      instructionIndex=v,
      keyIndex=v})
  end
end

function createQuestionnaires(num)
  for i=1, num do
    local v=i
    logger.log({
      date=os.date("%F"),
      time=os.date("%T"),
      confidence_melody_1=v,
      confidence_melody_2=v,
      pleasure_melody_1=v,
      pleasure_melody_2=v,
    })
  end
end

function test(sendData,questionnaire)
  if sendData then
    logger.startCatchUp()
    return
  end
  if questionnaire then
    createQuestionnaires(60)
  else
    createTouches(60)
  end
end

return M


