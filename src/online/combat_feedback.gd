extends Node2D
const DATA := preload("res://src/data/online_feedback_catalog.gd")
const BANK := preload("res://src/audio/event_sfx_bank.gd")
const POPUPS := preload("res://src/ui/damage_number_spawner.gd")
const LEVEL_EFFECT := preload("res://src/ui/hero_level_up_effect.gd")
var bank
var level_sprite: AnimatedSprite2D
var baseline := 0
var slots: Array = []
var cursor := 0
var accepted := 0
var suspended := true
var result_played := false
func _ready() -> void:
	z_index = 80
	bank = BANK.new(); add_child(bank); bank.configure(DATA.audio_cues())
	level_sprite = AnimatedSprite2D.new(); add_child(level_sprite)
	LEVEL_EFFECT.configure(level_sprite, func(path: String): return load(path) as Texture2D if ResourceLoader.exists(path) else null)
	level_sprite.animation_finished.connect(func(): level_sprite.hide())
	for _index in DATA.CAPACITY: slots.append({"left":0.0,"point":Vector2.ZERO,"kind":"","color":Color.WHITE})
	set_process(false)
func reset(sequence: int = 0) -> void:
	baseline = sequence; suspended = true; result_played = false; clear()
func clear() -> void:
	for slot in slots: slot.left = 0.0
	for popup in get_meta(POPUPS.POOL_META,[]):
		if is_instance_valid(popup): popup.call("_deactivate_for_pool")
	bank.stop_all(); set_process(false); queue_redraw()
	if is_instance_valid(level_sprite): level_sprite.stop(); level_sprite.hide()
func pause_feedback() -> void:
	suspended = true; clear()
func consume(events: Variant,sequence: Variant,tick: Variant) -> bool:
	if not DATA.valid_events(events,sequence,tick): return false
	if sequence<baseline: return false
	if not suspended:
		_sync_transform()
		for row in events:
			if row[0]<=baseline or tick-row[1]>DATA.MAX_AGE_SECONDS*Engine.physics_ticks_per_second: continue
			accepted += 1
			var cue: String = row[2]
			if cue == "hero_hit":
				cue = DATA.hit_cue(String(get_parent().state.get("hero_archetype", "")))
			elif cue == "cast":
				cue = DATA.cast_cue(String(get_parent().state.get("hero_archetype", "")))
			elif cue == "ultimate":
				bank.stop_cue("summon")
			bank.play_cue(cue)
			if row[2] == "level_up":
				level_sprite.position = Vector2(row[3], row[4]) + Vector2(0.0, 44.0)
				level_sprite.stop(); level_sprite.frame = 0; level_sprite.frame_progress = 0.0
				level_sprite.show(); level_sprite.play(&"level_up"); set_process(true)
				continue
			if row[2] in ["hero_hit","monster_hit","heal"]:
				POPUPS.show_feedback(self,int(row[10]),Vector2(row[3],row[4]),int(row[5]),Color(row[6],row[7],row[8],row[9]),row[2]=="heal")
				set_process(true)
				continue
			if row[2] in ["cast", "ultimate"]: continue
			var slot: Dictionary = slots[cursor]; cursor = (cursor+1)%DATA.CAPACITY
			slot.left = DATA.LIFETIME; slot.point = Vector2(row[3],row[4]); slot.kind = row[2]; slot.color = Color(row[6],row[7],row[8],row[9])
			set_process(true)
	baseline = int(sequence); return true
func result(winner: String,role: String) -> void:
	if result_played: return
	result_played = true
	bank.stop_all()
	if not winner.is_empty(): bank.play_cue("victory" if winner==role else "defeat")
func _sync_transform() -> void:
	var view = get_parent()
	view._layout_map()
	position = view.map_offset
	scale = view.map_scale
func _process(delta: float) -> void:
	_sync_transform()
	var active := false
	active = level_sprite.visible
	for slot in slots:
		if slot.left>0: slot.left = maxf(0,slot.left-delta); active = active or slot.left>0
	if not active:
		for popup in get_meta(POPUPS.POOL_META,[]):
			if is_instance_valid(popup) and bool(popup.call("is_pool_active")): active = true; break
	queue_redraw(); set_process(active)
func _draw() -> void:
	var view = get_parent()
	view._layout_map()
	for slot in slots:
		if slot.left<=0: continue
		var ratio: float = slot.left/DATA.LIFETIME
		var point: Vector2 = slot.point
		var color: Color = slot.color; color.a *= ratio
		var radius: float = (95 if slot.kind=="transcend" else 40)*(1.4-ratio*0.4)
		draw_arc(point,radius,0,TAU,16,color,2,false)
