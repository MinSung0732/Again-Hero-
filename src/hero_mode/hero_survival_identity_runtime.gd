extends RefCounted
const CATALOG := preload("res://src/data/hero_survival_identity_catalog.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const FIT := preload("res://src/ui/hero_weapon_visual_fit.gd")
var hero
var weapon_ref: WeakRef
var weapons: RefCounted:
	get: return weapon_ref.get_ref() as RefCounted
var archetype := ""
var spec: Dictionary = {}
var charge_config: Dictionary = {}
var starter := ""
var audio: AudioStreamPlayer
var impact_audio: AudioStreamPlayer
var audio_call: Callable
var resource_redraw := 0.0
var signature_cursor := 0
var signature_pending := ""
var native_actors: Array = []
var native_pool_size := 0
var attack_serial := 0
var audio_serial := 0
var revive_left := 0.0
var impact_left := 0.0
var status_hp_y := -64.0
var status_resource_y := -79.0
var status_shield_y := -49.0
var gas_costs: Dictionary = {}
static var body_bounds_cache: Dictionary = {}
func install(host, runtime) -> void:
	hero = host; weapon_ref = weakref(runtime); archetype = String(hero.hero_archetype)
	spec = CATALOG.ARCHETYPES.get(archetype,{})
	starter = String(WEAPONS.STARTERS.get(hero.hero_id,""))
	if spec.has("config"): charge_config = hero.get(String(spec.config))
	if spec.has("ensure"): hero.call(String(spec.ensure))
	for id in spec.get("gas_costs",{}):
		var value = hero.alchemist_config
		for key in spec.gas_costs[id]: value = value.get(key,0)
		var period := float(hero.attack_cooldown)
		if id in spec.get("gas_periods",{}):
			var period_value = hero.alchemist_config
			for key in spec.gas_periods[id]: period_value = period_value.get(key,period)
			period = float(period_value)
		# Preserve original gas per second when native 24s skills become 2s
		# survival weapons, rather than multiplying their resource demand tenfold.
		gas_costs[id] = float(value)*float(WEAPONS.WEAPONS[id].cooldown)/maxf(period,0.1)
	for id in WEAPONS.weapon_pool(String(hero.hero_id)):
		if WEAPONS.WEAPONS[id].has("gas_cost"): gas_costs[id] = maxf(0.0,float(WEAPONS.WEAPONS[id].gas_cost))
	if spec.has("audio"): audio_call = Callable(hero,String(spec.audio))
	if spec.has("player"): audio = hero.get(String(spec.player)) as AudioStreamPlayer
	if spec.has("audio_path"):
		audio = hero._create_hero_sfx_player(String(spec.audio_path),-11.0)
		impact_audio = hero._create_hero_sfx_player(String(spec.impact_path),-9.0)
	if archetype == "pistol_gunner": _warm_fx("gunner_afterimage","sprite",4)
	if archetype == "archmage_elementalist":
		_warm_fx("archmage_basic_chain_line","line",8); _warm_fx("archmage_basic_impact_ring","line",8)
	var sprite: AnimatedSprite2D = hero.hero_sprite
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(&"idle"):
		var texture := sprite.sprite_frames.get_frame_texture(&"idle",0)
		if texture != null:
			var key := texture.get_instance_id()
			if not body_bounds_cache.has(key): body_bounds_cache[key] = texture.get_image().get_used_rect()
			var bounds: Rect2 = Rect2(body_bounds_cache[key])
			var origin := -texture.get_size()*0.5 if sprite.centered else Vector2.ZERO
			var top := sprite.position.y+(origin.y+sprite.offset.y+bounds.position.y)*sprite.scale.y
			status_shield_y = minf(-49,top-14)
			status_hp_y = status_shield_y-15; status_resource_y = status_hp_y-15
	# Native elemental/third-shot projectiles are retained at entry, never grown
	# when saturation occurs. Existing Hero helpers keep their sounds and effects.
	if spec.has("pools"):
		var scene: PackedScene = hero.ARCHMAGE_PROJECTILE_SCENE if archetype == "archmage_elementalist" else hero.SAGE_PROJECTILE_SCENE
		for key in spec.pools:
			var start := native_actors.size()
			var paths := PackedStringArray()
			if archetype == "archmage_elementalist": paths = PackedStringArray(preload("res://src/hero/archmage_projectile.gd").ORB_FRAME_PATHS)
			elif key == "sage_basic_projectile":
				for frame in range(4,8): paths.append("res://assets/art/heroes/stage10_sage/frames/effect2/projectile_%02d.png" % frame)
			else:
				for frame in range(1,6): paths.append("res://assets/art/heroes/stage10_sage/frames/effect5/crescent_%02d.png" % frame)
			var bounds := FIT.warm(paths)
			for index in 8:
				var actor = hero._acquire_projectile(scene,String(key))
				if is_instance_valid(actor):
					actor.set_meta("survival_geometry",true); actor.set_meta("survival_visual_bounds",bounds); actor.set_meta("identity_pool_key",key)
					if archetype == "archmage_elementalist": actor._apply_orb_visual()
					elif key == "sage_basic_projectile": actor._get_basic_frames()
					else: actor._get_piercing_frames()
					native_actors.append(actor)
			for index in range(start,native_actors.size()): hero.get_parent().recycle_projectile(native_actors[index],String(key))
		native_pool_size = native_actors.size()
	if archetype == "grand_sage_astra":
		var paths := PackedStringArray()
		for frame in range(1,9): paths.append("res://assets/art/heroes/stage10_sage/frames/effect9/stage10_effect4_%02d.png" % frame)
		var bounds := FIT.warm(paths)
		for actor in hero.sage_blackspot_effects:
			if is_instance_valid(actor):
				actor.set_meta("survival_geometry",true); actor.set_meta("survival_visual_bounds",bounds)
func tick(delta: float) -> bool:
	# True blocks both movement and casting for an actual channel/revival.
	if bool(hero.berserker_reviving): return true
	impact_left = maxf(0,impact_left-delta)
	if not charge_config.is_empty():
		var maximum := maxf(float(charge_config.get(String(spec.max),100)),1)
		hero.ultimate_charge = minf(maximum,hero.ultimate_charge+maxf(float(charge_config.get(String(spec.get("regen","")),0)),0)*delta)
	match archetype:
		"sword_shield": hero._update_fighter_guard(delta)
		"rogue_combo": hero._update_rogue_attack_collision_ignore(delta)
		"pistol_gunner":
			hero.gunner_backstep_cooldown = maxf(0,hero.gunner_backstep_cooldown-delta)
			hero._update_gunner_collision_ignore(delta)
			if hero.gunner_reloading:
				hero.gunner_reload_timer = maxf(0,hero.gunner_reload_timer-delta)
				if hero.gunner_reload_timer <= 0: hero._finish_gunner_reload()
		"berserker_madness":
			hero._update_berserker_madness(delta); hero._update_berserker_hp_visual()
		"alchemist_chemical":
			hero._update_alchemist_material_spawning(delta); hero._collect_nearby_alchemy_materials()
			hero.alchemist_philosopher_unlock_grace_timer = maxf(0,hero.alchemist_philosopher_unlock_grace_timer-delta)
			if hero._update_alchemist_philosopher_unlock_sequence(delta): return true
			hero._update_alchemist_philosopher_gas_regen(delta)
			if hero._update_alchemist_philosopher_channel(delta) or hero._try_start_alchemist_philosopher_stone(): return true
			hero._update_alchemist_poison_trail(delta)
		"summoner_gatekeeper": hero._update_summoner_full_slot_shield(delta)
		"cleric_purifier":
			hero.purifier_protection_cooldown = maxf(0,hero.purifier_protection_cooldown-delta)
			if hero.purifier_protection_active:
				hero.purifier_protection_duration_timer -= delta
				if hero.purifier_protection_duration_timer <= 0: hero._end_purifier_protection(false)
				else:
					hero.purifier_protection_tick_timer -= delta
					if hero.purifier_protection_tick_timer <= 0:
						hero._add_purifier_shield_layer()
						hero.purifier_protection_tick_timer += maxf(float(hero.purifier_protection_config.get("shield_tick_interval",1)),0.05)
			hero._try_activate_purifier_protection()
		"grand_sage_astra":
			_tick_sage(delta)
			if hero.sage_skill3_cooldown_timer <= 0 and hero.imposed_skill_cooldown <= 0: hero._try_cast_sage_mana_condensation()
	if not charge_config.is_empty() and hero.silence_timer <= 0 and hero.imposed_skill_cooldown <= 0:
		if hero.ultimate_charge >= float(charge_config.get(String(spec.max),100)):
			var id := String(spec.get("signature",""))
			if id.is_empty() and weapons.weapon_ids.size() > 1:
				signature_cursor = posmod(signature_cursor, weapons.weapon_ids.size()-1)
				id = String(weapons.weapon_ids[signature_cursor+1])
			if signature_pending.is_empty() and weapons.levels.has(id): signature_pending = id; weapons.cooldowns[id] = 0.0
	resource_redraw -= delta
	if resource_redraw <= 0: resource_redraw = 0.08; hero.queue_redraw()
	return false
func _tick_sage(delta: float) -> void:
	# Tick native passives without enabling the entire unowned AI skill tree.
	var config: Dictionary = hero.sage_config
	var regen := float(config.get("gauge_regen_base",1.5))+floorf(hero.level/5.0)*float(config.get("gauge_regen_per_5_levels",0.5))
	hero._add_sage_gauge(regen*delta)
	hero.sage_skill3_cooldown_timer = maxf(0,hero.sage_skill3_cooldown_timer-delta*hero._get_sage_condensation_cooldown_rate())
	hero.sage_condensation_skill_damage_buff_timer = maxf(0,hero.sage_condensation_skill_damage_buff_timer-delta)
	if hero.sage_condensation_unlock_pending:
		hero.sage_condensation_unlock_effect_timer -= delta
		if hero.sage_condensation_unlock_effect_timer <= 0:
			hero.sage_condensation_unlock_pending = false; hero._emit_sage_late_skill_unlock_cutscene()
	if hero.sage_post_phase_shield_timer > 0:
		hero.sage_post_phase_shield_timer = maxf(0,hero.sage_post_phase_shield_timer-delta)
		if hero.sage_post_phase_shield_timer <= 0 or hero.shield_hp <= 0:
			hero.sage_post_phase_shield_timer = 0; hero.shield_hp = 0; hero.shield_max_hp = 0
	if hero.sage_phase_active:
		hero.sage_phase_remaining = maxf(0,hero.sage_phase_remaining-delta)
		hero.sage_afterimage_timer -= delta
		if hero.velocity.length_squared() > 36 and hero.sage_afterimage_timer <= 0:
			hero._emit_sage_afterimage(); hero.sage_afterimage_timer = maxf(float(config.get("afterimage_interval",0.075)),0.03)
		if hero.sage_phase_remaining <= 0: hero._end_sage_phase()
	else:
		hero.sage_phase_cooldown_timer = maxf(0,hero.sage_phase_cooldown_timer-delta)
		if hero.sage_phase_cooldown_timer <= 0: hero._start_sage_phase()
func _warm_fx(key: String, type: String, count: int) -> void:
	var actors: Array = []
	for index in count: actors.append(hero.get_parent().acquire_transient_fx(key,type))
	for actor in actors:
		if is_instance_valid(actor): hero.get_parent().recycle_transient_fx(actor,key)
func can_cast(id: String, pattern: String) -> bool:
	if uses_ammo(id): return not hero.gunner_reloading and hero.gunner_ammo > 0
	if archetype == "alchemist_chemical" and id == starter:
		if hero.alchemist_transformed: return false
	if archetype == "alchemist_chemical": return hero.alchemist_gas >= float(gas_costs.get(id,0))
	return true
func uses_ammo(id: String) -> bool:
	return archetype == "pistol_gunner" and (id in spec.ammo_weapons or bool(WEAPONS.WEAPONS.get(id,{}).get("uses_ammo",false)))
func prepare_cast(id: String) -> void:
	if archetype == "berserker_madness" and id == starter and hero.berserker_madness_active:
		var target: Node2D = hero._find_berserker_madness_target()
		if is_instance_valid(target): hero._berserker_madness_blink_to(target)
func modify_damage(id: String, damage: int) -> int:
	if uses_ammo(id) and randf() <= float(hero.gunner_config.get("headshot_chance",0.1)):
		return maxi(1,roundi(damage*float(hero.gunner_config.get("headshot_multiplier",1.2))))
	if archetype == "grand_sage_astra": return maxi(1,roundi(damage*hero._get_sage_skill_damage_multiplier()))
	return damage
func on_cast(id: String, play_audio: bool = true, charge_attack: bool = true) -> void:
	attack_serial += 1
	if id == signature_pending:
		hero.ultimate_charge = 0.0; signature_pending = ""; signature_cursor += 1
		hero.ultimate_used.emit(id,String(WEAPONS.WEAPONS[id].name))
	if charge_attack and id == starter and not charge_config.is_empty():
		hero.ultimate_charge = minf(float(charge_config.get(String(spec.max),100)),hero.ultimate_charge+float(charge_config.get(String(spec.get("attack","")),0)))
	if archetype == "alchemist_chemical": hero._consume_alchemist_gas(float(gas_costs.get(id,0)))
	if uses_ammo(id) and String(WEAPONS.WEAPONS[id].pattern) != "burst": consume_ammo(1)
	if not play_audio: return
	audio_serial += 1
	if audio_call.is_valid():
		if spec.has("arg"): audio_call.call(spec.arg)
		else: audio_call.call()
	elif is_instance_valid(audio) and audio.stream != null: audio.stop(); audio.play()
func consume_ammo(shots: int) -> int:
	var count := mini(shots,int(hero.gunner_ammo))
	hero.gunner_ammo -= count; hero._gunner_register_ammo_consumed(count)
	if randf() <= float(hero.gunner_config.get("quickdraw_chance",0.03)):
		hero.gunner_ammo = hero.gunner_magazine_size
	elif hero.gunner_ammo <= 0:
		hero._refresh_gunner_empty_magazine_shield(); hero._start_gunner_reload()
	hero.queue_redraw(); return count
func attack_damage() -> float:
	return float(hero._get_berserker_effective_attack_damage()) if archetype == "berserker_madness" else float(hero.attack_damage)
func cooldown_multiplier() -> float:
	var result := 1.0/(1.0+maxf(float(hero.common_attack_speed_bonus),0))
	if archetype == "berserker_madness" and hero.berserker_madness_active: result /= maxf(float(hero.berserker_config.get("madness_attack_speed_multiplier",2.6)),0.1)
	if archetype == "alchemist_chemical" and hero.alchemist_transformed: result *= float(hero.alchemist_philosopher_config.get("skill_cooldown_multiplier",0.8))
	if archetype == "grand_sage_astra": result /= hero._get_sage_condensation_cooldown_rate()
	return result
func cooldown_for(id: String, base: float) -> float:
	if archetype == "rogue_combo" and id == starter:
		return hero.attack_timer*weapons.haste*float(weapons.stats_for(id).cooldown_scale)
	return base*cooldown_multiplier()
var native_cast_succeeded := false
func native_basic(id: String, target: Node2D, damage: int, reach: float) -> bool:
	native_cast_succeeded = false
	if id != starter or not spec.has("native_basic"): return false
	if not is_instance_valid(target): return true
	var growth: Dictionary = weapons.stats_for(id)
	var sage_interval := maxi(int(growth.get("sage_interval",hero.sage_config.get("third_attack_interval",3))),1)
	var key := "archmage_projectile" if archetype == "archmage_elementalist" else "sage_piercing_projectile" if (hero.sage_attack_serial+1)%sage_interval == 0 else "sage_basic_projectile"
	var authority = hero.get_parent()
	if spec.has("pools") and (not authority.projectile_pools.has(key) or authority.projectile_pools[key].is_empty()): return true
	var old_damage: int = hero.attack_damage; var old_range: float = hero.attack_range; var old_speed: float = hero.projectile_speed
	var basic_range := 0.0; var basic_speed := 0.0; var piercing_speed := 0.0
	var old_combo: int = hero.rogue_bonus_combo_hits
	var old_sage_interval: int = int(hero.sage_config.get("third_attack_interval",3))
	if archetype == "rogue_combo": hero.rogue_bonus_combo_hits = old_combo+int(growth.get("native_combo_bonus",0))
	if archetype == "grand_sage_astra":
		hero.sage_config["third_attack_interval"] = sage_interval
		basic_range = float(hero.sage_config.get("basic_range",650))
		basic_speed = float(hero.sage_config.get("basic_projectile_speed",800)); piercing_speed = float(hero.sage_config.get("piercing_projectile_speed",800))
		hero.sage_config.basic_range = reach
		hero.sage_config.basic_projectile_speed = basic_speed*weapons.projectile_speed; hero.sage_config.piercing_projectile_speed = piercing_speed*weapons.projectile_speed
	hero.attack_damage = damage; hero.attack_range = reach; hero.projectile_speed = old_speed*weapons.projectile_speed
	hero.call(String(spec.native_basic),target)
	native_cast_succeeded = true
	hero.attack_damage = old_damage; hero.attack_range = old_range; hero.projectile_speed = old_speed
	hero.rogue_bonus_combo_hits = old_combo
	if archetype == "grand_sage_astra":
		hero.sage_config.third_attack_interval = old_sage_interval
		hero.sage_config.basic_range = basic_range; hero.sage_config.basic_projectile_speed = basic_speed; hero.sage_config.piercing_projectile_speed = piercing_speed
	# Original helper already plays the appropriate element/third-shot sound.
	on_cast(id,false,false); audio_serial += 1
	if authority.is_combat_simulation_paused(): set_paused(true)
	return true
func tick_revive(delta: float) -> void:
	if not hero.berserker_reviving: return
	revive_left = maxf(0,revive_left-delta)
	if revive_left <= 0: hero._finish_berserker_revive()
func permanent_growth(hp_multiplier: float, move_multiplier: float) -> void:
	weapons.base_max_hp = roundi(weapons.base_max_hp*hp_multiplier)
	weapons.base_move_speed *= move_multiplier
func notify_kill() -> void:
	match archetype:
		"berserker_madness": hero.notify_berserker_skill_kill()
		"cleric_purifier": hero._add_purifier_gauge(float(hero.purifier_gauge_config.get("charge_per_kill",2)))
		"grand_sage_astra": hero._add_sage_gauge(float(hero.sage_config.get("gauge_per_kill",0.75)))
func impact() -> void:
	if impact_left > 0: return
	if is_instance_valid(impact_audio) and impact_audio.stream != null:
		impact_left = 0.12; impact_audio.stop(); impact_audio.play()
func set_paused(paused: bool) -> void:
	for actor in native_actors:
		if is_instance_valid(actor) and bool(actor.active):
			actor.set_physics_process(not paused)
			if paused: actor.projectile_sprite.pause()
			else: actor.projectile_sprite.play()
			if actor.has_method("_sync_monitoring"): actor.call_deferred("_sync_monitoring")
func summary() -> String:
	match archetype:
		"pistol_gunner": return "장전 %.1f초" % hero.gunner_reload_timer if hero.gunner_reloading else "탄약 %d/%d" % [hero.gunner_ammo,hero.gunner_magazine_size]
		"alchemist_chemical": return "현자의 돌 · 변신" if hero.alchemist_transformed else "가스 %d/%d · 재료 %d/%d" % [hero.alchemist_gas,hero.alchemist_gas_max,hero.alchemist_materials_collected,int(hero.alchemist_philosopher_config.get("required_materials",24))]
		"berserker_madness": return ("광기 발동" if hero.berserker_madness_active else "광기 %d/100" % hero.ultimate_charge)+(" · 부활 소진" if hero.berserker_revive_used else " · 부활 1회")
		"summoner_gatekeeper": return "소환 %d/%d" % [hero._get_active_summon_count(),hero._get_summoner_slot_capacity()]
		"grand_sage_astra": return "마력 %d/100 · 응축 %d/%d" % [hero.ultimate_charge,hero.sage_condensation_stacks,int(hero.sage_config.skill_3.get("max_stacks",8))]
	return String(spec.get("label","자원"))+" %d/100" % hero.ultimate_charge
