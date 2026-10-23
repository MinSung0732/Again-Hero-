extends RefCounted
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
const TARGETS := preload("res://src/systems/hero_target_policy.gd")
const EFFECT_LIMIT := 48
const PROJECTILE_LIMIT := 64
const MODE := preload("res://src/data/hero_mode_catalog.gd")
const AFFLICTIONS := preload("res://src/systems/received_afflictions.gd")
const ART := preload("res://src/ui/hero_weapon_art.gd")
const NATIVE := preload("res://src/hero_mode/hero_weapon_native_runtime.gd")
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
const IDENTITY := preload("res://src/hero_mode/hero_survival_identity_runtime.gd")
const EVOLUTION := preload("res://src/hero_mode/hero_weapon_evolution_runtime.gd")
const DELIVERY := preload("res://src/hero_mode/hero_weapon_delivery_runtime.gd")
const KIT := preload("res://src/hero_mode/hero_weapon_kit_runtime.gd")
const FLIGHT := preload("res://src/hero_mode/hero_weapon_flight_runtime.gd")
const EMPTY_ART: Array[Texture2D] = []
var combat_profile: RefCounted
var native_skills: RefCounted
var identity: RefCounted
var delivery: RefCounted
var evolution: RefCounted
var kit: RefCounted
var flight: RefCounted
var art: Dictionary = {}
var magazines: Dictionary = {}
var hero
var levels: Dictionary = {}
var passives: Dictionary = {}
var evolved: Dictionary = {}
var weapon_ids: Array[String] = []
var available_weapons: Array = []
var cooldowns: Dictionary = {}
var scratch: Array = []
var pulse_scratch: Array = []
var splash_scratch: Array = []
var resolved: Dictionary = {}
var pulses: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var fields: Array[Dictionary] = []
var field_cursor := 0
var effect_cursor := 0
var power := 1.0
var haste := 1.0
var projectile_speed := 1.0
var damage_multiplier := 1.0
var base_max_hp := 1200
var base_move_speed := 270.0
var base_pickup_radius := 150.0
var base_exp_multiplier := 1.0
var projectiles: Array[Dictionary] = []
var projectile_cursor := 0
var authority: Node
var visual_clock := 0.0
var chest_serial := 0
var last_applied_chest := 0
var research: Dictionary = {}
var gold_bonus := 0.0
var regen_bank := 0.0
var passive_siphon := 0.0
var siphon_bank := 0.0
var reach_bonus := 1.0
var area_bonus := 1.0
var duration_bonus := 1.0
var projectile_power := 1.0
var projectile_bonus := 0
var base_slow_resistance := 0.0
var shield_left := 0.0
var owned_shield := 0.0
var awakening_flash := 0.0
var reroll_limit := MODE.AUGMENT_REROLLS
var rerolls_used := 0

const RESTORE_CARD := {"id":"survival_restore","name":"완성된 빌드 · 회복","description":"모든 선택이 최대 레벨입니다. 최대 HP의 15%를 회복합니다."}
func rerolls_remaining() -> int:
	return maxi(0,reroll_limit-rerolls_used)

func reroll(previous: Array) -> Array:
	if previous.is_empty() or rerolls_remaining() <= 0 or hero.current_hp <= 0: return []
	var old_ids: Array = []
	for card in previous: old_ids.append(String(card.id))
	var next := candidates(old_ids)
	var changed := next.size() != previous.size()
	for card in next:
		if String(card.id) not in old_ids: changed = true
	if not changed: return []
	rerolls_used += 1
	return next

func install(host, research_bonus: int = 0, starting_research: Dictionary = {}) -> void:
	reroll_limit = MODE.augment_reroll_limit(research_bonus)
	rerolls_used = 0
	research = starting_research.duplicate()
	gold_bonus = float(research.get("gold",0))
	haste = 1.0/(1.0+float(research.get("haste",0)))
	passive_siphon = float(research.get("siphon",0))
	area_bonus = 1.0+float(research.get("area",0))
	hero = host
	hero.exp_gain_multiplier *= 1.0+float(research.get("learning",0))
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	authority = hero.get_parent()
	combat_profile = authority.get("combat_profile") if is_instance_valid(authority) else null
	delivery = DELIVERY.new(); delivery.install(self)
	kit = KIT.new(); kit.install(self)
	flight = FLIGHT.new(); flight.install(self)
	evolution = EVOLUTION.new(); evolution.install(self)
	if "status_resistances" in hero: base_slow_resistance = float(hero.status_resistances.get("slow",0))
	base_max_hp = int(hero.max_hp); base_move_speed = float(hero.move_speed)
	base_pickup_radius = float(hero.exp_pickup_radius); base_exp_multiplier = float(hero.exp_gain_multiplier)
	for index in range(PROJECTILE_LIMIT):
		projectiles.append({"active":false,"handle":Vector3i.ZERO,"position":Vector2.ZERO,"damage":0,"rank":1,"color":Color.WHITE,"age":0.0,"delay":0.0,"data":{},"melee":false,"reach":0.0,"traveled":0.0,"frames":EMPTY_ART,"direction":Vector2.RIGHT,"flight":"homing","phase":0,"victims":{},"start":Vector2.ZERO,"strikes":0,"pierces":1,"bounces":0,"serial":0})
	available_weapons = DATA.weapon_pool(String(hero.hero_id))
	var effect_directories := {}
	for id in available_weapons:
		effect_directories[String(DATA.WEAPONS[id].get("effect_dir",""))] = true
	ART.retain_sequences(effect_directories)
	if hero.has_method("_acquire_projectile"):
		native_skills = NATIVE.new(); native_skills.install(hero)
	# Generic effects are required even when the host has no native actor pool.
	for id in available_weapons:
		var pattern := String(DATA.WEAPONS[id].pattern)
		# Native actors own their cached textures; do not duplicate their bitmaps.
		art[id] = EMPTY_ART if native_skills != null and NATIVE.SCENES.has(pattern) else ART.sequence(String(DATA.WEAPONS[id].get("effect_dir","")))
	for index in range(EFFECT_LIMIT):
		effects.append({"left":0.0,"duration":0.0,"a":Vector2.ZERO,"b":Vector2.ZERO,"radius":0.0,"pattern":"","color":Color.WHITE,"orbit_count":4,"orbit_speed":3.0,"orbit_ratio":0.7})
	for index in range(8): fields.append({"left":0.0,"tick":0.0,"origin":Vector2.ZERO,"radius":0.0,"damage":0,"interval":0.5,"follow":false,"data":{},"rank":1})
	for index in 24: pulses.append({"active":false,"left":0.0,"origin":Vector2.ZERO,"direction":Vector2.RIGHT,"radius":0.0,"damage":0,"rank":1,"data":{}})
	add(String(DATA.STARTERS.get(hero.hero_id,"ranged_rookie_arcane_bolt")))
	if hero.has_method("_draw_combat_status_overlay"):
		identity = IDENTITY.new(); identity.install(hero,self)

