local M = {}
zipdirectory = M

local zip = require("plugin.zip")
local lfs = require "lfs"

local os = os
local tostring = tostring
local system= system
local print = print

setfenv(1, M)

local function getFilesInDirectory()
	local files = {}
	local path = system.pathForFile("", system.DocumentsDirectory)
	local relPath = "" -- only required for files in subfolders
	for file in lfs.dir(path) do
		if not file:match("^%.") then
			files[#files + 1] =  relPath..file
		end
	end

	return files
end


function zipData(participantID,onComplete)
	local filename=("%s_%s_multipad_recall_data.zip"):format(tostring(participantID),os.date("%d-%m-%Y"))
	zip.compress({
		zipFile=filename,
		zipBaseDir=system.TemporaryDirectory,
		srcFiles=getFilesInDirectory(),
		srcBaseDir=system.DocumentsDirectory,
		listener=onComplete,
	})
	return filename
end

return M