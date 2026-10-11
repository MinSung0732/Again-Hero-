extends SceneTree
const G = preload("res://src/monsters/Gargoyle.tscn")
const D = preload("res://src/data/gargoyle_behavior_catalog.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func verify(actor, profile: Dictionary) -> void:
 var v = actor.get_node("Visual")
 check(v.is_visual_ready(), "visual ready")
 check(v.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "nearest filter")
 for name in D.ANIMATIONS:
  var a: Dictionary = D.ANIMATIONS[name]
  check(v.sprite_frames.get_frame_count(name) == a.count, "frame count " + name)
  check(v.sprite_frames.get_animation_loop(name) == a.loop, "loop " + name)
  for i in a.count:
   var t = v.sprite_frames.get_frame_texture(name,i)
   check(t != null and t.get_width() > 0, "real PNG loaded")
 check(is_equal_approx(v.scale.y*v.sprite_frames.get_frame_texture("idle",0).get_height(),profile.target_height),"profile scale")
 check(is_equal_approx(actor.status_bar_head_y,-profile.target_height*0.5-12.0),"bar anchor follows sprite")
 v.play_attack()
 check(v.animation == &"attack", "attack animation")
 v._on_animation_finished()
 v.play_hit()
 check(v.animation == &"hit", "hit animation")
 v._on_animation_finished()
func run() -> void:
 var actor = G.instantiate()
 root.add_child(actor)
 actor.set_physics_process(false)
 verify(actor,D.NORMAL_VISUAL)
 var normal_texture = actor.visual.sprite_frames.get_frame_texture("idle",0)
 actor.apply_visual_profile(D.ELITE_VISUAL)
 verify(actor,D.ELITE_VISUAL)
 check(normal_texture != actor.visual.sprite_frames.get_frame_texture("idle",0),"elite has distinct art")
 actor.configure_special_augments({"gargoyle_stone_slumber":{}})
 actor.take_damage(170)
 check(actor.petrify_remaining > 0.0 and actor.visual.speed_scale == 0.0,"petrification freezes sprite")
 actor._physics_process(3.0)
 check(actor.visual.speed_scale == 1.0,"petrification restores animation")
 actor.petrify_remaining = 1.0
 actor.visual.speed_scale = 0.0
 actor.take_damage(9999)
 check(actor.visual.speed_scale == 1.0 and actor.visual.animation == &"death","petrified death plays")
 await create_timer(0.6).timeout
 check(not is_instance_valid(actor),"death animation completes removal")
 print("GARGOYLE_VISUAL_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures > 0 else 0)
