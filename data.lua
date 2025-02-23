data:extend{
	{
		type = "item",
		name = "halflife-placeholder",
		icons = {util.empty_icon()}, --TODO: make an icon for 1/2 or something
		stack_size = 100000000,
		spoil_ticks = 1 -- I do not want this living for very long if it ever gets out.
	}
}
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
	item.spoil_ticks = ticks
	item.spoil_result = "halflife-placeholder"
	item.spoil_to_trigger_result = {
		items_per_trigger = binning,
		trigger = {
			type = "direct",
			action_delivery = {
				type = "instant",
				source_effects = {
					type = "script",
					effect_id = "halflife::coin"
				}
			}
		}
	}
	return item
end

-- FOR TESTING
add_halflife(data.raw["item"]["coin"], 60)