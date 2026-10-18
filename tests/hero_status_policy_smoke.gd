extends SceneTree

const BEFORE = preload("res://before.gd")
const AFTER = preload("res://after.gd")
const DATA = preload("res://src/data/hero_presentation_catalog.gd")
const ANIMATIONS = [&"death", &"hit", &"dash_start", &"dash_finish", &"attack", &"run", &"move", &"idle", &"custom"]
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func make(script):
	var node = script.new()
	root.add_child(node)
	return node

func draw_case(archetype: String, sample: Dictionary, mode: int):
	var a = make(BEFORE)
	var b = make(AFTER)
	for node in [a, b]:
		node.hero_archetype = archetype
		for property in sample:
			node.set(property, sample[property])
		node.player_controlled = mode > 0
		if mode == 2:
			node.player_weapons = {"identity": null}
		if mode == 3:
			node.player_weapons = {"identity": {"status_resource_y": -101.25, "status_hp_y": -81.5, "status_shield_y": -61.75}}
		node._draw_combat_status_overlay()
	check(a.status_overlay.commands == b.status_overlay.commands and a.bar_queries == b.bar_queries, "draw mismatch: %s/%s/%s" % [archetype, sample, mode])
	# Mutate the same live owner; the next draw must read current config/identity.
	for node in [a, b]:
		node.status_overlay.commands.clear()
		node.bar_queries.clear()
		node.ultimate_charge = 23.5
		node.ultimate_config = {"charge_max": 37.0}
		node.purifier_gauge_config = {"charge_max": 11.5}
		node.berserker_config = {"gauge_max": 73.0}
		node.gunner_config = {"reload_seconds": 1.75}
		node.gunner_reload_timer = 0.5
		node.fixture_slots = 5
		node.fixture_active = 3
		node.hero_archetype = "summoner_gatekeeper" if archetype != "summoner_gatekeeper" else "grand_sage_astra"
		if mode == 3:
			node.player_weapons.identity = {"status_resource_y": -133.5, "status_hp_y": -117.25, "status_shield_y": -101.75}
		node._draw_combat_status_overlay()
	check(a.status_overlay.commands == b.status_overlay.commands and a.bar_queries == b.bar_queries, "redraw mismatch")
	a.free()
	b.free()

func playback_case(a, b, current, requested, playing, looping, visible, state):
	for node in [a, b]:
		node.hero_sprite.visible = visible
		node.is_dying = state == 1
		node.berserker_reviving = state == 2
		node.hit_pose_timer = 0.25 if state == 3 else 0.0
		node.attack_pose_timer = 0.25 if state == 4 else 0.0
		node.berserker_skill3_active = state == 5
		node.fighter_charge_active = state == 6
		node.hero_sprite.sprite_frames.set_animation_loop(current, looping)
		node.hero_sprite.play(current)
		if not playing:
			node.hero_sprite.pause()
		node.hero_sprite.frame = 1
		node.hero_sprite.frame_progress = 0.4
		node.hero_sprite.speed_scale = 1.25
		node.hero_animation_last_restart_name = &""
		node.hero_animation_last_restart_msec = 0
		node.fixture_now = 1000
	check(a._is_current_hero_animation_protected(requested) == b._is_current_hero_animation_protected(requested), "animation protection mismatch")
	for node in [a, b]:
		node._play_stage1_animation(String(requested), 0.9)
	check(a.animation_state() == b.animation_state(), "play state mismatch")
	for node in [a, b]:
		node._restart_stage1_animation(String(requested), 1.3)
		node._restart_stage1_animation(String(requested), 0.75)
		node.fixture_now += 71
		node._restart_stage1_animation(String(requested), 1.1)
	check(a.animation_state() == b.animation_state(), "restart state mismatch")

