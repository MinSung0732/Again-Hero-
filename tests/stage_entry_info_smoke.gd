extends SceneTree
const VIEW := preload("res://src/ui/stage_entry_info_view.gd")
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for dimensions in [Vector2(280,220),Vector2(360,300),Vector2(560,360),Vector2(900,600)]:
		var host := Control.new()
		host.size = dimensions
		root.add_child(host)
		var description := Label.new()
		var reward := Label.new()
		var status := Label.new()
		var repeat := Label.new()
		for label in [description,reward,status]:
			host.add_child(label)
			label.grow_vertical = Control.GROW_DIRECTION_BOTH
		var button := Button.new()
		host.add_child(button)
		var modes := VIEW.install(host,description,reward,status,repeat,button)
		var selector := Button.new()
		selector.text = "마왕 · 용사 · 랭킹"
		modes.add_child(selector)
		description.text = "원거리 마법탄 · 레벨업마다 전투 기회 획득\n긴 설명도 아래 보상과 겹치지 않아야 합니다."
		reward.text = "최초 보상\n골드 +1000 · 연구 +4500\n몬스터 · 사티로스 주술사"
		status.text = "클리어 완료 · 제한 3분"
		repeat.text = "반복 보상 ×1.00"
		for tick in 4: await process_frame
		var scroll := host.get_node("StageEntryLayout").get_child(0).get_child(0) as ScrollContainer
		assert(scroll.get_global_rect().end.y <= button.global_position.y)
		assert(button.get_global_rect().end.y <= modes.global_position.y)
		assert(modes.get_global_rect().end.y <= host.get_global_rect().end.y+1)
		assert(description.get_global_rect().end.y <= reward.global_position.y)
		for label in [reward,status,repeat]:
			assert(not label.clip_text and label.max_lines_visible == -1)
			assert(label.get_global_rect().position.x >= scroll.global_position.x)
			assert(label.get_global_rect().end.x <= scroll.get_global_rect().end.x+1)
		if dimensions.x == 560:
			# 540x960 window's logical stage card: all ordinary text must fit.
			assert(repeat.get_global_rect().end.y <= scroll.get_global_rect().end.y+1)
		var fixed_button := button.get_global_rect()
		scroll.scroll_vertical = 10000
		for tick in 2: await process_frame
		assert(button.get_global_rect() == fixed_button)
		host.queue_free()
		await process_frame
	print("PASS stage entry info layout")
	quit()
