extends SceneTree
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const IDENTITY := preload("res://src/hero_mode/hero_survival_identity_runtime.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
var checks := 0
var failures := 0
class Target extends Node2D:
	var current_hp := 100000
	var max_hp := 100000
	var slow_multiplier := 1.0
	func take_damage(amount: int) -> void: current_hp -= amount
	func apply_slow(value: float, _seconds: float) -> void: slow_multiplier = value
class Arena extends Node2D:
	var targets: Array = []
	func get_battle_entity_handle(actor: Node) -> Vector3i: return Vector3i(targets.find(actor)+1,1,1)
	func resolve_battle_entity(handle: Vector3i) -> Node:
		return targets[handle.x-1] if handle.x > 0 and handle.x <= targets.size() else null
class Hero extends Node2D:
	signal health_changed(current: int, maximum: int)
	var hero_id := "ranged_rookie"
	var build_counts: Dictionary = {}
	var max_hp := 1000
	var current_hp := 500
	var attack_damage := 26
	var move_speed := 270.0
	var exp_pickup_radius := 150.0
	var exp_gain_multiplier := 1.0
	var shield_hp := 0.0
	var shield_max_hp := 0.0
	var player_move_input := Vector2.RIGHT
	var attack_pose_timer := 0.0
	var hero_sprite: AnimatedSprite2D
	var silence_timer := 0.0
	var petrify_timer := 0.0
	var imposed_skill_cooldown := 0.0
	var poison_timer := 0.0
	var poison_tick_timer := 0.0
	var poison_damage_remaining := 0
	var poison_ticks_remaining := 0
	var poison_source: Node
	var slow_timer := 0.0
	var move_multiplier := 1.0
	var damage_poison_tracker := RefCounted.new()
	var burn_runtime := RefCounted.new()
	var gunner_ammo := 12
	var gunner_reloading := false
	var gunner_magazine_size := 12
	var gunner_config := {"quickdraw_chance":0.0,"headshot_chance":0.0}
	var alchemist_gas := 50.0
	var alchemist_transformed := false
	func _fill_monster_nodes_near(_point: Vector2, _radius: float, result: Array) -> void:
		result.clear(); result.append_array(get_parent().targets)
	func _face_attack_direction(_value: float) -> void: pass
	func _damage_treasure_chests(_point: Vector2, _radius: float, _damage: int) -> void: pass
	func _gunner_register_ammo_consumed(_amount: int) -> void: pass
	func _refresh_gunner_empty_magazine_shield() -> void: pass
	func _start_gunner_reload() -> void: gunner_reloading = true
	func _consume_alchemist_gas(amount: float) -> void: alchemist_gas -= amount
	func _set_poison_flash(_value: bool) -> void: pass
	func heal_direct(value: int) -> void: current_hp = mini(max_hp,current_hp+value)
	func get_paralysis_attack_multiplier() -> float: return 1.0
class Clearable extends RefCounted:
	func clear() -> void: pass
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("WEAPON_EXTENSION: "+message)
func run() -> void:
	check(DATA.WEAPONS.size() == 100 and DATA.GROWTH.PROFILES.size() == 100,"100 weapon and growth entries")
	check(DATA.WEAPON_SLOTS == 6 and DATA.PASSIVE_SLOTS == 6,"equipment limits preserved")
	var ids: Dictionary = {}; var names: Dictionary = {}; var extra_count := 0
	for owner in DATA.HERO_WEAPONS:
		var pool: Array = DATA.weapon_pool(owner)
		check(pool.size() == 10 and DATA.STARTERS[owner] in pool,"ten weapons and original starter "+owner)
		for id in pool:
			var data: Dictionary = DATA.WEAPONS[id]
			check(data.owner == owner and not ids.has(id),"unique owner "+id); ids[id] = true
			check(not names.has(owner+":"+data.name),"unique name "+id); names[owner+":"+data.name] = true
			check(ICONS.texture(id) != null and ICONS.texture(id).region.has_area(),"valid retained icon "+id)
			for rank in range(1,11):
				var text: String = DATA.description(id,rank)
				check(not text.is_empty() and not text.contains("진화") and not text.contains("다음") and not text.contains("Lv."),"current selection only "+id+str(rank))
			var evolved := DATA.GROWTH.resolve(id,data,10,true)
			check(evolved.damage_scale > 2.62 and evolved.cooldown_scale < 0.685,"chest evolution preserved "+id)
			if not data.has("icon_index_v2"): continue
			extra_count += 1
			check(int(data.icon_index_v2) in range(40) and ICONS.texture(id).atlas == ICONS.UNIQUE_WEAPONS,"new icon uses own generated atlas cell "+id)
			var arena := Arena.new(); root.add_child(arena)
			var hero := Hero.new(); hero.hero_id = owner; hero.damage_poison_tracker = Clearable.new(); hero.burn_runtime = Clearable.new(); arena.add_child(hero)
			for index in 3:
				var target := Target.new(); target.position = Vector2(140+index*20,index*10); arena.add_child(target); arena.targets.append(target)
			var runtime := RUNTIME.new(); runtime.install(hero)
			check(id in runtime.available_weapons and runtime.add(id),"new weapon selectable and equipable "+id)
			var foreign := "swift_hunter_dagger" if owner == "ranged_rookie" else "ranged_rookie_arcane_bolt"
			check(not runtime.add(foreign),"foreign kit rejected "+id)
			var card := runtime._card(id,2)
			check(card.description == DATA.description(id,2),"actual candidate uses immediate summary "+id)
			for rank in [1,3,6,10]:
				for awakened in [false,true] if rank == 10 else [false]:
					runtime.levels.clear(); runtime.weapon_ids.clear(); runtime.cooldowns.clear(); runtime.resolved.clear(); runtime.evolved.clear()
					runtime.levels[id] = rank; runtime.weapon_ids.append(id); runtime.cooldowns[id] = 1000
					if awakened: runtime.evolved[id] = true
					for field in runtime.fields: field.left = 0
					for shot in runtime.projectiles: shot.active = false
					for pulse in runtime.pulses: pulse.active = false
					var stats := runtime.stats_for(id)
					var reach := float(stats.range)*float(stats.reach_scale)
					var distance := minf(140.0,reach*0.5)
					if data.pattern == "orbit": distance = reach*float(stats.get("orbit_ratio",0.7))
					elif data.pattern == "poison" and stats.get("field_follow",false): distance = reach*float(stats.get("field_radius_ratio",0.45))*0.6
					for index in arena.targets.size():
						var target = arena.targets[index]; target.current_hp = target.max_hp
						target.position = Vector2(distance+index*5,index*3)
					hero.current_hp = 500; hero.shield_hp = 0
					runtime._cast(id)
					if data.pattern == "guard": check(hero.shield_hp > 0,"new protection really granted "+id)
					if data.pattern == "heal": check(hero.current_hp > 500,"new recovery really applied "+id)
					for step in 20: runtime.tick(0.1)
					check(arena.targets[0].current_hp < arena.targets[0].max_hp,"new weapon actually damages "+id+str(rank)+str(awakened))
					check(runtime.projectiles.size() == 64 and runtime.fields.size() == 8 and runtime.pulses.size() == 24,"fixed pools "+id)
				arena.queue_free()
			await process_frame
	check(not DATA.description("sword_shield_hero_longsword",3).contains("대상"),"area target-count label omitted because all eligible targets already hit")
	check(extra_count == 40,"exactly four additions per hero")
	for id in DATA.PASSIVES:
		for rank in range(1,11): check(not DATA.description(id,rank).contains("레벨"),"passive describes immediate bonus")
	var gunner := Hero.new(); root.add_child(gunner)
	var identity := IDENTITY.new(); identity.hero = gunner; identity.archetype = "pistol_gunner"; identity.spec = identity.CATALOG.ARCHETYPES.pistol_gunner
	for id in DATA.weapon_pool("pistol_hero").slice(6):
		if not DATA.WEAPONS[id].get("uses_ammo",false): continue
		check(identity.uses_ammo(id),"new firearm shares ammo "+id)
		gunner.gunner_reloading = false
		gunner.gunner_ammo = 0; check(not identity.can_cast(id,DATA.WEAPONS[id].pattern),"empty clip blocks "+id)
		gunner.gunner_ammo = 1; check(identity.can_cast(id,DATA.WEAPONS[id].pattern),"loaded clip permits "+id)
		gunner.gunner_ammo = 4
		if DATA.WEAPONS[id].pattern == "burst":
			check(identity.consume_ammo(2) == 2 and gunner.gunner_ammo == 2,"burst consumes actual shared bullets "+id)
		else:
			identity.on_cast(id,false,false); check(gunner.gunner_ammo == 3,"firearm cast spends shared ammo "+id)
	identity.archetype = "alchemist_chemical"
	for id in DATA.weapon_pool("chemical_hero").slice(6):
		identity.gas_costs[id] = DATA.WEAPONS[id].gas_cost
		gunner.alchemist_gas = 0; check(not identity.can_cast(id,DATA.WEAPONS[id].pattern),"empty gas blocks "+id)
		gunner.alchemist_gas = 50; check(identity.can_cast(id,DATA.WEAPONS[id].pattern),"gas permits "+id)
		identity.on_cast(id,false,false)
		check(is_equal_approx(gunner.alchemist_gas,50-float(DATA.WEAPONS[id].gas_cost)),"new alchemy cast consumes gas "+id)
	gunner.queue_free(); await process_frame
	print("HERO_WEAPON_EXTENSION_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
