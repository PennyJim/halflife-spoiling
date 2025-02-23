---@type table<string, fun(event:EventData.on_script_trigger_effect, param?:string)>
local tick_handlers = {}
---@param event EventData.on_script_trigger_effect
script.on_event(defines.events.on_script_trigger_effect, function (event)
	local effect,param = event.effect_id:match("(.+)::(.+)")
	local func = tick_handlers[effect or event.effect_id]
	if func then return func(event, param) end
end)


function tick_handlers.halflife(event, item)
	if not item then error("Cannot halflife without knowing the original item. Please format the effect_id like 'halflife::<item-name>'") end
	__DebugAdapter.print(event)
end