func add(id: String) -> bool:
	if DATA.is_weapon(id):
		if id not in available_weapons: return false
		if int(levels.get(id,0)) >= DATA.MAX_LEVEL: return false
		if not levels.has(id):
			if weapon_ids.size() >= DATA.WEAPON_SLOTS: return false
			weapon_ids.append(id); cooldowns[id] = 0.0
			magazines[id] = int(DATA.WEAPONS[id].get("magazine",0))
		levels[id] = int(levels.get(id,0))+1
		resolved.erase(id)
		hero.build_counts[id] = levels[id]
		for weapon in weapon_ids: _refresh_owned_summons(weapon)
		return true
	if not DATA.PASSIVES.has(id) or not DATA.passive_allowed(id,String(hero.hero_id),weapon_ids): return false
	if bool(DATA.PASSIVES[id].get("one_shot",false)):
		if hero.current_hp <= 0 or hero.current_hp >= hero.max_hp: return false
		hero.heal_direct(roundi(hero.max_hp*float(DATA.PASSIVES[id].value))); return true
	if int(passives.get(id,0)) >= DATA.passive_limit(id): return false
	if not passives.has(id) and passives.size() >= DATA.PASSIVE_SLOTS: return false
	passives[id] = int(passives.get(id,0))+1
	hero.build_counts[id] = passives[id]
	var data: Dictionary = DATA.PASSIVES[id]
	var rank := int(passives[id])
	var bonus := float(data.value)*rank
	match String(data.stat):
		"siphon": passive_siphon = bonus+float(research.get("siphon",0))
		"slow_resist": hero.status_resistances["slow"] = minf(0.85,base_slow_resistance+bonus)
		"reach": reach_bonus = 1.0+bonus
		"area": area_bonus = 1.0+bonus+float(research.get("area",0))
		"duration": duration_bonus = 1.0+bonus
		"projectile_power": projectile_power = 1.0+bonus
		"multishot": projectile_bonus = mini(2,rank)
		"power": power = 1.0+bonus
		"haste": haste = 1.0/(1.0+bonus+float(research.get("haste",0)))
		"projectile": projectile_speed = 1.0+bonus
		"armor": damage_multiplier = 1.0-minf(bonus,0.30)
		"vitality":
			var increase: int = roundi(base_max_hp*float(data.value)*rank)-roundi(base_max_hp*float(data.value)*(rank-1))
			hero.max_hp += increase; hero.heal_direct(increase)
		"mobility": hero.move_speed = base_move_speed*(1.0+bonus)
		"magnet": hero.exp_pickup_radius = base_pickup_radius*(1.0+bonus)
		"learning": hero.exp_gain_multiplier = base_exp_multiplier*(1.0+bonus)
	resolved.clear()
	for weapon in weapon_ids: _refresh_owned_summons(weapon)
	return true

func _refresh_owned_summons(id: String) -> void:
	if native_skills == null or String(DATA.WEAPONS[id].pattern) != "summon": return
	if not native_skills.summon_configs.has(String(DATA.WEAPONS[id].summon_kind)): return
	var data := stats_for(id)
	native_skills.refresh_summons(data,_cast_damage(id,data))

func candidates(previous_ids: Array = []) -> Array:
	var options: Array = []
	for id in available_weapons:
		var card := offer_card(id)
		if not card.is_empty(): options.append(card)
	for id in DATA.PASSIVES:
		if bool(DATA.PASSIVES[id].get("one_shot",false)) and not (hero.current_hp > 0 and hero.current_hp < hero.max_hp): continue
		var card := offer_card(id)
		if not card.is_empty(): options.append(card)
	# Guarantee an owned upgrade when available; two other choices still explore.
	var result: Array = []
	var owned: Array = []
	for card in options:
		if levels.has(card.id): owned.append(card)
	var fresh_owned: Array = []
	for card in owned:
		if String(card.id) not in previous_ids: fresh_owned.append(card)
	if not fresh_owned.is_empty(): owned = fresh_owned
	if not owned.is_empty():
		var chosen: Dictionary = owned[randi_range(0,owned.size()-1)]
		result.append(chosen); options.erase(chosen)
	options.shuffle()
	var fresh: Array = []
	var repeated: Array = []
	for card in options:
		if String(card.id) in previous_ids: repeated.append(card)
		else: fresh.append(card)
	while result.size() < 3 and not fresh.is_empty(): result.append(fresh.pop_back())
	while result.size() < 3 and not repeated.is_empty(): result.append(repeated.pop_back())
	if result.is_empty(): result.append(RESTORE_CARD.duplicate())
	return result

# Current-level card for one id, or {} when it can no longer be taken (max level or full slots).
# Held online offers re-read this so a stored card never shows a stale level.
func offer_card(id: String) -> Dictionary:
	if id == RESTORE_CARD.id: return RESTORE_CARD.duplicate()
	if DATA.is_weapon(id):
		if id not in available_weapons or int(levels.get(id,0)) >= DATA.MAX_LEVEL: return {}
		if not levels.has(id) and weapon_ids.size() >= DATA.WEAPON_SLOTS: return {}
		return _card(id,int(levels.get(id,0))+1)
	if not DATA.PASSIVES.has(id) or not DATA.passive_allowed(id,String(hero.hero_id),weapon_ids): return {}
	if bool(DATA.PASSIVES[id].get("one_shot",false)): return _card(id,1)
	if int(passives.get(id,0)) >= DATA.passive_limit(id): return {}
	if not passives.has(id) and passives.size() >= DATA.PASSIVE_SLOTS: return {}
	return _card(id,int(passives.get(id,0))+1)

func _card(id: String, next_level: int) -> Dictionary:
	var data: Dictionary = DATA.WEAPONS.get(id,DATA.PASSIVES.get(id,{}))
	if bool(data.get("one_shot",false)): return {"id":id,"name":String(data.name),"description":DATA.description(id,1)}
	var comparison: Array = []
	if DATA.is_weapon(id):
		var current: Dictionary = stats_for(id) if levels.has(id) else {}
		var had_level := levels.has(id)
		var previous_level := int(levels.get(id,0))
		var previous_cache: Dictionary = resolved.get(id,{})
		levels[id] = next_level
		resolved.erase(id)
		var projected: Dictionary = stats_for(id)
		projected = projected.duplicate()
		projected["display_damage"] = _cast_damage(id,projected)
		var next_cooldown := float(projected.cooldown)*haste*float(projected.cooldown_scale)
		projected["display_cooldown"] = identity.cooldown_for(id,next_cooldown) if identity != null else next_cooldown
		if not current.is_empty():
			current = current.duplicate()
			current["display_damage"] = _cast_damage(id,current)
			var old_cooldown := float(current.cooldown)*haste*float(current.cooldown_scale)
			current["display_cooldown"] = identity.cooldown_for(id,old_cooldown) if identity != null else old_cooldown
		if had_level: levels[id] = previous_level
		else: levels.erase(id)
		if previous_cache.is_empty(): resolved.erase(id)
		else: resolved[id] = previous_cache
		var base_damage: float = identity.attack_damage() if identity != null else float(hero.attack_damage)
		comparison = DATA.compare(id,next_level,current,projected,base_damage*power)
	else:
		comparison = DATA.compare(id,next_level)
	return {"id":id,"name":("무기" if DATA.is_weapon(id) else "보조")+" · "+String(data.name)+" Lv.%d" % next_level,"description":DATA.description(id,next_level),"compare":comparison}

