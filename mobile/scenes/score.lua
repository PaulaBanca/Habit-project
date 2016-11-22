local composer=require "composer"
local scene=composer.newScene()

local stimuli=require "stimuli"
local jsonreader=require "jsonreader"
local daycounter=require "daycounter"
local practicelogger=require "practicelogger"
local incompletetasks=require "incompletetasks"
local user=require "user"
local display=display
local system=system
local native=native
local tonumber=tonumber
local math=math

setfenv(1,scene)

local path=system.pathForFile("score.json",system.DocumentsDirectory)

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local text=display.newText({
    text="Your Score: " .. event.params.score,
    fontSize=20,
    font=native.systemFont,
    parent=scene.view
  })
  text.x=display.contentCenterX
  text.y=display.contentCenterY*0.5
  
  local track=event.params.track
  local img=stimuli.getStimulus(track)
  scene.view:insert(img)
  img.x=display.contentCenterX
  img.y=display.contentCenterY
  img:scale(0.5,0.5)

  local prev=jsonreader.load(path)
  local newScore=not prev or not prev[track]
  if prev and prev[track] then
    local prevtext=display.newText({
      text="Previous Best Score: " .. prev[track].score,
      fontSize=20,
      font=native.systemFont,
      parent=scene.view
    })
    prevtext.anchorY=0
    prevtext:translate(img.x, img.y+img.contentHeight/2)

    if prev[track].score<tonumber(event.params.score) then
      local winner=display.newText({
        text="Well done!\nNew Highscore!",
        fontSize=25,
        font=native.systemFont,
        parent=scene.view,
        width=display.contentWidth/2,
        align="center"
      })
      winner.x=img.x
      winner.anchorY=1
      winner.y=text.y-text.height/2
      newScore=true
    end
  end
  if newScore then
    prev=prev or {}
    prev[track]={score=tonumber(event.params.score)}
    jsonreader.store(path,prev)
  end

  local bg=display.newRect(self.view,display.contentCenterX,display.contentHeight-30,120,50)
  bg:setFillColor(83/255, 148/255, 250/255)
  
  display.newText({
    parent=self.view,
    text="Done",
    fontSize=20
  }):translate(bg.x, bg.y)

  bg:addEventListener("tap", function()
    local d=daycounter.getPracticeDay()
    local practiced=daycounter.getPracticed(d)
    local quizzed=user.get("quizzed") or {}
    local qd=quizzed[d] or {}
    local candiate
    for i=1,2 do 
      if not qd[i] and practiced[i]==2 then
        candiate=i
        break
      end
    end
    if candiate then
      qd[candiate]=true
      quizzed[d]=qd
      user.store("quizzed",quizzed)
      local scene,params="scenes.pleasure",{melody=candiate,rounds=1,practice=practicelogger.getPractices(candiate),track=candiate}
      incompletetasks.push(scene,params)

      composer.gotoScene(scene,{params=params})
    else
      composer.gotoScene("scenes.schedule")
    end
  end)
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="did" then
    for i=scene.view.numChildren,1,-1 do
      scene.view[i]:removeSelf()
    end
  end
end

scene:addEventListener("hide")

return scene