extends "res://src/monsters/orc.gd"
const CLOCK_GUMIHO = preload("res://src/systems/battle_clock.gd")
const DATA := preload("res://src/data/gumiho_behavior_catalog.gd")
const SHARED := preload("res://src/systems/gumiho_shared_runtime.gd")
const RETURN_BOLT := preload("res://src/monsters/GumihoReflectedProjectile.tscn")
static var _status_bar_top_cache: Dictionary = {}
var shield_remaining := 5.0
var quiet_time := 0.0
var stealth_remaining := 0.0
var emergency_used := false
var fox_remaining := 0.0
var breath_remaining := 0.0
var breath_elapsed := 0.0
var breath_ticks := 0
var breath_damage := 0
var breath_burn_applied := false
var breath_target: WeakRef
var human_profile: Dictionary = DATA.NORMAL_VISUAL
var status_bar_head_y := -82.0
var gauge := 0.0
var gauge_timer := 0.0
var local_shared := SHARED.new()

func _init() -> void:
	monster_type = "gumiho"; monster_role = "exploder"
	max_hp = DATA.BASE.max_hp; attack_damage = DATA.BASE.attack_damage
	move_speed = DATA.BASE.move_speed; attack_range = DATA.BASE.attack_range
	attack_cooldown = DATA.BASE.attack_cooldown; exp_reward = DATA.BASE.exp_reward
	set_meta("combat_attack_type","melee")
func _ready() -> void:
	super._ready()
	apply_visual_profile(DATA.NORMAL_VISUAL)
	_grant_spawn_shield()
func apply_visual_profile(profile: Dictionary) -> void:
	if profile != DATA.FOX_VISUAL: human_profile = profile
	if is_instance_valid(visual) and visual.apply_visual_profile(profile):
		_update_status_bar_height()
	if profile != DATA.FOX_VISUAL and shield_remaining >= DATA.SHIELD_DURATION and is_inside_tree(): _grant_spawn_shield()
func _update_status_bar_height() -> void:
	var texture: Texture2D = visual.sprite_frames.get_frame_texture(&"idle",0)
	if texture == null: return
	if not _status_bar_top_cache.has(texture):
		var image := texture.get_image()
		var source_top := 0.0
		if image != null and not image.is_empty():
			var used := image.get_used_rect()
			if used.has_area(): source_top = float(used.position.y)
		_status_bar_top_cache[texture] = source_top
	var top: float = _status_bar_top_cache[texture]
	if visual.centered: top -= float(texture.get_height())*0.5
	var head_position: Vector2 = visual.transform * (visual.offset+Vector2(0.0,top))
	status_bar_head_y = head_position.y-12.0
func _grant_spawn_shield() -> void:
	var kind := "shield" if special_augment_configs.has("gumiho_universal") else "ranged"
	set_meta("temporary_shield_kind",kind)
	set_meta("temporary_shield_hp",int(round(max_hp*DATA.SHIELD_RATIO)))
	set_meta("temporary_shield_capacity",int(round(max_hp*DATA.SHIELD_RATIO)))
	MONSTER_RUNTIME_COMMON.note_shield_grant(self,kind)
func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	if shield_remaining > 0.0:
		var kind := "shield" if configs.has("gumiho_universal") else "ranged"
		if String(get_meta("temporary_shield_kind","ranged")) != kind:
			set_meta("temporary_shield_kind",kind)
			MONSTER_RUNTIME_COMMON.note_shield_grant(self,kind)
func supports_damage_receipt() -> bool: return true
func _can_act() -> bool:
	return current_hp > 0 and not dying and not bool(get_meta("stun_active",false)) and not MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self)
func _stealthed() -> bool:
	return stealth_remaining > 0.0 or (fox_remaining > 0.0 and quiet_time >= DATA.FOX_STEALTH_DELAY)
