extends SceneTree
## Hero lobby preferences share their keys with the in-game Hero settings.
const SETTINGS_VIEW := preload("res://src/ui/lobby_settings_view.gd")
var checks := 0
var failures := 0

class MockLobby extends Control:
	var gameplay_settings_path := "user://hero_lobby_visual_settings_smoke.cfg"
	var hero_mode := true
	func _is_hero_lobby_mode() -> bool:
		return hero_mode

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HERO_LOBBY_VISUAL: " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var mock := MockLobby.new()
	root.add_child(mock)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(mock.gameplay_settings_path))
	var page := VBoxContainer.new()
	mock.add_child(page)
	var settings = SETTINGS_VIEW.new()
	settings.lobby = mock
	settings.pages = {"game": page}
	settings._build_game()
	settings._sync_game()
	check(settings.hero_visual_section.visible, "Hero lobby displays combat visual options")
	check(settings.hero_visual_section.get_parent() == page, "controls belong to game tab")
	check(settings.hero_effect_slider.min_value == 0.0 and settings.hero_effect_slider.max_value == 100.0 and settings.hero_effect_slider.step == 1.0, "slider covers 0 to 100 percent")
	check(settings.hero_effect_slider.value == 0.0 and settings.hero_attack_range_check.button_pressed, "defaults match battle settings")

	settings.hero_effect_slider.value = 65.0
	settings.hero_attack_range_check.button_pressed = false
	var saved := ConfigFile.new()
	check(saved.load(mock.gameplay_settings_path) == OK, "changes persisted")
	check(int(saved.get_value("gameplay","hero_effect_transparency",-1)) == 65, "lobby uses same transparency key")
	check(not bool(saved.get_value("gameplay","hero_attack_range_visible",true)), "lobby uses same range toggle key")

	saved.set_value("gameplay","hero_effect_transparency",85)
	saved.set_value("gameplay","hero_attack_range_visible",true)
	saved.save(mock.gameplay_settings_path)
	settings._sync_game()
	check(settings.hero_effect_slider.value == 85.0 and settings.hero_effect_value.text == "85%", "changes from battle appear in lobby")
	check(settings.hero_attack_range_check.button_pressed, "range setting from battle restored")

	mock.hero_mode = false
	settings._sync_game()
	check(not settings.hero_visual_section.visible, "Demon lobby hides Hero-only options")
	mock.hero_mode = true
	settings._sync_game()
	check(settings.hero_visual_section.visible, "return to Hero lobby restores options")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(mock.gameplay_settings_path))
	mock.queue_free()
	await process_frame
	print("HERO_LOBBY_VISUAL checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
