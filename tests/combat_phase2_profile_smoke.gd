extends SceneTree
const PROBE := preload("res://src/systems/combat_performance_probe.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func stop_audio(host) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	var b = load("res://src/battle/Battle.tscn").instantiate()
	b.hero_player_mode = true; b.hero_player_stage = "stage_9"; b.hero_player_hero_id = "purifier_hero"
	b._monster_spawn_resources_warmed = true; root.add_child(b); b.set_external_pause(true)
	b.hero.invulnerability_timer = 9999
	var actors: Array = []
	# Exercise core actor instrumentation independently of survival spawn quotas.
	b.hero_player_mode = false
	for kind in ["orc","slime","spider","skeleton_archer","bomb_rat"]:
		var actor = b._spawn_monster(kind,b.hero.position+Vector2(300,actors.size()*40))
		check(is_instance_valid(actor),"real core actor "+kind)
		if not is_instance_valid(actor): quit(1); return
		check(actor._combat_profile == b.combat_profile,"cached profile bound at configure "+kind)
		actors.append(actor)
	b.hero_player_mode = true
	b.combat_profile.start(); b.set_external_pause(false)
	for frame in 12: await physics_frame
	b.set_external_pause(true)
	var report: Dictionary = b.combat_profile.report()
	for scope in ["monster_base_physics","monster_move_and_slide","monster_separation"]:
		check(report.scopes[scope].calls > 0,"live scope "+scope)
	var calls: int = b.combat_profile.calls[PROBE.Scope.MONSTER_PHYSICS]
	for frame in 4: await physics_frame
	check(b.combat_profile.calls[PROBE.Scope.MONSTER_PHYSICS] == calls,"pause stops actor scopes")
	b.combat_profile.stop(); b.set_external_pause(false)
	for frame in 4: await physics_frame
	b.set_external_pause(true)
	check(b.combat_profile.calls[PROBE.Scope.MONSTER_PHYSICS] == calls,"disabled probe retains counts")
	var other = load("res://src/battle/Battle.tscn").instantiate()
	# configure is also the pooling/room-reassignment boundary; no global cache.
	for actor in actors:
		actor.configure_combat_context(b.hero,other)
		check(actor._combat_profile == other.combat_profile,"authority reassignment updates cached probe")
		actor.configure_combat_context(b.hero,b)
		if not is_instance_valid(actor): quit(1); return
		check(actor._combat_profile == b.combat_profile,"authority reassignment restored")
	other.free(); stop_audio(b); stop_audio(root.get_node("GameAudio")); b.free()
	print("COMBAT_PHASE2_PROFILE checks=",checks," failures=",failures); quit(1 if failures else 0)
