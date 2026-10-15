extends RefCounted
# Reuse shipped skill actors and their existing damage/status/audio paths.
const SCENES := {
	"piercer":[preload("res://src/hero/UltimatePiercingProjectile.tscn"),"ultimate_piercing_projectile",6],
	"ice_pillar":[preload("res://src/hero/SageIcePillar.tscn"),"sage_ice_pillar",3],
	"meteor":[preload("res://src/hero/SageStarlightMeteor.tscn"),"sage_starlight_meteor",8],
	"singularity":[preload("res://src/hero/SageAnnihilationPoint.tscn"),"sage_annihilation_point",2],
}
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const FIT := preload("res://src/ui/hero_weapon_visual_fit.gd")
var hero
var last_cast_succeeded := false
var authority
var summon_configs: Dictionary = {}
var actors_by_pattern: Dictionary = {}
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
			actors.append(actor)
		actors_by_pattern[pattern] = actors
		for actor in actors:
			if is_instance_valid(actor): authority.recycle_projectile(actor,spec[1])
	if String(hero.hero_archetype) == "summoner_gatekeeper":
		hero.summoner_slot_base = WEAPONS.SUMMON_LIMIT
		hero._ensure_summoner_runtime()
		for kind in ["hound","scout","watcher","gatekeeper"]:
			summon_configs[kind] = hero.get("summoner_"+kind+"_config").duplicate(true)
func cast(data: Dictionary, origin: Vector2, direction: Vector2, target: Node2D, damage: int, reach: float, hits: int, rank: int, speed: float, awakened: bool = false) -> bool:
	last_cast_succeeded = false
	var pattern := String(data.pattern)
	if pattern == "summon":
		if not hero.has_method("_get_active_summon_count"): return true
		if hero._get_active_summon_count() >= WEAPONS.SUMMON_LIMIT: return true
		var kind := String(data.summon_kind)
		if not summon_configs.has(kind): return true
		# Cached on upgrade. Actors snapshot scalars in setup; no per-cast deep copy.
		var config: Dictionary = data.get("summon_config",summon_configs[kind])
		config["damage_ratio"] = float(damage)*WEAPONS.SUMMON_DAMAGE_RATIO/maxf(hero.attack_damage,1)
		config["duration"] = float(data.get("summon_duration",14.0))
		config["max_hp"] = roundi(hero.max_hp*float(data.get("summon_hp_ratio",WEAPONS.SUMMON_HP_RATIO)))
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
	if authority.is_combat_simulation_paused(): set_paused(true)
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
