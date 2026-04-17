local colors = require("colors")

local function bar_height()
	local handle = io.popen("/opt/homebrew/bin/yabai -m config external_bar 2>/dev/null")
	if not handle then
		return 30
	end
	local result = handle:read("*a") or ""
	handle:close()
	local top = result:match("^%s*[^:]+:(%d+):")
	return tonumber(top) or 30
end

-- Equivalent to the --bar domain
sbar.bar({
	height = bar_height(),
	color = colors.background,
	shadow = true,
	sticky = true,
	padding_right = 10,
	padding_left = 10,
	blur_radius = 20,
	topmost = "window",
})
