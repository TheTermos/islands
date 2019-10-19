local floor = math.floor
local ceil = math.ceil
local min = math.min
local max = math.max
local random = math.random

local convex = false
local mpath = minetest.get_modpath('islands')

dofile(mpath ..'/registerstuff.lua')

local mult = 1.0
-- Set the 3D noise parameters for the terrain.


local np_terrain = {
--	offset = -13,
	offset = -11*mult,						-- ratio 2:7 or 1:4 ?
	scale = 40*mult,
--	scale = 30,
	spread = {x = 256*mult, y =256*mult, z = 256*mult},
--	spread = {x = 128, y =128, z = 128},
	seed = 1234,
	octaves = convex and 1 or 5,
	persist = 0.38,
	lacunarity = 2.33,
	--flags = "eased"
}	--]]

local np_var = {
	offset = 0,						
	scale = 6*mult,
	spread = {x = 64*mult, y =64*mult, z = 64*mult},
	seed = 567891,
	octaves = 4,
	persist = 0.4,
	lacunarity = 1.89,
	--flags = "eased"
}

local np_hills = {
	offset = 2.5,					-- off/scale ~ 2:3
	scale = -3.5,
	spread = {x = 64*mult, y =64*mult, z = 64*mult},
--	spread = {x = 32, y =32, z = 32},
	seed = 2345,
	octaves = 3,
	persist = 0.40,
	lacunarity = 2.0,
	flags = "absvalue"
}

local np_cliffs = {
	offset = 0,					
	scale = 0.72,
	spread = {x = 180*mult, y =180*mult, z = 180*mult},
	seed = 78901,
	octaves = 2,
	persist = 0.4,
	lacunarity = 2.11,
--	flags = "absvalue"
}

local hills_offset = np_hills.spread.x*0.5
local hills_thresh = floor((np_terrain.scale)*0.5)
local shelf_thresh = floor((np_terrain.scale)*0.5) 
local cliffs_thresh=10

local function max_height(noiseprm)
	local height = 0
	local scale = noiseprm.scale
	for i=1,noiseprm.octaves do
		height=height + scale
		scale = scale * noiseprm.persist
	end	
	return height+noiseprm.offset
end

local function min_height(noiseprm)
	local height = 0
	local scale = noiseprm.scale
	for i=1,noiseprm.octaves do
		height=height - scale
		scale = scale * noiseprm.persist
	end	
	return height+noiseprm.offset
end

local base_min = min_height(np_terrain)
local base_max = max_height(np_terrain)
local base_rng = base_max-base_min
local easing_factor = 1/(base_max*base_max*4)
local base_heightmap = {}


-- Set singlenode mapgen (air nodes only).
-- Disable the engine lighting calculation since that will be done for a
-- mapchunk of air nodes and will be incorrect after we place nodes.

--minetest.set_mapgen_params({mgname = "singlenode", flags = "nolight"})

minetest.set_mapgen_setting('mg_name','singlenode',true)
minetest.set_mapgen_setting('flags','nolight',true)


-- Get the content IDs for the nodes used.

local c_sandstone = minetest.get_content_id("default:sandstone")
local c_stone = minetest.get_content_id("default:stone")
local c_sand = minetest.get_content_id("default:sand")
--local c_dirt = minetest.get_content_id("default:dirt_with_grass")
--local c_dirt = minetest.get_content_id("default:dirt_with_dry_grass")
local c_dirt = minetest.get_content_id("islands:dirt_with_grass_palm")
local c_snow = minetest.get_content_id("islands:dirt_with_snow")
local c_water     = minetest.get_content_id("default:water_source")


-- Initialize noise object to nil. It will be created once only during the
-- generation of the first mapchunk, to minimise memory use.

local nobj_terrain = nil
local nobj_var = nil
local nobj_hills = nil
local nobj_cliffs = nil


-- Localise noise buffer table outside the loop, to be re-used for all
-- mapchunks, therefore minimising memory use.

local nvals_terrain = {}
local isln_terrain = nil
local isln_var = nil
local isln_hills = nil
local isln_cliffs = nil


-- Localise data buffer table outside the loop, to be re-used for all
-- mapchunks, therefore minimising memory use.

local data = {}

