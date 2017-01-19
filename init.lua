--Building Elements  -  A mod for Minetest version 0.4.15 and above.
--                      This mod provides a variety of nodebox shapes that can be applied to any stone, wood, tree,
--                      metal or glass type node.  It is intended to assist in reducing inventory clutter, by placing
--                      only the shape objects and the various nodes in inventory.  Ultimately, this should be a library
--                      that simply create nodebox shapes.  Each shape should be available to any of the node types above,
--                      thus maximizing the creative abilities of the player.
--                      Shapes currently include columns, pillars, beams, crosslinks, walls, fences, doors, fence gates, stairs,
--                      slabs, tree and some custom shapes.  Variations of each are included.
--                      To be added are furniture, religious symbols, plants, tree roots, and other decorative items.
--                      
--**LICENSING**
--All code is licensed LGPL2.1

--All graphics content is copyright 2017 by shadmordre@gmail.com, also known as, shadmordre on minetest.net forum.
--License is CC BY-SA 3.0
--Please do not interpret the copyright notice as any violation of CC BY-SA 3.0.  Copyright and license are NOT the same.

--  #####   The point is:  Have Fun!!!   #####

building_elements = {}

local _building_elements = {}
building_elements.registered_doors = {}

function building_elements.get(pos)
	local node_name = minetest.get_node(pos).name
	if _building_elements.registered_doors[node_name] then
		-- A normal upright door
		return {
			pos = pos,
			open = function(self, player)
				if self:state() then
					return false
				end
				return _building_elements.door_toggle(self.pos, nil, player)
			end,
			close = function(self, player)
				if not self:state() then
					return false
				end
				return _building_elements.door_toggle(self.pos, nil, player)
			end,
			toggle = function(self, player)
				return _building_elements.door_toggle(self.pos, nil, player)
			end,
			state = function(self)
				return minetest.get_node(self.pos).name:sub(-5) == "_open"
			end
		}
	else
		return nil
	end
end
function building_elements.door_toggle(pos, node, clicker)
	node = node or minetest.get_node(pos)
	if clicker and not minetest.check_player_privs(clicker, "protection_bypass") then
		-- is player wielding the right key?
		local item = clicker:get_wielded_item()
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("doors_owner")
		if item:get_name() == "default:key" then
			local key_meta = minetest.parse_json(item:get_metadata())
			local secret = meta:get_string("key_lock_secret")
			if secret ~= key_meta.secret then
				return false
			end

		elseif owner ~= "" then
			if clicker:get_player_name() ~= owner then
				return false
			end
		end
	end

	local def = minetest.registered_nodes[node.name]

	if string.sub(node.name, -5) == "_open" then
		minetest.sound_play(def.sound_close,
			{pos = pos, gain = 0.3, max_hear_distance = 10})
		minetest.swap_node(pos, {name = string.sub(node.name, 1,
			string.len(node.name) - 5), param1 = node.param1, param2 = node.param2})
	else
		minetest.sound_play(def.sound_open,
			{pos = pos, gain = 0.3, max_hear_distance = 10})
		minetest.swap_node(pos, {name = node.name .. "_open",
			param1 = node.param1, param2 = node.param2})
	end
end
local function can_dig_door(pos, digger)
	local digger_name = digger and digger:get_player_name()
	if digger_name and minetest.get_player_privs(digger_name).protection_bypass then
		return true
	end
	return minetest.get_meta(pos):get_string("doors_owner") == digger_name
end
local function on_place_node(place_to, newnode,
	placer, oldnode, itemstack, pointed_thing)
	-- Run script hook
	for _, callback in ipairs(minetest.registered_on_placenodes) do
		-- Deepcopy pos, node and pointed_thing because callback can modify them
		local place_to_copy = {x = place_to.x, y = place_to.y, z = place_to.z}
		local newnode_copy =
			{name = newnode.name, param1 = newnode.param1, param2 = newnode.param2}
		local oldnode_copy =
			{name = oldnode.name, param1 = oldnode.param1, param2 = oldnode.param2}
		local pointed_thing_copy = {
			type  = pointed_thing.type,
			above = vector.new(pointed_thing.above),
			under = vector.new(pointed_thing.under),
			ref   = pointed_thing.ref,
		}
		callback(place_to_copy, newnode_copy, placer,
			oldnode_copy, itemstack, pointed_thing_copy)
	end
end


minetest.register_craftitem("building_elements:blueprint", {
	description = "Building Elements Blueprint",
	inventory_image = "building_elements_blueprint.png",
})
minetest.register_craft({
	output = 'building_elements:blueprint',
	recipe = {
		{'default:paper', 'default:paper', 'default:paper'},
		{'default:paper', 'building_elements:pencil', 'default:paper'},
		{'default:paper', 'default:paper', 'default:paper'},
	}
})

minetest.register_craftitem("building_elements:pencil", {
	description = "Building Elements Pencil",
	inventory_image = "building_elements_pencil.png",
})
minetest.register_craft({
	output = 'building_elements:pencil',
	recipe = {
		{'', 'group:stick', ''},
		{'', 'default:coal_lump', ''},
		{'', '', ''},
	}
})

minetest.register_node("building_elements:stair_4step_shape", {
	description = "be Stair 4step Shape",
	tiles = {"default_stone_block.png"},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = true,
	groups = {cracky = 3, stone = 2, wall = 1},
	drop = 'default:stone_block',
	sounds = default.node_sound_stone_defaults(),
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, 0.25, 0.5, 0.5, 0.5}, -- NodeBox11
			{-0.5, -0.5, 0, 0.5, 0.25, 0.25}, -- NodeBox12
			{-0.5, -0.5, -0.25, 0.5, 0, 0}, -- NodeBox13
			{-0.5, -0.5, -0.5, 0.5, -0.25, -0.25}, -- NodeBox14
		}
	},
	on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
})
minetest.register_craft({output = 'building_elements:stair_4step_shape',
	recipe = {
		{ '', '', 'default:cobble'},
		{ 'default:cobble', '', ''},
		{ '', '', ''},
	}
})

--[[
minetest.register_node("building_elements:door_centered", {
	description = "Center aligned door",
	tiles = {"default_stone_block.png"},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = true,
	groups = {cracky = 3, stone = 2, wall = 1},
	drop = 'default:stone_block',
	sounds = default.node_sound_stone_defaults(),
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, 0.5, 1.5, 0.0625}, -- node_DoorCenterAligned_y
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, 0.5, 1.5, 0.0625},
		}
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, 0.5, 1.5, 0.0625},
		}
	},
	on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
})
minetest.register_craft({output = 'building_elements:door_centered',
	recipe = {
		{ '', '', 'default:cobble'},
		{ 'default:cobble', '', ''},
		{ '', '', ''},
	}
})
]]


--FUNCTIONS DEFINING SHAPE NODES AND CRAFT RECIPES
function building_elements.register_shapes(wall_texture)
--BOXES

--COLUMNS
	building_elements.register_column_end_half_shape("column_end_half_shape", "column_end_half_shape", wall_texture)
	building_elements.register_column_end_half_with_wall_shape("column_end_half_with_wall_shape", "column_end_half_with_wall_shape", wall_texture)
	building_elements.register_column_end_full_shape("column_end_full_shape", "column_end_full_shape", wall_texture)

--CROSSLINK BEAMS FOR ABOVE COLUMNS
	building_elements.register_cross_link_shape("cross_link_shape", "cross_link_shape", wall_texture)
	building_elements.register_cross_link_support_shape("cross_link_support_shape", "cross_link_support_shape", wall_texture)

--DOORS, GATES
	building_elements.register_door_centered_right_shape("door_centered_right_shape", "door_centered_right_shape", wall_texture)
	building_elements.register_door_centered_shape("door_centered_shape", "door_centered_shape", wall_texture)
	building_elements.register_door_with_window_centered_right_shape("door_with_window_centered_right_shape", "door_with_window_centered_right_shape", wall_texture)
	building_elements.register_door_with_window_centered_shape("door_with_window_centered_shape", "door_with_window_centered_shape", wall_texture)
	building_elements.register_fencegate_solid_centered_right_shape("fencegate_solid_centered_right_shape", "fencegate_solid_centered_right_shape", wall_texture)
	building_elements.register_fencegate_solid_centered_shape("fencegate_solid_centered_shape", "fencegate_solid_centered_shape", wall_texture)
	building_elements.register_fencegate_centered_right_shape("fencegate_centered_right_shape", "fencegate_centered_right_shape", wall_texture)
	building_elements.register_fencegate_centered_shape("fencegate_centered_shape", "fencegate_centered_shape", wall_texture)

--FENCES
	building_elements.register_fence_shape("fence_shape", "fence_shape", wall_texture)

--GENERIC SIMPLE SHAPES AND LINKAGES
	building_elements.register_linkage_shape("linkage_shape", "linkage_shape", wall_texture)
	building_elements.register_linkage_medium_half_shape("linkage_medium_half_shape", "linkage_medium_half_shape", wall_texture)
	building_elements.register_linkage_small_qtr_shape("linkage_small_qtr_shape", "linkage_small_qtr_shape", wall_texture)
	building_elements.register_linkage_round_med_half_shape("linkage_round_med_half_shape", "linkage_round_med_half_shape", wall_texture)
	building_elements.register_linkage_round_small_quarter_shape("linkage_round_small_quarter_shape", "linkage_round_small_quarter_shape", wall_texture)
	building_elements.register_cylinder_shape("cylinder_shape", "cylinder_shape", wall_texture)
	building_elements.register_cylinder_3qtr_shape("cylinder_3qtr_shape", "cylinder_3qtr_shape", wall_texture)
	building_elements.register_cylinder_half_shape("cylinder_half_shape", "cylinder_half_shape", wall_texture)
	building_elements.register_cylinder_1qtr_shape("cylinder_1qtr_shape", "cylinder_1qtr_shape", wall_texture)
	building_elements.register_cylinder_to_cross_shape("cylinder_to_cross_shape", "cylinder_to_cross_shape", wall_texture)
	building_elements.register_octagon_shape("octagon_shape", "octagon_shape", wall_texture)

--PILLARS (ALSO WITH WALL SECTIONS)
	building_elements.register_pillar_shape("pillar_shape", "pillar_shape", wall_texture)
	building_elements.register_pillar_junction_shape("pillar_junction_shape", "pillar_junction_shape", wall_texture)
	building_elements.register_pillar_with_center_link_shape("pillar_with_center_link_shape", "pillar_with_center_link_shape", wall_texture)
	building_elements.register_pillar_with_curtain_wall_shape("pillar_with_curtain_wall_shape", "pillar_with_curtain_wall_shape", wall_texture)
	building_elements.register_pillar_with_default_wall_shape("pillar_with_default_wall_shape", "pillar_with_default_wall_shape", wall_texture)
	building_elements.register_pillar_with_half_wall_shape("pillar_with_half_wall_shape", "pillar_with_half_wall_shape", wall_texture)
	building_elements.register_pillar_with_full_wall_shape("pillar_with_full_wall_shape", "pillar_with_full_wall_shape", wall_texture)

--RAILING AND TRIM ITEMS
	building_elements.register_railing_shape("railing_shape", "railing_shape", wall_texture)

--FLAT SLABS (TO INCLUDE ROADS)
	building_elements.register_road_shape("road_shape", "road_shape", wall_texture)

--LADDERS, CAGE BARS, TRAIN TRACKS, LATTICES
	building_elements.register_track_shape("track_shape", "track_shape", wall_texture)

--SLABS OF VARIOUS THICKNESS
	building_elements.register_slab_shape("slab_shape", "slab_shape", wall_texture)

--STAIRS
	building_elements.register_stair_shape("stair_shape", "stair_shape", wall_texture)

--TREES
	building_elements.register_tree_branch_shape("tree_branch_shape", "tree_branch_shape", wall_texture)
	building_elements.register_tree_root_shape("tree_root_shape", "tree_root_shape", wall_texture)
	building_elements.register_tree_trunk_large_shape("tree_trunk_large_shape", "tree_trunk_large_shape", wall_texture)
	building_elements.register_tree_trunk_medium_shape("tree_trunk_medium_shape", "tree_trunk_medium_shape", wall_texture)
	building_elements.register_tree_trunk_small_shape("tree_trunk_small_shape", "tree_trunk_small_shape", wall_texture)

--WALLS (CENTER ALIGNED, VERTICAL SLABS)
	building_elements.register_wall_shape("wall_shape", "wall_shape", wall_texture)
	building_elements.register_wall_thin_shape("wall_thin_shape", "wall_thin_shape", wall_texture)
	building_elements.register_wall_section_shape("wall_section_shape", "wall_section_shape", wall_texture)
end

--BOXES


--COLUMNS
building_elements.register_column_end_half_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			   {-0.25, -0.5, -0.25, 0.25, 0.5, 0.25},
			   {-0.5, 0, -0.25, 0.5, 0.5, 0.25},
			   {-0.25, 0, -0.5, 0.25, 0.5, 0.5},
			   {-0.4375, 0.0625, -0.4375, 0.4375, 0.4375, 0.4375},
		    },
		},
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', ''},
			{ '', '', ''},
		}
	})

end
building_elements.register_column_end_half_with_wall_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			   {-0.25, -0.5, -0.25, 0.25, 0.5, 0.25},
			   {-0.5, 0, -0.25, 0.5, 0.5, 0.25},
			   {-0.25, 0, -0.5, 0.25, 0.5, 0.5},
			   {-0.4375, 0.0625, -0.4375, 0.4375, 0.4375, 0.4375},
			   {-3/16, -1/2, -1/2,  3/16, 0, -1/4},
		    },
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ '', 'building_elements:blueprint', 'building_elements:blueprint'},
		}
	})

end
building_elements.register_column_end_full_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			   {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
			   {-0.5, -0.25, -0.25, 0.5, 0.5, 0.25},
			   {-0.25, -0.25, -0.5, 0.25, 0.5, 0.5},
			   {-0.4375, -0.25, -0.4375, 0.4375, 0.4375, 0.4375},
		    },
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', ''},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end

--CROSSLINK BEAMS FOR ABOVE COLUMNS
building_elements.register_cross_link_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2},
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			    {-0.25, 0, -0.5, 0.25, 0.5, 0.5},
		    },
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', '', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ '', '', ''},
		}
	})

end
building_elements.register_cross_link_support_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			   {-0.25, 0, -0.5, 0.25, 0.5, 0.5},
			   {-0.125, -0.5, -0.125, 0.125, 0, 0.125},
			   {-0.1875, -0.5, -0.1875, 0.1875, -0.375, 0.1875},
			   {-0.1875, -0.125, -0.1875, 0.1875, 0, 0.1875},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', '', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end

--DOORS, GATES
building_elements.register_door_centered_right_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{0.375, -0.5, 0, 0.5, 1.5, 1.0},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', 'building_elements:blueprint' },
		}
	})

