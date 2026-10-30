extends SceneTree
const VIEW := preload("res://src/ui/ranked_leaderboard_view.gd")
const DATA := preload("res://src/data/ranked_leaderboard_catalog.gd")
var failed := false
class Host extends Control:
	var other_tab: Control
	var main_modes_view: RefCounted
class Settings extends RefCounted:
	var lobby: Control
	func _title_plate(parent: Control, label: Label) -> PanelContainer:
		var plate := PanelContainer.new()
		parent.add_child(plate)
		plate.add_child(label)
		return plate
class FakeCloud extends Node:
	signal release
	var calls := 0
	func request_optional_rpc(_method: String, args: Dictionary) -> Dictionary:
		calls += 1
		await release
		var rows := []
		for i in range(int(args.page_offset), mini(int(args.page_offset) + int(args.page_size), DATA.LOCAL_COUNT)):
			rows.append({"rank": i + 1, "nickname": "test", "mmr": 1000, "tier": ""})
		return {"rows": rows}
func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var mode := root.get_node("LocalTestMode")
	var previous: bool = mode.active
	mode.active = true
	var host := Host.new()
	root.add_child(host)
	host.other_tab = Control.new()
	host.other_tab.size = Vector2(800, 1000)
	root.add_child(host.other_tab)
	var box := VBoxContainer.new()
	box.size = Vector2(800, 700)
	host.other_tab.add_child(box)
	var settings := Settings.new()
	settings.lobby = host
	var view := VIEW.new()
	view.install(settings, box)
	view.show()
	await process_frame
	check(view.caches.hero.rows.size() == 10, "first page")
	view._load_next()
	view._load_next()
	check(view.caches.hero.rows.size() == 30, "successive pages append")
	view._load_next()
	view._load_next()
	check(view.caches.hero.rows.size() == 35 and view.caches.hero.end, "end of feed")
	check(view.status.text == DATA.END, "end indicator")
	view.select_role("demon")
	check(view.caches.demon.rows.size() == 10, "other role first page")
	view.select_role("hero")
	check(view.caches.hero.rows.size() == 35, "role cache preserved")
	var line = view.pool[0]
	view.scroll.scroll_vertical = 200
	view._render()
	check(view.my_line.get_parent() == view.root and view.my_line.get_parent() != view.scroll, "my rank fixed outside scroll")
	view.refresh()
	check(view.caches.hero.rows.size() == 10 and view.pool[0] == line and view.pool.size() == DATA.POOL_SIZE, "refresh and row reuse")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(10, 10)
	view._on_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.position = Vector2(10, 10 + DATA.PULL_DISTANCE + 1)
	view._on_input(drag)
	check(view.caches.hero.rows.size() == 10 and not view.caches.hero.end, "pull refresh resets feed")
	var gateway := root.get_node("LoginGateway")
	var old_user: String = gateway.user_id
	mode.active = false
	gateway.user_id = "test"
	view.owner_id = "test"
	var fake := FakeCloud.new()
	host.add_child(fake)
	view.cloud_override = fake
	view.refresh()
	view._load_next()
	check(fake.calls == 1, "in-flight page requested once")
	fake.release.emit()
	check(view.caches.hero.rows.size() == 10, "async first page")
	var bar := view.scroll.get_v_scroll_bar()
	bar.max_value = 1000
	bar.page = 100
	bar.value = 900
	view._on_scroll(900)
	view._on_scroll(900)
	check(fake.calls == 2, "next page requested once")
	fake.release.emit()
	check(view.caches.hero.rows.size() == 20, "async second page appended")
	gateway.user_id = old_user
	view.hide()
	host.other_tab.queue_free()
	host.queue_free()
	mode.active = previous
	print("ranked leaderboard smoke: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
