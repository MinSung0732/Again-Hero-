extends SceneTree
const VIEW := preload("res://src/ui/stage_entry_info_view.gd")
const COPY := preload("res://src/data/stage_entry_copy_catalog.gd")
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for dimensions in [Vector2(360,440),Vector2(560,400),Vector2(640,440),Vector2(900,540)]:
		var host := Control.new()
		host.size = dimensions
		root.add_child(host)
		var description := Label.new()
		var reward := Label.new()
		var status := Label.new()
		var repeat := Label.new()
		for label in [description,reward,status]: host.add_child(label)
		var button := Button.new()
		host.add_child(button)
		var modes := VIEW.install(host,description,reward,status,repeat,button)
		var selector := Button.new()
		selector.text = "마왕 · 용사 · 랭킹"
		modes.add_child(selector)
		for stage in 10:
			description.text = COPY.summary("stage_%d" % (stage+1))
			reward.text = "최초 보상\n골드 +1000\n연구 +4500\n해골 궁수"
			status.text = "입장 가능\n15분 도전"
			repeat.text = "반복 보상\n×1.60"
			for tick in 4: await process_frame
			var layout := host.get_node("StageEntryLayout").get_child(0)
			var grid := layout.get_node("StageInfoGrid") as HBoxContainer
			assert(grid.get_child_count() == 3)
			assert(description.get_global_rect().end.y <= grid.global_position.y)
			assert(grid.get_global_rect().end.y <= button.global_position.y)
			assert(button.get_global_rect().end.y <= modes.global_position.y)
			assert(modes.get_global_rect().end.y <= host.get_global_rect().end.y+1)
			for label in [status,reward,repeat]:
				var panel := label.get_parent().get_parent() as PanelContainer
				assert(not label.clip_text and label.max_lines_visible == -1)
				assert(panel.get_global_rect().encloses(label.get_global_rect()))
			host.size = dimensions
		host.queue_free()
		await process_frame
	print("PASS stage info three cells / 10 summaries")
	quit()
