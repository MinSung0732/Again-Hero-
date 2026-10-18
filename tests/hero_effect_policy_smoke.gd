extends SceneTree
const BEFORE=preload("res://before.gd")
const AFTER=preload("res://after.gd")
const DATA=preload("res://src/data/hero_presentation_catalog.gd")
var checks=0
var failures=0
func check(ok,label):
	checks+=1
	if not ok:
		failures+=1
		push_error(label)
func _initialize():call_deferred("run")
func make(script,id,archetype):
	var node=script.new();root.add_child(node);node.hero_id=id;node.hero_archetype=archetype
	return node
func sprite_state(sprite):
	var animations=[]
	if sprite.sprite_frames!=null:
		for animation in sprite.sprite_frames.get_animation_names():
			var paths=[]
			for frame in range(sprite.sprite_frames.get_frame_count(animation)):
				paths.append(sprite.sprite_frames.get_frame_texture(animation,frame).get_meta("fixture_path","body"))
			animations.append([animation,sprite.sprite_frames.get_animation_speed(animation),sprite.sprite_frames.get_animation_loop(animation),paths])
	return [animations,sprite.visible,sprite.position,sprite.offset,sprite.scale,sprite.modulate,sprite.rotation,sprite.z_index,sprite.texture_filter,sprite.animation,sprite.frame,sprite.frame_progress,sprite.speed_scale,sprite.is_playing()]
func snapshot(node):return [node.paths.duplicate(),node.signals_seen.duplicate(true),node.anchors.duplicate(),sprite_state(node.hero_sprite),sprite_state(node.channel_effect)]
func normalize_case(node,body,reference,mode):
	node.hero_sprite.scale=Vector2(3,4)
	if reference>=0:node.reference_texture=node.image_texture(reference,64,64)
	if mode!=0:
		var frames=SpriteFrames.new()
		if mode>=2:frames.add_animation("idle")
		if mode==3:frames.add_frame("idle",node.image_texture(body))
		node.hero_sprite.sprite_frames=frames
	node._apply_normalized_hero_visual_scale()
