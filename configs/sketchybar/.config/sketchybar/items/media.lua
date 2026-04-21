local icons = {
	play = "􀊆",
	pause = "􀊄",
}

local media = sbar.add("item", {
	icon = { drawing = false },
	padding_right = 30,
	position = "right",
	updates = true,
	update_freq = 3,
	drawing = false,
})

local app_name = ""
local last_title = ""
local last_artist = ""

local function update_media()
	sbar.exec(
		'media-control get 2>/dev/null | jq -r \'if . == null then "|||false" else (.title // "") + "|" + (.artist // "") + "|" + (.bundleIdentifier // "") + "|" + (if .playing then "true" else "false" end) end\'',
		function(result)
			result = trim(result)
			if result == "" or result == "|||false" then
				last_title = ""
				last_artist = ""
				app_name = ""
				media:set({ drawing = false })
				return
			end

			local title, artist, bundle, playing_str = result:match("^(.-)|(.-)|(.-)|(.+)$")

			if bundle and bundle ~= "" then
				app_name = bundle
			end

			if title and title ~= "" then
				last_title = title
			end
			if artist and artist ~= "" then
				last_artist = artist
			end

			if last_title ~= "" then
				local icon = playing_str == "true" and icons.play or icons.pause
				local label = last_artist ~= "" and (icon .. " " .. last_artist .. " – " .. last_title)
					or (icon .. " " .. last_title)
				media:set({
					drawing = true,
					label = label,
				})
			else
				media:set({ drawing = false })
			end
		end
	)
end

media:subscribe("routine", function()
	update_media()
end)

media:subscribe("forced", function()
	update_media()
end)

media:subscribe("mouse.clicked", function()
	if app_name ~= "" then
		sbar.exec("open -b '" .. app_name .. "'")
	end
end)