end
building_elements.register_door_centered_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, 0, -0.375, 1.5, 1.0},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', 'building_elements:blueprint', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', ''},
			{ 'building_elements:blueprint', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_door_with_window_centered_right_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{0.375, -0.5, 0, 0.5, 0.5, 1.0}, --Base
				{0.375, 0.5, 0, 0.5, 0.625, 1.0}, -- Bottom_x
				{0.375, 1.375, 0, 0.5, 1.5, 1.0}, -- Top_x
				{0.375, 0.625, 0, 0.5, 1.375, 0.125}, -- Right_y
				{0.375, 0.625, 0.875, 0.5, 1.375, 1.0}, -- Left_y
				{0.375, 0.9375, 0.0625, 0.5, 1.0625, 0.9375}, -- Center_x
				{0.375, 0.625, 0.4375, 0.5, 1.375, 0.5625}, -- Center_y
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', 'building_elements:blueprint' },
		}
	})

end
building_elements.register_door_with_window_centered_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, 0, -0.375, 0.5, 1.0}, --Base
				{-0.5, 0.5, 0, -0.375, 0.625, 1.0}, -- Bottom_x
				{-0.5, 1.375, 0, -0.375, 1.5, 1.0}, -- Top_x
				{-0.5, 0.625, 0.875, -0.375, 1.375, 1.0}, -- Right_y
				{-0.5, 0.625, 0, -0.375, 1.375, 0.125}, -- Left_y
				{-0.5, 0.9375, 0.125, -0.375, 1.0625, 0.9375}, -- Center_x
				{-0.5, 0.625, 0.4375, -0.375, 1.375, 0.5625}, -- Center_y
			}
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', 'building_elements:blueprint', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', ''},
			{ 'building_elements:blueprint', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_fencegate_centered_right_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{0.375, -0.5, -0.125, 0.5, 0.5, 0.125}, -- Post_y
				{-0.375, 0.375, -0.0625, 0.4375, 0.5, 0.0625}, -- TopRail_x
				{-0.375, -0.375, -0.0625, 0.4375, -0.25, 0.0625}, -- BottomRail_x
				{-0.5, -0.375, -0.0625, -0.375, 0.5, 0.0625}, -- OuterSupport_y
				{-0.375, 0, -0.0625, 0.25, 0.125, 0.0625}, -- InnerRail_x
				{0.25, -0.25, -0.0625, 0.375, 0.375, 0.0625}, -- HingeSupport_y
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', 'building_elements:blueprint', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', ''},
			{ 'building_elements:blueprint', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_fencegate_centered_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.125, -0.375, 0.5, 0.125}, -- Post_y
				{-0.4375, 0.375, -0.0625, 0.375, 0.5, 0.0625}, -- TopRail_x
				{-0.4375, -0.375, -0.0625, 0.375, -0.25, 0.0625}, -- BottomRail_x
				{0.375, -0.375, -0.0625, 0.5, 0.5, 0.0625}, -- OuterSupport_y
				{-0.25, 0, -0.0625, 0.375, 0.125, 0.0625}, -- InnerRail_x
				{-0.375, -0.25, -0.0625, -0.25, 0.375, 0.0625}, -- HingeSupport_y
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', 'building_elements:blueprint', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', ''},
			{ 'building_elements:blueprint', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_fencegate_solid_centered_right_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{0.375, -0.5, -0.125, 0.5, 0.5, 0.125}, -- Post_y
				{-0.5, -0.375, -0.0625, 0.375, 0.4375, 0.0625},
			}
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', 'building_elements:blueprint' },
		}
	})

end
building_elements.register_fencegate_solid_centered_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.125, -0.375, 0.5, 0.125}, -- Post_y
				{-0.375, -0.375, -0.0625, 0.5, 0.4375, 0.0625},
			}
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', 'building_elements:blueprint', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', ''},
			{ 'building_elements:blueprint', 'building_elements:blueprint', ''},
		}
	})

end

--FENCES
building_elements.register_fence_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125},
				{-0.0625, 0.1875, -0.5, 0.0625, 0.4375, -0.125}, -- Front Top
				{-0.0625, -0.3125, -0.5, 0.0625, -0.125, -0.125}, -- Front Bottom
				{0.125, 0.1875, -0.0625, 0.5, 0.4375, 0.0625}, -- Right Top
				{0.125, -0.3125, -0.0625, 0.5, -0.125, 0.0625}, -- Right Bottom
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end

--GENERIC SIMPLE SHAPES AND LINKAGES
building_elements.register_linkage_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.125, -0.125, -0.125, 0.125, 0.125, 0.125},
				{-0.0625, -0.0625, -0.5, 0.0625, 0.0625, -0.125},
				{0.125, -0.0625, -0.0625, 0.5, 0.0625, 0.0625},
				{-0.0625, 0.125, -0.0625, 0.0625, 0.5, 0.0625},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', '', ''},
		}
	})

end
building_elements.register_linkage_medium_half_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.25, -0.25, 0.25, 0.25, 0.25}, -- Base
				{-0.25, -0.25, -0.5, 0.25, 0.25, -0.25}, -- Front_zneg
				{0.25, -0.25, -0.25, 0.5, 0.25, 0.25}, -- Right_xpos
				{-0.25, 0.25, -0.25, 0.25, 0.5, 0.25}, -- Top_ypos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', '', ''},
		}
	})

end
building_elements.register_linkage_small_qtr_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.125, -0.125, -0.125, 0.125, 0.125, 0.125}, -- Base
				{-0.125, -0.125, -0.5, 0.125, 0.125, -0.125}, -- Front_zneg
				{0.125, -0.125, -0.125, 0.5, 0.125, 0.125}, -- Right_xpos
				{-0.125, 0.125, -0.125, 0.125, 0.5, 0.125}, -- Top_ypos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', '', ''},
		}
	})

end
building_elements.register_linkage_round_med_half_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.25, -0.25, 0.25, 0.25, 0.25}, -- Base
				{-0.25, -0.125, -0.5, 0.25, 0.125, -0.25}, -- Front_h_zneg
				{0.25, -0.125, -0.25, 0.5, 0.125, 0.25}, -- Right_h_xpos
				{-0.125, 0.25, -0.25, 0.125, 0.5, 0.25}, -- Top_z_ypos
				{-0.125, -0.25, -0.5, 0.125, 0.25, -0.25}, -- Front_v_zneg
				{0.25, -0.25, -0.125, 0.5, 0.25, 0.125}, -- Right_v_xpos
				{-0.25, 0.25, -0.125, 0.25, 0.5, 0.125}, -- Top_x_ypos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', '', ''},
		}
	})

end
building_elements.register_linkage_round_small_quarter_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.125, -0.0625, -0.0625, 0.125, 0.0625, 0.0625}, -- Base_x
				{-0.0625, -0.125, -0.0625, 0.0625, 0.125, 0.0625}, -- Base_y
				{-0.0625, -0.0625, -0.125, 0.0625, 0.0625, 0.125}, -- Base_z
				{-0.125, -0.0625, -0.5, 0.125, 0.0625, -0.0625}, -- Front_h_zneg
				{-0.0625, -0.125, -0.5, 0.0625, 0.125, -0.0625}, -- Front_v_zneg
				{0.0625, -0.0625, -0.125, 0.5, 0.0625, 0.125}, -- Right_h_xpos
				{0.0625, -0.125, -0.0625, 0.5, 0.125, 0.0625}, -- Right_v_xpos
				{-0.125, 0.0625, -0.0625, 0.125, 0.5, 0.0625}, -- Top_x_ypos
				{-0.0625, 0.0625, -0.125, 0.0625, 0.5, 0.125}, -- Top_z_ypos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', '', ''},
		}
	})

end
building_elements.register_cylinder_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2},
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.1875, -0.5, -0.5, 0.1875, 0.5, 0.5},
				{-0.5, -0.5, -0.1875, 0.5, 0.5, 0.1875},
				{-0.375, -0.5, -0.375, 0.375, 0.5, 0.375},
				{-0.3125, -0.5, -0.4375, 0.3125, 0.5, 0.4375},
				{-0.4375, -0.5, -0.3125, 0.4375, 0.5, 0.3125},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_cylinder_3qtr_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2},
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.375, -0.5, -0.125, 0.375, 0.5, 0.125},
				{-0.125, -0.5, -0.375, 0.125, 0.5, 0.375},
				{-0.25, -0.5, -0.3125, 0.25, 0.5, 0.3125},
				{-0.3125, -0.5, -0.25, 0.3125, 0.5, 0.25},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_cylinder_half_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2},
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, -0.125, 0.25, 0.5, 0.125}, -- Front_h_zneg
				{-0.125, -0.5, -0.25, 0.125, 0.5, 0.25}, -- Back_h_zpos
				{-0.1875, -0.5, -0.1875, 0.1875, 0.5, 0.1875}, -- NodeBox16
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_cylinder_1qtr_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2},
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.125, -0.5, -0.0625, 0.125, 0.5, 0.0625}, -- Front_h_zneg
				{-0.0625, -0.5, -0.125, 0.0625, 0.5, 0.125}, -- Back_h_zpos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_cylinder_to_cross_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2},
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, -0.4375, 0.25, 0.25, 0.4375}, -- Middle_z
				{-0.4375, -0.5, -0.25, 0.4375, 0.25, 0.25}, -- Middle_x
				{-0.1875, -0.5, -0.5, 0.1875, 0.5, 0.5}, -- Outer_z
				{-0.5, -0.5, -0.1875, 0.5, 0.5, 0.1875}, -- Outer_x
				{-0.3125, -0.5, -0.375, 0.3125, -0.125, 0.375}, -- Inner_z
				{-0.375, -0.5, -0.3125, 0.375, -0.125, 0.3125}, -- Inner_x
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_octagon_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2},
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, -0.4375, 0.25, 0.5, 0.4375}, -- Middle_z
				{-0.4375, -0.5, -0.25, 0.4375, 0.5, 0.25}, -- Middle_x
				{-0.1875, -0.5, -0.5, 0.1875, 0.5, 0.5}, -- Outer_z
				{-0.5, -0.5, -0.1875, 0.5, 0.5, 0.1875}, -- Outer_x
				{-0.3125, -0.5, -0.375, 0.3125, 0.5, 0.375}, -- Inner_z
				{-0.375, -0.5, -0.3125, 0.375, 0.5, 0.3125}, -- Inner_x
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end

--PILLARS (ALSO WITH WALL SECTIONS)
building_elements.register_pillar_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2},
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4}},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_pillar_junction_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
				{-0.25, -0.25, -0.5, 0.25, 0.25, -0.25},
				{0.25, -0.25, -0.25, 0.5, 0.25, 0.25},
				{-0.25, 0.25, -0.25, 0.25, 0.5, 0.25},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_pillar_with_center_link_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			{-0.3125, 0.1875, -0.25, 0.3125, 0.5, 0.25}, -- ConnectTopX
			{-0.25, 0.1875, -0.3125, 0.25, 0.5, 0.3125}, -- ConnectTopZ
			{-0.3125, -0.1875, -0.25, 0.3125, 0.1875, 0.25}, -- BaseX
			{-0.25, -0.1875, -0.3125, 0.25, 0.1875, 0.3125}, -- BaseZ
			{-0.3125, -0.5, -0.25, 0.3125, -0.1875, 0.25}, -- ConnectBottomX
			{-0.25, -0.5, -0.3125, 0.25, -0.1875, 0.3125}, -- ConnectBottomZ
			{0.3125, -0.1875, -0.125, 0.5, 0.1875, 0.125}, -- ConnectRightX_xpos
			{0.3125, -0.125, -0.1875, 0.5, 0.125, 0.1875}, -- ConnectRightZ_xpos
			{-0.125, -0.1875, -0.5, 0.125, 0.1875, -0.3125}, -- ConnectFrontY_zneg
			{-0.1875, -0.125, -0.5, 0.1875, 0.125, -0.3125}, -- ConnectFrontZ_zneg
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_pillar_with_curtain_wall_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4},
				{ 1/4, 0, -3/16,  1/2, 1/2,  3/16},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_pillar_with_default_wall_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4},
				{ 1/4, -1/2, -3/16,  1/2, 3/8,  3/16},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', '', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
		}
	})

end
building_elements.register_pillar_with_half_wall_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4},
				{ 1/4, -1/2, -3/16,  1/2, 0,  3/16},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ '', 'building_elements:blueprint', ''},
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
		}
	})

end
building_elements.register_pillar_with_full_wall_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4},
				{ 1/4, -1/2, -3/16,  1/2, 1/2,  3/16},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
		}
	})

end

--RAILING AND TRIM ITEMS
building_elements.register_railing_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.0625, -0.5, -0.0625, 0.0625, 0.1875, 0.0625},
				{-0.125, 0.1875, -0.125, 0.125, 0.5, 0.125},
				{-0.0625, 0.25, -0.5, 0.0625, 0.5, -0.125},
				{0.125, 0.25, -0.0625, 0.5, 0.5, 0.0625},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', ''},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end

--FLAT SLABS (TO INCLUDE ROADS)
building_elements.register_road_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5}, -- base
				{0.4375, -0.375, -0.4375, 0.5, 0.1875, -0.375}, -- support1 from front
				{0.4375, -0.375, -0.1875, 0.5, 0.1875, -0.125}, -- support2 from front
				{0.4375, -0.375, 0.0625, 0.5, 0.1875, 0.125}, -- support3 from front
				{0.4375, -0.375, 0.3125, 0.5, 0.1875, 0.375}, -- support4 from front
				{0.375, 0.1875, -0.5, 0.5, 0.3125, 0.5}, -- top rail
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', '', '' },
			{ '', '', 'building_elements:blueprint'},
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
		}
	})

end

--LADDERS, CAGE BARS, TRAIN TRACKS, LATTICES
building_elements.register_track_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.4375, -0.5, -0.5, -0.3125, -0.4375, 0.5}, -- board1 from left
				{-0.1875, -0.5, -0.5, -0.0625, -0.4375, 0.5}, -- board2 from left
				{0.0625, -0.5, -0.5, 0.1875, -0.4375, 0.5}, -- board3 from left
				{0.3125, -0.5, -0.5, 0.4375, -0.4375, 0.5}, -- board4 from left
				{-0.5, -0.4375, 0.3125, 0.5, -0.375, 0.375}, -- rail1 from front
				{-0.5, -0.4375, -0.375, 0.5, -0.375, -0.3125}, -- rail2 from front
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', '', 'building_elements:blueprint' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ 'building_elements:blueprint', '', 'building_elements:blueprint'},
		}
	})

end

--SLABS OF VARIOUS THICKNESS
building_elements.register_slab_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-1/2, -1/2, -1/2, 1/2, 0, 1/2}
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', '', '' },
			{ '', '', ''},
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
		}
	})

end

--STAIRS
building_elements.register_stair_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-1/2, -1/2, -1/2, 1/2, 0, 1/2},
				{-1/2, 0, 0, 1/2, 1/2, 1/2},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', '', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
		}
	})

end

