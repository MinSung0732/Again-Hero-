extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const COSMETICS := preload("res://src/systems/profile_cosmetic_store.gd")
const PROFILE := preload("res://src/data/profile_cosmetic_catalog.gd")
const LOADOUT := preload("res://src/systems/transcendence_loadout_store.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const DETAILS := preload("res://src/data/transcendent_detail_catalog.gd")
const ICONS := preload("res://src/data/skill_icon_catalog.gd")
const CUTSCENE := preload("res://src/data/transcendent_cutscene_catalog.gd")
const OVERLAY := preload("res://src/ui/gacha_reveal_overlay.gd")
var failures := 0
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ARTHUR_INTEGRATION: "+message)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://arthur_integration_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	check(SHOP.get_monster_pool("transcendent").size()==6 and "arthur" in SHOP.get_monster_pool("transcendent"),"shop/test pool")
	check(is_equal_approx(SHOP.get_effective_probability("transcendent"),0.5),"rarity unchanged")
	check(not LOADOUT.save_id("arthur"),"locked cannot register")
	var roll := {"monster_id":"arthur","source":"local_test","rarity":"transcendent","shards":1}
	var award := COLLECTION.award_shard_batch([roll],0)
	check(award.success and award.state.arthur.unlocked,"unlock")
	check("arthur" in COSMETICS.choices("avatar") and "arthur" in COSMETICS.choices("banner"),"unlock profile rewards")
	check("arthur_plus_banner" not in COSMETICS.choices("banner"),"five banner locked")
	check(LOADOUT.save_id("arthur"),"register saved")
	var state := COLLECTION.load_state()
	for id in ["arthur","bulgasal","izanami","shuten_doji"]:
		state[id] = {"unlocked":true,"level":4,"shards":1}
		COLLECTION.save_state(state)
		check(COLLECTION.try_upgrade(id).success,"fifth upgrade "+id)
		state = COLLECTION.load_state()
		check(id+"_plus_banner" in COSMETICS.choices("banner"),"fifth banner awarded "+id)
		check(ResourceLoader.exists(PROFILE.path(id+"_plus_banner","banner")),"case correct asset "+id)
	for skill in DETAILS.ENTRIES.arthur.skills:
		check(ICONS.texture("transcendent","arthur",skill.name)!=null,"skill icon "+skill.name)
	var saved := FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("monster_collection.cfg"))
	var overlay = OVERLAY.new()
	root.add_child(overlay)
	overlay.present([roll])
	overlay._sequence_token += 1
	overlay._show_reveal(0)
	check(overlay._phase=="cutscene","real gacha dispatch")
	overlay._cutscene.set_process(false)
	overlay._cutscene.advance(5)
	check(overlay._phase=="reveal","gacha ends once")
	check(saved==FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("monster_collection.cfg")),"no duplicate reward")
	overlay.free()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	battle._monster_spawn_resources_warmed = true
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	battle.hero.set_physics_process(false)
	check(battle.transcendence.monster_id=="arthur" and not battle.transcendence.ready,"actual battle loadout")
	var normal_tank = battle._spawn_monster("orc",Vector2(200,200),0,false,{"counts_population":true})
	check(is_instance_valid(normal_tank) and battle.raw_real_tank_summons==1,"actual summon counter")
	normal_tank.set_physics_process(false)
	var augment_tank = battle._spawn_monster("orc",Vector2(220,200),0,false,{})
	check(is_instance_valid(augment_tank) and battle.raw_real_tank_summons==1,"augment summon excluded from growth")
	augment_tank.set_physics_process(false)
	battle.transcendence.configure("arthur",preload("res://src/data/arthur_behavior_catalog.gd").RULES)
	battle.raw_real_tank_summons = 40
	for i in range(40): battle.transcendence.record_summon("tank")
	for i in range(50): battle.transcendence.record_ally_death()
	check(battle.try_summon_transcendent(),"actual summon")
	var actor = battle.transcendent_actor
	actor.set_physics_process(false)
	check(actor.max_hp==2600 and actor.attack_damage==230 and actor.transcend_level==5,"snapshot routed")
	check(not battle.try_summon_transcendent(),"once per battle")
	actor.set_meta("arthur_gate_active",true)
	actor.gate_boost_count = 2
	check(is_equal_approx(battle.get_transcendent_aura_modifier(actor,"outgoing"),1.5*1.009),"gate attack buff and Arthur count")
	actor.set_meta("arthur_gate_active",false)
	# Run the full Arthur physics state machine against the actual Hero, not a
	# Target mock with a different death flag. This catches the original bool(null).
	battle.external_pause = false
	battle.demon_augment_selection_active = false
	actor.transcend_level = 0
	actor.arrival_remaining = 0
	actor.shielded_arrival = true
	actor.gauge = 50
	actor.cooldowns[1] = 100
	actor.cooldowns[2] = 100
	actor.attack_timer = 0
	actor.hero = battle.hero
	battle.hero.current_hp = 1000000
	actor.global_position = battle.to_global(battle.clamp_monster_wander_position(battle.current_map_size*0.5))
	var dash_start: Vector2 = actor.global_position
	battle.hero.global_position = dash_start+Vector2(200,0)
	check(actor._alive(battle.hero),"actual Hero uses is_dying")
	battle.hero.is_dying = true
	check(not actor._alive(battle.hero),"actual Hero death flag rejected")
	battle.hero.is_dying = false
	for i in range(26): actor._physics_process(0.02)
	check(actor.dash_remaining > 0 and actor.collision_mask == 0,"actual physics enters collision-free dash")
	for i in range(10): actor._physics_process(0.02)
	check(actor.global_position.x >= dash_start.x+179,"actual physics moves at 900px/sec")
	check(actor.visual.animation == &"skill" and actor.visual.frame == 0,"actual rush skill_01 held")
	check(actor.fx_age[0] >= 0 and actor.front_effects.z_index > actor.visual.z_index,"actual foreground dash FX")
	actor._tick_dash(2)
	check(battle._is_spawn_position_inside_bounds(actor.position),"rush stops inside map")
	check(not actor.dash_collision_disabled and not actor.visual._one_shot_locked,"landing restores collision and idle")
	var body_texture: Texture2D = actor.visual.sprite_frames.get_frame_texture(&"idle",0)
	check(is_equal_approx(body_texture.get_image().get_used_rect().size.y*actor.visual.scale.y,108.0),"combat body at ninety percent")
	# Put a real static decor footprint exactly at the next rush's terminal point.
	actor.position = battle.clamp_monster_wander_position(battle.current_map_size*0.5)
	battle.hero.global_position = actor.global_position+Vector2(100,0)
	actor.dash_direction = Vector2.RIGHT
	actor.dash_origin = actor.global_position
	var landing: Vector2 = actor._clamp_dash_point(actor.global_position+Vector2(1000,0))
	var decor := StaticBody2D.new()
	decor.collision_layer = 1 << 2
	decor.collision_mask = 0
	decor.global_position = landing
	var footprint := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(160,160)
	footprint.shape = rectangle
	decor.add_child(footprint)
	battle.add_child(decor)
	await physics_frame
	actor._start_dash_channel()
	actor._physics_process(0.5)
	actor._tick_dash(2)
	check(actor.global_position.distance_to(landing) >= 96,"lands outside decor footprint")
	check(battle._is_spawn_position_inside_bounds(actor.position),"decor escape remains inside map")
	actor.collision_mask = 12
	check(not actor._landing_blocked(actor.global_position),"restored landing not stuck in static collider")
	actor.collision_mask = actor.saved_collision_mask
	decor.free()
	var minimum: Vector2 = battle.clamp_monster_wander_position(Vector2.ZERO)
	var maximum: Vector2 = battle.clamp_monster_wander_position(battle.current_map_size)
	var middle := (minimum+maximum)*0.5
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		actor.position = middle
		if direction.x>0: actor.position.x = maximum.x-10
		elif direction.x<0: actor.position.x = minimum.x+10
		elif direction.y>0: actor.position.y = maximum.y-10
		else: actor.position.y = minimum.y+10
		battle.hero.global_position = actor.global_position+direction*100
		actor._begin_dash()
		check(actor.dash_remaining <= 10.1,"boundary shortens straight rush "+str(direction))
		actor._tick_dash(2)
		check(battle._is_spawn_position_inside_bounds(actor.position),"four map sides bounded "+str(direction))
	var view = load("res://src/ui/arthur_battle_summon_view.gd").new()
	root.add_child(view)
	view.size = Vector2(540,960)
	for time in [0.0,0.5,1.5,2.0,2.2,3.5,5.0]: view.set_time(time)
	check(view.corner_triangle and view.rig.bones.size()==7,"battle view native rig")
	view.free()
	battle.free()
	await process_frame
	print("ARTHUR_INTEGRATION: %s (%d checks)"%["PASS" if failures==0 else "FAIL",checks])
	quit(0 if failures==0 else 1)
