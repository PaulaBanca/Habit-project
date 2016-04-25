local M={}
tunes=M

local math=math
local type=type
local table=table
local system=system
local tunegenerator=require "tunegenerator"

setfenv(1,M)

local short1={
   "a4",
  {chord={"e4","a3"}},
  "g4",
  "c3",
  {chord={"none","none","e4","c3"},forceLayout=true},
  {chord={"c4","a4","f4","none"},forceLayout=true},
}

local short2={
  {chord={"c4","g4"}},
  "f4",
  {chord={"none","a4","f4","c3"},forceLayout=true},
  "a4",
  {chord={"d4","none","none","g4"},forceLayout=true},
  "c4"
}

local short3={
  "f4",
  {chord={"none","f4","a4","c3"},forceLayout=true},
  {chord={"d4","none","b4","none"},forceLayout=true},
  "a4",
  "g4",
  {chord={"c4","g4"}},
}

local recipe={
  length=6,
  multipleTouches={2,2,3}
}
local config={
  {tune=tunegenerator.create(recipe),stimulus=1},
  {tune=tunegenerator.create(recipe),stimulus=2},
  {tune=tunegenerator.create(recipe),stimulus=3},
}

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

return M