func choose(id: String) -> bool:
	if id == "survival_restore": hero.heal_direct(roundi(hero.max_hp*0.15)); return true
	return add(id)

func roll_chest() -> Dictionary:
	var eligible: Array[String] = []
	for id in weapon_ids:
		if int(levels[id]) == DATA.MAX_LEVEL and not evolved.has(id): eligible.append(id)
	var evolution := not eligible.is_empty()
	if not evolution:
		for id in weapon_ids:
			if int(levels[id]) < DATA.MAX_LEVEL: eligible.append(id)
	var passive_reward := false
	if eligible.is_empty():
		for id in passives:
			if int(passives[id]) < DATA.passive_limit(id) and not bool(DATA.PASSIVES[id].get("one_shot",false)) and DATA.passive_allowed(id,String(hero.hero_id),weapon_ids): eligible.append(String(id))
		passive_reward = not eligible.is_empty()
	chest_serial += 1
	if eligible.is_empty(): return {"serial":chest_serial,"id":"survival_restore","evolution":false,"name":"생명의 축복","description":"장착 증강이 모두 완성됐습니다. 최대 HP 25% 회복","kind":"recovery","pool":["survival_restore"],"applied":false}
	var id := eligible[randi_range(0,eligible.size()-1)]
	if passive_reward:
		var next_level := int(passives[id])+1
		return {"serial":chest_serial,"id":id,"evolution":false,"kind":"passive","pool":eligible,"name":String(DATA.PASSIVES[id].name)+" Lv.%d" % next_level,"description":DATA.description(id,next_level),"applied":false}
	return {"serial":chest_serial,"id":id,"evolution":evolution,"kind":"weapon","pool":eligible,"name":DATA.GROWTH.evolution_name(id) if evolution else String(DATA.WEAPONS[id].name)+" Lv.%d" % (int(levels[id])+1),"description":DATA.description(id,11 if evolution else int(levels[id])+1),"applied":false}

func apply_chest(receipt: Dictionary) -> bool:
	if bool(receipt.get("applied",false)) or int(receipt.get("serial",-1)) != chest_serial or chest_serial <= last_applied_chest: return false
	var id := String(receipt.get("id",""))
	if id == "survival_restore": hero.heal_direct(roundi(hero.max_hp*0.25))
	elif bool(receipt.get("evolution",false)):
		if int(levels.get(id,0)) != DATA.MAX_LEVEL or evolved.has(id): return false
		evolved[id] = true
		resolved.erase(id)
		_refresh_owned_summons(id)
		cooldowns[id] = 0.0 # MAX is ready immediately after the chest closes.
		awakening_flash = 1.6
		hero.queue_redraw()
	else:
		if not levels.has(id) and not passives.has(id): return false
		if not add(id): return false
	receipt["applied"] = true
	last_applied_chest = chest_serial
	return true

func build_tags() -> Dictionary:
	var result: Dictionary = {}
	for id in weapon_ids:
		for tag in DATA.WEAPONS[id].tags: result[tag] = int(result.get(tag,0))+int(levels[id])
	if passives.has("survival_mobility"): result["mobility"] = int(passives.survival_mobility)
	return result

func summary() -> String:
	var parts: PackedStringArray = []
	for id in weapon_ids:
		parts.append(DATA.GROWTH.evolution_name(id) if evolved.has(id) else String(DATA.WEAPONS[id].name)+" Lv.%d/10" % int(levels[id]))
	return " · ".join(parts)

func tick(delta: float, allow_casts: bool = true) -> void:
	var started: int = Time.get_ticks_usec() if combat_profile != null and combat_profile.enabled else 0
	_tick_weapons(delta,allow_casts)
	if started: combat_profile.record(combat_profile.Scope.WEAPONS,started)

func _tick_weapons(delta: float, allow_casts: bool = true) -> void:
	visual_clock += delta
	if awakening_flash>0.0:
		awakening_flash=maxf(0.0,awakening_flash-delta);hero.queue_redraw()
	if kit != null: kit.tick(delta)
	if delivery != null: delivery.tick(delta)
	if evolution != null: evolution.tick(delta)
	if hero.current_hp > 0 and hero.current_hp < hero.max_hp:
		regen_bank += hero.max_hp*float(research.get("regeneration",0))*delta
		var recovered := floori(regen_bank)
		if recovered > 0: hero.heal_direct(recovered); regen_bank -= recovered
	else: regen_bank = 0.0
	var identity_blocked: bool = allow_casts and identity != null and identity.tick(delta)
	_tick_projectiles(delta)
	_tick_pulses(delta)
	var redraw := false
	for effect in effects:
		if float(effect.left) <= 0.0: continue
		effect.left = maxf(0.0,float(effect.left)-delta); redraw = true
	if redraw: hero.queue_redraw()
	if shield_left > 0.0:
		shield_left -= delta
		if shield_left <= 0.0:
			hero.shield_hp = maxf(0.0,hero.shield_hp-owned_shield); owned_shield = 0.0
	for field in fields:
		if float(field.left) <= 0.0: continue
		hero.queue_redraw()
		field.left = maxf(0.0,float(field.left)-delta)
		if float(field.left) <= 0.0: continue
		if bool(field.follow): field.origin = hero.global_position
		field.tick = float(field.tick)-delta
		if float(field.tick) > 0.0: continue
		field.tick = float(field.interval)
		hero._fill_monster_nodes_near(field.origin,float(field.radius),scratch)
		for raw in scratch:
			var actor := raw as Node2D
			if not TARGETS.is_detectable(actor): continue
			# Grid queries return padded cells, not an exact circle.
			if actor.global_position.distance_squared_to(field.origin) > float(field.radius)*float(field.radius): continue
			_hit(actor,int(field.damage),"field",int(field.rank),field.data)
	if not allow_casts or identity_blocked or hero.silence_timer > 0.0 or hero.imposed_skill_cooldown > 0.0 or hero.petrify_timer > 0.0: return
	for id in weapon_ids:
		cooldowns[id] = maxf(0.0,float(cooldowns[id])-delta*hero.get_paralysis_attack_multiplier())
		if float(cooldowns[id]) > 0.0: continue
		_cast(id)
		var stats := stats_for(id)
		cooldowns[id] = float(stats.cooldown)*haste*float(stats.cooldown_scale)
		if identity != null: cooldowns[id] = identity.cooldown_for(id,float(cooldowns[id]))
		if (identity == null or identity.archetype != "pistol_gunner") and int(DATA.WEAPONS[id].get("magazine",0)) > 0 and int(magazines[id]) <= 0:
			cooldowns[id] += float(DATA.WEAPONS[id].get("reload",1.6))
			magazines[id] = int(DATA.WEAPONS[id].magazine)