--TREES
building_elements.register_tree_branch_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.125, -0.0625, -0.0625, 0.125, 0.0625, 0.0625}, -- Base_x
				{-0.0625, -0.125, -0.0625, 0.0625, 0.125, 0.0625}, -- Base_y
				{-0.0625, -0.0625, -0.125, 0.0625, 0.0625, 0.125}, -- Base_z
				{-0.125, -0.0625, -0.5, 0.125, 0.0625, -0.0625}, -- Front_h_zneg
				{-0.0625, -0.125, -0.5, 0.0625, 0.125, -0.0625}, -- Front_v_zneg
				{0.0625, -0.0625, -0.125, 0.5, 0.0625, 0.125}, -- Right_h_xpos
				{0.0625, -0.125, -0.0625, 0.5, 0.125, 0.0625}, -- Right_v_xpos
				{-0.125, 0.0625, -0.0625, 0.125, 0.5, 0.0625}, -- Top_x_ypos
				{-0.0625, 0.0625, -0.125, 0.0625, 0.5, 0.125}, -- Top_z_ypos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:blueprint', ''},
			{ '', '', ''},
		}
	})

end
building_elements.register_tree_root_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.4375, -0.5, -0.5, 0.4375, -0.25, 0.5},
				{-0.5, -0.5, -0.4375, 0.5, -0.25, 0.4375},
				{-0.375, -0.25, -0.4375, 0.375, 0, 0.4375},
				{-0.4375, -0.25, -0.375, 0.4375, 0, 0.375},
				{-0.375, 0, -0.3125, 0.375, 0.5, 0.3125},
				{-0.3125, 0, -0.375, 0.3125, 0.5, 0.375},
		    },
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', ''},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_tree_trunk_large_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			{-0.3125, 0.1875, -0.25, 0.3125, 0.5, 0.25}, -- ConnectTopX
			{-0.25, 0.1875, -0.3125, 0.25, 0.5, 0.3125}, -- ConnectTopZ
			{-0.3125, -0.1875, -0.25, 0.3125, 0.1875, 0.25}, -- BaseX
			{-0.25, -0.1875, -0.3125, 0.25, 0.1875, 0.3125}, -- BaseZ
			{-0.3125, -0.5, -0.25, 0.3125, -0.1875, 0.25}, -- ConnectBottomX
			{-0.25, -0.5, -0.3125, 0.25, -0.1875, 0.3125}, -- ConnectBottomZ
			{0.3125, -0.1875, -0.125, 0.5, 0.1875, 0.125}, -- ConnectRightX_xpos
			{0.3125, -0.125, -0.1875, 0.5, 0.125, 0.1875}, -- ConnectRightZ_xpos
			{-0.125, -0.1875, -0.5, 0.125, 0.1875, -0.3125}, -- ConnectFrontY_zneg
			{-0.1875, -0.125, -0.5, 0.1875, 0.125, -0.3125}, -- ConnectFrontZ_zneg
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_tree_trunk_medium_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			{-0.25, 0.1875, -0.1875, 0.25, 0.5, 0.1875}, -- ConnectTopX
			{-0.1875, 0.1875, -0.25, 0.1875, 0.5, 0.25}, -- ConnectTopZ
			{-0.25, -0.1875, -0.1875, 0.25, 0.1875, 0.1875}, -- BaseX
			{-0.1875, -0.1875, -0.25, 0.1875, 0.1875, 0.25}, -- BaseZ
			{-0.25, -0.5, -0.1875, 0.25, -0.1875, 0.1875}, -- ConnectBottomX
			{-0.1875, -0.5, -0.25, 0.1875, -0.1875, 0.25}, -- ConnectBottomZ
			{0.25, -0.1875, -0.125, 0.5, 0.1875, 0.125}, -- ConnectRightX_xpos
			{0.25, -0.125, -0.1875, 0.5, 0.125, 0.1875}, -- ConnectRightZ_xpos
			{-0.5, -0.125, -0.1875, -0.25, 0.125, 0.1875}, -- ConnectLeftX_xneg
			{-0.5, -0.1875, -0.125, -0.25, 0.1875, 0.125}, -- ConnectLeftZ_xneg
			{-0.125, -0.1875, -0.5, 0.125, 0.1875, -0.25}, -- ConnectFrontY_zneg
			{-0.1875, -0.125, -0.5, 0.1875, 0.125, -0.25}, -- ConnectFrontZ_zneg
			{-0.125, -0.1875, 0.25, 0.125, 0.1875, 0.5}, -- ConnectBackY_zpos
			{-0.1875, -0.1875, 0.25, 0.1875, 0.1875, 0.5}, -- ConnectBackZ_zpos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end
building_elements.register_tree_trunk_small_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:tree", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, tree = 1, wood = 1 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			{-0.1875, 0.1875, -0.125, 0.1875, 0.5, 0.125}, -- ConnectTopX
			{-0.125, 0.1875, -0.1875, 0.125, 0.5, 0.1875}, -- ConnectTopZ
			{-0.1875, -0.1875, -0.125, 0.1875, 0.1875, 0.125}, -- BaseX
			{-0.125, -0.1875, -0.1875, 0.125, 0.1875, 0.1875}, -- BaseZ
			{-0.1875, -0.5, -0.125, 0.1875, -0.1875, 0.125}, -- ConnectBottomX
			{-0.125, -0.5, -0.1875, 0.125, -0.1875, 0.1875}, -- ConnectBottomZ
			{0.1875, -0.0625, -0.125, 0.5, 0.0625, 0.125}, -- ConnectRightX_xpos
			{0.1875, -0.125, -0.0625, 0.5, 0.125, 0.0625}, -- ConnectRightZ_xpos
			{-0.5, -0.0625, -0.125, -0.1875, 0.0625, 0.125}, -- ConnectLeftX_xneg
			{-0.5, -0.125, -0.0625, -0.1875, 0.125, 0.0625}, -- ConnectLeftZ_xneg
			{-0.0625, -0.125, -0.5, 0.0625, 0.125, -0.1875}, -- ConnectFrontY_zneg
			{-0.125, -0.0625, -0.5, 0.125, 0.0625, -0.1875}, -- ConnectFrontZ_zneg
			{-0.0625, -0.125, 0.1875, 0.0625, 0.125, 0.5}, -- ConnectBackY_zpos
			{-0.125, -0.0625, 0.1875, 0.125, 0.0625, 0.5}, -- ConnectBackZ_zpos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ '', 'building_elements:blueprint', ''},
		}
	})

end

--WALLS (CENTER ALIGNED, VERTICAL SLABS)
building_elements.register_wall_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {{-1/4, -1/2, -1/2, 1/4, 1/2, 1/2}},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ 'building_elements:blueprint', 'building_elements:blueprint', 'building_elements:blueprint'},
		}
	})

end
building_elements.register_wall_thin_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {{-3/16, -1/2, -1/2, 3/16, 1/2, 1/2}},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ '', 'building_elements:blueprint', 'building_elements:blueprint' },
			{ '', 'building_elements:blueprint', 'building_elements:blueprint'},
			{ '', 'building_elements:blueprint', 'building_elements:blueprint'},
		}
	})

end
building_elements.register_wall_section_shape = function(wall_name, wall_desc, wall_texture)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture .. "^align_grid_ypos.png",
			wall_texture .. "^align_grid_yneg.png",
			wall_texture .. "^align_grid_xpos.png",
			wall_texture .. "^align_grid_xneg.png",
			wall_texture .. "^align_grid_zpos.png",
			wall_texture .. "^align_grid_zneg.png",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2 },
		--sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-3/16, -1/2, -3/16, 3/16, 1/2, 3/16},
				{ 3/16, -1/2, -3/16,  1/2, 1/2,  3/16},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 1",
		recipe = {
			{ 'building_elements:blueprint', 'building_elements:blueprint', '' },
			{ 'building_elements:blueprint', 'building_elements:blueprint', ''},
			{ 'building_elements:blueprint', 'building_elements:blueprint', ''},
		}
	})

end

building_elements.register_shapes("grey_noise.png")


--FUNCTIONS THAT ASSIGN THE DESIRED NODE TYPE (ie, STONE, WOOD, TREE, GLASS,  Elements are assigned at bottom.  Just add to the list.)
--Functions here correspond to functions above, with each function assigning a particular shape to a particular node type.
function building_elements.register_nodes(node_name, node_desc, node_texture, node_craft_mat, node_sounds)
--BOXES


--COLUMNS
	building_elements.register_column_end_half("column_end_half" .. node_name, node_desc .. "Column End Half", node_texture, node_craft_mat, node_sounds)
	building_elements.register_column_end_half_with_wall("column_end_half_with_wall" .. node_name, node_desc .. "Column End Half with Wall", node_texture, node_craft_mat, node_sounds)
	building_elements.register_column_end_full("column_end_full" .. node_name, node_desc .. "Column End Full", node_texture, node_craft_mat, node_sounds)

--CROSSLINK BEAMS FOR ABOVE COLUMNS
	building_elements.register_cross_link("cross_link" .. node_name, node_desc .. "Cross Link", node_texture, node_craft_mat, node_sounds)
	building_elements.register_cross_link_support("cross_link_support" .. node_name, node_desc .. "Cross Link Support", node_texture, node_craft_mat, node_sounds)

--DOORS, GATES
	building_elements.register_door_centered_right("door_centered_right" .. node_name, node_desc .. "Centered Door Right", node_texture, node_craft_mat, node_sounds)
	building_elements.register_door_centered("door_centered" .. node_name, node_desc .. "Centered Door", node_texture, node_craft_mat, node_sounds)

	building_elements.register_door_with_window_centered_right("door_with_window_centered_right" .. node_name, node_desc .. "Centered Door with Window Right", node_texture, node_craft_mat, node_sounds)

	building_elements.register_door_with_window_centered("door_with_window_centered" .. node_name, node_desc .. "Centered Door with Window", node_texture, node_craft_mat, node_sounds)
	building_elements.register_fencegate_solid_centered_right("fencegate_solid_centered_right" .. node_name, node_desc .. "Centered Solid Fencegate Right", node_texture, node_craft_mat, node_sounds)
	building_elements.register_fencegate_solid_centered("fencegate_solid_centered" .. node_name, node_desc .. "Centered Solid Fencegate", node_texture, node_craft_mat, node_sounds)
	building_elements.register_fencegate_centered_right("fencegate_centered_right" .. node_name, node_desc .. "Centered Fencegate Right", node_texture, node_craft_mat, node_sounds)
	building_elements.register_fencegate_centered("fencegate_centered" .. node_name, node_desc .. "Centered Fencegate", node_texture, node_craft_mat, node_sounds)

--FENCES
	building_elements.register_fence("fence" .. node_name, node_desc .. "Fence", node_texture, node_craft_mat, node_sounds)

--GENERIC SIMPLE SHAPES AND LINKAGES
	building_elements.register_linkage("linkage" .. node_name, node_desc .. "Linkage", node_texture, node_craft_mat, node_sounds)
	building_elements.register_linkage_medium_half("linkage_medium_half" .. node_name, node_desc .. "Linkage Medium Half", node_texture, node_craft_mat, node_sounds)
	building_elements.register_linkage_small_quarter("linkage_small_quarter" .. node_name, node_desc .. "Linkage Small Quarter", node_texture, node_craft_mat, node_sounds)
	building_elements.register_linkage_round_med_half("linkage_round_med_half" .. node_name, node_desc .. "Linkage Round Medium Half", node_texture, node_craft_mat, node_sounds)
	building_elements.register_linkage_round_small_quarter("linkage_round_small_quarter" .. node_name, node_desc .. "Linkage Round Small Quarter", node_texture, node_craft_mat, node_sounds)
	building_elements.register_cylinder("cylinder" .. node_name, node_desc .. "Cylinder", node_texture, node_craft_mat, node_sounds)
	building_elements.register_cylinder_3qtr("cylinder_3qtr" .. node_name, node_desc .. "Cylinder 3/4", node_texture, node_craft_mat, node_sounds)
	building_elements.register_cylinder_half("cylinder_half" .. node_name, node_desc .. "Cylinder 1/2", node_texture, node_craft_mat, node_sounds)
	building_elements.register_cylinder_1qtr("cylinder_1qtr" .. node_name, node_desc .. "Cylinder 1/4", node_texture, node_craft_mat, node_sounds)
	building_elements.register_cylinder_to_cross("cylinder_to_cross" .. node_name, node_desc .. "Cylinder to Cross", node_texture, node_craft_mat, node_sounds)
	building_elements.register_octagon("octagon" .. node_name, node_desc .. "Octagon", node_texture, node_craft_mat, node_sounds)


--PILLARS (ALSO WITH WALL SECTIONS)
	building_elements.register_pillar("pillar" .. node_name, node_desc .. "Pillar", node_texture, node_craft_mat, node_sounds)
	building_elements.register_pillar_junction("pillar_junction" .. node_name, node_desc .. "Pillar Junction", node_texture, node_craft_mat, node_sounds)
	building_elements.register_pillar_with_center_link("pillar_with_center_link" .. node_name, node_desc .. "Pillar with Center Link", node_texture, node_craft_mat, node_sounds)
	building_elements.register_pillar_with_curtain_wall("pillar_with_curtain_wall" .. node_name, node_desc .. "Pillar with Curtain Wall", node_texture, node_craft_mat, node_sounds)
	building_elements.register_pillar_with_default_wall("pillar_with_default_wall" .. node_name, node_desc .. "Pillar with Default Wall", node_texture, node_craft_mat, node_sounds)
	building_elements.register_pillar_with_half_wall("pillar_with_half_wall" .. node_name, node_desc .. "Pillar with Half Wall", node_texture, node_craft_mat, node_sounds)
	building_elements.register_pillar_with_full_wall("pillar_with_full_wall" .. node_name, node_desc .. "Pillar with Full Wall", node_texture, node_craft_mat, node_sounds)

--RAILING AND TRIM ITEMS
	building_elements.register_railing("railing" .. node_name, node_desc .. "Railing", node_texture, node_craft_mat, node_sounds)

--FLAT SLABS (TO INCLUDE ROADS)
	building_elements.register_road("road" .. node_name, node_desc .. "Road", node_texture, node_craft_mat, node_sounds)

--LADDERS, CAGE BARS, TRAIN TRACKS, LATTICES
	building_elements.register_track("track" .. node_name, node_desc .. "Train/Cart Track", node_texture, node_craft_mat, node_sounds)

--SLABS OF VARIOUS THICKNESS
	building_elements.register_slab("slab" .. node_name, node_desc .. "Slab", node_texture, node_craft_mat, node_sounds)

--STAIRS
	building_elements.register_stair("stair" .. node_name, node_desc .. "Stair", node_texture, node_craft_mat, node_sounds)

--TREES
	building_elements.register_tree_branch("tree_branch" .. node_name, node_desc .. "Tree Branch", node_texture, node_craft_mat, node_sounds)
	building_elements.register_tree_root("tree_root" .. node_name, node_desc .. "Tree Root", node_texture, node_craft_mat, node_sounds)
	building_elements.register_tree_trunk_large("tree_trunk_large" .. node_name, node_desc .. "Tree Trunk Large", node_texture, node_craft_mat, node_sounds)
	building_elements.register_tree_trunk_medium("tree_trunk_medium" .. node_name, node_desc .. "Tree Trunk Medium", node_texture, node_craft_mat, node_sounds)
	building_elements.register_tree_trunk_small("tree_trunk_small" .. node_name, node_desc .. "Tree Trunk Small", node_texture, node_craft_mat, node_sounds)

