--calculate the aspect ratio of the device
local aspectRatio = display.pixelHeight / display.pixelWidth
application = {
   content = {
      scale = "adaptive",
      fps = 30,

      imageSuffix = {
         ["@2x"] = 1.3,
      },
   },
}