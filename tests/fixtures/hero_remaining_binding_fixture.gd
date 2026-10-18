extends CharacterBody2D
const HERO_ACTION_INTENT := preload("res://src/hero/hero_action_intent.gd")
const HERO_ACTION_PORT := preload("res://src/hero/hero_action_port.gd")
var action_intent = HERO_ACTION_INTENT.new()
# Baseline compatibility only; the real Hero owns one action_intent.
var ranged_action_intent = action_intent
class TargetPolicy:
	static func is_detectable(node: Node) -> bool:
		return is_instance_valid(node) and bool(node.get_meta("detectable", true))
class BurnSpy:
	var remaining := 0.0
	func update(actor, _delta: float) -> void:
		actor.events.append("burn")
const HERO_TARGET_POLICY = TargetPolicy
var burn_runtime = BurnSpy.new()
var events: Array = []
var target: Node2D
var candidate: Node2D
var fighter_charge_target: Node2D
var fighter_charge_active := false
var current_hp := 100
var is_dying := false
var hero_archetype := "ranged_kiter"
var channeling := false
var purifier_gungnir_casting := false
var attack_timer := 0.0
var retarget_timer := 0.0
var wander_timer := 0.0
var attack_pose_timer := 0.0
var hit_pose_timer := 0.0
var ultimate_flash_timer := 0.0
var level_flash_timer := 0.0
var slow_timer := 0.0
var move_multiplier := 1.0
var possession_immunity_timer := 0.0
var ai_memory_clock := 0.0
var ai_observation_timer := 0.0
var silence_timer := 0.0
var imposed_skill_cooldown := 0.0
var paralysis_timer := 0.0
var paralysis_ratio := 0.0
var petrify_timer := 0.0
var move_speed := 235.0
var attack_range := 650.0
var purifier_speed := 1.0
var stunned := false
var feared := false
var charmed := false
var poison_kills := false
var channel_starts := false
var player_controlled := false
var player_input_suspended := true
var player_weapon_tick_done := false
var player_weapons
var alchemist_philosopher_channeling := false
var alchemist_philosopher_unlock_pending := false
var berserker_reviving := false
var revive_finishes := false
var weapon_starts_channel := false
var mutations: Dictionary = {}
var range_after_move := -1.0
var timer_after_move := -1.0
var replace_target_after_move := false
var replacement_target: Node2D
func _update_poison(_delta: float) -> void:
	events.append("poison")
	if poison_kills:
		current_hp = 0
func _tick_petrify(delta: float) -> void:
	events.append("petrify")
	petrify_timer = maxf(petrify_timer - delta, 0.0)
func _tick_charm_timers(_delta: float) -> bool:
	events.append("charm_timers")
	return charmed
func _tick_stun_state(_delta: float) -> bool:
	events.append("stun")
	if stunned:
		velocity = Vector2.ZERO
	return stunned
func _tick_fear_state(_delta: float) -> bool:
	events.append("fear")
	if feared:
		velocity = Vector2(19, 23)
	return feared
func _finish_fighter_charge() -> void:
	events.append("finish_charge")
	fighter_charge_active = false
func _refresh_ai_observation() -> void:
	events.append("observe")
	ai_observation_timer = 0.35
func get_paralysis_attack_multiplier() -> float:
	return 1.0 - paralysis_ratio
func _update_channel_skill(_delta: float) -> void:
	events.append("channel")
	mutate("channel")
	if channel_starts:
		channeling = true
func _find_nearest_monster() -> Node2D:
	events.append("retarget")
	return candidate
func _move_without_monsters() -> void:
	events.append("wander")
	velocity = Vector2(-15, 30)
func _choose_move_direction(_target: Node2D, distance: float) -> Vector2:
	events.append(["choose", distance])
	return Vector2(0.75, -0.25)
func _apply_heal_item_steering(direction: Vector2, _delta: float) -> Vector2:
	events.append("heal_steer")
	mutate("heal_steer")
	return direction + Vector2(0.1, 0.0)
