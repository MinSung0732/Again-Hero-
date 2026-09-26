extends Node

enum Phase {
	NONE = -1,
	INTRO = 0,
	BATTLE = 1,
	PHASE2 = 2,
	FINAL = 3,
}

const CROSSFADE_SECONDS := 0.40
const STOP_FADE_SECONDS := 0.40
const SILENT_DB := -80.0
const PLAY_DB := 0.0
const BGM_BUS := &"BGM"

# Add stage_2 ~ stage_10 entries here after Stage 1 verification.
# The manager logic itself does not need stage-specific branches.
const STAGE_BGM: Dictionary = {
	"stage_1": {
		"intro": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage01/Stage01_Intro_Frozen_First_Step.ogg",
		"battle": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage01/Stage01_Battle_Frozen_First_Step.ogg",
		"phase2": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage01/Stage01_Phase2_Frozen_First_Step.ogg",
		"final": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage01/Stage01_Final_Frozen_First_Step.ogg",
	},
}

@onready var player_a: AudioStreamPlayer = $PlayerA
@onready var player_b: AudioStreamPlayer = $PlayerB

var current_stage_id: String = ""
var current_phase: int = Phase.NONE

var _active_player: AudioStreamPlayer
var _standby_player: AudioStreamPlayer
var _stage_streams: Dictionary = {}
var _fade_tween: Tween
var _stopping: bool = false


func _ready() -> void:
	_active_player = player_a
	_standby_player = player_b
	player_a.bus = BGM_BUS
	player_b.bus = BGM_BUS
	player_a.volume_db = SILENT_DB
	player_b.volume_db = SILENT_DB
	player_a.finished.connect(_on_player_finished.bind(player_a))
	player_b.finished.connect(_on_player_finished.bind(player_b))


func start_stage(stage_id: String) -> void:
	_reset_runtime_state()
	current_stage_id = stage_id

	var stage_data = STAGE_BGM.get(stage_id, {})
	if typeof(stage_data) != TYPE_DICTIONARY or stage_data.is_empty():
		return

	_cache_stage_streams(Dictionary(stage_data))
	if not _stage_streams.has("intro"):
		push_warning("Hero BGM: intro track missing for %s" % stage_id)
		return

	_stopping = false
	change_phase(Phase.INTRO, false)


func update_hero_hp(current_hp: int, max_hp: int) -> void:
	if current_phase == Phase.NONE or _stopping or max_hp <= 0:
		return

	var hp_ratio := clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	if hp_ratio <= 0.10:
		change_phase(Phase.FINAL)
	elif hp_ratio <= 0.50:
		change_phase(Phase.PHASE2)


func stop_bgm() -> void:
	_stopping = true
	_kill_fade_tween()

	var players: Array[AudioStreamPlayer] = [player_a, player_b]
	var has_playing_player := false
	var tween := create_tween()
	tween.set_parallel(true)

	for player in players:
		if not player.playing:
			continue
		has_playing_player = true
		tween.tween_property(
			player,
			"volume_db",
			SILENT_DB,
			STOP_FADE_SECONDS
		)

	if not has_playing_player:
		_stop_players()
		current_phase = Phase.NONE
		return

	_fade_tween = tween
	tween.finished.connect(
		func() -> void:
			_stop_players()
			current_phase = Phase.NONE
			_fade_tween = null
	)


func change_phase(next_phase: int, use_crossfade: bool = true) -> void:
	if _stopping:
		return
	if next_phase < Phase.INTRO or next_phase > Phase.FINAL:
		return
	if current_phase != Phase.NONE and next_phase <= current_phase:
		return

	var phase_key := _phase_key(next_phase)
	var stream = _stage_streams.get(phase_key)
	if not (stream is AudioStream):
		push_warning(
			"Hero BGM: missing %s track for %s"
			% [phase_key, current_stage_id]
		)
		return

	current_phase = next_phase

	if (
		not use_crossfade
		or not is_instance_valid(_active_player)
		or not _active_player.playing
	):
		_play_immediate(stream)
		return

	crossfade_to(stream)


func crossfade_to(stream: AudioStream, duration: float = CROSSFADE_SECONDS) -> void:
	if stream == null:
		return
	if not is_instance_valid(_active_player) or not is_instance_valid(_standby_player):
		return

	_kill_fade_tween()

	var outgoing := _active_player
	var incoming := _standby_player

	incoming.stop()
	incoming.stream = stream
	incoming.volume_db = SILENT_DB
	incoming.play()

	_active_player = incoming
	_standby_player = outgoing

	var fade_duration := maxf(duration, 0.01)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(incoming, "volume_db", PLAY_DB, fade_duration)
	if outgoing.playing:
		tween.tween_property(outgoing, "volume_db", SILENT_DB, fade_duration)

	_fade_tween = tween
	tween.finished.connect(
		func() -> void:
			if outgoing != _active_player:
				outgoing.stop()
				outgoing.stream = null
				outgoing.volume_db = SILENT_DB
			if _fade_tween == tween:
				_fade_tween = null
	)


func _play_immediate(stream: AudioStream) -> void:
	_kill_fade_tween()
	_stop_players()
	_active_player = player_a
	_standby_player = player_b
	_active_player.stream = stream
	_active_player.volume_db = PLAY_DB
	_active_player.play()


func _on_player_finished(player: AudioStreamPlayer) -> void:
	if _stopping:
		return
	if player != _active_player:
		return
	if current_phase != Phase.INTRO:
		return

	change_phase(Phase.BATTLE)


func _cache_stage_streams(stage_data: Dictionary) -> void:
	_stage_streams.clear()
	for phase_key in ["intro", "battle", "phase2", "final"]:
		var path := String(stage_data.get(phase_key, ""))
		if path.is_empty() or not ResourceLoader.exists(path):
			continue

		var resource = load(path)
		if not (resource is AudioStream):
			continue

		var stream: AudioStream = resource
		if resource is AudioStreamOggVorbis:
			var ogg_stream := resource.duplicate(true) as AudioStreamOggVorbis
			ogg_stream.loop = phase_key != "intro"
			stream = ogg_stream

		_stage_streams[phase_key] = stream


func _phase_key(phase: int) -> String:
	match phase:
		Phase.INTRO:
			return "intro"
		Phase.BATTLE:
			return "battle"
		Phase.PHASE2:
			return "phase2"
		Phase.FINAL:
			return "final"
		_:
			return ""


func _reset_runtime_state() -> void:
	_kill_fade_tween()
	_stop_players()
	_stage_streams.clear()
	current_stage_id = ""
	current_phase = Phase.NONE
	_stopping = false
	_active_player = player_a
	_standby_player = player_b


func _kill_fade_tween() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func _stop_players() -> void:
	for player in [player_a, player_b]:
		player.stop()
		player.stream = null
		player.volume_db = SILENT_DB
