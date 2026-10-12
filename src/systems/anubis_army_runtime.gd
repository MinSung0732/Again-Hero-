extends RefCounted
const REFRESH_BUDGET := 8
var mummy_ids: Dictionary = {}
var anubis_ids: Dictionary = {}
var registrations: Dictionary = {}
var leaders: Dictionary = {}
var leader_ids: Array[int] = []
var mummy_count := 0
var anubis_count := 0
var cursor := 0

func setup(catalog: Dictionary) -> void:
	mummy_ids.clear(); anubis_ids.clear()
	for id in catalog:
		var name := String(catalog[id].get("name",""))
		if "미라" in name: mummy_ids[id] = true
		if "아누비스" in name: anubis_ids[id] = true

func reset() -> void:
	registrations.clear(); leaders.clear(); leader_ids.clear()
	mummy_count = 0; anubis_count = 0; cursor = 0

func register(actor: Node) -> void:
	var id := actor.get_instance_id()
	if registrations.has(id): return
	var kind := String(actor.get("monster_type"))
	if not mummy_ids.has(kind) and not anubis_ids.has(kind): return
	registrations[id] = kind
	if mummy_ids.has(kind): mummy_count += 1
	if anubis_ids.has(kind):
		anubis_count += 1
		if actor.has_method("update_army_counts"):
			leaders[id] = weakref(actor); leader_ids.append(id)
	if leaders.has(id):
		actor.update_army_counts(mummy_count,anubis_count)

func retire(id: int, actual_death: bool = false) -> void:
	if not registrations.has(id): return
	var kind: String = registrations[id]
	registrations.erase(id)
	var was_mummy := mummy_ids.has(kind)
	if was_mummy: mummy_count = maxi(mummy_count-1,0)
	if anubis_ids.has(kind): anubis_count = maxi(anubis_count-1,0)
	leaders.erase(id); leader_ids.erase(id)
	if actual_death and was_mummy:
		for leader_id in leader_ids:
			var actor = leaders[leader_id].get_ref()
			if _alive(actor):
				actor.update_army_counts(mummy_count,anubis_count)
				actor.on_mummy_death()

func _alive(actor) -> bool:
	return is_instance_valid(actor) and not actor.is_queued_for_deletion() and not bool(actor.get("dying")) and int(actor.get("current_hp")) > 0

func tick() -> void:
	var size := leader_ids.size()
	var budget := mini(size,REFRESH_BUDGET)
	while budget > 0:
		cursor %= size
		var id := leader_ids[cursor]; cursor += 1; budget -= 1
		var actor = leaders[id].get_ref()
		if not _alive(actor): continue
		# Also checks consumed shield thresholds; only changed multipliers refresh stats.
		actor.update_army_counts(mummy_count,anubis_count)
