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

setfenv(1,M)

function create(logName,onTuneComplete,onMistake,onFine,restrictedToTune,allowWildCard,getWildCardLength)
  local keysDown={}

  local function keyPattern()
    local pattern={}
    for i=1, NUM_KEYS do
      pattern[i]=keysDown[i] and "X" or "_"
    end
    return table.concat(pattern, "") 
  end

  local logInput=logger.create(logName,{"date","system millis","key","keys down", "mistake", "completed step", "phase","finished sequence"})
  
  local function matchesNoTune(matchingTunes)
    if allowWildCard then
      return false
    end
    if not restrictedToTune then
      return not matchingTunes 
    end
    return restrictedToTune>0 and (not matchingTunes or not matchingTunes[restrictedToTune])
  end

  local isComplete
  local wildcardSteps=0
  local onPlay=function(event) 
    local mistake=false
    if keysDown[event.note] then
      mistake=true
    end
    keysDown[event.note]=true
    logInput("date",os.date())
    logInput("system millis",system.getTimer())
    logInput("key",event.note)
    logInput("keys down",keyPattern())
    logInput("phase","pressed")
    logInput("finished sequence","n/a")

    isComplete=false
    local tune,matchingTunes=tunedetector.matchAgainstTunes(keysDown)
    mistake=mistake or matchesNoTune(matchingTunes)
    logInput("mistake",mistake)
    
    if mistake then
      onMistake()
    elseif not tune then
      for k,v in pairs(matchingTunes or {}) do
        isComplete=isComplete or (v.type=="complete" and (k==restrictedToTune or not restrictedToTune))
      end
      onFine({complete=isComplete,phase="pressed"})
    end
    logInput("completed step",isComplete)
  end
  local onRelease=function(event)
    keysDown[event.note]=false
    local tune,matchingTunes=tunedetector.matchAgainstTunes(keysDown,true)
    local mistake=matchesNoTune(matchingTunes)
    logInput("mistake",mistake)
    logInput("completed step",isComplete)
    local allReleased=not _.contains(keysDown,true)
    if allowWildCard and allReleased then
      wildcardSteps=wildcardSteps+1
    end
    local complete=tune or wildcardSteps==getWildCardLength()

    if mistake then
      onMistake()
    elseif complete then
      wildcardSteps=0
      onTuneComplete(tune or -getWildCardLength())
    else
      onFine({complete=isComplete,allReleased=allReleased,phase="released",matchingTunes=matchingTunes})
      isComplete=isComplete and not allReleased
    end
    logInput("finished sequence",complete and (tune or -getWildCardLength()) or "no")

    logInput("date",os.date())
    logInput("system millis",system.getTimer())
    logInput("key",event.note)
    logInput("keys down",keyPattern())
    logInput("phase","released")
  end

  function reset()
    wildcardSteps=0
    tunedetector.reset()
  end
  return onPlay,onRelease,reset
end

return M