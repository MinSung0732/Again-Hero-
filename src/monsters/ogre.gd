extends "res://src/monsters/orc.gd"
const DATA := preload("res://src/data/ogre_behavior_catalog.gd")
var status_bar_head_y := -89.5
var hit_count := 0
var medium_variant := false
var spawn_shield_granted := false
var fat_active := false
var pending_reflection := 0
var reflecting := false
var runtime_additions := {"hp_multiplier":1.0,"damage_multiplier":1.0,"speed_multiplier":1.0,"attack_speed_multiplier":1.0}

func _init() -> void:
	monster_type = "ogre"
	monster_role = "tank"
	max_hp = DATA.BASE.max_hp
	attack_damage = DATA.BASE.attack_damage
	move_speed = DATA.BASE.move_speed
	attack_range = DATA.BASE.attack_range
	attack_cooldown = DATA.BASE.attack_cooldown
	exp_reward = DATA.BASE.exp_reward

func _ready() -> void:
	super._ready()
	apply_visual_profile(DATA.NORMAL_VISUAL)
	# Battle finalizes synchronously after all modifiers. Standalone scenes get a fallback.
	call_deferred("on_spawn_stats_finalized")

func apply_visual_profile(profile: Dictionary) -> void:
	if is_instance_valid(visual) and visual.apply_visual_profile(profile):
		status_bar_head_y = visual.position.y-float(profile.get("target_height",155.0))*0.5-12.0
		queue_redraw()

func on_spawn_stats_finalized() -> void:
	if spawn_shield_granted or dying or current_hp <= 0: return
	spawn_shield_granted = true
	MONSTER_RUNTIME_COMMON.grant_typed_shield(self,"melee",max_hp)

func configure_summon_variant(effect_type: String, selected: bool) -> void:
	if effect_type != "ogre_great_blood" or not selected or medium_variant: return
	medium_variant = true
	scale *= DATA.MEDIUM_SCALE
	_refresh_variant_stats()

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	_refresh_variant_stats()

func _refresh_variant_stats() -> void:
	var fury: Dictionary = special_augment_configs.get("ogre_war_fury",{})
	var fury_stats: Dictionary = fury.get("runtime_stat_multipliers",DATA.FURY_STATS)
	for key in runtime_additions:
		runtime_additions[key] = (float(DATA.MEDIUM_STATS.get(key,1.0)) if medium_variant else 1.0)*(float(fury_stats.get(key,1.0)) if special_augment_configs.has("ogre_war_fury") else 1.0)
	monster_role = String(fury.get("role_override",DATA.FURY_ROLE)) if special_augment_configs.has("ogre_war_fury") else "tank"
	if is_instance_valid(combat_authority) and combat_authority.has_method("refresh_monster_runtime_stats"):
		combat_authority.refresh_monster_runtime_stats(self)
	queue_redraw()

func get_runtime_stat_additions() -> Dictionary:
	return runtime_additions

func configure_elite_passive(_skill: Dictionary) -> void:
	fat_active = true

func supports_damage_receipt() -> bool:
	return true

func take_damage(amount: int) -> void:
	_apply_ogre_damage(amount)

func take_damage_with_result(amount: int, receipt) -> bool:
	if receipt == null:
		take_damage(amount)
		return false
	var revision: int = receipt.begin(self,amount)
	_apply_ogre_damage(amount,receipt,revision)
	return receipt.finish(revision)

func _apply_ogre_damage(amount: int, receipt = null, revision: int = 0) -> void:
	if amount <= 0 or dying or current_hp <= 0: return
	hit_count += 1
	pending_reflection = 0
	var source = get_meta("_status_damage_source",null)
	super._apply_orc_damage(amount,receipt,revision)
	var reflected := pending_reflection
	pending_reflection = 0
	if reflected > 0 and is_instance_valid(source) and source != self and not source.is_queued_for_deletion() and source.has_method("take_damage"):
		reflecting = true
		source.call("take_damage",reflected,self)
		reflecting = false

func modify_melee_damage(amount: int) -> int:
	var multiplier := DATA.MEDIUM_INCOMING if medium_variant else 1.0
	if hit_count % DATA.HIT_INTERVAL == 0: multiplier *= DATA.THIRD_HIT_MULTIPLIER
	var reduced := maxi(int(round(amount*multiplier)),1)
	if fat_active and not reflecting:
		var roll := _roll_fat()
		if roll < DATA.NULLIFY_CHANCE: return 0
		if roll < DATA.NULLIFY_CHANCE+DATA.REFLECT_CHANCE:
			pending_reflection = int(round(reduced*DATA.REFLECT_RATIO))
	return reduced

func _roll_fat() -> float:
	return randf()

func _draw() -> void:
	if dying: return
	MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,status_bar_head_y)
