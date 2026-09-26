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
	_configure_modern_cauldron_sfx()
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



func _configure_modern_cauldron_sfx() -> void:
	# Keep scene WAVs as fallback resources, then replace them with richer
	# one-shot PCM streams once this node is ready.
	if is_instance_valid(place_audio):
		place_audio.stream = _build_cauldron_place_sfx()
	if is_instance_valid(success_audio):
		success_audio.stream = _build_cauldron_success_sfx()
	if is_instance_valid(great_success_audio):
		great_success_audio.stream = _build_cauldron_great_success_sfx()
	if is_instance_valid(failure_audio):
		failure_audio.stream = _build_cauldron_failure_sfx()


func _build_cauldron_place_sfx() -> AudioStreamWAV:
	var stream := _new_cauldron_audio_stream()
	var duration := 0.46
	var sample_count := int(stream.mix_rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	var noise_state := 0.0
	for index in range(sample_count):
		var t := float(index) / float(stream.mix_rate)
		var raw_noise := _cauldron_noise(index, 1.37)
		noise_state = noise_state * 0.74 + raw_noise * 0.26
		var body := (
			sin(TAU * 78.0 * t) * 0.52
			+ sin(TAU * 131.0 * t) * 0.22
		) * exp(-13.0 * t)
		var metal := (
			sin(TAU * 421.0 * t) * 0.22
			+ sin(TAU * 683.0 * t) * 0.16
			+ sin(TAU * 1129.0 * t) * 0.10
		) * exp(-6.8 * t)
		var contact := noise_state * exp(-31.0 * t) * 0.26
		var scrape := noise_state * exp(-9.0 * t) * 0.07
		var sample := clampf((body + metal + contact + scrape) * 0.62, -1.0, 1.0)
		pcm.encode_s16(index * 2, int(round(sample * 32767.0)))
	stream.data = pcm
	return stream


func _build_cauldron_success_sfx() -> AudioStreamWAV:
	var stream := _new_cauldron_audio_stream()
	var duration := 0.68
	var sample_count := int(stream.mix_rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	var noise_state := 0.0
	for index in range(sample_count):
		var t := float(index) / float(stream.mix_rate)
		var raw_noise := _cauldron_noise(index, 4.91)
		noise_state = noise_state * 0.82 + raw_noise * 0.18
		var bubble_center := (t - 0.065) / 0.045
		var bubble_env := exp(-bubble_center * bubble_center * 2.8)
		var bubble := sin(TAU * (132.0 + 210.0 * t) * t) * bubble_env * 0.26
		var chime_t := maxf(t - 0.08, 0.0)
		var chime_gate := 1.0 if t >= 0.08 else 0.0
		var chime := (
			sin(TAU * 617.0 * chime_t) * 0.31
			+ sin(TAU * 929.0 * chime_t) * 0.21
			+ sin(TAU * 1387.0 * chime_t) * 0.13
		) * chime_gate * exp(-5.1 * chime_t)
		var air := noise_state * exp(-6.0 * t) * 0.07
		var sample := clampf((bubble + chime + air) * 0.58, -1.0, 1.0)
		pcm.encode_s16(index * 2, int(round(sample * 32767.0)))
	stream.data = pcm
	return stream


func _build_cauldron_great_success_sfx() -> AudioStreamWAV:
	var stream := _new_cauldron_audio_stream()
	var duration := 0.96
	var sample_count := int(stream.mix_rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	var noise_state := 0.0
	for index in range(sample_count):
		var t := float(index) / float(stream.mix_rate)
		var raw_noise := _cauldron_noise(index, 8.43)
		noise_state = noise_state * 0.86 + raw_noise * 0.14
		var bloom := (
			sin(TAU * 146.0 * t) * 0.28
			+ sin(TAU * 233.0 * t) * 0.16
		) * exp(-4.4 * t)
		var sparkle_t := maxf(t - 0.07, 0.0)
		var sparkle_gate := 1.0 if t >= 0.07 else 0.0
		var sparkle := (
			sin(TAU * 557.0 * sparkle_t) * 0.24
			+ sin(TAU * 887.0 * sparkle_t) * 0.19
			+ sin(TAU * 1321.0 * sparkle_t) * 0.13
			+ sin(TAU * 1769.0 * sparkle_t) * 0.08
		) * sparkle_gate * exp(-3.9 * sparkle_t)
		var tail_t := maxf(t - 0.34, 0.0)
		var tail_gate := 1.0 if t >= 0.34 else 0.0
		var tail := (
			sin(TAU * 761.0 * tail_t) * 0.13
			+ sin(TAU * 1181.0 * tail_t) * 0.09
		) * tail_gate * exp(-4.8 * tail_t)
		var air := noise_state * exp(-3.8 * t) * 0.055
		var sample := clampf((bloom + sparkle + tail + air) * 0.48, -1.0, 1.0)
		pcm.encode_s16(index * 2, int(round(sample * 32767.0)))
	stream.data = pcm
	return stream


func _build_cauldron_failure_sfx() -> AudioStreamWAV:
	var stream := _new_cauldron_audio_stream()
	var duration := 0.52
	var sample_count := int(stream.mix_rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	var noise_state := 0.0
	for index in range(sample_count):
		var t := float(index) / float(stream.mix_rate)
		var raw_noise := _cauldron_noise(index, 12.17)
		noise_state = noise_state * 0.78 + raw_noise * 0.22
		var plop := sin(TAU * (171.0 - 88.0 * t) * t) * exp(-9.2 * t) * 0.38
		var vessel := (
			sin(TAU * 389.0 * t) * 0.12
			+ sin(TAU * 641.0 * t) * 0.07
		) * exp(-12.0 * t)
		var fizz := noise_state * exp(-6.6 * t) * 0.17
		var sample := clampf((plop + vessel + fizz) * 0.60, -1.0, 1.0)
		pcm.encode_s16(index * 2, int(round(sample * 32767.0)))
	stream.data = pcm
	return stream


func _new_cauldron_audio_stream() -> AudioStreamWAV:
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
