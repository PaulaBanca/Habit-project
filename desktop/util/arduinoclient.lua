local M={}
arduinoclient=M

local socket = require("socket")
local assert=assert
local print=print
local error=error
local pcall=pcall
local os=os
local timer=timer

setfenv(1,M)

local function connect(port)
  -- Connect to the client
  local client = assert(socket.connect("localhost", port))
  client:settimeout(10)
  -- Get IP and port from client
  local ip, port = client:getsockname()

  -- Print the IP address and port to the terminal
  print("IP Address:", ip)
  print("Port:", port)

  local function sendValue(v)
    local sent,status=client:send(v)
    if status then
      error(status)
    end
  end

  return sendValue
end

local function attemptConnect(port,onConnect)
  local ok,sendValue=pcall(connect,port)
  if ok then
    return onConnect(sendValue)
  end
  timer.performWithDelay(500, function() attemptConnect(port,onConnect) end)
end

local isServerRunning=[[
for pid in $(pgrep -f arduino-serial-server.+%s); do
    if [ $pid != $$ ]; then
        echo "[$(date)] : arduino-serial-server.sh : Process is already running with PID $pid"
        exit 1
    fi
done
]]

function startServer(path,device,port,onConnect)
  local cmd=isServerRunning:format(device)
  local isRunning=os.execute(cmd)
  if isRunning>0 then
    return attemptConnect(port,onConnect)
  end
  path=path:gsub("%s","\\ ")
  local startServerShellCmd=path..(" -a %s -p %d &"):format(device,port)
  os.execute(startServerShellCmd)
  timer.performWithDelay(1000,function()
    startServer(path,device,port,onConnect)
  end)
end

return M