extends SceneTree
const MAIN_MODES := preload("res://src/ui/lobby_main_modes_view.gd")
const VIEW := preload("res://src/ui/hero_lobby_view.gd")
const STORE := preload("res://src/systems/hero_mode_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const CHARACTERS := preload("res://src/data/hero_character_catalog.gd")
const MODAL := preload("res://src/ui/hero_formation_modal.gd")
var checks := 0
var failures := 0
class Lobby extends Control:
	const STAGE_PROGRESS := preload("res://src/systems/stage_progress.gd")
	var stage_ids := preload("res://src/data/stage_catalog.gd").ORDER
	var selected_stage_index := 0
	var _stage_transition_running := false
	var hero_lobby_view
	var _portrait_texture_cache := {}
	var normalized := 0
	var loads := 0
	var current_tab := "team"
	func _normalize_hero_portrait_texture(texture: Texture2D) -> Texture2D: normalized += 1; return texture
	func _load_texture(path: String) -> Texture2D:
		loads += 1; return get_node("/root/PresentationWarmup").get_texture(path)
	func _load_png_texture_direct(path: String) -> Texture2D: return get_node("/root/PresentationWarmup").get_texture(path)
	func _refresh_stage_card() -> void: pass
class Mode extends Node:
	var active := true
	func has_all_heroes_unlocked() -> bool: return active
func _initialize() -> void: call_deferred("run")
func check(ok: bool,value: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("FORMATION: "+value)
func run() -> void:
	root.size = Vector2i(1080,1920)
	SCOPE.guest_directory = "user://formation_"+str(Time.get_ticks_usec()); DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory); SCOPE.select_guest()
	var mode := Mode.new(); mode.name = "LocalTestMode"; root.add_child(mode)
	var warm = load("res://tests/formation_warmup.gd").new(); warm.name = "PresentationWarmup"; root.add_child(warm)
	var loading = load("res://tests/formation_transition.gd").new(); loading.name = "SceneTransition"; root.add_child(loading)
	var lobby := Lobby.new(); root.add_child(lobby); lobby.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := VBoxContainer.new(); lobby.add_child(body); body.position = Vector2(40,290); body.size = Vector2(1000,1400)
	var view := VIEW.new(); view.lobby = lobby; view.bodies = {"team":body}; lobby.hero_lobby_view = view
	var status := {"ready":false}
	var callback := func() -> bool:
		check(loading.visible,"loading visible before expensive preparation")
		await view.prepare_mode(); status.ready = true; return true
	loading.prepare_in_place(callback,"용사 모드 준비 중")
	check(loading.visible and not status.ready,"loading blocks before construction")
	check(not await loading.prepare_in_place(callback),"overlapping load rejected")
	while loading.visible: await process_frame
	check(status.ready and lobby.normalized == 10 and lobby._portrait_texture_cache.size() == 10,"ten portraits normalized during loading")
	check(warm.texture_load_count == 11,"only eleven lobby textures prepared")
	var modes := MAIN_MODES.new(); modes.lobby = lobby
	modes.choose_perspective("hero")
	check(modes.switching_perspective and loading.visible and modes.perspective == "demon","actual mode switch displays loading first")
	modes.choose_perspective("demon")
	while loading.visible: await process_frame
	check(modes.perspective == "hero" and not modes.switching_perspective,"mode commits after preparation and double taps ignored")
	modes.perspective = "demon"
	check(not await modes._prepare_perspective("hero","stale-account") and modes.perspective == "demon","stale account cannot commit mode")
	view.active = true
	await process_frame
	check(view.hero_cards.size() == 10 and view.stat_values.size() == 6,"ten roster cards and six actual stats")
	check(view.selected_portrait.texture != null and view.selected_portrait.size.x >= 270,"large portrait")
	check(view.stat_values[0].text == "1200" and view.stat_values[1].text == "26" and view.stat_values[2].text == "1.61회/초","actual shared survival stats")
	print("FORMATION layout body=",body.size," selected=",view.selected_hero_panel.size," roster=",view.hero_roster_panel.size)
	check(view.selected_hero_panel.size.y < 620 and view.hero_roster_panel.size.y > 450,"roster gets mobile space")
	var card: Button = view.hero_cards.ranged_rookie
	var panel := view.selected_hero_panel
	for id in CHARACTERS.ORDER:
		view._select_character(id); await process_frame
		check(view.selected_hero_panel == panel and view.hero_cards.ranged_rookie == card,"retained controls "+id)
		check(view.selected_hero_label.text == CHARACTERS.get_character(id).name and view.selected_portrait.texture != null,"selection updates "+id)
	check(lobby.normalized == 10 and lobby.loads == 10,"selection never reloads/normalizes portraits")
	var before: int = warm.texture_load_count
	await view.prepare_mode()
	check(warm.texture_load_count == before and view.selected_hero_panel == panel,"warm return reuses cached UI and textures")
	view._open_modal("augment"); await process_frame
	check(is_instance_valid(view.modal) and view.modal.visible and view.modal.mouse_filter == Control.MOUSE_FILTER_STOP,"augment modal blocks background")
	var modal := view.modal
	var focus_event := InputEventAction.new(); focus_event.action = "ui_focus_next"; focus_event.pressed = true; root.push_input(focus_event)
	check(root.gui_get_focus_owner() == modal.weapon_tab,"modal keyboard focus stays inside")
	check(modal.content.get_child_count() == 10,"ten weapon descriptions move into modal")
	modal._show_passives()
	check(modal.selected_tab == "passive" and modal.content.get_child_count() > 1,"passive tab available")
	check(modal.get_node("ModalPanel").size.x <= 1000 and modal.get_node("ModalPanel").size.y <= 1200,"mobile modal bounds")
	view._open_modal("details"); check(view.modal == modal,"double popup blocked")
	modal.get_node("ModalPanel").find_child("CloseModal",true,false).pressed.emit(); await process_frame; await process_frame
	check(not is_instance_valid(view.modal),"close popup")
	for kind in ["skills","details"]:
		view._open_modal(kind); await process_frame
		check(is_instance_valid(view.modal),"secondary popup "+kind)
		var back := InputEventAction.new(); back.action = "ui_cancel"; back.pressed = true; root.push_input(back); await process_frame
		check(not is_instance_valid(view.modal),"back closes only popup "+kind)
	lobby.queue_free(); loading.queue_free(); warm.queue_free(); mode.queue_free(); await process_frame
	print("HERO_FORMATION checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
