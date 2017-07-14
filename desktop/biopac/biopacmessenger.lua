local M={}
biopacmessenger=M

local arduinoclient=require "util.arduinoclient"

setfenv(1,M)

local PORT=8889

function connect(path,device,onConnect)
  arduinoclient.startServer(path,device,PORT,function(sendValue)
    onConnect(sendValue)
  end)
end

return M