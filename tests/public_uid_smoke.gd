extends SceneTree
const UID := preload("res://src/data/public_uid_catalog.gd")
const PROFILE := preload("res://src/ui/lobby_profile_view.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const MODES := preload("res://src/ui/lobby_main_modes_view.gd")
class Host extends Control:
	var panel_style := StyleBoxFlat.new()
	func _apply_lobby_button_skin(_button: Button, _primary: bool, _size: int) -> void: pass
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	assert(UID.format_uid("12345678") == "UID 1234-5678")
	assert(UID.format_uid("bad").is_empty())
	var host := Host.new()
	root.add_child(host)
	var view := PROFILE.new()
	view.lobby = host
	view.uid_label = Label.new()
	view.uid_copy = Button.new()
	host.add_child(view.uid_label)
	host.add_child(view.uid_copy)
	var gateway = root.get_node("LoginGateway")
	var mode = root.get_node("LocalTestMode")
	var old_id: String = gateway.user_id
	var old_local: bool = mode.active
	gateway.user_id = ""
	mode.active = false
	view._refresh_uid()
	assert(view.uid_label.text == UID.GUEST and not view.uid_copy.visible)
	mode.active = true
	view._refresh_uid()
	assert(view.uid_label.text == "UID 0000-0001" and view.uid_copy.visible)
	var modes := MODES.new()
	modes.lobby = host
	assert(not modes.guest_rank_blocked())
	mode.active = false
	assert(modes.guest_rank_blocked())
	modes.toggle_ranked()
	assert(not modes.ranked and host.has_node("GuestRankNoticeLayer/GuestRankNotice"))
	var account := "00000000-0000-0000-0000-000000000001"
	assert(SCOPE.select_account(account))
	gateway.user_id = account
	gateway._public_uids[account] = "12345678"
	view._refresh_uid()
	assert(view.uid_label.text == "UID 1234-5678" and view.uid_copy.visible)
	assert(not modes.guest_rank_blocked())
	SCOPE.select_guest()
	mode.active = old_local
	gateway.user_id = old_id
	host.queue_free()
	quit()
