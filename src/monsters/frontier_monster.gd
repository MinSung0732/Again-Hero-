extends "res://src/monsters/orc.gd"
## All content values live in FrontierMonsterCatalog. Reuses cached navigation,
## target refresh, damage receipts, visual LOD, shields and ordinary death.
const DATA := preload("res://src/data/frontier_monster_catalog.gd")
const BUDGET := preload("res://src/data/monster_balance_catalog.gd")
const HIT := preload("res://src/monsters/frontier_attack.gd")
const SCOPE := preload("res://src/systems/status_action_scope.gd")
const BOLT := preload("res://src/monsters/FrontierBolt.tscn")
static var base_stats_cache: Dictionary = {}
@export var species_id: String = "":
	set(value):
		species_id = value
		if DATA.DEFINITIONS.has(value):
			var data: Dictionary = DATA.DEFINITIONS[value]
			monster_type = value
			monster_role = data.role
			# Serialized setter runs before Battle snapshots/modifiers; _ready never resets stats.
			if not base_stats_cache.has(value): base_stats_cache[value] = BUDGET.resolve_base_stats(data)
			BUDGET.apply_base_stats(self,base_stats_cache[value])
@export var projectile_speed := 0.0
var behavior: Dictionary = {}
var attack_count := 0
var first_attack_spent := false
var shield_ratio_granted := 0.0
var initial_shield_total := 0
var spawn_shield_finalized := false
var speed_buff_remaining := 0.0
var speed_buff_multiplier := 1.0
var pending: Dictionary = {}
var pending_time := 0.0
var pending_position := Vector2.ZERO
var pending_target: WeakRef
var pending_handle := Vector3i.ZERO
var pending_action: RefCounted
var ally_scratch: Array = []
var status_bar_y := -78.0
var visible_body_height := 0.0

func _ready() -> void:
	super._ready()
	_refresh_behavior()
	var data: Dictionary = DATA.DEFINITIONS[species_id]
	set_meta("combat_attack_type",data.attack_type)
	apply_visual_profile(data.elite_visual if String(get_meta("visual_variant","")) == "elite" else data.normal_visual)
	_grant_initial_shield()

func apply_visual_profile(profile: Dictionary) -> bool:
	var sprite = get_node_or_null("Visual")
	if sprite == null: return false
	var ok: bool = sprite.apply_visual_profile(profile)
	if ok:
		var origin: Array = profile.get("offset",[0.0,0.0])
		sprite.offset = Vector2(float(origin[0]),float(origin[1]))
		# Actor scale belongs to combat geometry. Normalize presentation separately
		# so elite profile + variant scale cannot multiply body size twice.
		var parent_x := maxf(absf(global_scale.x),0.01)
		var parent_y := maxf(absf(global_scale.y),0.01)
		var giant := float(get_meta("giant_size_multiplier",1.0))
		sprite.scale = Vector2(sprite.scale.x/parent_x,sprite.scale.y/parent_y)*giant
		var floor_y := float(profile.get("ground_y",30.0))
		sprite.position = Vector2(0.0,floor_y)
		var texture: Texture2D = sprite.sprite_frames.get_frame_texture(&"idle",0)
		var source: Array = profile.get("source_idle_bounds",[0,0,texture.get_width(),texture.get_height()])
		visible_body_height = (float(source[3])-float(source[1]))*sprite.scale.y*parent_y
		var top: float = float(profile.get("source_animation_top",source[1]))-texture.get_height()*0.5+sprite.offset.y
		status_bar_y = floor_y+top*sprite.scale.y-12.0/parent_y
		var shadow := get_node_or_null("GroundShadow")
		if shadow != null:
			shadow.position = Vector2(0.0,floor_y)
			var body_width: float = (float(source[2])-float(source[0]))*sprite.scale.x*parent_x
			var width := clampf(body_width*0.58,34.0,86.0)
			shadow.configure(Vector2(width/parent_x,maxf(10.0,width*.25)/parent_y),0.42)
		queue_redraw()
	return ok

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	_refresh_behavior()
	if is_node_ready(): _grant_initial_shield()

func _refresh_behavior() -> void:
	if not DATA.DEFINITIONS.has(species_id): return
	var data: Dictionary = DATA.DEFINITIONS[species_id]
	behavior = data.behavior.duplicate(true)
	behavior["move_multiplier"] = 1.0
	combat_bonus_refresh_timer = 0.0
	attack_range = float(data.base_stats.attack_range)
	projectile_speed = float(data.base_stats.projectile_speed)
	for config in special_augment_configs.values():
		behavior.merge(Dictionary(config.get("behavior",{})),true)
		behavior.move_multiplier *= float(config.get("runtime_stat_multipliers",{}).get("speed_multiplier",1.0))
		var overrides: Dictionary = config.get("stat_overrides",{})
		attack_range = float(overrides.get("attack_range",attack_range))
		projectile_speed = float(overrides.get("projectile_speed",projectile_speed))

