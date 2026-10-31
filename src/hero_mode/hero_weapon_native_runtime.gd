extends RefCounted
# Reuse shipped skill actors and their existing damage/status/audio paths.
const SCENES := {
	"piercer":[preload("res://src/hero/UltimatePiercingProjectile.tscn"),"ultimate_piercing_projectile",6],
	"ice_pillar":[preload("res://src/hero/SageIcePillar.tscn"),"sage_ice_pillar",3],
	"meteor":[preload("res://src/hero/SageStarlightMeteor.tscn"),"sage_starlight_meteor",8],
	"singularity":[preload("res://src/hero/SageAnnihilationPoint.tscn"),"sage_annihilation_point",2],
}
const SUMMONER := preload("res://src/hero/hero_summoner_runtime.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const FIT := preload("res://src/ui/hero_weapon_visual_fit.gd")
var hero
var last_cast_succeeded := false
var authority
var summon_configs: Dictionary = {}
var actors_by_pattern: Dictionary = {}
var visual_opacity := 1.0
var attack_range_visible := true

func set_visual_settings(opacity: float, show_ranges: bool) -> void:
	visual_opacity = clampf(opacity,0.0,1.0)
	attack_range_visible = show_ranges
	for pattern in actors_by_pattern:
		for actor in actors_by_pattern[pattern]:
			if not is_instance_valid(actor): continue
			_apply_actor_visual_settings(actor)

func _apply_actor_visual_settings(actor: CanvasItem) -> void:
	actor.modulate.a = visual_opacity
	actor.set_meta("hero_attack_range_visible",attack_range_visible)
	actor.queue_redraw()

const SUMMON_LIVE_FIELDS := ["attack_range","attack_cooldown","move_speed","sense_range","hits_per_attack","hit_interval","second_hit_bonus_ratio","high_hp_damage_bonus","elite_move_speed_bonus","projectile_speed","consecutive_damage_bonus_per_step","focus_damage_bonus","focus_attack_speed_bonus"]
const SUMMON_AREA_FIELDS := ["summon_area_radius","summon_area_ratio","summon_area_targets","summon_area_mode"]

func _prepare_summon(data: Dictionary, damage: int) -> Dictionary:
	var kind := String(data.summon_kind)
	var config: Dictionary = data.get("summon_config",summon_configs[kind])
	config["damage_ratio"] = float(damage)*WEAPONS.SUMMON_DAMAGE_RATIO/maxf(hero.attack_damage,1)
	config["duration"] = float(data.get("summon_duration",14.0))
	config["max_hp"] = roundi(hero.max_hp*float(data.get("summon_hp_ratio",WEAPONS.SUMMON_HP_RATIO)))
	for field in SUMMON_AREA_FIELDS:
		config[field] = data.get(field,0.0 if field != "summon_area_mode" else "")
	config.summon_area_radius = float(config.summon_area_radius)*float(data.get("area_scale",1.0))
	return config

func refresh_summons(data: Dictionary, damage: int) -> void:
	# Upgrade events only; bounded owned pools, no reactivation or entity-life reset.
	var kind := String(data.get("summon_kind",""))
	if not summon_configs.has(kind): return
	var config := _prepare_summon(data,damage)
	for actor in hero.get("summoner_"+kind+"_pool"):
		if not is_instance_valid(actor) or not actor.active or actor.dying or actor.is_queued_for_deletion() or actor.owner_hero != hero: continue
		if float(actor.duration_remaining) <= 0.0 or (actor.get("current_hp") != null and int(actor.current_hp) <= 0): continue
		var elapsed := maxf(0.0,float(actor.duration_total)-float(actor.duration_remaining))
		actor.duration_total = float(config.duration)
		actor.duration_remaining = maxf(0.0,float(config.duration)-elapsed)
		if actor.get("max_hp") != null:
			var health_ratio := float(actor.current_hp)/maxf(float(actor.max_hp),1.0)
			actor.max_hp = maxi(1,int(config.max_hp))
			actor.current_hp = maxi(1,roundi(actor.max_hp*health_ratio))
		actor.attack_damage = maxi(1,roundi(hero.attack_damage*float(config.damage_ratio)))
		if actor.get("owner_attack_damage") != null: actor.owner_attack_damage = hero.attack_damage
		actor.area_attack.configure(config)
		for field in SUMMON_LIVE_FIELDS:
			if config.has(field) and actor.get(field) != null: actor.set(field,config[field])
		actor.queue_redraw()
func install(host) -> void:
	hero = host; authority = hero.get_parent()
	if not hero.has_method("_acquire_projectile") or not is_instance_valid(authority) or not authority.has_method("recycle_projectile"): return
	var prepared: Dictionary = {}
	for id in WEAPONS.weapon_pool(String(hero.hero_id)):
		var pattern := String(WEAPONS.WEAPONS[id].pattern)
		if not SCENES.has(pattern) or prepared.has(pattern): continue
		prepared[pattern] = true
		var spec: Array = SCENES[pattern]
		var paths := PackedStringArray()
		if pattern == "piercer":
			for frame in range(1,7): paths.append("res://assets/art/heroes/stage1_mage/frames/effect_01/frame_%02d.png" % frame)
		elif pattern == "meteor":
			for frame in range(5,9): paths.append("res://assets/art/heroes/stage10_sage/frames/effect7/stage10_effect2_%02d.png" % frame)
		elif pattern == "singularity":
			for frame in range(1,9): paths.append("res://assets/art/heroes/stage10_sage/frames/effect8/stage10_effect3_%02d.png" % frame)
		var bounds := FIT.warm(paths) if not paths.is_empty() else Rect2()
		var actors: Array = []
		for index in int(spec[2]):
			var actor = hero._acquire_projectile(spec[0],spec[1])
			if not is_instance_valid(actor): continue
			actor.set_meta("survival_geometry",true); actor.set_meta("survival_visual_bounds",bounds)
			_apply_actor_visual_settings(actor)
			actors.append(actor)
		actors_by_pattern[pattern] = actors
		for actor in actors:
			if is_instance_valid(actor): authority.recycle_projectile(actor,spec[1])
	if String(hero.hero_archetype) == "summoner_gatekeeper":
		hero.summoner_slot_base = WEAPONS.SUMMON_LIMIT
		hero._ensure_summoner_runtime()
		for kind in ["hound","scout","watcher","gatekeeper"]:
			summon_configs[kind] = hero.get("summoner_"+kind+"_config").duplicate(true)
func summon_capacity() -> int:
	var kinds := 0
	for id in hero.player_weapons.weapon_ids:
		if String(WEAPONS.WEAPONS[id].pattern) == "summon": kinds += 1
	return SUMMONER.get_slot_capacity(maxi(int(hero.summoner_slot_base),kinds),int(hero.summoner_slot_bonus),int(hero.level))

func _active_kind(kind: String) -> int:
	return int(hero.get("summoner_active_"+kind+"s"))

func _reserve_summon_slot(kind: String) -> bool:
	var missing := 0
	for id in hero.player_weapons.weapon_ids:
		var data: Dictionary = WEAPONS.WEAPONS[id]
		if String(data.pattern) == "summon" and _active_kind(String(data.summon_kind)) == 0: missing += 1
	var total: int = hero._get_active_summon_count()
	var capacity := summon_capacity()
	if _active_kind(kind) > 0:
		return total < capacity-missing
	if total < capacity: return true
	# A newly learned species replaces one duplicate from an existing pool.
	# This is bounded by the four owned pools, only on a due summon cast.
	for other_kind in summon_configs:
		if _active_kind(other_kind) < 2: continue
		for actor in hero.get("summoner_"+String(other_kind)+"_pool"):
			if is_instance_valid(actor) and actor.active and actor.owner_hero == hero:
				actor.deactivate()
				return true
	return false

func cast(data: Dictionary, origin: Vector2, direction: Vector2, target: Node2D, damage: int, reach: float, hits: int, rank: int, speed: float, awakened: bool = false) -> bool:
	last_cast_succeeded = false
	var pattern := String(data.pattern)
	if pattern == "summon":
		if not hero.has_method("_get_active_summon_count"): return true
		var kind := String(data.summon_kind)
		if not summon_configs.has(kind): return true
		if not _reserve_summon_slot(kind): return true
		# Cached on upgrade. Actors snapshot scalars in setup; no per-cast deep copy.
		var config := _prepare_summon(data,damage)
		hero.set("summoner_"+kind+"_config",config)
		hero.set("summoner_"+kind+"_cooldown",0.0)
		last_cast_succeeded = bool(hero.call("_try_cast_summoner_"+kind))
		return true
	if not SCENES.has(pattern): return false
	if not is_instance_valid(authority) or not authority.has_method("recycle_projectile"): return true
	if not is_instance_valid(target): return true
	var spec: Array = SCENES[pattern]
	var count := mini(hits,int(spec[2]))
	var radius_scale := float(data.get("native_radius_scale",1.25 if awakened else 1.0))
	# Overlapping native copies share a cast budget rather than multiplying it.
	damage = maxi(1,roundi(damage/sqrt(float(maxi(1,count)))))
	for index in count:
		# Only use the startup pool. Saturation skips a cast rather than allocating.
		if not authority.projectile_pools.has(spec[1]) or authority.projectile_pools[spec[1]].is_empty(): break
		var actor = hero._acquire_projectile(spec[0],spec[1])
		if not is_instance_valid(actor): break
		actor.global_position = origin if pattern == "piercer" else target.global_position+direction.orthogonal()*float(index)*70.0
		match pattern:
			"piercer": actor.setup(direction.rotated((index-(count-1)*0.5)*0.08),damage,float(data.projectile_speed)*speed,reach)
			"ice_pillar": actor.setup(damage,float(data.field_duration),(float(data.native_radius)+rank*float(data.native_radius_per_level))*radius_scale,float(data.slow_multiplier),float(data.collision_radius),hero)
			"meteor": actor.setup(damage,(float(data.native_radius)+rank*float(data.native_radius_per_level))*radius_scale,float(data.fall_duration),float(data.visual_scale)*radius_scale,float(data.fall_height),float(data.fall_side_offset),float(data.explosion_fps),hero)
			"singularity": actor.setup(hero,float(data.field_duration),(float(data.native_radius)+rank*float(data.native_radius_per_level))*radius_scale,maxi(1,roundi(damage*float(data.field_power))),float(data.pull_interval),float(data.pull_step),float(data.field_interval),float(data.execute_ratio),float(data.visual_scale)*radius_scale,float(data.create_fps),float(data.active_fps),float(data.disappear_fps))
		_apply_actor_visual_settings(actor)
	if authority.is_combat_simulation_paused() and not (authority.has_method("uses_hero_subtree_pause") and authority.uses_hero_subtree_pause()): set_paused(true)
	return true
func set_paused(paused: bool) -> void:
	for pattern in actors_by_pattern:
		for actor in actors_by_pattern[pattern]:
			if not is_instance_valid(actor): continue
			var active: bool = bool(actor.active) if pattern == "ice_pillar" or pattern == "piercer" else int(actor.state) != 0
			if not active: continue
			if pattern == "ice_pillar":
				actor.set_process(not paused)
				if paused: actor.visual.pause()
				else: actor.visual.play()
			else: actor.set_physics_process(not paused)