--WALLS (CENTER ALIGNED, VERTICAL SLABS)
	building_elements.register_wall("wall" .. node_name, node_desc .. "Wall", node_texture, node_craft_mat, node_sounds)
	building_elements.register_wall_thin("wall_thin" .. node_name, node_desc .. "Wall Thin", node_texture, node_craft_mat, node_sounds)
	building_elements.register_wall_section("wall_section" .. node_name, node_desc .. "Wall Section", node_texture, node_craft_mat, node_sounds)

end

--COLUMNS
building_elements.register_column_end_half = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			   {-0.25, -0.5, -0.25, 0.25, 0.5, 0.25},
			   {-0.5, 0, -0.25, 0.5, 0.5, 0.25},
			   {-0.25, 0, -0.5, 0.25, 0.5, 0.5},
			   {-0.4375, 0.0625, -0.4375, 0.4375, 0.4375, 0.4375},
		    },
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5,0,-0.5,0.5,0.5,0.5},
			   {-0.25, -0.5, -0.25, 0.25, 0, 0.25},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5,0,-0.5,0.5,0.5,0.5},
			   {-0.25, -0.5, -0.25, 0.25, 0, 0.25},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:column_end_half_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_column_end_half_with_wall = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			   {-0.25, -0.5, -0.25, 0.25, 0.5, 0.25},
			   {-0.5, 0, -0.25, 0.5, 0.5, 0.25},
			   {-0.25, 0, -0.5, 0.25, 0.5, 0.5},
			   {-0.4375, 0.0625, -0.4375, 0.4375, 0.4375, 0.4375},
			   {-3/16, -1/2, -1/2,  3/16, 0, -1/4},
		    },
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:column_end_half_with_wall_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_column_end_full = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			   {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
			   {-0.5, -0.25, -0.25, 0.5, 0.5, 0.25},
			   {-0.25, -0.25, -0.5, 0.25, 0.5, 0.5},
			   {-0.4375, -0.25, -0.4375, 0.4375, 0.4375, 0.4375},
		    },
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,0.5,0.5},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,0.5,0.5},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:column_end_full_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end

--CROSSLINK BEAMS FOR ABOVE COLUMNS
building_elements.register_cross_link = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			    {-0.25, 0, -0.5, 0.25, 0.5, 0.5},
		    },
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.25, 0, -0.5, 0.25, 0.5, 0.5},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{ -0.25, 0, -0.5, 0.25, 0.5, 0.5},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:cross_link_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_cross_link_support = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
			   {-0.25, 0, -0.5, 0.25, 0.5, 0.5},
			   {-0.125, -0.5, -0.125, 0.125, 0, 0.125},
			   {-0.1875, -0.5, -0.1875, 0.1875, -0.375, 0.1875},
			   {-0.1875, -0.125, -0.1875, 0.1875, 0, 0.1875},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
			   {-0.25, 0, -0.5, 0.25, 0.5, 0.5},
			   {-0.1875, -0.5, -0.1875, 0.1875, 0, 0.1875},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
			   {-0.25, 0, -0.5, 0.25, 0.5, 0.5},
			   {-0.1875, -0.5, -0.1875, 0.1875, 0, 0.1875},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:cross_link_support_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end


--DOORS	
building_elements.register_door_centered_right = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)

	local name = ""

	if not wall_name:find(":") then
		name = "building_elements:" .. wall_name
	end

	local name_closed = name
	local name_opened = name.."_open"
	local skel_key = false


	local def = {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			building_elements.door_toggle(pos, node, clicker)
			return itemstack
		end,

		-- Common door configuration
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = wall_sounds,
		sound_open = "doors_door_open",
		sound_close = "doors_door_close",
		protected = false,
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, fence = 1, wall = 1, stone = 1, wood = 1, glass = 1},
		--groups = minetest.registered_nodes[wall_mat].groups,
		tiles = {wall_texture},
	}
	if skel_key then
		def.can_dig = can_dig_door
		def.after_place_node = function(pos, placer, itemstack, pointed_thing)
			local pn = placer:get_player_name()
			local meta = minetest.get_meta(pos)
			meta:set_string("doors_owner", pn)
			meta:set_string("infotext", "Owned by "..pn)

			return minetest.setting_getbool("creative_mode")
		end

		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local door = building_elements.get(pos)
			building_elements:toggle(player)
		end
		def.on_skeleton_key_use = function(pos, player, newsecret)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("doors_owner")
			local pname = player:get_player_name()

			-- verify placer is owner of lockable door
			if owner ~= pname then
				minetest.record_protection_violation(pos, pname)
				minetest.chat_send_player(pname, "You do not own this trapdoor.")
				return nil
			end

			local secret = meta:get_string("key_lock_secret")
			if secret == "" then
				secret = newsecret
				meta:set_string("key_lock_secret", secret)
			end

			return secret, "a locked trapdoor", owner
		end
	else
		def.on_blast = function(pos, intensity)
			minetest.remove_node(pos)
			return {name}
		end
	end


	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_closed.node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.0625, 0.5, 1.5, 0.0625}
	}
	def_closed.selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.0625, 0.5, 1.5, 0.0625}
	}

	def_opened.node_box = {
		type = "fixed",
		fixed = {0.375, -0.5, 0, 0.5, 1.5, 1.0}
	}
	def_opened.selection_box = {
		type = "fixed",
		fixed = {0.375, -0.5, 0, 0.5, 1.5, 1.0}
	}

	def_opened.drop = name_closed
	def_opened.groups.not_in_creative_inventory = 1

	minetest.register_node(name_opened, def_opened)
	minetest.register_node(name_closed, def_closed)

	building_elements.registered_doors[name_opened] = true
	building_elements.registered_doors[name_closed] = true

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:door_centered_right_shape', ''},
			{ '', wall_mat, ''},
		}
	})
end
building_elements.register_door_centered = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)

	local name = ""

	if not wall_name:find(":") then
		name = "building_elements:" .. wall_name
	end

	local name_closed = name
	local name_opened = name.."_open"
	local skel_key = false


	local def = {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			building_elements.door_toggle(pos, node, clicker)
			return itemstack
		end,

		-- Common door configuration
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = wall_sounds,
		sound_open = "doors_door_open",
		sound_close = "doors_door_close",
		protected = false,
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, fence = 1, wall = 1, stone = 1, wood = 1, glass = 1},
		--groups = minetest.registered_nodes[wall_mat].groups,
		tiles = {wall_texture},
	}
	if skel_key then
		def.can_dig = can_dig_door
		def.after_place_node = function(pos, placer, itemstack, pointed_thing)
			local pn = placer:get_player_name()
			local meta = minetest.get_meta(pos)
			meta:set_string("doors_owner", pn)
			meta:set_string("infotext", "Owned by "..pn)

			return minetest.setting_getbool("creative_mode")
		end

		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local door = building_elements.get(pos)
			building_elements:toggle(player)
		end
		def.on_skeleton_key_use = function(pos, player, newsecret)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("doors_owner")
			local pname = player:get_player_name()

			-- verify placer is owner of lockable door
			if owner ~= pname then
				minetest.record_protection_violation(pos, pname)
				minetest.chat_send_player(pname, "You do not own this trapdoor.")
				return nil
			end

			local secret = meta:get_string("key_lock_secret")
			if secret == "" then
				secret = newsecret
				meta:set_string("key_lock_secret", secret)
			end

			return secret, "a locked trapdoor", owner
		end
	else
		def.on_blast = function(pos, intensity)
			minetest.remove_node(pos)
			return {name}
		end
	end


	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_closed.node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.0625, 0.5, 1.5, 0.0625}
	}
	def_closed.selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.0625, 0.5, 1.5, 0.0625}
	}

	def_opened.node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, 0, -0.375, 1.5, 1.0}
	}
	def_opened.selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, 0, -0.375, 1.5, 1.0}
	}

	def_opened.drop = name_closed
	def_opened.groups.not_in_creative_inventory = 1

	minetest.register_node(name_opened, def_opened)
	minetest.register_node(name_closed, def_closed)

	building_elements.registered_doors[name_opened] = true
	building_elements.registered_doors[name_closed] = true

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:door_centered_shape', ''},
			{ '', wall_mat, ''},
		}
	})
end
building_elements.register_door_with_window_centered_right = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)

	local name = ""

	if not wall_name:find(":") then
		name = "building_elements:" .. wall_name
	end

	local name_closed = name
	local name_opened = name.."_open"
	local skel_key = false


	local def = {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			building_elements.door_toggle(pos, node, clicker)
			return itemstack
		end,

		-- Common door configuration
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = wall_sounds,
		sound_open = "doors_door_open",
		sound_close = "doors_door_close",
		protected = false,
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, fence = 1, wall = 1, stone = 1, wood = 1, glass = 1},
		--groups = minetest.registered_nodes[wall_mat].groups,
		tiles = {wall_texture},
	}
	if skel_key then
		def.can_dig = can_dig_door
		def.after_place_node = function(pos, placer, itemstack, pointed_thing)
			local pn = placer:get_player_name()
			local meta = minetest.get_meta(pos)
			meta:set_string("doors_owner", pn)
			meta:set_string("infotext", "Owned by "..pn)

			return minetest.setting_getbool("creative_mode")
		end

		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local door = building_elements.get(pos)
			building_elements:toggle(player)
		end
		def.on_skeleton_key_use = function(pos, player, newsecret)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("doors_owner")
			local pname = player:get_player_name()

			-- verify placer is owner of lockable door
			if owner ~= pname then
				minetest.record_protection_violation(pos, pname)
				minetest.chat_send_player(pname, "You do not own this trapdoor.")
				return nil
			end

			local secret = meta:get_string("key_lock_secret")
			if secret == "" then
				secret = newsecret
				meta:set_string("key_lock_secret", secret)
			end

			return secret, "a locked trapdoor", owner
		end
	else
		def.on_blast = function(pos, intensity)
			minetest.remove_node(pos)
			return {name}
		end
	end


	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_closed.node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, 0.5, 0.5, 0.0625}, --Base
			{-0.5, 0.5, -0.0625, 0.5, 0.625, 0.0625}, -- Bottom_x
			{-0.5, 1.375, -0.0625, 0.5, 1.5, 0.0625}, -- Top_x
			{0.375, 0.625, -0.0625, 0.5, 1.375, 0.0625}, -- Right_y
			{-0.5, 0.625, -0.0625, -0.375, 1.375, 0.0625}, -- Left_y
			{-0.375, 0.9375, -0.0625, 0.375, 1.0625, 0.0625}, -- Center_x
			{-0.0625, 0.625, -0.0625, 0.0625, 1.375, 0.0625}, -- Center_y
		}
	}
	def_closed.selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, 0.5, 1.5, 0.0625}, --Base
		}
--[[
			{-0.5, 0.5, -0.0625, 0.5, 0.625, 0.0625}, -- Bottom_x
			{-0.5, 1.375, -0.0625, 0.5, 1.5, 0.0625}, -- Top_x
			{0.375, 0.875, -0.0625, 0.5, 1.375, 0.0625}, -- Right_y
			{-0.5, 0.875, -0.0625, -0.375, 1.375, 0.0625}, -- Left_y
			{-0.375, 0.9375, -0.0625, 0.375, 1.0625, 0.0625}, -- Center_x
			{-0.0625, 0.875, -0.0625, 0.0625, 1.375, 0.0625}, -- Center_y
		}
]]
	}

	def_opened.node_box = {
		type = "fixed",
		fixed = {
			{0.375, -0.5, 0, 0.5, 0.5, 1.0}, --Base
			{0.375, 0.5, 0, 0.5, 0.625, 1.0}, -- Bottom_x
			{0.375, 1.375, 0, 0.5, 1.5, 1.0}, -- Top_x
			{0.375, 0.625, 0, 0.5, 1.375, 0.125}, -- Right_y
			{0.375, 0.625, 0.875, 0.5, 1.375, 1.0}, -- Left_y
			{0.375, 0.9375, 0.0625, 0.5, 1.0625, 0.9375}, -- Center_x
			{0.375, 0.625, 0.4375, 0.5, 1.375, 0.5625}, -- Center_y
		}
	}
	def_opened.selection_box = {
		type = "fixed",
		fixed = {0.375, -0.5, 0, 0.5, 1.5, 1.0}
	}

	def_opened.drop = name_closed
	def_opened.groups.not_in_creative_inventory = 1

	minetest.register_node(name_opened, def_opened)
	minetest.register_node(name_closed, def_closed)

	building_elements.registered_doors[name_opened] = true
	building_elements.registered_doors[name_closed] = true

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:door_with_window_centered_right_shape', ''},
			{ '', wall_mat, ''},
		}
	})
end
building_elements.register_door_with_window_centered = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)

	local name = ""

	if not wall_name:find(":") then
		name = "building_elements:" .. wall_name
	end

	local name_closed = name
	local name_opened = name.."_open"
	local skel_key = false


	local def = {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			building_elements.door_toggle(pos, node, clicker)
			return itemstack
		end,

		-- Common door configuration
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = wall_sounds,
		sound_open = "doors_door_open",
		sound_close = "doors_door_close",
		protected = false,
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, fence = 1, wall = 1, stone = 1, wood = 1, glass = 1},
		--groups = minetest.registered_nodes[wall_mat].groups,
		tiles = {wall_texture},
	}
	if skel_key then
		def.can_dig = can_dig_door
		def.after_place_node = function(pos, placer, itemstack, pointed_thing)
			local pn = placer:get_player_name()
			local meta = minetest.get_meta(pos)
			meta:set_string("doors_owner", pn)
			meta:set_string("infotext", "Owned by "..pn)

			return minetest.setting_getbool("creative_mode")
		end

		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local door = building_elements.get(pos)
			building_elements:toggle(player)
		end
		def.on_skeleton_key_use = function(pos, player, newsecret)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("doors_owner")
			local pname = player:get_player_name()

			-- verify placer is owner of lockable door
			if owner ~= pname then
				minetest.record_protection_violation(pos, pname)
				minetest.chat_send_player(pname, "You do not own this trapdoor.")
				return nil
			end

			local secret = meta:get_string("key_lock_secret")
			if secret == "" then
				secret = newsecret
				meta:set_string("key_lock_secret", secret)
			end

			return secret, "a locked trapdoor", owner
		end
	else
		def.on_blast = function(pos, intensity)
			minetest.remove_node(pos)
			return {name}
		end
	end


	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_closed.node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, 0.5, 0.5, 0.0625}, --Base
			{-0.5, 0.5, -0.0625, 0.5, 0.625, 0.0625}, -- Bottom_x
			{-0.5, 1.375, -0.0625, 0.5, 1.5, 0.0625}, -- Top_x
			{0.375, 0.625, -0.0625, 0.5, 1.375, 0.0625}, -- Right_y
			{-0.5, 0.625, -0.0625, -0.375, 1.375, 0.0625}, -- Left_y
			{-0.375, 0.9375, -0.0625, 0.375, 1.0625, 0.0625}, -- Center_x
			{-0.0625, 0.625, -0.0625, 0.0625, 1.375, 0.0625}, -- Center_y
		}
	}
	def_closed.selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, 0.5, 1.5, 0.0625}, --Base
		}