func _grant_initial_shield() -> void:
	var ratio := float(behavior.get("shield_ratio",0.0))
	if ratio <= shield_ratio_granted: return
	var extra := int(round(max_hp*(ratio-shield_ratio_granted)))
	shield_ratio_granted = ratio
	initial_shield_total += extra
	_set_own_shield(int(get_meta("temporary_shield_hp",0))+extra)

func on_spawn_stats_finalized() -> void:
	if spawn_shield_finalized: return
	spawn_shield_finalized = true
	var target := int(round(max_hp*float(behavior.get("shield_ratio",0.0))))
	var extra := maxi(target-initial_shield_total,0)
	if extra > 0: _set_own_shield(int(get_meta("temporary_shield_hp",0))+extra)

func _set_own_shield(amount: int) -> void:
	set_meta("temporary_shield_kind","shield")
	set_meta("temporary_shield_hp",maxi(amount,0))
	set_meta("temporary_shield_capacity",maxi(amount,int(get_meta("temporary_shield_capacity",0))))
	MONSTER_RUNTIME_COMMON.note_shield_grant(self,"shield")
	queue_redraw()

func _can_act() -> bool:
	return not dying and current_hp > 0 and not bool(get_meta("stun_active",false)) and not MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self)

func _physics_process(delta: float) -> void:
	if speed_buff_remaining > 0.0:
		speed_buff_remaining = maxf(speed_buff_remaining-delta,0.0)
		if speed_buff_remaining <= 0.0: combat_bonus_refresh_timer = 0.0
	if not pending.is_empty():
		velocity = Vector2.ZERO
		if not _can_act() or bool(get_meta("silence_active",false)):
			_clear_pending()
			return
		pending_time -= delta
		attack_timer = maxf(attack_timer-delta,0.0)
		queue_redraw()
		if pending_time <= 0.0: _finish_strike()
		return
	if not _can_act():
		velocity = Vector2.ZERO
		return
	super._physics_process(delta)

func _get_combat_bonuses() -> Dictionary:
	var result := super._get_combat_bonuses()
	result.move_speed_multiplier = float(result.move_speed_multiplier)*float(behavior.get("move_multiplier",1.0))
	if speed_buff_remaining > 0.0:
		result.move_speed_multiplier = float(result.move_speed_multiplier)*speed_buff_multiplier
	return result

func _attack_target(target: Node2D) -> void:
	if not HIT.target_alive(target): return
	attack_count += 1
	var multiplier := 1.0
	if not first_attack_spent: multiplier *= float(behavior.get("first_multiplier",1.0))
	first_attack_spent = true
	if attack_count % 3 == 0 and behavior.has("third_bonus"):
		multiplier += float(behavior.third_bonus)
		_set_speed_buff(float(behavior.get("third_speed",1.0)),float(behavior.get("speed_duration",0.0)))
	if target.get("current_hp") != null and target.get("max_hp") != null:
		if float(target.get("current_hp"))/maxf(float(target.get("max_hp")),1.0) <= float(behavior.get("execute_threshold",0.0)):
			multiplier *= float(behavior.get("execute_multiplier",1.0))
	var amount := maxi(1,int(round(attack_damage*multiplier)))
	var token := SCOPE.action_or_new(target)
	if bool(behavior.get("projectile",false)):
		_fire(target,(target.global_position-global_position).normalized(),amount,behavior,token)
	else: HIT.hit(target,amount,self,behavior,token)
	var ward_every := int(behavior.get("ward_every",0))
	if ward_every > 0 and attack_count % ward_every == 0: _ward_allies(behavior)

func _fire(target: Node2D, aim: Vector2, amount: int, config: Dictionary, token: RefCounted) -> bool:
	if not is_instance_valid(combat_authority) or not combat_authority.has_method("acquire_projectile"): return false
	var bolt = combat_authority.acquire_projectile(BOLT,"frontier_bolt")
	if not is_instance_valid(bolt): return false
	var payload := config.duplicate(true)
	payload["projectile_speed"] = projectile_speed
	payload["projectile_range"] = attack_range+80.0
	bolt.global_position = global_position
	bolt.setup(self,target,aim,amount,payload,token)
	return true

func _set_speed_buff(multiplier: float, duration: float) -> void:
	if duration <= 0.0: return
	speed_buff_multiplier = multiplier
	speed_buff_remaining = duration
	combat_bonus_refresh_timer = 0.0

