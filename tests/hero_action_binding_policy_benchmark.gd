extends SceneTree
const BEFORE = preload("res://before.gd")
const AFTER = preload("res://after.gd")
const ARCHETYPES = ["ranged_kiter", "rogue_combo", "sword_shield", "pistol_gunner", "archmage_elementalist", "berserker_madness", "alchemist_chemical", "summoner_gatekeeper", "cleric_purifier", "grand_sage_astra"]
func _initialize(): call_deferred("run")
func sample(node, count):
	var start = Time.get_ticks_usec()
	for i in range(count):
		node._physics_process_actions(0.016)
		node.events.clear()
	return float(Time.get_ticks_usec() - start) / float(count)
func run():
	var total_before := 0.0
	var total_after := 0.0
	for archetype in ARCHETYPES:
		for player in [false, true]:
			var a = BEFORE.new(); root.add_child(a)
			var b = AFTER.new(); root.add_child(b)
			for node in [a, b]:
				node.hero_archetype = archetype
				if player: node.enable_player(true)
			sample(a, 50); sample(b, 50)
			var before: Array = []; var after: Array = []
			for i in range(5):
				if i % 2 == 0:
					before.append(sample(a, 2000)); after.append(sample(b, 2000))
				else:
					after.append(sample(b, 2000)); before.append(sample(a, 2000))
			before.sort(); after.sort()
			total_before += before[2]; total_after += after[2]
			a.free(); b.free()
	print("ACTION_BINDING_CPU_ONLY before_us=%s after_us=%s delta_us=%s; equal-weight 10 NPC/player owners, spies, no whole game" % [total_before / 20.0, total_after / 20.0, (total_after - total_before) / 20.0])
	quit()
