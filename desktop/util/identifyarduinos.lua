local M={}
indentifyarduinos=M

local os=os
local jsonreader=require "util.jsonreader"

setfenv(1,M)

local createJSON=[[
rm tmp.json
echo "{" >> tmp.json
for f in $(ls /dev | grep tty.usbmodem); do
  a=$(./arduino-serial -b 9600 -p /dev/$f -r)
  for w in $a; do
    if [ $w == "Arduino-Controller" ] 
      then
        if [ $found == "true" ]
          then
            echo , >> tmp.json
        fi

        found=true
        echo "\"Arduino-Controller\": \"/dev/$f\"" >> tmp.json
        echo $f is the $w
        break
    fi
    if [ $w == "BIOPAC-Controller" ] 
      then
        if [ $found == "true" ]
          then
            echo , >> tmp.json
        fi

        found=true
        echo "\"BIOPAC-Controller\": \"/dev/$f\"" >> tmp.json
        echo $f is the $w
        break
    fi
  done
done
echo "}" >> tmp.json
chmod 777 tmp.json
]]


function createControllerTable(path)
  local safePath=path
  path=path:gsub("%s","\\ ")
  os.execute("cd " .. path .. "; "..  createJSON)
  return jsonreader.load(safePath .."/tmp.json")
end

return M