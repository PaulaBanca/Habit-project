local M={}
clientloop=M

local socket=require "socket"
local json=require "json"
local ipairs=ipairs
local pairs=pairs
local print=print
local timer=timer
local table=table 

setfenv(1,M)

function connectToServer(ip, port)
  local sock, err = socket.connect( ip, port )
  if sock == nil then
    return false
  end
  sock:settimeout( 0 )
  sock:setoption( "tcp-nodelay", true )  --disable Nagle's algorithm
  print (sock:send( "we are connected\n" ))

  return sock
end

local buffer = {}
function createClientLoop(server)
  local clientPulse
  local sock=connectToServer(server.ip,server.port)

  local function cPulse()
    local allData = {}
    local data, err

    repeat
      if not sock then
        sock=connectToServer(server.ip,server.port)
      end
      if sock then
        data, err = sock:receive()
      end
      if data then
        allData[#allData+1] = data
      end
      if err == "closed" and clientPulse then  --try again if connection closed
        sock=nil
      end
    until not data and sock

    if #allData>0 then
      for i, thisData in ipairs(allData) do
        print( "thisData: ", thisData )
      --react to incoming data 
      end
    end

    for i=1,#buffer do
      local msg=buffer[i]
      local data, err = sock:send(msg)
      print ("send",msg,data,err)
      if (err == "closed" and clientPulse) then  --try to reconnect and resend
        sock=connectToServer(server.ip,server.port)
        data, err = sock:send(msg )
      end
    end
    buffer={}
  end

  --pulse 10 times per second
  clientPulse = timer.performWithDelay( 100, cPulse, 0 )

  local function stopClient()
    timer.cancel( clientPulse )  --cancel timer
    clientPulse = nil
    sock:close()
  end
  return stopClient
end

function start(server)
  local stop=createClientLoop(server)
end

function sendEvent(event)
  buffer[#buffer+1]=json.encode(event).."\n"
end

return M