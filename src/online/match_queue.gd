extends RefCounted
## Identity comes from authentication, never from a client's declared user ID.
var waiting := {"hero":[],"demon":[]}
var members := {}
func enqueue(peer: int,uid: String,role: String) -> bool:
	if role not in waiting or members.has(peer) or uid.is_empty(): return false
	for entry in members.values():
		if entry.uid == uid: return false
	members[peer] = {"uid":uid,"role":role}; waiting[role].append(peer); return true
func remove(peer: int) -> void:
	if not members.has(peer): return
	waiting[members[peer].role].erase(peer); members.erase(peer)
func pair() -> Array:
	if waiting.hero.is_empty() or waiting.demon.is_empty(): return []
	var hero: int = waiting.hero[0]; var demon: int = waiting.demon[0]
	remove(hero); remove(demon); return [hero,demon]