func stats_for(id: String) -> Dictionary:
	if resolved.has(id):
		var cached: Dictionary = resolved[id]
		if int(cached.growth_rank) == int(levels[id]) and bool(cached.growth_evolved) == evolved.has(id): return cached
	var stats := DATA.GROWTH.resolve(id,DATA.WEAPONS[id],int(levels[id]),evolved.has(id))
	if native_skills != null and String(stats.pattern) == "summon":
		var config: Dictionary = native_skills.summon_configs[String(stats.summon_kind)].duplicate(true)
		if stats.has("summon_patch"):
			config.merge(stats.summon_patch,true)
			config["survival_overrides"] = stats.summon_patch
		for key in ["attack_range","range"]:
			var summon_reach := reach_bonus*(1.0+float(research.get("ranged_reach",0)) if String(stats.summon_kind) in ["watcher","gatekeeper"] else 1.0)
			if config.has(key) and summon_reach != 1.0:
				config[key] = float(config[key])*summon_reach
				if not config.has("survival_overrides"): config["survival_overrides"] = {}
				else: config["survival_overrides"] = config.survival_overrides.duplicate()
				config.survival_overrides[key] = config[key]
		config["survival_weapon_id"] = id
		stats["summon_config"] = config
		if String(stats.summon_kind) in ["watcher","gatekeeper"]: stats["power"] = float(stats.power)*projectile_power
	stats["reach_scale"] = float(stats.reach_scale)*reach_bonus
	var pattern := String(stats.pattern)
	if pattern in DATA.RANGED_RESEARCH_PATTERNS: stats["reach_scale"] *= 1.0+float(research.get("ranged_reach",0))
	stats["area_scale"] = area_bonus
	for key in ["splash_radius","finish_radius"]:
		if stats.has(key): stats[key] = float(stats[key])*area_bonus
	if pattern not in DATA.AREA_PATTERNS and stats.has("pulse_count"):
		stats["pulse_radius_ratio"] = float(stats.get("pulse_radius_ratio",0.6))*area_bonus
	if pattern in DATA.AREA_PATTERNS:
		stats["area_scale"] = area_bonus
		if pattern not in ["beam","capsule"]: stats["reach_scale"] *= area_bonus
		stats["native_radius_scale"] = float(stats.get("native_radius_scale",1.0))*area_bonus
	if pattern == "guard": stats["shield_duration"] = float(stats.get("shield_duration",3.0))
	for key in ["field_duration","summon_duration","shield_duration"]:
		if stats.has(key): stats[key] = float(stats[key])*duration_bonus
	if pattern in DATA.PROJECTILE_PATTERNS:
		stats["power"] = float(stats.power)*projectile_power
	stats["extra_projectiles"] = projectile_bonus if DATA.projectile_quantity_kind(id) != "" else 0
	if DATA.projectile_quantity_kind(id) == "orbit":
		stats["orbit_count"] = mini(10,int(stats.get("orbit_count",4))+int(stats.extra_projectiles))
	var secondary := stats.duplicate()
	secondary["evolution_secondary"] = true
	stats["evolution_secondary_data"] = secondary
	resolved[id] = stats
	return stats

func _cast_damage(id: String, data: Dictionary) -> int:
	var base_damage: float = identity.attack_damage() if identity != null else float(hero.attack_damage)
	var damage: int = maxi(1,roundi(base_damage*float(data.power)*power*float(data.damage_scale)))
	damage = maxi(1,roundi(damage*(1.0+float(data.get("low_hp_bonus",0.0))*(1.0-float(hero.current_hp)/maxf(hero.max_hp,1)))))
	if identity != null: damage = identity.modify_damage(id,damage)
	return damage

