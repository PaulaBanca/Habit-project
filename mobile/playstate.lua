local M={}
playstate=M

setfenv(1,M)

local function blankState()
  return {
    count=-1,
    mistakes=0,
    lastChanged=0,
    prevState,
    iterations=0,
    rounds=0,
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

  function t.restart()
    state.count=-1
  end

  function t.clear(key)
    state[key]=blankState()[key] 
  end
  return t
end
return M