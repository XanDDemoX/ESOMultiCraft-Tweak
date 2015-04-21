MultiCraftAddon = MultiCraftAddon or {}
local mkstr = ZO_CreateStringId
local SI = MultiCraftAddon.SI

mkstr(SI.USAGE_1,			"Utilisation de MultiCraft:")
mkstr(SI.USAGE_2,			"/toggle: Alterne les valeurs par défaut du slider entre 1 et max. La valeur par défaut est 1.")
mkstr(SI.USAGE_3,			"/trait: Active/désactive l'utilisation des caractéristiques d'objets lors de la fabrication d'objets multiples. Activé par défaut.")
mkstr(SI.USAGE_4,			"/delay N: Applique un délai de N millisecondes aux appels serveur pour la fabrication d’objets. Le délai par défaut est 500.")
mkstr(SI.DEFAULT_MAX,		"MultiCraft: La valeur par défaut du slider est max.")
mkstr(SI.DEFAULT_MIN,		"MultiCraft: La valeur par défaut du slider est 1.")
mkstr(SI.TRAITS_ON,			"MultiCraft: Utilisation des caractéristiques activée.")
mkstr(SI.TRAITS_OFF,		"MultiCraft: Utilisation des caractéristiques désactivée.")
mkstr(SI.CALL_DELAY,		"MultiCraft: Fréquence de fabrication limitée à un appel toutes les %d millisecondes.")