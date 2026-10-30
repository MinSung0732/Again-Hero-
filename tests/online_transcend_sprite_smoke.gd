extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const TRANSCENDENCE := preload("res://src/data/transcendence_catalog.gd")
const PNG := preload("res://src/ui/png_texture_source.gd")
var checks := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value: push_error(message); quit(1); assert(value, message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
 for id in TRANSCENDENCE.get_ids():
  var room = ROOM.new(); root.add_child(room)
  room.set_loadouts({"hero_id":"hero"},{"team_ids":["slime","spider","orc"],"skill_ids":[],"transcendence_id":id})
  room.prepare(); room.start(); room.battle.transcendence.ready = true
  check(room.apply("demon","transcend",{"point":[2100,2100]}), "summon " + id)
  var state: Dictionary = room.snapshot(); var found := false
  for actor in state.actors:
   if actor[1] != id: continue
   for command in state.visuals:
    if command[0] == actor[0] and String(command[1]).begins_with("res://assets/art/"): found = true
  check(found, "snapshot visual " + id)
  room.queue_free(); await process_frame
 var image := Image.create(1,1,false,Image.FORMAT_RGBA8)
 image.fill(Color.WHITE)
 check(image.save_png("user://online_transcend_test.png") == OK,"write fallback PNG")
 var visual = preload("res://src/monsters/monster_visual.gd").new()
 var texture: Texture2D = visual._load_texture("user://online_transcend_test.png")
 check(texture != null and PNG.path(texture) == "user://online_transcend_test.png","decoded PNG retains source path")
 visual.free()
 print("ONLINE_TRANSCEND_SPRITE_PASS checks=",checks); quit()
