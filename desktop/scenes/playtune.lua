local composer=require "composer"
local scene=composer.newScene()

local server=require "server"
local events=require "events"
local serpent=require "serpent"
local tunes=require "tunes"
local stimuli=require "stimuli"
local countdown=require "ui.countdown"
local tunemanager=require "tunemanager"
local sound=require "sound"
local keyeventslisteners=require "util.keyeventslisteners"
local logger=require "util.logger"
local progress=require "ui.progress"
local transition=transition
local display=display
local table=table
local pairs=pairs
local print=print
local timer=timer
local tonumber=tonumber
local next=next
local native=native
local os=os
local system=system
local math=math
local NUM_KEYS=NUM_KEYS

setfenv(1,scene)

function scene:create()
end
scene:addEventListener("create")

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local tunePlaying=event.params.tune
  local img=tunemanager.getImg(tunePlaying)
  scene.view:insert(img)
  img.x=display.contentCenterX
  img.y=display.contentCenterY
  
  local mistakes=0
  local completed=0
  local shock=true
  self.timer=timer.performWithDelay(event.params.time, function()
    event.params.onComplete(shock,completed,mistakes)
    self.timer=nil
  end)

  local steps=0
  local reset
  local function madeMistake()
    mistakes=mistakes+1
    shock=true
    reset()
    print ("mistake")
  end

  local onPlay,onRelease,_r=keyeventslisteners.create(event.params.logInputFilename,function(tune)
    if tune~=tunePlaying then
      print ("completed wrong tune")
      madeMistake()
    else
      print ("completed correct tune")
      shock=mistakes>0
      completed=completed+1
    end
  end,madeMistake,function() end,function() return tunePlaying end,tunePlaying<0,function() return math.abs(tunePlaying) end)
  reset=_r
  events.addEventListener("key played",onPlay)
  events.addEventListener("key released",onRelease)
  self.onRelease=onRelease
  self.onPlay=onPlay
end
scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    if self.timer then
      timer.cancel(self.timer)
      self.timer=nil
    end
    if self.onPlay then
      events.removeEventListener("key played",self.onPlay)
      events.removeEventListener("key released",self.onRelease)
      self.onPlay=nil
      self.onRelease=nil
    end
    composer.hideOverlay("scenes.shapecounter")
  else
    for i=self.view.numChildren,1,-1 do
      self.view[i]:removeSelf()
    end
  end
end

scene:addEventListener("hide")

return scene