local function get_terrain_height(theight,hheight,cheight)
		-- parabolic gradient
	if theight > 0 and theight < shelf_thresh then
		theight = theight * (theight*theight/(shelf_thresh*shelf_thresh)*0.5 + 0.5)
	end	
		-- hills
	if theight > hills_thresh then
		theight = theight + max((theight-hills_thresh) * hheight,0)
		-- cliffs
	elseif theight > 1 and theight < hills_thresh then 
		local clifh = max(min(cheight,1),0) 
		if clifh > 0 then
			clifh = -1*(clifh-1)*(clifh-1) + 1
			theight = theight + (hills_thresh-theight) * clifh * ((theight<2) and theight-1 or 1)
		end
	end
	return theight
end
 
-- On generated function.

-- 'minp' and 'maxp' are the minimum and maximum positions of the mapchunk that
-- define the 3D volume.
minetest.register_on_generated(function(minp, maxp, seed)
	-- Start time of mapchunk generation.
	local t0 = os.clock()
	
	local sidelen = maxp.x - minp.x + 1
--	local permapdims3d = {x = sidelen, y = sidelen, z = sidelen}
	local permapdims3d = {x = sidelen, y = sidelen, z = 0}
	
	-- base terrain
	nobj_terrain = nobj_terrain or
		minetest.get_perlin_map(np_terrain, permapdims3d)		
	isln_terrain=nobj_terrain:get_2d_map({x=minp.x,y=minp.z})
	
	-- base variation
	nobj_var = nobj_var or
		minetest.get_perlin_map(np_var, permapdims3d)		
	isln_var=nobj_var:get_2d_map({x=minp.x,y=minp.z})
	
	-- hills
	nobj_hills = nobj_hills or
		minetest.get_perlin_map(np_hills, permapdims3d)
	isln_hills=nobj_hills:get_2d_map({x=minp.x+hills_offset,y=minp.z+hills_offset})
	
	-- cliffs
	nobj_cliffs = nobj_cliffs or
		minetest.get_perlin_map(np_cliffs, permapdims3d)
	isln_cliffs=nobj_cliffs:get_2d_map({x=minp.x,y=minp.z})
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	vm:get_data(data)

	for z = minp.z, maxp.z do
		base_heightmap[z-minp.z+1]={}
		for x = minp.x, maxp.x do
			local theight = isln_terrain[z-minp.z+1][x-minp.x+1] + (convex and isln_var[z-minp.z+1][x-minp.x+1] or 0)
			local hheight = isln_hills[z-minp.z+1][x-minp.x+1]
			local cheight = isln_cliffs[z-minp.z+1][x-minp.x+1]
			base_heightmap[z-minp.z+1][x-minp.x+1]=get_terrain_height(theight,hheight,cheight)
		end
	end	

	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			for x = minp.x, maxp.x do
				local vi = area:index(x, y, z)								
				local theight = base_heightmap[z-minp.z+1][x-minp.x+1]
				
				if theight > y then
					data[vi] = c_stone
				elseif y==ceil(theight) then
					data[vi]= y<3 and c_sand or (y<60-random(3) and c_dirt or c_snow)
				elseif y <= 1 then
					data[vi] = c_water
				end
			end
		end
	end

	vm:set_data(data)
	minetest.generate_decorations(vm)
	minetest.generate_ores(vm)
	vm:calc_lighting()
	vm:write_to_map()
	vm:update_liquids()
	
	-- Print generation time of this mapchunk.
	local chugent = ceil((os.clock() - t0) * 1000)
	print ("[lvm_example] Mapchunk generation time " .. chugent .. " ms")
end)

minetest.register_on_newplayer(function(obj)
	local nobj_terrain = minetest.get_perlin_map(np_terrain, {x=1,y=1,z=0})	
	local nobj_hills = minetest.get_perlin_map(np_hills, {x=1,y=1,z=0})	
	local nobj_cliffs = minetest.get_perlin_map(np_cliffs, {x=1,y=1,z=0})	
	local th=nobj_terrain:get_2d_map({x=1,y=1})
	local hh=nobj_hills:get_2d_map({x=1,y=1})
	local ch=nobj_cliffs:get_2d_map({x=1,y=1})
	local height = get_terrain_height(th[1][1],hh[1][1],ch[1][1])

	minetest.set_timeofday(0.30)
	local inv = obj:get_inventory()
	inv:add_item('main','binoculars:binoculars')
	local pos = obj:get_pos()
	local node = minetest.get_node(pos)
	if height<2 then
		pos.y = 2
		minetest.add_entity(pos,'boats:boat')
		pos.y = 3
		obj:set_pos(pos)
	else
		inv:add_item("main", "boats:boat")
		pos.y=height+2
		obj:set_pos(pos)
	end
	return true
end
)
