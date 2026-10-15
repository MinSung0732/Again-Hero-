extends RefCounted
## Wallet refund and levels are committed together in the existing account bundle.
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const DEMON := preload("res://src/data/research_catalog.gd")
const HERO := preload("res://src/data/hero_mode_catalog.gd")
const CHARACTERS := preload("res://src/data/hero_character_catalog.gd")
const PROGRESS := "user://stage_progress.cfg"
const TEAM := "user://team_loadout.cfg"
static func owner() -> String:
	return SCOPE.user_id if not SCOPE.user_id.is_empty() else "guest:"+SCOPE.guest_directory
static func _load(config: ConfigFile,path: String) -> bool:
	var error := SCOPE.load_config(config,path)
	return error == OK or error == ERR_FILE_NOT_FOUND
static func invested(config: ConfigFile, mode: String) -> int:
	if config.has_section_key("research_spending",mode):
		return maxi(0,int(config.get_value("research_spending",mode,0)))
	# Legacy saves have no receipt. Reconstruct using current level-by-level prices.
	var total := 0
	if mode == "demon":
		for id in DEMON.get_ordered_ids():
			var data: Dictionary = DEMON.get_research(id)
			var level := clampi(int(config.get_value("research",id,0)),0,int(data.max_level))
			for rank in level: total += DEMON.get_cost(id,rank)
	elif mode == "hero":
		for id in HERO.GROWTH:
			var highest_legacy := 0
			var seen := {}
			for hero in CHARACTERS.ORDER:
				var key := CHARACTERS.stage_for_hero(hero)+"_"+String(id)
				if seen.has(key): continue
				seen[key] = true
				var level := clampi(int(config.get_value("hero_growth",key,0)),0,int(HERO.GROWTH[id].max))
				highest_legacy = maxi(highest_legacy,level)
				for rank in level: total += HERO.growth_cost(id,rank)
			var shared := clampi(int(config.get_value("hero_growth","shared_"+String(id),0)),0,int(HERO.GROWTH[id].max))
			# shared contains the migrated maximum, not another purchase of old levels.
			for rank in range(highest_legacy,shared): total += HERO.growth_cost(id,rank)
	return total
static func _clear(config: ConfigFile,mode: String) -> void:
	if mode == "demon":
		for id in DEMON.get_ordered_ids(): config.set_value("research",id,0)
	else:
		for id in HERO.GROWTH:
			config.set_value("hero_growth","shared_"+String(id),0)
			for hero in CHARACTERS.ORDER:
				config.set_value("hero_growth",CHARACTERS.stage_for_hero(hero)+"_"+String(id),0)
	config.set_value("research_spending",mode,0)
static func preview(mode: String) -> Dictionary:
	if mode not in ["demon","hero"]: return {"success":false,"refund":0}
	var config := ConfigFile.new()
	if not _load(config,PROGRESS if mode == "demon" else TEAM): return {"success":false,"refund":0}
	return {"success":true,"refund":invested(config,mode),"owner":owner()}
static func reset(mode: String, expected_owner: String) -> Dictionary:
	if mode not in ["demon","hero"] or expected_owner != owner(): return {"success":false,"reason":"owner_changed"}
	var progress := ConfigFile.new()
	if not _load(progress,PROGRESS): return {"success":false,"reason":"save_failed"}
	var config := progress if mode == "demon" else ConfigFile.new()
	if mode == "hero" and not _load(config,TEAM): return {"success":false,"reason":"save_failed"}
	var refund := invested(config,mode)
	_clear(config,mode)
	progress.set_value("meta","research_points",maxi(0,int(progress.get_value("meta","research_points",0)))+refund)
	var configs := {"stage_progress.cfg":progress}
	if mode == "hero": configs["team_loadout.cfg"] = config
	if SCOPE.save_configs(configs) != OK: return {"success":false,"reason":"save_failed"}
	return {"success":true,"refunded":refund}
