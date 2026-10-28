extends RefCounted
## Fixed display slots only. Collection is explicitly sent by the authority.
const DATA := preload("res://src/data/online_exp_orb_catalog.gd")
const ART := preload("res://src/data/online_presentation_catalog.gd")
var slots := {}
var ids := PackedInt64Array()
var seen := PackedInt64Array()
var kinds := PackedByteArray()
var tiers := PackedByteArray()
var positions := PackedVector2Array()
var starts := PackedVector2Array()
var targets := PackedVector2Array()
var elapsed := PackedFloat32Array()
var free_slots := PackedInt32Array()
var free_count := 0
var revision := 0
var clock := 0.0
var frame_paths: Array = []
var requested_tiers := {}
func _init() -> void:
	ids.resize(DATA.MAX_ROWS); seen.resize(DATA.MAX_ROWS); kinds.resize(DATA.MAX_ROWS)
	tiers.resize(DATA.MAX_ROWS); positions.resize(DATA.MAX_ROWS); starts.resize(DATA.MAX_ROWS)
	targets.resize(DATA.MAX_ROWS); elapsed.resize(DATA.MAX_ROWS); free_slots.resize(DATA.MAX_ROWS)
	for tier in DATA.SOURCE.TIER_DATA.size():
		var paths:=PackedStringArray()
		for frame in DATA.SOURCE.FRAME_COUNT: paths.append(DATA.frame_path(tier,frame))
		frame_paths.append(paths)
	clear()
func clear() -> void:
	slots.clear(); free_count=DATA.MAX_ROWS; clock=0.0
	for index in DATA.MAX_ROWS: free_slots[index]=DATA.MAX_ROWS-index-1
func replace(rows: Array,view) -> void:
	revision+=1
	for row in rows:
		var slot: int=slots.get(int(row[0]),-1)
		if slot>=0: seen[slot]=revision
	for slot in DATA.MAX_ROWS:
		if not slots.has(ids[slot]) or slots[ids[slot]]!=slot or seen[slot]==revision: continue
		slots.erase(ids[slot]); free_slots[free_count]=slot; free_count+=1
	for row in rows:
		var id:=int(row[0]); var slot: int=slots.get(id,-1)
		var known:=slot>=0
		if not known:
			if free_count==0: break
			free_count-=1; slot=free_slots[free_count]; slots[id]=slot; ids[slot]=id
		var point:=Vector2(row[1],row[2])
		if not known: positions[slot]=point
		# Repeated retained pickup rows must not restart the absorption animation.
		if not known or kinds[slot]!=DATA.COLLECTED:
			starts[slot]=positions[slot]; targets[slot]=point; elapsed[slot]=0.0
		kinds[slot]=int(row[4]); tiers[slot]=int(row[3]); seen[slot]=revision
		var tier:=int(row[3])
		if not requested_tiers.has(tier):
			requested_tiers[tier]=true
			for path in frame_paths[tier]: view._request_texture(path)
func advance(delta: float) -> bool:
	if slots.is_empty(): return false
	clock+=maxf(delta,0.0)
	var active:=false
	for slot in DATA.MAX_ROWS:
		if not slots.has(ids[slot]) or slots[ids[slot]]!=slot: continue
		var was_elapsed:=elapsed[slot]
		elapsed[slot]+=maxf(delta,0.0)
		if kinds[slot]==DATA.COLLECTED:
			active=active or was_elapsed<DATA.ABSORB_SECONDS
		else:
			positions[slot]=starts[slot].lerp(targets[slot],minf(1.0,elapsed[slot]/ART.MOTION_SECONDS))
			active=true # Shared six-frame idle animation continues on stationary gems.
	return active
func needs_process() -> bool:
	for slot in DATA.MAX_ROWS:
		if slots.has(ids[slot]) and slots[ids[slot]]==slot and (kinds[slot]!=DATA.COLLECTED or elapsed[slot]<DATA.ABSORB_SECONDS): return true
	return false
func draw(view,hero: Vector2) -> void:
	var map:=Transform2D(Vector2(view.map_scale.x,0),Vector2(0,view.map_scale.y),view.map_offset)
	var frame:=int(clock*DATA.ANIMATION_FPS)%DATA.SOURCE.FRAME_COUNT
	var extent: Vector2=DATA.SOURCE.FRAME_SIZE*(DATA.SOURCE.TARGET_HEIGHT/DATA.SOURCE.FRAME_SIZE.y)
	for slot in DATA.MAX_ROWS:
		if not slots.has(ids[slot]) or slots[ids[slot]]!=slot: continue
		var progress:=clampf(elapsed[slot]/DATA.ABSORB_SECONDS,0.0,1.0) if kinds[slot]==DATA.COLLECTED else 0.0
		if progress>=1.0: continue
		var point:=positions[slot].lerp(hero,progress)
		view.draw_set_transform_matrix(map*Transform2D(0.0,point))
		var texture: Texture2D=view.art_textures.get(frame_paths[tiers[slot]][frame])
		if texture!=null: view.draw_texture_rect(texture,Rect2(-extent*.5,extent),false,Color(1,1,1,1.0-progress))
		else: view.draw_circle(Vector2.ZERO,10.0,Color(.2,.85,1.0,1.0-progress))
	view.draw_set_transform_matrix(Transform2D.IDENTITY)
