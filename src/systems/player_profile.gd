extends RefCounted

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const DATA := preload("res://src/data/player_profile_catalog.gd")
const PATH := DATA.PATH
const APPEARANCE := preload("res://src/systems/demon_appearance_store.gd")
const APPEARANCE_CATALOG := preload("res://src/data/demon_appearance_catalog.gd")
const GENDERS := preload("res://src/data/profile_gender_catalog.gd")
const NAMES := preload("res://src/data/nickname_catalog.gd")
const PORTRAITS := APPEARANCE_CATALOG.PORTRAITS # Preserve the public path lookup API.

static func valid_name(value: String) -> bool:
	return NAMES.valid(value)

static func random_name(previous: String = "") -> String:
	return NAMES.random_name(previous)

static func get_profile() -> Dictionary:
	var config := ConfigFile.new()
	SCOPE.load_config(config, PATH)
	var value: Variant = config.get_value(DATA.SECTION, DATA.VALUE_KEY, {})
	return value.duplicate(true) if value is Dictionary else {}

static func display_name() -> String:
	var nickname := String(get_profile().get("nickname", ""))
	return "마왕(%s)" % nickname if NAMES.valid(nickname, NAMES.LEGACY_MIN_LENGTH) else "마왕"

static func gender_id() -> String:
	return DATA.gender_id(get_profile())

static func appearance_id() -> String:
	return APPEARANCE.equipped_id()

static func portrait_path(purpose: String = "dialogue", expression: String = "neutral") -> String:
	var selected := APPEARANCE_CATALOG.path(appearance_id(), purpose, expression)
	if not selected.is_empty():
		return selected
	return APPEARANCE_CATALOG.base_portrait_path(gender_id())

static func appearance_resource_paths() -> Array[String]:
	var paths := APPEARANCE_CATALOG.resource_paths(appearance_id())
	var fallback: String = APPEARANCE_CATALOG.base_portrait_path(gender_id())
	if fallback not in paths:
		paths.append(fallback)
	return paths

static func needs_prologue(profile: Dictionary) -> bool:
	return bool(profile.get("required", false)) and not bool(profile.get("completed", false))

static func _store_response(result: Dictionary) -> Dictionary:
	if not bool(result.get("ok", false)):
		return result
	var value: Variant = result.get("profile")
	if not value is Dictionary or not GENDERS.valid(String(value.get("gender", ""))) or not value.get("nickname") is String or not value.get("required") is bool or not value.get("completed") is bool:
		return {"ok": false, "error": "invalid_response"}
	var nickname := String(value.get("nickname", ""))
	# Existing one-character accounts remain readable; new submissions require 2+.
	if not nickname.is_empty() and not NAMES.valid(nickname, NAMES.LEGACY_MIN_LENGTH):
		return {"ok": false, "error": "invalid_response"}
	if bool(value.required) and bool(value.completed) and nickname.is_empty():
		return {"ok": false, "error": "invalid_response"}
	if get_profile() == value:
		return result
	var config := ConfigFile.new()
	SCOPE.load_config(config, PATH)
	config.set_value(DATA.SECTION, DATA.VALUE_KEY, value.duplicate(true))
	if SCOPE.save_config(config, PATH) != OK:
		return {"ok": false, "error": "local_save"}
	return result

static func refresh(cloud: Node) -> Dictionary:
	if preload("res://src/systems/guest_progress_store.gd").is_guest():
		var profile := get_profile()
		if not valid_name(String(profile.get("nickname", ""))):
			profile["nickname"] = random_name()
		profile = DATA.guest_profile(profile)
		return _store_response({"ok": true, "profile": profile})
	if _preview():
		var profile := get_profile()
		if profile.is_empty():
			profile = DATA.initial_profile()
		return _store_response({"ok": true, "profile": profile})
	var owner := SCOPE.user_id
	var result: Dictionary = await cloud.request_rpc("read_player_profile", {})
	if owner.is_empty() or owner != SCOPE.user_id:
		return {"ok": false, "error": "account_changed"}
	return _store_response(result)

static func register(cloud: Node, nickname: String, gender: String) -> Dictionary:
	if not valid_name(nickname) or not GENDERS.valid(gender):
		return {"ok": false, "error": "invalid"}
	if _preview():
		# Preview names are local only: do not reserve or check server nicknames.
		var profile := get_profile()
		if String(profile.get("nickname", "")).is_empty():
			profile = DATA.initial_profile(nickname, gender)
		return _store_response({"ok": true, "profile": profile})
	var owner := SCOPE.user_id
	var result: Dictionary = await cloud.request_rpc("register_player_profile", {"chosen_name": nickname, "chosen_gender": gender})
	if owner.is_empty() or owner != SCOPE.user_id:
		return {"ok": false, "error": "account_changed"}
	return _store_response(result)

static func check_name(cloud: Node, nickname: String) -> Dictionary:
	if not valid_name(nickname): return {"ok": false, "error": "invalid"}
	if _preview(): return {"ok": true, "available": true, "local_only": true}
	var owner := SCOPE.user_id
	var result: Dictionary = await cloud.request_rpc("check_player_nickname", {"chosen_name": nickname})
	return result if not owner.is_empty() and owner == SCOPE.user_id else {"ok": false, "error": "account_changed"}

static func can_rename() -> bool:
	return not SCOPE.user_id.is_empty() and int(get_profile().get("nickname_changes_remaining", 0)) > 0

static func rename(cloud: Node, nickname: String, operation_id: String) -> Dictionary:
	if not valid_name(nickname) or SCOPE.user_id.is_empty(): return {"ok": false, "error": "invalid"}
	var owner := SCOPE.user_id
	var result: Dictionary = await cloud.request_rpc("rename_player_nickname", {"chosen_name": nickname, "operation_id": operation_id})
	if owner != SCOPE.user_id: return {"ok": false, "error": "account_changed"}
	return _store_response(result)

static func can_change_gender() -> bool:
	return not SCOPE.user_id.is_empty() and int(get_profile().get("gender_changes_remaining", 0)) > 0

static func change_gender(cloud: Node, gender: String, operation_id: String) -> Dictionary:
	if not GENDERS.valid(gender) or SCOPE.user_id.is_empty() or operation_id.is_empty():
		return {"ok": false, "error": "invalid"}
	var owner := SCOPE.user_id
	var result: Dictionary = await cloud.request_rpc("change_player_gender", {"chosen_gender": gender, "operation_id": operation_id})
	if owner != SCOPE.user_id: return {"ok": false, "error": "account_changed"}
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
	return mode != null and (mode.is_tutorial_preview() or preload("res://src/systems/guest_progress_store.gd").is_guest())
