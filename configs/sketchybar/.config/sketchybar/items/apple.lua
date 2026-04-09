local icons = require("icons")
local colors = require("colors")

local popup_toggle = "sketchybar --set $NAME popup.drawing=toggle"

local apple_logo = sbar.add("item", {
	padding_right = 15,
	click_script = popup_toggle,
	icon = {
		string = icons.apple,
		font = {
			style = "Black",
			size = 16.0,
		},
		color = colors.foreground,
	},
	label = {
		drawing = false,
	},
	popup = {
		height = 35,
	},
})

local apple_prefs = sbar.add("item", {
	position = "popup." .. apple_logo.name,
	icon = icons.preferences,
	label = "Preferences",
})

local lock_device = sbar.add("item", {
	position = "popup." .. apple_logo.name,
	icon = icons.lock,
	label = " Lock screen",
})

local reboot_device = sbar.add("item", {
	position = "popup." .. apple_logo.name,
	icon = icons.lock,
	label = " Reboot",
})

apple_prefs:subscribe("mouse.clicked", function(_)
	sbar.exec("open -a 'System Preferences'")
	apple_logo:set({ popup = { drawing = false } })
end)

lock_device:subscribe("mouse.clicked", function(_)
	sbar.exec("pmset displaysleepnow")
	apple_logo:set({ popup = { drawing = false } })
end)

reboot_device:subscribe("mouse.clicked", function(_)
	sbar.exec("osascript -e 'tell application \"System Events\" to restart'")
	apple_logo:set({ popup = { drawing = false } })
end)
