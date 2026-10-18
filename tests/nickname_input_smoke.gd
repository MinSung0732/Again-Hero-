extends SceneTree
const PROFILE := preload("res://src/systems/player_profile.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const GUEST := preload("res://src/systems/guest_progress_store.gd")
const RULES := preload("res://src/data/nickname_catalog.gd")
const EDIT := preload("res://src/ui/nickname_line_edit.gd")
const PROLOGUE := preload("res://src/ui/player_prologue.gd")
const DATA := preload("res://src/data/prologue_catalog.gd")
const PROFILE_VIEW := preload("res://src/ui/lobby_profile_view.gd")
var checks := 0
var failed := false

class Lobby extends Control:
	var other_tab: Control

class Settings extends RefCounted:
	var lobby: Control
	func _title_plate(parent: Control, title: Label) -> PanelContainer:
		var plate := PanelContainer.new(); parent.add_child(plate); plate.add_child(title)
		return plate

class Cloud extends Node:
	var available := true
	var duplicate_on_save := false
	var writes := 0
	var calls := 0
	func request_rpc(method: String, data: Dictionary) -> Dictionary:
		calls += 1
		await get_tree().process_frame
		await get_tree().process_frame
		if method == "check_player_nickname": return {"ok": true,"available":available}
		writes += 1
		if duplicate_on_save: return {"ok":false,"error":"duplicate"}
		return {"ok":true,"profile":{"nickname":data.chosen_name,"gender":"male","required":false,"completed":true,"nickname_changes_remaining":0}}

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed = true; push_error(message)

func _initialize() -> void: call_deferred("run")

func uuid() -> String:
	var h := Crypto.new().generate_random_bytes(16).hex_encode()
	return "%s-%s-%s-%s-%s" % [h.substr(0,8),h.substr(8,4),h.substr(12,4),h.substr(16,4),h.substr(20,12)]

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func run() -> void:
	root.size = Vector2i(540,960)
	root.content_scale_size = Vector2i(1080,1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	for value in ["", "왕", "1234567", "ㄱㄴ", "가 나", "가!", "가나\n"]: check(not PROFILE.valid_name(value),"reject "+value)
	for value in ["마왕", "민성", "가나다라마바", "Ab12cd"]: check(PROFILE.valid_name(value),"valid "+value)
	for i in 100: check(PROFILE.valid_name(PROFILE.random_name()),"random within policy")
	var input := EDIT.new(); root.add_child(input)
	check(input.max_length == 0,"IME composing buffer has no premature length truncation")
	input.text = "가"; input.caret_column = 0; input._text_committed(input.text)
	await settle()
	check(input.text == "가" and input.caret_column == 1,"repair stale caret after committed Korean insertion")
	input.insert_text_at_caret("나"); input._text_committed(input.text)
	await settle()
	check(input.text == "가나" and input.caret_column == 2,"next Korean character appends without arrow")
	input.caret_column = 1
	input.insert_text_at_caret("다"); input._text_committed(input.text)
	await settle()
	check(input.text == "가다나" and input.caret_column == 2,"mid-text insertion preserves caret instead of forcing end")
	input.set_generated_name("")
	input.text = "마"; input.caret_column = 0; input._text_committed(input.text)
	var left := InputEventKey.new(); left.pressed=true; left.keycode=KEY_LEFT
	input.gui_input.emit(left)
	await settle()
	check(input.caret_column==0,"manual arrow navigation cancels pending stale-caret repair")
	input.set_generated_name("달빛마왕7")
	check(input.caret_column == input.text.length() and input.committed_name()=="달빛마왕7","generated/committed input includes all characters")
	input.queue_free()
	SCOPE.guest_directory = "user://nickname_guest_"+uuid()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var cloud := Cloud.new(); root.add_child(cloud)
	var result := await PROFILE.refresh(cloud)
	check(result.ok and not PROFILE.needs_prologue(result.profile) and PROFILE.valid_name(result.profile.nickname),"guest starts random with no naming/prologue gate")
	var guest_name: String = result.profile.nickname
	result = await PROFILE.refresh(cloud)
	check(result.profile.nickname == guest_name and cloud.calls == 0,"guest name persists without server calls")
	check(not PROFILE.can_rename(),"guest cannot use account rename")
	check(SCOPE.select_account(uuid()),"isolated account")
	var view := PROLOGUE.new(); view.cloud = cloud; root.add_child(view)
	for i in DATA.LINES.size():
		if DATA.LINES[i].get("kind","") == "name": view.index = i; break
	view._show_line()
	view.name_input.set_generated_name("마왕")
	check(view.confirm.disabled,"unverified name cannot confirm")
	await view._check_name()
	check(not view.confirm.disabled,"available name enables confirm")
	view.name_input.set_generated_name("새이름")
	check(view.confirm.disabled,"editing invalidates duplicate result")
	view._check_name()
	view.name_input.set_generated_name("다른이름")
	await settle()
	check(view.confirm.disabled,"late availability response cannot approve changed input")
	cloud.available = false
	await view._check_name()
	check(view.confirm.disabled and view.error_label.text.contains("이미"),"duplicate blocks confirmation")
	cloud.available = true
	await view._check_name()
	cloud.duplicate_on_save = true
	await view._register_name()
	check(view.name_input.editable and view.confirm.disabled and view.error_label.text.contains("이미"),"server race rejection keeps editable without approval")
	cloud.duplicate_on_save = false
	await view._check_name()
	await view._register_name()
	check(PROFILE.get_profile().nickname == "다른이름","checked name saved")
	view.queue_free(); await settle()
	var p := PROFILE.get_profile(); p.nickname_changes_remaining = RULES.LINKED_RENAMES
	PROFILE._store_response({"ok":true,"profile":p})
	check(PROFILE.can_rename(),"linked allowance shown")
	var host := Lobby.new(); root.add_child(host); host.other_tab = Control.new(); host.add_child(host.other_tab)
	var settings := Settings.new(); settings.lobby=host
	var profile_view := PROFILE_VIEW.new(); profile_view.install(settings,host.other_tab); profile_view.refresh()
	check(profile_view.rename_button.visible and not profile_view.rename_button.disabled,"actual profile page exposes linked rename action")
	profile_view._open_name_change()
	var opened: Control
	for child in host.get_children():
		if child is PROLOGUE: opened = child
	check(opened != null and opened.rename_only and is_instance_valid(opened.name_input),"actual profile action opens shared name-only editor")
	host.queue_free(); await settle()
	var rename := PROLOGUE.new(); rename.cloud=cloud; rename.rename_only=true; root.add_child(rename)
	var done := [false]; rename.finished.connect(func():done[0]=true)
	rename.name_input.set_generated_name("연동마왕")
	await rename._check_name()
	await rename._register_name()
	check(done[0] and PROFILE.get_profile().nickname=="연동마왕" and not PROFILE.can_rename(),"rename-only editor finishes and consumes allowance")
	rename.queue_free(); cloud.queue_free(); await settle()
	SCOPE.select_guest()
	print("NICKNAME_INPUT_SMOKE checks=",checks," ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
