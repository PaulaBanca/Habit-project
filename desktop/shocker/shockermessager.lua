local M={}
shockermessager=M

local socket = require("socket")
local assert=assert
local print=print
local error=error
local pcall=pcall
local os=os
local timer=timer

setfenv(1,M)

local PORT=8888

local function connect()
  -- Connect to the client
  local client = assert(socket.connect("localhost", PORT))
  client:settimeout(10)
  -- Get IP and port from client
  local ip, port = client:getsockname()

  -- Print the IP address and port to the terminal
  print("IP Address:", ip)
  print("Port:", port)

  local function left()
    print ("sending left")
    local sent,status=client:send(1)
    if status then
      error(status)
    end
  end

  local function right()
    print ("sending right")
    local sent,status=client:send(2)
    if status then
      error(status)
    end
  end
  return left,right
end

local function attemptConnect(onConnect)
  local ok,left,right=pcall(connect)
  if ok then
    return onConnect(left,right)
  end
  timer.performWithDelay(500, function() attemptConnect(onConnect) end)
end

local isServerRunning=[[
for pid in $(pgrep arduino-serial-server); do
    if [ $pid != $$ ]; then
        echo "[$(date)] : arduino-serial-server.sh : Process is already running with PID $pid"
        exit 1
    fi
done
]]

function startServer(path,onConnect)
  local isRunning=os.execute(isServerRunning)
  if isRunning>0 then
    return attemptConnect(onConnect)
  end
  path=path:gsub("%s","\\ ")
  os.execute(path..(" -a /dev/$(ls /dev | grep tty.usbmodem) -p %d &"):format(PORT))
  timer.performWithDelay(1000,function() startServer(path,onConnect) end)
end

return M