func run():
	var saved_effects=DATA.CHANNEL_EFFECT_PROFILES.duplicate(true)
	var saved_release=DATA.RELEASE_EFFECT_COMPLETION.duplicate(true)
	for id in ["ranged_rookie","other","","swift_hunter"]:
		for body in [0,1,36,108]:
			for reference in [-1,0,1,10,36,64]:
				for mode in range(4):
					var a=make(BEFORE,id,"unknown");var b=make(AFTER,id,"unknown")
					normalize_case(a,body,reference,mode);normalize_case(b,body,reference,mode)
					check(snapshot(a)==snapshot(b),"normalization mismatch %s/%d/%d/%d"%[id,body,reference,mode])
					a.free();b.free()
	var archetypes=DATA.VISUAL_PROFILES.keys();archetypes.append("unknown");archetypes.append("")
	for archetype in archetypes:
		var configs=[{}, {"channel_fps":-2.0},{"channel_fps":0.0},{"channel_fps":0.5},{"channel_fps":1.0},{"channel_fps":8.0},{"channel_fps":12.5},{"channel_fps":"9"}] if archetype in ["berserker_madness","alchemist_chemical"] else [{}]
		var missing_cases=[-1,0,1,2,3,4,5,6,7,8,9,10,11,12] if archetype in ["berserker_madness","alchemist_chemical"] else [-1]
		for config in configs:
			for missing in missing_cases:
				for method in ["_apply_stage6_berserker_effect_visuals","_apply_alchemist_philosopher_effect_visuals"]:
					var a=make(BEFORE,"other",archetype);var b=make(AFTER,"other",archetype)
					for node in [a,b]:
						node.alchemist_philosopher_config=config;node.missing_all=missing==0
						if missing>0:node.missing_requests=[missing]
						node.call(method)
					check(snapshot(a)==snapshot(b),"effect setup mismatch %s/%s/%s/%d"%[archetype,method,config,missing])
					# Refresh the same effect with changed config, retaining cache/old state.
					for node in [a,b]:node.alchemist_philosopher_config={"channel_fps":7.25};node.call(method)
					check(snapshot(a)==snapshot(b),"effect refresh mismatch")
					a.free();b.free()
		for animation in ["default","cylinder_dust","other","madness"]:
			for position in [Vector2.ZERO,Vector2(13,17)]:
				for color in [Color.WHITE,Color.RED]:
					var a=make(BEFORE,"other",archetype);var b=make(AFTER,"other",archetype)
					for node in [a,b]:
						node.channel_effect.animation=animation;node.channel_effect.position=position;node.channel_effect.modulate=color
						node._on_fighter_guard_release_effect_finished()
					check(snapshot(a)==snapshot(b),"effect completion mismatch "+archetype)
					a.free();b.free()
	# Existing complete body visual owner now uses actual normalization and actual channel setup.
	for archetype in archetypes:
		for id in ["ranged_rookie","other",""]:
			for reference in [-1,10]:
				for directory in ["","res://override"]:
					var a=make(BEFORE,id,archetype);var b=make(AFTER,id,archetype)
					for node in [a,b]:
						node.sprite_frame_dir=directory
						if reference>=0:node.reference_texture=node.image_texture(reference,64,64)
						node._apply_profile_visual();node._apply_stage6_berserker_effect_visuals()
					check(snapshot(a)==snapshot(b),"visual owner integration mismatch "+archetype)
					a.free();b.free()
	var sanity=make(AFTER,"ranged_rookie","unknown");normalize_case(sanity,36,10,3)
	check(sanity.hero_sprite.scale==Vector2(3,3),"rookie uses108 opaque height")
	check(sanity.paths.size()==1,"rookie still reads reference once")
	sanity.hero_id="other";sanity._apply_normalized_hero_visual_scale()
	check(sanity.hero_sprite.scale.is_equal_approx(Vector2(30.0/36.0,30.0/36.0)),"other uses live reference height")
	sanity.hero_archetype="alchemist_chemical";sanity._apply_alchemist_philosopher_effect_visuals()
	check(sanity.channel_effect.sprite_frames.get_frame_count("philosopher_stone")==12,"brew8 then cast4")
	check(sanity.channel_effect.offset==Vector2(64,-144) and sanity.channel_effect.scale==Vector2(0.5,0.5),"manifest anchor properties")
	sanity.alchemist_philosopher_config={"channel_fps":0.0};sanity._apply_alchemist_philosopher_effect_visuals()
	check(sanity.channel_effect.sprite_frames.get_animation_speed("philosopher_stone")==1.0,"fps minimum")
	sanity.free()
	var custom=DATA.get_channel_effect_profile("berserker_madness",&"persistent").duplicate(true)
	custom.animation=&"fixture_animation";custom.fps=3.25;custom.loop=false
	custom.frame_groups=[{"path_pattern":"res://fixture/frame_%02d.png","first":2,"last":3,"required":true}]
	custom.properties={"animation":&"fixture_animation","position":Vector2(11,-21),"scale":Vector2(1.25,1.25)}
	var custom_node=make(AFTER,"other","unknown")
	custom_node._configure_channel_effect_profile(custom)
	check(custom_node.channel_effect.sprite_frames.get_frame_count("fixture_animation")==2 and custom_node.channel_effect.sprite_frames.get_animation_speed("fixture_animation")==3.25,"custom channel binding")
	check(custom_node.channel_effect.position==Vector2(11,-21) and custom_node.channel_effect.scale==Vector2(1.25,1.25),"custom channel properties")
	check(custom_node.paths==["res://fixture/frame_02.png","res://fixture/frame_03.png"],"custom texture binding")
	custom_node.free()
	check(DATA.CHANNEL_EFFECT_PROFILES==saved_effects and DATA.RELEASE_EFFECT_COMPLETION==saved_release,"shared policy unchanged")
	print("HERO_EFFECT_POLICY checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
