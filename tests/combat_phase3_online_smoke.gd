extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const SERVER := preload("res://src/online/match_server.gd")
const POPUPS := preload("res://src/ui/damage_number_spawner.gd")
const CODEC := preload("res://src/online/snapshot_codec.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func baseline():
	var script := GDScript.new(); script.source_code = FileAccess.get_file_as_string("res://tests/fixtures/combat_phase3/battle_room_before.gd.txt")
	check(script.reload() == OK,"frozen snapshot compiles"); return script
# The frozen baseline predates later snapshot fields (battlefield, visuals,
# primitives, feedback). Compare the fields it produces, in wire order.
func baseline_fields(before: Dictionary, after: Dictionary) -> Dictionary:
	var result := {}
	for key in after:
		if before.has(key): result[key] = after[key]
	return result
func added_fields(before: Dictionary, after: Dictionary) -> Array:
	var result: Array = []
	for key in after:
		if not before.has(key): result.append(key)
	return result
# Protocol 7 interns PNG paths on the wire; decoding must restore the snapshot.
func codec_round_trip(codec, message: Dictionary) -> bool:
	var wire: String = codec.encode(message)
	var decoded: Variant = JSON.parse_string(wire)
	if wire.is_empty() or not decoded is Dictionary or not CODEC.expand(decoded): return false
	return decoded == JSON.parse_string(SERVER._encode(message))
func stop_audio(host) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	var old_script = baseline(); var rooms: Array = []
	var codec = CODEC.new()
	var later_fields := ["battlefield", "visuals", "primitives", "feedback", "feedback_cursor"]
	for index in 2:
		var room := ROOM.new(); root.add_child(room); room.prepare(); rooms.append(room)
		var previous = old_script.new(); previous.battle = room.battle
		room.battle.hero_player_mode = false
		for actor_index in 48:
			var actor = room.battle._spawn_monster("orc",room.battle.hero.position+Vector2(90+actor_index*3,50))
			check(is_instance_valid(actor),"48 authoritative actors")
		room.battle.hero_player_mode = true
		var first = room.battle.active_monsters.values()[0]
		for frame in 40:
			first.position += Vector2(.13,-.29); first.current_hp = maxi(0,first.current_hp-1)
			if frame == 8:
				var handle: Vector3i = room.battle.get_battle_entity_handle(first)
				room.battle.battle_entity_registry.retire(handle); room.battle._activate_battle_entity(first)
			if frame == 16:
				var gone = room.battle.active_monsters.values()[-1]; gone.free()
			var before: Dictionary = previous.snapshot(); var after := room.snapshot()
			var shared := baseline_fields(before, after)
			check(shared.size() == before.size() and JSON.stringify(before) == SERVER._encode(shared),"wire/ID/order/generation parity")
			check(added_fields(before, after) == later_fields,"only known later snapshot fields added")
			check(codec_round_trip(codec, after),"path-interned wire decodes to the same snapshot")
			check(room.ids.size() == room.battle.active_monsters.size(),"wire registry pruned without scratch snapshots")
		previous.free()
	var unchanged: String = SERVER._encode(rooms[1].snapshot())
	rooms[0].battle.active_monsters.values()[0].position += Vector2(13,0)
	check(SERVER._encode(rooms[1].snapshot()) == unchanged,"other room snapshot isolated")
	check(rooms[0].world.world_2d != rooms[1].world.world_2d,"physics worlds isolated")
	check(SERVER._encode({"message":"가".repeat(40000)}) == "","oversized UTF8 packet still rejected")
	# Number-only authoritative popup keeps the same merge/RNG/lifetime semantics.
	var actor = rooms[0].battle.active_monsters.values()[0]
	POPUPS.show(actor,20); var popup = actor.get_meta("damage_number_popup")
	check(popup.value_label == null and popup.numeric_amount == 20,"authoritative popup omits Label")
	POPUPS.show(actor,7); check(actor.get_meta("damage_number_popup") == popup and popup.numeric_amount == 27,"same owner merges")
	check(rooms[1].battle.get_meta("_damage_number_pool",[]).is_empty(),"popup pool isolated")
	for room in rooms: stop_audio(room); room.free()
	stop_audio(root.get_node("GameAudio"))
	print("COMBAT_PHASE3_ONLINE checks=",checks," failures=",failures); quit(1 if failures else 0)
