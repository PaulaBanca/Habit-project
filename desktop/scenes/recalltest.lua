local composer=require "composer"
local scene=composer.newScene()

local tunemanager=require "tunemanager"
local stimuli=require "stimuli"
local display=display
local type=type
local Runtime=Runtime
local timer=timer
local os=os

setfenv(1, scene)

local pageSetup={
  {
    text="Welcome Back, lets see how much you remember",
    onKeyPress=function() 
      composer.gotoScene("scenes.recalltest",{params={page=2}})
    end
  },
  {text="First lets see how much you remember of this sequence that you practiced",img=function()
    return stimuli.getStimulus(composer.getVariable("first test"))
  end,
  onKeyPress=function()
    composer.gotoScene("scenes.learntune", {
      params={
        logInputFilename="recall-first-test",
        tune=tunemanager.getID(composer.getVariable("first test")),
        advanced=true,
        nextScene="scenes.recalltest",
        page=3,
        iterations=20,
      }
    })
  end},
  {text="Now lets see how much you remember of this second sequence that you practiced",img=function()
    return stimuli.getStimulus(composer.getVariable("second test"))
  end,
  onKeyPress=function()
    composer.gotoScene("scenes.learntune", {
      params={
        logInputFilename="recall-second-test",
        tune=tunemanager.getID(composer.getVariable("second test")),
        advanced=true,
        nextScene="scenes.recalltest",
        page=4,
        iterations=20,
      }
    })
  end},
  {
    text="Well done. Thank you for your time",
    onKeyPress=function()
      os.exit()
    end
   }
}

local nextScene
function scene:show(event)
  local setup=pageSetup[event.params and event.params.page or 1]
  if event.phase=="did" then
    if nextScene then
      Runtime:removeEventListener("key", nextScene)
      nextScene=nil
    end
    scene.keyTimer=timer.performWithDelay(500, function()
      nextScene=function(event)
        if event.phase=="up" and event.keyName=="enter" then
          if nextScene then
            Runtime:removeEventListener("key", nextScene)
            nextScene=nil
            setup.onKeyPress()
          end
        end
      end
      Runtime:addEventListener("key", nextScene)
    end)
    return
  end
  local img
  if setup.img then
    if type(setup.img)=="string" then
      img=display.newImage(self.view,setup.img)
    else
      img=setup.img()
      self.view:insert(img)
    end
    img.x=display.contentCenterX
  end
  local text=display.newText({
    parent=self.view,
    text=setup.text,
    x=display.contentCenterX,
    y=display.contentCenterY,
    width=display.actualContentWidth*3/4,
    align="center",
    fontSize=48})
  text:setFillColor(0)

  if img then
    local h=text.height+img.height+20
    img.anchorY=0
    img.y=display.contentCenterY-h/2
    text.anchorY=1
    text.y=display.contentCenterY+h/2
  end

  local any=display.newText({
    parent=self.view,
    text="Press enter to continue",
    x=display.contentCenterX,
    y=display.actualContentHeight-20,
    align="center",
    fontSize=40})
  any.anchorY=1
  any:setFillColor(0)
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    for i=self.view.numChildren,1,-1 do
      self.view[i]:removeSelf()
    end
    if self.keyTimer then
      timer.cancel(self.keyTimer)
      self.keyTimer=nil
    end
    if nextScene then
      Runtime:removeEventListener("key", nextScene)
      nextScene=nil
    end
  end
end

scene:addEventListener("hide")

return scene