--[[
			{-0.5, 0.5, -0.0625, 0.5, 0.625, 0.0625}, -- Bottom_x
			{-0.5, 1.375, -0.0625, 0.5, 1.5, 0.0625}, -- Top_x
			{0.375, 0.625, -0.0625, 0.5, 1.375, 0.0625}, -- Right_y
			{-0.5, 0.625, -0.0625, -0.375, 1.375, 0.0625}, -- Left_y
			{-0.375, 0.9375, -0.0625, 0.375, 1.0625, 0.0625}, -- Center_x
			{-0.0625, 0.625, -0.0625, 0.0625, 1.375, 0.0625}, -- Center_y
		}
]]
	}

	def_opened.node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, 0, -0.375, 0.5, 1.0}, --Base
			{-0.5, 0.5, 0, -0.375, 0.625, 1.0}, -- Bottom_x
			{-0.5, 1.375, 0, -0.375, 1.5, 1.0}, -- Top_x
			{-0.5, 0.625, 0.875, -0.375, 1.375, 1.0}, -- Right_y
			{-0.5, 0.625, 0, -0.375, 1.375, 0.125}, -- Left_y
			{-0.5, 0.9375, 0.125, -0.375, 1.0625, 0.9375}, -- Center_x
			{-0.5, 0.625, 0.4375, -0.375, 1.375, 0.5625}, -- Center_y
		}
	}
	def_opened.selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, 0, -0.375, 1.5, 1.0}, --Base
		}
--[[
			{-0.5, 0.5, 0, -0.375, 0.625, 1.0}, -- Bottom_x
			{-0.5, 1.375, 0, -0.375, 1.5, 1.0}, -- Top_x
			{-0.5, 0.625, 0.875, -0.375, 1.375, 1.0}, -- Right_y
			{-0.5, 0.625, 0, -0.375, 1.375, 0.125}, -- Left_y
			{-0.5, 0.9375, 0.125, -0.375, 1.0625, 0.9375}, -- Center_x
			{-0.5, 0.625, 0.4375, -0.375, 1.375, 0.5625}, -- Center_y
		}
]]
	}

	def_opened.drop = name_closed
	def_opened.groups.not_in_creative_inventory = 1

	minetest.register_node(name_opened, def_opened)
	minetest.register_node(name_closed, def_closed)

	building_elements.registered_doors[name_opened] = true
	building_elements.registered_doors[name_closed] = true

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:door_with_window_centered_shape', ''},
			{ '', wall_mat, ''},
		}
	})
end
building_elements.register_fencegate_solid_centered_right = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)

	local name = ""

	if not wall_name:find(":") then
		name = "building_elements:" .. wall_name
	end

	local name_closed = name
	local name_opened = name.."_open"
	local skel_key = false


	local def = {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			building_elements.door_toggle(pos, node, clicker)
			return itemstack
		end,

		-- Common door configuration
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = wall_sounds,
		sound_open = "doors_door_open",
		sound_close = "doors_door_close",
		protected = false,
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, fence = 1, wall = 1, stone = 1, wood = 1, glass = 1},
		--groups = minetest.registered_nodes[wall_mat].groups,
		tiles = {wall_texture},
	}
	if skel_key then
		def.can_dig = can_dig_door
		def.after_place_node = function(pos, placer, itemstack, pointed_thing)
			local pn = placer:get_player_name()
			local meta = minetest.get_meta(pos)
			meta:set_string("doors_owner", pn)
			meta:set_string("infotext", "Owned by "..pn)

			return minetest.setting_getbool("creative_mode")
		end

		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local door = building_elements.get(pos)
			building_elements:toggle(player)
		end
		def.on_skeleton_key_use = function(pos, player, newsecret)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("doors_owner")
			local pname = player:get_player_name()

			-- verify placer is owner of lockable door
			if owner ~= pname then
				minetest.record_protection_violation(pos, pname)
				minetest.chat_send_player(pname, "You do not own this trapdoor.")
				return nil
			end

			local secret = meta:get_string("key_lock_secret")
			if secret == "" then
				secret = newsecret
				meta:set_string("key_lock_secret", secret)
			end

			return secret, "a locked trapdoor", owner
		end
	else
		def.on_blast = function(pos, intensity)
			minetest.remove_node(pos)
			return {name}
		end
	end


	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_closed.node_box = {
		type = "fixed",
		fixed = {
			{0.375, -0.5, -0.125, 0.5, 0.5, 0.125}, -- Post_y
			{-0.5, -0.375, -0.0625, 0.375, 0.4375, 0.0625},
		}
	}
	def_closed.selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, 0.5, 0.5, 0.125}, -- Post_y
		}
	}

	def_opened.node_box = {
		type = "fixed",
		fixed = {
			{0.375, -0.5, -0.125, 0.5, 0.5, 0.125}, -- Post_y
			{0.3125, -0.5, 0, 0.4375, 0.5, 0.875},
		}
	}
	def_opened.selection_box = {
		type = "fixed",
		fixed = {0.3125, -0.5, -0.125, 0.5, 0.5, 0.875}
	}

	def_opened.drop = name_closed
	def_opened.groups.not_in_creative_inventory = 1

	minetest.register_node(name_opened, def_opened)
	minetest.register_node(name_closed, def_closed)

	building_elements.registered_doors[name_opened] = true
	building_elements.registered_doors[name_closed] = true

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:fencegate_solid_centered_right_shape', ''},
			{ '', wall_mat, ''},
		}
	})
end
building_elements.register_fencegate_solid_centered = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)

	local name = ""

	if not wall_name:find(":") then
		name = "building_elements:" .. wall_name
	end

	local name_closed = name
	local name_opened = name.."_open"
	local skel_key = false


	local def = {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			building_elements.door_toggle(pos, node, clicker)
			return itemstack
		end,

		-- Common door configuration
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = wall_sounds,
		sound_open = "doors_door_open",
		sound_close = "doors_door_close",
		protected = false,
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, fence = 1, wall = 1, stone = 1, wood = 1, glass = 1},
		--groups = minetest.registered_nodes[wall_mat].groups,
		tiles = {wall_texture},
	}
	if skel_key then
		def.can_dig = can_dig_door
		def.after_place_node = function(pos, placer, itemstack, pointed_thing)
			local pn = placer:get_player_name()
			local meta = minetest.get_meta(pos)
			meta:set_string("doors_owner", pn)
			meta:set_string("infotext", "Owned by "..pn)

			return minetest.setting_getbool("creative_mode")
		end

		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local door = building_elements.get(pos)
			building_elements:toggle(player)
		end
		def.on_skeleton_key_use = function(pos, player, newsecret)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("doors_owner")
			local pname = player:get_player_name()

			-- verify placer is owner of lockable door
			if owner ~= pname then
				minetest.record_protection_violation(pos, pname)
				minetest.chat_send_player(pname, "You do not own this trapdoor.")
				return nil
			end

			local secret = meta:get_string("key_lock_secret")
			if secret == "" then
				secret = newsecret
				meta:set_string("key_lock_secret", secret)
			end

			return secret, "a locked trapdoor", owner
		end
	else
		def.on_blast = function(pos, intensity)
			minetest.remove_node(pos)
			return {name}
		end
	end


	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_closed.node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, -0.375, 0.5, 0.125}, -- Post_y
			{-0.375, -0.375, -0.0625, 0.5, 0.4375, 0.0625},
		}
	}
	def_closed.selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, 0.5, 0.5, 0.125}, -- Post_y
		}
	}

	def_opened.node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, -0.375, 0.5, 0.125}, -- Post_y
			{-0.4375, -0.375, 0, -0.3125, 0.4375, 0.875},
		}
	}
	def_opened.selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, -0.3125, 0.5, 0.875}, -- Post_y
		}
	}

	def_opened.drop = name_closed
	def_opened.groups.not_in_creative_inventory = 1

	minetest.register_node(name_opened, def_opened)
	minetest.register_node(name_closed, def_closed)

	building_elements.registered_doors[name_opened] = true
	building_elements.registered_doors[name_closed] = true

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:fencegate_solid_centered_shape', ''},
			{ '', wall_mat, ''},
		}
	})
end
building_elements.register_fencegate_centered_right = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)

	local name = ""

	if not wall_name:find(":") then
		name = "building_elements:" .. wall_name
	end

	local name_closed = name
	local name_opened = name.."_open"
	local skel_key = false


	local def = {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			building_elements.door_toggle(pos, node, clicker)
			return itemstack
		end,

		-- Common door configuration
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = wall_sounds,
		sound_open = "doors_door_open",
		sound_close = "doors_door_close",
		protected = false,
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, fence = 1, wall = 1, stone = 1, wood = 1, glass = 1},
		--groups = minetest.registered_nodes[wall_mat].groups,
		tiles = {wall_texture},
	}
	if skel_key then
		def.can_dig = can_dig_door
		def.after_place_node = function(pos, placer, itemstack, pointed_thing)
			local pn = placer:get_player_name()
			local meta = minetest.get_meta(pos)
			meta:set_string("doors_owner", pn)
			meta:set_string("infotext", "Owned by "..pn)

			return minetest.setting_getbool("creative_mode")
		end

		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local door = building_elements.get(pos)
			building_elements:toggle(player)
		end
		def.on_skeleton_key_use = function(pos, player, newsecret)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("doors_owner")
			local pname = player:get_player_name()

			-- verify placer is owner of lockable door
			if owner ~= pname then
				minetest.record_protection_violation(pos, pname)
				minetest.chat_send_player(pname, "You do not own this trapdoor.")
				return nil
			end

			local secret = meta:get_string("key_lock_secret")
			if secret == "" then
				secret = newsecret
				meta:set_string("key_lock_secret", secret)
			end

			return secret, "a locked trapdoor", owner
		end
	else
		def.on_blast = function(pos, intensity)
			minetest.remove_node(pos)
			return {name}
		end
	end


	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_closed.node_box = {
		type = "fixed",
		fixed = {
			{0.375, -0.5, -0.125, 0.5, 0.5, 0.125}, -- Post_y
			{-0.375, 0.375, -0.0625, 0.4375, 0.5, 0.0625}, -- TopRail_x
			{-0.375, -0.375, -0.0625, 0.4375, -0.25, 0.0625}, -- BottomRail_x
			{-0.5, -0.375, -0.0625, -0.375, 0.5, 0.0625}, -- OuterSupport_y
			{-0.375, 0, -0.0625, 0.25, 0.125, 0.0625}, -- InnerRail_x
			{0.25, -0.25, -0.0625, 0.375, 0.375, 0.0625}, -- HingeSupport_y
		}
	}
	def_closed.selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, 0.5, 0.5, 0.125}, -- Post_y
		}
--[[
			{-0.375, 0.375, -0.0625, 0.4375, 0.5, 0.0625}, -- TopRail_x
			{-0.375, -0.375, -0.0625, 0.4375, -0.25, 0.0625}, -- BottomRail_x
			{-0.5, -0.375, -0.0625, -0.375, 0.5, 0.0625}, -- OuterSupport_y
			{-0.375, 0, -0.0625, 0.25, 0.125, 0.0625}, -- InnerRail_x
			{0.25, -0.25, -0.0625, 0.375, 0.375, 0.0625}, -- HingeSupport_y
		}
]]
	}

	def_opened.node_box = {
		type = "fixed",
		fixed = {
			{0.375, -0.5, -0.125, 0.5, 0.5, 0.125}, -- Post_y
			{0.3125, 0.375, 0, 0.4375, 0.5, 0.875}, -- TopRail_x
			{0.3125, -0.375, 0, 0.4375, -0.25, 0.875}, -- BottomRail_x
			{0.3125, -0.375, 0.875, 0.4375, 0.5, 1.0}, -- OuterSupport_y
			{0.3125, 0, 0.0625, 0.4375, 0.125, 0.875}, -- InnerRail_x
			{0.3125, -0.25, 0, 0.4375, 0.375, 0.125}, -- HingeSupport_y
		}
	}
	def_opened.selection_box = {
		type = "fixed",
		fixed = {
			{0.3125, -0.5, -0.125, 0.5, 0.5, 1.0}, -- Post_y
		}
--[[
			{0.3125, 0.375, 0, 0.4375, 0.5, 0.875}, -- TopRail_x
			{0.3125, -0.375, 0, 0.4375, -0.25, 0.875}, -- BottomRail_x
			{0.3125, -0.375, 0.875, 0.4375, 0.5, 1.0}, -- OuterSupport_y
			{0.3125, 0, 0.0625, 0.4375, 0.125, 0.875}, -- InnerRail_x
			{0.3125, -0.25, 0, 0.4375, 0.375, 0.125}, -- HingeSupport_y
		}
]]
	}

	def_opened.drop = name_closed
	def_opened.groups.not_in_creative_inventory = 1

	minetest.register_node(name_opened, def_opened)
	minetest.register_node(name_closed, def_closed)

	building_elements.registered_doors[name_opened] = true
	building_elements.registered_doors[name_closed] = true

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:fencegate_centered_right_shape', ''},
			{ '', wall_mat, ''},
		}
	})
end
building_elements.register_fencegate_centered = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)

	local name = ""

	if not wall_name:find(":") then
		name = "building_elements:" .. wall_name
	end

	local name_closed = name
	local name_opened = name.."_open"
	local skel_key = false


	local def = {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			building_elements.door_toggle(pos, node, clicker)
			return itemstack
		end,

		-- Common door configuration
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = wall_sounds,
		sound_open = "doors_door_open",
		sound_close = "doors_door_close",
		protected = false,
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, fence = 1, wall = 1, stone = 1, wood = 1, glass = 1},
		--groups = minetest.registered_nodes[wall_mat].groups,
		tiles = {wall_texture},
	}
	if skel_key then
		def.can_dig = can_dig_door
		def.after_place_node = function(pos, placer, itemstack, pointed_thing)
			local pn = placer:get_player_name()
			local meta = minetest.get_meta(pos)
			meta:set_string("doors_owner", pn)
			meta:set_string("infotext", "Owned by "..pn)

			return minetest.setting_getbool("creative_mode")
		end

		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local door = building_elements.get(pos)
			building_elements:toggle(player)
		end
		def.on_skeleton_key_use = function(pos, player, newsecret)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("doors_owner")
			local pname = player:get_player_name()

			-- verify placer is owner of lockable door
			if owner ~= pname then
				minetest.record_protection_violation(pos, pname)
				minetest.chat_send_player(pname, "You do not own this trapdoor.")
				return nil
			end

			local secret = meta:get_string("key_lock_secret")
			if secret == "" then
				secret = newsecret
				meta:set_string("key_lock_secret", secret)
			end

			return secret, "a locked trapdoor", owner
		end
	else
		def.on_blast = function(pos, intensity)
			minetest.remove_node(pos)
			return {name}
		end
	end


	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_closed.node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, -0.375, 0.5, 0.125}, -- Post_y
			{-0.4375, 0.375, -0.0625, 0.375, 0.5, 0.0625}, -- TopRail_x
			{-0.4375, -0.375, -0.0625, 0.375, -0.25, 0.0625}, -- BottomRail_x
			{0.375, -0.375, -0.0625, 0.5, 0.5, 0.0625}, -- OuterSupport_y
			{-0.25, 0, -0.0625, 0.375, 0.125, 0.0625}, -- InnerRail_x
			{-0.375, -0.25, -0.0625, -0.25, 0.375, 0.0625}, -- HingeSupport_y
		},
	}
	def_closed.selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, 0.5, 0.5, 0.125},