func _cast(id: String) -> void:
	var data := stats_for(id)
	var rank := int(levels[id])
	var awakened := evolved.has(id)
	if identity != null and not identity.can_cast(id,String(data.pattern)): return
	if identity != null: identity.prepare_cast(id)
	var origin: Vector2 = kit.origin(data,hero.global_position) if kit != null else hero.global_position
	var reach: float = GEOMETRY.reach(data,rank,awakened)
	var damage := _cast_damage(id,data)
	var hits := int(data.get("base_hits",1))+int(data.get("bonus_hits",0))
	var pattern := String(data.pattern)
	var color := Color(String(data.color))
	hero._fill_monster_nodes_near(origin,reach,scratch)
	# Existing world-query registry/grid supplies detectable candidates; no group scan.
	var closest: Node2D = null
	var closest_distance := INF
	for raw in scratch:
		var actor := raw as Node2D
		if not TARGETS.is_detectable(actor): continue
		var distance: float = origin.distance_squared_to(actor.global_position)
		if distance > reach*reach: continue
		if distance < closest_distance: closest_distance = distance; closest = actor
	if not is_instance_valid(closest) and float(data.get("gas_cost",0.0)) > 0.0 and pattern == "poison" and DELIVERY.RULES.spec(id,data).is_empty(): return
	if kit != null and is_instance_valid(closest):
		var ambush: float = kit.cast_factor(data)
		damage = maxi(1,roundi(damage*ambush))
		if ambush > 1.0: _effect(origin,closest.global_position,34.0,"combo",color,data)
	var direction: Vector2 = hero.player_move_input.normalized()
	if is_instance_valid(closest): direction = origin.direction_to(closest.global_position)
	if direction.length_squared() < 0.01: direction = Vector2.RIGHT
	if identity != null and identity.native_basic(id,closest,damage,reach):
		if identity.native_cast_succeeded:
			if evolution != null: evolution.on_native_basic(data,origin,closest,damage,reach)
			if identity.archetype == "rogue_combo" and bool(data.get("visual_effect_unique",false)):
				_effect(origin,closest.global_position,24.0,"combo",color,data)
			for extra in int(data.get("extra_projectiles",0)):
				_launch_projectile(closest,origin,damage,rank,color,data,float(extra+1)*0.06,false,reach)
			_after_cast(data,origin,direction,closest,damage,reach,rank)
		return
	if is_instance_valid(closest) or pattern == "summon" or pattern == "guard" or pattern == "heal": _pose(direction)
	if identity != null and (is_instance_valid(closest) or pattern in ["summon","guard","heal"] or not DELIVERY.RULES.spec(id,data).is_empty()): identity.on_cast(id)
	if native_skills != null and native_skills.cast(data,origin,direction,closest,damage,reach,hits+int(data.get("extra_projectiles",0)),rank,projectile_speed,awakened):
		if pattern == "summon" and native_skills.last_cast_succeeded:
			_effect(origin,origin,minf(reach,90.0),"summon",color,data)
		if is_instance_valid(closest) or pattern == "summon": _after_cast(data,origin,direction,closest,damage,reach,rank)
		hero._damage_treasure_chests(origin,minf(reach,220.0),damage)
		return
	if is_instance_valid(closest) or pattern in ["guard","heal"]: _after_cast(data,origin,direction,closest,damage,reach,rank)
	if bool(data.get("cleanse",false)):
		hero.poison_timer = 0.0; hero.poison_tick_timer = 0.0; hero.poison_damage_remaining = 0; hero.poison_ticks_remaining = 0; hero.poison_source = null
		hero.damage_poison_tracker.clear(); hero.burn_runtime.clear(); hero.slow_timer = 0.0; hero.move_multiplier = 1.0
		hero.set_meta("poison_active",false); hero.set_meta("burn_active",false); hero._set_poison_flash(false)
	if is_instance_valid(closest) and float(data.get("hp_cost",0.0)) > 0.0:
		hero.current_hp = maxi(1,hero.current_hp-maxi(1,roundi(hero.current_hp*float(data.hp_cost))))
		hero.health_changed.emit(hero.current_hp,hero.max_hp)
	if delivery != null and delivery.cast(id,data,origin,damage,reach,rank,closest):
		if pattern == "burst":
			if identity != null and identity.uses_ammo(id): identity.consume_ammo(1)
			elif int(data.get("magazine",0)) > 0: magazines[id] = maxi(0,int(magazines[id])-1)
		return
	if pattern in ["combo","burst"]:
		if not is_instance_valid(closest): return
		var shots := mini(hits,6)
		if identity != null and identity.archetype == "pistol_gunner" and pattern == "burst": shots = identity.consume_ammo(shots)
		elif int(data.get("magazine",0)) > 0:
			shots = mini(shots,int(magazines[id])); magazines[id] = int(magazines[id])-shots
		if shots > 0 and pattern == "burst": shots += int(data.get("extra_projectiles",0))
		for index in shots: _launch_projectile(closest,origin,damage,rank,color,data,index*float(data.get("hit_interval",0.14)),pattern == "combo",reach,index == shots-1)
		hero._damage_treasure_chests(origin,minf(reach,220.0),damage)
		hero.attack_pose_timer = 0.25
		return
	if pattern == "poison":
		# Replace only this weapon's old zones rather than stacking infinite recasts.
		for old_field in fields:
			if String(old_field.data.get("weapon_id","")) == id: old_field.left = 0.0
		for index in mini(3,int(data.get("field_count",1))):
			var field := _free_field()
			if field.is_empty(): break
			field.origin = closest.global_position if is_instance_valid(closest) else origin
			field.left = float(data.get("field_duration",3.0)); field.tick = 0.0; field.interval = float(data.get("field_interval",0.5)); field.radius = reach*float(data.get("field_radius_ratio",0.45)); field.damage = maxi(1,roundi(damage*1.6*float(field.interval)/(float(field.left)*maxi(1,int(data.get("field_count",1))))))
			# Secondary circles cover flanks, each with its own visible/actual footprint.
			if index > 0: field.origin += direction.orthogonal()*float(field.radius)*1.25*(1.0 if index == 1 else -1.0)
			field.follow = bool(data.get("field_follow",false)); field.data = data; field.rank = rank
			if bool(field.follow): field.origin = origin
			field["frames"] = ART.cache.get(String(data.get("effect_dir","")),EMPTY_ART)
			field["color"] = color
		hero.queue_redraw()
		hero._damage_treasure_chests(origin,minf(reach,220.0),damage)
		return
	if pattern == "heal": hero.heal_direct(roundi(hero.max_hp*(float(data.get("heal_ratio",0.015))+rank*0.002)))
	if pattern == "guard":
		var shield: float = shield_amount(hero.max_hp*(float(data.get("shield_ratio",0.04))+rank*0.006))
		# Replace only this runtime's grant; preserve other shield sources.
		hero.shield_hp = maxf(0.0,hero.shield_hp-owned_shield)+shield; owned_shield = shield; shield_left = float(data.get("shield_duration",3.0))
		if identity != null: hero.shield_max_hp = maxf(hero.shield_max_hp,hero.shield_hp)
	if pattern == "beam" and int(data.get("fan_lines",1)) > 1:
		_cast_fan(data,origin,direction,reach,rank,damage)
		hero._damage_treasure_chests(origin,minf(reach,220.0),damage)
		return
	var struck := 0
	if pattern in ["bolt","chain"] and is_instance_valid(closest):
		if pattern == "bolt": _launch_projectile(closest,origin,damage,rank,color,data,0.0,false,reach)
		else:
			_hit(closest,damage,pattern,rank,data)
			_effect(origin,closest.global_position,22.0,pattern,color,data)
		struck = 1
	for raw in scratch:
		# Shot/chain counts limit targeted attacks, never a visible damage area.
		if pattern in ["bolt","chain"] and struck >= hits: break
		var actor := raw as Node2D
		if not TARGETS.is_detectable(actor): continue
		if actor == closest and pattern in ["bolt","chain"]: continue
		if pattern == "chain" and is_instance_valid(closest) and actor.global_position.distance_squared_to(closest.global_position) > pow(float(data.get("chain_radius",200.0)),2): continue
		var offset: Vector2 = actor.global_position-origin
		if not GEOMETRY.contains(pattern,offset,direction,reach,rank,data): continue
		if pattern == "bolt": _launch_projectile(actor,origin,damage,rank,color,data,0.0,false,reach)
		else: _hit(actor,roundi(damage*(1.0+minf(0.5,struck*float(data.get("chain_growth",0.0))))) if pattern == "chain" else damage,pattern,rank,data)
		struck += 1
		if pattern == "chain": _effect(closest.global_position if is_instance_valid(closest) else origin,actor.global_position,20.0,pattern,color,data)
	if pattern == "bolt" and is_instance_valid(closest):
		for remaining in maxi(0,hits-struck):
			_launch_projectile(closest,origin,damage,rank,color,data,float(remaining+1)*0.08,false,reach)
		for extra in int(data.get("extra_projectiles",0)):
			_launch_projectile(closest,origin,damage,rank,color,data,float(extra+1)*0.08,false,reach)
	if pattern == "beam": _effect(origin,origin+direction*reach,GEOMETRY.beam_half_width(rank)*float(data.get("area_scale",1.0)),pattern,color,data)
	elif pattern not in ["bolt","chain"]: _effect(origin,origin+direction*reach,reach,pattern,color,data)
	hero._damage_treasure_chests(origin,minf(reach,220.0),damage)

