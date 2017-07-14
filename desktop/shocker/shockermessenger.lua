local M={}
shockermessenger=M

local arduinoclient=require "util.arduinoclient"

setfenv(1,M)

local LEFT=1
local RIGHT=2
local PORT=8888

function connect(path,device,onConnect)
  arduinoclient.startServer(path,device,PORT,function(sendValue)
    onConnect(function() sendValue(LEFT) end,
              function() sendValue(RIGHT) end)
  end)
end

return M