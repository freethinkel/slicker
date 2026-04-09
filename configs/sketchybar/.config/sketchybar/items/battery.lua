local icons = require("icons")
local colors = require("colors")

local battery = sbar.add("item", {
	position = "right",
	icon = {
		font = {
			style = "Regular",
			size = 19.0,
		},
	},
	label = {
		drawing = false,
		string = icons.battery.plug,
		padding_left = -22,
		y_offset = 1,
		font = {
			size = 12,
		},
	},
	update_freq = 120,
})

local function battery_update()
	sbar.exec("pmset -g batt", function(batt_info)
		local icon = "!"

		local is_charging = string.find(batt_info, "AC Power") ~= nil

		battery:set({
			label = {
				drawing = is_charging,
			},
		})

		local found, _, charge = batt_info:find("(%d+)%%")
		if found then
			charge = tonumber(charge)
		end

		if found and charge > 80 then
			icon = icons.battery._100
		elseif found and charge > 60 then
			icon = icons.battery._75
		elseif found and charge > 40 then
			icon = icons.battery._50
		elseif found and charge >= 20 then
			icon = icons.battery._25
		else
			icon = icons.battery._0
		end

		local color = colors.foreground
		if is_charging then
			color = charge > 20 and colors.green or colors.red
		end

		battery:set({ icon = { color = color } })

		battery:set({ icon = icon })
	end)
end

battery:subscribe({ "routine", "power_source_change", "system_woke" }, battery_update)
