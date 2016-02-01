local M={}
stimuli=M

local display=display

setfenv(1,M)

local img={
  "img/stimuli/1.png",
  "img/stimuli/2.png",
  "img/stimuli/3.png",
  "img/stimuli/4.png"
}

function getStimulus(n)
  return display.newImage(img[n])
end

return M