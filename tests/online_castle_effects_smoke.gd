extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const VIEW := preload("res://src/online/battle_view.gd")
const SAMPLE := preload("res://src/online/presentation_snapshot.gd")
const ART := preload("res://src/data/online_presentation_catalog.gd")
const GEO := preload("res://src/hero_mode/hero_weapon_geometry.gd")
const WEB := preload("res://src/monsters/SpiderProjectile.tscn")
const ARROW := preload("res://src/monsters/SkeletonArcherProjectile.tscn")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var room = ROOM.new(); root.add_child(room); room.prepare(); room.start()
	var battle = room.battle
	battle.process_mode = Node.PROCESS_MODE_DISABLED
	var original_field = battle.get_node("Stage1Battlefield")
	check(original_field.collision_layer_root.get_child_count()>0,"server castle still creates original collision bodies")
	var view = VIEW.new(); view.position = Vector2(73,91); view.size = Vector2(1080,1200); root.add_child(view)
	check(view.prepare_battlefield(room.battlefield_info),"prepare original castle layout before ready")
	var field = view.battlefield.field
	check(field.render_only and field.stage_active,"client uses shared castle in render-only mode")
	check(field.collision_layer_root.get_child_count()==0 and view.find_children("*","CollisionObject2D",true,false).is_empty(),"no client collision/physics bodies")
	check(field.depth_prop_roots.size()==original_field.depth_prop_roots.size() and field.background_decor_layer.get_child_count()==original_field.background_decor_layer.get_child_count(),"same authored prop and wall count")
	check(field.floor_damage_paths == original_field.floor_damage_paths,"same deterministic floor damage")
	check(not view.battlefield.prop_commands.is_empty(),"static depth commands captured once")
	for index in field.depth_prop_roots.size():
		var prop = field.depth_prop_roots[index]
		check(prop.position == original_field.depth_prop_roots[index].position,"same source ground anchor")
		check(not prop.visible,"static prop drawn only by merged mirror")
		var command: Array = view.battlefield.prop_commands[index]
		check(is_equal_approx(float(command[21]),prop.position.y),"UI offset removed from ground sort anchor")
		var sprite: Sprite2D = prop.get_child(0)
		check(is_equal_approx(float(command[10]),prop.position.x + sprite.position.x),"UI offset removed from prop world X")
	var builds: int = view.battlefield.rebuilds
	for index in 10: check(view.prepare_battlefield(room.battlefield_info),"repeat descriptor accepted")
	check(view.battlefield.rebuilds==builds,"unchanged snapshots never rebuild static scene")
	var snapshot: Dictionary = room.snapshot()
	check(view.update_state(snapshot),"castle and actor snapshot compose")
	var prop_command: Array = view.battlefield.prop_commands[0]
	var behind: Array = prop_command.duplicate(); behind[0] = 999; behind[21] -= 1.0
	var in_front: Array = prop_command.duplicate(); in_front[0] = 1000; in_front[21] += 1.0
	var sorted := [in_front,prop_command,behind]; sorted.sort_custom(SAMPLE.visual_order)
	check(sorted[0][0]==999 and sorted[1][0]==-2 and sorted[2][0]==1000,"prop covers actors above ground and is covered below ground")
	for bad in [{"stage":"missing","bounds":[3600,3600]}, {"stage":"stage_1","bounds":[NAN,3600]}, {"stage":"stage_1","bounds":[1e9,3600]}, {"stage":"stage_1","bounds":[3600,3600],"extra":"bad"}]:
		check(not view.prepare_battlefield(bad) and view.battlefield.rebuilds==builds,"bad metadata cannot rebuild scene")
	var bad_state: Dictionary = snapshot.duplicate(true); bad_state.bounds[0] += 1
	check(not view.update_state(bad_state),"map bounds must agree with shared descriptor")
	# Original active projectile lifecycle; no group/tree lookup on snapshots.
	for spec in [[WEB,"spider_projectile"],[ARROW,"skeleton_archer_projectile"]]:
		var actor = battle.acquire_projectile(spec[0],spec[1])
		actor.global_position = battle.hero.position+Vector2(300,0)
		if spec[0]==WEB: actor.setup(Vector2.RIGHT,1,320.0,360.0,0.72,1.5,false)
		else: actor.setup(Vector2.RIGHT,1,300.0,190.0,false,false)
		var id: int = actor.get_instance_id()
		var handle: Vector3i = battle.get_battle_entity_handle(actor)
		check(battle.online_visual_projectiles.has(id),"acquire registers active projectile")
		snapshot = room.snapshot()
		var source: String = actor.projectile_sprite.sprite_frames.get_frame_texture(&"fly",0).resource_path
		var present := false
		for command in snapshot.visuals:
			if command[1]==source: present = true
		check(present,"real enemy projectile PNG appears in wire snapshot")
		check(view.update_state(snapshot),"enemy projectile reaches render-only view")
		battle.recycle_projectile(actor,spec[1])
		check(not battle.online_visual_projectiles.has(id) and not actor.active,"pool return removes active record")
		var reused = battle.acquire_projectile(spec[0],spec[1])
		check(reused==actor and battle.get_battle_entity_handle(actor)!=handle,"reused actor receives new generation")
		reused.queue_free(); await process_frame
		check(not battle.online_visual_projectiles.has(id) and not room.presentation.node_cache.has(id),"tree exit clears registry and weak visual cache")
	# Compare shared pure render geometry against the old formulas.
	for pattern in ["beam","capsule","slash"]:
		for length in [0.0,30.0,200.0]:
			for radius in [5.0,40.0]:
				var expected := Rect2(Vector2(length*0.2,-length*0.3),Vector2.ONE*length*0.6) if pattern=="slash" else Rect2(Vector2(0,-radius),Vector2(sqrt(maxf(0,length*length-radius*radius)),radius*2))
				check(GEO.effect_texture_rect(pattern,length,radius)==expected,"shared rectangle preserves old rendering")
	var weapons = battle.hero.player_weapons
	var frames: Array = []
	for candidate in weapons.art.values():
		if not candidate.is_empty(): frames = candidate; break
	var effect: Dictionary = weapons.effects[0]
	effect.left = 0.5; effect.duration = 1.0; effect.a = Vector2(100,100); effect.b = Vector2(300,100); effect.radius = 40.0; effect.frames = frames
	var sampler := SAMPLE.new()
	for pattern in ["beam","capsule","slash","combo","orbit"]:
		effect.pattern = pattern
		var output: Array = []; sampler.append_weapon_areas(weapons,output)
		check(output.size()==(int(effect.orbit_count) if pattern=="orbit" else 1),"missing PNG effect adapter: "+pattern)
		for command in output: check(ART.valid(command),"effect command validates")
	effect.left = 0.0
	view.clear_state(); check(not view.battlefield.visible and view.render_visuals.is_empty(),"queue/rematch hides old castle")
	check(view.prepare_battlefield(room.battlefield_info) and view.battlefield.rebuilds==builds,"same arena reuses configured visual scene")
	room.finish("","fixture_done"); view.queue_free(); room.queue_free(); await create_timer(0.2).timeout
	print("ONLINE_CASTLE_EFFECTS_PASS checks=",checks); quit()
