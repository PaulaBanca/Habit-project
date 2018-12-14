local M={}
tunegenerator=M

local math=math
local print=print
local table=table
local _=require "util.moses"
local serpent=require "serpent"
local NUM_KEYS = NUM_KEYS

setfenv(1,M)

local badCombos={
  {false,true,false,true},
  {true,false,true,true},
  {true,true,false,true},
}

local iters={}

for i=1, NUM_KEYS-1 do
  iters[i] = _.permutation(_.append(_.rep(true, NUM_KEYS-i),_.rep(false,i)))
end

local allCombos={}
for i=1,#iters do
  for nextPermutation in iters[i] do
    allCombos[#allCombos+1]=_.clone(nextPermutation)
  end
end

if NUM_KEYS<4 then
  badCombos = {}
end

allCombos=_(allCombos):unique():difference(badCombos):value()
local summary=_.rep(0,NUM_KEYS)
for i=1, #allCombos do
  local t=allCombos[i]
  for k=1,#t do
    summary[k]=summary[k]+(t[k] and 1 or 0)
  end
end

local allCombosByFingers=_.groupBy(allCombos,function(i,value)
  return _.count(value,true)
end)

local notes={
  "a","b","c","d","e","f","g"
}
local pitches={"3","4"}
function createStep(keys)
  local simultaneous=_.count(keys,true)
  local noteIndicies={}
  local root=math.random(#notes)
  noteIndicies[1]=root
  for i=2,simultaneous do
    noteIndicies[i]=(noteIndicies[i-1]+1)%#notes+1
  end
  local lastPitch=math.random(#pitches)
  local notes=_.map(noteIndicies,function(_,v)
    local pitch=pitches[lastPitch]
    local nextPitch=math.random(#pitches)
    lastPitch=nextPitch>lastPitch and nextPitch or lastPitch
    return notes[v]..pitch
  end)

  local step={
    chord=_.map(keys,function(_,v)
      if not v then
        return "none"
      end
      return table.remove(notes,1)
    end),
    forceLayout=true
  }
  return step
end

function generateTouchStructure(recipe)
  local structure=_.rep(1,recipe.length)
  if recipe.multipleTouches then
    local options=_.range(1,recipe.length)
    for i=1,#recipe.multipleTouches do
      local touches=recipe.multipleTouches[i]
      local place=table.remove(options,math.random(#options))
      structure[place]=touches
    end
  end
  return structure
end

function create(recipe)
  recipe=_.clone(recipe)
  local optionsByFingers=_.map(allCombosByFingers,function(k,v)
    return _.range(1,#v)
  end)
  local tune={}
  local summary=_.rep(0,NUM_KEYS)
  local hash=0
  local structure=generateTouchStructure(recipe)
  for i=1, recipe.length do
    local touches=structure[i]
    local options=optionsByFingers[touches]
    local opts=math.random(#options)
    local value=table.remove(options,opts)
    local keys=allCombosByFingers[touches][value]
    for k=1,#keys do
      hash=hash+(keys[k] and (2^(i+k)) or 0)
      summary[k]=summary[k]+(keys[k] and 1 or 0)
    end
    tune[i]=createStep(keys)
  end
  for i=1,NUM_KEYS do
    if summary[i]==0 then
      return create(recipe)
    end
  end
  return tune
end

return M