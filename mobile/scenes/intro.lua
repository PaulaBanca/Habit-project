local composer=require "composer"
local scene=composer.newScene()

local display=display
local table=table
local system=system
local media=media
local keys=require "keys"
local chordbar=require "ui.chordbar"
local jsonreader=require "jsonreader"
local NUM_KEYS = NUM_KEYS

setfenv(1,scene)

local instructions={
  {text="Welcome!\n\nThis App will help you to learn 2 sequences of finger presses",y=display.contentCenterY-40},
  {text="You will tap out the sequences on circles like the ones below.\n\nPlace one finger on each circle and give it a go! Tap the coloured circles.\nIn the example below, tap all the coloured circles at once.",y=5,width=display.contentWidth*7/8,fontSize=15,onShow=function()
    local k=keys.create({
        onAllReleased=function() end,
        onMistake=function() end,
        onKeyRelease=function() end
      },
      true)
    scene.view:insert(k)
    k:toBack()
    k:enable()
    local targetKeys=k:setup({chord={"a3",nil,"c4"}},false,false,false,1)
    local hint=chordbar.create(targetKeys)
    if hint then
      hint:translate(0,-k:getKeyHeight()/2)
      scene.view:insert(hint)
    end
  end},
  {text="Let’s practice a simple sequence a few times.\n\nFollow the coloured circles.",y=display.contentCenterY-40,scene="scenes.play",params={intro=true,nextScene="scenes.intro",noSwitch=true}},
  {text="Different levels of difficulty will help you memorizing the sequences.\n\nYou start with an easy level: colours and sounds will guide you.\n\nLater on, you will tap out the sequences with less and less help.",y=display.contentCenterY-140,width=display.contentWidth/2+80},
  {text="We will now guide you through the different levels of difficulty.\n\nTry the same sequence at each level.",y=display.contentCenterY-120},
  {text="Level 1:\n\nColoured circles show you where to tap",y=display.contentCenterY-40,scene="scenes.play",params={intro=true,nextScene="scenes.intro",noSwitch=true,modeProgression=1,difficulty=1}},
  {text="Level 2:\n\nThe circles are all grey, but still play sounds.\n\nYou need to remember the sequence!",y=display.contentCenterY-100,scene="scenes.play",params={intro=true,nextScene="scenes.intro",noSwitch=true,modeProgression=2,difficulty=2}},
  {text="Level 3:\n\nThe circles do not play any sounds.\n\nAt this level you should know the sequence by heart. Try now!",y=display.contentCenterY-80,scene="scenes.play",params={intro=true,nextScene="scenes.intro",noSwitch=true,modeProgression=3,difficulty=3}},
  {text="Level 4:\n\nThe circles are blank. Give it a go!",y=display.contentCenterY-40,scene="scenes.play",params={intro=true,nextScene="scenes.intro",noSwitch=true,modeProgression=4,difficulty=4}},
  {text="The App only works if you keep a spare finger touching the screen while playing.\n\nHere are some examples of how to hold your phone.",y=display.contentCenterY-120},
  {img=("img/keys_%d/instructions1.png"):format(NUM_KEYS)},
  {img=("img/keys_%d/instructions2.png"):format(NUM_KEYS)},
  {img=("img/keys_%d/instructions3.png"):format(NUM_KEYS)},
  {img=("img/keys_%d/instructions4.png"):format(NUM_KEYS)},
  {onShow=function()
    media.playVideo(("img/keys_%d/instructions.mov"):format(NUM_KEYS),system.ResourceDirectory,false,function()
      for i=scene.view.numChildren,1,-1 do
        scene.view[i]:removeSelf()
      end
      composer.gotoScene("scenes.intro",{params=16})
    end)
  end},
  {text="Now, let’s play the same sequence as last time. Play it once at each of the different levels.\n\nDon’t forget to place a spare finger one the screen while playing!",y=display.contentCenterY-120,scene="scenes.play",params={intro=true,modeProgression=4,nextScene="scenes.intro"}},
  {text="Now you are ready to start practising your sequences.\n\nYou have a month to master the sequences!\n\nGood luck!",y=display.contentCenterY-120},
}

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local path=system.pathForFile("intro.json",system.DocumentsDirectory)
  local loaded=jsonreader.load(path)
  local step=table.remove(instructions,1)
  if not step or loaded then
    jsonreader.store(path,{done=true})
    return composer.gotoScene("scenes.schedule")
  end

  if step.onShow then
    step.onShow()
  end

  local obj
  if step.text then
    obj=display.newText({
      parent=scene.view,
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
  elseif step.img then
    obj=display.newImage(self.view,step.img,display.contentCenterX,20)
    obj.anchorY=0
    if obj.width>display.actualContentWidth-40 then
      obj.xScale=(display.actualContentWidth-40)/obj.width
      obj.yScale=obj.xScale
    end
    if obj.contentHeight+70>display.actualContentHeight then
      local scale=(display.actualContentHeight-70)/obj.contentHeight
      obj:scale(scale,scale)
    end
  end
  if obj then
    local bg=display.newRect(scene.view,display.contentCenterX, obj.y+obj.contentHeight+20,100 ,30)
    bg:setFillColor(83/255, 148/255, 250/255)
    display.newText({
      parent=scene.view,
      x=bg.x,
      y=bg.y,
      text="Next",
      align="center"
    })

    bg:addEventListener("tap", function ()
      for i=scene.view.numChildren,1,-1 do
        scene.view[i]:removeSelf()
      end
      composer.gotoScene(step.scene and step.scene or "scenes.intro",{params=step.params})
    end)
  end
end
scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    return
  end
  for i=scene.view.numChildren, 1, -1 do
    scene.view[i]:removeSelf()
  end
end
scene:addEventListener("hide")

return scene