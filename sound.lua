local M={}
sound=M

local audio=audio
local ipairs=ipairs
local pairs=pairs
local print=print
local tostring=tostring
local timer=timer
local al=al
local FLAGS=FLAGS
local display=display
local math=math
local assert=assert

setfenv(1,M)

FLAGS=FLAGS or {}

audio.setVolume(FLAGS.NO_SOUND and 0 or 0.6)

local soundFiles={
  {name="c.wav", purpose="c note"},
  {name="d.wav", purpose="d note"},
  {name="e.wav", purpose="e note"},
  {name="f.wav", purpose="f note"},
  {name="g.wav", purpose="g note"},
  {name="a.wav", purpose="a note"},
  {name="b.wav", purpose="b note"},
  {name="feed.wav", purpose="wrong"},
  {name="323493__activeobjectx__c-chord.wav", purpose="correct"},
  {name="246281__afleetingspeck__a-guitar-chord-hit-percussion.wav", purpose="mistakes"},
}

local soundInstancesByPurpose={}
local duckMusic={}
local dontUseLastFreeChannel={}
local x,y=80,80
for _,v in ipairs(soundFiles) do
  assert(v.purpose)
  if not soundInstancesByPurpose[v.purpose] then
    soundInstancesByPurpose[v.purpose]={}
  end
  if v.duck then
    duckMusic[v.purpose]=true
  end
  if v.noswamp then
    dontUseLastFreeChannel[v.purpose]=true
  end
  assert(duckMusic[v.purpose]==v.duck)
  local list=soundInstancesByPurpose[v.purpose]
  list[#list+1]=audio.loadSound("sounds/"..v.name)
end

function showDebugButtons()
  for _,list in pairs(soundInstancesByPurpose) do
    for _,sound in ipairs(list) do
      local button=display.newRoundedRect(x,y,80,80,8)
      function button:touch(event)
        if self.disable then
          return
        end
        if event.phase=="began" then
          self.touchId=event.id
        end
        if event.phase=="ended" and self.touchId==event.id then
          self:setFillColor(255/255,0/255,0/255)
        self.disable=true
          local function onComplete()
            self:setFillColor(50/255,124/255,9/255)
            self.disable=false
          end
          audio.play(sound,{onComplete=onComplete})
        end
      end
      button:addEventListener("touch",button)

      button:setFillColor(50/255,124/255,9/255)
      x=x+100
      if x+40>display.contentWidth-80 then
        y=y+100
        x=80
      end
    end
  end
end

function playSound(purpose,onComplete,pitch)
  if dontUseLastFreeChannel[purpose] then
    if audio.unreservedFreeChannels<=2 then
      return
    end
  end
  local index=math.random(#soundInstancesByPurpose[purpose])

  -- if duckMusic[purpose] then
  --   music.fadeMusic(0)
  --   local oldOnComplete=onComplete
  --   onComplete=function()
  --     music.fadeMusic(1)
  --     if oldOnComplete then
  --       oldOnComplete()
  --     end
  --   end
  -- end

  local mysource
  if pitch then
    local oldC=onComplete or function() end
    onComplete=function(event)
      oldC(event)
      al.Source(mysource, al.PITCH, 1)
    end
  end

  local channel=audio.play(soundInstancesByPurpose[purpose][index],{onComplete=onComplete})
  audio.setVolume(FLAGS.NO_SOUND and 0 or 1,{channel=channel})
  if pitch then
    mysource=audio.getSourceFromChannel(channel)
    al.Source(mysource, al.PITCH, pitch)
  end

  return channel
end

function loopSound(purpose)
  local index=math.random(#soundInstancesByPurpose[purpose])
  local channel=audio.play(soundInstancesByPurpose[purpose][index],{loops=-1})
  audio.setVolume(FLAGS.NO_SOUND and 0 or 1,{channel=channel})
  return function(time)
    time=500
    audio.fadeOut({channel=channel,time=time})
    timer.performWithDelay(time, function() audio.setVolume(FLAGS.NO_SOUND and 0 or 1,{channel=channel}) end)
  end, channel
end

return M
