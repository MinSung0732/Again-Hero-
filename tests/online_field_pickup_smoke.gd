extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const VIEW := preload("res://src/online/battle_view.gd")
const CODEC := preload("res://src/online/snapshot_codec.gd")
const ART := preload("res://src/data/online_presentation_catalog.gd")
const PNG := preload("res://src/ui/png_texture_source.gd")
const HEAL := preload("res://src/battle/heal_item.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: run.call_deferred()
func frame_path(item) -> String:
	return PNG.path(item.visual.sprite_frames.get_frame_texture(item.visual.animation,item.visual.frame))
func find_command(snapshot: Dictionary,path: String) -> Array:
	for command in snapshot.visuals:
		if command[1] == path: return command
	return []
func stop_audio(host: Node) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var room := ROOM.new(); root.add_child(room); room.prepare(); room.start()
	var other := ROOM.new(); root.add_child(other); other.prepare(); other.start()
	var battle = room.battle
	battle.process_mode = Node.PROCESS_MODE_DISABLED
	other.battle.process_mode = Node.PROCESS_MODE_DISABLED
	check(not battle._hero_chest_eligible("kills"),"natural chest eligibility is reserved for the next stage")
	battle._spawn_random_heal_item(); battle._spawn_random_magnet_item()
	check(battle._spawn_random_treasure_chest(),"existing chest factory still works")
	var heal = battle.active_heal_items.values()[0]
	var magnet = battle.active_magnet_items.values()[0]
	var chest = battle.active_treasure_chests.values()[0]
	var items: Array = [heal,magnet,chest]
	for index in items.size(): items[index].position = battle.hero.position+Vector2(200+index*90,0)
	check(room.presentation.field_items.size()==3,"direct pickup births enter the room presentation registry")
	room.presentation.track_field_item(heal)
	check(room.presentation.field_items.size()==3,"repeated registration never duplicates a pickup")
	var snapshot: Dictionary = room.snapshot()
	for item in items:
		var command := find_command(snapshot,frame_path(item))
		check(not command.is_empty(),"live item PNG reaches authoritative state")
		if not command.is_empty():
			check(ART.valid(command) and Vector2(command[10],command[11]).is_equal_approx(item.visual.global_position),"item command preserves source anchor and valid geometry")
			check(is_equal_approx(absf(command[6]),item.visual.global_scale.x) and int(command[20])==item.z_index+item.visual.z_index,"original item scale and render layer preserved")
	check(other.presentation.field_items.is_empty(),"other room never adopts foreign items")
	for item in items: check(find_command(other.snapshot(),frame_path(item)).is_empty(),"other room never publishes foreign item PNG")
	var codec := CODEC.new()
	var views: Array = []
	var before_hp: int = battle.hero.current_hp
	var before_exp: int = battle.hero.current_exp
	for role in ["hero","demon"]:
		var state: Dictionary = JSON.parse_string(codec.encode(room.snapshot_for_role(role,snapshot)))
		check(CODEC.expand(state),"existing JSON path codec expands item state for "+role)
		var view := VIEW.new(); view.hero_role = role=="hero"; root.add_child(view); view.size = Vector2(1080,1450)
		check(view.update_state(state),"role view accepts field items without a new protocol")
		for item in items: check(view.art_textures.get(frame_path(item)) is Texture2D,"role view resolves original item texture")
		views.append(view)
	check(battle.hero.current_hp==before_hp and battle.hero.current_exp==before_exp,"display and JSON transport never apply gameplay rewards")
	# Ability-created temporary heals bypass the normal drop registry/cap.
	var temporary = battle.HEAL_ITEM_SCENE.instantiate(); battle.add_child(temporary)
	temporary.position = battle.hero.position+Vector2(350,0); temporary.set_temporary_lifetime(0.1)
	check(room.presentation.field_items.size()==4 and battle.active_heal_items.size()==1,"temporary heal is visible without changing normal drop capacity")
	temporary.visual.hide()
	heal.visual.hide()
	check(find_command(room.snapshot(),frame_path(temporary)).is_empty(),"hidden/blinking source sprites are omitted")
	temporary.visual.show(); heal.visual.show(); temporary.visual.frame = 1
	check(not find_command(room.snapshot(),frame_path(temporary)).is_empty(),"actual temporary heal animation frame is sampled")
	var temporary_id: int = temporary.get_instance_id()
	temporary._physics_process(0.2)
	await process_frame
	check(not room.presentation.field_items.has(temporary_id) and not room.presentation.node_cache.has(temporary_id),"expiry retires both registry and sampler cache")
	check(battle.hero.current_hp==before_hp,"expiry does not grant healing")
	# Real authoritative collection, followed by a duplicate call before free.
	battle.hero.current_hp = maxi(1,battle.hero.max_hp-20)
	var missing: int = battle.hero.max_hp-battle.hero.current_hp
	var expected := mini(battle.hero.max_hp,battle.hero.current_hp+maxi(1,roundi((HEAL.HEAL_AMOUNT+roundi(missing*0.1))*maxf(battle.hero.heal_item_multiplier,0.0))))
	var heal_path := frame_path(heal)
	var heal_id: int = heal.get_instance_id()
	heal.position = battle.hero.position; heal._physics_process(0.0)
	check(battle.hero.current_hp==expected and heal.collected,"source heal pickup applies original recovery formula once")
	var recovered: int = battle.hero.current_hp
	heal._physics_process(0.0)
	check(battle.hero.current_hp==recovered,"duplicate pickup cannot grant healing again")
	check(find_command(room.snapshot(),heal_path).is_empty(),"collected queued item disappears before deferred free")
	battle._spawn_exp_orb(battle.hero.position+Vector2(600,0),1)
	other.battle._spawn_exp_orb(other.battle.hero.position+Vector2(600,0),1)
	var orb = room.exp_orb_visuals.active.values()[0].node
	var foreign_orb = other.exp_orb_visuals.active.values()[0].node
	var magnet_id: int = magnet.get_instance_id()
	magnet.position = battle.hero.position; magnet._physics_process(0.0)
	check(magnet.picked_up and orb.global_magnet_time_left>0.0,"real magnet pickup attracts the authoritative room EXP")
	check(foreign_orb.global_magnet_time_left==0.0,"magnet never attracts another room's EXP")
	magnet._physics_process(0.0)
	await process_frame
	check(not room.presentation.field_items.has(heal_id) and not room.presentation.field_items.has(magnet_id),"collection retires both item identities")
	for view in views:
		check(view.update_state(room.snapshot()),"post-collection state accepted")
		check(find_command(view.state,heal_path).is_empty(),"collected heal is absent on both role mirrors")
		view.clear_state(); check(view.render_visuals.is_empty(),"leave/rematch clears field item display")
		view.free()
	var bounded: Array = []
	for index in ART.MAX_COMMANDS-1: bounded.append([])
	room.presentation.append_field_items(bounded)
	check(bounded.size()==ART.MAX_COMMANDS and bounded[-1][1]==frame_path(chest),"final available render slot admits the field item")
	room.presentation.append_field_items(bounded)
	check(bounded.size()==ART.MAX_COMMANDS,"live items never expand the shared render command cap")
	var chest_id: int = chest.get_instance_id()
	chest.free()
	check(room.presentation.field_items.is_empty() and not room.presentation.node_cache.has(chest_id),"external removal clears final item and cached sprite references")
	stop_audio(room); stop_audio(other); room.free(); other.free()
	print("ONLINE_FIELD_PICKUP checks=",checks," failures=",failures)
	quit(1 if failures else 0)
