local composer=require "composer"
local scene=composer.newScene()

local display=display
local timer=timer
local math=math
local Runtime=Runtime
local physics=require "physics"
local system=system
local print=print
local _=require "util.moses"

setfenv(1,scene)

local files={
  "img/shapes/circ.png",
  "img/shapes/dia.png",
  "img/shapes/hex.png",
  "img/shapes/oct.png",
  "img/shapes/pent.png",
  "img/shapes/square.png",
  "img/shapes/star.png",
  "img/shapes/tri.png",
}

local fileToCount=files[7]
local biasFileList=_(files):clone():append(_.rep(fileToCount,2)):value()

local function randomFile()
  return files[math.random(#files)]
end

local function biasRandomFile()
  return biasFileList[math.random(#biasFileList)]
end

local function colVal()
  return (math.random(3)-1)*0.5
end

local function getRGB()
  local r,g,b
  repeat
    r,g,b=colVal(),colVal(),colVal()
  until r~=1 or g~=1 or b~=1
  return r,g,b
end

function scene:getCountShape()
  local img=display.newImage(fileToCount)
  img:setFillColor(getRGB())

  local t
  t=timer.performWithDelay(500, function ()
    if not img.setFillColor then
      timer.cancel(t)
      return
    end
    img:setFillColor(getRGB())
  end ,-1)

  return img
end

function scene:addObject(noCounted,biased)
  local f
  repeat
    f=(biased and biasRandomFile or randomFile)()
  until not noCounted or f~=fileToCount
  local img=display.newImage(self.view,f)
  local t=math.pi*2*math.random()
  img.x,img.y=math.cos(t)*math.random(display.actualContentWidth/2-60)+display.contentCenterX,math.sin(t)*math.random(display.actualContentHeight/2-60)+display.contentCenterY
  img.protectedTime=system.getTimer()+1000
  physics.addBody(img, "dynamic")

  if f==fileToCount then
    timer.performWithDelay(2000,function()
      img.alpha=0
    end)
  end

  img:setFillColor(getRGB())
  return f==fileToCount
end

scene.nextUpdate=0
function scene:update(event)
  if event.time<self.nextUpdate then
    return
  end
  self.nextUpdate=self.nextUpdate+math.random(1000)
  local count=math.floor(self.view.numChildren/2)
  local obj
  for i=1, self.view.numChildren do
    if self.view[i].alpha==0 then
      obj=self.view[i]
      break
    end
  end
  if not obj then
    repeat
      if count==0 then
        return false
      end
      count=count-1
      obj=self.view[math.random(self.view.numChildren)]
    until not obj.text and obj.protectedTime<event.time
  end
  obj:removeSelf()
  self.shapeCount=self.shapeCount+(self:addObject(false,scene.biased) and 1 or 0)
  composer.setVariable("shapes", self.shapeCount)
end

function scene:show(event)
  if event.phase=="did" then
    return
  end

  self.biased=event.params.moreStars
  physics.start()
  physics.setGravity(0, 0)

  local bounds=composer.getVariable("iconbounds")
  if bounds then
    local w=bounds.xMax-bounds.xMin
    local h=bounds.yMax-bounds.yMin

    local block=display.newRect(self.view, bounds.xMin+w/2, bounds.yMin+h/2, w, h)
    physics.addBody(block,"static")
    block.isVisible=false
    block.protectedTime=math.huge
  end

  display.newText({parent=self.view,text="Count the total number of stars you see",fontSize=40,x=display.contentCenterX,y=60,align="center"}):setFillColor(0)

  self.nextUpdate=system.getTimer()+600
  self.shapeCount=0
  composer.setVariable("shapes", self.shapeCount)

  for i=1, 20 do
    self.shapeCount=self.shapeCount+(self:addObject(true,scene.biased) and 1 or 0)
  end
  self.wrapUpdate=function(event) self:update(event) end
  Runtime:addEventListener("enterFrame", self.wrapUpdate)
end

scene:addEventListener("show")

function scene:hide(event)
  if event.phase=="will" then
    Runtime:removeEventListener("enterFrame", self.wrapUpdate)
  else
    for i=self.view.numChildren,1,-1 do
      self.view[i]:removeSelf()
    end
    physics.stop()
  end
end

scene:addEventListener("hide")

return scene