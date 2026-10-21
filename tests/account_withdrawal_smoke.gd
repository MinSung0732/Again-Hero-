extends SceneTree
## Actual cloud/login scripts with network/vault/scope fixtures. No real accounts.
var checks := 0
var failures := 0
var cloud: Node
var gateway: Node
var scope: GDScript
var fixture_paths: Array[String] = []
class Transition extends Node:
	func cancel() -> void: pass
class TestMode extends Node:
	var active := false
	var tutorial_preview := false
	var pending_reset_id := ""
	func reset_progress() -> bool: return true
	func persist() -> bool: return true
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func fixture(name: String, source: String) -> String:
	var path := "user://withdrawal-smoke-" + name + ".gd"
	fixture_paths.append(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(source)
	file.close()
	return path
func script(source: String, label: String) -> GDScript:
	var result := GDScript.new()
	result.source_code = source
	check(result.reload() == OK, label)
	return result
func method(source: String, name: String) -> String:
	var start := source.find("func " + name + "(")
	assert(start >= 0)
	var end := source.find("\nfunc ", start + 1)
	return source.substr(start) if end < 0 else source.substr(start, end-start) + "\n"
func set_account() -> void:
	cloud.stop()
	scope.pending_cloud = {}
	gateway.user_id = "fixture-account"
	gateway.access_token = "fixture-token"
	gateway._refresh_token = "fixture-refresh"
	gateway.account_provider = "google"
	gateway.account_label = "test"
	scope.user_id = "fixture-account"
	scope.dirty = false
	cloud.ready_for_play = true
	cloud.conflict = false
	cloud.calls.clear()
	cloud.replies.clear()
func run() -> void:
	var scope_path := fixture("scope", "extends RefCounted\nstatic var user_id := \"\"\nstatic var dirty := false\nstatic var revision := 1\nstatic var serial := 0\nstatic var files := {}\nstatic var saved_callback: Callable\nstatic var write_allowed: Callable\nstatic var pending_cloud := {}\nstatic var guest_directory := String()\nstatic func select_account(id: String) -> bool: user_id = id; return true\nstatic func select_guest() -> void: user_id = \"\"\nstatic func valid_payload(_value: Variant) -> bool: return true\nstatic func install(_value: Variant, version: int) -> bool: revision = version; dirty = false; return true\nstatic func persist() -> int: return OK\n")
	var oauth_path := fixture("oauth", "extends Node\nsignal notice(message: String)\nsignal validated(session: Dictionary, user: Dictionary)\nvar cancelled := false\nfunc cancel() -> void: cancelled = true\nfunc begin(_provider: String) -> void: pass\nfunc request_json(_path: String, _data: Variant, _token: String = \"\") -> Dictionary: return {}\n")
	var vault_path := fixture("vault", "extends Node\nvar clears := 0\nfunc clear_session() -> bool: clears += 1; return true\nfunc save_session(_id: String, _token: String) -> bool: return true\nfunc read_session() -> Dictionary: return {}\n")
	var config_path := fixture("config", "extends RefCounted\nconst PROJECT_URL := \"https://fixture.invalid\"\nconst PUBLISHABLE_KEY := \"fixture-public-key\"\n")
	scope = load(scope_path)
	var cloud_source := FileAccess.get_file_as_string("res://src/network/cloud_store.gd").replace("\r", "").replace("res://src/systems/account_save_scope.gd", scope_path).replace("res://src/network/supabase_config.gd", config_path)
	# Replace only HTTP transport; retain complete initialize/flush/withdraw logic.
	cloud_source = cloud_source.replace(method(cloud_source, "request_rpc"), "func request_rpc(name: String, _data: Dictionary) -> Dictionary:\n\tcalls.append(name)\n\tif slow_reply: await get_tree().process_frame\n\treturn replies.pop_front() if not replies.is_empty() else {}\n\n")
	cloud_source += "\nvar calls: Array[String] = []\nvar replies: Array[Dictionary] = []\nvar slow_reply := false\n"
	var cloud_script := script(cloud_source, "complete cloud logic compiles")
	var guest_path := fixture("guest", "extends RefCounted\nstatic func ensure_available() -> bool: return true\nstatic func is_guest() -> bool: return false\nstatic func capture() -> Dictionary: return {}\nstatic func reset() -> bool: return true\nstatic func mark_consumed(_folder: String, _guest: String, _account: String) -> bool: return true\n")
	var login_source := FileAccess.get_file_as_string("res://src/network/login_gateway.gd").replace("\r", "").replace("res://src/systems/account_save_scope.gd",scope_path).replace("res://src/network/windows_oauth.gd",oauth_path).replace("res://src/network/session_vault.gd",vault_path).replace("res://src/systems/guest_progress_store.gd",guest_path)
	var login_script := script(login_source, "complete login logic compiles")
	if failures > 0: quit(1); return
	# Project autoloads exist in --script runs; replace them so /root/<Name>
	# resolves to these fixtures instead of auto-renamed duplicates.
	root.get_node("CloudConnectionOverlay").free()
	root.get_node("CloudStore").stop()
	for autoload in ["LoginGateway", "CloudStore", "LocalTestMode", "SceneTransition"]:
		var real := root.get_node(autoload)
		root.remove_child(real)
		real.free()
	var transition := Transition.new()
	transition.name = "SceneTransition"
	root.add_child(transition)
	var mode := TestMode.new()
	mode.name = "LocalTestMode"
	root.add_child(mode)
	cloud = cloud_script.new()
	cloud.name = "CloudStore"
	root.add_child(cloud)
	gateway = login_script.new()
	gateway.name = "LoginGateway"
	root.add_child(gateway)
	set_account()
	mode.active = true
	check(not await gateway.withdraw_account() and cloud.calls.is_empty(), "local test cannot withdraw")
	mode.active = false
	mode.tutorial_preview = true
	check(not await gateway.withdraw_account(), "tutorial test cannot withdraw")
	mode.tutorial_preview = false
	gateway.user_id = ""
	check(not await gateway.withdraw_account(), "guest cannot withdraw")
	set_account()
	cloud.conflict = true
	check(not await gateway.withdraw_account() and not gateway.user_id.is_empty(), "conflict does not clear account")
	set_account()
	cloud.replies.assign([{}, {}])
	check(not await gateway.withdraw_account() and gateway.user_id == "fixture-account", "network failure retains account")
	check(not gateway.withdrawal_busy and not cloud.busy, "failure releases locks")
	set_account()
	scope.dirty = true
	cloud.replies.assign([{"ok":true,"revision":2}, {"ok":true,"inactive":true,"delete_after":"fixture"}])
	gateway.remember_session_enabled = false
	var clears: int = gateway._vault.clears
	check(await gateway.withdraw_account(), "successful withdrawal")
	check(cloud.calls == ["cloud_sync", "request_account_withdrawal"], "save precedes withdrawal")
	check(gateway.user_id.is_empty() and gateway.access_token.is_empty() and gateway._refresh_token.is_empty(), "memory session cleared")
	check(gateway._vault.clears == clears+1, "vault cleared even when remember disabled")
	check(not cloud.ready_for_play and cloud._timer.is_stopped() and scope.user_id.is_empty(), "cloud stopped and guest scope selected")
	set_account()
	cloud.replies.assign([{}, {"active":false,"inactive":true,"delete_after":"fixture"}])
	check(await gateway.withdraw_account() and gateway.user_id.is_empty(), "lost commit response resolved by server status")
	set_account()
	cloud.replies.assign([{"inactive":true}])
	check(not await cloud.initialize() and gateway.user_id.is_empty(), "inactive login cleared")
	check(cloud.calls == ["cloud_sync"], "inactive login never reads game save")
	set_account()
	cloud.replies.assign([{}])
	check(not await cloud.initialize() and cloud.calls.size() == 1, "unknown lifecycle fails closed")
	set_account()
	cloud.replies.assign([{"ok":true}, {"found":true,"revision":2,"payload":{}}])
	check(await cloud.initialize() and cloud.ready_for_play, "active login still loads normally")
	set_account()
	scope.dirty = true
	cloud.replies.assign([{"inactive":true}])
	check(not await cloud.flush() and gateway.user_id.is_empty(), "another device withdrawal clears failed save session")
	set_account()
	cloud.slow_reply = true
	cloud.replies.assign([{"ok":true,"inactive":true}])
	gateway.withdraw_account()
	check(gateway.withdrawal_busy, "in-flight withdrawal locked")
	check(not await gateway.withdraw_account(), "double click rejected")
	await process_frame
	await process_frame
	check(not gateway.withdrawal_busy and gateway.user_id.is_empty(), "async completion clears lock/session")
	cloud.slow_reply = false
	# Compile/execute actual codex guard and direct preview method with a data fixture.
	var codex_source := FileAccess.get_file_as_string("res://src/ui/lobby_demon_codex_view.gd").replace("\r", "")
	var collection_path := fixture("collection", "extends RefCounted\nstatic var state := {}\nstatic func load_state() -> Dictionary: return state\nstatic func is_unlocked(id: String, data: Dictionary) -> bool: return data.get(id,{}).get(\"owned\",false)\nstatic func get_upgrade_level(id: String, data: Dictionary) -> int: return data.get(id,{}).get(\"level\",0)\n")
	var monster_path := fixture("monsters", "extends RefCounted\nstatic func get_monster_name(id: String) -> String: return id\n")
	var data_path := fixture("data", "extends RefCounted\nconst MONSTERS = preload(\""+monster_path+"\")\nstatic func artwork(_id: String, _kind: String) -> String: return \"fixture\"\n")
	var codex := script("extends RefCounted\nconst COLLECTION = preload(\""+collection_path+"\")\nconst DATA = preload(\""+data_path+"\")\nvar monster_pages := {\"transcendent\":{\"selected\":\"arthur\"}}\nvar preview_title := Label.new()\nvar preview_image := TextureRect.new()\nvar preview_background := TextureRect.new()\nvar preview_root := Control.new()\nvar loads := 0\nvar closed := false\nvar _banner_lock_icon: Texture2D\nfunc close_preview() -> void: closed = true; preview_root.hide()\nfunc _art_texture(_path: String, _trim: bool) -> Texture2D: loads += 1; return ImageTexture.create_from_image(Image.create(4,4,false,Image.FORMAT_RGBA8))\n"+method(codex_source,"artwork_unlocked")+method(codex_source,"preview")+method(codex_source,"_lock_icon"), "actual codex guard and preview compile")
	if failures == 0:
		var view: RefCounted = codex.new()
		for id in ["arthur","zeus","bulgasal","izanami","manticore","shuten_doji"]:
			for level in range(6):
				check(view.artwork_unlocked(id,"plus_banner",{id:{"owned":true,"level":level}}) == (level>=5), "5 ascension ownership gate")
			check(not view.artwork_unlocked(id,"plus_banner",{id:{"owned":false,"level":5}}), "locked monster cannot view banner")
		view.COLLECTION.state = {"arthur":{"owned":true,"level":4}}
		view.preview("transcendent","plus_banner")
		check(view.closed and view.loads == 0, "direct locked preview never loads image")
		check(view._lock_icon() == view._lock_icon(), "lock texture retained")
		view.preview_root.focus_mode = Control.FOCUS_ALL
		root.add_child(view.preview_root)
		view.COLLECTION.state = {"arthur":{"owned":true,"level":5}}
		view.preview("transcendent","plus_banner")
		check(view.loads == 1 and view.preview_root.visible and view.preview_image.texture != null, "unlocked banner opens")
		view.COLLECTION.state = {"arthur":{"owned":true,"level":4}}
		view.preview("transcendent","plus_banner")
		check(view.loads == 1 and not view.preview_root.visible, "ownership is rechecked before every open")
		check(view.artwork_unlocked("arthur","illustration",{}), "normal artwork preview unchanged")
		view.preview_title.free(); view.preview_image.free(); view.preview_background.free(); view.preview_root.free()
	# Build the actual withdrawal section and modal, keeping the unrelated profile
	# page fixture small. UI checks never call a real network transport.
	var settings_source := FileAccess.get_file_as_string("res://src/ui/lobby_settings_view.gd").replace("\r", "")
	var section := method(settings_source,"_build_account")
	section = section.substr(section.find("\tvar withdrawal := Button.new()"))
	# Guest-link UI has its own suite; avoid loading the full presentation tree.
	section = section.replace('\tguest_account_view = preload("res://src/ui/guest_account_view.gd").new()\n\tguest_account_view.install(lobby, page)\n', "")
	var skin_path := fixture("skin", "extends RefCounted\nstatic func apply(_node: Node) -> void: pass\n")
	var settings_script := script("extends RefCounted\nconst SKIN = preload(\""+skin_path+"\")\nvar lobby: Control\nvar pages := {}\nvar withdrawal_button: Button\nvar withdrawal_dialog: ConfirmationDialog\nvar returns := 0\nvar guest_account_view = null\nfunc install(host: Control) -> void:\n\tlobby = host\n\tvar page := VBoxContainer.new()\n\thost.add_child(page)\n\tpages.account = page\n"+section+"\nfunc _sync_account() -> void:\n\twithdrawal_button.disabled = lobby.get_node(\"/root/LoginGateway\").withdrawal_busy\nfunc _return_to_login() -> void: returns += 1\n"+method(settings_source,"_confirm_withdrawal")+method(settings_source,"_withdraw_account"), "actual withdrawal UI section compiles")
	if failures == 0:
		var host := Control.new()
		root.add_child(host)
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var settings: RefCounted = settings_script.new()
		settings.install(host)
		settings._sync_account()
		set_account()
		settings.withdrawal_button.pressed.emit()
		await process_frame
		check(settings.withdrawal_dialog.visible and cloud.calls.is_empty(), "click only opens confirmation")
		settings.withdrawal_dialog.get_cancel_button().pressed.emit()
		check(cloud.calls.is_empty(), "cancel does not withdraw")
		check(settings.withdrawal_dialog.dialog_text.contains("30일") and settings.withdrawal_dialog.ok_button_text == "탈퇴하기", "retention and explicit consent shown")
		var connections: int = gateway.account_deactivated.get_connections().size()
		host.free()
		check(gateway.account_deactivated.get_connections().size() == connections-1, "modal navigation callback disconnected on scene exit")
	gateway.free(); cloud.free(); mode.free(); transition.free()
	for path in fixture_paths: DirAccess.remove_absolute(path)
	await process_frame
	print("ACCOUNT_WITHDRAWAL_AND_BANNER: %s (%d checks)" % ["PASS" if failures==0 else "FAIL",checks])
	quit(0 if failures==0 else 1)
