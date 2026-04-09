local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
sbar.default({
	updates = "when_shown",
	icon = {
		font = {
			family = settings.font,
			style = "Bold",
			size = 14.0,
		},
		color = colors.foreground,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	label = {
		font = {
			family = settings.font,
			style = "Semibold",
			size = 13.0,
		},
		color = colors.foreground,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	background = {
		height = 24,
		corner_radius = 3,
		border_width = 0,
	},
	popup = {
		background = {
			border_width = 2,
			corner_radius = 9,
			border_color = colors.popup_border,
			color = colors.popup_background,
			shadow = { drawing = true },
		},
		blur_radius = 20,
	},
	padding_left = 5,
	padding_right = 5,
})
