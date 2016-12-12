local M={}
user=M

local jsonreader=require "jsonreader"
local system=system
local display=display
local native=native
local print=print
local math=math
local os=os
local table=table

setfenv(1,M)

local path=system.pathForFile("user.json",system.DocumentsDirectory)
local data=jsonreader.load(path)

local chars={[[ ]],[[!]],[[#]],[[$]],[[%]],[[&]],[[(]],[[)]],[[*]],[[+]],[[-]],[[.]],[[0]],[[1]],[[2]],[[3]],[[4]],[[5]],[[6]],[[7]],[[8]],[[9]],[[:]],[[;]],[[<]],[[>]],[[?]],[[A]],[[B]],[[C]],[[D]],[[E]],[[F]],[[G]],[[H]],[[I]],[[J]],[[K]],[[L]],[[M]],[[N]],[[O]],[[P]],[[Q]],[[R]],[[S]],[[T]],[[U]],[[V]],[[W]],[[X]],[[Y]],[[Z]],[[[]],[[^]],[[_]],[[`]],[[a]],[[b]],[[c]],[[d]],[[e]],[[f]],[[g]],[[h]],[[i]],[[j]],[[k]],[[l]],[[m]],[[n]],[[o]],[[p]],[[q]],[[r]],[[s]],[[t]],[[u]],[[v]],[[w]],[[x]],[[y]],[[z]],[[{]],[[|]],[[}]]}
function generatePassword()
  math.randomseed(os.time()+system.getTimer())
  local password={}
  for i=1, 50 do 
    password[i]=chars[math.random(#chars)]
  end

  return table.concat(password,"")
end

function setup(whenDone,force)
  if data and not force then
    return whenDone()
  end

  local instruction=display.newText({
    text="Enter the User ID",
    fontSize=48,
  })
  instruction:translate(display.contentCenterX, display.contentCenterY-100)

  local textField
  local function textListener(event)
    if event.phase == "submitted" then
      local text=textField.text
      local function onComplete( event )
        if event.action == "clicked" then
          local i = event.index
          if i == 1 then
            return setup(whenDone,force)
          elseif i == 2 then
            data={id=text,password=generatePassword()}
            jsonreader.store(path,data)
            whenDone(true)
          end
        end
      end

      -- Show alert with two buttons
      local alert = native.showAlert("Confirm", "Set User ID to " .. text .. ". All data will logged against this id", { "Cancel", "Okay" }, onComplete )

      instruction:removeSelf()
      textField:removeSelf()
    end
  end

 
  textField = native.newTextField(display.contentCenterX, display.contentCenterY-40, display.contentWidth-20, 50)

  textField:addEventListener("userInput", textListener)
end

function getID()
  return data and data.id or (system.getInfo("environment")=="simulator" and "test")
end

function getPassword()
  return data.password
end

function store(k,v)
  data[k]=v
  jsonreader.store(path,data)
end

function get(k)
  return data[k]
end

return M