extends SceneTree
const CARD := preload("res://src/ui/research_grid_card.gd")
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for width in [640,832,1080,1440]:
		var grid := GridContainer.new()
		grid.columns = 4
		grid.size = Vector2(width,600)
		grid.add_theme_constant_override("h_separation",12)
		grid.add_theme_constant_override("v_separation",12)
		root.add_child(grid)
		for index in 9:
			var button := CARD.create(null,index,70)
			grid.add_child(button)
		for tick in 4: await process_frame
		assert(grid.get_child_count() == 9)
		for index in 9:
			var button := grid.get_child(index) as Button
			assert(button.text.is_empty())
			var rows := button.get_node("CardContent")
			assert(rows.get_child_count() == 2)
			assert(rows.get_child(0) is TextureRect)
			assert(rows.get_node("ResearchLevel").text == "Lv.%d / 70" % index)
			assert(button.get_rect().end.x <= width+1)
			if index >= 4: assert(button.position.y > grid.get_child(index-4).position.y)
			elif index > 0: assert(is_equal_approx(button.position.y,grid.get_child(0).position.y))
		grid.queue_free()
		await process_frame
	print("PASS research cards: 4 columns, 3 rows, icon and rank only")
	quit()
