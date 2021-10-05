local composer=require "composer"
local scene=composer.newScene()

local display=display
local table=table
local system=system
local media=media
local math=math
local keys=require "keys"
local chordbar=require "ui.chordbar"
local jsonreader=require "jsonreader"
local i18n = require ("i18n.init")
local NUM_KEYS = NUM_KEYS

setfenv(1,scene)

local instructions={
  {text=i18n("tutorial.welcome"),y=display.contentCenterY-40},
  {text=i18n("tutorial.explanation"),y=5,width=display.contentWidth*7/8,fontSize=15,onShow=function()
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
  {
    text=i18n("tutorial.practice"),
    y=display.contentCenterY-40,
    scene="scenes.play",
    params={
      intro=true,
      nextScene="scenes.intro",
      noSwitch=true
    }
  },
  {
    text=i18n("tutorial.levels"),
    y=display.contentCenterY-140,
    width=display.contentWidth/2+80
  },
  {
    text=i18n("tutorial.level_practice"),
    y=display.contentCenterY-120},
  {
    text=i18n("tutorial.level1"),
    y=display.contentCenterY-40,
    scene="scenes.play",
    params={
      intro=true,
      nextScene="scenes.intro",
      noSwitch=true,
      modeProgression=1,
      iterationDifficulties={1}
    }
  },
  {
    text=i18n("tutorial.level4"),
    y=display.contentCenterY-80,
    scene="scenes.play",
    params={
      intro=true,
      nextScene="scenes.intro",
      noSwitch=true,
      modeProgression=2,
      iterationDifficulties={2}
    }
  },
  {text=i18n("tutorial.deadmans_switch"),y=display.contentCenterY-120},
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
  {
    text=i18n("tutorial.full_practice"),
    y=display.contentCenterY-120,
    scene="scenes.play",
    params={
      intro=true,
      modeProgression=2,
      iterationDifficulties = {1,2},
      nextScene="scenes.intro",
      maxLearningLength = 1,
      rounds = 1
    }
  },
  {
    text=i18n("tutorial.devaluation1"),
    y=display.contentCenterY-120
  },
  {
    text=i18n("tutorial.devaluation2"),
    y=display.contentCenterY-120
  },
  {text=i18n("tutorial.tutorial_completed"),y=display.contentCenterY-120},
}

function scene:show(event)
  if event.phase=="will" then
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
    local maxButtonY = display.safeScreenOriginY + display.safeActualContentHeight - 25
    local bg=display.newRect(
      scene.view,
      display.contentCenterX,
      math.min(obj.y+obj.contentHeight+20, maxButtonY),
      100,
      30)
    bg:setFillColor(83/255, 148/255, 250/255)
    display.newText({
      parent=scene.view,
      x=bg.x,
      y=bg.y,
      text=i18n("buttons.next"),
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
