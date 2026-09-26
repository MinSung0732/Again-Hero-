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
	_configure_cauldron_audio()
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
			complete_frame = 5
			complete_timer = 0.0
			_apply_frame(complete_frame)
		elif complete_frame == 5 and complete_timer >= 0.20:
			mix_completed.emit(self, global_position)
			set_process(false)
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



const CAULDRON_PLACE_VOLUME_DB := -16.5
const CAULDRON_SUCCESS_VOLUME_DB := -17.5
const CAULDRON_GREAT_SUCCESS_VOLUME_DB := -22.0
const CAULDRON_FAILURE_VOLUME_DB := -18.0


func _configure_cauldron_audio() -> void:
	if is_instance_valid(place_audio):
		place_audio.stream = _build_cauldron_place_sfx()
		place_audio.volume_db = CAULDRON_PLACE_VOLUME_DB
	if is_instance_valid(success_audio):
		success_audio.stream = _build_cauldron_success_sfx()
		success_audio.volume_db = CAULDRON_SUCCESS_VOLUME_DB
	if is_instance_valid(great_success_audio):
		great_success_audio.stream = _build_cauldron_great_success_sfx()
		great_success_audio.volume_db = CAULDRON_GREAT_SUCCESS_VOLUME_DB
	if is_instance_valid(failure_audio):
		failure_audio.stream = _build_cauldron_failure_sfx()
		failure_audio.volume_db = CAULDRON_FAILURE_VOLUME_DB


func _build_cauldron_place_sfx() -> AudioStreamWAV:
	var stream := _new_cauldron_stream()
	var duration := 0.42
	var sample_count := int(stream.mix_rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for index in range(sample_count):
		var t := float(index) / float(stream.mix_rate)
		var impact_env := exp(-13.0 * t)
		var metal_env := exp(-7.2 * t)
		var body := (
			sin(TAU * 82.0 * t) * 0.62
			+ sin(TAU * 137.0 * t) * 0.23
		) * impact_env
		var metal := (
			sin(TAU * 437.0 * t) * 0.23
			+ sin(TAU * 683.0 * t) * 0.17
			+ sin(TAU * 1091.0 * t) * 0.10
		) * metal_env
		var transient := _cauldron_noise(index, 1.7) * exp(-38.0 * t) * 0.30
		var scrape := _cauldron_noise(index, 3.1) * exp(-11.0 * t) * 0.07
		var sample := clampf((body + metal + transient + scrape) * 0.68, -1.0, 1.0)
		pcm.encode_s16(index * 2, int(round(sample * 32767.0)))
	stream.data = pcm
	return stream


func _build_cauldron_success_sfx() -> AudioStreamWAV:
	var stream := _new_cauldron_stream()
	var duration := 0.62
	var sample_count := int(stream.mix_rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for index in range(sample_count):
		var t := float(index) / float(stream.mix_rate)
		var bubble_delta := (t - 0.055) / 0.034
		var bubble_env := exp(-bubble_delta * bubble_delta * 3.2)
		var bubble := sin(TAU * 148.0 * t) * bubble_env * 0.28
		var chime_t := maxf(t - 0.07, 0.0)
		var chime_gate := 1.0 if t >= 0.07 else 0.0
		var chime_env := chime_gate * exp(-5.8 * chime_t)
		var chime := (
			sin(TAU * 724.0 * chime_t) * 0.42
			+ sin(TAU * 1037.0 * chime_t) * 0.27
			+ sin(TAU * 1481.0 * chime_t) * 0.15
		) * chime_env
		var air := _cauldron_noise(index, 5.3) * exp(-7.0 * t) * 0.08
		var sample := clampf((bubble + chime + air) * 0.62, -1.0, 1.0)
		pcm.encode_s16(index * 2, int(round(sample * 32767.0)))
	stream.data = pcm
	return stream


func _build_cauldron_great_success_sfx() -> AudioStreamWAV:
	var stream := _new_cauldron_stream()
	var duration := 0.95
	var sample_count := int(stream.mix_rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for index in range(sample_count):
		var t := float(index) / float(stream.mix_rate)
		var bloom := (
			sin(TAU * 151.0 * t) * 0.34
			+ sin(TAU * 227.0 * t) * 0.18
		) * exp(-4.6 * t)
		var sparkle_t := maxf(t - 0.08, 0.0)
		var sparkle_gate := 1.0 if t >= 0.08 else 0.0
		var sparkle := (
			sin(TAU * 611.0 * sparkle_t) * 0.29
			+ sin(TAU * 941.0 * sparkle_t) * 0.23
			+ sin(TAU * 1367.0 * sparkle_t) * 0.17
			+ sin(TAU * 1831.0 * sparkle_t) * 0.10
		) * sparkle_gate * exp(-4.1 * sparkle_t)
		var tail_t := maxf(t - 0.31, 0.0)
		var tail_gate := 1.0 if t >= 0.31 else 0.0
		var tail := (
			sin(TAU * 823.0 * tail_t) * 0.18
			+ sin(TAU * 1259.0 * tail_t) * 0.12
		) * tail_gate * exp(-5.2 * tail_t)
		var air := _cauldron_noise(index, 7.7) * exp(-4.0 * t) * 0.06
		var sample := clampf((bloom + sparkle + tail + air) * 0.52, -1.0, 1.0)
		pcm.encode_s16(index * 2, int(round(sample * 32767.0)))
	stream.data = pcm
	return stream


func _build_cauldron_failure_sfx() -> AudioStreamWAV:
	var stream := _new_cauldron_stream()
	var duration := 0.48
	var sample_count := int(stream.mix_rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for index in range(sample_count):
		var t := float(index) / float(stream.mix_rate)
		var plop := sin(TAU * (178.0 - 92.0 * t) * t) * exp(-9.5 * t) * 0.45
		var fizz := _cauldron_noise(index, 11.4) * exp(-8.2 * t) * 0.18
		var glass := sin(TAU * 503.0 * t) * exp(-15.0 * t) * 0.12
		var sample := clampf((plop + fizz + glass) * 0.66, -1.0, 1.0)
		pcm.encode_s16(index * 2, int(round(sample * 32767.0)))
	stream.data = pcm
	return stream


func _new_cauldron_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	return stream


func _cauldron_noise(index: int, salt: float) -> float:
	var seed := sin(float(index) * 12.9898 + salt * 78.233) * 43758.5453
	var unit := seed - floor(seed)
	return unit * 2.0 - 1.0


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