func try_cast_elite_skill(skill: Dictionary) -> bool:
	if not _can_act() or bool(get_meta("silence_active",false)) or not pending.is_empty(): return false
	match String(skill.get("kind","")):
		"self_ward":
			_set_own_shield(maxi(int(get_meta("temporary_shield_hp",0)),int(round(max_hp*float(skill.shield_ratio)))))
			return true
		"ally_ward": return _ward_allies(skill) > 0
	if not HIT.target_alive(hero): return false
	if global_position.distance_squared_to(hero.global_position) > pow(float(skill.get("cast_range",attack_range)),2): return false
	var token: RefCounted = skill.get("_status_action",SCOPE.action_or_new(hero))
	if String(skill.get("kind","")) == "fan":
		var aim := (hero.global_position-global_position).normalized()
		var payload := behavior.duplicate(true)
		payload.merge(skill,true)
		for index in range(-1,2):
			_fire(hero,aim.rotated(float(index)*float(skill.get("spread",.18))),maxi(1,int(round(attack_damage*float(skill.damage_multiplier)))),payload,token)
		_visual_call(&"play_attack")
		return true
	if String(skill.get("kind","")) != "strike": return false
	pending = skill.duplicate(true)
	pending_position = hero.global_position
	pending_target = weakref(hero)
	pending_handle = combat_authority.get_battle_entity_handle(hero) if is_instance_valid(combat_authority) and combat_authority.has_method("get_battle_entity_handle") else Vector3i.ZERO
	pending_action = token
	pending_time = float(skill.get("windup",.5))
	velocity = Vector2.ZERO
	_visual_call(&"play_attack")
	queue_redraw()
	return true

func _finish_strike() -> void:
	var target = pending_target.get_ref() if pending_target != null else null
	var same_life: bool = pending_handle == Vector3i.ZERO or (is_instance_valid(combat_authority) and combat_authority.resolve_battle_entity(pending_handle) == target)
	if same_life and HIT.target_alive(target) and target is Node2D and target.global_position.distance_squared_to(pending_position) <= pow(float(pending.get("radius",100.0)),2):
		HIT.hit(target,maxi(1,int(round(attack_damage*float(pending.get("damage_multiplier",1.0))))),self,pending,pending_action)
	_set_speed_buff(float(pending.get("speed_multiplier",1.0)),float(pending.get("speed_duration",0.0)))
	_clear_pending()

func _clear_pending() -> void:
	pending.clear()
	pending_time = 0.0
	pending_target = null
	pending_action = null
	pending_handle = Vector3i.ZERO
	queue_redraw()

func _ward_allies(config: Dictionary) -> int:
	if not is_instance_valid(combat_authority) or not combat_authority.has_method("fill_monsters_near"): return 0
	var radius := float(config.get("ward_radius",220.0))
	combat_authority.fill_monsters_near(global_position,radius,ally_scratch)
	var count := 0
	for actor in ally_scratch:
		if actor == self or not HIT.target_alive(actor) or not actor is Node2D or actor.global_position.distance_squared_to(global_position) > radius*radius: continue
		var value := int(round(float(actor.get("max_hp"))*float(config.get("ward_ratio",.08))))
		# Refresh shared support shield to the greater remaining value; never add repeatedly.
		actor.set_meta("support_shield_hp",maxi(int(actor.get_meta("support_shield_hp",0)),value))
		actor.set_meta("support_shield_capacity",maxi(int(actor.get_meta("support_shield_capacity",0)),value))
		MONSTER_RUNTIME_COMMON.note_shield_grant(actor,"shield")
		actor.queue_redraw()
		count += 1
		if count >= int(config.get("ward_count",3)): break
	ally_scratch.clear()
	return count

func supports_damage_receipt() -> bool:
	return true

func _begin_death() -> void:
	_clear_pending()
	super._begin_death()

func _begin_death_with_result(receipt = null, receipt_revision: int = 0) -> void:
	_clear_pending()
	super._begin_death_with_result(receipt,receipt_revision)

func _draw() -> void:
	# Old Orc's -59 bar line intersects our taller, floor-aligned bodies.
	# The common bar renderer keeps world pixel dimensions under variant scaling.
	if dying: return
	if is_instance_valid(visual) and not visual.is_visual_ready():
		draw_circle(Vector2(0,0),25.0,Color("9b866a"))
	MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,status_bar_y)
	if not pending.is_empty():
		# World-fixed target warning: actor movement/knockback never drags it along.
		var center := to_local(pending_position)
		var radius := float(pending.get("radius",100.0))/maxf(absf(global_scale.x),0.01)
		var color := Color(String(pending.get("color","d6a86f")))
		draw_arc(center,radius,0.0,TAU,32,Color(color,.7),3.0)
		var progress := 1.0-pending_time/maxf(float(pending.get("windup",.5)),.01)
		draw_arc(center,radius-5.0,-PI*.5,-PI*.5+TAU*clampf(progress,0.0,1.0),24,color,4.0)
