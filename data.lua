data:extend{
	{
		type = "item-subgroup",
		name = "halflife-placeholder",
		group = "other",
	}
}

---@param base_type string
---@param name string
---@return data.PrototypeBase
local function get_prototype(base_type, name)
	for type in pairs(defines.prototypes[base_type]--[[@as table<string>]]) do
		local prototypes = data.raw[type]--[[@as table<string,data.PrototypeBase>]]
		if prototypes and prototypes[name] then
			return prototypes[name]
		end
	end
	error("Could not find prototype of base type '"..base_type.."' and name '"..name.."'")
end

---Borrowed from flib
---An MIT licensed mod from raiguard
--- Returns the localised name of the given item.
--- @param item data.ItemPrototype
--- @return data.LocalisedString
local function item_locale(item)
  if not defines.prototypes.item[item.type] then
    error("Given prototype is not an item: " .. serpent.block(item))
  end
  if item.localised_name then
    return item.localised_name
  end
  local type_name = "item"
  --- @type data.PrototypeBase?
  local prototype
  if item.place_result then
    type_name = "entity"
    prototype = get_prototype("entity", item.place_result) --[[@as data.PrototypeBase]]
  elseif item.place_as_equipment_result then
    type_name = "equipment"
    prototype = get_prototype("equipment", item.place_as_equipment_result) --[[@as data.PrototypeBase]]
  elseif item.place_as_tile then
    local tile_prototype = data.raw.tile[item.place_as_tile.result]
    -- Tiles with variations don't have a localised name
    if tile_prototype and tile_prototype.localised_name then
      prototype = tile_prototype
      type_name = "tile"
    end
  end
  return prototype and prototype.localised_name or { type_name .. "-name." .. item.name }
end

--- Will cause the item to decay into half the stack size every given ticks.<br>
--- Overwrites most spoil fields (leaving spoil_level untouched).
--- 
--- 
--- Binning is the required amount for it to half-life into an item.
--- If the stack is lower than the given amount, it'll dissappear instead of halve its size.<br>
--- Increasing this will reduce the amount of script triggers fired, if the quantity is problematic
---@param item data.ItemPrototype
---@param ticks uint
---@param binning? uint
---@return data.ItemPrototype
function add_halflife(item, ticks, binning)
	binning = binning or 2
	local placeholder_name = "halflife-placeholder-"..item.name

	item.spoil_ticks = ticks
	item.spoil_result = placeholder_name
	item.spoil_to_trigger_result = {
		items_per_trigger = binning,
		trigger = {
			type = "direct",
			action_delivery = {
				type = "instant",
				source_effects = {
					type = "script",
					effect_id = "halflife::"..item.name
				}
			}
		}
	}

	local new_icons = item.icons
	if new_icons then
		new_icons = util.copy(new_icons)
	else
		new_icons = {
			{icon = item.icon, icon_size = item.icon_size or 64}
		}
	end

	table.insert(new_icons, {
		icon = "__halflife-spoiling__/graphics/icons/halflife.png",
		icon_size = 64,
	})

	data:extend{{
		type = "item",
		name = placeholder_name,
		icons = new_icons,
		localised_name = item_locale(item),
		subgroup = "halflife-placeholder",
		spoil_ticks = 1, -- I do not want this living for very long if it ever gets out.
		stack_size = item.stack_size,
		hidden = true,
		hidden_in_factoriopedia = true,
	}}


	return item
end

-- FOR TESTING
add_halflife(data.raw["item"]["coin"], 60)