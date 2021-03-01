islands.weathertimer = 0

local function get_adjusted_light(atime)
	atime = atime or minetest.get_timeofday()
	atime = math.abs(atime-0.5)
	local light
	if atime < 0.23 then
		return 1
	elseif atime > 0.32 then
		return 0.12
	else
		return (-atime+0.32)/0.09*0.88+0.12
	end
end

minetest.register_on_joinplayer(function(plyr)
	plyr:override_day_night_ratio(get_adjusted_light())
--	plyr:set_sky({sky_color={day_sky="#00D3F0"}})
	plyr:set_sky({sky_color={day_sky="#01C7EC",night_sky="#00FFFF",dawn_sky="#00AAFF"}})
	plyr:set_clouds({density=0.3})
end)

minetest.register_globalstep(function(dtime)
	islands.weathertimer = islands.weathertimer + dtime
	if islands.weathertimer > 5 then
		islands.weathertimer = 0
		
		local curtime = minetest.get_timeofday()
		local prefs = minetest.get_connected_players()
		for _,plyr in ipairs(prefs) do
			plyr:override_day_night_ratio(get_adjusted_light(curtime))
		end
	end
end)	

--[[
minetest.register_globalstep(function(dtime)
	islands.weathertimer = islands.weathertimer + dtime
	if islands.weathertimer > 5 then
		islands.weathertimer = 0
		local atime = math.abs(minetest.get_timeofday()-0.5)
		local light
		if atime < 0.2 then
			light = 1
		elseif atime > 0.32 then
			light = 0.1
		else
			light = (-atime+0.32)/0.12*0.9+0.1
		end
		
		local prefs = minetest.get_connected_players()
		for _,plyr in ipairs(prefs) do
			plyr:override_day_night_ratio(light)
			minetest.chat_send_all(tostring(atime) .. ' ' .. tostring(light))
		end
	end
end)	--]]