local M={}
keysparks=M

local particles=require "particles"
local display=display
local transition=transition
local NUM_KEYS=NUM_KEYS

setfenv(1,M)

local function configureSparks(colour)
  local json=particles.load("CorrectNote")
  json.finishColorRed=colour[1]
  json.startColorRed=colour[1]
  json.finishColorGreen=colour[2]
  json.startColorGreen=colour[2]
  json.finishColorBlue=colour[3]
  json.startColorBlue=colour[3]
  return json
end

local sparks={}

function clear()
  for i=1, NUM_KEYS do
    if sparks[i] then
      display.remove(sparks[i])
      sparks[i]=nil
    end
  end
end

function startSparks(i,colour,x,y)
  if sparks[i] or not colour then
    return
  end

  local e=display.newEmitter(configureSparks(colour))
  e:translate(x,y)
  sparks[i]=e
end

function stopSparks(i)
  if not sparks[i] then
    return
  end
  sparks[i]:stop()
  transition.to(sparks[i],{
    alpha=0,
    onComplete=display.remove
  })
  sparks[i]=nil
end

return M