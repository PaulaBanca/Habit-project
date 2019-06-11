local M = {}
standardrecall = M

local i18n = require ("i18n.init")
local phasemanager=require "phasemanager"
local events=require "events"
local setmetatable=setmetatable
local rawget=rawget
local display = display

local FLAGS=FLAGS

setfenv(1, M)

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
    {track=1,phase='A',allowSkipForwards=true},
    {track=1,phase='B',allowSkipForwards=true},
    {track=1,phase='B2',allowSkipForwards=true},
    {track=1,phase='C',allowSkipForwards=true},
    {track=2,phase='A',allowSkipForwards=true},
    {track=2,phase='B',allowSkipForwards=true},
    {track=2,phase='B2',allowSkipForwards=true},
    {track=2,phase='C',allowSkipForwards=true},
    {track=6,phase='C2',allowSkipForwards=true},
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
    y=5,
    width=display.contentWidth*7/8,
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
    text=i18n("instructions.phase_a"),
    y=5,
    width=display.contentWidth*7/8,
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
      phase="A1",
      nextScene="scenes.intro",
      noSwitch=true,
      allowRestarts=true,
      rounds=1,
      iterations=FLAGS.QUICK_ROUNDS and 1
    },getTrackMT)
  },
  -- PHASE B
  {
    phase='B',
    text=i18n("instructions.phase_b"),
    y=display.contentCenterY-40,
    scene="scenes.play",
    params=setmetatable({
      requireStartButton=true,
      feedback = true,
      phase="B1",
      nextScene="scenes.intro",
      noSwitch=true,
      rounds=1,
      iterations=FLAGS.QUICK_ROUNDS and 4 or 7
    },getTrackMT)
  },
  {
    phase='B2',
    scene="scenes.play",
    seamless=true,
    params=setmetatable({
      requireStartButton=true,
      feedback = true,
      phase="B2",
      nextScene="scenes.intro",
      noSwitch=true,
      rounds=1,
      iterations=FLAGS.QUICK_ROUNDS and 1 or 7
    },getTrackMT)
  },
  -- PHASE C
  {

    phase='C',
    text=i18n("instructions.phase_c"),
    y=5,
    width=display.contentWidth*7/8,
    fontSize=10,
    scene="scenes.play",
    params=setmetatable({
      phase="C1",
      requireStartButton=true,
      nextScene="scenes.intro",
      noSwitch=true,
      rounds=1,
      iterations=FLAGS.QUICK_ROUNDS and 1 or 15
    },getTrackMT)
  },
  {

    phase='C2',
    text=i18n("instructions.phase_c2"),
    y=5,
    width=display.contentWidth*7/8,
    fontSize=15,
    scene="scenes.play",
    img=function()
      local icon=phasemanager.getCurrentStimulus()
      if icon.contentHeight>display.contentHeight*3/4 then
        local scale=icon.contentHeight/display.contentHeight*3/4
        icon:scale(scale,scale)
      end
      return icon
    end,
    params=setmetatable({
      phase="C2",
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
    y=5,
    width=display.contentWidth*7/8,
    fontSize=15,
    noButton=true
  },
}

return M