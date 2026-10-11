extends "res://src/monsters/orc.gd"
const DATA := preload("res://src/data/gargoyle_behavior_catalog.gd")
var stored_damage := 0.0
var petrify_used := false
var petrify_remaining := 0.0
var petrify_budget := 0
var petrify_paid := 0
var petrify_elapsed := 0.0
var shield_granted := false
var ally_scratch: Array = []
var movement_bonuses := {"move_speed_multiplier":1.0,"attack_speed_multiplier":1.0,"berserk_active":false}

func _init() -> void:
	monster_type = "gargoyle"
	monster_role = "tank"
	max_hp = DATA.BASE.max_hp
	attack_damage = DATA.BASE.attack_damage
	move_speed = DATA.BASE.move_speed
	attack_range = DATA.BASE.attack_range
	attack_cooldown = DATA.BASE.attack_cooldown
	exp_reward = DATA.BASE.exp_reward

func _ready() -> void:
	super._ready()
	add_to_group("ranged_guards")
	set_meta("ranged_guard", true)
	_grant_augmented_shield()

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	if is_node_ready(): _grant_augmented_shield()

func _grant_augmented_shield() -> void:
	if shield_granted or not special_augment_configs.has("gargoyle_sky_bastion"): return
	shield_granted = true
	MONSTER_RUNTIME_COMMON.grant_typed_shield(self,"ranged",int(round(max_hp*DATA.RANGED_SHIELD_RATIO)))

func _get_combat_bonuses() -> Dictionary:
	return movement_bonuses

func ranged_damage_multiplier() -> float:
	var ratio := float(current_hp)/maxi(max_hp,1)
	var progress := clampf((DATA.LOW_HP_START-ratio)/(DATA.LOW_HP_START-DATA.LOW_HP_MAX),0.0,1.0)
	return 1.0-DATA.RANGED_REDUCTION-DATA.EXTRA_REDUCTION*progress

func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0: return
	if petrify_remaining > 0.0:
		var step := minf(delta,petrify_remaining)
		petrify_remaining = maxf(petrify_remaining-step,0.0)
		petrify_elapsed += step
		var cumulative := int(round(petrify_budget*minf(petrify_elapsed/DATA.PETRIFY_SECONDS,1.0)))
		heal_direct(maxi(cumulative-petrify_paid,0))
		petrify_paid = cumulative
		velocity = Vector2.ZERO
		queue_redraw()
		return
	super._physics_process(delta)

func _attack_target(target: Node2D) -> void:
	var hp_before := int(target.get("current_hp"))
	var shield_before := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	target.call("take_damage",attack_damage,self)
	if not is_instance_valid(target): return
	var shield_after := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	if (hp_before > int(target.get("current_hp")) or shield_before > shield_after) and stored_damage > 0.0:
		var healing := int(round(stored_damage*DATA.STORAGE_HEAL_RATIO))
		stored_damage = 0.0
		heal_direct(healing)

func supports_damage_receipt() -> bool:
	return true

func take_damage(amount: int) -> void:
	_apply_gargoyle_damage(amount)

func take_damage_with_result(amount: int, receipt) -> bool:
	if receipt == null:
		take_damage(amount)
		return false
	var revision: int = receipt.begin(self,amount)
	_apply_gargoyle_damage(amount,receipt,revision)
	return receipt.finish(revision)

func _apply_gargoyle_damage(amount: int, receipt = null, revision: int = 0) -> void:
	if amount <= 0 or dying or current_hp <= 0: return
	amount = MONSTER_RUNTIME_COMMON._consume_support_shield(self,amount,receipt,revision)
	var paid := mini(current_hp,maxi(amount,0))
	current_hp -= paid
	if receipt != null: receipt.record_hp(paid,revision)
	if special_augment_configs.has("gargoyle_recompense"):
		stored_damage += paid*DATA.STORAGE_RATIO
	DAMAGE_NUMBERS.show(self,paid)
	queue_redraw()
	if current_hp <= 0:
		_begin_death_with_result(receipt,revision)
	elif not petrify_used and special_augment_configs.has("gargoyle_stone_slumber") and float(current_hp)/maxi(max_hp,1) <= DATA.LOW_HP_START:
		petrify_used = true
		petrify_remaining = DATA.PETRIFY_SECONDS
		petrify_budget = int(round((max_hp-current_hp)*DATA.PETRIFY_HEAL_RATIO))
		petrify_elapsed = 0.0
		petrify_paid = 0

func try_cast_elite_skill(skill: Dictionary) -> bool:
	if dying or current_hp <= 0 or petrify_remaining > 0.0 or bool(get_meta("stun_active",false)) or bool(get_meta("silence_active",false)) or MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self): return false
	if not is_instance_valid(combat_authority) or not combat_authority.has_method("fill_monsters_near"): return false
	var radius := float(skill.get("radius",DATA.GUARD_RADIUS))
	ally_scratch.clear()
	combat_authority.call("fill_monsters_near",global_position,radius,ally_scratch)
	for ally in ally_scratch:
		if is_instance_valid(ally) and not ally.is_queued_for_deletion() and int(ally.get("current_hp")) > 0 and global_position.distance_squared_to(ally.global_position) <= radius*radius:
			MONSTER_RUNTIME_COMMON.grant_typed_shield(ally,"ranged",int(skill.get("shield_amount",150)))
	ally_scratch.clear()
	return true

func _draw() -> void:
	if dying: return
	# Explicit stone placeholder until approved sprite frames are provided.
	var color := Color("858894") if petrify_remaining <= 0.0 else Color("b2bac7")
	draw_colored_polygon(PackedVector2Array([Vector2(-22,-18),Vector2(-65,-46),Vector2(-48,4),Vector2(-20,18)]),color)
	draw_colored_polygon(PackedVector2Array([Vector2(22,-18),Vector2(65,-46),Vector2(48,4),Vector2(20,18)]),color)
	draw_rect(Rect2(-24,-27,48,58),color)
	draw_circle(Vector2(0,-34),22,color)
	draw_line(Vector2(-14,-46),Vector2(-18,-64),color,7)
	draw_line(Vector2(14,-46),Vector2(18,-64),color,7)
	draw_circle(Vector2(-8,-36),3,Color("dcbf64"))
	draw_circle(Vector2(8,-36),3,Color("dcbf64"))
	MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,-80.0)
