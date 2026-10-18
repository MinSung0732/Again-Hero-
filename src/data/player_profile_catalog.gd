extends RefCounted

const GENDERS := preload("res://src/data/profile_gender_catalog.gd")
const PATH := "user://stage_progress.cfg"
const SECTION := "player_profile"
const VALUE_KEY := "value"
const INITIAL := {"nickname": "", "gender": GENDERS.DEFAULT_ID, "required": true, "completed": false}
const GUEST_FLAGS := {"required": false, "completed": true, "nickname_changes_remaining": 0, "gender_changes_remaining": 0}

static func gender_id(profile: Dictionary) -> String:
	# Missing gets the old default; invalid saved/server values are not repaired.
	return String(profile.get("gender", GENDERS.DEFAULT_ID))

static func initial_profile(nickname: String = "", gender: String = GENDERS.DEFAULT_ID) -> Dictionary:
	var result := INITIAL.duplicate(true)
	result.nickname = nickname
	result.gender = gender
	return result

static func guest_profile(profile: Dictionary) -> Dictionary:
	var result := profile.duplicate(true)
	result["gender"] = result.get("gender", GENDERS.DEFAULT_ID)
	result.merge(GUEST_FLAGS, true)
	return result