--[[

			{-0.5, -0.5, -0.125, -0.375, 0.5, 0.125}, -- Post_y
			{-0.4375, 0.375, -0.0625, 0.375, 0.5, 0.0625}, -- TopRail_x
			{-0.4375, -0.375, -0.0625, 0.375, -0.25, 0.0625}, -- BottomRail_x
			{0.375, -0.375, -0.0625, 0.5, 0.5, 0.0625}, -- OuterSupport_y
			{-0.25, 0, -0.0625, 0.375, 0.125, 0.0625}, -- InnerRail_x
			{-0.375, -0.25, -0.0625, -0.25, 0.375, 0.0625}, -- HingeSupport_y
]]
		},
	}

	def_opened.node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, -0.375, 0.5, 0.125}, -- Post_y
			{-0.4375, 0.375, 0, -0.3125, 0.5, 0.875}, -- TopRail_x
			{-0.4375, -0.375, 0, -0.3125, -0.25, 0.875}, -- BottomRail_x
			{-0.4375, -0.375, 0.875, -0.3125, 0.5, 1.0}, -- OuterSupport_y
			{-0.4375, 0, 0.125, -0.3125, 0.125, 0.875}, -- InnerRail_x
			{-0.4375, -0.25, 0, -0.3125, 0.375, 0.125}, -- HingeSupport_y
		},
	}
	def_opened.selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, -0.3125, 0.5, 1.0},
--[[
			{-0.5, -0.5, -0.125, -0.375, 0.5, 0.125}, -- Post_y
			{-0.4375, 0.375, 0, -0.3125, 0.5, 0.875}, -- TopRail_x
			{-0.4375, -0.375, 0, -0.3125, -0.25, 0.875}, -- BottomRail_x
			{-0.4375, -0.375, 0.875, -0.3125, 0.5, 1.0}, -- OuterSupport_y
			{-0.4375, 0, 0.125, -0.3125, 0.125, 0.875}, -- InnerRail_x
			{-0.4375, -0.25, 0, -0.3125, 0.375, 0.125}, -- HingeSupport_y
]]
		},
	}

	def_opened.drop = name_closed
	def_opened.groups.not_in_creative_inventory = 1

	minetest.register_node(name_opened, def_opened)
	minetest.register_node(name_closed, def_closed)

	building_elements.registered_doors[name_opened] = true
	building_elements.registered_doors[name_closed] = true

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:fencegate_centered_shape', ''},
			{ '', wall_mat, ''},
		}
	})
end

--FENCES
building_elements.register_fence_special = function(wall_name, wall_desc, wall_texture, wall_mat, wall_texture2, wall_mat2, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			"(fence_post_top_overlay.png^" .. wall_texture .. "^fence_post_top_overlay.png^[makealpha:255,126,126)^(fence_rail_top_overlay.png^" .. wall_texture2 .. "^fence_rail_top_overlay.png^[makealpha:255,126,126)",
			"(fence_post_top_overlay.png^" .. wall_texture .. "^fence_post_top_overlay.png^[makealpha:255,126,126)^(fence_rail_top_overlay.png^" .. wall_texture2 .. "^fence_rail_top_overlay.png^[makealpha:255,126,126)",
			"(fence_post_side_overlay.png^" .. wall_texture .. "^fence_post_side_overlay.png^[makealpha:255,126,126)^(fence_rail_side_overlay.png^" .. wall_texture2 .. "^fence_rail_side_overlay.png^[makealpha:255,126,126)",
			"(fence_post_side_overlay.png^" .. wall_texture .. "^fence_post_side_overlay.png^[makealpha:255,126,126)^(fence_rail_side_overlay.png^" .. wall_texture2 .. "^fence_rail_side_overlay.png^[makealpha:255,126,126)",
			"(fence_post_side_overlay.png^" .. wall_texture .. "^fence_post_side_overlay.png^[makealpha:255,126,126)^(fence_rail_side_overlay.png^" .. wall_texture2 .. "^fence_rail_side_overlay.png^[makealpha:255,126,126)",
			"(fence_post_side_overlay.png^" .. wall_texture .. "^fence_post_side_overlay.png^[makealpha:255,126,126)^(fence_rail_side_overlay.png^" .. wall_texture2 .. "^fence_rail_side_overlay.png^[makealpha:255,126,126)",
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone", "group:fence", "group:wood" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125},
			},
			connect_front = {
				{-0.0625, 0.1875, -0.5, 0.0625, 0.4375, -0.125}, -- Top
				{-0.0625, -0.3125, -0.5, 0.0625, -0.125, -0.125}, -- Bottom
			},
			connect_back = {
				{-0.0625, 0.1875, 0.125, 0.0625, 0.4375, 0.5}, -- Top
				{-0.0625, -0.3125, 0.125, 0.0625, -0.125, 0.5}, -- Bottom
			},
			connect_left = {
				{-0.5, 0.1875, -0.0625, -0.125, 0.4375, 0.0625}, -- Top
				{-0.5, -0.3125, -0.0625, -0.125, -0.125, 0.0625}, -- Bottom
			},
			connect_right = {
				{0.125, 0.1875, -0.0625, 0.5, 0.4375, 0.0625}, -- Top
				{0.125, -0.3125, -0.0625, 0.5, -0.125, 0.0625}, -- Bottom
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', wall_mat2, '' },
			{ '', 'building_elements:fence_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_fence = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125},
			},
			connect_front = {
				{-0.0625, 0.1875, -0.5, 0.0625, 0.4375, -0.125}, -- Top
				{-0.0625, -0.3125, -0.5, 0.0625, -0.125, -0.125}, -- Bottom
			},
			connect_back = {
				{-0.0625, 0.1875, 0.125, 0.0625, 0.4375, 0.5}, -- Top
				{-0.0625, -0.3125, 0.125, 0.0625, -0.125, 0.5}, -- Bottom
			},
			connect_left = {
				{-0.5, 0.1875, -0.0625, -0.125, 0.4375, 0.0625}, -- Top
				{-0.5, -0.3125, -0.0625, -0.125, -0.125, 0.0625}, -- Bottom
			},
			connect_right = {
				{0.125, 0.1875, -0.0625, 0.5, 0.4375, 0.0625}, -- Top
				{0.125, -0.3125, -0.0625, 0.5, -0.125, 0.0625}, -- Bottom
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:fence_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end

--GENERIC SIMPLE SHAPES AND LINKAGES
building_elements.register_linkage = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.125, -0.125, -0.125, 0.125, 0.125, 0.125},
			},
			connect_front = {
				{-0.0625, -0.0625, -0.5, 0.0625, 0.0625, -0.125},
			},
			connect_back = {
				{-0.0625, -0.0625, 0.125, 0.0625, 0.0625, 0.5},
			},
			connect_left = {
				{-0.5, -0.0625, -0.0625, -0.125, 0.0625, 0.0625},
			},
			connect_right = {
				{0.125, -0.0625, -0.0625, 0.5, 0.0625, 0.0625},
			},
			connect_bottom = {
				{-0.0625, -0.5, -0.0625, 0.0625, -0.125, 0.0625},
			},
			connect_top = {
				{-0.0625, 0.125, -0.0625, 0.0625, 0.5, 0.0625},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:linkage_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_linkage_medium_half = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
			},
			connect_front = {
				{-0.25, -0.25, -0.5, 0.25, 0.25, -0.25},
			},
			connect_back = {
				{-0.25, -0.25, 0.25, 0.25, 0.25, 0.5},
			},
			connect_left = {
				{-0.5, -0.25, -0.25, -0.25, 0.25, 0.25},
			},
			connect_right = {
				{0.25, -0.25, -0.25, 0.5, 0.25, 0.25},
			},
			connect_bottom = {
				{-0.25, -0.5, -0.25, 0.25, -0.25, 0.25},
			},
			connect_top = {
				{-0.25, 0.25, -0.25, 0.25, 0.5, 0.25},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:linkage_medium_half_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_linkage_small_quarter= function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.125, -0.125, -0.125, 0.125, 0.125, 0.125},
			},
			connect_front = {
				{-0.125, -0.125, -0.5, 0.125, 0.125, -0.125},
			},
			connect_back = {
				{-0.125, -0.125, 0.125, 0.125, 0.125, 0.5},
			},
			connect_left = {
				{-0.5, -0.125, -0.125, -0.125, 0.125, 0.125},
			},
			connect_right = {
				{0.125, -0.125, -0.125, 0.5, 0.125, 0.125},
			},
			connect_bottom = {
				{-0.125, -0.5, -0.125, 0.125, -0.125, 0.125},
			},
			connect_top = {
				{-0.125, 0.125, -0.125, 0.125, 0.5, 0.125},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:linkage_small_qtr_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_linkage_round_med_half = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
			},
			connect_front = {
				{-0.25, -0.125, -0.5, 0.25, 0.125, -0.25}, -- Front_h_zneg
				{-0.125, -0.25, -0.5, 0.125, 0.25, -0.25}, -- Front_v_zneg
			},
			connect_back = {
				{-0.25, -0.125, 0.25, 0.25, 0.125, 0.5}, -- Back_h_zpos
				{-0.125, -0.25, 0.25, 0.125, 0.25, 0.5}, -- Back_v_zpos
			},
			connect_left = {
				{-0.5, -0.125, -0.25, -0.25, 0.125, 0.25}, -- Left_h_xneg
				{-0.5, -0.25, -0.125, -0.25, 0.25, 0.125}, -- Left_v_xneg
			},
			connect_right = {
				{0.25, -0.125, -0.25, 0.5, 0.125, 0.25}, -- Right_h_xpos
				{0.25, -0.25, -0.125, 0.5, 0.25, 0.125}, -- Right_v_xpos
			},
			connect_bottom = {
				{-0.125, -0.5, -0.25, 0.125, -0.25, 0.25}, -- Bottom_z_yneg
				{-0.25, -0.5, -0.125, 0.25, -0.25, 0.125}, -- Bottom_x_yneg
			},
			connect_top = {
				{-0.125, 0.25, -0.25, 0.125, 0.5, 0.25}, -- Top_z_ypos
				{-0.25, 0.25, -0.125, 0.25, 0.5, 0.125}, -- Top_x_ypos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:linkage_round_med_half_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_linkage_round_small_quarter = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.125, -0.0625, -0.0625, 0.125, 0.0625, 0.0625}, -- Base_x
				{-0.0625, -0.125, -0.0625, 0.0625, 0.125, 0.0625}, -- Base_y
				{-0.0625, -0.0625, -0.125, 0.0625, 0.0625, 0.125}, -- Base_z
			},
			connect_front = {
				{-0.125, -0.0625, -0.5, 0.125, 0.0625, -0.0625}, -- Front_h_zneg
				{-0.0625, -0.125, -0.5, 0.0625, 0.125, -0.0625}, -- Front_v_zneg
			},
			connect_back = {
				{-0.125, -0.0625, 0.0625, 0.125, 0.0625, 0.5}, -- Back_h_zpos
				{-0.0625, -0.125, 0.0625, 0.0625, 0.125, 0.5}, -- Back_v_zpos
			},
			connect_left = {
				{-0.5, -0.0625, -0.125, -0.0625, 0.0625, 0.125}, -- Left_h_xneg
				{-0.5, -0.125, -0.0625, -0.0625, 0.125, 0.0625}, -- Left_v_xneg
			},
			connect_right = {
				{0.0625, -0.0625, -0.125, 0.5, 0.0625, 0.125}, -- Right_h_xpos
				{0.0625, -0.125, -0.0625, 0.5, 0.125, 0.0625}, -- Right_v_xpos
			},
			connect_bottom = {
				{-0.125, -0.5, -0.0625, 0.125, -0.0625, 0.0625}, -- Bottom_x_yneg
				{-0.0625, -0.5, -0.125, 0.0625, -0.0625, 0.125}, -- Bottom_z_yneg
			},
			connect_top = {
				{-0.125, 0.0625, -0.0625, 0.125, 0.5, 0.0625}, -- Top_x_ypos
				{-0.0625, 0.0625, -0.125, 0.0625, 0.5, 0.125}, -- Top_z_ypos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:linkage_round_small_quarter_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end

building_elements.register_cylinder = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.1875, -0.5, -0.5, 0.1875, 0.5, 0.5},
				{-0.5, -0.5, -0.1875, 0.5, 0.5, 0.1875},
				{-0.375, -0.5, -0.375, 0.375, 0.5, 0.375},
				{-0.3125, -0.5, -0.4375, 0.3125, 0.5, 0.4375},
				{-0.4375, -0.5, -0.3125, 0.4375, 0.5, 0.3125},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,0.5,0.5},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,0.5,0.5},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:cylinder_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_cylinder_3qtr = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.375, -0.5, -0.125, 0.375, 0.5, 0.125},
				{-0.125, -0.5, -0.375, 0.125, 0.5, 0.375},
				{-0.25, -0.5, -0.3125, 0.25, 0.5, 0.3125},
				{-0.3125, -0.5, -0.25, 0.3125, 0.5, 0.25},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.375,-0.5,-0.375,0.375,0.5,0.375},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.375,-0.5,-0.375,0.375,0.5,0.375},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:cylinder_3qtr_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_cylinder_half = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, -0.125, 0.25, 0.5, 0.125}, -- Front_h_zneg
				{-0.125, -0.5, -0.25, 0.125, 0.5, 0.25}, -- Back_h_zpos
				{-0.1875, -0.5, -0.1875, 0.1875, 0.5, 0.1875}, -- NodeBox16
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.25,-0.5,-0.25,0.25,0.5,0.25},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.25,-0.5,-0.25,0.25,0.5,0.25},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:cylinder_half_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_cylinder_1qtr = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.125, -0.5, -0.0625, 0.125, 0.5, 0.0625}, -- Front_h_zneg
				{-0.0625, -0.5, -0.125, 0.0625, 0.5, 0.125}, -- Back_h_zpos
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.125,-0.5,-0.125,0.125,0.5,0.125},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.125,-0.5,-0.125,0.125,0.5,0.125},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:cylinder_1qtr_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_cylinder_to_cross = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, -0.4375, 0.25, 0.25, 0.4375}, -- Middle_z
				{-0.4375, -0.5, -0.25, 0.4375, 0.25, 0.25}, -- Middle_x
				{-0.1875, -0.5, -0.5, 0.1875, 0.5, 0.5}, -- Outer_z
				{-0.5, -0.5, -0.1875, 0.5, 0.5, 0.1875}, -- Outer_x
				{-0.3125, -0.5, -0.375, 0.3125, -0.125, 0.375}, -- Inner_z
				{-0.375, -0.5, -0.3125, 0.375, -0.125, 0.3125}, -- Inner_x
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,0.5,0.5},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,0.5,0.5},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:cylinder_to_cross_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end

