extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STORE := preload("res://src/systems/monster_collection_store.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("UPGRADE_FEEDBACK: " + message)

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(id), "isolated account")
	var folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	var state := STORE.load_state()
	state.slime = {"unlocked": true, "level": 0, "shards": 90}
	check(STORE.save_state(state), "seed test shards")
	var lobby: Control = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	lobby._on_team_tab_pressed()
	while lobby._formation_card_cache.pending:
		await process_frame
	await process_frame
	await process_frame
	var grid_size: Vector2 = lobby.team_monster_grid.size
	lobby._upgrade_team_monster("slime")
	var effect: Node2D = lobby._team_upgrade_feedback
	check(is_instance_valid(effect) and effect.visible and effect.level == 1, "success feedback")
	check(effect.get_parent().formation_id == "slime", "on upgraded card")
	check(is_instance_valid(effect._portrait) and is_instance_valid(effect._badge), "portrait and badge resolved")
	check(effect._caption.modulate.a == 0.0 and effect._badge.modulate.a == 0.0, "gather reserves copy space")
	await create_timer(0.15).timeout
	check(effect.elapsed > 0.0, "animation advances")
	check(effect._caption.modulate.a > 0.0 and effect._portrait.scale.x > 1.0, "copy and portrait share burst")
	lobby._upgrade_team_monster("slime")
	check(lobby._team_upgrade_feedback == effect and effect.elapsed == 0.0 and effect.level == 2, "rapid upgrade restarts same effect")
	await process_frame
	check(lobby.team_monster_grid.size == grid_size, "no grid resize")
	check(STORE.get_upgrade_level("slime") == 2 and STORE.get_shards("slime") == 30, "two actual upgrades")
	# The effect has no Control hit region; its label also ignores input.
	check(effect._caption.mouse_filter == Control.MOUSE_FILTER_IGNORE, "caption input transparent")
	lobby._upgrade_team_monster("slime")
	check(effect.visible and effect.level == 3, "third upgrade during effect")
	var portrait: TextureRect = effect._portrait
	var badge: Label = effect._badge
	if "--capture" in OS.get_cmdline_user_args():
		await create_timer(0.16).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://upgrade-feedback-preview.png")
	await create_timer(0.75).timeout
	check(not effect.visible and not effect.is_processing(), "expires without idle processing")
	check(portrait.scale == Vector2.ONE and portrait.self_modulate == Color.WHITE, "portrait restored")
	check(badge.modulate.a == 1.0, "badge restored without resizing")
	lobby._upgrade_team_monster("slime")
	check(not effect.visible and STORE.get_upgrade_level("slime") == 3, "failure never shows success")
	# Presentation-only max-level fixture also checks cancellation restores the card.
	effect.restart(30)
	portrait = effect._portrait
	badge = effect._badge
	await process_frame
	check(effect._caption.get_minimum_size().x <= badge.size.x, "max-level caption fits badge")
	lobby._refresh_team_preview()
	check(not effect.visible and portrait.scale == Vector2.ONE and badge.modulate.a == 1.0, "refresh cancels and restores")
	lobby.free()
	SCOPE.select_guest()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	print("MONSTER_UPGRADE_FEEDBACK_FAILED" if failed else "MONSTER_UPGRADE_FEEDBACK_OK")
	quit(1 if failed else 0)
