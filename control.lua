---@type table<string, fun(event:EventData.on_script_trigger_effect, param?:string)>
local tick_handlers = {}
---@param event EventData.on_script_trigger_effect
script.on_event(defines.events.on_script_trigger_effect, function (event)
	local effect,param = event.effect_id:match("(.+)::(.+)")
	local func = tick_handlers[effect or event.effect_id]
	if func then return func(event, param) end
end)

local last_tick_halflifed = 0
---@type table<uint, table<uint,uint>>
local entities_halflifed = {}

---@param inventory LuaInventory
---@param item data.ItemID
---@param last_indexed uint
---@return uint
local function halflife_inventory(inventory, item, last_indexed)
	local contents = inventory.get_contents()
	local has_halflife = false
	for _, count in pairs(contents) do
		if count.name == "halflife-placeholder" then
			has_halflife = true
			break
		end
	end
	if not has_halflife then return last_indexed end

	local inventory_size = #inventory
	for i = last_indexed, inventory_size, 1 do
		local slot = inventory[i]
		if not slot.valid_for_read then goto continue end
		if slot.name ~= "halflife-placeholder" then
			if slot.spoil_tick >= last_tick_halflifed then goto continue end
			local spoil_result = prototypes.item[slot.name].spoil_result
			if spoil_result and spoil_result.name == "halflife-placeholder" then
				return i
			else
				goto continue
			end
		end

		local count = slot.count / 2
		if count < 1 then
			slot.clear()
			goto continue
		end

		slot.set_stack{
			name = item,
			quality = slot.quality,
			count = count
		}

		::continue::
	end
	return inventory_size
end


function tick_handlers.halflife(event, item)
	if event.tick ~= last_tick_halflifed then
		last_tick_halflifed = event.tick
		entities_halflifed = {}
	end
	if not item then error("Cannot halflife without knowing the original item. Please format the effect_id like 'halflife::<item-name>'") end

	local entity = event.source_entity
	if not entity then return end

	local last_indexed = entities_halflifed[entity.unit_number--[[@as uint]]]
	if not last_indexed then
		last_indexed = {}
		entities_halflifed[entity.unit_number--[[@as uint]]] = last_indexed
	end

	for i = 1, entity.get_max_inventory_index() do
---@diagnostic disable-next-line: param-type-mismatch
		local inventory = entity.get_inventory(i)
		if inventory then
			last_indexed[i] = halflife_inventory(inventory, item, last_indexed[i] or 1)
		end
	end
end