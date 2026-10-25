extends SceneTree
const VIEW := preload("res://src/ui/augment_compare_view.gd")
const CARDS := preload("res://src/ui/hero_augment_cards_view.gd")
var failed := false
var checks := 0
var selected := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed = true; push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size = Vector2i(1080,1920)
	var rows: Array = [{"label":"변화 없음","current":"10","next":"10"},{"label":"미사용","current":"없음","next":"0%"}]
	for i in 7: rows.append({"label":"항목%d" % i,"current":"없음","next":str(i+1)})
	var host := HBoxContainer.new(); root.add_child(host); host.size = Vector2(900,500)
	var candidate := {"id":"test","name":"아주 긴 증강 이름입니다","description":"긴 설명입니다. ".repeat(30),"compare":rows}
	var card: Button = CARDS.create(host,candidate,func(): selected += 1)
	for i in 2: CARDS.create(host,candidate,func(): selected += 1)
	var label := card.get_node("MarginContainer/VBoxContainer/AugmentCompare") as RichTextLabel
	check(label.text.split("\n").size() == 4,"card has at most four rows")
	check(not label.text.contains("변화 없음") and not label.text.contains("미사용"),"unchanged and zero acquisition hidden")
	check(label.text.contains("신규") and not label.text.contains("없음"),"acquisition shows starting values")
	var details := card.get_node("MarginContainer/VBoxContainer/AugmentDetails") as Button
	check(details.mouse_filter == Control.MOUSE_FILTER_STOP,"details consumes card input")
	await process_frame
	await process_frame
	check(details.get_global_rect().end.y <= card.get_global_rect().end.y,"details stays inside card")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = details.get_global_rect().get_center()
	click.pressed = true
	root.push_input(click,true)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click,true)
	await process_frame
	check(selected == 0,"details does not select augment")
	if details.get_child_count() == 0:
		check(false,"details click opens modal"); quit(1); return
	var dialog := details.get_child(0) as PopupPanel
	check(dialog != null and dialog.visible,"details opens modal")
	var body := dialog.get_node("Content/Body") as RichTextLabel
	check(body != null and body.text.contains("항목6") and body.text.contains("긴 설명"),"details contains full description and all meaningful stats")
	check(dialog.process_mode == Node.PROCESS_MODE_ALWAYS,"details works during solo pause")
	check(dialog.get_theme_stylebox("panel") is StyleBoxTexture,"details uses shared pixel panel")
	var close := dialog.get_node("Content/Close") as Button
	check(close.custom_minimum_size.y == 84,"close uses mobile touch size")
	check(dialog.exclusive and dialog.theme != null,"details uses game theme and modal input")
	await process_frame
	check(body.size.y > 0 and body.scroll_active,"body has a scrollable content area")
	check(close.get_global_rect().position.y >= body.get_global_rect().end.y,"close does not overlap content")
	check(dialog.size.x <= root.size.x and dialog.size.y <= root.size.y,"modal fits viewport")
	close.pressed.emit()
	await process_frame
	check(details.get_child_count() == 0,"closed details is freed")
	VIEW.update(label,[{"label":"피해","current":"10","next":"12"}])
	check(label.text.contains("10 →") and label.text.contains("12"),"upgrade preserves comparison")
	check(VIEW.meaningful_rows([{"current":"없음","next":"0초"},{"current":"없음","next":"0개"}]).is_empty(),"unit zero values hidden")
	host.queue_free()
	print("AUGMENT_CARD_DETAILS_", "FAIL" if failed else "PASS", " checks=",checks)
	quit(1 if failed else 0)
