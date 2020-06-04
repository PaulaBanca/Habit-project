local M = {}
eegrecall = M

local i18n = require ("i18n.init")
local phasemanager=require "phasemanager"
local events=require "events"
local _ = require ("util.moses")
local setmetatable=setmetatable
local rawget=rawget
local display = display

local FLAGS=FLAGS

setfenv(1, M)

local safeWidth
do
  local _, leftInset, _, rightInset = display.getSafeAreaInsets()
  safeWidth = display.actualContentWidth - ( leftInset + rightInset )
end

local skipSteps = _({
  2,
  3,
  4
}):shuffle():value()

local getTrackMT={
  __index=function(t,k)
    if k=="track" then
      return phasemanager.getCurrentTrack()
    end
    return rawget(t, k)
  end
}

function init()
  phasemanager.setPhases({
    {phase='Intro'},
    {track=1,phase='A'},
    {track=1,phase='B1'},
    {track=1,phase='B2'},
    {track=1,phase='B3'},
    {track=1,phase='C'},
    {track=2,phase='A'},
    {track=2,phase='B1'},
    {track=2,phase='B2'},
    {track=2,phase='B3'},
    {track=2,phase='C'},
    {phase='Outro'},
  })
end

task = {
  {
    phase='Intro',
    text=i18n("instructions.welcome"),
    y=display.contentCenterY-40,
    onComplete=function()
      events.fire({type='phase finished'})
    end
  },
  {
    phase='A',
    text=i18n("instructions.pattern"),
    y=20,
    width=safeWidth-20,
    fontSize=15,
    img=function()
      local icon=phasemanager.getCurrentStimulus()
      if icon.contentHeight>display.contentHeight*3/4 then
        local scale=icon.contentHeight/display.contentHeight*3/4
        icon:scale(scale,scale)
      end
      return icon
    end,
  },
  {
    phase='A',
    text=i18n("eeg.phase_a"),
    y=20,
    width=safeWidth-20,
    fontSize=15,
    img=function()
      local icon=phasemanager.getCurrentStimulus()
      if icon.contentHeight>display.contentHeight*3/4 then
        local scale=icon.contentHeight/display.contentHeight*3/4
        icon:scale(scale,scale)
      end
      return icon
    end,
    scene="scenes.play",
    params=setmetatable({
      requireStartButton=true,
      phase="A",
      nextScene="scenes.intro",
      noSwitch=true,
      restartOnMistakes=true,
      showHints=true,
      rounds=1,
      iterations=FLAGS.QUICK_ROUNDS and 1 or 15
    },getTrackMT)
  },
  -- PHASE B
  {
    phase='B1',
    text=i18n("eeg.phase_b"),
    y=20,
  },
  {
    phase='B1',
    text=i18n("eeg.skip", {step = skipSteps[1]}),
    y=display.contentCenterY-40,
    scene="scenes.play",
    params=setmetatable({
      requireStartButton=true,
      phase="B1",
      nextScene="scenes.intro",
      skip = skipSteps[1],
      noSwitch=true,
      rounds=1,
      iterations=FLAGS.QUICK_ROUNDS and 4 or 20
    },getTrackMT)
  },
  {
    phase='B2',
    text=i18n("eeg.skip", {step = skipSteps[2]}),
    y=display.contentCenterY-40,
    scene="scenes.play",
    params=setmetatable({
      requireStartButton=true,
      phase="B2",
      nextScene="scenes.intro",
      skip = skipSteps[2],
      noSwitch=true,
      rounds=1,
      iterations=FLAGS.QUICK_ROUNDS and 4 or 20
    },getTrackMT)
  },
  -- PHASE B
  {
    phase='B3',
    text=i18n("eeg.skip", {step = skipSteps[3]}),
    y=display.contentCenterY-40,
    scene="scenes.play",
    params=setmetatable({
      requireStartButton=true,
      phase="B3",
      nextScene="scenes.intro",
      skip = skipSteps[3],
      noSwitch=true,
      rounds=1,
      iterations=FLAGS.QUICK_ROUNDS and 4 or 20
    },getTrackMT)
  },
  -- PHASE C
  {

    phase='C',
    text=i18n("eeg.phase_c"),
    y=20,
    width=safeWidth-20,
    fontSize=10,
    scene="scenes.play",
    params=setmetatable({
      phase="C",
      requireStartButton=true,
      nextScene="scenes.intro",
      noSwitch=true,
      rounds=1,
      iterations=FLAGS.QUICK_ROUNDS and 1 or 15
    },getTrackMT)
  },
  {

    phase='Outro',
    text=i18n("instructions.completed"),
    y=20,
    width=safeWidth-20,
    fontSize=15,
    noButton=true
  },
}

return M


