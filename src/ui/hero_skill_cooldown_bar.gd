extends HBoxContainer
## One badge implementation for solo and online hero cooldowns.
const BADGE := preload("res://src/ui/hero_skill_cooldown_badge.gd")
var badges: Dictionary = {}
var seen: Dictionary = {}
var stale: Array[String] = []

func refresh(skills: Array) -> void:
	seen.clear()
	for raw in skills:
		if not raw is Dictionary: continue
		var id := String(raw.get("id", ""))
		if id.is_empty(): continue
		seen[id] = true
		var badge: Control = badges.get(id)
		if not is_instance_valid(badge):
			badge = BADGE.new()
			badges[id] = badge
			add_child(badge)
			badge.call("configure", raw)
		else: badge.call("update_state", raw)
	stale.clear()
	for id in badges:
		if not seen.has(id): stale.append(String(id))
	for id in stale:
		var badge: Control = badges[id]
		if is_instance_valid(badge): badge.queue_free()
		badges.erase(id)
	visible = not seen.is_empty()
	if visible:
		z_index = 120
		move_to_front()
