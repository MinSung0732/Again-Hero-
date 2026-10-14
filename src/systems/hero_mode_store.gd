extends RefCounted
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
const PROFILES := preload("res://src/data/hero_profiles.gd")
const CHARACTERS := preload("res://src/data/hero_character_catalog.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const UNLOCK_DATA := preload("res://src/data/mode_unlock_catalog.gd")
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const RESEARCH_PROFILE_FIELDS := {"max_hp":"vitality","attack_damage":"power","move_speed":"mobility","exp_pickup_radius":"magnet"}
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
static func test_override() -> bool:
	return all_characters_unlocked_for_test()
static func mode_unlocked() -> bool:
	return test_override() or PROGRESS.is_stage_cleared(String(UNLOCK_DATA.RULES.hero.required_stage))
static func hard_stage_unlocked(id: String) -> bool:
	return battle_stage_unlocked(id) and (test_override() or battle_stage_cleared(id,"easy"))
static func can_enter(id: String, value: String) -> bool:
	return value in ["easy","hard"] and battle_stage_unlocked(id) and (value == "easy" or hard_stage_unlocked(id))
static func highest_battle_stage() -> int:
	return STAGES.get_ordered_stage_ids().size() if mode_unlocked() else 0
static func _highest_battle_stage_in_config(_config: ConfigFile) -> int:
	# Kept for legacy callers: battlefield availability follows the mode gate.
	return highest_battle_stage()
static func battle_stage_unlocked(id: String) -> bool:
	var stage: Dictionary = STAGES.get_stage(id)
	return not stage.is_empty() and int(stage.get("number",0)) <= highest_battle_stage()
static func battle_stage_cleared(id: String, value: String = "easy") -> bool:
	if value not in ["easy","hard"] or STAGES.get_stage(id).is_empty(): return false
	var config := ConfigFile.new()
	# Legacy aggregate wins may include hard runs; never fabricate easy clears.
	return _load(config) and int(config.get_value("hero_progress",id+"_"+value+"_wins",0)) > 0
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
static func growth_bonuses(subject: String) -> Dictionary:
	var config := ConfigFile.new(); var result := {}
	if not _load(config): return result
	for id in DATA.GROWTH: result[id] = _shared_growth(config,id)*float(DATA.GROWTH[id].value)
	return result
static func apply_growth(stage: String,profile: Dictionary) -> void:
	var bonus := growth_bonuses(stage)
	for field in RESEARCH_PROFILE_FIELDS:
		var amount := float(profile.get(field,1))*(1.0+float(bonus.get(RESEARCH_PROFILE_FIELDS[field],0)))
		profile[field] = maxi(1,roundi(amount)) if field in ["max_hp","attack_damage"] else amount
	profile["hero_research_bonuses"] = bonus
static func record_chest(entry: Dictionary, chest_serial: int, gold_bonus: float = 0.0) -> Dictionary:
	var serial := int(entry.get("entry_id",0)); var config := ConfigFile.new(); var progress := ConfigFile.new()
	if not is_finite(gold_bonus) or serial <= 0 or chest_serial <= 0 or not _load(config) or not _load(progress,"user://stage_progress.cfg"): return {"success":false}
	if String(entry.get("owner","")) != (SCOPE.user_id if not SCOPE.user_id.is_empty() else "guest:"+SCOPE.guest_directory): return {"success":false}
	if serial != int(progress.get_value("stamina","active_entry",0)) or not bool(progress.get_value("stamina","active_claimed",false)) or serial <= int(config.get_value("hero_progress","last_reward_entry",0)): return {"success":false}
	var same := int(config.get_value("hero_run_gold","entry",0)) == serial
	var previous := int(config.get_value("hero_run_gold","chest",0)) if same else 0
	var units := int(config.get_value("hero_run_gold","units",0)) if same else 0
	if chest_serial <= previous: return {"success":true,"pending":floori(units/1000.0)}
	units += roundi(DATA.CHEST_GOLD*1000*(1.0+clampf(gold_bonus,0,0.15)))
	config.set_value("hero_run_gold","entry",serial); config.set_value("hero_run_gold","chest",chest_serial); config.set_value("hero_run_gold","units",units)
	return {"success":SCOPE.save_config(config,PATH) == OK,"pending":floori(units/1000.0)}
static func award_run(stage: String,entry: Dictionary,elapsed: float,kills: int,won: bool,value: String = "easy", outcome: String = "", gold_bonus: float = -1.0) -> Dictionary:
	if not is_finite(gold_bonus) or outcome not in ["","victory","defeat","abandon"] or (won and outcome in ["defeat","abandon"]) or (not won and outcome == "victory"): return {"success":false}
	if not can_enter(stage,value): return {"success":false}
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
	var ratio := float(DATA.CHEST_GOLD_RATES["victory" if won else "abandon" if outcome == "abandon" else "defeat"])
	var units := int(config.get_value("hero_run_gold","units",0)) if int(config.get_value("hero_run_gold","entry",0)) == serial else 0
	var chest_paid := floori(maxi(0,units)*ratio/1000.0)
	var bonus := clampf(gold_bonus if gold_bonus >= 0.0 else _shared_growth(config,"gold")*float(DATA.GROWTH.gold.value),0,0.15)
	gold = floori(gold*(1.0+bonus))+chest_paid
	config.set_value("hero_progress","last_reward_entry",serial)
	config.set_value("hero_progress",stage+"_best_seconds",maxf(elapsed,float(config.get_value("hero_progress",stage+"_best_seconds",0.0))))
	if won:
		config.set_value("hero_progress",stage+"_wins",int(config.get_value("hero_progress",stage+"_wins",0))+1)
		var wins_key := stage+"_"+value+"_wins"
		config.set_value("hero_progress",wins_key,int(config.get_value("hero_progress",wins_key,0))+1)
	progress.set_value("meta","research_points",int(progress.get_value("meta","research_points",0))+points)
	progress.set_value("meta","gold",int(progress.get_value("meta","gold",0))+gold)
	var success := SCOPE.save_configs({"stage_progress.cfg":progress,"team_loadout.cfg":config}) == OK
	return {"success":success,"research":points if success else 0,"gold":gold if success else 0,"chest_earned":floori(maxi(0,units)/1000.0),"chest_paid":chest_paid if success else 0,"chest_rate":ratio}

static func character_unlocked(subject: String) -> bool:
	var id := CHARACTERS.hero_for_stage(subject) if subject.begins_with("stage_") else subject
	var data: Dictionary = CHARACTERS.get_character(id)
	if data.is_empty(): return false
	return all_characters_unlocked_for_test() or (mode_unlocked() and PROGRESS.is_stage_cleared(String(data.stage)))
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
	var value := String(config.get_value("hero_loadout","difficulty","easy"))
	return "hard" if value == "hard" and hard_stage_unlocked(selected_battle_stage()) else "easy"
static func set_difficulty(value: String, stage_id: String = "") -> bool:
	var target := selected_battle_stage() if stage_id.is_empty() else stage_id
	if not can_enter(target,value): return false
	var config := ConfigFile.new()
	if not _load(config): return false
	config.set_value("hero_loadout","difficulty",value)
	return SCOPE.save_config(config,PATH) == OK
