extends RefCounted

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PATH := "user://stage_progress.cfg"
const PORTRAITS := {
	"male": "res://assets/art/demonking/demonking_portrait_male.png",
	"female": "res://assets/art/demonking/demonking_portrait_female.png",
}
const RANDOM_PREFIXES := ["새벽", "붉은", "검은", "달빛", "별빛", "고요", "은빛", "심연", "황혼", "푸른"]
const RANDOM_SUFFIXES := ["군주", "마왕", "왕관", "그림자", "불꽃", "루나", "아르", "카인", "밤", "별"]

static func valid_name(value: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile("\\A[가-힣A-Za-z0-9]{1,6}\\z")
	return pattern.search(value) != null

static func random_name(previous: String = "") -> String:
	var candidate := previous
	while candidate == previous:
		candidate = String(RANDOM_PREFIXES.pick_random()) + String(RANDOM_SUFFIXES.pick_random()) + str(randi_range(0, 9))
	return candidate

static func get_profile() -> Dictionary:
	var config := ConfigFile.new()
	SCOPE.load_config(config, PATH)
	var value: Variant = config.get_value("player_profile", "value", {})
	return value.duplicate(true) if value is Dictionary else {}

static func display_name() -> String:
	var nickname := String(get_profile().get("nickname", ""))
	return "마왕(%s)" % nickname if valid_name(nickname) else "마왕"

static func portrait_path() -> String:
	return PORTRAITS.get(String(get_profile().get("gender", "male")), PORTRAITS.male)

static func needs_prologue(profile: Dictionary) -> bool:
	return bool(profile.get("required", false)) and not bool(profile.get("completed", false))

static func _store_response(result: Dictionary) -> Dictionary:
	if not bool(result.get("ok", false)):
		return result
	var value: Variant = result.get("profile")
	if not value is Dictionary or not PORTRAITS.has(String(value.get("gender", ""))) or not value.get("nickname") is String or not value.get("required") is bool or not value.get("completed") is bool:
		return {"ok": false, "error": "invalid_response"}
	var nickname := String(value.get("nickname", ""))
	if not nickname.is_empty() and not valid_name(nickname):
		return {"ok": false, "error": "invalid_response"}
	if bool(value.required) and bool(value.completed) and nickname.is_empty():
		return {"ok": false, "error": "invalid_response"}
	if get_profile() == value:
		return result
	var config := ConfigFile.new()
	SCOPE.load_config(config, PATH)
	config.set_value("player_profile", "value", value.duplicate(true))
	if SCOPE.save_config(config, PATH) != OK:
		return {"ok": false, "error": "local_save"}
	return result

static func refresh(cloud: Node) -> Dictionary:
	if _preview():
		var profile := get_profile()
		if profile.is_empty():
			profile = {"nickname": "", "gender": "male", "required": true, "completed": false}
		return _store_response({"ok": true, "profile": profile})
	var owner := SCOPE.user_id
	var result: Dictionary = await cloud.request_rpc("read_player_profile", {})
	if owner.is_empty() or owner != SCOPE.user_id:
		return {"ok": false, "error": "account_changed"}
	return _store_response(result)

static func register(cloud: Node, nickname: String, gender: String) -> Dictionary:
	if not valid_name(nickname) or not PORTRAITS.has(gender):
		return {"ok": false, "error": "invalid"}
	if _preview():
		# Preview names are local only: do not reserve or check server nicknames.
		var profile := get_profile()
		if String(profile.get("nickname", "")).is_empty():
			profile = {"nickname": nickname, "gender": gender, "required": true, "completed": false}
		return _store_response({"ok": true, "profile": profile})
	var owner := SCOPE.user_id
	var result: Dictionary = await cloud.request_rpc("register_player_profile", {"chosen_name": nickname, "chosen_gender": gender})
	if owner.is_empty() or owner != SCOPE.user_id:
		return {"ok": false, "error": "account_changed"}
	return _store_response(result)

static func complete(cloud: Node) -> bool:
	if _preview():
		var profile := get_profile()
		if not valid_name(String(profile.get("nickname", ""))):
			return false
		profile.completed = true
		return bool(_store_response({"ok": true, "profile": profile}).get("ok", false))
	var owner := SCOPE.user_id
	var result: Dictionary = await cloud.request_rpc("complete_player_prologue", {})
	if owner.is_empty() or owner != SCOPE.user_id:
		return false
	if not bool(_store_response(result).get("ok", false)):
		return false
	return await cloud.flush()

static func _preview() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var mode := tree.root.get_node_or_null("LocalTestMode") if tree != null else null
	return mode != null and mode.is_tutorial_preview()
