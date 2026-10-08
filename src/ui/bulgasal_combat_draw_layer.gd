extends Node2D
## Two lifetime-stable draw layers; actor owns all timers and combat authority.
var actor: Node2D
var status := false

func _draw() -> void:
	if not is_instance_valid(actor) or actor.dying:
		return
	if status:
		actor.draw_status_overlay(self)
	else:
		actor.draw_combat_overlay(self)
