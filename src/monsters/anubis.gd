extends "res://src/monsters/orc.gd"
const CLOCK_ANUBIS = preload("res://src/systems/battle_clock.gd")
const DATA := preload("res://src/data/anubis_behavior_catalog.gd")
var mummy_count := 0
var anubis_count := 1
var elite_active := false
var thought_stacks := 0
var shield_fraction := 0.0
var shield_mode := ""
var _last_multiplier := -1.0
var _profile: Dictionary = {}
var _base_visual_scale := Vector2.ONE
var rage_remaining := 0.0
var sacrifice_stat_bonus := 0.0
var sacrifice_size_bonus := 0.0
var status_bar_head_y := -85.0
var runtime_additions := {"hp_multiplier":1.0,"damage_multiplier":1.0,"speed_multiplier":1.0,"attack_speed_multiplier":1.0}

func _init() -> void:
	monster_type = "anubis"
	monster_role = "exploder"
	max_hp = DATA.BASE.max_hp; attack_damage = DATA.BASE.attack_damage
	move_speed = DATA.BASE.move_speed; attack_range = DATA.BASE.attack_range
	attack_cooldown = DATA.BASE.attack_cooldown; exp_reward = DATA.BASE.exp_reward

func _ready() -> void:
	super._ready()
	apply_visual_profile(DATA.NORMAL_VISUAL)

func supports_damage_receipt() -> bool: return true

func _apply_orc_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:
	super._apply_orc_damage(amount,receipt,receipt_revision)
	if not dying and current_hp > 0: _refresh_synergy()

func get_runtime_stat_additions() -> Dictionary: return runtime_additions

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	shield_mode = ""
	for mode in DATA.MODES:
		if configs.has(mode): shield_mode = mode; break
	_refresh_synergy()

func configure_elite_passive(_skill: Dictionary) -> void:
	elite_active = true
	_last_multiplier = -1.0
	_refresh_synergy()

func update_army_counts(mummies: int, anubises: int) -> void:
	var size_changed := mummy_count != mummies
	mummy_count = maxi(0,mummies); anubis_count = maxi(0,anubises)
	_refresh_synergy()
	if size_changed and not _profile.is_empty(): _apply_size()

func _refresh_synergy() -> void:
	var threshold_active := false
	if DATA.MODES.has(shield_mode):
		var mode: Dictionary = DATA.MODES[shield_mode]
		threshold_active = MONSTER_RUNTIME_COMMON.shield_value(self,mode.kind) >= float(mode.threshold)
	var multiplier := (1.0+mummy_count*DATA.MUMMY_STAT_STEP)*(1.0+sacrifice_stat_bonus)*DATA.crowd_multiplier(anubis_count)*(1.0+DATA.SHIELD_STAT_BONUS if threshold_active else 1.0)*(DATA.RAGE_STAT_MULTIPLIER if rage_remaining > 0.0 else 1.0)
	var attack_speed := multiplier*(1.0+mummy_count*DATA.ELITE_MUMMY_SPEED_STEP if elite_active else 1.0)
	if is_equal_approx(multiplier,_last_multiplier) and is_equal_approx(attack_speed,float(runtime_additions.attack_speed_multiplier)): return
	_last_multiplier = multiplier
	runtime_additions.hp_multiplier = multiplier; runtime_additions.damage_multiplier = multiplier
	runtime_additions.speed_multiplier = multiplier; runtime_additions.attack_speed_multiplier = attack_speed
	if is_instance_valid(combat_authority) and combat_authority.has_method("refresh_monster_runtime_stats"):
		combat_authority.refresh_monster_runtime_stats(self)

func on_mummy_death() -> void:
	if dying or current_hp <= 0: return
	if DATA.MODES.has(shield_mode):
		var mode: Dictionary = DATA.MODES[shield_mode]
		shield_fraction += float(mode.production)
		var amount := floori(shield_fraction)
		shield_fraction -= amount
		if mode.kind == "shield": MONSTER_RUNTIME_COMMON.add_support_shield(self,amount,"anubis")
		else: MONSTER_RUNTIME_COMMON.grant_typed_shield(self,mode.kind,amount,true)
	else:
		MONSTER_RUNTIME_COMMON.grant_typed_shield(self,"melee",DATA.MELEE_SHIELD,true)
		MONSTER_RUNTIME_COMMON.grant_typed_shield(self,"ranged",DATA.RANGED_SHIELD,true)
	_refresh_synergy()

func _attack_target(target: Node2D) -> void:
	if not is_instance_valid(target): return
	if elite_active: thought_stacks += DATA.ELITE_STACK_STEP
	# One melee packet avoids losing the fixed additional damage to hit invulnerability.
	target.call("take_damage",attack_damage+thought_stacks,self)

func apply_visual_profile(profile: Dictionary) -> void:
	_profile = profile.duplicate(true)
	if is_instance_valid(visual) and visual.apply_visual_profile(_profile): _base_visual_scale = visual.scale
	_apply_size()

func _apply_size() -> void:
	if not is_instance_valid(visual): return
	var multiplier := minf(1.0+mummy_count*DATA.MUMMY_SIZE_STEP,DATA.MAX_VISUAL_MULTIPLIER)*(1.0+sacrifice_size_bonus)*(DATA.RAGE_SIZE_MULTIPLIER if rage_remaining > 0.0 else 1.0)
	# Scale only: preserve attack/death animation and the cached original SpriteFrames.
	visual.scale = _base_visual_scale*multiplier
	status_bar_head_y = visual.position.y-float(_profile.get("target_height",191.8))*multiplier*0.5-12.0
	visual.self_modulate = Color("ffd1a1") if rage_remaining > 0.0 else Color.WHITE
	queue_redraw()

func _can_cast() -> bool:
	return current_hp > 0 and not dying and not bool(get_meta("stun_active",false)) and not bool(get_meta("silence_active",false)) and not MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self)

func try_cast_elite_skill(skill: Dictionary) -> bool:
	if not _can_cast(): return false
	match String(skill.get("id","")):
		"elite_anubis_rage":
			if rage_remaining > 0.0: return false
			rage_remaining = DATA.RAGE_DURATION
			_refresh_synergy(); _apply_size()
			return true
		"elite_anubis_sacrifice":
			if not is_instance_valid(combat_authority): return false
			var army = combat_authority.get("anubis_army_runtime")
			if army == null: return false
			var kind: String = army.sacrifice(self)
			if not DATA.SACRIFICE_STATS.has(kind): return false
			sacrifice_stat_bonus += float(DATA.SACRIFICE_STATS[kind])
			sacrifice_size_bonus += float(DATA.SACRIFICE_SIZE[kind])
			_refresh_synergy(); _apply_size()
			return true
	return false

func _physics_process(delta: float) -> void:
	var clock_raw_delta := delta
	delta = CLOCK_ANUBIS.scaled(self, delta)
	if dying or current_hp <= 0: return
	if rage_remaining > 0.0:
		rage_remaining = maxf(rage_remaining-delta,0.0)
		if rage_remaining <= 0.0: _refresh_synergy(); _apply_size()
	super._physics_process(clock_raw_delta)

func _draw() -> void:
	if not dying: MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,status_bar_head_y)
