MultiCraftAddon = MultiCraftAddon or {}
local mkstr = ZO_CreateStringId
local SI = MultiCraftAddon.SI

mkstr(SI.USAGE_1,			"MultiCraft Benutzung:")
mkstr(SI.USAGE_2,			"/toggle: Schaltet den Standard des Reglers zwischen 1 und Max um. Standard ist 1.")
mkstr(SI.USAGE_3,			"/trait: Schaltet um, ob die mehrfache Herstellung von Gegenständen mit Eigenschaften erlaubt ist. Standard ist aktiviert.")
mkstr(SI.USAGE_4,			"/delay N: Dies verzögert alle Handwerksaktivitäten um den angegebenen Wert in Millisekunden. Standard ist 500.")
mkstr(SI.DEFAULT_MAX,		"MultiCraft: Reglerstandard ist jetzt Max.")
mkstr(SI.DEFAULT_MIN,		"MultiCraft: Reglerstandard ist jetzt 1.")
mkstr(SI.TRAITS_ON,			"MultiCraft: Eigenschaften aktiviert.")
mkstr(SI.TRAITS_OFF,		"MultiCraft: Eigenschaften deaktiviert.")
mkstr(SI.CALL_DELAY,		"MultiCraft: Handwerksaktivitäten limitiert auf einen Aufruf alle %d Millisekunden.")