func _apply_chest_steering(direction: Vector2, _delta: float) -> Vector2:
	events.append("chest_steer")
	mutate("chest_steer")
	return direction.rotated(0.1)
func _apply_magnet_item_steering(direction: Vector2, _delta: float) -> Vector2:
	events.append("magnet_steer")
	mutate("magnet_steer")
	return direction * 0.8
func _apply_archmage_boundary_steering(direction: Vector2) -> Vector2:
	events.append("archmage_boundary")
	return direction.rotated(-0.15)
func _apply_ranged_boundary_escape(direction: Vector2) -> Vector2:
	events.append("ranged_boundary")
	return direction.rotated(0.2)
func _get_effective_move_multiplier() -> float:
	return move_multiplier
func _get_purifier_move_speed_multiplier() -> float:
	return purifier_speed
func _move_and_slide_with_obstacle_escape() -> void:
	events.append("move")
	mutate("move")
	global_position += velocity * 0.016
	if range_after_move >= 0.0:
		attack_range = range_after_move
	if timer_after_move >= 0.0:
		attack_timer = timer_after_move
	if replace_target_after_move:
		target = replacement_target
func _clamp_to_battlefield() -> void:
	events.append("clamp")
	global_position = global_position.clamp(Vector2.ZERO, Vector2(2000, 2000))
class IdentitySpy extends RefCounted:
	var host
	func tick_revive(_delta: float):
		host.events.append("revive")
		if host.revive_finishes: host.berserker_reviving = false
class WeaponSpy extends RefCounted:
	var host
	var identity
	func candidates(): return host.fixture_candidates
	func tick(_delta: float):
		host.events.append("weapon_tick")
		host.mutate("weapon_tick")
		if host.weapon_starts_channel: host.alchemist_philosopher_channeling = true
func enable_player(identity_present: bool):
	player_controlled = true
	player_weapons = WeaponSpy.new()
	player_weapons.host = self
	if identity_present:
		player_weapons.identity = IdentitySpy.new()
		player_weapons.identity.host = self
func mutate(point: String):
	if mutations.has(point): hero_archetype = mutations[point]
func _player_move_velocity() -> Vector2:
	events.append("player_velocity")
	mutate("player_velocity")
	return Vector2(33, -17)
func snapshot():
	return [events.duplicate(true), hero_archetype, player_input_suspended, player_weapon_tick_done, berserker_reviving, current_hp, is_dying, velocity, global_position, target, fighter_charge_active, attack_timer, retarget_timer, wander_timer, attack_pose_timer, hit_pose_timer, ultimate_flash_timer, level_flash_timer, slow_timer, move_multiplier, possession_immunity_timer, ai_memory_clock, ai_observation_timer, get_meta("burn_active", false), action_intent.kind, action_intent.attack_kind, action_intent.movement_velocity, action_intent.observed_attack_distance, action_intent.basic_attack_requested, action_intent.pending]

func _update_hero_hit_flash(_delta: float) -> void:
	events.append("_update_hero_hit_flash")
	mutate("_update_hero_hit_flash")

func _update_bleed(_delta: float) -> void:
	events.append("_update_bleed")
	mutate("_update_bleed")

func _update_damage_poison(_delta: float) -> void:
	events.append("_update_damage_poison")
	mutate("_update_damage_poison")

func _tick_received_modifiers(_delta: float) -> void:
	events.append("_tick_received_modifiers")
	mutate("_tick_received_modifiers")

func _update_combat_reposition(_delta: float) -> void:
	events.append("_update_combat_reposition")
	mutate("_update_combat_reposition")

func _update_invulnerability(_delta: float) -> void:
	events.append("_update_invulnerability")
	mutate("_update_invulnerability")

func _update_ultimate(_delta: float) -> void:
	events.append("_update_ultimate")
	mutate("_update_ultimate")

func _update_purifier_gauge(_delta: float) -> void:
	events.append("_update_purifier_gauge")
	mutate("_update_purifier_gauge")

