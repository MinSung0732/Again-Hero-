extends SceneTree

const STORE := preload("res://src/systems/team_loadout_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const POLICY := preload("res://src/systems/dungeon_entry_policy.gd")
const NOTICE := preload("res://src/ui/dungeon_entry_notice.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
var checks := 0
var failures := 0

class Host extends Control:
	const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
	var panel_style: StyleBoxFlat
	func _init() -> void:
		panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color("171423")
		panel_style.border_color = Color("4d405f")
		panel_style.set_border_width_all(3)
	func _apply_lobby_button_skin(button: Button, _primary: bool, font_size: int) -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("6c3b87")
		style.border_color = Color("d4af52")
		style.set_border_width_all(4)
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, SKIN.button_style(style))
		button.add_theme_font_size_override("font_size", font_size)
		button.add_theme_color_override("font_color", Color("fff0c2"))

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# Isolate writes from every real guest/account save.
	var previous_directory := SCOPE.guest_directory
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://entry_notice_smoke_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	var valid := ["slime", "spider", "orc", "bat", "zeus"]
	var fallback := ["slime", "spider", "orc"]
	check(STORE.load_ids(valid, fallback) == fallback, "new profile retains initial defaults")
	check(STORE.save_ids(["slime"], valid), "save one monster")
	check(STORE.load_ids(valid, fallback) == ["slime"], "one monster reload")
	check(STORE.save_ids([], valid), "empty team can be saved")
	check(STORE.load_ids(valid, fallback).is_empty(), "empty saved team stays empty")
	check(STORE.load_ids(valid, fallback).is_empty(), "reopening formation keeps empty team")
	check(STORE.save_ids(["slime", "slime", "zeus", "invalid", "spider", "orc", "bat"], valid), "normalization save")
	check(STORE.load_ids(valid, fallback) == fallback, "deduplication, transcendent exclusion and three-slot limit")
	check(STORE.load_ids([], fallback).is_empty(), "removed/locked IDs do not silently repopulate saved formation")
	for count in range(4):
		check(POLICY.blocked_reason(fallback.slice(0, count), ["a", "b", "c"], false).is_empty() == (count == 3), "entry gate count %d" % count)
	check(not POLICY.blocked_reason(fallback, [], false).is_empty(), "skill gate retained")
	check(POLICY.blocked_reason([], [], true).is_empty(), "tutorial/test exemption retained")
	DirAccess.remove_absolute(SCOPE.guest_directory.path_join("team_loadout.cfg"))
	DirAccess.remove_absolute(SCOPE.guest_directory)
	SCOPE.guest_directory = previous_directory
	var account_id := "00000000-0000-0000-0000-%012x" % Time.get_ticks_usec()
	check(SCOPE.select_account(account_id), "isolated account namespace")
	check(STORE.save_ids([], valid), "account bundle accepts empty team")
	check(STORE.load_ids(valid, fallback).is_empty(), "account empty team reload")
	SCOPE.select_guest()
	check(SCOPE.select_account(account_id) and STORE.load_ids(valid, fallback).is_empty(), "account bundle reopen preserves empty team")
	SCOPE.select_guest()
	DirAccess.remove_absolute("user://accounts/%s/save_bundle.json" % account_id)
	DirAccess.remove_absolute("user://accounts/%s" % account_id)

	var host := Host.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.theme = Theme.new()
	host.theme.default_font = load("res://assets/fonts/Galmuri11.ttf")
	var notice := NOTICE.new()
	notice.install(host)
	check(not notice.visible, "modal initially hidden")
	check(notice.get_parent() is CanvasLayer and notice.get_parent().layer == 130, "above lobby, below tutorial layer")
	var message := POLICY.blocked_reason([], [], false)
	notice.open(message)
	await process_frame
	await process_frame
	check(notice.visible and notice._message.text == message, "entry reason displayed")
	check(notice._message.get_theme_font("font").has_char("던".unicode_at(0)), "Korean game font inherited across canvas layer")
	check(notice._panel.get_theme_stylebox("panel") is StyleBoxTexture, "authored pixel frame installed")
	check(notice._confirm.get_theme_stylebox("normal") is StyleBoxFlat, "authored clean button frame installed")
	check(root.gui_get_focus_owner() == notice._confirm, "confirmation takes focus")
	check(notice.blocks_lobby_input(InputEventMouseButton.new()), "lobby gestures blocked while modal open")
	for width in [1080, 720, 480]:
		root.size = Vector2i(width, 1920)
		await process_frame
		await process_frame
		check(notice._panel.size.x <= width - 48 + 1, "frame fits viewport %d" % width)
		check(notice._message.get_global_rect().end.x <= notice._panel.get_global_rect().end.x, "message fits frame %d" % width)
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	check(notice.blocks_lobby_input(cancel) and not notice.visible, "back closes modal")
	notice.open("스테미너가 부족합니다.")
	notice._confirm.pressed.emit()
	check(not notice.visible, "confirm closes reusable modal")
	check(not notice.blocks_lobby_input(cancel), "closed modal releases lobby input")
	host.queue_free()
	await process_frame
	print("dungeon_entry_notice_smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
