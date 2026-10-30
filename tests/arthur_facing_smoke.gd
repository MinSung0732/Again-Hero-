extends SceneTree
# Isolated source-method regression. Does not preload the game's assets/autoloads.
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func method(source: String, name: String) -> String:
	var start := source.find("func "+name+"(")
	assert(start>=0,"Missing source method: "+name)
	var end := source.find("\nfunc ",start+1)
	return source.substr(start) if end<0 else source.substr(start,end-start)+"\n"
func run() -> void:
	var actor_path := "res://src/monsters/arthur.gd"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--actor-source="): actor_path = arg.trim_prefix("--actor-source=")
	var arthur := FileAccess.get_file_as_string(actor_path)
	var orc := FileAccess.get_file_as_string("res://src/monsters/orc.gd")
	var visual_source := FileAccess.get_file_as_string("res://src/monsters/monster_visual.gd")
	var visual_script := GDScript.new()
	visual_script.source_code = "extends Node2D\nvar flip_h := false\nvar art_faces_left := false\nvar _one_shot_locked := false\nvar moving := false\nfunc play_locomotion(value: bool) -> void: moving = value\n"+method(visual_source,"set_facing_direction")
	check(visual_script.reload()==OK,"actual visual facing method compiles")
	var actor_script := GDScript.new()
	actor_script.source_code = "extends Node2D\nvar visual: Node2D\nvar hero: Node2D\nvar visual_moving_state := -1\nvar visual_facing_sign := 0\nfunc _visual_call(name: StringName, args: Array = []) -> void: visual.callv(name,args)\n"+method(orc,"_update_visual_motion")+method(arthur,"_restore_combat_pose")
	check(actor_script.reload()==OK,"actual actor restore and cached motion methods compile")
	if failures>0:
		quit(1)
		return
	var actor: Node2D = actor_script.new()
	root.add_child(actor)
	actor.visual = visual_script.new()
	actor.add_child(actor.visual)
	actor.hero = Node2D.new()
	root.add_child(actor.hero)
	for side in [-1,1]:
		for moving in [false,true]:
			for repeat in range(3):
				actor.position = Vector2(300,400)
				actor.hero.position = actor.position+Vector2(side*100,0)
				actor.visual_facing_sign = side
				actor.visual_moving_state = 1 if moving else 0
				actor.visual.flip_h = side>0
				actor.visual._one_shot_locked = true
				actor._restore_combat_pose()
				check(actor.visual.flip_h==(side<0),"return faces current target")
				check(actor.visual_facing_sign==side,"return synchronizes facing cache")
				check(not actor.visual._one_shot_locked and not actor.visual.moving,"return unlocks/idle")
				actor._update_visual_motion(side,moving)
				check(actor.visual.flip_h==(side<0),"same cached side stays correct")
				actor._update_visual_motion(-side,true)
				check(actor.visual.flip_h==(side>0),"later motion reverses facing")
	actor.hero.position = actor.position+Vector2(0,100)
	actor.visual.flip_h = true
	actor._restore_combat_pose()
	check(actor.visual.flip_h,"vertical target retains previous facing")
	actor.hero.free()
	actor._restore_combat_pose()
	check(actor.visual.flip_h and not actor.visual.moving,"deleted target safe")
	actor.free()
	await process_frame
	print("ARTHUR_FACING: %s (%d checks)" % ["PASS" if failures==0 else "FAIL",checks])
	quit(0 if failures==0 else 1)
