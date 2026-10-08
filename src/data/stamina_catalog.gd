extends RefCounted

# Balance rules live here so future modes/items share one source.
const MAX_NATURAL := 30
const ENTRY_COST := 5
const EARLY_EXIT_WINDOW_MS := 30000
const EARLY_EXIT_REFUND := 4
const RECOVERY_SECONDS := 360
const INITIAL_AMOUNT := MAX_NATURAL
const ICON_PATH := "res://assets/art/UI/lobby_header/stamina.svg"
const SHOP_PACKAGE_ID := "stamina_supply"
