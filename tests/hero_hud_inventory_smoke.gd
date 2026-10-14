extends SceneTree
const HUD := preload("res://src/ui/hero_survival_hud.gd")
const STATS := preload("res://src/ui/hero_compact_stats.gd")
const FRAME := preload("res://src/ui/hero_battle_frame.gd")
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const MODE := preload("res://src/data/hero_mode_catalog.gd")
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const PAD := preload("res://src/hero_mode/hero_move_pad.gd")
class TestHero extends BASE.Hero:
	var player_weapons
	var exp_to_next_level := 60
	var current_exp := 0
	var level := 1
class Metrics extends RefCounted:
	var monster_death_counts := {}
	var elapsed_seconds := 0.0
	func get_remaining_seconds() -> float: return 900.0
class Battle extends RefCounted:
	var hero
	var active_monsters: Dictionary = {}
	var current_stage_data := {"number":1}
	var current_hero_profile := {"display_name":"대현자 아스트라"}
	var run_metrics := Metrics.new()
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("HERO_HUD: "+message)
func run() -> void:
	root.size = Vector2i(1080,1920)
	var harness = load("res://tests/hero_hud_harness.gd").new()
	root.add_child(harness); harness.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); harness._build_ui()
	await process_frame; await process_frame
	check(harness.find_child("HeroPortrait",true,false).texture != null,"selected hero portrait is visible")
	for id in HUD.CHARACTERS.ORDER:
		check(HUD.portrait_texture(id) != null and not HUD.portrait_path(id).is_empty(),"real portrait "+id)
	check(HUD.portrait_path("sage_astra").contains("stage10"),"portrait uses selected hero, not stage1 battlefield")
	check(HUD.portrait_texture("sage_astra") == HUD.portrait_texture("sage_astra"),"portrait texture cached")
	check(harness.timer.get_theme_font_size("font_size") >= 26,"mobile hero/time text enlarged")
	check(harness.weapon_buttons[0].custom_minimum_size.y >= 76,"mobile inventory target enlarged")
	check(harness.hp.custom_minimum_size.y >= 36 and harness.xp.custom_minimum_size.y >= 32,"mobile status bars enlarged")
	check(harness.weapon_buttons.size() == 6 and harness.passive_buttons.size() == 6,"two rows of six actual HUD slots")
	check(harness.get_node("HeroHUD").get_global_rect().end.y <= HUD.BATTLE_TOP,"header remains above battle")
	for slot in harness.weapon_buttons+harness.passive_buttons:
		check(slot.get_global_rect().end.x <= 1060 and slot.get_global_rect().position.x >= 20,"slot stays in header")
		check(slot.get_global_rect().end.y <= HUD.BATTLE_TOP,"slot does not cover battlefield")
	HUD.update_slot(harness.weapon_buttons[0],ICONS.texture(DATA.STARTERS.ranged_rookie),"Lv.10","test")
	check(harness.weapon_buttons[0].get_node("Rank").text == "Lv.10","rank ten remains pending evolution")
	HUD.update_slot(harness.weapon_buttons[0],ICONS.texture(DATA.STARTERS.ranged_rookie),"MAX","test")
	check(harness.weapon_buttons[0].get_node("Rank").text == "MAX" and harness.weapon_buttons[0].text.is_empty(),"icon and max only")
	var stats = harness.stats_panel
	check(not stats.expanded and not stats.rows.visible,"stats starts folded")
	stats.toggle.pressed.emit(); await process_frame; await process_frame
	check(stats.expanded and stats.rows.visible and stats.size.x <= 400,"readable compact expanded panel")
	var arena := BASE.Arena.new(); root.add_child(arena)
	var hero := TestHero.new(); arena.add_child(hero)
	var runtime := RUNTIME.new(); runtime.install(hero); hero.player_weapons = runtime
	var battle := Battle.new(); battle.hero = hero; harness.battle = battle
	for id in DATA.weapon_pool(hero.hero_id).slice(1,6): check(runtime.add(id),"equip six including starter")
	check(runtime.weapon_ids.size() == 6 and not runtime.add(DATA.weapon_pool(hero.hero_id)[6]),"seventh weapon rejected")
	var target := BASE.Target.new(); target.position = Vector2(150,0); arena.add_child(target); arena.targets.append(target)
	for id in runtime.weapon_ids: runtime._cast(id)
	check(target.current_hp < target.max_hp,"six equipped generic weapons deliver damage")
	check(runtime.projectiles.size() == 64 and runtime.effects.size() == 48 and runtime.fields.size() == 8,"six slots retain fixed pool capacity")
	for candidate in runtime.candidates():
		check(not DATA.is_weapon(candidate.id) or runtime.levels.has(candidate.id),"full inventory offers owned weapon upgrades")
	runtime.add("survival_power"); stats.refresh(hero,runtime)
	check(stats.values[0].text == str(roundi(hero.attack_damage*runtime.power)),"live attack includes passive power")
	var starter := String(runtime.weapon_ids[0]); runtime.levels[starter] = 10
	runtime.passives["survival_multishot"] = 2
	harness._refresh_hud()
	check(harness.weapon_buttons[0].get_node("Rank").text == "Lv.10","actual HUD shows pending evolution")
	runtime.evolved[starter] = true; harness._refresh_hud()
	check(harness.weapon_buttons[0].get_node("Rank").text == "MAX","actual HUD shows completed evolution")
	check(harness.passive_buttons[1].get_node("Rank").text == "MAX","actual HUD uses two-level passive cap")
	battle.run_metrics.monster_death_counts = {"slime":7,"orc":3}
	battle.active_monsters[123] = true; battle.active_monsters[456] = true
	harness._refresh_hud(); check(harness.kills_label.text == "처치 10","actual kill total from metrics")
	check(harness.population_label.text == "현재 적 2","live count from active registry")
	battle.active_monsters.erase(123); harness._refresh_hud()
	check(harness.population_label.text == "현재 적 1","despawn updates live count")
	hero.current_hp = 100; harness._refresh_hud()
	check(harness.hp.get_theme_stylebox("fill").bg_color == Color("ec6464"),"danger HP visibly red")
	hero.current_hp = 400; harness._refresh_hud()
	check(harness.hp.get_theme_stylebox("fill").bg_color == Color("e4b84f"),"caution HP amber")
	hero.current_hp = 800; harness._refresh_hud()
	check(harness.hp.get_theme_stylebox("fill").bg_color == Color("29cf79"),"healthy HP green")
	check(harness.hp.get_node("Caption").text.begins_with("체력") and harness.xp.get_node("Caption").text.begins_with("경험치"),"plain Korean health and experience")
	await process_frame; await process_frame
	check(harness.get_node("HeroHUD").get_global_rect().end.y <= HUD.BATTLE_TOP,"refreshed long hero name stays above battle")
	check(harness.find_child("HeroPortrait",true,false).size.y >= 88,"portrait maintains mobile footprint")
	var frame := FRAME.new(); frame.size = Vector2(1080,1920); root.add_child(frame)
	check(frame.tiles.size() == 4 and frame.tiles[0].get_height() > frame.tiles[0].get_width()*2,"tall cropped pillar tiles preserve aspect")
	harness.battle_frame = frame
	var surface := SubViewportContainer.new(); surface.name = "BattleView"; harness.add_child(surface); surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.offset_top = HUD.BATTLE_TOP
	harness.battle_frame_enabled = false; harness._apply_battle_frame()
	check(is_equal_approx(stats.position.x,10) and not frame.visible,"frame off moves stats left")
	check(stats.expanded,"frame change retains expanded stats")
	harness.battle_frame_enabled = true; harness._apply_battle_frame()
	check(is_equal_approx(stats.position.x,100) and frame.visible,"frame on restores stats position")
	check(is_equal_approx(surface.offset_left,90),"stats and battle share frame margin")
	check(STATS.GROUPS.size() == 3 and STATS.GROUPS[0].indices == [0,3,6],"attack survival mobility groups")
	check(stats.values[2].text.ends_with("%"),"movement uses understandable percentage")
	runtime.add("survival_mobility"); stats.refresh(hero,runtime)
	check(stats.values[2].text == "+%.0f%%" % (float(DATA.PASSIVES.survival_mobility.value)*100),"movement bonus matches equipped passive")
	harness.pad.input_surface = surface; harness.pad.set_mode(PAD.MODE_FREE)
	check(not harness.pad._can_start_free(stats.get_global_rect().get_center()),"stats excludes free pad origin")
	check(harness.pad._can_start_free(Vector2(700,700)),"battle still accepts free pad origin")
	var touch := InputEventScreenTouch.new(); touch.index = 4; touch.pressed = true; touch.position = stats.get_global_rect().get_center()
	Input.parse_input_event(touch); Input.flush_buffered_events()
	check(harness.pad.touch_id == -1,"actual stats touch never captures free pad")
	touch = touch.duplicate(); touch.position = Vector2(700,700); Input.parse_input_event(touch); Input.flush_buffered_events()
	check(harness.pad.touch_id == 4,"actual battle touch captures free pad")
	touch = touch.duplicate(); touch.pressed = false; Input.parse_input_event(touch); Input.flush_buffered_events()
	check(harness.pad.touch_id == -1,"free pad releases after battle gesture")
	stats.toggle.pressed.emit(); await process_frame; await process_frame
	check(not stats.rows.visible and stats.size.x < 170,"stats folds back to small button")
	harness.battle_frame_enabled = false; harness._apply_battle_frame()
	check(is_equal_approx(stats.position.x,10) and not stats.expanded,"collapsed button follows frame off")
	harness.battle_frame_enabled = true; harness._apply_battle_frame()
	check(is_equal_approx(stats.position.x,100),"collapsed button restored with frame")
	print("HERO_HUD_INVENTORY checks=%d failures=%d" % [checks,failures])
	frame.queue_free(); arena.queue_free(); harness.queue_free()
	await process_frame
	quit(1 if failures else 0)
