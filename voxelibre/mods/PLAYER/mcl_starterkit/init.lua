minetest.register_on_newplayer(function(player)
	local inv = player:get_inventory()

	local items = {
		"mcl_tools:axe_wood",
		"mcl_tools:pick_wood",
		"mcl_tools:sword_wood",
		"mcl_armor:helmet_leather",
		"mcl_armor:chestplate_leather",
		"mcl_armor:leggings_leather",
		"mcl_armor:boots_leather",
		"mcl_torches:torch 8",
		"mcl_farming:bread 6",
		"mcl_mobitems:beef 6",
		"mcl_core:tree 16",
	}

	for _, item in ipairs(items) do
		inv:add_item("main", ItemStack(item))
	end
end)
