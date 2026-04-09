local colors = require("colors")

local caffeinate = sbar.add("item", {
	icon = {
		string = "􀸙",
		color = colors.orange,
		font = {
			size = 16.0,
		},
	},
	position = "right",
})

function check_is_active(callback)
	sbar.exec("pgrep -x 'caffeinate'", function(result)
		local is_caffeinate_active = trim(result) ~= ""
		callback(is_caffeinate_active)
	end)
end

caffeinate:subscribe("mouse.clicked", function()
	check_is_active(function(is_active)
		if is_active then
			sbar.exec("killall caffeinate")
		else
			sbar.exec("caffeinate -di & disown")
		end

		if is_active then
			caffeinate:set({ icon = { string = "􀸘", color = colors.foreground } })
		else
			caffeinate:set({ icon = { string = "􀸙 ", color = colors.yellow } })
		end
	end)
end)

check_is_active(function(is_active)
	if is_active then
		caffeinate:set({ icon = { string = "􀸙 ", color = colors.yellow } })
	else
		caffeinate:set({ icon = { string = "􀸘", color = colors.foreground } })
	end
end)