func _apply_orc_damage(amount: int, receipt = null, revision: int = 0) -> void:
	if current_hp <= 0 or dying: return
	if amount > 0:
		if _stealthed(): amount = maxi(1,ceili(amount*0.5))
		quiet_time = 0.0
	super._apply_orc_damage(amount,receipt,revision)
	if not dying and not emergency_used and special_augment_configs.has("gumiho_last_shadow") and current_hp <= max_hp*0.3:
		emergency_used = true; stealth_remaining = DATA.EMERGENCY_STEALTH_DURATION
func _shared():
	return combat_authority.gumiho_shared_runtime if is_instance_valid(combat_authority) and "gumiho_shared_runtime" in combat_authority else local_shared
func _attack_target(target: Node2D) -> void:
	if not _can_act() or breath_remaining > 0.0 or not is_instance_valid(target): return
	super._attack_target(target)
	_shared().record_attack(self,target)
func _get_combat_bonuses() -> Dictionary:
	return {"move_speed_multiplier":1.0,"attack_speed_multiplier":1.7 if special_augment_configs.has("gumiho_fascination") and is_instance_valid(hero) and bool(hero.get_meta("charm_active",false)) else 1.0,"berserk_active":false}
func get_runtime_stat_additions() -> Dictionary:
	return get_meta("runtime_additions",{})
func get_yellow_gauge_value() -> float: return gauge
func _set_fox(enabled: bool) -> void:
	var factor := DATA.FOX_MULTIPLIER if enabled else 1.0
	set_meta("runtime_additions",{"hp_multiplier":factor,"damage_multiplier":factor,"speed_multiplier":factor,"attack_speed_multiplier":factor})
	if is_instance_valid(combat_authority) and combat_authority.has_method("refresh_monster_runtime_stats"):
		combat_authority.refresh_monster_runtime_stats(self)
	else:
		var scale_factor := DATA.FOX_MULTIPLIER if enabled else 1.0/DATA.FOX_MULTIPLIER
		max_hp = maxi(1,roundi(max_hp*scale_factor)); current_hp = mini(max_hp,roundi(current_hp*scale_factor))
		attack_damage = maxi(1,roundi(attack_damage*scale_factor)); move_speed *= scale_factor; attack_cooldown /= scale_factor
	apply_visual_profile(DATA.FOX_VISUAL if enabled else human_profile)
	combat_bonus_cache.clear()
func try_cast_elite_skill(skill: Dictionary) -> bool:
	if not _can_act() or bool(get_meta("silence_active",false)): return false
	var id := String(skill.get("id",""))
	if id == "elite_gumiho_transform":
		if fox_remaining > 0.0: return false
		fox_remaining = DATA.FOX_DURATION; quiet_time = 0.0; _set_fox(true); return true
	if not is_instance_valid(hero): return false
	var target_hp = hero.get("current_hp")
	if target_hp == null or int(target_hp) <= 0: return false
	if id == "elite_gumiho_fear":
		# Summons can be selected as combat targets but do not expose Hero fear fields.
		if not hero.has_method("apply_fear"): return false
		var immunity = hero.get("fear_immunity_timer")
		if bool(hero.get_meta("fear_active",false)) or (immunity != null and float(immunity) > 0.0): return false
		var previous = hero.get_meta("incoming_fear_immunity") if hero.has_meta("incoming_fear_immunity") else null
		hero.set_meta("incoming_fear_immunity",DATA.FEAR_IMMUNITY)
		hero.call("apply_fear",self,DATA.FEAR_DURATION,DATA.FEAR_SPEED)
		if previous == null: hero.remove_meta("incoming_fear_immunity")
		else: hero.set_meta("incoming_fear_immunity",previous)
		return bool(hero.get_meta("fear_active",false))
	if id == "elite_gumiho_foxfire":
		if fox_remaining <= 0.0 or breath_remaining > 0.0 or global_position.distance_squared_to(hero.global_position) > DATA.BREATH_RANGE*DATA.BREATH_RANGE: return false
		breath_target = weakref(hero); breath_remaining = DATA.BREATH_DURATION; breath_elapsed = 0.0; breath_ticks = 0
		breath_damage = maxi(1,roundi(attack_damage*DATA.BREATH_DAMAGE)); breath_burn_applied = false
		visual.play(&"skill"); return true
	return false
