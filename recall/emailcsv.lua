local M={}
emailcsv=M

local i18n = require ("i18n.init")
local io=io
local native=native
local system=system
local assert=assert
local os=os
local tostring=tostring

local zipdirectory = require ("zipdirectory")

setfenv(1,M)

function send(userid)
	if not native.canShowPopup("mail") then
		native.showAlert(
			i18n("email.notsupported.title"),
			i18n("email.notsupported.message"),
			{i18n("buttons.ok")})
		return
	end

	native.setActivityIndicator(true)
	local filename
	filename = zipdirectory.zipData(userid, function()
		native.setActivityIndicator(false)
		local options = {
			to = {""},
			cc = {""},
			subject = "Multipad Recall - Data " .. os.date(),
			isBodyHtml = true,
			body = ("<html><body>The results for user <b>%s</b>.</body></html>"):format(tostring(userid)),
			attachment = {
				baseDir=system.TemporaryDirectory, filename=filename, type="application/zip"
			},
		}
		native.showPopup("mail", options)
	end)
end

return M