extends SceneTree

const BEFORE = preload("res://before.gd")
const AFTER = preload("res://after.gd")
const DATA = preload("res://src/data/hero_presentation_catalog.gd")
const METHODS = [
	"_apply_stage2_rogue_effect_visuals",
	"_apply_stage3_fighter_effect_visuals",
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

func make(script, archetype):
	var node = script.new()
	root.add_child(node)
	node.hero_archetype = archetype
	return node

func compare_case(archetype: String, methods: Array, missing: Array, missing_all: bool) -> void:
	var before = make(BEFORE, archetype)
	var after = make(AFTER, archetype)
	for node in [before, after]:
		node.missing = missing
		node.missing_all = missing_all
		for method in methods:
			node.call(method)
	check(before.snapshot() == after.snapshot(), "setup mismatch: %s/%s/%s/%s" % [archetype, methods, missing, missing_all])
	# Reuse the same nodes after a failed or successful setup with all frames restored.
	for node in [before, after]:
		node.missing = []
		node.missing_all = false
		for method in methods:
			node.call(method)
	check(before.snapshot() == after.snapshot(), "refresh mismatch: %s/%s" % [archetype, methods])
	before.free()
	after.free()

func run() -> void:
	var saved = DATA.COMBAT_EFFECT_PROFILES.duplicate(true)
	var archetypes = DATA.VISUAL_PROFILES.keys()
	archetypes.append("unknown")
	archetypes.append("")
	for archetype in archetypes:
		for method in METHODS:
			var probe = make(BEFORE, archetype)
			probe.call(method)
			var paths = probe.paths.duplicate()
			probe.free()
			compare_case(archetype, [method], [], false)
			compare_case(archetype, [method], [], true)
			for path in paths:
				compare_case(archetype, [method], [path], false)
			# Missing every frame of each animation exercises partial/empty bindings.
			var profile = DATA.get_combat_effect_profile(archetype, {METHODS[0]: &"rogue", METHODS[1]: &"fighter", METHODS[2]: &"gunner"}[method])
			for batch in profile.get("batches", []):
				for build in batch["builds"]:
					var block_missing: Array = []
					for animation in build["animations"]:
						var animation_missing: Array = []
						for index in range(int(animation["first"]), int(animation["last"]) + 1):
							animation_missing.append(String(animation["path_pattern"]) % index)
						block_missing.append_array(animation_missing)
						compare_case(archetype, [method], animation_missing, false)
					compare_case(archetype, [method], block_missing, false)
		# Original ready sequence after a preceding hero's presentation has left state.
		for id in ["ranged_rookie", "other"]:
			for missing_all in [false, true]:
				var a = make(BEFORE, archetype)
				var b = make(AFTER, archetype)
				for node in [a, b]:
					node.hero_id = id
					node.missing_all = missing_all
					node._apply_stage1_shield_visual()
					node._apply_stage1_channel_visual()
					for method in METHODS:
						node.call(method)
				check(a.snapshot() == b.snapshot(), "ready setup sequence mismatch: %s/%s/%s" % [archetype, id, missing_all])
				a.free()
				b.free()
	# Test archetype changes on reused sprites, including unconditional rogue reset.
	var a = make(BEFORE, "unknown")
	var b = make(AFTER, "unknown")
	for archetype in ["sword_shield", "pistol_gunner", "rogue_combo", "unknown", "pistol_gunner"]:
		for node in [a, b]:
			node.hero_archetype = archetype
			for method in METHODS:
				node.call(method)
		check(a.snapshot() == b.snapshot(), "archetype change mismatch: " + archetype)
	a.free()
	b.free()
	# Independent data rebinding: new names, path ranges, targets and properties.
	var custom = DATA.get_combat_effect_profile("rogue_combo", &"rogue").duplicate(true)
	custom.batches[0].builds[0].animations[0].name = &"custom"
	custom.batches[0].builds[0].animations[0].path_pattern = "res://fixture_%02d.png"
	custom.batches[0].builds[0].animations[0].first = 2
	custom.batches[0].builds[0].animations[0].last = 3
	custom.batches[0].builds[0].animations[0].fps = 4.25
	custom.batches[0].bindings[0].properties.scale = Vector2(1.25, 1.25)
	var node = make(AFTER, "unknown")
	node._configure_combat_effect_profile(custom)
	check(node.rogue_attack_effect.sprite_frames.get_frame_count(&"custom") == 2, "custom frame range")
	check(node.rogue_attack_effect.sprite_frames.get_animation_speed(&"custom") == 4.25, "custom fps")
	check(node.paths.slice(0, 2) == ["res://fixture_02.png", "res://fixture_03.png"], "custom paths")
	check(node.rogue_attack_effect.scale == Vector2(1.25, 1.25), "custom properties")
	node.free()
	check(DATA.COMBAT_EFFECT_PROFILES == saved, "shared metadata remains unchanged")
	print("HERO_COMBAT_EFFECT_POLICY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
