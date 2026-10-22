extends RefCounted
## Shared wire and cloud-snapshot rules for ranked entry.
const HEROES := preload("res://src/data/hero_character_catalog.gd")
const HERO_STORE := preload("res://src/systems/hero_mode_store.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const SKILLS := preload("res://src/data/demon_ultimate_catalog.gd")
const ENTRY := preload("res://src/systems/dungeon_entry_policy.gd")

static func unlocked_heroes() -> Array[String]:
	var result: Array[String] = []
	for raw_id in HEROES.ORDER:
		var id := String(raw_id)
		if HERO_STORE.character_unlocked(id): result.append(id)
	return result

static func default_demon() -> Dictionary:
	var team: Array = []
	for raw_id in MONSTERS.ORDER:
		var id := String(raw_id)
		if MONSTERS.is_default_unlocked(id) and MONSTERS.get_rarity(id) != "transcendent": team.append(id)
		if team.size() == 3: break
	var skills: Array = []
	for id in SKILLS.get_ordered_ids():
		if bool(SKILLS.get_skill(id).get("implemented",false)): skills.append(id)
		if skills.size() == 3: break
	return {"team_ids":team,"skill_ids":skills,"transcendence_id":""}

static func valid(role: String,value: Variant) -> bool:
	if not value is Dictionary or JSON.stringify(value).to_utf8_buffer().size() > 512: return false
	if role == "hero":
		return value.size() == 1 and value.get("hero_id",null) is String and _id(value.hero_id)
	if role != "demon" or value.size() != 3: return false
	return _ids(value.get("team_ids"),3) and _ids(value.get("skill_ids"),3) and value.get("transcendence_id",null) is String and (value.transcendence_id.is_empty() or _id(value.transcendence_id))

static func _id(value: String) -> bool:
	if value.is_empty() or value.length() > 64: return false
	for c in value.to_utf8_buffer():
		if not (c >= 97 and c <= 122 or c >= 48 and c <= 57 or c == 95): return false
	return true

static func _ids(value: Variant,limit: int) -> bool:
	if not value is Array or value.size() > limit: return false
	var seen := {}
	for id in value:
		if not id is String or not _id(id) or seen.has(id): return false
		seen[id] = true
	return true

static func owned(role: String,loadout: Dictionary,snapshot: Dictionary) -> bool:
	if not valid(role,loadout): return false
	if not snapshot.get("progress",null) is Dictionary or not snapshot.progress.get("cleared",null) is Dictionary or not snapshot.get("monsters",null) is Dictionary: return false
	var progress: Dictionary = snapshot.get("progress",{})
	var clears: Dictionary = progress.get("cleared",{})
	if role == "hero":
		var hero: Dictionary = HEROES.get_character(loadout.hero_id)
		return not hero.is_empty() and bool(clears.get("stage_3",false)) and bool(clears.get(String(hero.stage),false))
	var team: Array = loadout.team_ids
	var skills: Array = loadout.skill_ids
	if not ENTRY.blocked_reason(team,skills,false).is_empty(): return false
	if ",".join(team) != String(snapshot.get("team_ids","")) or ",".join(skills) != String(snapshot.get("skill_ids","")): return false
	var owned_monsters: Dictionary = snapshot.get("monsters",{})
	for id in team:
		if MONSTERS.get_monster(id).is_empty() or MONSTERS.get_rarity(id) == "transcendent" or not _monster_owned(id,owned_monsters): return false
	for id in skills:
		if not bool(SKILLS.get_skill(id).get("implemented",false)): return false
	var transcendence: String = loadout.transcendence_id
	if transcendence != String(snapshot.get("transcendence_id","")): return false
	if not transcendence.is_empty() and (MONSTERS.get_rarity(transcendence) != "transcendent" or not _monster_owned(transcendence,owned_monsters)): return false
	return true

static func _monster_owned(id: String,monsters: Dictionary) -> bool:
	return bool(monsters.get(id+"_unlocked",MONSTERS.is_default_unlocked(id))) or int(monsters.get(id+"_shards",0)) >= MONSTERS.get_shards_required(id)
