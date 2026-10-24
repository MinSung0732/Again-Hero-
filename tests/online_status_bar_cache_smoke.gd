extends SceneTree
const VIEW := preload("res://src/online/status_bar_view.gd")
const COOLDOWNS := preload("res://src/ui/hero_skill_cooldown_bar.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var view := VIEW.new(); view.capacity = 4; root.add_child(view)
	var state := {"hero":[0,0,10,20,1,[128,64,1,5,12,-79,-64,-49]],"hero_archetype":"pistol_gunner","actors":[[1,"slime",10,10,20,20,[255,-1,-44,100,100]],[2,"slime",20,20,10,20,[128,128,-44,100,100,0,255]]]}
	view.sync_state(state)
	check(view.pool.size() == 3 and view.bindings.size() == 3,"one cached renderer per live actor")
	view.position = Vector2(80,90); view.scale = Vector2(0.5,0.75)
	view.move_actor(0,Vector2(120,200))
	check(view.bindings[0].global_position == Vector2(140,240),"camera offset and non-uniform map scale match original bar transform")
	var hero = view.bindings[0]; var first = view.bindings[1]
	check(hero.bars == state.hero[5] and hero.bars[3] == 5 and hero.bars[4] == 12,"ammo count and capacity preserved")
	check(view.bindings[2].bars == state.actors[1][6],"HP/yellow/shield payload preserved")
	for index in 1000:
		view.move_actor(0,Vector2(index,index*0.5))
		view.move_actor(1,Vector2(index*0.5,index))
		view.sync_state(state)
	check(hero.refreshes == 1 and first.refreshes == 1,"unchanged data and moving actors do not regenerate bars")
	check(view.pool.size() == 3 and view.bindings[0] == hero,"steady updates keep the same renderer instances")
	state.hero[5][3] = 6; view.sync_state(state)
	check(hero.refreshes == 2 and hero.bars[3] == 6,"in-place ammo mutation invalidates only hero bar")
	check(first.refreshes == 1,"ammo change does not invalidate monster bars")
	state.hero_archetype = "cleric_purifier"; view.sync_state(state)
	check(hero.refreshes == 3,"archetype change invalidates style")
	state.actors = [[3,"slime",10,10,20,20,[255,-1,-44,100,100]],[4,"slime",20,20,10,20,[128,-1,-44,100,100]]]
	view.sync_state(state)
	check(view.pool.size() == 3 and not view.bindings.has(1) and not view.bindings.has(2),"full actor turnover reuses released slots")
	check(view.bindings.has(3) and view.bindings.has(4),"new wire ids receive slots")
	state.actors.clear(); view.sync_state(state)
	check(view.available.size() == 2 and not first.visible,"despawn hides bars and returns slots")
	view.capacity = 3
	state.actors = [[7,"slime",0,0,1,1,[255,-1,-44,100,100]],[8,"slime",0,0,1,1,[255,-1,-44,100,100]],[9,"slime",0,0,1,1,[255,-1,-44,100,100]]]
	view.sync_state(state)
	check(view.pool.size() == 3 and view.bindings.size() == 3,"capacity remains bounded")
	var host := Control.new(); root.add_child(host)
	var cooldowns := COOLDOWNS.new(); host.add_child(cooldowns)
	var other := Control.new(); host.add_child(other)
	var skills := [{"id":"cache_test","cooldown_total":4.0,"cooldown_remaining":2.0}]
	cooldowns.refresh(skills)
	check(cooldowns.get_index() == host.get_child_count()-1,"cooldown bar rises above sibling once")
	var sibling_changes := [0]
	host.child_order_changed.connect(func(): sibling_changes[0] += 1)
	for _index in 100: cooldowns.refresh(skills)
	check(sibling_changes[0] == 0 and cooldowns.badges.size() == 1,"steady cooldown refresh does not reorder or recreate children")
	view.free(); host.free()
	print("ONLINE_STATUS_BAR_CACHE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
