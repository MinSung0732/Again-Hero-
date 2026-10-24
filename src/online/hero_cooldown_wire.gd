extends RefCounted
## Match handshake carries badge metadata; states carry only index and byte ratio.
static func capture_catalog(hero: Node) -> Array:
	var result: Array = []
	if not is_instance_valid(hero) or not hero.has_method("get_skill_cooldown_hud"): return result
	for raw in hero.call("get_skill_cooldown_hud"):
		if raw is Dictionary and not String(raw.get("id", "")).is_empty(): result.append(raw.duplicate())
	return result

static func encode(hero: Node, catalog: Array) -> Array:
	var rows: Array = []
	if not is_instance_valid(hero): return rows
	var current: Array = hero.call("get_skill_cooldown_hud")
	for index in catalog.size():
		var id := String(catalog[index].get("id", ""))
		for skill in current:
			if not skill is Dictionary or String(skill.get("id", "")) != id: continue
			# The handshake total is the shared scale so client seconds stay accurate
			# when an augment changes the live cooldown duration.
			var total := maxf(float(catalog[index].get("cooldown_total", 0.0)), 0.001)
			rows.append([index, clampi(roundi(float(skill.get("cooldown_remaining", 0.0)) / total * 255.0), 0, 255)])
			break
	return rows

static func decode(rows: Variant, catalog: Array) -> Array:
	var result: Array = []
	if not rows is Array or rows.size() > catalog.size(): return result
	var previous := -1
	for row in rows:
		if not row is Array or row.size() != 2: return []
		if not (row[0] is int or row[0] is float) or not (row[1] is int or row[1] is float): return []
		if not is_finite(float(row[0])) or not is_finite(float(row[1])): return []
		if row[0] != floorf(float(row[0])) or row[1] != floorf(float(row[1])): return []
		var index := int(row[0])
		if index <= previous or index >= catalog.size() or row[1] < 0 or row[1] > 255: return []
		previous = index
		var skill: Dictionary = catalog[index].duplicate()
		skill["cooldown_remaining"] = float(skill.get("cooldown_total", 0.0)) * float(row[1]) / 255.0
		skill["available"] = row[1] == 0
		result.append(skill)
	return result
