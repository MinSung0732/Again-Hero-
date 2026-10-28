extends SceneTree
const VIEW := preload("res://src/online/battle_view.gd")
const BUFFER := preload("res://src/online/feedback_buffer.gd")
const POPUPS := preload("res://src/ui/damage_number_spawner.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("CloudStore").stop()
	for hero_role in [true,false]:
		for size in [Vector2(1080,1450),Vector2(720,780)]:
			var view := VIEW.new(); view.hero_role = hero_role; root.add_child(view)
			view.size = size; view.position = Vector2(24,52)
			view.bounds = Vector2(3600,3600)
			view.state = {"hero":[1800.0,1800.0],"hero_archetype":"ranged_kiter"}
			var feedback = view.feedback
			feedback.reset(); feedback.suspended = false
			check(feedback.get_meta(POPUPS.POOL_META,[]).size() == POPUPS.MAX_ACTIVE_POPUPS,"popup pool fully allocated before first attack")
			var buffer := BUFFER.new()
			var point := Vector2(1800,1800)
			view._layout_map()
			buffer.publish("monster_hit",point,37,Color.WHITE,1,42)
			check(feedback.consume(buffer.snapshot(),buffer.sequence,1),"damage event accepted")
			var pool: Array = feedback.get_meta(POPUPS.POOL_META,[])
			check(pool.size() == POPUPS.MAX_ACTIVE_POPUPS,"one visible popup acquired")
			var popup = pool[0]
			var expected := view.global_position+view.map_offset+(point+POPUPS.WORLD_OFFSET)*view.map_scale
			check(popup.global_position.is_equal_approx(expected),"first draw already uses current camera transform")
			check(popup.visible and popup.value_label != null and popup.value_label.is_visible_in_tree() and popup.value_label.text == "37","actual damage Label visible")
			check(view.get_global_rect().intersects(popup.value_label.get_global_rect()),"damage text lies inside clipped battlefield")
			# A different camera center must be applied before a new packet's first draw.
			view.state.hero[0] = 2400.0; point.x = 2400.0
			view._layout_map()
			buffer.publish("heal",point,9,Color.GREEN,2,43)
			feedback.consume(buffer.snapshot(),buffer.sequence,2)
			pool = feedback.get_meta(POPUPS.POOL_META,[]); popup = pool[1]
			expected = view.global_position+view.map_offset+(point+POPUPS.WORLD_OFFSET+Vector2(0,-10))*view.map_scale
			check(popup.global_position.is_equal_approx(expected) and popup.value_label.text == "+9","camera move keeps new recovery text on target immediately")
			var accepted: int = feedback.accepted
			feedback.consume(buffer.snapshot(),buffer.sequence,2)
			check(feedback.accepted == accepted and pool.size() == POPUPS.MAX_ACTIVE_POPUPS,"packet repeat never duplicates text")
			for index in POPUPS.MAX_ACTIVE_POPUPS:
				POPUPS.show_feedback(feedback,1000+index,point,1,Color.WHITE,false)
			var latest := POPUPS.show_feedback(feedback,9999,point,71,Color.WHITE,false)
			check(latest != null and latest.value_label.text == "71" and latest.visible,"pool saturation preserves newest damage without allocating")
			check(pool.size() == POPUPS.MAX_ACTIVE_POPUPS,"combat burst never grows prepared pool")
			feedback.pause_feedback()
			check(not pool[0].visible and not pool[1].visible,"connection pause clears visible text")
			buffer.publish("monster_hit",point,4,Color.WHITE,3,44)
			feedback.consume(buffer.snapshot(),buffer.sequence,3); feedback.suspended = false
			feedback.consume(buffer.snapshot(),buffer.sequence,3)
			check(feedback.accepted == accepted,"resume does not replay paused text")
			view.free()
	print("ONLINE_DAMAGE_POPUP_VIEW checks=",checks," failures=",failures)
	quit(1 if failures else 0)
