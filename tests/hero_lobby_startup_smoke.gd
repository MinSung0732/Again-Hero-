extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HERO_LOBBY: " + message)

func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://hero_lobby_smoke_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	var progress := ConfigFile.new()
	progress.set_value("progress", "highest_unlocked_stage", 10)
	progress.set_value("cleared", "stage_10", true)
	for key in ["hard:stage_1", "hero", "rank"]:
		progress.set_value("mode_unlock_seen", key, true)
	check(SCOPE.save_config(progress, "user://stage_progress.cfg") == OK, "isolated unlock fixture")
	var script: Script = load("res://src/ui/hero_lobby_view.gd")
	check(script != null and script.can_instantiate(), "Godot compiles hero lobby extension")
	if script == null or not script.can_instantiate():
		quit(1)
		return
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	check(lobby.current_tab == "main" and lobby.main_tab.visible, "startup main tab initialized")
	check(not lobby.team_tab.visible and not lobby.shop_tab.visible and not lobby.research_tab.visible and not lobby.other_tab.visible, "startup shows one tab without extra click")
	check(lobby.stamina_view != null, "stamina installed")
	check(lobby.main_tools_view != null, "friend and event trays installed")
	check(lobby.exploration_rewards_view != null and lobby.missions_view != null, "exploration and missions installed")
	check(lobby.hero_lobby_view != null, "hero extension installed after shared UI")
	var backdrop := lobby.get_node("LobbyBackground") as TextureRect
	var original_texture: Texture2D = backdrop.texture
	var original_shop: String = lobby.shop_button.text
	var original_team: String = lobby.team_button.text
	var original_research: String = lobby.research_button.text
	for cycle in range(2):
		lobby.main_modes_view.choose_perspective("hero")
		check(lobby.hero_lobby_view.active, "hero perspective active %d" % cycle)
		check(lobby.shop_button.text == "용사상점" and lobby.team_button.text == "팀편성 🔒" and lobby.team_button.disabled and lobby.research_button.text == "성장", "hero navigation labels")
		check(backdrop.texture != null and backdrop.texture != original_texture, "hero guild background loaded")
		for tab in ["shop", "research"]:
			lobby._switch_tab(tab)
			check(lobby.hero_lobby_view.panels[tab].is_visible_in_tree(), "hero content visible: " + tab)
		for child in lobby.hero_lobby_view.original_visibility:
			check(not child.visible, "demon content hidden: " + String(child.name))
		var before_team: String = lobby.current_tab
		lobby._switch_tab("team")
		check(lobby.current_tab == before_team, "locked team tab rejects direct navigation")
		lobby._on_team_tab_pressed()
		check(lobby.current_tab == before_team and not lobby.team_tab.visible, "actual team click handler rejects hero mode")
		lobby.team_button.pressed.emit()
		check(lobby.current_tab == before_team and not lobby.team_tab.visible, "connected button signal cannot bypass lock")
		lobby.hero_lobby_view.active = false
		lobby._on_team_tab_pressed(); lobby._switch_tab("team")
		check(lobby.current_tab == before_team, "selected hero mode blocks entry with stale visual state")
		lobby.hero_lobby_view.active = true
		lobby.team_button.disabled = false
		lobby.main_modes_view.refresh()
		check(lobby.team_button.disabled, "same-mode refresh reasserts team lock")
		lobby._switch_tab("main")
		check(lobby.main_tools_view.is_visible_in_tree(), "shared tools remain in hero mode")
		lobby.main_modes_view.choose_perspective("demon")
		check(not lobby.hero_lobby_view.active and backdrop.texture == original_texture, "demon background restored")
		check(lobby.shop_button.text == original_shop and lobby.team_button.text == original_team and lobby.research_button.text == original_research, "demon labels restored")
		check(not lobby.team_button.disabled, "demon team navigation restored")
		lobby._on_team_tab_pressed()
		check(lobby.current_tab == "team" and lobby.team_tab.visible, "demon team click remains functional")
		lobby._switch_tab("main")
		for child in lobby.hero_lobby_view.original_visibility:
			check(child.visible == lobby.hero_lobby_view.original_visibility[child], "demon visibility restored: " + String(child.name))
	print("HERO_LOBBY_STARTUP_SMOKE checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
