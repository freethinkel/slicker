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
		'osascript -e \'tell application "System Events" to (name of processes) contains "Spotify"\'',
		function(running)
			running = trim(running)
			if running ~= "true" then
				media:set({ drawing = false })
				return
			end
			sbar.exec(
				"osascript -e 'tell application \"Spotify\" to {player state as string, name of current track, artist of current track}'",
				function(result)
					result = trim(result)
					local state, title, artist = result:match("^(.+), (.+), (.+)$")
					if state == "playing" or state == "paused" then
						app_name = "Spotify"
						local icon = state == "playing" and icons.play or icons.pause
						media:set({
							drawing = true,
							label = icon .. " " .. artist .. " – " .. title,
						})
					else
						media:set({ drawing = false })
					end
				end
			)
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
		sbar.exec("open -a '" .. app_name .. "'")
	end
end)
