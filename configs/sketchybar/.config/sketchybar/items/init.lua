require("items.apple")
require("items.spaces")

-- User items: loaded between left and right items.
-- Left items (default position) appear after spaces.
-- Right items (position = "right") appear before the base right items.

require("items.calendar")
require("items.volume")
require("items.battery")
require("items.keyboard")
require("items.caffeinate")

local user_items = os.getenv("HOME") .. "/.config/slicker/user/sketchybar/items.lua"
local f = io.open(user_items, "r")
if f then
	f:close()
	dofile(user_items)
end

require("items.media")