func _update_sage_runtime(_delta: float) -> void:
	events.append("_update_sage_runtime")
	mutate("_update_sage_runtime")

func _update_shield_skill(_delta: float) -> void:
	events.append("_update_shield_skill")
	mutate("_update_shield_skill")

func _update_archmage_skill_runtime(_delta: float) -> void:
	events.append("_update_archmage_skill_runtime")
	mutate("_update_archmage_skill_runtime")

func _update_heal_item_goal(_delta: float) -> void:
	events.append("_update_heal_item_goal")
	mutate("_update_heal_item_goal")

func _update_chest_goal(_delta: float) -> void:
	events.append("_update_chest_goal")
	mutate("_update_chest_goal")

func _update_magnet_item_goal(_delta: float) -> void:
	events.append("_update_magnet_item_goal")
	mutate("_update_magnet_item_goal")

func _update_stage1_pose_visual(_delta: float) -> void:
	events.append("_update_stage1_pose_visual")
	mutate("_update_stage1_pose_visual")

func _prune_offensive_memory() -> void:
	events.append("_prune_offensive_memory")

func _prune_status_memory() -> void:
	events.append("_prune_status_memory")

func _physics_process_rogue(_delta: float) -> void:
	events.append("rogue")
	velocity = Vector2(17, -9)
	mutate("rogue")

func _update_rogue_pose_visual(_delta: float) -> void:
	events.append("rogue_pose")
	mutate("rogue_pose")

func _physics_process_fighter(_delta: float) -> void:
	events.append("fighter")
	velocity = Vector2(17, -9)
	mutate("fighter")

func _update_fighter_pose_visual(_delta: float) -> void:
	events.append("fighter_pose")
	mutate("fighter_pose")

func _physics_process_gunner(_delta: float) -> void:
	events.append("gunner")
	velocity = Vector2(17, -9)
	mutate("gunner")

func _update_gunner_pose_visual(_delta: float) -> void:
	events.append("gunner_pose")
	mutate("gunner_pose")

func _physics_process_berserker(_delta: float) -> void:
	events.append("berserker")
	velocity = Vector2(17, -9)
	mutate("berserker")

func _update_berserker_pose_visual(_delta: float) -> void:
	events.append("berserker_pose")
	mutate("berserker_pose")

func _physics_process_alchemist(_delta: float) -> void:
	events.append("alchemist")
	velocity = Vector2(17, -9)
	mutate("alchemist")

func _update_alchemist_pose_visual(_delta: float) -> void:
	events.append("alchemist_pose")
	mutate("alchemist_pose")

func _physics_process_summoner(_delta: float) -> void:
	events.append("summoner")
	velocity = Vector2(17, -9)
	mutate("summoner")

func _update_summoner_pose_visual(_delta: float) -> void:
	events.append("summoner_pose")
	mutate("summoner_pose")


const HERO_PRESENTATION = preload("res://src/data/hero_presentation_catalog.gd")
const HERO_RUNTIME_BINDINGS = preload("res://src/data/hero_runtime_binding_catalog.gd")
const ARCHMAGE_SKILL_KEYS: Array[String] = HERO_RUNTIME_BINDINGS.ARCHMAGE_SKILL_KEYS
const CONTEXT_AUDIO = preload("res://src/data/contextual_audio_catalog.gd")
const PROJECTILE_SCENE = null
const ULTIMATE_PIERCING_PROJECTILE_SCENE = null
class PROJECTILE_VOLLEY extends RefCounted:
	pass
class SUCCUBUS_BEHAVIOR extends RefCounted:
	const CHARM = {"slow_multiplier": 0.5}
class ProjectileSpy extends Node2D:
	var host
	var payload: Array = []
	var volley
	func setup(a, b, c, d, e = null, f = null, g = null, h = null):
		volley = h
		payload = [a, b, c, d, e, f, g, h != null]
		host.events.append(["setup", global_position, payload.duplicate(true)])
		host.mutate("projectile_setup")
