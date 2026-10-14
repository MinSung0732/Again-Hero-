extends SceneTree
const VIEW := preload("res://src/ui/hero_result_view.gd")
class Weapons extends RefCounted:
	var weapon_ids: Array = VIEW.DETAIL.DATA.weapon_pool("ranged_rookie").slice(0,6)
	var evolved := {}
	var levels := {}
	func _init():
		for id in weapon_ids: levels[id] = 10; evolved[id] = true
class Hero extends RefCounted:
	var level := 40
	var player_weapons := Weapons.new()
class Metrics extends RefCounted:
	var elapsed_seconds := 925.0
class Battle extends RefCounted:
	var hero := Hero.new()
	var run_metrics := Metrics.new()
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok,label):
	checks += 1
	if not ok: failures += 1; push_error(label)
func click(point):
	var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.position = point; e.pressed = true
	Input.parse_input_event(e); Input.flush_buffered_events()
	e = e.duplicate(); e.pressed = false; Input.parse_input_event(e); Input.flush_buffered_events()
func run():
	for viewport in [Vector2i(1080,1920),Vector2i(540,960),Vector2i(1920,1080),Vector2i(960,540)]:
		root.size = viewport
		for won in [true,false]:
			var host = load("res://tests/hero_result_binding_harness.gd").new(); root.add_child(host); host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			host.battle = Battle.new(); host.finished_won = won; host.finished_message = "최종 보스를 처치했습니다!" if won else "용사가 쓰러졌습니다. 다른 조합으로 다시 도전하세요."
			await process_frame
			host.STORE.calls = 0; host.STORE.fail = true; host._show_result()
			await process_frame; await process_frame
			check(not host.settled and host.overlay_rows.find_child("ResultSettle",true,false) != null,"save failure offers retry")
			check(host.overlay_rows.find_child("ResultLobby",true,false) == null and host.overlay_rows.find_child("ResultRetry",true,false) == null,"failed settlement blocks navigation")
			host.STORE.fail = false; host._show_result(); host._show_result()
			await process_frame; await process_frame; await process_frame
			check(host.STORE.calls == 2 and host.settled,"redraw preserves award and does not re-award")
			var amounts = host.overlay_rows.find_children("RewardAmount","Label",true,false)
			check(amounts.size() == 2 and amounts[0].text == ("+100" if won else "+5") and amounts[1].text == ("+60" if won else "+3"),"actual reward retained after redraw")
			check(host.overlay_rows.get_child(0).text == ("용사 승리!" if won else "용사 패배"),"victory and defeat distinct")
			check(host.overlay_rows.find_child("ResultWeapons",true,false).get_child_count() == 6,"six real equipped weapon icons")
			check((host.overlay_rows.find_child("ResultNext",true,false) != null) == won,"next stage only for victory")
			var rect: Rect2 = host.overlay.get_global_rect()
			check(rect.position.x >= 0 and rect.end.x <= viewport.x and rect.position.y >= 0 and rect.end.y <= viewport.y,"result stays inside viewport")
			check(host.overlay_rows.get_node("ResultScroll").size.y >= 30,"result scroll remains usable")
			for name in ["ResultRetry","ResultLobby"]:
				var target = host.overlay_rows.find_child(name,true,false)
				check(target.get_global_rect().end.y <= viewport.y and target.size.y >= 76,"action accessible "+name)
				click(target.get_global_rect().get_center()); await process_frame
				check(host.last_action == ("retry" if name == "ResultRetry" else "leave"),"real mouse action "+name)
			if won:
				var next = host.overlay_rows.find_child("ResultNext",true,false)
				var touch := InputEventScreenTouch.new(); touch.index = 1; touch.position = next.get_global_rect().get_center(); touch.pressed = true
				Input.parse_input_event(touch); Input.flush_buffered_events(); await process_frame
				touch = touch.duplicate(); touch.pressed = false; Input.parse_input_event(touch); Input.flush_buffered_events(); await process_frame
				check(host.last_action == "next","touch next stage action")
			host.queue_free(); await process_frame
	var last = load("res://tests/hero_result_binding_harness.gd").new(); root.add_child(last); last.size = Vector2(1080,1920); last.battle = Battle.new()
	last.STAGES.next_id = ""; last._show_result(); await process_frame; await process_frame
	check(last.overlay_rows.find_child("ResultNext",true,false) == null,"final stage has no unavailable next button")
	last.queue_free(); await process_frame
	print("HERO_RESULT checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
