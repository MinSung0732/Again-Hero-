extends SceneTree

const BEFORE = preload("res://before.gd")
const AFTER = preload("res://after.gd")
const DATA = preload("res://src/data/hero_presentation_catalog.gd")
const METHODS = ["_apply_stage1_shield_visual", "_apply_stage1_channel_visual"]
const ALL_SETUP = [
	"_apply_stage1_shield_visual", "_apply_stage1_channel_visual",
	"_apply_stage2_rogue_effect_visuals", "_apply_stage3_fighter_effect_visuals",
	"_apply_stage4_gunner_effect_visuals",
]
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func make(script, id: String, empty_state: bool = false):
	var node = script.new()
	root.add_child(node)
	node.hero_id = id
	if empty_state:
		for sprite in [node.rogue_attack_effect, node.channel_effect, node.shield_effect]:
			sprite.sprite_frames = null
	return node

func compare_case(id: String, method: String, size: Vector2i, empty_state: bool, missing: Array, missing_all: bool) -> void:
	var a = make(BEFORE, id, empty_state)
	var b = make(AFTER, id, empty_state)
	for node in [a, b]:
		node.texture_size = size
		node.missing = missing
		node.missing_all = missing_all
		node.call(method)
	check(a.snapshot() == b.snapshot(), "setup mismatch: %s/%s/%s/%s/%s/%s" % [id, method, size, empty_state, missing, missing_all])
	# Recover from incomplete setup and change dimensions on the same sprite.
	for node in [a, b]:
		node.missing = []
		node.missing_all = false
		node.textures.clear()
		node.texture_size = Vector2i(120, 40)
		node.call(method)
	check(a.snapshot() == b.snapshot(), "refresh mismatch: %s/%s" % [id, method])
	a.free()
	b.free()

func run() -> void:
	var saved = DATA.SCALED_EFFECT_PROFILES.duplicate(true)
	var ids = ["ranged_rookie", "other", "", "swift_hunter"]
	for id in ids:
		for method in METHODS:
			var probe = make(BEFORE, "ranged_rookie")
			probe.call(method)
			var paths = probe.paths.duplicate()
			probe.free()
			for size in [Vector2i.ZERO, Vector2i.ONE, Vector2i(64, 96), Vector2i(512, 256)]:
				for empty_state in [false, true]:
					compare_case(id, method, size, empty_state, [], false)
					compare_case(id, method, size, empty_state, [], true)
					for path in paths:
						compare_case(id, method, size, empty_state, [path], false)
	# Maximum extent must consider every loaded frame and both axes.
	for peak in range(1, 7):
		for wide in [false, true]:
			var a = make(BEFORE, "ranged_rookie")
			var b = make(AFTER, "ranged_rookie")
			var pattern = DATA.get_scaled_effect_profile(&"rookie_channel").path_pattern
			for node in [a, b]:
				node.size_overrides[String(pattern) % peak] = Vector2i(240, 20) if wide else Vector2i(20, 240)
				node._apply_stage1_channel_visual()
			check(a.snapshot() == b.snapshot(), "mixed-size frames mismatch")
			check(b.channel_effect.scale == Vector2(1.25, 1.25), "channel max extent across all frames")
			a.free()
			b.free()
	var archetypes = DATA.VISUAL_PROFILES.keys()
	archetypes.append("unknown")
	archetypes.append("")
	for archetype in archetypes:
		for id in ids:
			for missing_all in [false, true]:
				var a = make(BEFORE, id)
				var b = make(AFTER, id)
				for node in [a, b]:
					node.hero_archetype = archetype
					node.missing_all = missing_all
					for method in ALL_SETUP:
						node.call(method)
				check(a.snapshot() == b.snapshot(), "setup owner mismatch: %s/%s/%s" % [id, archetype, missing_all])
				a.free()
				b.free()
	# Independent outcomes, including intentional reset asymmetry.
	var node = make(AFTER, "other")
	var old_channel = node.channel_effect.sprite_frames
	node._apply_stage1_channel_visual()
	check(node.paths.is_empty() and node.channel_effect.sprite_frames == old_channel and node.channel_effect.visible, "other hero channel remains untouched")
	node._apply_stage1_shield_visual()
	check(node.paths.is_empty() and node.shield_effect.sprite_frames == null and not node.shield_effect.visible, "other hero shield reset without loads")
	node.hero_id = "ranged_rookie"
	node.texture_size = Vector2i(10, 20)
	node._apply_stage1_shield_visual()
	check(node.shield_effect.scale == Vector2(180.0 / 512.0, 180.0 / 512.0), "shield uses fixed canvas")
	node._apply_stage1_channel_visual()
	check(node.channel_effect.scale == Vector2(15, 15), "channel uses loaded extent")
	check(node.channel_effect.sprite_frames.get_frame_count(&"channel") == 6, "channel frame count")
	node.free()
	# Data controls identity, node, frame range, animation/FPS and scale policy.
	var custom = DATA.get_scaled_effect_profile(&"rookie_channel").duplicate(true)
	custom.hero_ids = {"fixture_hero": true}
	custom.target = &"rogue_attack_effect"
	custom.animation = &"fixture_animation"
	custom.path_pattern = "res://fixture_%02d.png"
	custom.first = 2
	custom.last = 3
	custom.fps = 7.25
	custom.loop = false
	custom.measure_source_extent = false
	custom.source_extent = 40.0
	custom.target_extent = 100.0
	node = make(AFTER, "fixture_hero")
	node._configure_scaled_effect_profile(custom)
	check(node.paths == ["res://fixture_02.png", "res://fixture_03.png"], "custom frame paths")
	check(node.rogue_attack_effect.sprite_frames.get_frame_count(&"fixture_animation") == 2, "custom animation and target")
	check(node.rogue_attack_effect.sprite_frames.get_animation_speed(&"fixture_animation") == 7.25 and not node.rogue_attack_effect.sprite_frames.get_animation_loop(&"fixture_animation"), "custom fps/loop")
	check(node.rogue_attack_effect.scale == Vector2(2.5, 2.5), "custom extent policy")
	node.free()
	check(DATA.SCALED_EFFECT_PROFILES == saved, "shared metadata unchanged")
	print("HERO_SCALED_EFFECT_POLICY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