class AugmentSpy extends RefCounted:
	static var host
	static func roll_candidates(count, counts, pool):
		host.events.append(["roll", count, counts.duplicate(true), pool.duplicate()])
		return host.fixture_candidates
const AUGMENT_CATALOG = AugmentSpy
class BuildAISpy extends RefCounted:
	static func choose_candidate(candidates, context, counts, settings):
		var host = context.host
		host.events.append(["choose", counts.duplicate(true), settings.duplicate(true)])
		settings["fixture_probe"] = 1
		return candidates[randi() % candidates.size()]
const BUILD_AI = BuildAISpy
signal health_changed(current, maximum)
signal leveled_up(new_level)
signal augment_selected(new_level, candidates, title, reason, summary)
signal player_augment_requested(candidates)
var hero_id := "fixture_hero"
var max_hp := 100
var hero_sprite: AnimatedSprite2D
var channel_effect: AnimatedSprite2D
var shield_effect: AnimatedSprite2D
var channel_skill_config: Dictionary = {}
var shield_skill_config: Dictionary = {}
var ultimate_config: Dictionary = {}
var channel_duration_timer := 0.0
var channel_tick_timer := 0.0
var channel_cooldown_timer := 0.0
var channel_hid_hero_sprite := false
var shield_hp := 0.0
var shield_max_hp := 0.0
var shield_duration_timer := 0.0
var shield_cooldown_timer := 0.0
var shield_factor := 1.0
var attack_cooldown := 1.35
var attack_damage := 34
var projectile_speed := 500.0
var projectile_count_bonus := 0
var projectile_splash_radius := 0.0
var projectile_splash_damage_ratio := 0.0
var shots: Array = []
var acquire_count := 0
var fail_acquires: Array = []
var piercing_direction := Vector2.ZERO
var level := 1
var exp_to_next_level := 50
var ai_settings: Dictionary = {"base": 3.0}
var build_counts: Dictionary = {}
var augment_pool_ids: Array[String] = ["fixture"]
var fixture_candidates: Array = []
var fixture_max_stack := -1
var player_augment_candidates: Array = []
var archmage_skill_cooldowns: Dictionary = {}
var charm_cooldown_properties: Array = [&"frozen_timer"]
var timers: Dictionary = {&"frozen_timer": 2.0, &"unused_timer": 9.0}
var charm_source: WeakRef
var charm_timer := 2.0
var sage_phase_active := false
var sage_phase_remaining := 1.0
var fighter_block_audio
var magic_block_audio

func _init():
	hero_sprite = AnimatedSprite2D.new(); add_child(hero_sprite)
	channel_effect = AnimatedSprite2D.new(); add_child(channel_effect)
	shield_effect = AnimatedSprite2D.new(); add_child(shield_effect)
	for sprite in [hero_sprite, channel_effect, shield_effect]:
		var frames := SpriteFrames.new()
		for name in [&"channel", &"shield", &"attack"]:
			frames.add_animation(name)
			frames.add_frame(name, ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8)))
		sprite.sprite_frames = frames
	health_changed.connect(func(a, b): events.append(["health", a, b]))
	leveled_up.connect(func(a): events.append(["leveled", a]))
	augment_selected.connect(func(a, b, c, d, e): events.append(["selected", a, b.duplicate(true), c, d, e]))
	player_augment_requested.connect(func(a): events.append(["requested", a.duplicate(true)]))

func _get(property: StringName):
	if timers.has(property): return timers[property]
	return null
func _set(property: StringName, value) -> bool:
	if timers.has(property): timers[property] = value; return true
	return false
func activate_fixture(): AUGMENT_CATALOG.host = self
func _get_common_attack_interval(value): events.append("interval"); return value
func _face_attack_direction(value): events.append(["face", value]); mutate("face")
func _restart_stage1_animation(name, speed = 1.0): events.append(["animation", name, speed]); mutate("animation")
func _play_stage1_audio(slot):
	events.append(["audio", slot])
	if slot == &"basic": mutate("audio_basic")
