extends "res://src/monsters/orc.gd"
const DATA := preload("res://src/data/fanatic_behavior_catalog.gd")
const STATUS_SCOPE := preload("res://src/systems/status_action_scope.gd")
var explosion_damage := DATA.BASE.explosion_damage
var followup_target: WeakRef
var followup_remaining := 0.0
var combo_action: RefCounted
var fusing := false
var fuse_remaining := 0.0
var exploded := false
var ritual_active := false
var ritual_elapsed := 0.0
var ritual_spawned := 0
var orb_remaining := 0.0
var status_bar_head_y := -82.0
var enemy_scratch: Array = []
@onready var blast = $ExplosionEffect
@onready var orb = $OrbEffect
func _init() -> void:
	monster_type = "fanatic"; monster_role = "exploder"
	max_hp = DATA.BASE.max_hp; attack_damage = DATA.BASE.attack_damage
	move_speed = DATA.BASE.move_speed; attack_range = DATA.BASE.attack_range
	attack_cooldown = DATA.BASE.attack_cooldown; exp_reward = DATA.BASE.exp_reward
func _ready() -> void:
	super._ready(); apply_visual_profile(DATA.NORMAL_VISUAL)
	blast.apply_visual_profile(DATA.EXPLOSION_VISUAL); blast.hide()
	orb.apply_visual_profile(DATA.ORB_VISUAL); orb.hide()
	blast.animation_finished.connect(_on_blast_finished)
func apply_visual_profile(profile: Dictionary) -> void:
	if is_instance_valid(visual) and visual.apply_visual_profile(profile): status_bar_head_y = visual.position.y-float(profile.get("target_height",140.0))*0.5-12.0
func supports_damage_receipt() -> bool: return true
func _can_act() -> bool:
	return not dying and current_hp > 0 and not bool(get_meta("stun_active",false)) and not MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self)
func _get_combat_bonuses() -> Dictionary:
	return {"move_speed_multiplier":1.5 if special_augment_configs.has("fanatic_suicide") else 1.0,"attack_speed_multiplier":1.0,"berserk_active":false}
func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs); combat_bonus_cache.clear()
	if configs.has("fanatic_suicide"): followup_target = null
func _attack_target(target: Node2D) -> void:
	if not _can_act() or followup_target != null: return
	if special_augment_configs.has("fanatic_suicide"):
		_begin_fuse(0.0); return
	combo_action = STATUS_SCOPE.action_or_new(target)
	var previous := STATUS_SCOPE.begin(target,combo_action)
	var result = target.call("take_damage",maxi(1,int(round(attack_damage*(1.3 if special_augment_configs.has("fanatic_dagger") else 1.0)))),self)
	STATUS_SCOPE.finish(target,previous)
	if result != false and String(get_meta("visual_variant","")) != "elite" and _can_act():
		followup_target = weakref(target); followup_remaining = DATA.FOLLOWUP_DELAY
func _tick_followup(delta: float) -> void:
	if followup_target == null: return
	followup_remaining = maxf(followup_remaining-delta,0.0)
	if followup_remaining > 0.0: return
	var target = followup_target.get_ref(); followup_target = null
	if not is_instance_valid(target) or int(target.get("current_hp")) <= 0 or global_position.distance_squared_to(target.global_position) > attack_range*attack_range: return
	orb.position = to_local(target.global_position); orb.show(); orb_remaining = 0.18
	var previous := STATUS_SCOPE.begin(target,combo_action)
	if target.has_method("take_followup_damage"): target.call("take_followup_damage",attack_damage,self)
	else: target.call("take_damage",attack_damage,self)
	STATUS_SCOPE.finish(target,previous)
func try_cast_elite_skill(_skill: Dictionary) -> bool:
	if not _can_act() or bool(get_meta("silence_active",false)) or ritual_active or not is_instance_valid(combat_authority) or not combat_authority.has_method("_spawn_monster"): return false
	ritual_active = true; ritual_elapsed = 0.0; ritual_spawned = 0
	return true
func _tick_ritual(delta: float) -> void:
	ritual_elapsed = minf(ritual_elapsed+delta,DATA.RITUAL_DURATION)
	var due := mini(DATA.RITUAL_COUNT,int(floor((ritual_elapsed+0.000001)/DATA.RITUAL_DURATION*DATA.RITUAL_COUNT)))
	var budget := 2
	while ritual_spawned < due and budget > 0:
		var point := global_position+Vector2.RIGHT.rotated(TAU*ritual_spawned/DATA.RITUAL_COUNT)*42.0
		var unit = combat_authority.call("_spawn_monster","fanatic",point,0.0,false,{"fixed_base_stats":true,"exclude_all_augments":true,"counts_population":false})
		if is_instance_valid(unit): unit.set_meta("spawn_source","fanatic_ritual")
		ritual_spawned += 1; budget -= 1
	if ritual_spawned >= DATA.RITUAL_COUNT: ritual_active = false
func _physics_process(delta: float) -> void:
	if fusing:
		fuse_remaining = maxf(fuse_remaining-delta,0.0)
		visual.modulate.a = 0.25 if int(fuse_remaining*14.0)%2 == 0 else 1.0
		if fuse_remaining <= 0.0: _explode()
		return
	if dying or current_hp <= 0: return
	orb_remaining = maxf(orb_remaining-delta,0.0)
	if orb_remaining <= 0.0: orb.hide()
	if not _can_act(): followup_target = null; ritual_active = false; velocity = Vector2.ZERO; return
	if bool(get_meta("silence_active",false)): ritual_active = false
	if ritual_active: _tick_ritual(delta)
	_tick_followup(delta)
	super._physics_process(delta)
func _begin_death() -> void: _begin_fuse(DATA.DEATH_DELAY)
func _begin_death_with_result(receipt = null, revision: int = 0) -> void:
	if not dying and receipt != null: receipt.record_death_started(revision)
	_begin_fuse(DATA.DEATH_DELAY)
func _begin_fuse(delay: float) -> void:
	if dying: return
	dying = true; current_hp = 0; fusing = true; fuse_remaining = delay
	followup_target = null; ritual_active = false; velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled",true)
	set_meta("death_type","self_destruct" if delay == 0.0 else "normal")
	died.emit()
	queue_redraw()
	if delay <= 0.0: _explode()
func _explode() -> void:
	if exploded: return
	exploded = true; fusing = false; set_physics_process(false)
	visual.hide(); orb.hide(); blast.show(); blast.stop(); blast.play(&"idle")
	var damage := maxi(1,int(round(explosion_damage*float(attack_damage)/float(DATA.BASE.attack_damage)*float(get_meta("support_damage_multiplier",1.0)))))
	if is_instance_valid(hero) and int(hero.get("current_hp")) > 0 and global_position.distance_squared_to(hero.global_position) <= DATA.EXPLOSION_RADIUS*DATA.EXPLOSION_RADIUS: hero.call("take_damage",damage,self)
	if is_instance_valid(combat_authority) and combat_authority.has_method("fill_active_enemy_summons"):
		combat_authority.fill_active_enemy_summons(enemy_scratch)
		for target in enemy_scratch:
			if target != hero and global_position.distance_squared_to(target.global_position) <= DATA.EXPLOSION_RADIUS*DATA.EXPLOSION_RADIUS: target.call("take_damage",damage,self)
func _on_blast_finished() -> void:
	if exploded: queue_free()
func _draw() -> void:
	if not dying: MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,status_bar_head_y)
