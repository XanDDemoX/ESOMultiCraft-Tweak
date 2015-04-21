MultiCraftAddon = MultiCraftAddon or {}
local mkstr = ZO_CreateStringId
local SI = MultiCraftAddon.SI

mkstr(SI.USAGE_1,			"MultiCraft Usage:")
mkstr(SI.USAGE_2,			"/toggle: Toggle slider defaults between 1 and max. Default is 1.")
mkstr(SI.USAGE_3,			"/trait: Toggle whether using traits allows crafting multiple items. Default is enabled.")
mkstr(SI.USAGE_4,			"/delay N: This delays all crafting calls by the specified value in milliseconds. Default is 500.")
mkstr(SI.DEFAULT_MAX,		"MultiCraft: Slider defaults to max.")
mkstr(SI.DEFAULT_MIN,		"MultiCraft: Slider defaults to 1.")
mkstr(SI.TRAITS_ON,			"MultiCraft: Traits enabled.")
mkstr(SI.TRAITS_OFF,		"MultiCraft: Traits disabled.")
mkstr(SI.CALL_DELAY,		"MultiCraft: Crafting rate limited to one call every %d milliseconds.")
