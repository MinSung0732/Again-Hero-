extends RefCounted

const GUEST := preload("res://src/systems/guest_progress_store.gd")
var lobby: Control
var panel: VBoxContainer
var buttons: Array[Button] = []
var notice: Control

func install(host: Control, parent: Control) -> void:
	lobby = host
	panel = VBoxContainer.new()
	panel.name = "GuestAccountActions"
	panel.add_theme_constant_override("separation", 16)
	parent.add_child(panel)
	parent.move_child(panel, parent.get_node("KakaoLogin").get_index())
	var copy := Label.new()
	copy.text = "게스트 진행도를 새 계정에 저장합니다.\n이미 가입된 계정은 연동할 수 없습니다."
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_size_override("font_size", 24)
	panel.add_child(copy)
	var gateway := lobby.get_node("/root/LoginGateway")
	for item in [["Google", "google"], ["카카오", "kakao"], ["게스트 초기화", "reset"]]:
		var button := Button.new()
		button.name = "Guest_" + String(item[1])
		button.text = String(item[0]) + " 연동" if item[1] != "reset" else String(item[0])
		button.custom_minimum_size.y = 104
		panel.add_child(button)
		lobby._apply_lobby_button_skin(button, item[1] != "reset", 30)
		buttons.append(button)
		button.pressed.connect(_reset_notice if item[1] == "reset" else gateway.begin_guest_link.bind(String(item[1])))
	gateway.guest_link_failed.connect(_failed)
	gateway.authenticated.connect(_linked)
	lobby.tree_exiting.connect(func():
		if gateway.guest_link_failed.is_connected(_failed): gateway.guest_link_failed.disconnect(_failed)
		if gateway.authenticated.is_connected(_linked): gateway.authenticated.disconnect(_linked), CONNECT_ONE_SHOT)
	refresh()

func refresh() -> void:
	panel.visible = GUEST.is_guest()
	var gateway := lobby.get_node("/root/LoginGateway")
	for button in buttons: button.disabled = gateway.guest_link_busy or gateway.withdrawal_busy

func _modal() -> Control:
	if not is_instance_valid(notice):
		notice = preload("res://src/ui/dungeon_entry_notice.gd").new()
		notice.install(lobby)
	return notice

func _failed(message: String) -> void:
	_modal().open(message, "계정 연동 안내")
	refresh()

func blocks_input(event: InputEvent) -> bool:
	return is_instance_valid(notice) and notice.blocks_lobby_input(event)

func _reset_notice() -> void:
	_modal().open_confirmation("게스트 진행도를 초기화하시겠습니까?\n재화·몬스터·연구·프로필이 초기화됩니다.\n구글·카카오 계정의 저장은 변경되지 않습니다.", "게스트 초기화", _reset)

func _reset() -> void:
	if not lobby.get_node("/root/LoginGateway").reset_guest_progress():
		_failed("게스트 저장을 초기화하지 못했습니다. 다시 시도해 주세요.")
		return
	lobby.get_tree().change_scene_to_file("res://src/startup/Startup.tscn")

func _linked() -> void:
	# Reload profile/tutorial/team/wallet from the accepted account namespace.
	lobby.get_tree().call_deferred("change_scene_to_file", "res://src/startup/Startup.tscn")
