local S = minetest.get_translator(minetest.get_current_modname())

local function count_needed(recipe)
	local needed = {}
	for _, item in pairs(recipe.items) do
		if item ~= "" then
			needed[item] = (needed[item] or 0) + 1
		end
	end
	return needed
end

local function find_matching_stack(inv, listname, item)
	local list = inv:get_list(listname)
	if not list then return nil end
	if item:sub(1, 6) == "group:" then
		local groups = {}
		for g in item:sub(7):gmatch("[^,]+") do
			groups[g] = true
		end
		for i, stack in ipairs(list) do
			if not stack:is_empty() then
				local def = minetest.registered_items[stack:get_name()]
				if def then
					local ok = true
					for g in pairs(groups) do
						if (def.groups[g] or 0) <= 0 then
							ok = false
							break
						end
					end
					if ok then
						return i
					end
				end
			end
		end
	else
		for i, stack in ipairs(list) do
			if not stack:is_empty() and stack:get_name() == item then
				return i
			end
		end
	end
	return nil
end

local function player_has_ingredients(player, recipe)
	local inv = player:get_inventory()
	local needed = count_needed(recipe)
	local reserved = {}
	for item, count in pairs(needed) do
		for _ = 1, count do
			local idx = nil
			local list = inv:get_list("main")
			for i, stack in ipairs(list) do
				if not reserved[i] and not stack:is_empty() then
					local matches = false
					if item:sub(1, 6) == "group:" then
						local groups = {}
						for g in item:sub(7):gmatch("[^,]+") do
							groups[g] = true
						end
						local def = minetest.registered_items[stack:get_name()]
						if def then
							matches = true
							for g in pairs(groups) do
								if (def.groups[g] or 0) <= 0 then
									matches = false
									break
								end
							end
						end
					else
						matches = (stack:get_name() == item)
					end
					if matches then
						idx = i
						break
					end
				end
			end
			if not idx then
				return false
			end
			reserved[idx] = true
		end
	end
	return true
end

local function do_craft(player, recipe)
	local inv = player:get_inventory()

	if not player_has_ingredients(player, recipe) then
		minetest.chat_send_player(player:get_player_name(), S("Not enough ingredients."))
		return
	end

	local needed = count_needed(recipe)
	for item, count in pairs(needed) do
		for _ = 1, count do
			local list = inv:get_list("main")
			for i, stack in ipairs(list) do
				if not stack:is_empty() then
					local matches = false
					if item:sub(1, 6) == "group:" then
						local groups = {}
						for g in item:sub(7):gmatch("[^,]+") do
							groups[g] = true
						end
						local def = minetest.registered_items[stack:get_name()]
						if def then
							matches = true
							for g in pairs(groups) do
								if (def.groups[g] or 0) <= 0 then
									matches = false
									break
								end
							end
						end
					else
						matches = (stack:get_name() == item)
					end
					if matches then
						stack:take_item(1)
						inv:set_stack("main", i, stack)
						break
					end
				end
			end
		end
	end

	local output = ItemStack(recipe.output)
	local leftover = inv:add_item("main", output)
	if not leftover:is_empty() then
		minetest.item_drop(leftover, player, player:get_pos())
	end
end

mcl_craftguide.add_formspec_element("autocraft", {
	type = "button",
	element = function(data)
		if data.recipes and data.recipes[data.rnum] and data.recipes[data.rnum].type ~= "fuel" then
			return {
				data.iX - 3.7,
				data.iX - 5 + 2.75,
				1.6,
				0.6,
				S("Craft")
			}
		end
	end,
	action = function(player, data)
		local recipe = data.recipes and data.recipes[data.rnum]
		if recipe and recipe.type ~= "fuel" then
			do_craft(player, recipe)
		end
	end
})
