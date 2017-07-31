local M={}
keyeventslisteners=M
local tunedetector=require "tunedetector"
local serpent=require "serpent"
local _=require "util.moses"
local logger=require "util.logger"
local NUM_KEYS=NUM_KEYS
local print=print
local pairs=pairs
local system=system
local os=os
local table=table
local assert=assert

setfenv(1,M)

function create(opts)
  local startTime=nil
  local wrapper=function(f,...)
    startTime=nil
    f(...)
  end
  local onTuneComplete=_.wrap(assert(opts.onTuneComplete),wrapper)
  local onMistake=_.wrap(assert(opts.onMistake),wrapper)
  local onGoodInput=assert(opts.onGoodInput,"missing onGoodInput listener")
  local getSelectedTune=opts.getSelectedTune
  local allowWildCard=opts.allowWildCard
  local getWildCardLength=opts.getWildCardLength or function() end
  local getRegisterInput=opts.getRegisterInput or function() return true end
  local onIllegalInput=opts.onIllegalInput or function() return true end
  assert(opts.logName,"missing logName value")
  local keysDown=_.rep(false,NUM_KEYS)

  local function keyPattern()
    local pattern={}
    for i=1, NUM_KEYS do
      pattern[i]=keysDown[i] and "1" or "0"
    end
    return table.concat(pattern, "")
  end

  local logInput=logger.create(opts.logName,{"date","system millis","key","keys down", "mistake","mistake count", "completed step", "phase","finished sequence","sequence millis","chord millis"})

  local function matchesNoTune(matchingTunes)
    if allowWildCard then
      return false
    end
    if not getSelectedTune or not getSelectedTune() then
      return not matchingTunes
    end
    return getSelectedTune()>0 and (not matchingTunes or not matchingTunes[getSelectedTune()])
  end

  local isComplete
  local wildcardSteps=0
  local chordMillis
  local mistakeCount=0
  local countMistakes=true
  local onPlay=function(event)
    if not getRegisterInput() then
      onIllegalInput()
      return
    end
    local mistake=false
    if keysDown[event.note] then
      mistake=true
    end
    startTime=startTime or system.getTimer()
    local allReleased=not _.contains(keysDown,true)
    chordMillis=allReleased and system.getTimer() or chordMillis
    keysDown[event.note]=true
    logInput("date",os.date())
    logInput("system millis",system.getTimer())
    logInput("key",event.note)
    logInput("keys down",keyPattern())
    logInput("phase","pressed")
    logInput("finished sequence","n/a")
    logInput("sequence millis",system.getTimer()-startTime)
    logInput("chord millis", system.getTimer()-chordMillis)
    isComplete=false
    local tune,matchingTunes=tunedetector.matchAgainstTunes(keysDown)
    mistake=mistake or matchesNoTune(matchingTunes)
    logInput("mistake",mistake)
    if countMistakes and mistake then
      mistakeCount=mistakeCount+1
      countMistakes=false
    end
    logInput("mistake count", mistakeCount)

    if mistake then
      onMistake()
    elseif not tune then
      for k,v in pairs(matchingTunes or {}) do
        isComplete=isComplete or (v.type=="complete" and (k==getSelectedTune() or not getSelectedTune()))
      end
      onGoodInput({complete=isComplete,phase="pressed"})
    end
    logInput("completed step",isComplete)
  end
  local onRelease=function(event)
    if not getRegisterInput() then
      return
    end
    keysDown[event.note]=false
    local tune,matchingTunes=tunedetector.matchAgainstTunes(keysDown,true)
    local mistake=matchesNoTune(matchingTunes)
    logInput("mistake",mistake)
    logInput("completed step",isComplete)
    if not countMistakes then
      countMistakes=not mistake and isComplete
    end
    local allReleased=not _.contains(keysDown,true)
    if allowWildCard and allReleased then
      wildcardSteps=wildcardSteps+1
    end
    local complete=tune or wildcardSteps==getWildCardLength()
    if complete and getSelectedTune then
      local wildcardCompleted=-wildcardSteps==getSelectedTune()
      if wildcardCompleted and matchingTunes then
        for _,v in pairs(matchingTunes) do
          if v.type=="complete" and v.step==wildcardSteps then
            wildcardCompleted=false
            mistake=allReleased
          end
        end
      end
      complete=tune==getSelectedTune() or wildcardCompleted
    end

    local sequenceTime=startTime and (system.getTimer()-startTime) or "n/a"
    logInput("sequence millis",sequenceTime)
    if mistake then
      onMistake()
    elseif complete then
      wildcardSteps=0
      onTuneComplete(tune or -getWildCardLength(),sequenceTime)
    else
      onGoodInput({complete=isComplete,allReleased=allReleased,phase="released",matchingTunes=matchingTunes})
      isComplete=isComplete and not allReleased
    end
    logInput("finished sequence",complete and (tune or -getWildCardLength()) or "no")
    if countMistakes and mistake then
      mistakeCount=mistakeCount+1
      countMistakes=false
    end
    logInput("mistake count", mistakeCount)

    logInput("date",os.date())
    logInput("system millis",system.getTimer())
    logInput("key",event.note)
    logInput("keys down",keyPattern())
    logInput("phase","released")
    logInput("chord millis", chordMillis and (system.getTimer()-chordMillis) or "n/a")
  end

  local reset=function()
    chordMillis=nil
    wildcardSteps=0
    keysDown=_.rep(false,NUM_KEYS)
    tunedetector.reset()
  end
  return onPlay,onRelease,reset
end

return M