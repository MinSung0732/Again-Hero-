extends RefCounted
class_name ShopSummonHistoryStore

const SAVE_PATH := "user://shop_summon_history.cfg"
const MAX_HISTORY := 100


static func load_entries() -> Array:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return []

	var saved = config.get_value("summons", "entries", [])
	if typeof(saved) != TYPE_ARRAY:
		return []

	var entries: Array = []
	for raw_entry in saved:
		var entry := _normalize_entry(raw_entry)
		if entry.is_empty():
			continue
		entries.append(entry)

	while entries.size() > MAX_HISTORY:
		entries.pop_front()
	return entries


static func append_entries(new_entries: Array) -> Array:
	var entries := load_entries()
	for raw_entry in new_entries:
		var entry := _normalize_entry(raw_entry)
		if entry.is_empty():
			continue
		entries.append(entry)

	while entries.size() > MAX_HISTORY:
		entries.pop_front()

	var config := ConfigFile.new()
	config.set_value("summons", "entries", entries)
	config.save(SAVE_PATH)
	return entries


static func _normalize_entry(raw_entry) -> Dictionary:
	if typeof(raw_entry) != TYPE_DICTIONARY:
		return {}

	var monster_id := String(raw_entry.get("monster_id", ""))
	var rarity_id := String(raw_entry.get("rarity", ""))
	var shards := maxi(int(raw_entry.get("shards", 0)), 0)
	if monster_id.is_empty() or rarity_id.is_empty() or shards <= 0:
		return {}

	return {
		"monster_id": monster_id,
		"rarity": rarity_id,
		"shards": shards,
		"unlocked": bool(raw_entry.get("unlocked", false)),
	}
