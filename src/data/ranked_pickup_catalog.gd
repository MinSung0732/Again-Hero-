extends RefCounted
## Ranked has no scheduled opening elite. Keep solo supply thresholds while
## allowing the first chest through ordinary kills as well as an elite kill.
const HERO := preload("res://src/data/hero_mode_catalog.gd")
const CHEST_KILLS := HERO.CHEST_KILLS
const CHEST_ELITE_KILLS := HERO.CHEST_ELITE_KILLS
const FIRST_ELITE_KILLS := 1
static func chest_eligible(source: String, spawned: int, kills: int, elites: int) -> bool:
	if source == "kills": return kills >= CHEST_KILLS
	if source == "elite": return elites >= (FIRST_ELITE_KILLS if spawned == 0 else CHEST_ELITE_KILLS)
	return false
