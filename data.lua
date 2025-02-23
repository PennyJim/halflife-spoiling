-- FOR TESTING
local coin = data.raw["item"]["coin"]
coin.spoil_ticks = 30
coin.spoil_result = "halflife-placeholder"
coin.spoil_to_trigger_result = {
	items_per_trigger = 1,
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

data:extend{
	{
		type = "item",
		name = "halflife-placeholder",
		icons = {util.empty_icon()},
		stack_size = 100000000,
		spoil_ticks = 1 -- I do not want this living for very long if it ever gets out.
	}
}