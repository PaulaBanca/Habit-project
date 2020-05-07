local M={}
button=M

local display=display

setfenv(1,M)

local PADDING=10

local _, leftInset, _, rightInset = display.getSafeAreaInsets()
local safeWidth = display.actualContentWidth - ( leftInset + rightInset )

local BUTTONWIDTH=(safeWidth-PADDING*2)/2-PADDING-(PADDING/4)
local BUTTONHEIGHT=PADDING*6

function create(text,type,func)
  local group=display.newGroup()
  local bg=display.newRect(group,0, 0, BUTTONWIDTH, BUTTONHEIGHT)
  if type=="change" then
    bg:setFillColor(0,0.7,0.2)
  elseif type=="abort" then
    bg:setFillColor(0.698,0,0.149)
  elseif type=="use" then
    bg:setFillColor(0, 0.498, 0.698)
  end

  local label={removeSelf=function() end}
  local size=50
  repeat
    label:removeSelf()
    label=display.newText({
      parent=group,
      text=text,
      fontSize=size,
      width=BUTTONWIDTH-PADDING/4,
      align="center"
    })
    size=size-1
  until label.height<BUTTONHEIGHT-PADDING/4

  bg:addEventListener("tap", func)
  return group
end

return M
