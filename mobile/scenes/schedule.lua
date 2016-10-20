local composer=require "composer"
local scene=composer.newScene()

local widget=require "widget"
local stimuli=require "stimuli"
local daycounter=require "daycounter"
local incompletetasks=require "incompletetasks"
local user=require "user"
local display=display
local native=native
local math=math
local pairs=pairs
local print=print

setfenv(1,scene)

local MAX_DAYS=31

function scene:show(event)
  if event.phase=="did" then
    return
  end

  if incompletetasks.getNext() then
    return
  end

  local scroll=widget.newScrollView({
    width=display.contentWidth,
    height=70,
    verticalScrollDisabled=true,
    hideBackground=true
  })
  scroll:translate(0, display.contentCenterY-scroll.height/2)
  self.view:insert(scroll)

  local title=display.newText({
    parent=scene.view,
    x=display.contentCenterX,
    y=scroll.y-scroll.height/2-5,
    text="Practice Schedule",
    align="center",
    fontSize=20
  })
  title.anchorY=1

  local seed=display.newText({
    parent=scene.view,
    x=10,
    y=10,
    text=user.get("seed"),
    align="right",
    fontSize=20
  })
  seed.anchorX=0
  seed.anchorY=0

  local dates=daycounter.getDayCount()
  local step=60
  local datePoints=math.min(MAX_DAYS,math.max(dates+3+1,10))
  local line=display.newLine(0,scroll.height/2,(datePoints+1)*step,scroll.height/2)
  line.strokeWidth=2
  scroll:insert(line)
  line:setStrokeColor(0.6)
  local today=dates+1
  local practiceDate
  for i=1, datePoints do
    local track=daycounter.getPracticed(i)
    local complete
    local x=i*step
    if track then
      local count=0
      for k,v in pairs(track) do
        local off=(k-1)*2-1
        local countedPractices=math.min(2,v)
        count=count+countedPractices
        local img=stimuli.getStimulus(k)
        img:scale(0.15,0.15)
        local container=display.newContainer(img.contentWidth/2,img.contentHeight/((2+countedPractices)%2+1))
        container.anchorY=0
        container.anchorChildren=true
        container:translate(x-container.width/2*off, scroll.height/2-img.contentHeight/2)
        img.x=container.width/2*off
        img.y=countedPractices==2 and 0 or img.contentHeight/4
        container:insert(img)
        scroll:insert(container)

        if countedPractices<2 then
          local line=display.newLine(x-container.width*off,scroll.height/2,x,scroll.height/2)
          line.strokeWidth=4
          scroll:insert(line)
        end
      end
      local line=display.newLine(x,14,x,scroll.height-14)
      line.strokeWidth=4
      scroll:insert(line)
      complete=count==4
    else
      local c=display.newCircle(self.view,x,scroll.height/2, 16)
      scroll:insert(c)
      c.strokeWidth=2
      if i~=today then
        c:setFillColor(0.6, 0.2)
        c:setStrokeColor(0.6, 0.5)
        if i>today then
          c.alpha=2*(datePoints==10 and 1 or 0.3)/(i-today)
        end
        if i<today then
         c:setFillColor(250/255, 41/255, 41/255)
       end
   
      else
        c:setFillColor(0.6, 0.2)
        c:setStrokeColor(1)
        c.strokeWidth=4
      end

      local day=display.newText({
        x=c.x,
        y=c.y,
        text=(i~=today and i or "Today")..(i<today and "!" or ""),
        align="center",
        fontSize=i~=today and 20 or 10
      })
      day.alpha=c.alpha
      scroll:insert(day)
    end
    local inComplete=not track or track and not complete
    if not practiceDate and inComplete or i==today then
      local t=display.newCircle(self.view,x,scroll.height/2, 30)
      scroll:insert(t)
      if not practiceDate then
        if complete then
        t:setFillColor(250/255, 220/255, 41/255,0.9)
        else
          t:setFillColor(83/255, 148/255, 250/255)
        end
        local day=i
        t:addEventListener("tap", function()
          daycounter.setPracticeDay(day)
          composer.gotoScene("scenes.select")
        end)
        t.strokeWidth=3
      else
        t:setFillColor(250/255, 41/255, 41/255)
      end 
      if not practiceDate then
        practiceDate=i
      end 
      t:toBack()
    end
  end
  scroll:scrollToPosition({x=-practiceDate*step+scroll.width/2})

  local connect=display.newImage(scene.view,"img/connect.png")
  connect.anchorX=1
  connect.anchorY=0
  connect:translate(display.contentWidth-5,5)
  connect:addEventListener("tap", function() 
    -- Handler that gets notified when the alert closes
    local function onComplete(event)
     if event.action == "clicked" then
        local i = event.index
        if i == 1 then      
        elseif i == 2 then
          composer.gotoScene("scenes.connect")
        end
      end
    end

    native.showAlert("For Lab Only", "Connect to desktop app? This function is for the final stage of the study. Without the app is will not do anything",{"No","Yes"},onComplete)

  end)

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