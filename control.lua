---@type table<string, fun(event:EventData.on_script_trigger_effect, param?:string)>
local tick_handlers = {}
---@param event EventData.on_script_trigger_effect
script.on_event(defines.events.on_script_trigger_effect, function (event)
	local effect,param = event.effect_id:match("(.+)::(.+)")
	local func = tick_handlers[effect or event.effect_id]
	if func then return func(event, param) end
end)

--- A lookup for if an item is one of our placeholders
---@type table<data.ItemID, true>
local is_placeholder = {}
for item in pairs(prototypes.get_item_filtered{
	{filter = "subgroup", subgroup = "halflife-placeholder"}
}) do
	is_placeholder[item] = true
end

local last_tick_halflifed = 0
---@type table<uint, table<uint,uint>>
local entities_halflifed = {}
---@type table<string, fun(event:EventData.on_script_trigger_effect,item:data.ItemID, entity:LuaEntity)>
local entity_type = {}

---@param inventory LuaInventory|LuaTransportLine
---@param item data.ItemID
---@param last_indexed uint
---@return uint
local function halflife_inventory(inventory, item, last_indexed)
	local inventory_size = #inventory
	if last_indexed > inventory_size then return last_indexed end
	-- Check whether it's worth doing anything
	-- On the chopping block for performance??
	local contents = inventory.get_contents()
	local has_halflife = false
	for _, count in pairs(contents) do
		if is_placeholder[count.name] then
			has_halflife = true
			break
		end
	end
	if not has_halflife then return last_indexed end

	-- Actually replace placeholders
	local index = last_indexed
	while index <= inventory_size do
		local slot = inventory[index]
		---@type number
		local count
		if not slot.valid_for_read then goto continue end
		if not is_placeholder[slot.name] then
			if slot.spoil_tick >= last_tick_halflifed then goto continue end
			local spoil_result = prototypes.item[slot.name].spoil_result
			if spoil_result and is_placeholder[spoil_result.name] then
				break
			else
				goto continue
			end
		end

		count = slot.count / 2
		if count < 1 then
			slot.clear()
			if inventory.object_name == "LuaTransportLine" then
				inventory_size = inventory_size - 1
				index = index - 1
			end
		else
			slot.set_stack{
				name = item,
				quality = slot.quality,
				count = count
			}
		end

		::continue::
		index = index + 1
	end

	-- Update what index was last used
	return index
end

entity_type["default"] = function(event, item, entity)
	local unit_number = entity.unit_number--[[@as uint]]
	local last_indexed = entities_halflifed[unit_number]
	if not last_indexed then
		last_indexed = {}
		entities_halflifed[unit_number] = last_indexed
	end

	for i = 1, entity.get_max_inventory_index() do
---@diagnostic disable-next-line: param-type-mismatch
		local inventory = entity.get_inventory(i)
		if inventory then
			last_indexed[i] = halflife_inventory(inventory, item, last_indexed[i] or 1)
		end
	end
end

entity_type["transport-belt"] = function (event, item, entity)
	local unit_number = entity.unit_number--[[@as uint]]
	local last_indexed = entities_halflifed[unit_number]
	if not last_indexed then
		last_indexed = {}
		entities_halflifed[unit_number] = last_indexed
	end

	for i = 1, entity.get_max_transport_line_index() do
---@diagnostic disable-next-line: param-type-mismatch
		local transport = entity.get_transport_line(i)
		last_indexed[i] = halflife_inventory(transport, item, last_indexed[i] or 1)
	end
end
entity_type["underground-belt"] = entity_type["transport-belt"]
entity_type["splitter"] = entity_type["transport-belt"]
entity_type["loader"] = entity_type["transport-belt"]

entity_type["inserter"] = function (event, item, entity)
	local stack = entity.held_stack -- Might need to check if it's valid for read?
	if not is_placeholder[stack.name] then return end
	local count = stack.count / 2
	if count >= 1 then
		stack.set_stack{
			name = item,
			count = count,
			quality = stack.quality,
		}
	else
		stack.clear()
	end
end

function tick_handlers.halflife(event, item)
	if event.tick ~= last_tick_halflifed then
		last_tick_halflifed = event.tick
		entities_halflifed = {}
	end
	if not item then error("Cannot halflife without knowing the original item. Please format the effect_id like 'halflife::<item-name>'") end

	local entity = event.source_entity
	if not entity then return end -- It's probably the Editor? just ignore?
	if not entity.unit_number then return end -- It's probably just an item on the ground. Can't be more than 1 so let spoil naturally

	local half_func = entity_type[entity.type]
	if not half_func then half_func = entity_type["default"] end
	half_func(event, item, entity)
end