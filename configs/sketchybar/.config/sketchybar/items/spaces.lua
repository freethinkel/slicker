local colors = require("colors")

local handle = io.popen("yabai -m query --spaces | jq -r '.[].index'")
local result = handle:read("*a")
handle:close()

for index_str in result:gmatch("%S+") do
	local key = tonumber(index_str)
	if key then
		local space = sbar.add("space", "space." .. key, {
			associated_space = key,
			icon = {
				string = key .. "",
				padding_left = 6,
				padding_right = 6,
				color = colors.foreground,
				highlight_color = colors.accent,
			},
			padding_left = 2,
			padding_right = 2,
		})

		space:subscribe("space_change", function(env)
			sbar.set(env.NAME, {
				icon = { highlight = env.SELECTED == "true" },
			})
		end)

		space:subscribe("mouse.clicked", function()
			sbar.exec("yabai -m space --focus " .. key)
		end)
	end
end
