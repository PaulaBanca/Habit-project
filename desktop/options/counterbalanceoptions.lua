local M={}
counterbalanceoptions=M

local composer=require "composer"

setfenv(1,M)

function create()
  composer.setVariable("preferencetest",{})

  local function setSwitch(index,v)
    local opts=composer.getVariable("preferencetest")
    opts[index]={switch=v=="Yes"}
    composer.setVariable("preferencetest",opts)
  end

  local options={
    {label="Practice Order",options={"A","B"},selectFunc=function(v)
      composer.setVariable("firstpractice", v=="A" and 1 or 2)
      composer.setVariable("secondpractice", v=="A" and 2 or 1)
    end},
    {label="Switch sides - Preference 1",options={"No","Yes"},selectFunc=function(v) setSwitch(1,v) end},
    {label="Switch sides - Preference 2",options={"No","Yes"},selectFunc=function(v) setSwitch(2,v) end},
    {label="Switch sides - Preference 3",options={"No","Yes"},selectFunc=function(v) setSwitch(3,v) end},
    {label="Switch sides - Preference 4",options={"No","Yes"},selectFunc=function(v) setSwitch(4,v) end},
    {label="Switch sides - Preference 5",options={"No","Yes"},selectFunc=function(v) setSwitch(5,v) end},
    {
      label="Preferred Shocks",
      options={"Left","Right"},
        selectFunc=function(v) composer.setVariable("shockerpreferred",v)
      end
    },
    {
      label="Handedness",
      options={"Left","Right"},
      selectFunc=function(v) composer.setVariable("left handed",v=="Left") end,
      debugSelection=2
    },
  }
  return options
end

return M
