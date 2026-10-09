extends SceneTree
const ART := preload("res://src/data/skill_icon_catalog.gd")
const ICON := preload("res://src/ui/codex_skill_icon.gd")
const BADGE := preload("res://src/ui/hero_skill_cooldown_badge.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error("SKILL_ICONS: " + message)
func run() -> void:
 root.get_node("CloudStore").stop()
 root.get_node("LoginGateway").remember_session_enabled = false
 SCOPE.select_guest()
 SCOPE.guest_directory = "user://skill-icons-%d" % Time.get_ticks_usec()
 DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
 var slot := ICON.new()
 root.add_child(slot)
 var badge := BADGE.new()
 root.add_child(badge)
 var hero_ids := {}
 for key in ART.PATHS:
  var fields: PackedStringArray = String(key).split(":")
  slot.configure(fields[0],fields[1],fields[2])
  check(slot.image.texture != null and not slot.placeholder.visible,"provided art replaces placeholder " + key)
  var texture: Texture2D = slot.image.texture
  slot.configure(fields[0],fields[1],fields[2])
  check(slot.image.texture == texture,"cached texture reused " + key)
  if fields[0] == "hero":
   check(not hero_ids.has(fields[2]),"HUD IDs unambiguous")
   hero_ids[fields[2]] = true
   badge.configure({"id":fields[2],"icon_path":"res://missing-old-effect.png"})
   check(badge.icon_path == ART.PATHS[key] and badge.icon_texture != null,"battle badge selects authored icon " + key)
 slot.configure("transcendent","manticore","재앙의 불꽃")
 check(slot.image.texture == null and slot.placeholder.visible,"unprovided icon stays empty")
 badge.configure({"id":"fixture_unprovided","icon_path":ART.PATHS.values()[0]})
 check(badge.icon_texture != null,"legacy fallback preserved")
 slot.queue_free()
 badge.queue_free()
 await process_frame
 await root.get_node("PresentationWarmup").prepare_scene("res://src/main/Main.tscn")
 var main = load("res://src/main/Main.tscn").instantiate()
 main.gameplay_settings_path = SCOPE.guest_directory.path_join("options.cfg")
 root.add_child(main)
 current_scene = main
 var deadline := Time.get_ticks_msec()+20000
 while not main._presentation_ready and Time.get_ticks_msec() < deadline: await process_frame
 check(main._presentation_ready,"actual Main initialized")
 main.battle.set_external_pause(true)
 for i in range(main.demon_ultimate_ui_skills.size()):
  var id: String = main.demon_ultimate_ui_skills[i].id
  check(main.demon_ultimate_ui_buttons[i].icon == ART.texture("demon","demon",id),"actual battle demon button " + id)
 main.queue_free()
 await process_frame
 await process_frame
 await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
 var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
 lobby.gameplay_settings_path = SCOPE.guest_directory.path_join("options.cfg")
 root.add_child(lobby)
 current_scene = lobby
 for id in ["encirclement","line_assault","square_siege"]:
  var card: Control = lobby._create_demon_skill_card(id)
  check(card.find_children("*","TextureRect",true,false).any(func(image):return image.texture == ART.texture("demon","demon",id)),"actual formation card " + id)
  card.free()
 lobby.queue_free()
 await process_frame
 await process_frame
 print("SKILL_ICONS: " + ("PASS" if failures == 0 else "FAIL"))
 quit(0 if failures == 0 else 1)