building_elements.register_octagon = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, -0.4375, 0.25, 0.5, 0.4375}, -- Middle_z
				{-0.4375, -0.5, -0.25, 0.4375, 0.5, 0.25}, -- Middle_x
				{-0.1875, -0.5, -0.5, 0.1875, 0.5, 0.5}, -- Outer_z
				{-0.5, -0.5, -0.1875, 0.5, 0.5, 0.1875}, -- Outer_x
				{-0.3125, -0.5, -0.375, 0.3125, 0.5, 0.375}, -- Inner_z
				{-0.375, -0.5, -0.3125, 0.375, 0.5, 0.3125}, -- Inner_x
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,0.5,0.5},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,0.5,0.5},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:octagon_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end

--PILLARS (ALSO WITH WALL SECTIONS)
building_elements.register_pillar = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4}},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:pillar_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_pillar_junction = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
			},
			connect_front = {
				{-0.25, -0.25, -0.5, 0.25, 0.25, -0.25},
			},
			connect_back = {
				{-0.25, -0.25, 0.25, 0.25, 0.25, 0.5},
			},
			connect_left = {
				{-0.5, -0.25, -0.25, -0.25, 0.25, 0.25},
			},
			connect_right = {
				{0.25, -0.25, -0.25, 0.5, 0.25, 0.25},
			},
			connect_bottom = {
				{-0.25, -0.5, -0.25, 0.25, -0.25, 0.25},
			},
			connect_top = {
				{-0.25, 0.25, -0.25, 0.25, 0.5, 0.25},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:pillar_junction_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_pillar_with_center_link = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone", "group:wood" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.3125, 0.1875, -0.25, 0.3125, 0.5, 0.25}, -- ConnectTopX
				{-0.25, 0.1875, -0.3125, 0.25, 0.5, 0.3125}, -- ConnectTopZ
				{-0.3125, -0.1875, -0.25, 0.3125, 0.1875, 0.25}, -- BaseX
				{-0.25, -0.1875, -0.3125, 0.25, 0.1875, 0.3125}, -- BaseZ
				{-0.3125, -0.5, -0.25, 0.3125, -0.1875, 0.25}, -- ConnectBottomX
				{-0.25, -0.5, -0.3125, 0.25, -0.1875, 0.3125}, -- ConnectBottomZ
			},
			connect_front = {
				{-0.125, -0.1875, -0.5, 0.125, 0.1875, -0.3125}, -- ConnectFrontY_zneg
				{-0.1875, -0.125, -0.5, 0.1875, 0.125, -0.3125}, -- ConnectFrontZ_zneg
			},
			connect_back = {
				{-0.125, -0.1875, 0.3125, 0.125, 0.1875, 0.5}, -- ConnectBackY_zpos
				{-0.1875, -0.1875, 0.3125, 0.1875, 0.1875, 0.5}, -- ConnectBackZ_zpos
			},
			connect_left = {
				{-0.5, -0.125, -0.1875, -0.3125, 0.125, 0.1875}, -- ConnectLeftX_xneg
				{-0.5, -0.1875, -0.125, -0.3125, 0.1875, 0.125}, -- ConnectLeftZ_xneg
			},
			connect_right = {
				{0.3125, -0.1875, -0.125, 0.5, 0.1875, 0.125}, -- ConnectRightX_xpos
				{0.3125, -0.125, -0.1875, 0.5, 0.125, 0.1875}, -- ConnectRightZ_xpos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:pillar_with_center_link', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_pillar_with_curtain_wall = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4}},
			-- connect_bottom =
			connect_front = {{-3/16, 0, -1/2,  3/16, 1/2, -1/4}},
			connect_left = {{-1/2, 0, -3/16, -1/4, 1/2,  3/16}},
			connect_back = {{-3/16, 0,  1/4,  3/16, 1/2,  1/2}},
			connect_right = {{ 1/4, 0, -3/16,  1/2, 1/2,  3/16}},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:pillar_with_curtain_wall_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_pillar_with_default_wall = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4}},
			-- connect_bottom =
			connect_front = {{-3/16, -1/2, -1/2,  3/16, 3/8, -1/4}},
			connect_left = {{-1/2, -1/2, -3/16, -1/4, 3/8,  3/16}},
			connect_back = {{-3/16, -1/2,  1/4,  3/16, 3/8,  1/2}},
			connect_right = {{ 1/4, -1/2, -3/16,  1/2, 3/8,  3/16}},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:pillar_with_default_wall_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_pillar_with_half_wall = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4}},
			-- connect_bottom =
			connect_front = {{-3/16, -1/2, -1/2,  3/16, 0, -1/4}},
			connect_left = {{-1/2, -1/2, -3/16, -1/4, 0,  3/16}},
			connect_back = {{-3/16, -1/2,  1/4,  3/16, 0,  1/2}},
			connect_right = {{ 1/4, -1/2, -3/16,  1/2, 0,  3/16}},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:pillar_with_half_wall_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_pillar_with_full_wall = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4}},
			-- connect_bottom =
			connect_front = {{-3/16, -1/2, -1/2,  3/16, 1/2, -1/4}},
			connect_left = {{-1/2, -1/2, -3/16, -1/4, 1/2,  3/16}},
			connect_back = {{-3/16, -1/2,  1/4,  3/16, 1/2,  1/2}},
			connect_right = {{ 1/4, -1/2, -3/16,  1/2, 1/2,  3/16}},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:pillar_with_full_wall_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end

--RAILING AND TRIM ITEMS
building_elements.register_railing = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = {
			wall_texture,
			wall_texture,
			wall_texture,
			wall_texture,
			wall_texture,
			wall_texture,
		},
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.0625, -0.5, -0.0625, 0.0625, 0.1875, 0.0625},
				{-0.125, 0.1875, -0.125, 0.125, 0.5, 0.125},
			},
			connect_front = {
				{-0.0625, 0.25, -0.5, 0.0625, 0.5, -0.125},
			},
			connect_back = {
				{-0.0625, 0.25, 0.125, 0.0625, 0.5, 0.5},
			},
			connect_left = {
				{-0.5, 0.25, -0.0625, -0.125, 0.5, 0.0625},
			},
			connect_right = {
				{0.125, 0.25, -0.0625, 0.5, 0.5, 0.0625},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:railing_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end


building_elements.register_road = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5}, -- base
				{0.4375, -0.375, -0.4375, 0.5, 0.1875, -0.375}, -- support1 from front
				{0.4375, -0.375, -0.1875, 0.5, 0.1875, -0.125}, -- support2 from front
				{0.4375, -0.375, 0.0625, 0.5, 0.1875, 0.125}, -- support3 from front
				{0.4375, -0.375, 0.3125, 0.5, 0.1875, 0.375}, -- support4 from front
				{0.375, 0.1875, -0.5, 0.5, 0.3125, 0.5}, -- top rail
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5}, -- base
				{0.375, -0.375, -0.5, 0.5, 0.3125, 0.5}, -- top rail
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5}, -- base
				{0.375, -0.375, -0.5, 0.5, 0.3125, 0.5}, -- top rail
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:road_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end

--LADDERS, CAGE BARS, TRAIN TRACKS, LATTICES
building_elements.register_track = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.4375, -0.5, -0.5, -0.3125, -0.4375, 0.5}, -- board1 from left
				{-0.1875, -0.5, -0.5, -0.0625, -0.4375, 0.5}, -- board2 from left
				{0.0625, -0.5, -0.5, 0.1875, -0.4375, 0.5}, -- board3 from left
				{0.3125, -0.5, -0.5, 0.4375, -0.4375, 0.5}, -- board4 from left
				{-0.5, -0.4375, 0.3125, 0.5, -0.375, 0.375}, -- rail1 from front
				{-0.5, -0.4375, -0.375, 0.5, -0.375, -0.3125}, -- rail2 from front
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,-0.375,0.5},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,-0.375,0.5},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:track_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end

--SLABS OF VARIOUS THICKNESS
building_elements.register_slab = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-1/2, -1/2, -1/2, 1/2, 0, 1/2}
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:slab_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end

--STAIRS
building_elements.register_stair = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-1/2, -1/2, -1/2, 1/2, 0, 1/2},
				{-1/2, 0, 0, 1/2, 1/2, 1/2},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:stair_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end

