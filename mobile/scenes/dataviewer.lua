local composer=require "composer"
local scene=composer.newScene()

local widget=require "widget"
local unsent=require "database.unsent"
local rawset=rawset
local setmetatable=setmetatable
local tonumber=tonumber
local display=display
local unpack=unpack

setfenv(1,scene)

function scene:create()
  local bg=display.newRect(self.view, display.contentCenterX, display.contentCenterY, display.actualContentWidth,display.actualContentHeight/2)
  bg.anchorY=1
  bg:setFillColor(0,0.2)
end
scene:addEventListener("create")

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local showGroup=display.newGroup()
  scene.view:insert(showGroup)
  scene.deleteOnHide=showGroup

  local scroll=widget.newScrollView({
    width=display.actualContentWidth/2-40,
    height=display.actualContentHeight/2-40,
    left=display.screenOriginX+20,
    top=display.screenOriginY+20, 
    horizontalScrollDisabled=true,
    backgroundColor={0,0.5}
  })
  showGroup:insert(scroll)

  local queued=unsent.getUnsent()
  local y=0
  local mistakes=0

  local infoStr="Mode Index: %s\nModes Dropped: %s\nIterations: %s\nDelay: %s"
  local infoText=display.newText({
    parent=showGroup,
    width=display.actualContentWidth/2-40,
    text=infoStr:format("n/a","n/a","n/a","n/a")
  })
  infoText.anchorX=0
  infoText.anchorY=0
  infoText.x=display.contentCenterX+20
  infoText.y=display.screenOriginY+20

  setmetatable(queued, {
    __newindex=function(t,k,v)
      rawset(t,k,v)
      local row=display.newGroup()
      row.y=y
      y=y+scroll.width/4
      scroll:insert(row)
      scroll:scrollTo("bottom", {time=100})
      infoText.text=infoStr:format(v.modeIndex,v.modesDropped,v.iterations,v.delay)
      local key=tonumber(v.keyIndex)
      if key then 
        local c=display.newCircle(row, scroll.width*key/4, 0, scroll.width/8)
        c.anchorX=1
        c.strokeWidth=4
        c:setStrokeColor(v.touchPhase=="began" and 1 or 0)
        if v.wasCorrect=="true" then
          if v.complete=="true" then
            c:setFillColor(0,1,0)
          else 
            c:setFillColor(1,1,0)
          end
        else
          c:setFillColor(1,0,0)
        end
      end
    end
  })

  function scroll:finalize()
    setmetatable(queued, nil)
  end
  scroll:addEventListener("finalize")
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="did" then
    display.remove(showGroup)
    showGroup=nil
  end
end

scene:addEventListener("hide")

return scene