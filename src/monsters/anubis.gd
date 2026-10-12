extends "res://src/monsters/orc.gd"
const DATA := preload("res://src/data/anubis_behavior_catalog.gd")
var mummy_count := 0
var anubis_count := 1
var elite_active := false
var thought_stacks := 0
var shield_fraction := 0.0
var shield_mode := ""
var _last_multiplier := -1.0
var _profile: Dictionary = {}
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
	var multiplier := (1.0+mummy_count*DATA.MUMMY_STAT_STEP)*DATA.crowd_multiplier(anubis_count)*(1.0+DATA.SHIELD_STAT_BONUS if threshold_active else 1.0)
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
		if mode.kind == "shield": MONSTER_RUNTIME_COMMON.add_support_shield(self,amount)
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
	_apply_size()

func _apply_size() -> void:
	if not is_instance_valid(visual): return
	var profile := _profile.duplicate(true)
	profile.target_height = float(profile.get("target_height",140.0))*minf(1.0+mummy_count*DATA.MUMMY_SIZE_STEP,DATA.MAX_VISUAL_MULTIPLIER)
	if visual.apply_visual_profile(profile):
		status_bar_head_y = visual.position.y-float(profile.target_height)*0.5-12.0
		queue_redraw()

func _draw() -> void:
	if not dying: MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,status_bar_head_y)
