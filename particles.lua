local M={}
particles=M

local json=require "json"
local system=system
local io=io

setfenv(1,M)

function load(name)
  -- Read the exported Particle Designer file (JSON) into a string
  local filePath = system.pathForFile("particles/"..name..".json")
  local f = io.open(filePath,"r")
  local fileData=f:read("*a")
  f:close()

  return json.decode(fileData)
end

return M