func _free_field() -> Dictionary:
	for offset in fields.size():
		var index := (field_cursor+offset)%fields.size()
		if float(fields[index].left) <= 0.0:
			field_cursor = (index+1)%fields.size()
			return fields[index]
	return {} # Saturation never overwrites a still-visible damage circle.

func _after_cast(data: Dictionary, origin: Vector2, direction: Vector2, target: Node2D, damage: int, reach: float, rank: int) -> void:
	if evolution != null:
		evolution.on_cast(data,origin,direction,target,damage,reach)
		evolution.awakening_cast(data,origin,direction,target,damage,reach)
	if kit != null: kit.after_cast(data,origin,direction,target,damage,reach)
	if float(data.get("cast_heal",0.0)) > 0.0: hero.heal_direct(roundi(hero.max_hp*float(data.cast_heal)))
	if float(data.get("cast_shield",0.0)) > 0.0:
		var grant: float = hero.max_hp*float(data.cast_shield)
		hero.shield_hp = maxf(0.0,hero.shield_hp-owned_shield)+grant
		owned_shield = grant; shield_left = 3.0
		if identity != null: hero.shield_max_hp = maxf(hero.shield_max_hp,hero.shield_hp)
	var count := 0 if not DELIVERY.RULES.spec(String(data.get("weapon_id","")),data).is_empty() else mini(1,int(data.get("pulse_count",0)))
	var center: Vector2 = target.global_position if bool(data.get("pulse_target",false)) and is_instance_valid(target) else origin
	var scheduled := 0
	for pulse in pulses:
		if scheduled >= count: break
		if bool(pulse.active): continue
		pulse.active = true; scheduled += 1
		pulse.left = scheduled*float(data.get("pulse_interval",0.24)); pulse.origin = center; pulse.direction = direction
		pulse.radius = reach*float(data.get("pulse_radius_ratio",0.6)); pulse.damage = maxi(1,roundi(damage*float(data.get("pulse_ratio",0.4))))
		pulse.rank = rank; pulse.data = data

func _tick_pulses(delta: float) -> void:
	for pulse in pulses:
		if not bool(pulse.active): continue
		pulse.left = float(pulse.left)-delta
		if float(pulse.left) > 0.0: continue
		pulse.active = false
		if hero.current_hp <= 0: continue
		var data: Dictionary = pulse.data
		var pattern := String(data.get("pulse_pattern","nova"))
		hero._fill_monster_nodes_near(pulse.origin,float(pulse.radius),pulse_scratch)
		for raw in pulse_scratch:
			var actor := raw as Node2D
			if not TARGETS.is_detectable(actor) or not GEOMETRY.contains(pattern,actor.global_position-Vector2(pulse.origin),pulse.direction,float(pulse.radius),int(pulse.rank),data): continue
			_hit(actor,int(pulse.damage),pattern,int(pulse.rank),data.get("evolution_secondary_data",data))
		_effect(pulse.origin,Vector2(pulse.origin)+Vector2(pulse.direction)*float(pulse.radius),GEOMETRY.beam_half_width(int(pulse.rank))*float(data.get("area_scale",1.0)) if pattern == "beam" else float(pulse.radius),pattern,Color(String(data.color)),data)

func _cast_fan(data: Dictionary, origin: Vector2, direction: Vector2, reach: float, rank: int, damage: int) -> void:
	var lines := mini(5,int(data.fan_lines))
	for index in lines:
		var aim := direction.rotated((index-(lines-1)*0.5)*0.32)
		_effect(origin,origin+aim*reach,GEOMETRY.beam_half_width(rank)*float(data.get("area_scale",1.0)),"beam",Color(String(data.color)),data)
	for raw in scratch:
		var actor := raw as Node2D
		if not TARGETS.is_detectable(actor): continue
		for index in lines:
			var aim := direction.rotated((index-(lines-1)*0.5)*0.32)
			if not GEOMETRY.contains("beam",actor.global_position-origin,aim,reach,rank,data): continue
			_hit(actor,damage,"beam",rank,data)
			break # Overlapping rays never multiply damage on one actor.

func _finish_shot(shot: Dictionary, actor: Node2D) -> void:
	var data: Dictionary = shot.data
	if not bool(shot.get("finisher",false)) or float(data.get("finish_ratio",0.0)) <= 0.0 or not is_instance_valid(actor): return
	_splash(actor.global_position,maxi(1,roundi(int(shot.damage)*float(data.finish_ratio))),float(data.finish_radius),null,data)

func _splash(center: Vector2, damage: int, radius: float, excluded: Node2D, data: Dictionary) -> void:
	hero._fill_monster_nodes_near(center,radius,splash_scratch)
	for raw in splash_scratch:
		var actor := raw as Node2D
		if actor == excluded or not TARGETS.is_detectable(actor) or actor.global_position.distance_squared_to(center) > radius*radius: continue
		# A splash cannot recursively create another splash.
		_hit(actor,damage,"nova",int(data.get("growth_rank",1)),data.get("evolution_secondary_data",data))
	_effect(center,center,radius,"nova",Color(String(data.color)),data)

func _pose(direction: Vector2) -> void:
	hero.attack_pose_timer = 0.25
	if is_instance_valid(hero.hero_sprite) and hero.hero_sprite.sprite_frames.has_animation(&"attack"): hero.hero_sprite.play(&"attack")
	if direction.x != 0.0: hero._face_attack_direction(direction.x)

# Generation handles prevent a recycled monster instance from receiving an old shot.
func _launch_projectile(actor: Node2D, origin: Vector2, damage: int, rank: int, color: Color, data: Dictionary = {}, delay: float = 0.0, melee: bool = false, reach: float = 0.0, finisher: bool = false) -> int:
	if not is_instance_valid(authority) or not authority.has_method("get_battle_entity_handle"): return -1
	var handle: Vector3i = authority.call("get_battle_entity_handle",actor)
	if handle == Vector3i.ZERO: return -1
	for offset in range(PROJECTILE_LIMIT):
		var index := (projectile_cursor+offset)%PROJECTILE_LIMIT
		var shot: Dictionary = projectiles[index]
		if bool(shot.active): continue
		projectile_cursor = (index+1)%PROJECTILE_LIMIT
		shot.active = true; shot.handle = handle; shot.position = origin
		shot.damage = damage; shot.rank = rank; shot.color = color; shot.age = 0.0
		shot.data = data; shot.delay = delay; shot.melee = melee; shot.reach = reach if reach > 0 else float(data.get("range",900.0)); shot.traveled = 0.0
		shot["finisher"] = finisher
		shot["visual_radius"] = DATA.projectile_visual_radius(data)*float(data.get("awakening_visual_scale",1.0))
		shot["frames"] = ART.cache.get(String(data.get("effect_dir","")),EMPTY_ART)
		shot["direction"] = origin.direction_to(actor.global_position)
		shot.serial = index
		flight.configure(shot)
		hero.queue_redraw()
		return index

	return -1

