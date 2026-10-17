extends SceneTree
const POLICY := preload("res://src/systems/hero_target_policy.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const IDS := ["purifier_hero_holy_bolt","purifier_hero_holy_lance","purifier_hero_purification","purifier_hero_sacred_orb","purifier_hero_mercy_chain","purifier_hero_judgment_seal"]
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func setup():
	var b = load("res://src/battle/Battle.tscn").instantiate()
	b.hero_player_mode = true; b.hero_player_stage = "stage_9"; b.hero_player_hero_id = "purifier_hero"
	b._monster_spawn_resources_warmed = true; root.add_child(b); b.set_external_pause(true)
	var hero = b.hero; var r = hero.player_weapons
	for id in IDS:
		while int(r.levels.get(id,0)) < 10: r.add(id)
	for item in IDS.size():
		var receipt: Dictionary = r.roll_chest()
		check(receipt.evolution and r.apply_chest(receipt),"actual MAX receipt")
	return b
func stop_audio(host) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null
func replay(cache_enabled: bool) -> Array:
	seed(45179)
	var b = setup(); b.monster_candidate_cache.enabled = cache_enabled
	var hero = b.hero; var r = hero.player_weapons
	var targets: Array = []
	for index in 80:
		var point: Vector2 = hero.position+Vector2.RIGHT.rotated(index*2.39996)*(70+(index%9)*43)
		var actor = b._spawn_monster("orc",point)
		actor.max_hp = 10000000; actor.current_hp = actor.max_hp; actor.set_physics_process(false)
		targets.append(actor)
	seed(20261017)
	var trace: Array = []
	for frame in 180:
		if frame == 30: POLICY.set_hidden(targets[0],true)
		if frame == 40: targets[1].current_hp = 0; b.invalidate_monster_spatial_snapshot()
		if frame == 50:
			targets[2].position += Vector2(1600,0); COMMON.notify_forced_position_change(targets[2])
		if frame == 70:
			var actor = b._spawn_monster("orc",hero.position+Vector2(80,0))
			actor.max_hp = 10000000; actor.current_hp = actor.max_hp; actor.set_physics_process(false); targets.append(actor)
		if frame == 90: POLICY.set_hidden(targets[0],false)
		# Equivalent to a new physics snapshot, without unrelated real-time ticks.
		b.invalidate_monster_spatial_snapshot()
		r.tick(1.0/60.0)
		var health: Array = []
		for actor in targets: health.append(actor.current_hp)
		trace.append([health,randi()])
	check(b.active_monsters.size() == targets.size(),"registry retains all static test actors")
	check(b.monster_candidate_cache.hits > 0 if cache_enabled else b.monster_candidate_cache.hits == 0,"real weapon path exercises requested cache mode")
	check(trace[-1][0].any(func(hp): return hp < 10000000 and hp > 0),"real six-weapon MAX build applies damage")
	stop_audio(b); b.free()
	return trace
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	var before := replay(false); var after := replay(true)
	for frame in before.size(): check(before[frame] == after[frame],"exact Stage9 damage and RNG at frame "+str(frame))
	var b = setup(); var profile = b.combat_profile
	profile.start(); b.set_external_pause(false)
	await create_timer(.15).timeout
	var report: Dictionary = profile.report()
	check(report.scopes.hero_physics.calls > 0 and report.scopes.weapon_tick.calls > 0 and report.scopes.battle_process.calls > 0,"live production scopes record")
	b.set_external_pause(true)
	var calls: int = profile.calls[profile.Scope.HERO]
	await create_timer(.1).timeout
	check(profile.calls[profile.Scope.HERO] == calls,"pause stops simulation capture")
	profile.stop(); stop_audio(b); stop_audio(root.get_node("GameAudio")); b.queue_free(); await process_frame
	print("COMBAT_PHASE1_STAGE9 checks=",checks," failures=",failures)
	quit(1 if failures else 0)
