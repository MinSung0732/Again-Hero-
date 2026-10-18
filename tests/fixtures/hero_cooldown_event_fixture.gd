extends CharacterBody2D

const HERO_PRESENTATION = preload("res://src/data/hero_presentation_catalog.gd")
const HERO_RUNTIME_BINDINGS = preload("res://src/data/hero_runtime_binding_catalog.gd")
signal death_started
signal died
class AudioRecorder extends Node:
	var host
	func stop(): host.trace.append([&"audio_stop", host.level_up_effect.is_playing()])
	func play(): host.trace.append([&"audio_play", host.level_up_effect.is_playing()])

var hero_archetype: String = "unknown"
var current_hp := 50
var is_dying := false
var imposed_skill_cooldown := 0.5
var archmage_blink_cooldown_timer := 1.5
var archmage_skill_config: Dictionary = {}
var archmage_skill_cooldowns: Dictionary = {}
var summoner_open_gate_unlocked := false
var unlocked: Dictionary = {}
var timers: Dictionary = {}
var trace: Array = []
var hero_sprite: AnimatedSprite2D
var level_up_effect: AnimatedSprite2D
var level_up_audio
var invulnerability_timer := 2.0
var possession_immunity_timer := 2.0
var fear_timer := 2.0
var fear_immunity_timer := 2.0
var fear_recovery_immunity := 2.0
var fear_source: Node2D
var fear_speed_multiplier := 2.0
var poison_timer := 2.0
var poison_tick_timer := 2.0
var poison_damage_remaining := 2
var poison_ticks_remaining := 2
var poison_flash_timer := 2.0
var poison_source: Node2D
var charm_stacks := 3
var charm_timer := 2.0
var charm_immunity_timer := 2.0
var charm_source: WeakRef
var charm_cooldown_properties: Array = []

func _init():
	hero_sprite = AnimatedSprite2D.new()
	add_child(hero_sprite)
	level_up_effect = AnimatedSprite2D.new()
	add_child(level_up_effect)
	level_up_audio = AudioRecorder.new()
	level_up_audio.host = self
	add_child(level_up_audio)
	var frames := SpriteFrames.new()
	for animation in [&"death", &"hit"]:
		frames.add_animation(animation)
		frames.add_frame(animation, ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8)))
	hero_sprite.sprite_frames = frames
	death_started.connect(func(): trace.append([&"death_started", death_state()]))
	died.connect(func(): trace.append([&"died", death_state()]))
	tree_exited.connect(func(): trace.append([&"tree_exited"]))

func _get(property: StringName):
	if timers.has(property):
		trace.append([&"get", property])
		return timers[property]
	return null

func _set(property: StringName, value) -> bool:
	if timers.has(property):
		trace.append([&"set", property, value])
		timers[property] = value
		return true
	return false

func is_conditional_skill_unlocked(key: String) -> bool:
	trace.append([&"unlock", key])
	return bool(unlocked.get(key, false))

func cooldown_state():
	return [timers.duplicate(true), archmage_skill_cooldowns.duplicate(true), imposed_skill_cooldown, archmage_blink_cooldown_timer, trace.duplicate(true)]

func death_state():
	return [is_dying, invulnerability_timer, possession_immunity_timer, fear_timer, fear_immunity_timer, fear_recovery_immunity, fear_speed_multiplier, poison_timer, poison_tick_timer, poison_damage_remaining, poison_ticks_remaining, poison_flash_timer, charm_stacks, charm_timer, charm_immunity_timer, charm_cooldown_properties.duplicate(), velocity, collision_layer, collision_mask, modulate, hero_sprite.modulate, hero_sprite.rotation, get_meta("fear_active", null), get_meta("poison_active", null), get_meta("dullahan_soul_stacks", null)]

func _clear_bleed(): trace.append(&"clear_bleed")
func _clear_burn(): trace.append(&"clear_burn")
func _clear_stun(): trace.append(&"clear_stun")
func _clear_medusa_statuses(): trace.append(&"clear_medusa")
func _clear_received_modifiers(): trace.append(&"clear_modifiers")
func _set_poison_flash(enabled): trace.append([&"poison_flash", enabled])
func _play_stage1_audio(event): trace.append([&"stage1_audio", event, death_state()])
func _play_rogue_death_audio(): trace.append([&"rogue_audio", death_state()])
func _play_fighter_death_audio(): trace.append([&"fighter_audio", death_state()])
func _play_gunner_death_audio(): trace.append([&"gunner_audio", death_state()])
func _play_archmage_death_audio(): trace.append([&"archmage_audio", death_state()])
func _play_berserker_death_audio(): trace.append([&"berserker_audio", death_state()])
func _restart_stage1_animation(animation, speed):
	trace.append([&"restart", animation, speed])

func _apply_level_up_effect_visual():
	trace.append(&"build_level_up")
	var frames := SpriteFrames.new()
	frames.add_animation(&"level_up")
	frames.add_frame(&"level_up", ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8)))
	level_up_effect.sprite_frames = frames

func level_up_state():
	return [trace.duplicate(true), level_up_effect.animation, level_up_effect.frame, level_up_effect.frame_progress, level_up_effect.visible, level_up_effect.is_playing()]
