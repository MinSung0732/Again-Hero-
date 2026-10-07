extends SceneTree

const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const LOADOUT := preload("res://src/systems/transcendence_loadout_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const DROPS := preload("res://src/data/transcendence_catalog.gd")

class HostStub extends Control:
	var hud_layer: Control
	var battle: Node2D
	var battle_viewport: SubViewport
	var battle_viewport_container: Control
	func _end_camera_drag() -> void:
		pass

var failed := false
var cues := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("TRANSCENDENT_DEATH: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	var folder := "user://death_cinematic_" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	var state := COLLECTION.load_state()
	state.zeus = {"unlocked": true, "level": 0, "shards": 0}
	COLLECTION.save_state(state)
	LOADOUT.save_id("zeus")
	root.size = Vector2i(1080, 1920)
	var host := HostStub.new()
	root.add_child(host)
	host.hud_layer = Control.new()
	host.add_child(host.hud_layer)
	host.battle_viewport_container = SubViewportContainer.new()
	host.battle_viewport_container.position = Vector2(0, 270)
	host.battle_viewport_container.size = Vector2(1080, 1174)
	host.add_child(host.battle_viewport_container)
	host.battle_viewport = SubViewport.new()
	host.battle_viewport.size = Vector2i(1080, 1174)
	host.battle_viewport_container.add_child(host.battle_viewport)
	host.battle = load("res://src/battle/Battle.tscn").instantiate()
	host.battle_viewport.add_child(host.battle)
	host.battle.set_process(false)
	host.battle.set_physics_process(false)
	var hero = host.battle.hero
	hero.set_physics_process(false)
	hero.position = Vector2(1800, 1800)
	hero.current_hp = hero.max_hp
	# This fixture prewarms only the relevant drop rather than all unrelated species.
	host.battle._monster_spawn_resources_warmed = true
	await host.battle._warm_transcendent_exp_drop()
	check(host.battle.exp_orb_pool.size() >= 15, "registered transcendent prewarms fifteen reusable orbs")
	var original := Camera2D.new()
	host.battle.add_child(original)
	original.position = Vector2(400, 500)
	original.make_current()
	await process_frame
	var cinematic = preload("res://src/ui/battle_summon_cinematic.gd").new()
	cinematic.install(host)
	host.battle.transcendent_died.connect(func(_id: String, _actor: Node2D): cues += 1)
	host.battle.transcendence.record_command(500.0)
	host.battle.transcendence.record_mana(250.0)
	var actor = host.battle._spawn_monster("zeus", Vector2(1100, 1100), 0.0, false, {"transcendence_summon": true})
	check(is_instance_valid(actor), "registered Zeus spawns after conditions")
	if not is_instance_valid(actor):
		quit(1)
		return
	actor.set_physics_process(false)
	var pool_ids := {}
	for orb in host.battle.exp_orb_pool:
		pool_ids[orb.get_instance_id()] = true
	Engine.time_scale = 0.8
	cinematic.play("zeus", actor)
	cinematic.set_process(false)
	cinematic.advance(1.0)
	check(Engine.time_scale < 0.8, "summon slowed before lethal hit")
	actor.take_damage(1000000)
	cinematic.set_process(false)
	check(actor.dying and cinematic.active and cinematic.death_mode, "actual lethal damage starts death focus")
	check(cinematic.view == null and cinematic.world_effect == null, "death focuses world animation without living portrait or summon bolts")
	check(is_equal_approx(Engine.time_scale, 0.8 * 0.45), "death replaces summon slow with original baseline")
	check(not host.battle.active_monsters.has(actor.get_instance_id()), "dead actor immediately removed from targeting registry")
	check(actor.get_node("Visual").animation == &"death", "actual Zeus death animation begins")
	var orbs := get_nodes_in_group("exp_orbs")
	check(orbs.size() == 15, "exactly fifteen stones")
	var total := 0
	for orb in orbs:
		orb.set_physics_process(false)
		total += int(orb.exp_value)
		check(pool_ids.has(orb.get_instance_id()), "drop reused prewarmed node")
		check(orb.burst_velocity.length() >= 219.0 and orb.pickup_delay_left > 0.0, "outward scatter with pickup grace")
	check(total == 300, "drop sum is configured total rather than fifteen times total")
	actor.take_damage(1000000)
	host.battle._on_monster_died(actor)
	check(cues == 1 and get_nodes_in_group("exp_orbs").size() == 15, "repeated death cannot duplicate cue or reward")
	cinematic.advance(0.8)
	check(is_equal_approx(Engine.time_scale, 0.8 * 0.12), "death reaches dramatic slow")
	check(cinematic.camera.zoom.x > original.zoom.x * 1.6, "death zoom close to target")
	if "--capture" in OS.get_cmdline_user_args():
		for orb in orbs:
			orb._physics_process(0.1)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/zeus-death-focus.png")
	var death_point: Vector2 = actor.global_position
	actor.free()
	cinematic.advance(0.8)
	check(cinematic.active and cinematic.focus_position == death_point, "natural actor removal keeps remembered death focus")
	cinematic.advance(0.6)
	check(is_equal_approx(Engine.time_scale, 0.8), "death speed smoothly recovers before cue ends")
	cinematic.advance(0.7)
	check(not cinematic.active and host.battle_viewport.get_camera_2d() == original, "death normal completion restores camera")
	check(original.position == Vector2(400, 500) and original.zoom == Vector2.ONE, "original camera transform untouched")
	# Actual pickup grants the exact sum once and recycles each stone.
	var before_exp := int(hero.current_exp)
	hero.exp_to_next_level = 1000000
	for orb in orbs:
		orb.hero = hero
		orb.global_position = hero.global_position
		orb.burst_velocity = Vector2.ZERO
		orb.burst_time = 0.0
		orb._physics_process(0.05)
		check(orb.visible, "pickup grace blocks immediate overlapping pickup")
		orb._physics_process(0.4)
	check(int(hero.current_exp) - before_exp == 300, "hero receives exact three hundred EXP")
	check(host.battle.exp_orb_pool.size() >= 15 and get_nodes_in_group("exp_orbs").is_empty(), "picked stones returned to pool")
	# Integer remainder and low totals preserve reward accounting.
	var drop := DROPS.get_death_drop("zeus")
	for amount in [307, 3, 0]:
		host.battle._spawn_transcendent_exp_drop(Vector2(900, 900), amount, drop)
		var pieces := get_nodes_in_group("exp_orbs")
		var sum := 0
		for orb in pieces:
			orb.set_physics_process(false)
			sum += int(orb.exp_value)
		check(sum == amount and pieces.size() == mini(15, amount), "split preserves arbitrary integer sum")
		for orb in pieces:
			host.battle.recycle_exp_orb(orb)
	# Let the real AnimatedSprite death complete naturally under the real-time clock.
	var natural_actor = host.battle._spawn_monster("zeus", Vector2(1100, 1100), 0.0, false, {"transcendence_summon": true})
	natural_actor.set_physics_process(false)
	var saved_fps := Engine.max_fps
	Engine.max_fps = 60
	natural_actor.take_damage(1000000)
	var begin := Time.get_ticks_usec()
	var observed_frame := false
	var captured := false
	while cinematic.active and Time.get_ticks_usec() - begin < 4000000:
		await process_frame
		if is_instance_valid(natural_actor) and natural_actor.get_node("Visual").frame > 0:
			observed_frame = true
		if "--capture" in OS.get_cmdline_user_args() and cinematic.elapsed > 0.75 and not captured:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/zeus-death-focus.png")
			captured = true
	check(not cinematic.active and observed_frame and not is_instance_valid(natural_actor), "real death animation advances and naturally frees before restoration")
	var wall_seconds := float(Time.get_ticks_usec() - begin) / 1000000.0
	check(wall_seconds >= 2.7 and wall_seconds < 3.8 and is_equal_approx(Engine.time_scale, 0.8), "death lasts 2.8 real seconds and restores preexisting speed")
	Engine.max_fps = saved_fps
	for orb in get_nodes_in_group("exp_orbs"):
		host.battle.recycle_exp_orb(orb)
	var ordinary = host.battle._spawn_monster("slime", Vector2(900, 900))
	ordinary.set_physics_process(false)
	var cues_before := cues
	ordinary.take_damage(1000000)
	check(cues == cues_before and get_nodes_in_group("exp_orbs").size() == 1, "ordinary death keeps single drop and no cinematic")
	for orb in get_nodes_in_group("exp_orbs"):
		host.battle.recycle_exp_orb(orb)
	var consumed = host.battle._spawn_monster("zeus", Vector2(1100, 1100), 0.0, false, {"transcendence_summon": true})
	consumed.set_physics_process(false)
	consumed.set_meta("death_type", "consumed")
	consumed.take_damage(1000000)
	check(get_nodes_in_group("exp_orbs").is_empty(), "rewardless consumption still grants no EXP")
	cinematic.cancel()
	# Defaults support future transcendent IDs, and all interruption paths restore speed.
	var other := Node2D.new()
	host.battle.add_child(other)
	for reason in ["menu", "augment", "hidden", "background", "finished"]:
		cinematic.play_death("future_transcendent", other)
		cinematic.set_process(false)
		cinematic.advance(0.5)
		if reason == "menu": host.battle.external_pause = true
		if reason == "augment": host.battle.demon_augment_selection_active = true
		if reason == "hidden": host.battle_viewport_container.hide()
		if reason == "background": cinematic._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		if reason == "finished": host.battle.battle_finished.emit("done", false)
		cinematic.advance(0.01)
		check(not cinematic.active and is_equal_approx(Engine.time_scale, 0.8), "death interruption restores " + reason)
		host.battle.external_pause = false
		host.battle.demon_augment_selection_active = false
		host.battle_viewport_container.show()
	cinematic.play_death("zeus", other)
	cinematic.set_process(false)
	cinematic.advance(0.5)
	host.queue_free()
	await process_frame
	check(is_equal_approx(Engine.time_scale, 0.8), "scene exit restores death slow")
	Engine.time_scale = 1.0
	print("TRANSCENDENT_DEATH_CINEMATIC ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
