extends SceneTree
const PAUSE_VIEW := preload("res://src/ui/hero_pause_view.gd")
const DETAIL := preload("res://src/ui/hero_inventory_detail.gd")
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
var checks := 0
var failures := 0
var closed := 0
class Hero extends BASE.Hero:
	var level := 25
	var player_weapons
	func set_camera_view_locked(_value: bool) -> void: pass
class Metrics extends RefCounted:
	var elapsed_seconds := 417.0
class Battle extends Node:
	var run_metrics := Metrics.new()
	var battle_over := false
	var hero
	var external_pause := false
	func set_external_pause(value: bool) -> void: external_pause = value
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func close() -> void: closed += 1
func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new(); event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	Input.parse_input_event(event); Input.flush_buffered_events()
	event = event.duplicate(); event.pressed = false; Input.parse_input_event(event); Input.flush_buffered_events()
func run() -> void:
	var arena := BASE.Arena.new(); root.add_child(arena)
	var hero := Hero.new(); arena.add_child(hero)
	var runtime := RUNTIME.new(); runtime.install(hero); hero.player_weapons = runtime
	for id in DETAIL.DATA.WEAPONS:
		runtime.levels[id] = 10
		for evolved in [false,true]:
			if evolved: runtime.evolved[id] = true
			else: runtime.evolved.erase(id)
			var model := DETAIL.weapon_model(runtime,hero,id)
			check(not model.name.is_empty() and not model.effects.is_empty(),"real weapon description "+id)
			check(model.rank == ("MAX" if evolved else "Lv.10"),"pending versus completed evolution "+id)
			check(model.rows.size() >= 4 and not model.rows[0][1].is_empty(),"actual current stat rows "+id)
	for id in DETAIL.DATA.PASSIVES:
		runtime.passives[id] = DETAIL.DATA.passive_limit(id)
		var model := DETAIL.passive_model(runtime,id)
		check(model.kind == "보조 증강" and model.rank == "MAX" and not model.effects.is_empty(),"actual passive model "+id)
	for viewport_size in [Vector2i(1080,1920),Vector2i(540,960),Vector2i(1920,1080),Vector2i(960,540)]:
		root.size = viewport_size
		var panel := PanelContainer.new(); root.add_child(panel); panel.position = Vector2(24,80); panel.size = Vector2(minf(920,viewport_size.x-48),viewport_size.y-120)
		panel.add_theme_stylebox_override("panel",DETAIL.style(Color("111322"),Color("e3bc69"),24))
		var rows := VBoxContainer.new(); panel.add_child(rows)
		DETAIL.build(rows,DETAIL.weapon_model(runtime,hero,"madness_hero_blood_sword"),close)
		await process_frame; await process_frame
		var resume := rows.get_node("DetailResume") as Button; var x := rows.get_node("DetailHeader/DetailClose") as Button
		check(resume.get_global_rect().end.y <= viewport_size.y and x.get_global_rect().end.x <= viewport_size.x,"controls fit viewport")
		check(resume.size.y >= 76 and x.size.x >= 76,"mobile target size")
		check((rows.get_node("DetailScroll") as ScrollContainer).size.y > 100,"body scroll retains footer")
		for stat in rows.find_children("StatValue","Label",true,false):
			check(stat.autowrap_mode == TextServer.AUTOWRAP_OFF and stat.get_line_count() == 1,"numeric stat must stay on one line")
			check(stat.size.x >= stat.get_minimum_size().x and stat.get_global_rect().end.x <= panel.get_global_rect().end.x-24,"numeric stat retains intrinsic width inside panel")
		var badges = rows.find_child("DetailBadges",true,false)
		for badge in badges.get_children():
			check(badge.get_child(0).get_line_count() == 1,"badge stays horizontal")
		var before := closed; click(resume.get_global_rect().get_center()); await process_frame
		check(closed == before+1,"actual PC mouse click resumes")
		before = closed; click(x.get_global_rect().get_center()); await process_frame
		check(closed == before+1,"actual close X mouse click")
		before = closed
		var touch := InputEventScreenTouch.new(); touch.index = 2; touch.position = resume.get_global_rect().get_center(); touch.pressed = true
		Input.parse_input_event(touch); Input.flush_buffered_events(); await process_frame
		touch = touch.duplicate(); touch.pressed = false; Input.parse_input_event(touch); Input.flush_buffered_events(); await process_frame
		check(closed == before+1,"actual emulated touch tap resumes")
		panel.queue_free(); await process_frame
	root.size = Vector2i(1080,1920)
	var host = load("res://tests/hero_inventory_binding_harness.gd").new(); root.add_child(host); host.size = Vector2(1080,1920)
	var battle := Battle.new(); root.add_child(battle); battle.hero = hero; host.battle = battle
	host._show_weapon_info(0); await process_frame; await process_frame
	check(host.paused and battle.external_pause and not host.pad.enabled,"actual inventory handler pauses combat/input")
	check(host.inventory_dim.visible and host.overlay.visible,"modal backdrop blocks battle input")
	check(host.overlay_rows.find_child("DetailIcon",true,false) != null,"actual weapon handler uses redesigned detail")
	var x := host.overlay_rows.get_node("DetailHeader/DetailClose") as Button
	click(x.get_global_rect().get_center()); await process_frame
	check(not host.paused and not battle.external_pause and host.pad.enabled and not host.inventory_dim.visible,"actual X resumes and removes input shield")
	host._show_passive_info(0); await process_frame; await process_frame
	check(host.paused and host.overlay_rows.find_child("DetailTitle",true,false) != null,"actual passive click opens shared design")
	var cancel := InputEventAction.new(); cancel.action = "ui_cancel"; cancel.pressed = true
	Input.parse_input_event(cancel); Input.flush_buffered_events(); await process_frame
	check(not host.paused and not host.overlay.visible,"Escape/back resumes detail popup")
	host.choosing = true; host._show_weapon_info(0)
	check(not host.overlay.visible,"augment choice cannot be replaced by inventory popup")
	host.choosing = false
	for viewport in [Vector2i(1080,1920),Vector2i(540,960),Vector2i(1920,1080),Vector2i(960,540)]:
		root.size = viewport; host.size = viewport
		host._pause(); await process_frame; await process_frame
		check(host.paused and battle.external_pause and host.inventory_dim.visible,"real pause handler stops battle with backdrop")
		check(host.overlay.get_global_rect().position.x >= 0 and host.overlay.get_global_rect().end.x <= viewport.x and host.overlay.get_global_rect().end.y <= viewport.y,"pause modal fits viewport")
		var summary = host.overlay_rows.find_child("PauseSummary",true,false)
		check(summary != null and summary.find_child("SummaryGrid",true,false).columns == (4 if summary.size.x-40 >= 760 else 2),"pause summary uses responsive readable columns")
		for action in ["resume","restart","settings","leave"]:
			var target = host.overlay_rows.find_child("Pause_"+action,true,false)
			check(target != null and target.size.y >= 96,"pause action touch target "+action)
		var scroll = host.overlay_rows.get_node("PauseScroll")
		check(scroll.size.y <= scroll.get_child(0).get_combined_minimum_size().y+4,"pause removes unused bottom space")
		scroll.scroll_vertical = 10000; await process_frame
		var leave = host.overlay_rows.find_child("Pause_leave",true,false)
		click(leave.get_global_rect().get_center()); await process_frame
		check(host.last_action == "leave","scroll reaches bottom action and mouse invokes callback")
		host.last_action = ""; host._resume()
		check(not host.inventory_dim.visible and not battle.external_pause,"pause resume clears backdrop")
	host.queue_free(); battle.queue_free(); arena.queue_free(); await process_frame
	print("HERO_INVENTORY_DETAIL checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
