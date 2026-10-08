extends SceneTree

const VIEW := preload("res://src/ui/lobby_stamina_view.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STORE := preload("res://src/systems/stamina_store.gd")
var failed := false

class Host extends Control:
	func _format_shop_number(amount: int) -> String:
		return str(amount)

class Guard extends Node:
	func locks_lobby() -> bool:
		return false
	func is_transitioning() -> bool:
		return false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("STAMINA_INFO_LAYOUT: " + message)

func first_visible_size(view: RefCounted) -> Vector2:
	for frame in 10:
		await process_frame
		if view.overlay.visible and view.overlay.self_modulate.a > 0.0:
			return view.overlay.size
	check(false, "card becomes visible after layout")
	return Vector2.ZERO

func settle() -> void:
	for frame in 6:
		await process_frame

func run() -> void:
	if root.has_node("CloudStore"):
		root.get_node("CloudStore").stop()
	for guard_name in ["TutorialFlow", "SceneTransition"]:
		if not root.has_node(guard_name):
			var guard := Guard.new()
			guard.name = guard_name
			root.add_child(guard)
	SCOPE.guest_directory = "user://stamina_layout_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var config := ConfigFile.new()
	config.set_value("stamina", "amount", 10)
	config.set_value("stamina", "recovery_at", int(Time.get_unix_time_from_system()))
	check(SCOPE.save_configs({"stage_progress.cfg": config}) == OK, "isolated wallet")
	STORE.invalidate()
	for screen in [Vector2i(540,960), Vector2i(360,800)]:
		root.size = screen
		root.content_scale_size = screen * 2
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		var host := Host.new()
		root.add_child(host)
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var view := VIEW.new()
		view.lobby = host
		view.value = Label.new()
		host.add_child(view.value)
		view._info_button = Button.new()
		host.add_child(view._info_button)
		view._info_button.position = Vector2(screen.x,100)
		view._info_button.size = Vector2(220,80)
		view._build_overlay()
		await settle()
		view._hover_info()
		var first := await first_visible_size(view)
		await settle()
		check(first.is_equal_approx(view.overlay.size), "first visible hover size stays settled")
		check(is_equal_approx(view.overlay.size.y, view.overlay.get_combined_minimum_size().y), "background fits text and padding")
		check(root.get_visible_rect().encloses(view.overlay.get_global_rect()), "card stays within viewport")
		view._leave_info()
		view._toggle_info()
		var reopened := await first_visible_size(view)
		check(reopened.is_equal_approx(first), "tap reopening has the same size as initial hover")
		view.close_info()
		view.show_info("안내 문구가 길어지는 상황도 확인합니다.\n두 번째 안내 줄입니다.")
		var longer := await first_visible_size(view)
		await settle()
		check(longer.is_equal_approx(view.overlay.size) and longer.y > first.y, "long notice settles before first visible frame")
		view.close_info()
		view.show_info()
		var shorter := await first_visible_size(view)
		check(shorter.is_equal_approx(first), "shorter text shrinks background again")
		view.close_info()
		view.show_info()
		view.close_info()
		await settle()
		check(not view.overlay.visible, "deferred layout cannot reopen dismissed card")
		if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
			view.show_info()
			await first_visible_size(view)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("../stamina-info-%d.png" % screen.x)
		host.queue_free()
		await settle()
	print("STAMINA_INFO_LAYOUT_" + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
