local M={}
key=M

local display=display
local system=system
local unpack=unpack
local notes=require "notes"
local math=math
local timer=timer
local print=print

setfenv(1,M)

local ran=false
local keyWidth,keyHeight
local isMiniScale=(system.getInfo("model")=="iPad" and display.pixelWidth==768) and  0.72 or 1

function createImages(whenDone)
  if ran then
    return whenDone()
  end
  ran=true

  local KEYR=math.min(130*display.contentScaleX,display.contentWidth/8)*isMiniScale
  local BLUR=8*display.contentScaleX-- TDODO check for iphone 4
  local c=display.newCircle(0, 0, KEYR)
  c:scale(1,1.75)

  keyWidth,keyHeight=c.contentWidth,c.contentHeight
  display.save(c, {filename="key.png",isFullResolution=true})
  c.strokeWidth=8
  c:setStrokeColor(0)
  display.save(c, {filename="key_pressed.png",isFullResolution=true})

  c:removeSelf()

  c=display.newImage("key_pressed.png" ,system.DocumentsDirectory)
  c:scale(keyWidth/c.width,keyHeight/c.height)
  local s=display.newSnapshot(c.contentWidth, c.contentHeight)
  s.fill.effect = "filter.emboss"
  s.fill.effect.intensity = 0.2

  s.canvas:insert(c)
  s:invalidate("canvas")
  s.yScale=-1
  display.save(s, {filename="key_pressed.png",isFullResolution=true})
  s:removeSelf()

  c=display.newImage("key_pressed.png" ,system.DocumentsDirectory)
  c:scale(keyWidth/c.width,keyHeight/c.height)
  c.fill.effect="filter.invert"
  local s=display.newSnapshot(c.contentWidth+BLUR, c.contentHeight+BLUR)
  s.fill.effect = "filter.blurGaussian"

  s.fill.effect.horizontal.blurSize = BLUR
  s.fill.effect.horizontal.sigma = 10
  s.fill.effect.vertical.blurSize = BLUR
  s.fill.effect.vertical.sigma = 10

  s.canvas:insert(c)

  s:invalidate("canvas")

  display.save(s, {filename="key_highlight2.png",isFullResolution=true})
  s:removeSelf()

  timer.performWithDelay(10 ,function()
    local g=display.newGroup()
    for i=1, 4 do
      local img=display.newImage(g,"key_highlight2.png",system.DocumentsDirectory)
      img.blendMode="add"
    end
    g:scale(keyWidth/g.width,keyHeight/g.height)
    display.save(g, {filename="key_highlight.png",isFullResolution=true})
    g:removeSelf()
    whenDone()
  end)
end

function create()
  local group=display.newGroup()
  local key=display.newImage(group,"key.png",system.DocumentsDirectory)
  key:setFillColor(0.6)
  local tapBg=display.newRect(group,0,0,key.width,key.height)
  tapBg.isVisible=false
  tapBg.isHitTestable=true
  local highlight=display.newImage(group, "key_highlight.png",system.DocumentsDirectory)
  local pressed=display.newImage(group, "key_pressed.png",system.DocumentsDirectory)

  for i=1, group.numChildren do
    local c=group[i]
    c:scale(keyWidth/c.width,keyHeight/c.height)
  end
  highlight.isVisible=false
  highlight.blendMode="add"
  pressed.isVisible=false
  pressed.blendMode="multiply"

  function highlightFunc(self,on)
    key.fill.effect=on and "filter.custom.pulse"
    highlight.isVisible=on
    self.highlighted=on
  end
  group.highlight=highlightFunc

  function getPos(self)
    return key.x,key.y
  end
  group.move=move
  group.getPos=getPos

  function setOctave(self,octave)
    self.octave=octave
  end
  group.setOctave=setOctave

  function setNote(self,note,noColour)
    self.note=note
    self.colour=notes.getColour(notes.getIndex(note))

    if noColour then
      key:setFillColor(0.6)
      pressed:setFillColor(1)
    else
      key:setFillColor(unpack(self.colour))
      pressed:setFillColor(unpack(self.colour))
    end
  end
  group.setNote=setNote

  function clear(self)
    key:setFillColor(0.6)
    pressed:setFillColor(1)
    pressed.isVisible=false
    self.note=nil
    self.colour=nil
    self.highlighted=false
    highlight.isVisible=false
  end
  group.clear=clear

  function getTouchImg()
    return tapBg
  end
  group.getTouchImg=getTouchImg

  function setPressed(visible)
    pressed.isVisible=visible
  end
  group.setPressed=setPressed

  function setHighlightAlpha(a)
    highlight.alpha=a
  end
  group.setHighlightAlpha=setHighlightAlpha

  function getHighlight()
    return highlight
  end
  group.getHighlight=getHighlight

  return group
end

return M