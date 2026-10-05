extends RefCounted

# Shared only by the extra basic-attack fan bullets from a single firing.
# No global cooldown: a new attack owns a new record; pool release drops only
# that projectile's reference, never clears surviving siblings' hit records.
var hit_ids: Dictionary = {}

func claim_target(target: Node) -> bool:
	if not target.is_in_group("monsters"):
		return true
	var id := target.get_instance_id()
	if hit_ids.has(id):
		return false
	hit_ids[id] = true
	return true
