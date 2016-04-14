local M={}
tunes=M

local math=math
local type=type
local table=table
local system=system

setfenv(1,M)

local paula={
  "a3",
  {chord={"c4","d4","a4"}},
  "d4",
  {chord={"c4","d4","g4"}},
  {chord={"d4","g4"}},
  {chord={ "c4","d4","a4"}},
  "c5",
  {chord={"d4","b5"}}, --octave on one
  {chord={"a5","b5"}},-- octave on all
  "g4",
  "b5", -- octave
  {chord={"d4","g4","b4"}}
}
local twinkle={
  "c4", "c4", "g4", "g4", "a4", "a4", "g4", "f4", "f4", "d4", "d4", "d4", "d4", "c4",
}
local morning={
  "g4","d4","d4","c4","d4","d4","g4","d4","d4","c4","d4","d4","d4","d4","g4","d4","g4","a4","d4","a4","g4","d4","d4","c4"
}

local gotter={
  {chord={"d4","c3"}},
  "d4",
  "f4",
  "g4",
  {chord={"g4","g3"}},
  "f4",
  "d4",
  "d4",
  {chord={"c4","c3"}},
  "c4",
  "d4",
  "d4",
  {chord={"d4","g3"}},
  "d4",
  "d4",
  
 }

local paula2={
  "a3",
  {chord={"a3","c4","e4"}},
  "d4",
  {chord={"c4","e4"}},
  {chord={"e4","g4"}},
  {chord={"e3","a3","c4","e4"}},
  "c5",
  {chord={"e4","b5"}},
  {chord={"a5","b5"}},
  "g4",
  "b5",
  {chord={"e3","e4","g4"}}
} 

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


local config={
  {tune=short1,stimulus=1},
  {tune=short2,stimulus=2},
  {tune=short3,stimulus=3},
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