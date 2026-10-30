extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const VIEW := preload("res://src/online/battle_view.gd")
const RULES := preload("res://src/online/match_rules.gd")
const CODEC := preload("res://src/online/snapshot_codec.gd")
func check(ok: bool, message: String) -> void:
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var room = ROOM.new(); root.add_child(room); room.prepare(); room.start()
	room.battle.process_mode = Node.PROCESS_MODE_DISABLED
	var fx = room.battle.acquire_transient_fx("interp_test","sprite")
	fx.texture = room.battle.hero.hero_sprite.sprite_frames.get_frame_texture("idle",0)
	fx.position = Vector2.ZERO
	var first: Dictionary = room.snapshot()
	var id: int = room.ids[fx.get_instance_id()].wire
	check(id > 0 and room.battle.online_visual_projectiles.has(fx.get_instance_id()),"active effect registered")
	var command: Array = []
	for row in first.visuals:
		if int(row[0]) == id: command = row; break
	check(not command.is_empty(),"effect sprite emitted")
	var view = VIEW.new(); root.add_child(view)
	check(view.update_state(first),"first snapshot")
	fx.position = Vector2(100,0)
	var second: Dictionary = room.snapshot()
	check(view.update_state(second),"second snapshot")
	view.visual_motion.advance(RULES.SNAPSHOT_INTERVAL * 0.5)
	var found := false
	for i in view.render_visuals.size():
		var row: Array = view.render_visuals[i]
		if int(row[0]) == id:
			check(is_equal_approx(float(row[10])+view._visual_offset(i,view.visual_slots[i]).x,50.0),"render midpoint")
			found = true
	check(found,"rendered owner")
	room.battle.recycle_transient_fx(fx,"interp_test")
	var reused = room.battle.acquire_transient_fx("interp_test","sprite")
	check(reused == fx,"pool reused")
	reused.texture = fx.texture if fx.texture != null else room.battle.hero.hero_sprite.sprite_frames.get_frame_texture("idle",0)
	reused.position = Vector2(300,0)
	var third: Dictionary = room.snapshot()
	var new_id: int = room.ids[fx.get_instance_id()].wire
	check(new_id != id,"pool generation creates new id")
	check(view.update_state(third),"reuse snapshot")
	check(not view.visual_motion.current.has(id) and view.visual_motion.position(new_id,Vector2.ZERO).x == 300.0,"removed owner and new owner immediate")
	reused.position = Vector2(2000,0)
	check(view.update_state(room.snapshot()),"jump snapshot")
	check(view.visual_motion.position(new_id,Vector2.ZERO).x == 2000.0,"large jump snaps")
	var encoded: String = CODEC.new().encode(third)
	check(not encoded.is_empty() and encoded.to_utf8_buffer().size() <= RULES.MAX_SNAPSHOT,"snapshot fits")
	print("ONLINE_VISUAL_INTERP_PASS bytes=",encoded.to_utf8_buffer().size())
	view.queue_free(); room.queue_free(); await process_frame; quit()
