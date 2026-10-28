extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const VIEW := preload("res://src/online/battle_view.gd")
const DATA := preload("res://src/data/online_feedback_catalog.gd")
const BUFFER := preload("res://src/online/feedback_buffer.gd")
const PRIMITIVES := preload("res://src/online/primitive_mirror.gd")
const GEO := preload("res://src/hero_mode/hero_weapon_geometry.gd")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var room = ROOM.new(); root.add_child(room); room.prepare(); room.start()
	room.battle.process_mode = Node.PROCESS_MODE_DISABLED
	var view = VIEW.new(); root.add_child(view); view.size = Vector2(1080,1200)
	var client = view.feedback
	client.reset(room.feedback.sequence); client.suspended = false
	var target: Vector2 = room.battle.hero.position+Vector2(300,0)
	check(room.apply("demon","summon",{"id":"slime","point":[target.x,target.y]}),"real accepted summon")
	var monster = room.battle.active_monsters.values()[0]
	var old_hp: int = monster.current_hp
	monster.take_damage(7)
	check(monster.current_hp==old_hp-7,"damage outcome unchanged")
	check(room.feedback.snapshot()[-1][2]=="monster_hit" and room.feedback.snapshot()[-1][5]==7,"actual popup amount captured before pool merge")
	var hero = room.battle.hero
	hero.current_hp = hero.max_hp; hero.shield_hp = 0; hero.invulnerability_timer = 0
	hero.take_damage(9,monster)
	check(room.feedback.snapshot()[-1][2]=="hero_hit","accepted real hero hit captured")
	hero.heal_direct(4)
	check(room.feedback.snapshot()[-1][2]=="heal","actual recovery captured")
	hero.player_weapons._cast(hero.player_weapons.identity.starter)
	check(room.feedback.snapshot()[-1][2]=="cast","actual starter attack emits existing sound cue")
	var codec := preload("res://src/online/snapshot_codec.gd").new()
	var encoded := codec.encode(room.snapshot())
	var snapshot: Dictionary = JSON.parse_string(encoded)
	check(not encoded.is_empty() and preload("res://src/online/snapshot_codec.gd").expand(snapshot),"actual damage survives server codec and JSON transport")
	check(DATA.valid_events(snapshot.feedback,snapshot.feedback_cursor,snapshot.tick),"authoritative wire validates")
	check(view.update_state(snapshot),"state and primitives accepted")
	check(client.consume(snapshot.feedback,snapshot.feedback_cursor,snapshot.tick),"consume accepted")
	check(client.accepted==snapshot.feedback.size(),"all live feedback handled once")
	var damage_visible := false
	for popup in client.get_meta(preload("res://src/ui/damage_number_spawner.gd").POOL_META,[]):
		if popup.is_pool_active() and popup.value_label != null and popup.value_label.is_visible_in_tree() and popup.numeric_amount == 7: damage_visible = true
	check(damage_visible and client.displayed >= 3,"real monster damage, hero damage and healing reach visible Labels")
	var accepted: int = client.accepted; var sounds: int = client.bank.played_count
	for _repeat in 10: check(client.consume(snapshot.feedback,snapshot.feedback_cursor,snapshot.tick),"repeat snapshot valid")
	check(client.accepted==accepted and client.bank.played_count==sounds,"repeated state cannot duplicate audio/popups")
	check(sounds>=3,"actual imported summon/hit/cast streams start")
	for cue in DATA.CUES:
		check(client.bank.players[cue].stream!=null and client.bank.players[cue].bus==&"SFX","cue uses real stream and settings bus: "+cue)
	client.reset(snapshot.feedback_cursor); client.suspended = false
	client.consume(snapshot.feedback,snapshot.feedback_cursor,snapshot.tick)
	check(client.accepted==accepted,"resume baseline suppresses historical feedback")
	room.battle.online_cast_feedback.emit("cast",hero.global_position)
	var newer: Dictionary = room.snapshot(); client.pause_feedback()
	client.consume(newer.feedback,newer.feedback_cursor,newer.tick)
	client.suspended = false; client.consume(newer.feedback,newer.feedback_cursor,newer.tick)
	check(client.accepted==accepted,"loading/pause suppression cannot replay on resume")
	room.battle.online_cast_feedback.emit("cast",hero.global_position)
	newer = room.snapshot()
	client.consume(newer.feedback,newer.feedback_cursor,newer.tick+10000)
	check(client.accepted==accepted,"stale effects skipped after lag")
	var before: int = client.baseline
	for bad in [[["bad"]], [[1,0,"hero_hit",NAN,0,5,1,1,1,1]], [[1,0,"hero_hit",0,0,5,2,1,1,1]], [[2,0,"cast",0,0,0,1,1,1,1],[1,0,"cast",0,0,0,1,1,1,1]]]:
		check(not client.consume(bad,99,10) and client.baseline==before,"bad wire leaves dedup baseline unchanged")
	# Saturation preserves hero-hit feedback in a separately reserved fixed ring.
	var buffer = BUFFER.new(); buffer.publish("hero_hit",Vector2.ZERO,1,Color.WHITE,0)
	for index in 200: buffer.publish("monster_hit",Vector2(index,0),1,Color.WHITE,0)
	var rows: Array = buffer.snapshot(); var hero_present := false
	for row in rows:
		if row[2]=="hero_hit": hero_present = true
	check(rows.size()<=DATA.CAPACITY and hero_present and DATA.valid_events(rows,buffer.sequence,0),"bounded burst retains hero feedback")
	# Each primitive is sampled from the original effect shapes and pure geometry.
	var weapons = hero.player_weapons
	for field in weapons.fields: field.left = 0
	for effect in weapons.effects: effect.left = 0
	var effect: Dictionary = weapons.effects[0]
	effect.left=0.5; effect.duration=1.0; effect.a=Vector2(100,100); effect.b=Vector2(300,100); effect.radius=40.0; effect.frames=[]
	for pattern in ["beam","slash","capsule","chain","combo","bolt","orbit","nova"]:
		effect.pattern=pattern
		effect.shape = GEO.sector(effect.radius) if pattern=="slash" else GEO.capsule(200,effect.radius) if pattern=="capsule" else GEO.beam(200,effect.radius)
		var commands: Array = PRIMITIVES.capture(weapons)
		check(not commands.is_empty() and PRIMITIVES.valid(commands),"procedural adapter: "+pattern)
		view.primitives.replace(commands)
		check(view.primitives.parsed.size()==commands.size(),"points decoded once per snapshot")
		if pattern in ["beam","slash","capsule"]:
			check(view.primitives.parsed[0].points==effect.shape,"source polygon unchanged")
	effect.pattern = "capsule"; effect.shape = GEO.capsule(700.25,140.5)
	for index in weapons.effects.size():
		weapons.effects[index].merge(effect,true)
	var commands: Array = PRIMITIVES.capture(weapons)
	check(commands.size()==DATA.MAX_PRIMITIVES,"primitive saturation bounded")
	check(not PRIMITIVES.valid([["bad"]]),"malformed primitive rejected")
	var original: Dictionary = room.snapshot()
	var body: Array = original.visuals[0].duplicate()
	original.visuals.clear()
	for _index in preload("res://src/data/online_presentation_catalog.gd").MAX_COMMANDS: original.visuals.append(body.duplicate())
	original.feedback = rows; original.feedback_cursor = buffer.sequence
	check(JSON.stringify(original).to_utf8_buffer().size()<preload("res://src/online/match_rules.gd").MAX_SNAPSHOT,"representative event/vector snapshot within wire budget")
	print("ONLINE_FEEDBACK_SNAPSHOT_BYTES=",JSON.stringify(original).to_utf8_buffer().size())
	var malformed: Dictionary = original.duplicate(true); malformed.primitives = [["bad"]]
	check(not view.update_state(malformed),"malformed vector state rejected transactionally")
	client.result("hero","hero"); var after_result: int = client.bank.played_count
	client.result("demon","hero")
	check(client.bank.played_count==after_result,"terminal cue idempotent")
	view.clear_state()
	check(not client.is_processing() and view.primitives.parsed.is_empty(),"rematch clears transient pool and primitives")
	# ResourceLoader workers outlive a render-only view until its drain consumes them.
	var deadline := Time.get_ticks_msec()+5000
	while not view.pending_textures.is_empty() and Time.get_ticks_msec()<deadline: await process_frame
	check(view.pending_textures.is_empty(),"all pending PNG loads resolved before test teardown")
	client.bank.stop_all()
	room.finish("","fixture_done"); view.queue_free(); room.queue_free(); await process_frame; await create_timer(0.5).timeout
	print("ONLINE_FEEDBACK_PASS checks=",checks); quit()