func run() -> void:
	var saved_resources = DATA.STATUS_RESOURCES.duplicate(true)
	var saved_layouts = DATA.STATUS_LAYOUTS.duplicate(true)
	var saved_hooks = DATA.FRAME_CHANGE_METHODS.duplicate(true)
	var archetypes = DATA.VISUAL_PROFILES.keys()
	archetypes.append("unknown")
	archetypes.append("")
	var samples = [
		{}, {"is_dying": true},
		{"current_hp": -5, "max_hp": 0, "shield_hp": 0.0},
		{"current_hp": 200, "max_hp": 100, "shield_hp": 40.0, "shield_max_hp": 10.0},
		{"shield_hp": 2.5, "shield_max_hp": 0.5, "ultimate_charge": -1.0, "alchemist_gas": -10.0},
		{"shield_hp": -1.0, "shield_max_hp": 10.0, "ultimate_charge": 200.0, "alchemist_gas": 200.0},
		{"ultimate_config": {"charge_max": 0}, "purifier_gauge_config": {"charge_max": -2.0}, "berserker_config": {"gauge_max": 0.5}, "alchemist_gas_max": 0.0},
		{"ultimate_config": {"charge_max": "120"}, "purifier_gauge_config": {"charge_max": 120}, "berserker_config": {"gauge_max": 120.0}, "alchemist_gas_max": 0.5},
	]
	for archetype in archetypes:
		for sample in samples:
			for mode in range(4):
				draw_case(archetype, sample, mode)
	# Segmented gauges: incomplete/negative/over-capacity counts and reload edges.
	for capacity in [1, 3, 6, 12]:
		for count in [-1, 0, 1, 3, 20]:
			for mode in range(4):
				draw_case("summoner_gatekeeper", {"fixture_slots": capacity, "fixture_active": count}, mode)
				draw_case("pistol_gunner", {"gunner_magazine_size": capacity, "gunner_ammo": count}, mode)
		for duration in [-1.0, 0.0, 0.05, 2.4, 5.0]:
			for timer in [-1.0, 0.0, 0.05, 1.2, 2.4, 9.0]:
				for mode in range(4):
					draw_case("pistol_gunner", {"gunner_magazine_size": capacity, "gunner_reloading": true, "gunner_reload_timer": timer, "gunner_config": {"reload_seconds": duration}}, mode)
	var a = make(BEFORE)
	var b = make(AFTER)
	for current in ANIMATIONS:
		check(a._hero_animation_priority(current) == b._hero_animation_priority(current), "priority mismatch")
		for requested in ANIMATIONS:
			for playing in [false, true]:
				for looping in [false, true]:
					for visible in [false, true]:
						for state in range(7):
							playback_case(a, b, current, requested, playing, looping, visible, state)
	for archetype in archetypes:
		for node in [a, b]:
			node.hero_archetype = archetype
			node._on_hero_sprite_frame_or_animation_changed()
		check(a.anchors == b.anchors, "frame hook routing mismatch")
	# Independent examples and a data-only binding to new properties/colors/targets.
	check(b._hero_animation_priority(&"missing") == 40 and b._hero_animation_priority(&"") == 40, "unknown animation priority")
	check(DATA.get_status_layout("summoner_gatekeeper") == Vector4(0, -128, -113, -98), "summoner layout")
	check(DATA.get_status_layout("grand_sage_astra").w == -94.0, "sage shield layout")
	b.is_dying = false
	b.status_overlay.commands.clear()
	var custom = DATA.DEFAULT_STATUS_RESOURCE.duplicate(true)
	custom.value_property = &"shield_hp"
	custom.max_property = &"shield_max_hp"
	custom.use_x_offset = true
	custom.color = Color(0.1, 0.2, 0.3)
	b.shield_hp = 5.0
	b.shield_max_hp = 20.0
	b._draw_status_resource_bar(custom, -25, 80, -30)
	check(b.status_overlay.commands == [[&"rect", Rect2(-30, -25, 80, 8), DATA.STATUS_BACKGROUND_COLOR, true], [&"rect", Rect2(-30, -25, 20, 8), custom.color, true]], "custom ratio binding")
	check(DATA.STATUS_RESOURCES == saved_resources and DATA.STATUS_LAYOUTS == saved_layouts and DATA.FRAME_CHANGE_METHODS == saved_hooks, "shared metadata unchanged")
	a.free()
	b.free()
	print("HERO_STATUS_POLICY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
