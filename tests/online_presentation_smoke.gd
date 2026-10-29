extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const VIEW := preload("res://src/online/battle_view.gd")
const RULES := preload("res://src/online/match_rules.gd")
const ART := preload("res://src/data/online_presentation_catalog.gd")
const SAMPLER := preload("res://src/online/presentation_snapshot.gd")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var room = ROOM.new(); root.add_child(room); room.prepare(); room.start()
	var battle = room.battle
	battle.process_mode = Node.PROCESS_MODE_DISABLED; battle.demon_exp_gain_multiplier = 0.0
	var point: Vector2 = battle.hero.position + Vector2(300,0)
	for id in RULES.ROSTER:
		battle.command_power = RULES.OPENING_MANA
		check(room.apply("demon","summon",{"id":id,"point":[point.x,point.y]}),"actual art roster spawn: "+id)
	var sprite: AnimatedSprite2D = battle.hero.hero_sprite
	sprite.animation = &"attack"; sprite.frame = 2; sprite.flip_h = true
	var snapshot: Dictionary = room.snapshot()
	check(not snapshot.visuals.is_empty(),"server emits existing PNG render state")
	var owners := {}
	var hero_command: Array = []
	var previous_z := -1000000.0
	for command in snapshot.visuals:
		check(ART.valid(command),"wire render command validates")
		check(command[20] >= previous_z,"server preserves render layer order")
		previous_z = command[20]; owners[int(command[0])] = true
		if int(command[0]) == 0 and command[1] == sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame).resource_path: hero_command = command
	check(not hero_command.is_empty() and hero_command[6] < 0,"current hero attack PNG and flip sampled")
	check(is_equal_approx(absf(hero_command[6]),sprite.global_transform.x.length()),"original automatic normalization scale retained")
	check(is_equal_approx(hero_command[10],sprite.global_position.x) and is_equal_approx(hero_command[11],sprite.global_position.y),"actual body anchor retained")
	for actor in snapshot.actors: check(owners.has(int(actor[0])),"each real monster body has PNG commands")
	var view = VIEW.new(); view.size = Vector2(1080,1200); root.add_child(view)
	check(view.update_state(snapshot),"client accepts authoritative presentation")
	await process_frame
	check(view.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and view.clip_contents,"pixel filtering and panel clipping")
	check(view.painted_owners.has(0) and view.painted_owners.size() >= RULES.ROSTER.size()+1,"imported PNGs available on view")
	var requests: int = view.texture_requests
	for index in 10: check(view.update_state(snapshot),"repeat snapshot accepted")
	check(view.texture_requests == requests and view.pending_textures.is_empty(),"cache prevents repeated loading and idle polling")
	check(view.find_children("*","CollisionObject2D",true,false).is_empty(),"client creates no Hero/monster/physics nodes")
	var uncached_path := "res://assets/art/heroes/item/heal_frames/float_01.png"
	check(not ResourceLoader.has_cached(uncached_path),"async fixture PNG is initially uncached")
	var async_command: Array = hero_command.duplicate()
	async_command[1] = uncached_path
	async_command[2] = 0.0; async_command[3] = 0.0; async_command[4] = 1.0; async_command[5] = 1.0
	var async_state: Dictionary = snapshot.duplicate(true); async_state.visuals = [async_command]
	check(view.update_state(async_state) and view.pending_textures.has(uncached_path),"uncached PNG queues asynchronous load")
	var load_deadline := Time.get_ticks_msec()+6000
	while not view.pending_textures.is_empty() and Time.get_ticks_msec()<load_deadline: await process_frame
	check(view.art_textures.get(uncached_path) is Texture2D and not view.is_processing(),"async completion caches PNG and stops polling")
	view.update_state(snapshot)
	var abandoned = VIEW.new(); root.add_child(abandoned)
	abandoned._request_texture("res://assets/art/heroes/item/heal_frames/float_02.png")
	check(not abandoned.pending_textures.is_empty(),"view can leave with an in-flight PNG request")
	var drain = abandoned.load_drain
	abandoned.queue_free()
	load_deadline = Time.get_ticks_msec()+6000
	while is_instance_valid(drain) and Time.get_ticks_msec()<load_deadline: await process_frame
	check(not is_instance_valid(drain),"outgoing view drains requests and removes its loader")
	for bad_path in ["res://src/hero/hero.gd","res://assets/art/../secret.png","https://example.invalid/a.png"]:
		var bad: Dictionary = snapshot.duplicate(true); bad.visuals[0][1] = bad_path
		check(not view.update_state(bad),"unapproved paths rejected atomically")
	var malformed: Dictionary = snapshot.duplicate(true); malformed.visuals[0][6] = NAN
	check(not view.update_state(malformed) and view.state == snapshot,"nonfinite pose does not replace last good state")
	malformed = snapshot.duplicate(true); malformed.visuals.resize(ART.MAX_COMMANDS+1)
	check(not view.update_state(malformed),"oversized render list rejected")
	# Shared AtlasTexture trimming is carried over without recentering each frame.
	var sampler = SAMPLER.new()
	var atlas := AtlasTexture.new(); atlas.atlas = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame); atlas.region = Rect2(1,2,16,18)
	var commands: Array = []
	sampler.append_texture(atlas,0,Transform2D.IDENTITY,Rect2(-8,-9,16,18),Color.WHITE,commands)
	check(commands.size()==1 and commands[0][2]==1 and commands[0][3]==2 and commands[0][4]==16 and commands[0][5]==18,"original atlas crop retained")
	# Fill the real roster cap and all existing generic projectile slots.
	while battle.active_monsters.size() < room.battle.get_population_limit():
		battle.command_power = RULES.OPENING_MANA
		check(room.apply("demon","summon",{"id":RULES.ROSTER[0],"point":[point.x,point.y]}),"populate online cap")
	var weapons = battle.hero.player_weapons
	var frames: Array = []
	for available in weapons.art.values():
		if not available.is_empty(): frames = available; break
	check(not frames.is_empty(),"actual weapon effect PNG frames imported")
	var areas: Array = []
	var field: Dictionary = weapons.fields[0]
	field.left = 1.0; field.radius = 100.0; field.origin = point; field.frames = frames
	var effect: Dictionary = weapons.effects[0]
	effect.left = 0.5; effect.duration = 1.0; effect.a = point; effect.b = point+Vector2(200,0); effect.frames = frames; effect.pattern = "chain"
	sampler.append_weapon_areas(weapons,areas)
	check(areas.size()==2,"persistent area and chain PNG adapters")
	check(is_equal_approx(areas[0][14],float(field.radius)*sqrt(2.0)) and is_equal_approx(areas[0][19],0.75),"original area texture geometry/alpha")
	check(is_equal_approx(areas[1][14],200.0) and is_equal_approx(areas[1][15],preload("res://src/hero_mode/hero_weapon_geometry.gd").CHAIN_DRAW_WIDTH) and is_equal_approx(areas[1][19],0.5),"shared chain texture geometry/alpha")
	field.left = 0.0; effect.left = 0.0
	var native = weapons.native_skills.actors_by_pattern["piercer"][0]
	native.global_position = point; native.setup(Vector2.RIGHT,1,300.0,300.0)
	var native_commands: Array = []
	sampler.append_tree(native,-1,native_commands)
	check(not native_commands.is_empty(),"actual pooled piercing skill PNG sampled")
	var native_texture: Texture2D = native.visual.sprite_frames.get_frame_texture(&"fly",0)
	var raw_image := Image.new()
	check(raw_image.load_png_from_buffer(FileAccess.get_file_as_bytes(native_commands[0][1])) == OK and raw_image.get_data() == native_texture.get_image().get_data(),"raw PNG source identity preserves all native RGBA bytes")
	native.deactivate_for_pool()
	for shot in weapons.projectiles:
		shot.active = true; shot.melee = false; shot.delay = 0.0; shot.frames = frames
		shot.visual_radius = 28.0
		shot.position = point; shot.direction = Vector2.RIGHT; shot.age = 0.1
	snapshot = room.snapshot()
	check(snapshot.visuals.size() <= ART.MAX_COMMANDS,"presentation work bounded under full projectile slots")
	check(not preload("res://src/online/match_server.gd")._encode(snapshot).is_empty(),"full roster/projectile packet fits existing byte budget")
	print("ONLINE_PRESENTATION_BYTES ",JSON.stringify(snapshot).to_utf8_buffer().size())
	owners.clear()
	var weapon_art := false
	for command in snapshot.visuals:
		owners[int(command[0])] = true
		if int(command[0]) == -1: weapon_art = true
	for actor in snapshot.actors: check(owners.has(int(actor[0])),"body art priority under FX saturation")
	check(weapon_art and view.update_state(snapshot),"actual generic projectile PNG reaches client")
	for shot in weapons.projectiles: shot.active = false
	var retired = battle.active_monsters.values()[0]
	var retired_id: int = retired.get_instance_id()
	check(room.presentation.node_cache.has(retired_id),"server cached visual subtree")
	battle.active_monsters.erase(retired_id); room.snapshot()
	check(not room.presentation.node_cache.has(retired_id),"retired actor clears visual node cache")
	view.clear_state(); check(view.state.is_empty() and view.painted_owners.is_empty(),"rematch clears previous mirror")
	room.finish("","fixture_done"); view.queue_free(); room.queue_free(); await create_timer(0.2).timeout
	print("ONLINE_PRESENTATION_PASS checks=",checks); quit()
