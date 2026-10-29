extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const ART := preload("res://src/data/online_presentation_catalog.gd")
const BUTTON_ART := preload("res://src/ui/augment_hold_art.gd")
const POPUPS := preload("res://src/ui/damage_number_spawner.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func z(item: CanvasItem) -> int:
	var result := item.z_index
	while item.z_as_relative and item.get_parent() is CanvasItem:
		item = item.get_parent(); result += item.z_index
	return result
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var room := ROOM.new(); root.add_child(room); room.prepare(); room.start()
	room.battle.process_mode = Node.PROCESS_MODE_DISABLED
	room.battle._spawn_monster("slime",room.battle.hero.position+Vector2(120,0))
	var snapshot: Dictionary = room.snapshot()
	for size in [Vector2i(1080,1920),Vector2i(720,1280)]:
		root.size = size
		for role in ["hero","demon"]:
			root.get_node("SceneTransition")._entry_options = {"role":role}
			var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene)
			scene._show_match_layout(); await process_frame; await process_frame
			check(scene.view.update_state(snapshot),"real combat bar state accepted")
			var popup := POPUPS.show_feedback(scene.view.feedback,42,room.battle.hero.position,7,Color.WHITE,false)
			scene.hold_popup.set_holds([{"number":1,"candidates":[{"id":"survival_power","name":"test","description":"test"}]}])
			scene.hold_popup.set_controls(true); scene.hold_popup.open_index(0)
			check(scene.hold_popup.popup.visible,"stored augment panel opens")
			check(z(scene.hold_popup.popup)>z(scene.view.status_bars) and z(scene.hold_popup.popup)>z(popup),"augment panel is above world HP bars and damage labels")
			var dot = scene.hold_popup.dots[0]
			check(dot.text=="1" and dot.custom_minimum_size==BUTTON_ART.BADGE_SIZE,"collapsed slot has readable number and mobile target")
			check(dot.get_theme_stylebox("normal") is StyleBoxTexture and scene.hold_popup.lower_button.get_theme_stylebox("normal") is StyleBoxTexture,"badge and lower button use prepared art")
			scene.hold_popup.lower_button.pressed.emit()
			check(not scene.hold_popup.popup.visible and dot.visible,"lower keeps stored augment available")
			dot.pressed.emit(); check(scene.hold_popup.popup.visible,"authored badge reopens its original offer")
			if role=="hero":
				var top = scene.get_node("BattleTopBacking/TopHUDBackdrop")
				check(top.texture != null and top.texture.resource_path==ART.HERO_TOP_BACKDROP_PATH,"hero uses authored role-specific backing")
				check(is_equal_approx(top.size.y,preload("res://src/ui/hero_survival_hud.gd").BATTLE_TOP) and is_equal_approx(top.size.x,scene.size.x),"art covers the full hero top HUD")
				for enabled in [false,true]:
					scene.battle_frame_enabled=enabled; scene._apply_match_frame()
					check(top.is_visible_in_tree(),"hero backing survives both frame settings")
			scene.free()
	# Solo shares the overlay ordering, while retaining its existing backing.
	var solo = load("res://src/hero_mode/hero_mode.gd").new()
	solo._build_ui()
	check(solo.overlay.z_index==preload("res://src/ui/augment_hold_popup.gd").OVERLAY_Z,"solo augment/chest overlay uses the same safe ordering")
	solo.free()
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in room.find_children("*",kind,true,false): player.stop(); player.stream=null
	room.free()
	print("ONLINE_OVERLAY_ART checks=",checks," failures=",failures)
	quit(1 if failures else 0)
