extends SceneTree
const VIEW := preload("res://src/ui/stage_entry_info_view.gd")
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for width in [280,360,640,900]:
		var host := Control.new()
		host.size = Vector2(width,480)
		root.add_child(host)
		var reward := Label.new()
		var status := Label.new()
		var repeat := Label.new()
		host.add_child(reward)
		host.add_child(status)
		var button := Button.new()
		button.position = Vector2(16,330)
		button.size = Vector2(width-32,76)
		host.add_child(button)
		VIEW.install(host,reward,status,repeat,button)
		reward.text = "최초 보상\n골드 +1000\n연구 +4500\n몬스터 · 사티로스 주술사"
		status.text = "클리어 완료\n시간 제한 없음"
		repeat.text = "반복 도전\n최초 보상은 1회 지급"
		await process_frame
		await process_frame
		var original := button.get_rect()
		var scroll := host.get_node("StageEntryInfo") as ScrollContainer
		assert(button.get_rect() == original)
		assert(scroll.get_rect().end.y < button.position.y)
		for label in [reward,status,repeat]:
			assert(not label.clip_text)
			assert(label.max_lines_visible == -1)
			assert(label.get_global_rect().position.x >= scroll.global_position.x)
			assert(label.get_global_rect().end.x <= scroll.get_global_rect().end.x+1)
		scroll.scroll_vertical = 10000
		await process_frame
		assert(button.get_rect() == original)
		host.queue_free()
		await process_frame
	print("PASS stage entry info layout")
	quit()
