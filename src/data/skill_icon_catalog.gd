extends RefCounted
## Presentation-only registry. Keys: domain:owner_id:skill_id (or authored skill name).
## Domains: demon, elite, transcendent, hero. No guessed filenames or combat changes.
const PATHS := {}
static var textures: Dictionary = {}
static func key(domain: String, owner_id: String, skill_id: String) -> String:
	return "%s:%s:%s" % [domain,owner_id,skill_id]
static func path(domain: String, owner_id: String, skill_id: String) -> String:
	return String(PATHS.get(key(domain,owner_id,skill_id),""))
static func texture(domain: String, owner_id: String, skill_id: String) -> Texture2D:
	var location := path(domain,owner_id,skill_id)
	if location.is_empty(): return null
	if not textures.has(location): textures[location] = load(location) as Texture2D if ResourceLoader.exists(location) else null
	return textures[location]
