local M={}
client=M

local socket=require "socket"
local appconfig=require "appconfig"
local print=print
local timer=timer
local ipairs=ipairs
local pairs=pairs
local assert=assert

setfenv(1,M)

function getIP()
  local s = socket.udp()  --creates a UDP object
  s:setpeername( "74.125.115.104", 80 )  --Google website
  local ip, sock = s:getsockname()
  return ip
end

function findServer(whenDone)
  local msg = "AwesomeGameServer"

  local listen = socket.udp()
  assert(listen:setsockname(appconfig.multicastAddress, 11111))  --this only works if the device supports multicast

  local name = listen:getsockname()
  if ( name ) then  --test to see if device supports multicast
    assert(listen:setoption( "ip-add-membership", { multiaddr=appconfig.multicastAddress, interface = getIP() } ))
  else  --the device doesn't support multicast so we'll listen for broadcast
    listen:close()  --first we close the old socket; this is important
    listen = socket.udp()  --make a new socket
    listen:setsockname( getIP(), 11111 )  --set the socket name to the real IP address
  end

  listen:settimeout( 0 )  --move along if there is nothing to hear

  local stop
  local server
  local function look(event)
    repeat
      local data, ip, port = listen:receivefrom()
      if data and data == msg then
        server = { ip=ip, port=22222 }
        stop()
        return
      end
    until not data

    if event.count==80 then  --stop after 2 seconds
      stop()
    end
  end

   --pulse 10 times per second
  local beginLooking = timer.performWithDelay(100, look, 80)

  stop=function()
    timer.cancel( beginLooking )
    listen:close()  --never forget to close the socket!
    whenDone(server)
  end
  return stop
end

return M