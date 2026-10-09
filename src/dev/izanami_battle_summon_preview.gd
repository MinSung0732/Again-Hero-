extends Control
## F6 presentation sandbox. No Battle gameplay, resources, rewards or account writes.
const CINEMATIC := preload("res://src/ui/battle_summon_cinematic.gd")
const DOT := preload("res://assets/art/Transcendent_monster/Izanami/frames/idle_01.png")
class PreviewField extends Node2D:
	signal transcendent_summoned(id: String, actor: Node2D)
	signal transcendent_died(id: String, actor: Node2D)
	signal battle_finished(message: String, won: bool)
	var battle_over := false
	var external_pause := false
	var demon_augment_selection_active := false
	func _draw() -> void:
		draw_rect(Rect2(0,0,1200,1200),Color("251f31"))
		for i in range(25):
			draw_line(Vector2(i*50,0),Vector2(i*50,1200),Color("342b42"),1)
			draw_line(Vector2(0,i*50),Vector2(1200,i*50),Color("342b42"),1)
class PreviewPawn extends Node2D:
	var current_hp := 100
var hud_layer: Control
var battle: PreviewField
var battle_viewport: SubViewport
var battle_viewport_container: SubViewportContainer
var actor: PreviewPawn
var original: Camera2D
var cinematic: Control
var controls: HBoxContainer
var status: Label
func _ready() -> void:
	theme=Theme.new()
	theme.default_font=load("res://assets/fonts/Galmuri11.ttf")
	battle_viewport_container=SubViewportContainer.new()
	battle_viewport_container.stretch=true
	add_child(battle_viewport_container)
	battle_viewport=SubViewport.new()
	battle_viewport.size=Vector2i(540,650)
	battle_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	battle_viewport_container.add_child(battle_viewport)
	battle=PreviewField.new()
	battle_viewport.add_child(battle)
	original=Camera2D.new()
	original.position=Vector2(450,450)
	battle.add_child(original)
	original.make_current()
	actor=PreviewPawn.new()
	actor.position=Vector2(580,490)
	var sprite:=Sprite2D.new()
	sprite.texture=DOT
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale=Vector2.ONE*0.5
	actor.add_child(sprite)
	battle.add_child(actor)
	actor.hide()
	hud_layer=Control.new()
	hud_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(hud_layer)
	cinematic=CINEMATIC.new()
	var preview_ids: Array[String] = ["izanami"]
	cinematic.install(self,preview_ids)
	status=Label.new()
	status.text="이자나미 · 전투 소환 연출 예시\n실제 전투·계정 저장 없음"
	status.position=Vector2(16,20)
	add_child(status)
	controls=HBoxContainer.new()
	add_child(controls)
	for caption in ["소환 재생","중단·복귀"]:
		var button:=Button.new()
		button.text=caption
		button.custom_minimum_size=Vector2(210,64)
		controls.add_child(button)
		if controls.get_child_count()==1:button.pressed.connect(replay)
		else:button.pressed.connect(cinematic.cancel)
	resized.connect(_layout)
	_layout()
	replay.call_deferred()
func _layout() -> void:
	battle_viewport_container.position=Vector2(0,110)
	battle_viewport_container.size=Vector2(size.x,maxf(240,size.y-230))
	controls.position=Vector2(16,size.y-90)
func replay() -> void:
	actor.show()
	battle.transcendent_summoned.emit("izanami",actor)
func _end_camera_drag() -> void:
	pass
func _exit_tree() -> void:
	if is_instance_valid(cinematic):cinematic.cancel()
