local composer=require "composer"
local scene=composer.newScene()
local button = require ("ui.button")
local i18n = require ("i18n.init")
local languages = require ("languages")
local stimuli = require ("stimuli")
local _ = require ("util.moses")
local user=require "user"
local display=display
local system=system
local ipairs = ipairs

setfenv(1,scene)

function scene:create()
  local instruction=display.newText({
    parent=self.view,
    text=i18n("eeg.sequence"),
    fontSize=48,
  })
  instruction:translate(display.contentCenterX, display.contentCenterY-100)

  local group=display.newGroup()
  self.view:insert(group)
  local sequences = _.shuffle({1,2})
  for i=1, 2 do
    local s=stimuli.getStimulus(sequences[i])
    group:insert(s)
    s:scale(0.5,0.5)
    s.y=display.contentCenterY
    local offset = i * 2 - 3
    s.x=display.contentCenterX+(s.contentWidth+50)*offset
  end

  local left,right
  function close()
    group:removeSelf()
    left:removeSelf()
    right:removeSelf()
    composer.gotoScene("scenes.intro")
  end
  left=button.create(i18n("buttons.select"),"use",function()
    user.store("preferred",sequences[1])
    close()
  end)
  right=button.create(i18n("buttons.select"),"use",function()
    user.store("preferred",sequences[2])
    close()
  end)
  left.y=group[1].y+group[1].contentHeight/2+20+left.height/2
  left.x=display.contentCenterX-left.width/2-20
  right.y=left.y
  right.x=display.contentCenterX+right.width/2+20
  self.view:insert(left)
  self.view:insert(right)
end
scene:addEventListener("create")

return scene