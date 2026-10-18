extends SceneTree
const BEFORE=preload("res://before.gd")
const AFTER=preload("res://after.gd")
const UI_BEFORE=preload("res://ui_before.gd")
const UI_AFTER=preload("res://ui_after.gd")
const DATA=preload("res://src/data/hero_presentation_catalog.gd")
var checks=0
var failures=0
var missing=false
func check(ok,label):
	checks+=1
	if not ok:
		failures+=1
		push_error(label)
func _initialize():call_deferred("run")
func make(script,id,archetype,directory,fail_request):
	var node=script.new();root.add_child(node)
	node.hero_id=id;node.hero_archetype=archetype;node.sprite_frame_dir=directory;node.missing_request=fail_request
	return node
func snapshot(owner):
	var sprite=owner.hero_sprite
	var animations=[]
	if sprite.sprite_frames!=null:
		for animation in sprite.sprite_frames.get_animation_names():
			var paths=[]
			for frame in range(sprite.sprite_frames.get_frame_count(animation)):
				paths.append(sprite.sprite_frames.get_frame_texture(animation,frame).get_meta("fixture_path",""))
			animations.append([animation,sprite.sprite_frames.get_animation_speed(animation),sprite.sprite_frames.get_animation_loop(animation),paths])
	return [owner.paths.duplicate(),owner.events.duplicate(true),animations,sprite.visible,sprite.modulate,sprite.rotation,sprite.offset,sprite.z_index,sprite.show_behind_parent,sprite.texture_filter,sprite.scale,sprite.speed_scale,sprite.animation,sprite.is_playing()]
func compare_visual(id,archetype,directory,fail_request):
	var a=make(BEFORE,id,archetype,directory,fail_request)
	var b=make(AFTER,id,archetype,directory,fail_request)
	a._apply_profile_visual();b._apply_profile_visual()
	check(snapshot(a)==snapshot(b),"visual mismatch %s/%s/%s/%d"%[id,archetype,directory,fail_request])
	var request_count=a.paths.size()
	# Repeat initialization on the same node to catch stale fields/anchor reset.
	a._apply_profile_visual();b._apply_profile_visual()
	check(snapshot(a)==snapshot(b),"repeat visual mismatch")
	a.free();b.free()
	return request_count
func ui_snapshot(node):
	var texts=[]
	for label in [node.hero_info_name,node.hero_info_stats,node.hero_info_abilities,node.hero_info_build,node.hero_info_ai]:texts.append(label.text)
	return [texts,node.events.duplicate(),node.battle.reads.duplicate()]
func run():
	missing="--missing-art" in OS.get_cmdline_user_args()
	var original=DATA.VISUAL_PROFILES.duplicate(true)
	var archetypes=DATA.VISUAL_PROFILES.keys();archetypes.append("unknown");archetypes.append("")
	if not missing:
		for id in ["ranged_rookie","other",""]:
			for archetype in archetypes:
				for directory in ["","res://fixture_override"]:compare_visual(id,archetype,directory,-1)
	else:
		for archetype in archetypes:
			var id="ranged_rookie" if archetype=="ranged_rookie" else "other"
			var pair=make(BEFORE,id,archetype,"",-1);pair._apply_profile_visual();var count=pair.paths.size();pair.free()
			for fail_request in range(1,count+1):compare_visual(id,archetype,"",fail_request)
	# Whole production UI owner, including default fields and unchanged build/AI text.
	for archetype in archetypes:
		for value in [-1.25,0.0,0.005,0.455,2.0]:
			for fallback in [false,true]:
				var a=UI_BEFORE.new();root.add_child(a)
				var b=UI_AFTER.new();root.add_child(b)
				var source={"hero_archetype":archetype,"hero_slash_shield_ratio":value,"hero_lifesteal_ratio":value*2,"hero_execute_ratio":value/2,"hero_projectile_speed":value*1000,"hero_build_counts":{"one":1,"max":3,"zero":0}}
				a.battle.snapshot=source;b.battle.snapshot=source;a.battle.fallback=fallback;b.battle.fallback=fallback
				a._refresh_hero_info_panel();b._refresh_hero_info_panel()
				check(ui_snapshot(a)==ui_snapshot(b),"UI mismatch "+archetype)
				# Missing fields and live snapshot updates must use current values.
				a.battle.snapshot={"hero_archetype":archetype};b.battle.snapshot={"hero_archetype":archetype}
				a._refresh_hero_info_panel();b._refresh_hero_info_panel()
				check(ui_snapshot(a)==ui_snapshot(b),"UI defaults mismatch")
				a.free();b.free()
	var sage=make(AFTER,"ranged_rookie","grand_sage_astra","",-1);sage._apply_profile_visual()
	check(sage.paths[0].begins_with(DATA.STAGE10_FRAME_DIR),"early archetype precedes hero ID")
	sage.free()
	var rookie=make(AFTER,"ranged_rookie","rogue_combo","",-1);rookie._apply_profile_visual()
	check(rookie.paths[0].begins_with(DATA.STAGE1_FRAME_DIR),"hero ID precedes late archetype")
	rookie.free()
	var previous=make(BEFORE,"other","cleric_purifier","",-1)
	var current=make(AFTER,"other","cleric_purifier","",-1)
	for state in [["other","cleric_purifier"],["other","alchemist_chemical"],["other","unknown"],["ranged_rookie","rogue_combo"],["other","berserker_madness"]]:
		previous.hero_id=state[0];current.hero_id=state[0]
		previous.hero_archetype=state[1];current.hero_archetype=state[1]
		previous._apply_profile_visual();current._apply_profile_visual()
		check(snapshot(previous)==snapshot(current),"identity reuse resets presentation")
	var attack=current.hero_sprite.sprite_frames
	var attack_indices=[]
	for frame in range(attack.get_frame_count("attack")):
		attack_indices.append(attack.get_frame_texture("attack",frame).get_meta("fixture_path").get_file())
	check(attack_indices==["atk_01.png","atk_05.png","atk_02.png","atk_06.png"],"berserker attack order sanity")
	check(attack.get_animation_speed("attack")==10.0 and not attack.get_animation_loop("attack"),"berserker attack playback sanity")
	previous.free();current.free()
	check(DATA.format_ability_lines("rogue_combo",{}).size()==4,"rogue four lines")
	check(DATA.format_ability_lines("future",{})==PackedStringArray(["원거리 투사체 속도  0","거리 유지형 전투 AI"]),"future UI fallback")
	check(DATA.VISUAL_PROFILES==original,"shared visual data unchanged")
	print("HERO_PRESENTATION checks=%d failures=%d missing=%s"%[checks,failures,missing])
	quit(1 if failures else 0)
