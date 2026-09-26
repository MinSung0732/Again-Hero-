extends Node2D

signal mix_completed(cauldron: Node2D, world_position: Vector2)

const FRAME_DIR := "res://assets/art/heroes/stage7_alchemist/frames/effect6"
const FRAME_PATHS: Array[String] = [
	"%s/cauldron_01.png" % FRAME_DIR,
	"%s/cauldron_02.png" % FRAME_DIR,
	"%s/cauldron_03.png" % FRAME_DIR,
	"%s/cauldron_04.png" % FRAME_DIR,
	"%s/cauldron_05.png" % FRAME_DIR,
	"%s/cauldron_06.png" % FRAME_DIR,
]
const MIX_FRAME_ORDER: Array[int] = [0, 1, 2, 5]
const ANCHOR := Vector2(192.0, 596.0)

@onready var visual: Sprite2D = $Visual
@onready var place_audio: AudioStreamPlayer = $PlaceAudio
@onready var great_success_audio: AudioStreamPlayer = $GreatSuccessAudio
@onready var success_audio: AudioStreamPlayer = $SuccessAudio
@onready var failure_audio: AudioStreamPlayer = $FailureAudio

var active: bool = false
var mix_duration: float = 8.0
var mix_elapsed: float = 0.0
var frame_timer: float = 0.0
var mix_frame_cursor: int = 0
var completing: bool = false
var complete_timer: float = 0.0
var complete_frame: int = 3


func _ready() -> void:
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.centered = false
	visual.offset = -ANCHOR
	visual.scale = Vector2(0.34, 0.34)
	deactivate()


func activate(world_position: Vector2, duration: float) -> void:
	global_position = world_position
	mix_duration = maxf(duration, 0.1)
	mix_elapsed = 0.0
	frame_timer = 0.0
	mix_frame_cursor = 0
	completing = false
	complete_timer = 0.0
	complete_frame = 3
	active = true
	visible = true
	set_process(true)
	_apply_frame(MIX_FRAME_ORDER[0])
	if is_instance_valid(place_audio):
		place_audio.stop()
		place_audio.play()
	queue_redraw()


func deactivate() -> void:
	active = false
	visible = false
	set_process(false)
	completing = false
	queue_redraw()


func _process(delta: float) -> void:
	if not active:
		return

	if completing:
		complete_timer += delta
		if complete_frame == 3 and complete_timer >= 0.16:
			complete_frame = 4
			complete_timer = 0.0
			_apply_frame(complete_frame)
		elif complete_frame == 4 and complete_timer >= 0.18:
			mix_completed.emit(self, global_position)
		return
		queue_redraw()
		return

	mix_elapsed = minf(mix_elapsed + delta, mix_duration)
	frame_timer -= delta
	if frame_timer <= 0.0:
		frame_timer = 0.16
		mix_frame_cursor = (mix_frame_cursor + 1) % MIX_FRAME_ORDER.size()
		_apply_frame(MIX_FRAME_ORDER[mix_frame_cursor])

	if mix_elapsed >= mix_duration:
		completing = true
		complete_timer = 0.0
		complete_frame = 3
		_apply_frame(complete_frame)

	queue_redraw()


func play_result_sound(result_type: String) -> void:
	var player: AudioStreamPlayer = null
	match result_type:
		"great_success":
			player = great_success_audio
		"success":
			player = success_audio
		"failure":
			player = failure_audio
	if is_instance_valid(player):
		player.stop()
		player.play()


func _apply_frame(index: int) -> void:
	if index < 0 or index >= FRAME_PATHS.size():
		return
	var texture := _load_texture(FRAME_PATHS[index])
	if texture != null:
		visual.texture = texture


func _draw() -> void:
	if not active:
		return

	var width: float = 104.0
	var height: float = 11.0
	var top_left := Vector2(-width * 0.5, -116.0)
	var ratio: float = 1.0 if completing else clampf(
		mix_elapsed / maxf(mix_duration, 0.001),
		0.0,
		1.0
	)
	draw_rect(
		Rect2(top_left - Vector2(2.0, 2.0), Vector2(width + 4.0, height + 4.0)),
		Color(0.05, 0.06, 0.08, 0.92)
	)
	draw_rect(
		Rect2(top_left, Vector2(width, height)),
		Color(0.18, 0.20, 0.24, 0.95)
	)
	draw_rect(
		Rect2(top_left, Vector2(width * ratio, height)),
		Color(0.72, 0.25, 0.92, 0.98)
	)


func _load_texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	return null
