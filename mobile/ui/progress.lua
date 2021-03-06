local M={}
progress=M

local display=display
local print=print

setfenv(1,M)

local PADDING=10

function create(w,h,buckets)
  local group=display.newGroup()

  local bucketW=w/#buckets-PADDING*(#buckets-1)
 
  local bx=-w/2
  for i=1, #buckets do
    local slots=buckets[i]
    local sw=bucketW/slots
    for s=1,slots do
      local x=bucketW*s/slots+bx
      local slot=display.newRect(group,0,0,sw,h)
      slot.anchorX=0
      slot.x=x
      slot.strokeWidth=1
      slot:setFillColor(0.2)
      slot:setStrokeColor(0.3)
    end
    bx=bx+bucketW+PADDING
  end

  function group:mark(i,good)
    if good then
      self[i]:setFillColor(0,1,0)
      self[i]:setFillColor(0.5,1,0.5)
    else
      self[i]:setFillColor(0,1,0,0.4)
      self[i]:setFillColor(0.5,0.7,0.5)
    end
  end

  function group:reset()
    if not self.numChildren then
      return
    end
    for i=1,self.numChildren do
      self[i]:setFillColor(0.2)
      self[i]:setStrokeColor(0.3)
    end
  end

  return group
end

return M