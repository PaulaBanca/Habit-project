local M = {}
detectdata = M

local lfs = require ("lfs")
local system = system

setfenv(1, M)

function hasDataFiles()
	local path = system.pathForFile("", system.DocumentsDirectory)
	for file in lfs.dir(path) do
		if file:match("%.csv") then
			return true
		end
	end

	return false
end

return M

