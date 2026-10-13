extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STAMINA := preload("res://src/systems/stamina_store.gd")
const PAD := preload("res://src/hero_mode/hero_move_pad.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HERO_PAD: "+message)
func send(event: InputEvent) -> void:
	# Inject physical window coordinates; Godot maps them back to viewport space.
	Input.parse_input_event(event.xformed_by(root.get_final_transform())); Input.flush_buffered_events()
func touch(point: Vector2, pressed: bool, index: int = 0, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point; event.pressed = pressed; event.index = index; event.canceled = canceled
	send(event)
func drag(point: Vector2, index: int = 0) -> void:
	var event := InputEventScreenDrag.new(); event.position = point; event.index = index
	send(event)
func mouse(point: Vector2, pressed: bool) -> void:
	if pressed:
		var hover := InputEventMouseMotion.new(); hover.position = point
		send(hover)
	var event := InputEventMouseButton.new()
	event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
	send(event)
func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new(); event.position = point; event.button_mask = MOUSE_BUTTON_MASK_LEFT
	send(event)
func viewport_point(control: Control, local: Vector2) -> Vector2:
	return control.get_global_transform_with_canvas()*local
func run() -> void:
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.select_guest(); SCOPE.guest_directory = "user://hero_pad_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	var paid := STAMINA.try_enter("stage_1",true,-1,false)
	check(paid.success,"isolated entry")
	root.get_node("SceneTransition").set("_entry_options",{"stage_id":"stage_1","hero_id":"ranged_rookie","hero_entry":paid})
	var scene = load("res://src/hero_mode/HeroMode.tscn").instantiate()
	scene.gameplay_settings_path = SCOPE.guest_directory+"/gameplay.cfg"
	root.add_child(scene)
	if not scene.entry_ready: await scene.entry_started
	await process_frame
	var pad = scene.pad
	var view := scene.get_node("BattleView") as Control
	check(pad.mode == PAD.MODE_FIXED and pad.visible,"missing config defaults to visible fixed pad")
	check(is_equal_approx(pad.get_global_rect().get_center().x,scene.get_global_rect().get_center().x),"fixed pad centered horizontally")
	check(is_equal_approx(scene.size.y-pad.position.y-pad.size.y,45.0),"fixed pad remains in original bottom band")
	for color in [PAD.BASE_COLOR,PAD.RIM_COLOR,PAD.KNOB_COLOR]:
		check(color.r == color.g and color.g == color.b and color.a > 0 and color.a < 1,"all pad shapes gray and translucent")
	var center := viewport_point(pad,pad.size*0.5)
	touch(center,true,7); drag(viewport_point(pad,pad.size*0.5+Vector2(105,0)),7)
	check(pad.touch_id == 7 and pad.direction.x > 0.99 and scene.battle.hero.player_move_input.x > 0.99,"fixed actual GUI touch and drag drive hero")
	touch(Vector2(-100,-100),false,7)
	check(pad.touch_id == -1 and pad.direction == Vector2.ZERO and scene.battle.hero.player_move_input == Vector2.ZERO,"fixed release outside widget stops hero")
	mouse(center,true); motion(viewport_point(pad,pad.size*0.5+Vector2(0,-200)))
	check(pad.mouse_owned and pad.direction.is_equal_approx(Vector2.UP),"fixed mouse capture and clamped drag")
	mouse(Vector2(-100,-100),false)
	check(not pad.mouse_owned and pad.direction == Vector2.ZERO,"fixed mouse release outside stops")
	scene._pause(); scene._open_settings()
	var selector := scene.pad_mode_selector as OptionButton
	check(selector.get_item_count() == 2 and selector.get_item_text(0) == "고정형 패드" and selector.get_item_text(1) == "자유형 패드","actual gameplay setting offers both modes")
	var panel := scene.settings_panel.get_node("Panel") as Control
	await process_frame
	check(scene.get_global_rect().encloses(panel.get_global_rect()),"settings panel fits viewport after adding pad controls")
	selector.item_selected.emit(1)
	check(pad.mode == PAD.MODE_FREE and not pad.visible and not pad.enabled,"setting applies while combat paused")
	var saved := ConfigFile.new(); saved.load(scene.gameplay_settings_path)
	check(saved.get_value("gameplay","hero_pad_mode","") == PAD.MODE_FREE,"free preference saved")
	scene._resume()
	var origin := viewport_point(view,view.size*Vector2(0.4,0.4))
	# HUD and decorative margins cannot create a free pad.
	touch(Vector2(10,10),true,3); check(pad.touch_id == -1 and not pad.visible,"HUD touch ignored")
	touch(Vector2(10,10),false,3)
	var margin := viewport_point(scene,Vector2(20,500))
	touch(margin,true,3); check(pad.touch_id == -1 and not pad.visible,"frame margin touch ignored")
	touch(margin,false,3)
	touch(origin,true,7)
	check(pad.visible and pad.touch_id == 7 and pad.direction == Vector2.ZERO,"hidden free pad captures initial finger with zero movement")
	check(viewport_point(pad,pad.size*0.5).is_equal_approx(origin),"free pad origin exactly equals battle touch")
	touch(origin+Vector2(200,0),true,8); drag(origin+Vector2(-200,0),8)
	check(pad.touch_id == 7 and pad.direction == Vector2.ZERO,"second finger cannot steal or steer")
	touch(origin,false,8); check(pad.touch_id == 7 and pad.visible,"second finger release cannot reset owner")
	drag(origin+Vector2(6,0),7); check(pad.direction == Vector2.ZERO,"center deadzone")
	drag(origin+Vector2(105,0),7)
	check(pad.direction.x > 0.99 and scene.battle.hero.player_move_input.x > 0.99,"free actual touch drag drives hero")
	check(viewport_point(pad,pad.size*0.5).is_equal_approx(origin),"drag does not shift initial base")
	drag(origin+Vector2(400,400),7); check(is_equal_approx(pad.direction.length(),1.0),"diagonal movement capped")
	touch(Vector2(-100,-100),false,7)
	check(not pad.visible and pad.touch_id == -1 and scene.battle.hero.player_move_input == Vector2.ZERO,"free release outside panel hides and stops")
	var next_origin := origin+Vector2(100,100)
	touch(next_origin,true,9)
	check(viewport_point(pad,pad.size*0.5).is_equal_approx(next_origin),"next gesture gets a new origin")
	touch(next_origin,false,9,true)
	check(not pad.visible and pad.direction == Vector2.ZERO,"canceled gesture clears movement")
	mouse(next_origin,true); motion(next_origin+Vector2(0,-105))
	check(pad.mouse_owned and pad.visible and pad.direction.y < -0.99,"free mouse emulates desktop pad")
	mouse(Vector2(-100,-100),false)
	check(not pad.visible and not pad.mouse_owned,"free mouse release hides")
	touch(origin,true,9); drag(origin+Vector2(105,0),9)
	scene._pause()
	check(not pad.visible and pad.touch_id == -1 and scene.battle.hero.player_move_input == Vector2.ZERO,"pause disables and resets active free gesture")
	touch(origin,true,10); check(not pad.visible and pad.touch_id == -1,"paused modal cannot create pad")
	touch(origin,false,9); touch(origin,false,10)
	scene._resume(); touch(origin,true,10); drag(origin+Vector2(105,0),10)
	pad._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not pad.visible and scene.battle.hero.player_move_input == Vector2.ZERO,"focus loss resets")
	touch(origin,false,10)
	# Save failure restores the selector and leaves the current control mode.
	scene._pause(); scene._open_settings()
	var good_path: String = scene.gameplay_settings_path
	scene.gameplay_settings_path = good_path+"/cannot-save.cfg"
	selector.item_selected.emit(0)
	check(pad.mode == PAD.MODE_FREE and selector.selected == 1,"failed save cannot change current mode or displayed selection")
	scene.gameplay_settings_path = good_path
	scene._set_battle_frame(false)
	saved.load(good_path)
	check(saved.get_value("gameplay","hero_pad_mode","") == PAD.MODE_FREE and not saved.get_value("gameplay","battle_frame_enabled",true),"frame save preserves pad setting")
	scene._resume(); await process_frame
	var expanded := viewport_point(scene,Vector2(20,500))
	touch(expanded,true,11)
	check(pad.visible and pad.touch_id == 11,"free input follows actual expanded battle panel after frame toggle")
	touch(expanded,false,11)
	scene._pause(); scene._set_pad_mode(0)
	check(pad.visible and pad.mode == PAD.MODE_FIXED,"switch back restores fixed pad")
	saved.load(good_path)
	check(not saved.get_value("gameplay","battle_frame_enabled",true),"pad save preserves other gameplay setting")
	# A fresh valid entry restores the saved free mode without touching campaign camera.
	scene._set_pad_mode(1); scene.queue_free(); await process_frame
	paid = STAMINA.try_enter("stage_1",true,-1,false)
	root.get_node("SceneTransition").set("_entry_options",{"stage_id":"stage_1","hero_id":"ranged_rookie","hero_entry":paid})
	var reentry = load("res://src/hero_mode/HeroMode.tscn").instantiate(); reentry.gameplay_settings_path = good_path; root.add_child(reentry)
	if not reentry.entry_ready: await reentry.entry_started
	check(reentry.pad.mode == PAD.MODE_FREE and not reentry.pad.visible and reentry.pad_mode_selector.selected == 1,"next entry restores free preference and idle hidden pad")
	reentry.queue_free(); await process_frame
	print("HERO_MOVE_PAD_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
