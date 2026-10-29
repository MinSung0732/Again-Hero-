extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const SERVER := preload("res://src/online/match_server.gd")
const POPUPS := preload("res://src/ui/damage_number_spawner.gd")
const CODEC := preload("res://src/online/snapshot_codec.gd")
const FEEDBACK := preload("res://src/data/online_feedback_catalog.gd")
const RULES := preload("res://src/online/match_rules.gd")
var checks := 0
var failures := 0
var max_snapshot_bytes := 0
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
# Protocol 11 retains PNG path interning; decoding must restore the snapshot.
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
	var later_fields := ["hero_archetype", "battlefield", "summon_costs", "demon_level", "demon_rerolls_left", "demon_reroll_limit", "demon_exp", "demon_exp_next", "demon_charge", "demon_charge_max", "demon_cooldowns", "demon_ready", "transcend_ready", "transcend_used", "exp_orbs", "visuals", "primitives", "feedback", "feedback_cursor"]
	for index in 2:
		var room := ROOM.new(); root.add_child(room); room.prepare(); rooms.append(room)
		var demon_state: Dictionary = room.snapshot("demon")
		var hero_state: Dictionary = room.snapshot("hero")
		check(demon_state.has("elite_choice") and demon_state.has("elite_cards") and demon_state.has("elite_pending"),"demon receives elite fields")
		check(not hero_state.has("elite_choice") and not hero_state.has("elite_cards") and not hero_state.has("elite_pending"),"hero does not receive elite fields")
		room.feedback.publish("hero_hit",room.battle.hero.position,1,Color.WHITE,room.tick,room.battle.hero.get_instance_id())
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
			check(not after.has("choice_revision") and not after.has("choices"),"obsolete shared choice fields removed")
			before.erase("choice_revision"); before.erase("choices")
			var shared := baseline_fields(before, after)
			# Protocol 22 retains the bar row extension; the frozen prefix must still match.
			check(after.hero.size() == before.hero.size()+1 and after.hero[-1] is Array,"hero row appends only the bar array")
			shared["hero"] = after.hero.slice(0,before.hero.size())
			var trimmed: Array = []
			for row in after.actors:
				check(row.size() == 7 and row[-1] is Array,"actor row appends only the bar array")
				trimmed.append(row.slice(0,6))
			shared["actors"] = trimmed
			check(shared.size() == before.size() and JSON.stringify(before) == SERVER._encode(shared),"wire/ID/order/generation parity")
			check(added_fields(before, after) == later_fields,"only known later snapshot fields added")
			check(FEEDBACK.valid_events(after.feedback,after.feedback_cursor,after.tick),"protocol 24 feedback row shape valid")
			check(not after.has("hero_skill_cooldowns"),"player hero has no AI skill cooldown wire (protocol 25)")
			var snapshot_bytes := JSON.stringify(after).to_utf8_buffer().size()
			max_snapshot_bytes = maxi(max_snapshot_bytes, snapshot_bytes)
			check(snapshot_bytes <= RULES.MAX_SNAPSHOT,"48 actor snapshot fits MAX_SNAPSHOT")
			check(after.feedback.size()==1 and after.feedback[0].size()==FEEDBACK.EVENT_SIZE,"feedback row appends owner and critical")
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
	print("COMBAT_PHASE3_ONLINE checks=",checks," failures=",failures," max_snapshot_bytes=",max_snapshot_bytes); quit(1 if failures else 0)
