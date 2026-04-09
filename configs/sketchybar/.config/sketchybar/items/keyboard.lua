local keyboard = sbar.add("item", {
	icon = {
		string = "􀂕",
		font = {
			size = 16.0,
		},
	},
	position = "right",
	-- y_offset = 2,
	update_freq = 2,
})

local update = function()
	sbar.exec(
		"defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | grep 'KeyboardLayout Name'",
		function(result)
			local layout = trim(result)
			layout = string.gsub(layout, '"KeyboardLayout Name" = ', "")
			layout = string.gsub(layout, ";", "")
			layout = trim(layout)

			local icon = ""
			if layout == "ABC" then
				icon = "􀂕"
			elseif layout == "RussianWin" then
				icon = "􀂳"
			end
			keyboard:set({ icon = icon })
		end
	)
end

keyboard:subscribe("routine", update)
-- keyboard:subscribe("forced", update)
