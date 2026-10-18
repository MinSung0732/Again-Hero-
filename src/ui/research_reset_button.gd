extends Button
const STORE := preload("res://src/systems/research_respec_store.gd")
var mode := "demon"
var completed: Callable
var dialog: ConfirmationDialog
var expected_owner := ""
static func create(kind: String,callback: Callable) -> Button:
	var button = load("res://src/ui/research_reset_button.gd").new()
	button.mode = kind; button.completed = callback
	button.text = "연구 초기화"
	button.custom_minimum_size = Vector2(180,72)
	button.add_theme_font_size_override("font_size",24)
	button.pressed.connect(button.open)
	button.refresh()
	return button
func refresh() -> void:
	var state := STORE.preview(mode)
	disabled = not bool(state.success) or int(state.refund) <= 0
func open() -> void:
	var state := STORE.preview(mode)
	if not bool(state.success): return
	expected_owner = String(state.owner)
	if not is_instance_valid(dialog):
		dialog = ConfirmationDialog.new(); dialog.title = "연구 초기화"
		dialog.exclusive = true; dialog.dialog_autowrap = true
		dialog.ok_button_text = "초기화 및 환급"; dialog.cancel_button_text = "취소"
		dialog.get_label().add_theme_font_size_override("font_size",28)
		for button in [dialog.get_ok_button(),dialog.get_cancel_button()]:
			button.custom_minimum_size.y = 76; button.add_theme_font_size_override("font_size",26)
		add_child(dialog); dialog.confirmed.connect(_reset)
	dialog.dialog_text = "%s 연구를 모두 초기화할까요?\n\n환급: %s P · 수수료 없음\n포인트를 돌려받아 다시 배분할 수 있습니다.\n이전 사용액 기록이 없으면 현재 단계별 비용으로 계산합니다." % ["마왕" if mode == "demon" else "용사",str(int(state.refund))]
	dialog.popup_centered(Vector2i(mini(780,maxi(280,int(get_viewport_rect().size.x)-64)),360))
func _reset() -> void:
	var result := STORE.reset(mode,expected_owner)
	refresh()
	if completed.is_valid(): completed.call(result)
