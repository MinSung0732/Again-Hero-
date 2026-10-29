extends RefCounted

static func populate(panel: Control, event_data: Dictionary, candidates: Array, icon_loader: Callable, name_loader: Callable) -> void:
	panel.get_node("Margin/VBox/Title").text = String(event_data.get("ui_title", "돌연변이 선택"))
	panel.get_node("Margin/VBox/Trigger").text = String(event_data.get("ui_description", "편성 몬스터 1종을 돌연변이로 투입합니다."))
	for index in 3:
		var button: Button = panel.get_node("Margin/VBox/Choices/Choice%d" % index)
		button.visible = index < candidates.size()
		if not button.visible: continue
		var id := String(candidates[index])
		button.text = ""
		button.get_node("Icon").texture = icon_loader.call(id)
		button.get_node("Name").text = name_loader.call(id)
		button.get_node("Select").text = "선택"
