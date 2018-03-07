local M={}
versionoptions=M

local composer=require "composer"
local counterbalanceoptions=require "options.counterbalanceoptions"
local recalloptions=require "options.recalloptions"

setfenv(1,M)

function create()
  local options={
    {label="Version",options={"Test","Recall","Long Recall"},selectFunc=function(v)
      local options
      local nextScene
      if v=="Recall" then
        options=recalloptions.create()
        nextScene="scenes.recalltest"
      elseif v=="Test" then
        options=counterbalanceoptions.create()
        nextScene="scenes.practiceintro"
      else 
        options=recalloptions.create()
        nextScene="scenes.longrecall"
      end

      composer.gotoScene("scenes.optionsmenu",{
        params={
          options=options,
          nextScene=nextScene
        }
      })
    end},
  }
  return options
end

return M
