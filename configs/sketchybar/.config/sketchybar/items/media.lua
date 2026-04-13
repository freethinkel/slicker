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

local function update_media()
	sbar.exec(
		'media-control get 2>/dev/null | jq -r \'if . == null then "|||false" else (.title // "") + "|" + (.artist // "") + "|" + (.bundleIdentifier // "") + "|" + (if .playing then "true" else "false" end) end\'',
		function(result)
			result = trim(result)
			if result == "" or result == "|||false" then
				media:set({ drawing = false })
				return
			end

			local title, artist, bundle, playing_str = result:match("^(.-)|(.-)|(.-)|(.+)$")
			if title and title ~= "" then
				app_name = bundle or ""
				local icon = playing_str == "true" and icons.play or icons.pause
				local label = icon .. " " .. artist .. " – " .. title
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
