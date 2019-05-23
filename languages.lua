local M = {}
languages = M

local lfs = require ("lfs")
local i18n = require ("i18n.init")
local jsonreader = require ("jsonreader")
local system = system
local require = require
local assert = assert
local print = print

setfenv(1,M)

local path = system.pathForFile("lang",system.ResourceDirectory)
assert(path, "languages.lua: No path found")
local langs = {}

for file in lfs.dir(path) do
	if file:match("json$") then
		local langName = file:sub(1,-6)
		print(langName, file)
		langs[#langs + 1] = langName
		i18n.load(jsonreader.load(path.."/"..file))
	end
end

function getLanguages()
	return langs
end

return M