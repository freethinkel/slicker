local vpn = "e.kolesnikov"

local colors = require("colors")
local is_connected = false

local tunnelblick = sbar.add("item", {
	icon = {
		string = "􀆪",
		color = colors.foreground,
		font = {
			size = 16.0,
		},
	},
	position = "right",
	update_freq = 10,
})

function check_connection()
	local script =
		'osascript -e \'tell application "Tunnelblick" to get state of first configuration where name = "vpn"\''
	script = string.gsub(script, "vpn", vpn)

	sbar.exec(script, function(result)
		if result:match("CONNECTED") then
			is_connected = true
			tunnelblick:set({ icon = { string = "􀆪", color = colors.green } })
		else
			is_connected = false
			tunnelblick:set({ icon = { string = "􀆪", color = colors.red } })
		end
	end)
end

tunnelblick:subscribe("mouse.clicked", function(env)
	local action = is_connected and "disconnect" or "connect"
	local script = 'osascript -e \'tell application "Tunnelblick" to __action__ "vpn"\''

	script = string.gsub(script, "vpn", vpn)
	script = string.gsub(script, "__action__", action)

	sbar.exec(script, function(result)
		is_connected = action == "connect" and true or false

		tunnelblick:set({ icon = { string = "􀆪", color = is_connected and colors.red or colors.red } })
	end)
end)

tunnelblick:subscribe("routine", function()
	check_connection()
end)

check_connection()
