local M={}
winnings=M

local display=display
local Runtime=Runtime
local _=require "util.moses"

setfenv(1,M)

local lastTotals={}
local totals={}
function add(type,amt)
  totals[type]=(totals[type] or 0) + amt
end

function get(type)
  return (totals[type] or 0)
end

function startTracking()
  lastTotals=_.clone(totals)
end

function getSinceLastTrack(type)
  return get(type)-(lastTotals[type] or 0)
end

function startDebugDisplay()
  local group=display.newGroup()
  local gemsStr="Gems total %.4d\ttask %.4d"
  local gemsLabel=display.newText({
    parent=group,
    text=gemsStr:format(0,0),
    fontSize=30,
    align="left",
  })

  local moneyStr="Money total %4.2f\ttask %4.2f"
  local money=display.newText({
    parent=group,
    text=moneyStr:format(0,0),
    fontSize=30,
    align="left",
  })

  gemsLabel.anchorX=0
  gemsLabel.anchorY=0
  money.anchorX=0
  money.anchorY=0
  gemsLabel:setFillColor(0)
  money:setFillColor(0)
  gemsLabel.x=20
  gemsLabel.y=20
  money.x=20
  money.y=20+gemsLabel.height+20

  Runtime:addEventListener("enterFrame",function(event)
    group:toFront()
    gemsLabel.text=gemsStr:format(get("gems") or 0,getSinceLastTrack("gems") or 0)
    money.text=moneyStr:format(get("money") or 0,getSinceLastTrack("money") or 0)
  end)
end
return M