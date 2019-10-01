local floor = math.floor
local ceil = math.ceil
local min = math.min
local max = math.max
local random = math.random

local mpath = minetest.get_modpath('islands')

minetest.register_node("islands:dirt_with_grass_palm", {
	description = "Dirt with Grass",
	tiles = {"islands_grass.png", "default_dirt.png",
		{name = "default_dirt.png^default_grass_side.png",
			tileable_vertical = false}},
	groups = {crumbly = 3, soil = 1, spreading_dirt_type = 1},
	drop = 'default:dirt',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.25},
	}),
})

minetest.register_node("islands:dirt_with_snow", {
	description = "Dirt with Snow",
	tiles = {"default_snow.png", "default_dirt.png",
		{name = "default_dirt.png^default_snow_side.png",
			tileable_vertical = false}},
	groups = {crumbly = 3, soil = 1, spreading_dirt_type = 1, snowy = 1},
	drop = 'default:dirt',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_snow_footstep", gain = 0.2},
	}),
})

minetest.register_decoration({
	name = "islands:palm_tree",
	deco_type = "schematic",
	place_on = {"islands:dirt_with_grass_palm"},
	sidelen = 20,
	noise_params = {
		offset = 0.006,
		scale = 0.008,
		spread = {x = 64, y = 64, z = 64},
		seed = 2,
		octaves = 2,
		persist = 0.66
	},
	biomes = {"taiga",},
	y_max = 21,
	y_min = 3,
	schematic = mpath .. "/schematics/schematik.mts",
	flags = "place_center_x, place_center_z",
})

local function register_grass_decoration(offset, scale, length)
	minetest.register_decoration({
		name = "islands:grass_" .. length,
		deco_type = "simple",
		place_on = {"islands:dirt_with_grass_palm"},
		sidelen = 16,
		noise_params = {
			offset = offset,
			scale = scale,
			spread = {x = 200, y = 200, z = 200},
			seed = 100*length,
			octaves = 3,
			persist = 0.6
		},
		biomes = {"grassland"},
		y_max = 31000,
		y_min = 1,
		decoration = "default:grass_" .. length,
	})
end

register_grass_decoration(0.03,  0.09,  5)
register_grass_decoration(0.015, 0.075, 4)
register_grass_decoration(0,      0.06,  3)
register_grass_decoration(-0.015,  0.045, 2)
register_grass_decoration(-0.03,   0.03,  1)

isln_pos1 = {x=0,y=0,z=0}
isln_pos2 = {x=0,y=0,z=0}

minetest.register_on_chat_message(
	function(name, message)
		if message == 'pos1' then
			local plyr = minetest.get_player_by_name('singleplayer')
			isln_pos1 = plyr:get_pos()
			minetest.chat_send_all(dump(isln_pos1))
		end
	end
)	
minetest.register_on_chat_message(
	function(name, message)
		if message == 'pos2' then
			local plyr = minetest.get_player_by_name('singleplayer')
			isln_pos2 = plyr:get_pos()
			minetest.chat_send_all(dump(isln_pos2))
		end
	end
)	

minetest.register_on_chat_message(
	function(name, message)
		if message == 'schm' then
			local fname = minetest.get_worldpath() .."\\schematik.txt"
			minetest.chat_send_all(fname)
			minetest.create_schematic(isln_pos1,isln_pos2,nil,fname)
			minetest.chat_send_all('saved')
		end
	end
)	

minetest.register_on_chat_message(
	function(name, message)
		if message == 'place' then
			local fname = minetest.get_modpath('islands') .."\\schematics\\schematik.mts"
			minetest.chat_send_all(fname)
			minetest.place_schematic(isln_pos1,fname,'random',nil,false,'place_center_x,place_center_z')
			minetest.chat_send_all('plced')
		end
	end
)	