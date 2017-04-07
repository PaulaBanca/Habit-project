local M={}
tunes=M

local tunegenerator=require "tunegenerator"
local keylayout=require "keylayout"
local _=require "util.moses"
local math=math
local type=type
local table=table
local NUM_KEYS=NUM_KEYS
local print=print

setfenv(1,M)

local simpleSequences=false

local config
function generateTunes()
  local function findLongestOverlap(a,b)
    local longest=0
    for offset=-#a+1,0 do
      local streak=0
      for i=1,#b do
        local bkeys=b[i]
        local akeys=a[(offset+i)%#a+1]
        if _.sameKeys(akeys,bkeys) then
          streak=streak+1
          longest=math.max(streak,longest)
        else
          streak=0
        end
      end
    end
    return longest
  end

  local function passesTest(tuneKeys)
    for i=1, #tuneKeys do
      local keys=tuneKeys[i]
      for k=i+1, #tuneKeys do
        local overlap=findLongestOverlap(keys,tuneKeys[k])
        if overlap>1 then
          return false
        end
      end
    end
    return true
  end

  local recipe={
    length=6,
    multipleTouches={2,2,2,3}
  }

  while true do
    config={}
    local tuneKeys={}
    for i=1,3 do
      local instructions=tunegenerator.create(recipe)
      config[i]={tune=instructions,stimulus=i}

      keylayout.reset()
      local keys={}
      for k=1, #instructions do
        keys[k]=keylayout.layout(instructions[k])
      end
      tuneKeys[i]=keys
    end

    if passesTest(tuneKeys) then
      break
    end
  end

  if simpleSequences then
    config[1]={
        stimulus=1,
        tune={
          {chord={"c4","none","none","none"},forceLayout=true},
          {chord={"c4","none","none","none"},forceLayout=true},
          {chord={"c4","none","none","none"},forceLayout=true},
          {chord={"c4","none","none","none"},forceLayout=true},
          {chord={"c4","none","none","none"},forceLayout=true},
          {chord={"c4","none","none","none"},forceLayout=true},
      }
    }
    config[2]={
        stimulus=2,
        tune={
          {chord={"none","c4","none","none"},forceLayout=true},
          {chord={"none","c4","none","none"},forceLayout=true},
          {chord={"none","c4","none","none"},forceLayout=true},
          {chord={"none","c4","none","none"},forceLayout=true},
          {chord={"none","c4","none","none"},forceLayout=true},
          {chord={"none","c4","none","none"},forceLayout=true},
      }
    }
  end
  config[4]={tune=_.first(config[1].tune,5),stimulus=1}
  config[5]={tune=_.first(config[2].tune,5),stimulus=2}
end

local maxLength=6
function setMaxLength(len)
  maxLength=len
end

local function createClippedCopy(tune)
  local clipped={}
  for i=1, math.min(#tune,maxLength) do
    clipped[i]=tune[i]
  end
  return clipped
end

function getTunes()
  local tunes={}
  for i=1,#config do
    tunes[i]=createClippedCopy(config[i].tune)
  end
  return tunes
end

function getStimulus(song)
  for i=1,#config do
    local match=true
    for k=1,#song do
      if config[i].tune[k]~=song[k] then
        match=false
        break
      end
    end
    if match then
      return config[i].stimulus
    end
  end
end

function getMaxSequenceLength()
  local selected=getTunes()
  local len=0
  for i=1, #selected do
    len=math.max(len,#selected[i])
  end

  return len
end

local function matchesSong(song,sequence)
  local start=#sequence-#song
  for i=1, #song do
    local sequenceNotes=sequence[i+start]
    if not sequenceNotes then
      return false
    end
    table.sort(sequenceNotes)

    local notes=song[i]
    if type(notes)=="string" then
      notes={notes}
    else
      table.sort(notes)
    end
    for j=1,#notes do 
      if notes[j]~=sequenceNotes[j] then
        return false
      end
    end
  end
  return true
end

function isSong(sequence)
  local selected=getTunes()
  for i=1, #selected do
    local song=selected[i]
    if matchesSong(song,sequence) then
      return i
    end
  end
end

function printKeys()
  local function keyPattern(instruction)
    local pattern={}
    for i=1, NUM_KEYS do
      pattern[i]=instruction[i]~="none" and (instruction.invert and "#" or "X") or "_"
    end
    return table.concat(pattern, "")
  end

  _.eachi(config,function(k,v)
     print (_(v.tune):map(function(k,v) return keyPattern(v.chord) end):concat(" "):value())
  end)
end

return M