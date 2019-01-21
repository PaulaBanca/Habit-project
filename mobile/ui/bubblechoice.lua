local bubblechoice = {}

function bubblechoice.create(params, onSelect)
	local options = params.labels

	local left = -params.width/2
	local right = params.width/2

	local buttonSize = params.labelSize
	local step = (params.width - buttonSize)/(#options - 1)

	local group = display.newGroup()

	local line = display.newLine(group, left, 0, right, 0)
	line:setStrokeColor(unpack(params.labelStrokeColour or {1}))
	line.strokeWidth = params.lineStrokeWidth or 0

	for i=1, #options do
		local x = left + buttonSize/2 + step * (i-1)
		local customImg = type(options[i]) == "table"
		local button
		if customImg then
			button = display.newImage(group, options[i].img, x, 0)
			button.width = buttonSize
			button.height = buttonSize
			line.isVisible = false
		else
			button = display.newCircle(group, x, 0, buttonSize/2)
			button:setFillColor(unpack(params.labelColour or {1}))
			button:setStrokeColor(unpack(params.labelStrokeColour or {1}))
			button.strokeWidth = params.labelStrokeWidth or 0
		end
		local text = customImg and options[i].label or options[i]

		local label = display.newText({
			parent = group,
			text = text,
			fontSize = params.labelFontSize or 10,
			align = "center",
			x = button.x,
			y = customImg and button.y + buttonSize/2 + 10 or button.y,
			width = buttonSize - 10
		})

		label:setFillColor(unpack(params.labelTextColour or {0}))

		local index = i
		function button:tap()
			onSelect(i, text)
			return true
		end
		button:addEventListener("tap")
	end

	return group
end

return bubblechoice