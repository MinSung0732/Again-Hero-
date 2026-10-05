extends RefCounted

# Stable IDs, not file paths, are saved. Avatar/dialogue art may diverge later.
const DEFAULTS := {"male": "original_male", "female": "original_female"}
const ORDER := ["original_male", "original_female"]
const ENTRIES := {
	"original_male": {
		"name": "기본 마왕 · 남성", "default_owned": true,
		"avatar": "res://assets/art/demonking/demonking_portrait_male.png",
		"dialogue": "res://assets/art/demonking/demonking_portrait_male.png",
		"expressions": {},
	},
	"original_female": {
		"name": "기본 마왕 · 여성", "default_owned": true,
		"avatar": "res://assets/art/demonking/demonking_portrait_female.png",
		"dialogue": "res://assets/art/demonking/demonking_portrait_female.png",
		"expressions": {},
	},
}

static func get_entry(id: String) -> Dictionary:
	return ENTRIES.get(id, {}).duplicate(true)

static func default_id(gender: String) -> String:
	return DEFAULTS.get(gender, DEFAULTS.male)

static func path(id: String, purpose: String = "dialogue", expression: String = "neutral") -> String:
	var entry := get_entry(id)
	var result := String(entry.get(purpose, ""))
	if purpose == "dialogue":
		var variant := String(entry.get("expressions", {}).get(expression, ""))
		if not variant.is_empty() and ResourceLoader.exists(variant):
			result = variant
	return result if not result.is_empty() and ResourceLoader.exists(result) else ""

static func resource_paths(id: String) -> Array[String]:
	var result: Array[String] = []
	var entry := get_entry(id)
	for value in [entry.get("avatar", ""), entry.get("dialogue", "")] + entry.get("expressions", {}).values():
		if value is String and not value.is_empty() and ResourceLoader.exists(value) and value not in result:
			result.append(value)
	return result
