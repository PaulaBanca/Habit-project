local composer=require "composer"
local scene=composer.newScene()

local events=require "events"
local tunemanager=require "tunemanager"
local keyeventslisteners=require "util.keyeventslisteners"
local display=display
local print=print
local timer=timer
local math=math

setfenv(1,scene)

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

  local reset
  local function madeMistake()
    mistakes=mistakes+1
    shock=true
    reset()
  end

  local onPlay,onRelease,_r=keyeventslisteners.create({
    logName=event.params.logInputFilename,
    onTuneComplete=function(tune)
      if tune~=tunePlaying then
        madeMistake()
      else
        shock=mistakes>0
        completed=completed+1
      end
    end,
    onMistake=madeMistake,
    onGoodInput=function() end,
    getSelectedTune=function() return tunePlaying end,
    allowWildCard=tunePlaying<0,
    getWildCardLenght=function() return math.abs(tunePlaying) end
  })
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
  else
    for i=self.view.numChildren,1,-1 do
      self.view[i]:removeSelf()
    end
  end
end

scene:addEventListener("hide")

return scene