func _play_purifier_basic_audio(): events.append("purifier_basic"); mutate("holy_audio")
func _fire_archmage_projectile(current): events.append(["archmage_shot", current.global_position]); mutate("override")
func _fire_sage_projectile(current): events.append(["sage_shot", current.global_position]); mutate("override")
func _acquire_projectile(_scene, key) -> Node2D:
	acquire_count += 1
	events.append(["acquire", key, acquire_count])
	if acquire_count in fail_acquires: return null
	var projectile = ProjectileSpy.new()
	projectile.host = self
	add_child(projectile)
	shots.append(projectile)
	return projectile
func _add_ultimate_charge(amount): events.append(["charge", amount])
func _find_best_piercing_direction() -> Vector2: return piercing_direction
func _apply_channel_damage(): events.append(["channel_damage", channeling, channel_duration_timer, attack_timer, hero_sprite.visible])
func _player_shield_amount(value): events.append(["shield_amount", value]); return value * shield_factor
func _required_exp_for_level(value): return value * 25
func _play_level_up_feedback(): events.append("feedback"); mutate("feedback")
func _apply_level_growth(): events.append("growth"); mutate("growth")
func _ensure_summoner_pool_capacity(): events.append(["pool", level, build_counts.duplicate(true)]); mutate("pool")
func _get_augment_roll_build_counts() -> Dictionary: return build_counts
func _get_ai_decision_context() -> Dictionary: events.append("context"); mutate("ai_context"); return {"host": self}
func _get_summoner_augment_ai_settings() -> Dictionary: events.append("summoner_settings"); return ai_settings.duplicate(true)
func get_build_summary(): return "fixture"
func _get_effective_augment_max_stack(_id, maximum) -> int: return fixture_max_stack if fixture_max_stack >= 0 else maximum
func _apply_augment_effect(effect): events.append(["effect", effect.duplicate(true), build_counts.duplicate(true)]); mutate("augment_effect")
func _on_purifier_augment_stack_changed(id): events.append(["purifier_hook", id, build_counts.duplicate(true)])
func _end_sage_phase(): events.append("end_phase"); sage_phase_active = false
func _create_hero_sfx_player(path, db):
	events.append(["create_audio", path, db])
	var player := AudioStreamPlayer.new(); add_child(player); return player
func _ensure_stage1_audio_runtime(): events.append("ensure_stage1"); mutate("ensure_hit")
func _ensure_rogue_audio_runtime(): events.append("ensure_rogue"); mutate("ensure_hit")
func _ensure_fighter_audio_runtime(): events.append("ensure_fighter"); mutate("ensure_hit")
func _ensure_gunner_audio_runtime(): events.append("ensure_gunner"); mutate("ensure_hit")
func _ensure_archmage_audio_runtime(): events.append("ensure_archmage"); mutate("ensure_hit")
func _ensure_berserker_audio_runtime(): events.append("ensure_berserker"); mutate("ensure_hit")
func binding_state():
	var payloads: Array = []
	var shared_volley := true
	for shot in shots:
		payloads.append([shot.global_position, shot.payload.duplicate(true)])
		if shot.volley != shots[0].volley: shared_volley = false
	return [events.duplicate(true), hero_archetype, velocity, global_position, attack_timer, attack_pose_timer, payloads, shared_volley, channeling, channel_duration_timer, channel_tick_timer, channel_cooldown_timer, channel_hid_hero_sprite, hero_sprite.visible, channel_effect.visible, channel_effect.animation, channel_effect.is_playing(), shield_effect.visible, shield_effect.animation, shield_effect.is_playing(), shield_hp, shield_max_hp, shield_duration_timer, shield_cooldown_timer, level, exp_to_next_level, level_flash_timer, build_counts.duplicate(true), ai_settings.duplicate(true), player_augment_candidates.duplicate(true), timers.duplicate(true), archmage_skill_cooldowns.duplicate(true), slow_timer, move_multiplier, sage_phase_active, sage_phase_remaining, is_instance_valid(fighter_block_audio), is_instance_valid(magic_block_audio), action_intent.kind, action_intent.movement_velocity]
