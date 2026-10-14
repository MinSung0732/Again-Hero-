extends RefCounted
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
const PROFILES := preload("res://src/data/hero_profiles.gd")
const CHARACTERS := preload("res://src/data/hero_character_catalog.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const PATH := "user://team_loadout.cfg"
static func augment_reroll_bonus() -> int:
	# Future account-scoped research hook; no research upgrade is sold yet.
	return 0
static func owner() -> String:
	return SCOPE.user_id+":"+SCOPE.guest_directory
static func _load(config: ConfigFile,path: String = PATH) -> bool:
	var error := SCOPE.load_config(config,path)
	return error == OK or error == ERR_FILE_NOT_FOUND
static func selected_hero() -> String:
	var config := ConfigFile.new()
	if not _load(config): return CHARACTERS.DEFAULT_HERO
	var id := String(config.get_value("hero_loadout","hero_id",""))
	if id.is_empty(): id = CHARACTERS.hero_for_stage(String(config.get_value("hero_loadout","stage","stage_1")))
	return id if character_unlocked(id) else CHARACTERS.DEFAULT_HERO
static func select_hero(id: String) -> bool:
	if not character_unlocked(id): return false
	var config := ConfigFile.new()
	if not _load(config): return false
	if String(config.get_value("hero_loadout","hero_id","")) == id: return true
	config.set_value("hero_loadout","hero_id",id)
	return SCOPE.save_config(config,PATH) == OK
static func selected_battle_stage() -> String:
	var config := ConfigFile.new()
	if not _load(config): return "stage_1"
	var id := String(config.get_value("hero_loadout","battle_stage","stage_1"))
	return id if battle_stage_unlocked(id) else "stage_1"
static func select_battle_stage(id: String) -> bool:
	if not battle_stage_unlocked(id): return false
	var config := ConfigFile.new()
	if not _load(config): return false
	if String(config.get_value("hero_loadout","battle_stage","")) == id: return true
	config.set_value("hero_loadout","battle_stage",id)
	return SCOPE.save_config(config,PATH) == OK
static func highest_battle_stage() -> int:
	var config := ConfigFile.new()
	if not _load(config): return 1
	return _highest_battle_stage_in_config(config)
static func _highest_battle_stage_in_config(config: ConfigFile) -> int:
	# Migrate existing wins, but never infer clears from an old free selection.
	var highest := 1
	var order := STAGES.get_ordered_stage_ids()
	for id in order:
		if int(config.get_value("hero_progress",String(id)+"_wins",0)) <= 0: break
		highest = mini(highest+1,order.size())
	return highest
static func battle_stage_unlocked(id: String) -> bool:
	var stage: Dictionary = STAGES.get_stage(id)
	return not stage.is_empty() and int(stage.get("number",0)) <= highest_battle_stage()
static func battle_stage_cleared(id: String) -> bool:
	var config := ConfigFile.new()
	return _load(config) and int(config.get_value("hero_progress",id+"_wins",0)) > 0
# Legacy calls refer to character origin, never the selected battlefield.
static func selected_stage(_fallback: String = "stage_1") -> String:
	return CHARACTERS.stage_for_hero(selected_hero())
static func select_stage(id: String) -> bool:
	return select_hero(CHARACTERS.hero_for_stage(id))
static func skill_pool(stage: String) -> Array:
	var hero_id := CHARACTERS.hero_for_stage(stage) if stage.begins_with("stage_") else stage
	return WEAPONS.weapon_pool(hero_id) if not CHARACTERS.get_character(hero_id).is_empty() else []
static func skills(stage: String) -> Array:
	var config := ConfigFile.new()
	if not _load(config): return []
	var result: Array = []
	for raw in String(config.get_value("hero_loadout",stage+"_skills","")).split(",",false):
		var id := String(raw)
		if id in skill_pool(stage) and id not in result and WEAPONS.is_weapon(id): result.append(id)
		if result.size() == DATA.SKILL_SLOTS: break
	return result
static func set_skills(stage: String,ids: Array) -> bool:
	if STAGES.get_stage(stage).is_empty(): return false
	if ids.size() > DATA.SKILL_SLOTS: return false
	var unique: Array = []
	var pool := skill_pool(stage)
	for id in ids:
		if id not in pool or id in unique or not WEAPONS.is_weapon(id): return false
		unique.append(id)
	var config := ConfigFile.new()
	if not _load(config): return false
	config.set_value("hero_loadout",stage+"_skills",",".join(unique))
	return SCOPE.save_config(config,PATH) == OK
static func growth_level(stage: String,id: String) -> int:
	var config := ConfigFile.new()
	if not DATA.GROWTH.has(id) or not _load(config): return 0
	return _shared_growth(config,id)
static func purchase_growth(stage: String,id: String) -> bool:
	if not DATA.GROWTH.has(id) or not character_unlocked(stage): return false
	var config := ConfigFile.new(); var progress := ConfigFile.new()
	if not _load(config) or not _load(progress,"user://stage_progress.cfg"): return false
	var level := _shared_growth(config,id)
	var cost := DATA.growth_cost(id,level)
	var points := int(progress.get_value("meta","research_points",0))
	if level >= int(DATA.GROWTH[id].max) or cost > points: return false
	progress.set_value("meta","research_points",points-cost)
	config.set_value("hero_growth","shared_"+id,level+1)
	return SCOPE.save_configs({"stage_progress.cfg":progress,"team_loadout.cfg":config}) == OK
static func apply_growth(stage: String,profile: Dictionary) -> void:
	var hp := 1.0; var damage := 1.0
	for id in DATA.GROWTH:
		var level := growth_level(stage,id)
		hp += level*float(DATA.GROWTH[id].hp); damage += level*float(DATA.GROWTH[id].damage)
	profile["max_hp"] = maxi(1,roundi(float(profile.get("max_hp",1))*hp))
	profile["attack_damage"] = maxi(1,roundi(float(profile.get("attack_damage",1))*damage))
static func award_run(stage: String,entry: Dictionary,elapsed: float,kills: int,won: bool) -> Dictionary:
	if STAGES.get_stage(stage).is_empty() or not is_finite(elapsed) or elapsed < 0.0 or kills < 0 or (won and elapsed < DATA.DURATION): return {"success":false}
	if String(entry.get("owner","")) != (SCOPE.user_id if not SCOPE.user_id.is_empty() else "guest:"+SCOPE.guest_directory): return {"success":false}
	var serial := int(entry.get("entry_id",0))
	if serial <= 0: return {"success":false}
	var config := ConfigFile.new(); var progress := ConfigFile.new()
	if not _load(config) or not _load(progress,"user://stage_progress.cfg"): return {"success":false}
	if serial != int(progress.get_value("stamina","active_entry",0)) or not bool(progress.get_value("stamina","active_claimed",false)) or String(progress.get_value("stamina","active_stage","")) != stage: return {"success":false}
	if serial <= int(config.get_value("hero_progress","last_reward_entry",0)): return {"success":true,"research":0,"gold":0}
	if int(STAGES.get_stage(stage).get("number",0)) > _highest_battle_stage_in_config(config): return {"success":false}
	var eligible := elapsed >= 30.0 and kills > 0
	var points: int = DATA.WIN_RESEARCH if won else (DATA.PARTIAL_RESEARCH if eligible else 0)
	var gold: int = DATA.WIN_GOLD if won else (DATA.PARTIAL_GOLD if eligible else 0)
	config.set_value("hero_progress","last_reward_entry",serial)
	config.set_value("hero_progress",stage+"_best_seconds",maxf(elapsed,float(config.get_value("hero_progress",stage+"_best_seconds",0.0))))
	if won: config.set_value("hero_progress",stage+"_wins",int(config.get_value("hero_progress",stage+"_wins",0))+1)
	progress.set_value("meta","research_points",int(progress.get_value("meta","research_points",0))+points)
	progress.set_value("meta","gold",int(progress.get_value("meta","gold",0))+gold)
	var success := SCOPE.save_configs({"stage_progress.cfg":progress,"team_loadout.cfg":config}) == OK
	return {"success":success,"research":points if success else 0,"gold":gold if success else 0}

static func character_unlocked(subject: String) -> bool:
	var id := CHARACTERS.hero_for_stage(subject) if subject.begins_with("stage_") else subject
	var data: Dictionary = CHARACTERS.get_character(id)
	if data.is_empty(): return false
	if id == CHARACTERS.DEFAULT_HERO: return true
	if all_characters_unlocked_for_test(): return true
	var collection := ConfigFile.new()
	if not _load(collection): return false
	if bool(collection.get_value("hero_collection",id,false)): return true
	var config := ConfigFile.new()
	if not _load(config,"user://stage_progress.cfg"): return false
	return bool(config.get_value("hard_cleared",String(data.stage),false))
static func all_characters_unlocked_for_test() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var mode := tree.root.get_node_or_null("LocalTestMode") if tree != null else null
	return mode != null and bool(mode.call("has_all_heroes_unlocked"))
static func set_character_owned_in_config(config: ConfigFile,id: String) -> bool:
	# Future summon transactions can debit currency and grant ownership atomically.
	if CHARACTERS.get_character(id).is_empty(): return false
	config.set_value("hero_collection",id,true)
	return true
static func _growth_key(subject: String) -> String:
	if subject.begins_with("stage_"): return subject
	var stage := CHARACTERS.stage_for_hero(subject)
	return stage if not stage.is_empty() else subject

static func _shared_growth(config: ConfigFile,id: String) -> int:
	var level := int(config.get_value("hero_growth","shared_"+id,0))
	for hero_id in CHARACTERS.ORDER:
		level = maxi(level,int(config.get_value("hero_growth",_growth_key(String(hero_id))+"_"+id,0)))
	return clampi(level,0,int(DATA.GROWTH[id].max))
static func difficulty() -> String:
	var config := ConfigFile.new()
	if not _load(config): return "easy"
	return "hard" if String(config.get_value("hero_loadout","difficulty","easy")) == "hard" else "easy"
static func set_difficulty(value: String) -> bool:
	if value not in ["easy","hard"]: return false
	var config := ConfigFile.new()
	if not _load(config): return false
	config.set_value("hero_loadout","difficulty",value)
	return SCOPE.save_config(config,PATH) == OK