--TREES
building_elements.register_tree_branch = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:tree", "group:leaves" },
		is_ground_content = false,
		walkable = true,
		groups = { tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.125, -0.0625, -0.0625, 0.125, 0.0625, 0.0625}, -- Base_x
				{-0.0625, -0.125, -0.0625, 0.0625, 0.125, 0.0625}, -- Base_y
				{-0.0625, -0.0625, -0.125, 0.0625, 0.0625, 0.125}, -- Base_z
			},
			connect_front = {
				{-0.125, -0.0625, -0.5, 0.125, 0.0625, -0.0625}, -- Front_h_zneg
				{-0.0625, -0.125, -0.5, 0.0625, 0.125, -0.0625}, -- Front_v_zneg
			},
			connect_back = {
				{-0.125, -0.0625, 0.0625, 0.125, 0.0625, 0.5}, -- Back_h_zpos
				{-0.0625, -0.125, 0.0625, 0.0625, 0.125, 0.5}, -- Back_v_zpos
			},
			connect_left = {
				{-0.5, -0.0625, -0.125, -0.0625, 0.0625, 0.125}, -- Left_h_xneg
				{-0.5, -0.125, -0.0625, -0.0625, 0.125, 0.0625}, -- Left_v_xneg
			},
			connect_right = {
				{0.0625, -0.0625, -0.125, 0.5, 0.0625, 0.125}, -- Right_h_xpos
				{0.0625, -0.125, -0.0625, 0.5, 0.125, 0.0625}, -- Right_v_xpos
			},
			connect_bottom = {
				{-0.125, -0.5, -0.0625, 0.125, -0.0625, 0.0625}, -- Bottom_x_yneg
				{-0.0625, -0.5, -0.125, 0.0625, -0.0625, 0.125}, -- Bottom_z_yneg
			},
			connect_top = {
				{-0.125, 0.0625, -0.0625, 0.125, 0.5, 0.0625}, -- Top_x_ypos
				{-0.0625, 0.0625, -0.125, 0.0625, 0.5, 0.125}, -- Top_z_ypos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:tree_branch_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_tree_root = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:tree", "group:leaves" },
		is_ground_content = false,
		walkable = true,
		groups = { tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.4375, -0.5, -0.5, 0.4375, -0.25, 0.5},
				{-0.5, -0.5, -0.4375, 0.5, -0.25, 0.4375},
				{-0.375, -0.25, -0.4375, 0.375, 0, 0.4375},
				{-0.4375, -0.25, -0.375, 0.4375, 0, 0.375},
				{-0.375, 0, -0.3125, 0.375, 0.5, 0.3125},
				{-0.3125, 0, -0.375, 0.3125, 0.5, 0.375},
		    },
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,0.5,0.5},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5,-0.5,-0.5,0.5,0.5,0.5},
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:tree_root_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_tree_trunk_large = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:tree", "group:leaves" },
		is_ground_content = false,
		walkable = true,
		groups = { tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.3125, 0.1875, -0.25, 0.3125, 0.5, 0.25}, -- ConnectTopX
				{-0.25, 0.1875, -0.3125, 0.25, 0.5, 0.3125}, -- ConnectTopZ
				{-0.3125, -0.1875, -0.25, 0.3125, 0.1875, 0.25}, -- BaseX
				{-0.25, -0.1875, -0.3125, 0.25, 0.1875, 0.3125}, -- BaseZ
				{-0.3125, -0.5, -0.25, 0.3125, -0.1875, 0.25}, -- ConnectBottomX
				{-0.25, -0.5, -0.3125, 0.25, -0.1875, 0.3125}, -- ConnectBottomZ
			},
			connect_front = {
				{-0.125, -0.1875, -0.5, 0.125, 0.1875, -0.3125}, -- ConnectFrontY_zneg
				{-0.1875, -0.125, -0.5, 0.1875, 0.125, -0.3125}, -- ConnectFrontZ_zneg
			},
			connect_back = {
				{-0.125, -0.1875, 0.3125, 0.125, 0.1875, 0.5}, -- ConnectBackY_zpos
				{-0.1875, -0.1875, 0.3125, 0.1875, 0.1875, 0.5}, -- ConnectBackZ_zpos
			},
			connect_left = {
				{-0.5, -0.125, -0.1875, -0.3125, 0.125, 0.1875}, -- ConnectLeftX_xneg
				{-0.5, -0.1875, -0.125, -0.3125, 0.1875, 0.125}, -- ConnectLeftZ_xneg
			},
			connect_right = {
				{0.3125, -0.1875, -0.125, 0.5, 0.1875, 0.125}, -- ConnectRightX_xpos
				{0.3125, -0.125, -0.1875, 0.5, 0.125, 0.1875}, -- ConnectRightZ_xpos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:tree_trunk_large_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_tree_trunk_medium = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:tree", "group:leaves" },
		is_ground_content = false,
		walkable = true,
		groups = { tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.25, 0.1875, -0.1875, 0.25, 0.5, 0.1875}, -- ConnectTopX
				{-0.1875, 0.1875, -0.25, 0.1875, 0.5, 0.25}, -- ConnectTopZ
				{-0.25, -0.1875, -0.1875, 0.25, 0.1875, 0.1875}, -- BaseX
				{-0.1875, -0.1875, -0.25, 0.1875, 0.1875, 0.25}, -- BaseZ
				{-0.25, -0.5, -0.1875, 0.25, -0.1875, 0.1875}, -- ConnectBottomX
				{-0.1875, -0.5, -0.25, 0.1875, -0.1875, 0.25}, -- ConnectBottomZ
			},
			connect_front = {
				{-0.125, -0.1875, -0.5, 0.125, 0.1875, -0.25}, -- ConnectFrontY_zneg
				{-0.1875, -0.125, -0.5, 0.1875, 0.125, -0.25}, -- ConnectFrontZ_zneg
			},
			connect_back = {
				{-0.125, -0.1875, 0.25, 0.125, 0.1875, 0.5}, -- ConnectBackY_zpos
				{-0.1875, -0.1875, 0.25, 0.1875, 0.1875, 0.5}, -- ConnectBackZ_zpos
			},
			connect_left = {
				{-0.5, -0.125, -0.1875, -0.25, 0.125, 0.1875}, -- ConnectLeftX_xneg
				{-0.5, -0.1875, -0.125, -0.25, 0.1875, 0.125}, -- ConnectLeftZ_xneg
			},
			connect_right = {
				{0.25, -0.1875, -0.125, 0.5, 0.1875, 0.125}, -- ConnectRightX_xpos
				{0.25, -0.125, -0.1875, 0.5, 0.125, 0.1875}, -- ConnectRightZ_xpos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:tree_trunk_medium_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_tree_trunk_small = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:tree", "group:leaves" },
		is_ground_content = false,
		walkable = true,
		groups = { tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {
				{-0.1875, 0.1875, -0.125, 0.1875, 0.5, 0.125}, -- ConnectTopX
				{-0.125, 0.1875, -0.1875, 0.125, 0.5, 0.1875}, -- ConnectTopZ
				{-0.1875, -0.1875, -0.125, 0.1875, 0.1875, 0.125}, -- BaseX
				{-0.125, -0.1875, -0.1875, 0.125, 0.1875, 0.1875}, -- BaseZ
				{-0.1875, -0.5, -0.125, 0.1875, -0.1875, 0.125}, -- ConnectBottomX
				{-0.125, -0.5, -0.1875, 0.125, -0.1875, 0.1875}, -- ConnectBottomZ
			},
			connect_front = {
				{-0.0625, -0.125, -0.5, 0.0625, 0.125, -0.1875}, -- ConnectFrontY_zneg
				{-0.125, -0.0625, -0.5, 0.125, 0.0625, -0.1875}, -- ConnectFrontZ_zneg
			},
			connect_back = {
				{-0.0625, -0.125, 0.1875, 0.0625, 0.125, 0.5}, -- ConnectBackY_zpos
				{-0.125, -0.0625, 0.1875, 0.125, 0.0625, 0.5}, -- ConnectBackZ_zpos
			},
			connect_left = {
				{-0.5, -0.0625, -0.125, -0.1875, 0.0625, 0.125}, -- ConnectLeftX_xneg
				{-0.5, -0.125, -0.0625, -0.1875, 0.125, 0.0625}, -- ConnectLeftZ_xneg
			},
			connect_right = {
				{0.1875, -0.0625, -0.125, 0.5, 0.0625, 0.125}, -- ConnectRightX_xpos
				{0.1875, -0.125, -0.0625, 0.5, 0.125, 0.0625}, -- ConnectRightZ_xpos
			},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:tree_trunk_small_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end

--WALLS (CENTER ALIGNED, VERTICAL SLABS)
building_elements.register_wall = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {{-1/4, -1/2, -1/2, 1/4, 1/2, 1/2}},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:wall_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_wall_thin = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "fixed",
			fixed = {{-3/16, -1/2, -1/2, 3/16, 1/2, 1/2}},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:wall_thin_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end
building_elements.register_wall_section = function(wall_name, wall_desc, wall_texture, wall_mat, wall_sounds)
	-- inventory node, and pole-type wall start item
	minetest.register_node("building_elements:" .. wall_name, {
		description = wall_desc,
		drawtype = "nodebox",
		tiles = { wall_texture, },
		paramtype = "light",
		paramtype2 = "facedir",
		connects_to = { "group:wall", "group:stone" },
		is_ground_content = false,
		walkable = true,
		groups = { cracky = 3, wall = 1, stone = 2, not_in_creative_inventory = 1 },
		sounds = wall_sounds,
		node_box = {
			type = "connected",
			fixed = {{-3/16, -1/2, -3/16, 3/16, 1/2, 3/16}},
			-- connect_bottom =
			connect_front = {{-3/16, -1/2, -1/2,  3/16, 1/2, -3/16}},
			connect_left = {{-1/2, -1/2, -3/16, -3/16, 1/2,  3/16}},
			connect_back = {{-3/16, -1/2,  3/16,  3/16, 1/2,  1/2}},
			connect_right = {{ 3/16, -1/2, -3/16,  1/2, 1/2,  3/16}},
		},

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "building_elements:" .. wall_name .. " 99",
		recipe = {
			{ '', '', '' },
			{ '', 'building_elements:wall_section_shape', ''},
			{ '', wall_mat, ''},
		}
	})

end




--building_elements.register_fence_special("fence" .. "_stone_block" .. "_wood", "BldgElmnts" .. " Fence", "default_stone_block.png", "default:stone_block", "default_wood.png", "default:wood", default.node_sound_stone_defaults())

building_elements.register_fence_special("fence" .. "_stone_block" .. "_wood", "BldgElmnts" .. "Stone Block and Wood Fence", "default_stone_block.png", "default:stone_block", "default_wood.png", "default:wood", default.node_sound_stone_defaults())
building_elements.register_fence_special("fence" .. "_stone_block" .. "_acacia_wood", "BldgElmnts" .. "Stone Block and Acacia Wood Fence", "default_stone_block.png", "default:stone_block", "default_acacia_wood.png", "default:acacia_wood", default.node_sound_stone_defaults())
building_elements.register_fence_special("fence" .. "_stone_block" .. "_jungle_wood", "BldgElmnts" .. "Stone Block and Jungle Wood Fence", "default_stone_block.png", "default:stone_block", "default_junglewood.png", "default:junglewood", default.node_sound_stone_defaults())


building_elements.register_fence_special("fence" .. "_stone_brick" .. "_wood", "BldgElmnts" .. "Stone Brick and Wood Fence", "default_stone_brick.png", "default:stonebrick", "default_wood.png", "default:wood", default.node_sound_stone_defaults())
building_elements.register_fence_special("fence" .. "_stone_brick" .. "_acacia_wood", "BldgElmnts" .. "Stone Brick and Acacia Wood Fence", "default_stone_brick.png", "default:stonebrick", "default_acacia_wood.png", "default:acacia_wood", default.node_sound_stone_defaults())
building_elements.register_fence_special("fence" .. "_stone_brick" .. "_jungle_wood", "BldgElmnts" .. "Stone Brick and Jungle Wood Fence", "default_stone_brick.png", "default:stonebrick", "default_junglewood.png", "default:junglewood", default.node_sound_stone_defaults())


building_elements.register_fence_special("fence" .. "_cobble" .. "_wood", "BldgElmnts" .. " Fence", "default_cobble.png", "default:cobble", "default_wood.png", "default:wood", default.node_sound_stone_defaults())
building_elements.register_fence_special("fence" .. "_cobble" .. "_acacia_wood", "BldgElmnts" .. " Fence", "default_cobble.png", "default:cobble", "default_acacia_wood.png", "default:acacia_wood", default.node_sound_stone_defaults())
building_elements.register_fence_special("fence" .. "_cobble" .. "_frost_wood", "BldgElmnts" .. " Fence", "default_cobble.png", "default:cobble", "frost_wood.png", "ethereal:frost_wood", default.node_sound_stone_defaults())

building_elements.register_fence_special("fence" .. "_circle_stone_bricks" .. "_wood", "BldgElmnts" .. " Fence", "moreblocks_circle_stone_bricks.png", "moreblocks:circle_stone_bricks", "default_wood.png", "default:wood", default.node_sound_stone_defaults())




--[[Default stone materials
"default:cobble", "default_cobble.png"
"default:mossycobble", "default_mossycobble.png"
"default:desert_cobble", "default_desert_cobble.png"
"default:brick", "default_brick.png"
"default:stone", "default_stone.png"
"default:desert_stone", "default_desert_stone.png"
"default:sandstone", "default_sandstone.png"
"default:stone_block", , 
"default:desert_stone_block", 
"default:sandstone_block", 
"default:stonebrick", 
"default:desert_stonebrick", 
"default:sandstonebrick", 
"default:obsidian", 
"default:obsidian_block", 
"default:obsidianbrick", 
]]
--[[Default glass materials
"default:glass", "default_glass.png", "default_glass_detail.png"
"default:obsidian_glass", "default_obsidian_glass.png", "default_obsidian_glass_detail.png"
]]
--[[Default wood materials
"default:wood", 
"default:tree", 
"default:jungletree", 
"default:junglewood", 
"default:pine_tree", 
"default:pine_wood", 
"default:acacia_tree", 
"default:acacia_wood", 
]]
--[[Default ice and metal blocks
"default:ice", "default_ice.png"
"default:steelblock", "default_steel_block.png"
"default:copperblock", "default_copper_block.png"
"default:bronzeblock", "default_bronze_block.png"
"default:goldblock", "default_gold_block.png"
"default:diamondblock", "default_diamond_block.png"
"default:coral_brown", "default_coral_brown.png"
"default:coral_orange", "default_coral_orange.png"
"default:coral_skeleton", "default_coral_skeleton.png"

]]
--[[Dark Age materials
"darkage:adobe", "darkage_adobe.png"
"darkage:basalt", "darkage_basalt.png"
"darkage:basalt_cobble", "darkage_basalt_cobble.png"
"darkage:cobble_with_plaster", 
"darkage:desert_stone_cobble", "darkage_desert_stone_cobble.png"
"darkage:gneiss", "darkage_gneiss.png"
"darkage:gneiss_cobble", "darkage_gneiss_cobble.png"
"darkage:marble", "darkage_marble.png"
"darkage:ors", "darkage_ors.png"
"darkage:ors_cobble", "darkage_ors_cobble.png"
"darkage:sandstone_cobble", "darkage_sandstone_cobble.png"
"darkage:serpentine", "darkage_serpentine.png"
"darkage:shale", "darkage_shale.png","darkage_shale_side.png"
"darkage:schist", "darkage_schist.png"
"darkage:slate", "darkage_slate.png","darkage_slate_side.png"
"darkage:slate_cobble", "darkage_slate_cobble.png"
"darkage:slate_tale", "darkage_slate_tale.png"
"darkage:stone_brick", "darkage_stone_brick.png"
"darkage:marble", "darkage_marble.png"
"darkage:marble_tile", "darkage_marble_tile.png"
]]
--[[Ethereal materials
"ethereal:willow_trunk", 
"ethereal:willow_wood", 
"ethereal:redwood_trunk", 
"ethereal:redwood_wood", 
"ethereal:frost_tree", 
"ethereal:frost_wood", 
"ethereal:yellow_trunk", 
"ethereal:yellow_wood", 
"ethereal:palm_trunk", 
"ethereal:palm_wood", 
"ethereal:banana_trunk", 
"ethereal:banana_wood", 
"ethereal:scorched_tree", 
"ethereal:mushroom_trunk", 
"ethereal:birch_trunk", 
"ethereal:birch_wood", 
]]
--[[More Blocks materials
"moreblocks:stone_tile", 
"moreblocks:circle_stone_bricks", 
"moreblocks:split_stone_tile", 
"moreblocks:split_stone_tile_alt", 
]]
--[[XDecor materials
"xdecor:barrel", 
"xdecor:cabinet", 
"xdecor:cabinet_half", 
"xdecor:desertstone_tile", 
"xdecor:hard_clay", 
"xdecor:stone_rune", 
]]
--[[Template
]]


building_elements.register_nodes("_cobble", "Cobblestone ", "default_cobble.png",
		"default:cobble", default.node_sound_stone_defaults())
building_elements.register_nodes("_mossycobble", "Mossy Cobblestone ", "default_mossycobble.png",
		"default:mossycobble", default.node_sound_stone_defaults())
building_elements.register_nodes("_desertcobble", "Desert Cobblestone ", "default_desert_cobble.png",
		"default:desert_cobble", default.node_sound_stone_defaults())

building_elements.register_nodes("_sandstone", "Sandstone ", "default_sandstone.png",
		"default:sandstone", default.node_sound_stone_defaults())
building_elements.register_nodes("_desert_stone", "Desert Stone ", "default_desert_stone.png",
		"default:desert_stone", default.node_sound_stone_defaults())
building_elements.register_nodes("_stone", "Stone ", "default_stone.png",
		"default:stone", default.node_sound_stone_defaults())

building_elements.register_nodes("_sandstone_block", "Sandstone Block ", "default_sandstone_block.png",
		"default:sandstone_block", default.node_sound_stone_defaults())
building_elements.register_nodes("_desert_stone_block", "Desert Stone Block ", "default_desert_stone_block.png",
		"default:desert_stone_block", default.node_sound_stone_defaults())
building_elements.register_nodes("_stone_block", "Stone Block ", "default_stone_block.png",
		"default:stone_block", default.node_sound_stone_defaults())

building_elements.register_nodes("_sandstone_brick", "Sandstone Brick ", "default_sandstone_brick.png",
		"default:sandstonebrick", default.node_sound_stone_defaults())
building_elements.register_nodes("_desertstone_brick", "Desert Stone Brick ", "default_desert_stone_brick.png",
		"default:desert_stonebrick", default.node_sound_stone_defaults())
building_elements.register_nodes("_stone_brick", "Stone Brick ", "default_stone_brick.png",
		"default:stonebrick", default.node_sound_stone_defaults())

building_elements.register_nodes("_wood", "Wood ", "default_wood.png",
		"default:wood", default.node_sound_wood_defaults())
building_elements.register_nodes("_tree", "Tree ", "default_tree.png",
		"default:tree", default.node_sound_wood_defaults())
building_elements.register_nodes("_junglewood", "Jungle Wood ", "default_junglewood.png",
		"default:junglewood", default.node_sound_wood_defaults())
building_elements.register_nodes("_jungletree", "Jungle Tree ", "default_jungletree.png",
		"default:jungletree", default.node_sound_wood_defaults())
building_elements.register_nodes("_acacia_wood", "Acacia Wood ", "default_acacia_wood.png",
		"default:acacia_wood", default.node_sound_wood_defaults())
building_elements.register_nodes("_acacia_tree", "Acacia Tree ", "default_acacia_tree.png",
		"default:acacia_tree", default.node_sound_wood_defaults())
building_elements.register_nodes("_pine_tree", "Pine Wood ", "default_pine_wood.png",
		"default:pine_tree", default.node_sound_wood_defaults())
building_elements.register_nodes("_pine_tree", "Pine Tree ", "default_pine_tree.png",
		"default:pine_tree", default.node_sound_wood_defaults())


building_elements.register_nodes("_obsidian", "Obsidian ", "default_obsidian.png",
		"default:obsidian", default.node_sound_stone_defaults())
building_elements.register_nodes("_obsidian_block", "Obsidian Block ", "default_obsidian_block.png",
		"default:obsidian_block", default.node_sound_stone_defaults())
building_elements.register_nodes("_obsidianbrick", "Obsidian Brick ", "default_obsidianbrick.png",
		"default:obsidianbrick", default.node_sound_stone_defaults())

building_elements.register_nodes("_glass", "Glass ", "default_glass.png",
		"default:glass", default.node_sound_glass_defaults())
building_elements.register_nodes("_obsidian_glass", "Obsidian Glass ", "default_obsidian_glass.png",
		"default:obsidian_glass", default.node_sound_glass_defaults())

building_elements.register_nodes("_ice", "Ice ", "default_ice.png",
		"default:ice", default.node_sound_glass_defaults())

building_elements.register_nodes("_steelblock", "Steel Block ", "default_steel_block.png",
		"default:steelblock", default.node_sound_stone_defaults())
building_elements.register_nodes("_copperblock", "Copper Block ", "default_copper_block.png",
		"default:copperblock", default.node_sound_stone_defaults())
building_elements.register_nodes("_bronzeblock", "Bronze Block ", "default_bronze_block.png",
		"default:bronzeblock", default.node_sound_stone_defaults())
building_elements.register_nodes("_goldblock", "Gold Block ", "default_gold_block.png",
		"default:goldblock", default.node_sound_stone_defaults())
building_elements.register_nodes("_diamondblock", "Diamond Block ", "default_diamond_block.png",
		"default:diamondblock", default.node_sound_stone_defaults())

building_elements.register_nodes("_coral_brown", "Coral Brown ", "default_coral_brown.png",
		"default:coral_brown", default.node_sound_stone_defaults())
building_elements.register_nodes("_coral_orange", "Coral Orange ", "default_coral_orange.png",
		"default:coral_orange", default.node_sound_stone_defaults())
building_elements.register_nodes("_coral_skeleton", "Coral Skeleton ", "default_coral_skeleton.png",
		"default:coral_skeleton", default.node_sound_stone_defaults())

