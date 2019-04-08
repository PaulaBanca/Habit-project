local composer=require "composer"
local scene=composer.newScene()

local phasemanager=require "phasemanager"
local events=require "events"
local _=require "util.moses"
local serpent=require "serpent"
local display=display
local type=type
local math=math
local timer=timer
local setmetatable=setmetatable
local rawget=rawget
local print=print
local FLAGS=FLAGS

setfenv(1,scene)

local getTrackMT={
  __index=function(t,k)
    if k=="track" then
      return phasemanager.getCurrentTrack()
    end
    return rawget(t, k)
  end
}

local instructions={
  {
    phase='Intro',
    text="Welcome back! We would like to see if you can remember any of the sequences you practiced some months ago",
    y=display.contentCenterY-40,
    onComplete=function()
      events.fire({type='phase finished'})
    end
  },
  {
    phase='A',
    text="Do you remember this pattern?",
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
    text="Try to play the sequence that goes with this pattern. Don’t worry if you make mistakes! There will be a re-start button available if you wish to start again.",
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
  {
    phase='A2',
    text="Let’s do it again. This time the re-start option is no longer available. Once you start playing the sequence you have to finish it in one go.",
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
      phase="A2",
      nextScene="scenes.intro",
      noSwitch=true,
      rounds=1,
      iterations=FLAGS.QUICK_ROUNDS and 1
    },getTrackMT)
  },
  -- PHASE B
  {
    phase='B',
    text="Let’s do this again but this time you get feedback on your mistakes after playing the sequence.",
    y=display.contentCenterY-40,
    scene="scenes.play",
    params=setmetatable({
      requireStartButton=true,
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
    text="Now if you make a mistake you will need to start from the beginning. However the correct keys will be highlighted where you made the mistake to help you.",
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
    text="Now you will learn a new sequence. Use the feedback to memorise it.",
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
    text="Well done",
    y=5,
    width=display.contentWidth*7/8,
    fontSize=15,
    noButton=true
  },
}

function scene:create()
  events.addEventListener('phase change',function()
    self.page=1
  end)
  self.page=1
end
scene:addEventListener('create')

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local phaseInstructions=_.select(instructions,function(_,v)
    return v.phase==phasemanager.getPhase()
  end)
  local step=phaseInstructions[self.page or 1]
  if not step then
    return composer.gotoScene("scenes.complete")
  end

  if step.onShow then
    step.onShow()
  end

  local function nextPage()
    self.page=self.page+1
    if step.onComplete then
      step.onComplete()
    end
    composer.gotoScene(step.scene and step.scene or "scenes.intro",{
      params=step.params
    })
  end
  if step.seamless then
    return timer.performWithDelay(1,nextPage)
  end

  local obj
  if step.text then
    obj=display.newText({
      parent=self.view,
      x=display.contentCenterX,
      y=step.y or display.contentCenterY,
      width=step.width or display.contentWidth/2,
      text=step.text,
      align="center",
      fontSize=step.fontSize or 20
    })
    obj.anchorY=0
    local bg=display.newRect(
      self.view,
      obj.x,
      obj.y+obj.height/2,
      display.contentWidth,
      obj.height+20
    )
    bg:setFillColor(0.2)
    obj:toFront()
  end

  if step.img then
    local img
    if type(step.img)=='string' then
      img=display.newImage(self.view,step.img,display.contentCenterX,20)
    else
      img=step.img()
      self.view:insert(img)
      img:translate(
        obj.x or display.contentCenterX,
        obj.y and (obj.y+obj.height + 10) or display.contentCenterY)
    end
    img.anchorY=0
    if img.width>display.actualContentWidth-40 then
      img.xScale=(display.actualContentWidth-40)/img.width
      img.yScale=img.xScale
    end
    if img.contentHeight+70>display.actualContentHeight then
      local scale=(display.actualContentHeight-70)/img.contentHeight
      img:scale(scale,scale)
    end
  end
  if obj and not step.noButton then
    local bottom=0
    for i=1, self.view.numChildren do
      bottom=math.max(self.view[i].contentBounds.yMax,bottom)
    end

    local bg=display.newRect(
      self.view,
      display.contentCenterX,
      bottom+20,
      100,
      30)
    bg:setFillColor(83/255, 148/255, 250/255)
    display.newText({
      parent=self.view,
      x=bg.x,
      y=bg.y,
      text="Next",
      align="center"
    })

    bg:addEventListener("tap", nextPage)
  end
end
scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    return
  end
  for i=self.view.numChildren, 1, -1 do
    self.view[i]:removeSelf()
  end
end
scene:addEventListener("hide")

return scene