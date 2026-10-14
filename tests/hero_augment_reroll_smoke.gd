extends SceneTree
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const MODE := preload("res://src/data/hero_mode_catalog.gd")
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
var checks := 0
var failures := 0
class Battle extends RefCounted:
	var hero
	var battle_over := false
	var paused := false
	func set_external_pause(value: bool) -> void: paused = value
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("REROLL: "+message)
func ids(cards: Array) -> Array:
	var result: Array = []
	for card in cards: result.append(String(card.id))
	result.sort(); return result
func run() -> void:
	root.size = Vector2i(1080,1920)
	check(MODE.augment_reroll_limit() == 3 and MODE.augment_reroll_limit(2) == 5 and MODE.augment_reroll_limit(-1) == 3,"3+n and negative bonus guard")
	var arena := BASE.Arena.new(); root.add_child(arena)
	var hero = load("res://tests/hero_reroll_actor.gd").new(); arena.add_child(hero)
	var runtime = RUNTIME.new(); runtime.install(hero); hero.player_weapons = runtime
	var ui = load("res://tests/hero_hud_harness.gd").new(); root.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui._build_ui()
	var battle := Battle.new(); battle.hero = hero; ui.battle = battle
	hero.player_augment_requested.connect(ui._show_choices)
	hero.player_augment_candidates = runtime.candidates(); ui._show_choices(hero.player_augment_candidates)
	check(ui.overlay_rows.get_node("AugmentReroll").disabled,"initial touch guard")
	await create_timer(0.30).timeout
	var initial_build: Dictionary = hero.build_counts.duplicate()
	for remaining in [2,1,0]:
		var previous := ids(hero.player_augment_candidates)
		var old_revision: int = ui.choice_generation
		var old_card: String = String(hero.player_augment_candidates[0].id)
		ui.overlay_rows.get_node("AugmentReroll").pressed.emit()
		check(runtime.rerolls_remaining() == remaining,"exactly one charge")
		check(previous != ids(hero.player_augment_candidates),"changed choices")
		check(hero.build_counts == initial_build and hero.level == 1 and hero.current_exp == 0,"build/EXP/level unchanged")
		check(ui.choosing and battle.paused and not ui.pad.enabled,"pause and input retained")
		ui._reroll_choices(old_revision); ui._choose(old_card,old_revision)
		check(runtime.rerolls_remaining() == remaining and hero.build_counts == initial_build,"stale callback rejected")
		await create_timer(0.30).timeout
		check(ui.overlay_rows.get_node("AugmentReroll").disabled == (remaining == 0),"budget button state")
	check(not hero.reroll_player_augment(),"fourth reroll rejected")
	var button: Button = ui.overlay_rows.get_node("AugmentReroll")
	check(button.size.y >= 64 and ui.overlay.position.y+ui.overlay.size.y <= 1920 and ui.overlay.size.y <= 800,"mobile button and centered modal fit")
	hero.current_exp = 60
	ui._choose(String(hero.player_augment_candidates[0].id),ui.choice_generation)
	check(hero.level == 2 and ui.choosing and battle.paused and runtime.rerolls_remaining() == 0,"queued next level keeps spent budget")
	await create_timer(0.30).timeout
	hero.player_controlled = false; check(not hero.reroll_player_augment(),"AI hero denied"); hero.player_controlled = true
	hero.current_hp = 0; check(not hero.reroll_player_augment(),"dead hero denied"); hero.current_hp = 500
	var bonus = RUNTIME.new(); bonus.install(hero,2)
	check(bonus.rerolls_remaining() == 5 and runtime.rerolls_remaining() == 0,"new run bonus separated from old budget")
	bonus.available_weapons = []; bonus.levels.clear(); bonus.weapon_ids.clear()
	for id in DATA.PASSIVES: bonus.passives[id] = DATA.passive_limit(id)
	hero.current_hp = hero.max_hp
	var exhausted: Array = bonus.candidates()
	check(exhausted.size() == 1 and exhausted[0].id == "survival_restore","completed pool")
	check(bonus.reroll(exhausted).is_empty() and bonus.rerolls_remaining() == 5,"no alternative does not consume")
	for owner in DATA.HERO_WEAPONS:
		hero.hero_id = owner
		var constrained = RUNTIME.new(); constrained.install(hero,100)
		for id in constrained.available_weapons:
			if constrained.weapon_ids.size() < 6 and not constrained.levels.has(id): constrained.add(id)
		var cards: Array = constrained.candidates()
		for iteration in range(6):
			var next: Array = constrained.reroll(cards)
			if not next.is_empty(): cards = next
			var unique: Array = []; var owned := false
			for card in cards:
				check(card.id not in unique,"unique card"); unique.append(card.id)
				if DATA.is_weapon(card.id):
					check(constrained.levels.has(card.id),"full six slots exclude new weapons"); owned = true
				else: check(DATA.passive_allowed(card.id,owner,constrained.weapon_ids),"passive compatibility")
			check(owned,"owned upgrade guarantee")
	ui.queue_free(); arena.queue_free(); await process_frame
	print("HERO_AUGMENT_REROLL checks=%d failures=%d" % [checks,failures]); quit(0 if failures == 0 else 1)
