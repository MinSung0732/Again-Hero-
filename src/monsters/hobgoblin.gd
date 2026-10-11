extends "res://src/monsters/orc.gd"
const DATA := preload("res://src/data/hobgoblin_behavior_catalog.gd")
var nearby_goblins := 0
var command_active := false
var status_bar_head_y := -84.5
var runtime_additions := {"hp":0.0,"damage":0.0,"speed":0.0,"hp_multiplier":1.0,"attack_speed_multiplier":1.0}

func _init() -> void:
	monster_type = "hobgoblin"
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
	var runtime = _formation_runtime()
	if runtime != null: runtime.register(self)

func _formation_runtime():
	return combat_authority.get("goblin_formation_runtime") if is_instance_valid(combat_authority) else null

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	var runtime = _formation_runtime()
	if runtime != null: runtime.invalidate(self)
	queue_redraw()

func formation_radius() -> float:
	return DATA.LORD_RADIUS if special_augment_configs.has("hobgoblin_lord") else DATA.RADIUS

func configure_elite_passive(_skill: Dictionary) -> void:
	command_active = true
	var runtime = _formation_runtime()
	if runtime != null: runtime.invalidate(self)

func apply_visual_profile(profile: Dictionary) -> void:
	if is_instance_valid(visual) and visual.apply_visual_profile(profile):
		status_bar_head_y = visual.position.y-float(profile.get("target_height",145.0))*0.5-12.0
		queue_redraw()

func get_runtime_stat_additions() -> Dictionary:
	return runtime_additions

func update_formation_count(count: int) -> void:
	if count == nearby_goblins: return
	nearby_goblins = maxi(count,0)
	var extra := nearby_goblins*DATA.STAT_PER_ALLY
	runtime_additions.hp = extra
	runtime_additions.damage = extra
	runtime_additions.speed = extra
	runtime_additions.hp_multiplier = DATA.FORTRESS_HP_MULTIPLIER if nearby_goblins >= DATA.FORTRESS_COUNT else 1.0
	runtime_additions.attack_speed_multiplier = 1.0+nearby_goblins*DATA.ATTACK_SPEED_PER_ALLY
	if is_instance_valid(combat_authority) and combat_authority.has_method("refresh_monster_runtime_stats"):
		combat_authority.refresh_monster_runtime_stats(self)
	queue_redraw()

func supports_damage_receipt() -> bool:
	return true

func _attack_target(target: Node2D) -> void:
	# Hero's return value reports a landed hit; invulnerability must not proc stun.
	var landed = target.call("take_damage",attack_damage,self)
	if landed == false or not is_instance_valid(target): return
	if nearby_goblins >= DATA.STUN_COUNT and _roll_stun() and target.has_method("apply_stun"):
		target.call("apply_stun",DATA.STUN_SECONDS)

func _roll_stun() -> bool:
	return randf() < DATA.STUN_CHANCE

func _draw() -> void:
	if dying: return
	if special_augment_configs.has("hobgoblin_lord"):
		# One world-space diameter, even for a giant/elite scaled actor.
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE/global_scale.abs())
		draw_arc(Vector2.ZERO,formation_radius(),0.0,TAU,96,Color(0.88,0.77,0.40,0.55),1.0,false)
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,status_bar_head_y)
