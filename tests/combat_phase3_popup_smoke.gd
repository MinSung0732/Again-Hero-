extends SceneTree
const POPUPS := preload("res://src/ui/damage_number_spawner.gd")
class Host extends Node2D:
	var combat_popup_visuals_enabled := true
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func state(popup) -> Array:
	return [popup.numeric_amount,popup.numeric_prefix,popup.elapsed,popup.position,popup.scale,popup.modulate,popup.pool_active,popup.can_merge_damage(),popup.can_merge_heal(),popup.horizontal_drift]
func run() -> void:
	var hosts: Array = []; var targets: Array = []
	for rendered in [true,false]:
		var host := Host.new(); host.combat_popup_visuals_enabled = rendered; root.add_child(host); hosts.append(host)
		var list: Array = []
		for index in 60:
			var actor := Node2D.new(); actor.position = Vector2(index*5,10); host.add_child(actor); list.append(actor)
		targets.append(list)
	for frame in 90:
		var states: Array = []; var randoms: Array = []
		for mode in 2:
			seed(98701+frame)
			for index in 60:
				var actor: Node2D = targets[mode][index]
				if frame%3 == 0: POPUPS.show_heal(actor,3)
				elif frame%3 == 1:
					actor.set_meta("damage_number_color_once",Color.RED); POPUPS.show(actor,7); POPUPS.show(actor,9)
				else: POPUPS.show_text_at(hosts[mode],actor.position,"면역")
			var values: Array = []; var pool: Array = hosts[mode].get_meta("_damage_number_pool",[])
			for popup in pool:
				popup._process(.025); values.append(state(popup))
				check((popup.value_label != null) == (mode == 0),"only rendered pool has Label")
			states.append(values); randoms.append(randi())
			check(pool.size() <= POPUPS.MAX_ACTIVE_POPUPS,"pool remains bounded")
		check(states[0] == states[1],"same numeric/merge/lifetime/pool saturation state")
		check(randoms[0] == randoms[1],"cosmetic optimization preserves global RNG draws")
	for host in hosts: host.free()
	print("COMBAT_PHASE3_POPUP checks=",checks," failures=",failures); quit(1 if failures else 0)