func launch_summon_extras(id: String, target: Node2D, origin: Vector2, damage: int, reach: float) -> void:
	if not levels.has(id) or not is_instance_valid(target): return
	var data := stats_for(id)
	for extra in mini(2,projectile_bonus):
		_launch_projectile(target,origin,damage,int(levels[id]),Color(String(data.color)),data,float(extra+1)*0.08,false,reach)

func _tick_projectiles(delta: float) -> void:
	var redraw := false
	for shot in projectiles:
		if not bool(shot.active): continue
		shot.delay = maxf(0.0,float(shot.delay)-delta)
		if float(shot.delay) > 0.0: continue
		redraw = true; shot.age = float(shot.age)+delta
		if float(shot.age)>3.0: shot.active=false;continue
		if flight.handles(shot):
			flight.tick(shot,delta);continue
		var actor: Node2D = authority.call("resolve_battle_entity",shot.handle) as Node2D if is_instance_valid(authority) else null
		if not TARGETS.is_detectable(actor) or float(shot.age) > 3.0:
			shot.active = false; continue
		if bool(shot.melee):
			shot.active = false
			if hero.global_position.distance_squared_to(actor.global_position) <= pow(float(shot.reach),2) and hero.silence_timer <= 0.0:
				_effect(hero.global_position,actor.global_position,24.0,"combo",shot.color,shot.data)
				_hit(actor,int(shot.damage),"slash",int(shot.rank),shot.data)
				_finish_shot(shot,actor)
			continue
		var remaining := maxf(0.0,float(shot.reach)-float(shot.traveled))
		var step := minf(MODE.PROJECTILE_SPEED*projectile_speed*delta,remaining)
		var position: Vector2 = shot.position
		shot["direction"] = position.direction_to(actor.global_position)
		if String(shot.flight)=="curve":
			shot.direction = Vector2(shot.direction).rotated(sin(float(shot.age)*6.0)*.35)
			shot.position = position+Vector2(shot.direction)*step
		else: shot.position = position.move_toward(actor.global_position,step)
		shot.traveled = float(shot.traveled)+position.distance_to(shot.position)
		if position.distance_to(actor.global_position) <= step+GEOMETRY.PROJECTILE_RADIUS*float(shot.data.get("awakening_visual_scale",1.0)):
			shot.active = false
			_hit(actor,int(shot.damage),"bolt",int(shot.rank),shot.data)
			_finish_shot(shot,actor)
		elif float(shot.traveled) >= float(shot.reach): shot.active = false
	if redraw: hero.queue_redraw()

func on_shield_absorbed(amount: float) -> void:
	if evolution != null: evolution.on_shield_absorbed(amount)

func absorb_damage(amount: int) -> void:
	if passive_siphon <= 0.0 or amount <= 0 or hero.current_hp <= 0: return
	if hero.current_hp >= hero.max_hp: siphon_bank = 0.0; return
	siphon_bank += amount*passive_siphon
	var recovered := floori(siphon_bank)
	if recovered > 0: hero.heal_direct(recovered); siphon_bank -= recovered

func _hit(actor: Node2D, damage: int, pattern: String, rank: int, data: Dictionary = {}) -> void:
	var point := actor.global_position
	var max_primary := data.has("max_mechanic") and not bool(data.get("evolution_secondary",false))
	var handle: Vector3i = authority.get_battle_entity_handle(actor) if max_primary and String(data.max_mechanic.mechanic) == "mark" and is_instance_valid(authority) and authority.has_method("get_battle_entity_handle") else Vector3i.ZERO
	var reaction: float = kit.factor(actor,data) if kit != null else 1.0
	damage = maxi(1,roundi(damage*reaction))
	var before := int(actor.get("current_hp"))
	if before > 0 and float(data.get("execute_ratio",0.0)) > 0.0 and before <= float(actor.get("max_hp"))*float(data.execute_ratio): damage = maxi(damage,before)
	HIT.hit(actor,damage,String(data.get("attack_kind","melee" if pattern == "slash" else "ranged")),hero)
	if identity != null and identity.archetype == "alchemist_chemical" and pattern == "field": identity.impact()
	var lost := maxi(0,before-int(actor.get("current_hp"))) if is_instance_valid(actor) else 0
	if lost > 0 and kit != null:
		kit.landed(actor,data,reaction > 1.0)
		if reaction > 1.0: _effect(point,point,55.0,"nova",Color(String(data.get("color","ffffff"))),data)
	if max_primary and evolution != null: evolution.on_hit(actor,handle,point,lost,not is_instance_valid(actor) or int(actor.get("current_hp")) <= 0,data,damage)
	if lost > 0 and float(data.get("lifesteal",0.0)) > 0.0: hero.heal_direct(roundi(lost*float(data.lifesteal)))
	if lost > 0 and pattern == "bolt" and float(data.get("splash_ratio",0.0)) > 0.0 and is_instance_valid(actor):
		_splash(actor.global_position,roundi(damage*float(data.splash_ratio)),float(data.splash_radius),actor,data)
	if not TARGETS.is_detectable(actor): return
	if lost > 0 and (pattern == "frost" or data.has("slow_multiplier")):
		AFFLICTIONS.apply_slow(actor,float(data.get("slow_multiplier",maxf(0.35,0.85-rank*0.04))),float(data.get("slow_duration",2.0)))
	# Poison uses frequent damage pulses; it does not reuse hero-target poison APIs.

func _effect(a: Vector2,b: Vector2,radius: float,pattern: String,color: Color,data: Dictionary = {}) -> void:
	var effect: Dictionary = effects[effect_cursor]
	effect_cursor = (effect_cursor+1)%EFFECT_LIMIT
	effect.a = a; effect.b = b; effect.radius = radius; effect.pattern = pattern; effect.color = color
	effect["frames"] = ART.cache.get(String(data.get("effect_dir","")),EMPTY_ART)
	effect["follow"] = bool(data.get("field_follow",false))
	effect["area_scale"] = float(data.get("area_scale",1.0))
	effect.orbit_count = int(data.get("orbit_count",4)); effect.orbit_speed = float(data.get("orbit_speed",3.0)); effect.orbit_ratio = float(data.get("orbit_ratio",0.7))
	effect["shape"] = GEOMETRY.sector(radius) if pattern == "slash" else GEOMETRY.beam(a.distance_to(b),radius) if pattern == "beam" else GEOMETRY.capsule(a.distance_to(b),radius) if pattern == "capsule" else PackedVector2Array()
	effect.duration = 0.28
	effect.left = effect.duration; hero.queue_redraw()

