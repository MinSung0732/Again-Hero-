extends SceneTree
const MODE := preload("res://src/data/hero_mode_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
var xp: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func level_for(amount: float) -> int:
	var level := 1
	while amount >= MODE.required_exp(level):
		amount -= MODE.required_exp(level); level += 1
	return level
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	for id in MONSTERS.ORDER:
		var data: Dictionary = MONSTERS.MONSTERS[id]
		if not data.has("scene"): continue
		var actor = data.scene.instantiate()
		var value = actor.get("exp_reward")
		if value != null: xp[id] = float(value)
		actor.free()
	for stage in [1,4,7,10]:
		seed(20261013+stage)
		var roster := MODE.roster_for(stage)
		var command := MODE.STARTING_COMMAND
		var remaining := 0.0; var rotation := 0; var total := 0.0; var summons := 0
		var pressure := MODE.stage_pressure(stage)
		for step in 18000:
			var clock := step*0.05
			var phase := MODE.phase_at(clock)
			command = minf(120,command+float(phase.regen)*pressure*0.05)
			remaining -= 0.05
			if remaining > 0: continue
			remaining = float(phase.interval)/pressure
			for index in int(phase.batch):
				var id := String(roster[rotation%int(phase.roster)]); rotation += 1
				if clock > 25 and randf() < 0.55:
					var counter := String(MODE.COUNTERS.area[rotation%2])
					if counter in roster: id = counter
				var cost := MONSTERS.get_base_cost(id)
				if command < cost: continue
				command -= cost; total += float(xp.get(id,25))*MODE.EXP_REWARD_RATIO; summons += 1
		var levels: Array = []
		for pickup in [0.70,0.85,1.0]: levels.append(level_for(total*pickup))
		print("BUDGET stage=",stage," kills_if_all_defeated=",summons," EXP=",roundi(total)," levels_pickup70_85_100=",levels," max_learning=",level_for(total*1.3))
	print("REQUIREMENT cumulative30=",cumulative(30)," cumulative40=",cumulative(40))
	print("MODEL ONLY: assumes all spawns defeated; no damage, pathing, occupancy, augments or special-drop simulation.")
	quit()
func cumulative(level: int) -> int:
	var total := 0
	for rank in range(1,level): total += MODE.required_exp(rank)
	return total
