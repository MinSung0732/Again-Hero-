extends Node2D
const DATA := preload("res://src/data/online_feedback_catalog.gd")
const BANK := preload("res://src/audio/event_sfx_bank.gd")
var bank
var baseline := 0
var slots: Array = []
var cursor := 0
var accepted := 0
var suspended := true
var result_played := false
var font: Font
func _ready() -> void:
	z_index = 80; font = get_parent().get_theme_default_font()
	bank = BANK.new(); add_child(bank); bank.configure(DATA.CUES)
	for _index in DATA.CAPACITY: slots.append({"left":0.0,"point":Vector2.ZERO,"kind":"","color":Color.WHITE,"text":"","width":0.0})
	set_process(false)
func reset(sequence: int = 0) -> void:
	baseline = sequence; suspended = true; result_played = false; clear()
func clear() -> void:
	for slot in slots: slot.left = 0.0
	bank.stop_all(); set_process(false); queue_redraw()
func pause_feedback() -> void:
	suspended = true; clear()
func consume(events: Variant,sequence: Variant,tick: Variant) -> bool:
	if not DATA.valid_events(events,sequence,tick): return false
	if sequence<baseline: return false
	if not suspended:
		for row in events:
			if row[0]<=baseline or tick-row[1]>DATA.MAX_AGE_SECONDS*Engine.physics_ticks_per_second: continue
			accepted += 1
			bank.play_cue(row[2])
			if row[2]=="cast": continue
			var slot: Dictionary = slots[cursor]; cursor = (cursor+1)%DATA.CAPACITY
			slot.left = DATA.LIFETIME; slot.point = Vector2(row[3],row[4]); slot.kind = row[2]; slot.color = Color(row[6],row[7],row[8],row[9])
			slot.text = ("+" if row[2]=="heal" else "")+str(int(row[5])) if row[5]>0 else ""
			slot.width = font.get_string_size(slot.text,HORIZONTAL_ALIGNMENT_LEFT,-1,DATA.FONT_SIZE).x
			set_process(true)
	baseline = int(sequence); return true
func result(winner: String,role: String) -> void:
	if result_played: return
	result_played = true
	bank.stop_all()
	if not winner.is_empty(): bank.play_cue("victory" if winner==role else "defeat")
func _process(delta: float) -> void:
	var active := false
	for slot in slots:
		if slot.left>0: slot.left = maxf(0,slot.left-delta); active = active or slot.left>0
	queue_redraw(); set_process(active)
func _draw() -> void:
	var view = get_parent()
	view._layout_map()
	for slot in slots:
		if slot.left<=0: continue
		var ratio: float = slot.left/DATA.LIFETIME
		var point: Vector2 = view.map_offset+slot.point*view.scale_ratio
		var color: Color = slot.color; color.a *= ratio
		var radius: float = maxf(8,40*view.scale_ratio)*(1.4-ratio*0.4)
		draw_arc(point,radius,0,TAU,16,color,2,false)
		if not slot.text.is_empty():
			var position := point+Vector2(-slot.width*0.5,-24-(DATA.LIFETIME-slot.left)*DATA.RISE_SPEED)
			draw_string(font,position+Vector2(2,2),slot.text,HORIZONTAL_ALIGNMENT_LEFT,-1,DATA.FONT_SIZE,Color(0,0,0,ratio))
			draw_string(font,position,slot.text,HORIZONTAL_ALIGNMENT_LEFT,-1,DATA.FONT_SIZE,color)