func draw() -> void:
	if awakening_flash>0.0:
		var progress:float=1.0-awakening_flash/1.6
		hero.draw_arc(Vector2.ZERO,45.0+progress*260,0,TAU,48,Color(1.0,.8,.3,(1.0-progress)*.8),5.0)
	if evolution != null: evolution.draw()
	if delivery != null: delivery.draw()
	for field in fields:
		if float(field.left) > 0.0:
			_draw_area(hero.to_local(field.origin),float(field.radius),field.get("color",Color.WHITE),field.get("frames",EMPTY_ART),_loop_progress(field.get("frames",EMPTY_ART),visual_clock))
	for shot in projectiles:
		if bool(shot.active) and not bool(shot.melee) and float(shot.delay) <= 0.0:
			var position: Vector2 = hero.to_local(shot.position)
			var frames: Array = shot.get("frames",EMPTY_ART)
			var visual_radius := float(shot.get("visual_radius",28.0))
			if not frames.is_empty():
				hero.draw_set_transform(position,Vector2(shot.direction).angle())
				hero.draw_texture_rect(_loop_frame(frames,float(shot.age)),Rect2(Vector2.ONE*-visual_radius,Vector2.ONE*visual_radius*2.0),false)
				hero.draw_set_transform(Vector2.ZERO)
			else:
				hero.draw_circle(position,visual_radius,shot.color)
				hero.draw_circle(position,7.0,Color.WHITE)
	for effect in effects:
		if float(effect.left) <= 0.0: continue
		var ratio: float = float(effect.left)/float(effect.duration)
		var a: Vector2 = hero.to_local(effect.a)
		if bool(effect.get("follow",false)): a = Vector2.ZERO
		var b: Vector2 = hero.to_local(effect.b)
		var color: Color = effect.color; color.a = ratio*GEOMETRY.EFFECT_ALPHA
		var radius: float = effect.radius
		var frames: Array = effect.get("frames",EMPTY_ART)
		match String(effect.pattern):
			"beam","slash","capsule":
				hero.draw_set_transform(a,(b-a).angle())
				hero.draw_colored_polygon(effect.shape,Color(color,ratio*GEOMETRY.SHAPE_FILL_ALPHA))
				hero.draw_polyline(effect.shape,color,GEOMETRY.OUTLINE_WIDTH)
				if not frames.is_empty():
					var texture: Texture2D = frames[mini(int((1-ratio)*frames.size()),frames.size()-1)]
					var length := a.distance_to(b)
					var rect := GEOMETRY.effect_texture_rect(String(effect.pattern),length,radius)
					hero.draw_texture_rect(texture,rect,false,Color(1,1,1,ratio*GEOMETRY.BEAM_TEXTURE_ALPHA))
				hero.draw_set_transform(Vector2.ZERO)
			"combo":
				if not frames.is_empty():
					hero.draw_set_transform(b,(b-a).angle())
					hero.draw_texture_rect(_frame(frames,1.0-ratio),Rect2(Vector2.ONE*-radius,Vector2.ONE*radius*2),false,Color(1,1,1,ratio))
					hero.draw_set_transform(Vector2.ZERO)
				else: hero.draw_line(a,b,color,GEOMETRY.OUTLINE_WIDTH)
			"chain":
				hero.draw_line(a,b,Color(color,ratio*GEOMETRY.CHAIN_LINE_ALPHA),GEOMETRY.OUTLINE_WIDTH)
				if not frames.is_empty():
					hero.draw_set_transform(a,(b-a).angle())
					hero.draw_texture_rect(_frame(frames,1.0-ratio),Rect2(Vector2(0,-GEOMETRY.CHAIN_DRAW_WIDTH*0.5),Vector2(a.distance_to(b),GEOMETRY.CHAIN_DRAW_WIDTH)),false,Color(1,1,1,ratio))
					hero.draw_set_transform(Vector2.ZERO)
				else: hero.draw_line(a,b,color,GEOMETRY.CHAIN_FALLBACK_WIDTH)
			"bolt":
				hero.draw_line(a,b,Color(color,ratio*GEOMETRY.BOLT_LINE_ALPHA),GEOMETRY.OUTLINE_WIDTH)
				hero.draw_circle(a.lerp(b,1.0-ratio),GEOMETRY.BOLT_RADIUS,color)
			"orbit":
				var inner := GEOMETRY.orbit_inner(radius,float(effect.orbit_ratio),float(effect.get("area_scale",1.0)))
				var outer := GEOMETRY.orbit_outer(radius,float(effect.orbit_ratio),float(effect.get("area_scale",1.0)))
				hero.draw_arc(a,(inner+outer)*0.5,0,TAU,48,Color(color,ratio*GEOMETRY.ORBIT_FILL_ALPHA),outer-inner)
				hero.draw_arc(a,inner,0,TAU,48,color,GEOMETRY.OUTLINE_WIDTH); hero.draw_arc(a,outer,0,TAU,48,color,GEOMETRY.OUTLINE_WIDTH)
				for index in int(effect.orbit_count):
					var angle := visual_clock*float(effect.orbit_speed)+index*TAU/float(effect.orbit_count)
					var position := a+Vector2.from_angle(angle)*(inner+outer)*0.5
					var extent := GEOMETRY.orbit_texture_extent(inner,outer)
					if not frames.is_empty():
						hero.draw_set_transform(position,angle+PI*0.5)
						hero.draw_texture_rect(_loop_frame(frames,visual_clock),Rect2(Vector2.ONE*-extent,Vector2.ONE*extent*2),false,Color(1,1,1,ratio))
						hero.draw_set_transform(Vector2.ZERO)
					else: hero.draw_circle(position,extent,color)
			_:
				_draw_area(a,radius,Color(color,ratio),frames,1.0-ratio)

func _loop_index(frames: Array, time: float) -> int:
	if frames.size() <= 1: return 0
	var cycle := frames.size()*2-2
	var index := posmod(floori(time*12.0),cycle)
	return index if index < frames.size() else cycle-index

func _loop_progress(frames: Array, time: float) -> float:
	return float(_loop_index(frames,time))/maxi(1,frames.size())

func _loop_frame(frames: Array, time: float) -> Texture2D:
	return frames[_loop_index(frames,time)] as Texture2D

func _frame(frames: Array, progress: float) -> Texture2D:
	return frames[clampi(int(progress*frames.size()),0,frames.size()-1)] as Texture2D

func _draw_area(center: Vector2, radius: float, color: Color, frames: Array, progress: float) -> void:
	if not frames.is_empty():
		var texture: Texture2D = frames[mini(int(progress*frames.size()),frames.size()-1)]
		var diameter := radius*sqrt(2.0)
		hero.draw_texture_rect(texture,Rect2(center-Vector2.ONE*diameter*0.5,Vector2.ONE*diameter),false,Color(1,1,1,color.a*GEOMETRY.AREA_TEXTURE_ALPHA))
	hero.draw_circle(center,radius,Color(color,color.a*GEOMETRY.AREA_FILL_ALPHA))
	hero.draw_arc(center,radius,0.0,TAU,48,color,GEOMETRY.OUTLINE_WIDTH)

func shield_amount(amount: float) -> float:
	return amount*(1.0+float(research.get("shield",0)))
