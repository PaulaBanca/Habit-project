local M={}
playstate=M

local serpent=require "serpent"
local system=system
local print=print

setfenv(1,M)

local function blankState()
  return {
    count=0,
    mistakes=0,
    lastChanged=0,
    prevState,
    iterations=0,
    rounds=0,
    timerStart=0,
    stepID=0,
  }
end

function create()
  local t={}
  local state=blankState()
  function t.increment(key)
    if not key then
      state.count=state.count+1
    else
      state[key]=state[key]+1
    end
  end

  function t.pushState()
    local temp=state
    state=blankState()
    state.prevState=temp
  end

  function t.pullState()
    state=state.prevState or state
  end

  function t.get(key)
    return state[key]
  end

  function t.getTime()
    return system.getTimer()-state.startTimer
  end

  function t.restart()
    state.count=0
    t.startTimer()
  end

  function t.startTimer()
    state.startTimer=system.getTimer()
  end

  function t.clear(key)
    state[key]=blankState()[key]
  end

  function t.print()
    print (serpent.block(state,{comment=false}))
  end
  return t
end
return M