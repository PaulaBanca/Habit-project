local M = {}
languages = M

local lfs = require ("lfs")
local i18n = require ("i18n.init")
local system = system
local require = require

setfenv(1,M)

local path = system.pathForFile("lang",system.ResourceDirectory)
local langs = {}

for file in lfs.dir(path) do
	if file:match("lua$") then
		local langName = file:sub(1,-5)
		langs[#langs + 1] = langName
		i18n.load(require ("lang."..langName))
	end
end

function getLanguages()
	return langs
end

return M