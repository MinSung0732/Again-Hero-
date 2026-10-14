extends SceneTree
const NOTICE := preload("res://src/ui/stamina_notice.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func run() -> void:
	var host := Control.new(); root.add_child(host)
	host.size = Vector2(540,960)
	var results := VBoxContainer.new(); host.add_child(results)
	for text in ["승리 결과","재도전","로비로"]:
		var button := Button.new(); button.text = text; button.custom_minimum_size.y = 84; results.add_child(button)
	await process_frame
	var positions: Array[Vector2] = []
	for child in results.get_children(): positions.append(child.position)
	var panel := NOTICE.show_notice(host,NOTICE.INSUFFICIENT)
	for index in range(100):
		panel.hide()
		check(NOTICE.show_notice(host,NOTICE.INSUFFICIENT) == panel,"same popup reused")
		check(results.get_child_count() == 3 and host.get_child_count() == 2,"no result row or modal growth")
		check(panel.dialog_text == NOTICE.INSUFFICIENT,"single current message")
		check(NOTICE.show_notice(host,"저장을 확인하고 다시 시도하세요.") == panel,"visible popup text replaces")
	await process_frame
	for index in range(3): check(results.get_child(index).position == positions[index],"result buttons retain positions")
	check(panel.exclusive and panel.get_ok_button().custom_minimum_size.y >= 84,"modal blocks underlying input and has touch target")
	panel.hide(); host.queue_free(); await process_frame
	print("STAMINA_NOTICE failures=",failures); quit(1 if failures else 0)
