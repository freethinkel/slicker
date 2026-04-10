local colors = require("colors")

local function is_builtin_only()
	local handle = io.popen("yabai -m query --displays 2>/dev/null | grep -c '\"id\"'")
	if not handle then
		return false
	end
	local result = handle:read("*a")
	handle:close()
	return (tonumber(result) or 0) <= 1
end

-- Equivalent to the --bar domain
sbar.bar({
	height = is_builtin_only() and 40 or 30,
	color = colors.background,
	-- border_color = colors.bar.border,
	shadow = true,
	sticky = true,
	padding_right = 10,
	padding_left = 10,
	blur_radius = 20,
	topmost = "window",
})
