local M={}
stimuli=M

local display=display

setfenv(1,M)

local img={
  "img/stimuli/1.png",
  "img/stimuli/2.png",
  "img/stimuli/3.png",
}

local wildImg={
  [3]="img/stimuli/wildcard3.png",
  [6]="img/stimuli/wildcard6.png",
}

function getStimulus(n)
  return display.newImage(img[n])
end

function getWildcardSimuli(presses)
  return display.newImage(wildImg[presses])
end

return M