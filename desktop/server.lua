local M={}
server=M

local socket=require "socket" 
local json=require "json"
local events=require "events"
local print=print
local timer=timer
local pairs=pairs
local ipairs=ipairs
local error=error

setfenv(1,M)

local clientList = {}
local clientBuffer = {}

function getIP()
  local s = socket.udp()
  s:setpeername( "74.125.115.104", 80 )
  local ip, sock = s:getsockname()
  print( "myIP:", ip, sock )
  return ip
end

function advertiseServer(whenDone)
  local send = socket.udp()

  local stop
  local function broadcast(event)
    print ("Broadcasting")
    local msg = "AwesomeGameServer"
    --multicast IP range from 224.0.0.0 to 239.255.255.255
    send:sendto( msg, "226.192.1.1", 11111 )
    --not all devices can multicast so it's a good idea to broadcast too
    --however, for broadcast to work, the network has to allow it
    send:setoption( "broadcast", true )  --turn on broadcast
    send:sendto( msg, "255.255.255.255", 11111 )
    send:setoption( "broadcast", false )  --turn off broadcast

    if (event.count==80) then  --stop after 8 seconds
      stop()
    end
  end

  --pulse 10 times per second
  local serverBroadcast = timer.performWithDelay(100, broadcast, 80)

  stop = function()
    timer.cancel(serverBroadcast)  --cancel timer
    whenDone()
  end
  return stop
end

local function handleData(event)
  if not event or not event.type then
    return
  end
  events.fire(event)
end

function create(hasClient)
  local tcp, err = socket.bind("*" or getIP(), 22222)  --create a server object
  if err then
    error(err)
  end
  tcp:settimeout(0)

  local function sPulse()
    repeat
      local client = tcp:accept()  --allow a new client to connect
      if client then
        client:settimeout(0)  --just check the socket and keep going
        --TO DO: implement a way to check to see if the client has connected previously
        --consider assigning the client a session ID and use it on reconnect.
        clientList[#clientList+1] = client
        clientBuffer[client] = { "hello_client\n" }  --just including something to send below
        hasClient(true)
      end
    until not client

    local ready, writeReady, err = socket.select(clientList, clientList, 0)
    if not err then
      for i = 1, #ready do  --list of clients who are available
        local client = ready[i]
        local allData = {}  --this holds all lines from a given client

        while true do
          local data, err = client:receive()  --get a line of data from the client, if any
          if data then
            allData[#allData+1] = data
          else
            break
          end
        end

        if (#allData > 0) then  --figure out what the client said to the server
          for i, thisData in ipairs( allData ) do
            handleData(json.decode(thisData))
          end
        end
      end

      for sock, buffer in pairs(clientBuffer) do
        for _, msg in pairs( buffer ) do  --might be empty
          local data, err = sock:send(msg)  --send the message to the client
        end
        clientBuffer[sock]={}
      end
    end
  end

  local serverPulse = timer.performWithDelay(1000/10, sPulse,-1)

  local function stopServer()
    timer.cancel(serverPulse)  --cancel timer
    tcp:close()
    for i, v in pairs(clientList) do
      v:close()
    end
  end
  return stopServer
end

return M