func _tick_breath(delta: float) -> void:
	breath_elapsed += delta; breath_remaining = maxf(breath_remaining-delta,0.0)
	var target = breath_target.get_ref() if breath_target != null else null
	var due := mini(DATA.BREATH_TICKS,int(floor((breath_elapsed+0.000001)/DATA.BREATH_DURATION*DATA.BREATH_TICKS)))
	while breath_ticks < due:
		var before := int(floor(float(breath_damage)*breath_ticks/DATA.BREATH_TICKS))
		breath_ticks += 1
		var amount := int(floor(float(breath_damage)*breath_ticks/DATA.BREATH_TICKS))-before
		if not is_instance_valid(target) or int(target.get("current_hp")) <= 0: continue
		if global_position.distance_squared_to(target.global_position) > DATA.BREATH_RANGE*DATA.BREATH_RANGE: continue
		if target.has_method("take_status_damage"): target.call("take_status_damage",amount,self)
		else: target.call("take_damage",amount,self)
		if not breath_burn_applied and target.has_method("apply_burn") and not bool(target.get_meta("burn_active",false)):
			breath_burn_applied = true
			target.call("apply_burn",DATA.BURN_DURATION,maxi(1,roundi(int(target.get("max_hp"))*DATA.BURN_HP_RATIO)),self)
func try_reflect_projectile(projectile: Node2D, amount: int, sender: Node) -> bool:
	if dying or current_hp <= 0 or randf() >= DATA.REFLECTION_CHANCE: return false
	var target := sender as Node2D
	if not is_instance_valid(target) or not target.has_method("take_damage"): target = hero
	if not is_instance_valid(target): return false
	var bolt = combat_authority.acquire_projectile(RETURN_BOLT,"gumiho_reflection") if is_instance_valid(combat_authority) and combat_authority.has_method("acquire_projectile") else RETURN_BOLT.instantiate()
	if bolt.get_parent() == null: get_parent().add_child(bolt)
	bolt.configure(self,target,projectile,amount)
	return true
func _physics_process(delta: float) -> void:
	var clock_raw_delta := delta
	delta = CLOCK_GUMIHO.scaled(self, delta)
	if dying or current_hp <= 0: return
	quiet_time += delta; stealth_remaining = maxf(stealth_remaining-delta,0.0)
	shield_remaining = maxf(shield_remaining-delta,0.0)
	if shield_remaining <= 0.0 and int(get_meta("temporary_shield_hp",0)) > 0:
		set_meta("temporary_shield_hp",0); queue_redraw()
	if fox_remaining > 0.0:
		fox_remaining = maxf(fox_remaining-delta,0.0)
		if fox_remaining <= 0.0: breath_remaining = 0.0; _set_fox(false)
	if is_instance_valid(visual): visual.self_modulate.a = 0.4 if _stealthed() else 1.0
	gauge_timer -= delta
	if gauge_timer <= 0.0:
		gauge_timer = 0.1
		combat_bonus_cache.clear()
		var next := float(_shared().get_stacks(hero)) if is_instance_valid(hero) else 0.0
		if next != gauge: gauge = next; queue_redraw()
	if breath_remaining > 0.0:
		if not _can_act() or bool(get_meta("silence_active",false)): breath_remaining = 0.0
		else: velocity = Vector2.ZERO; _tick_breath(delta); return
	super._physics_process(clock_raw_delta)
func _draw() -> void:
	if not dying: MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,status_bar_head_y,DATA.CHARM_STACKS)
