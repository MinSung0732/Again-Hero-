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
	"stage_2": {
		"intro": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage02/Stage02_Intro_One_Move_Ahead.ogg",
		"battle": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage02/Stage02_Battle_One_Move_Ahead.ogg",
		"phase2": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage02/Stage02_Phase2_One_Move_Ahead.ogg",
		"final": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage02/Stage02_Final_One_Move_Ahead.ogg",
	},
	"stage_3": {
		"intro": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage03/Stage03_Intro_Oath_of_Conviction.ogg",
		"battle": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage03/Stage03_Battle_Oath_of_Conviction.ogg",
		"phase2": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage03/Stage03_Phase2_Oath_of_Conviction.ogg",
		"final": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage03/Stage03_Final_Oath_of_Conviction.ogg",
	},
	"stage_4": {
		"intro": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage04/Stage04_Intro_Twin_Stars_of_the_Badlands.ogg",
		"battle": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage04/Stage04_Battle_Twin_Stars_of_the_Badlands.ogg",
		"phase2": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage04/Stage04_Phase2_Twin_Stars_of_the_Badlands.ogg",
		"final": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage04/Stage04_Final_Twin_Stars_of_the_Badlands.ogg",
	},
	"stage_5": {
		"intro": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage05/Stage05_Intro_Star_Beyond_Defeat.ogg",
		"battle": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage05/Stage05_Battle_Star_Beyond_Defeat.ogg",
		"phase2": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage05/Stage05_Phase2_Star_Beyond_Defeat.ogg",
		"final": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage05/Stage05_Final_Star_Beyond_Defeat.ogg",
	},
	"stage_6": {
		"intro": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage06/Stage06_Intro_Bloodstained_Silence.ogg",
		"battle": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage06/Stage06_Battle_Bloodstained_Silence.ogg",
		"phase2": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage06/Stage06_Phase2_Bloodstained_Silence.ogg",
		"final": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage06/Stage06_Final_Bloodstained_Silence.ogg",
	},
	"stage_7": {
		"intro": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage07/Stage07_Intro_Perfectly_Unstable.ogg",
		"battle": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage07/Stage07_Battle_Perfectly_Unstable.ogg",
		"phase2": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage07/Stage07_Phase2_Perfectly_Unstable.ogg",
		"final": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage07/Stage07_Final_Perfectly_Unstable.ogg",
	},
	"stage_8": {
		"intro": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage08/Stage08_Intro_The_Otherworld_Obeys_Me.ogg",
		"battle": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage08/Stage08_Battle_The_Otherworld_Obeys_Me.ogg",
		"phase2": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage08/Stage08_Phase2_The_Otherworld_Obeys_Me.ogg",
		"final": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage08/Stage08_Final_The_Otherworld_Obeys_Me.ogg",
	},
	"stage_9": {
		"intro": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage09/Stage09_Intro_Where_Prayer_Ends.ogg",
		"battle": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage09/Stage09_Battle_Where_Prayer_Ends.ogg",
		"phase2": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage09/Stage09_Phase2_Where_Prayer_Ends.ogg",
		"final": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage09/Stage09_Final_Where_Prayer_Ends.ogg",
	},
	"stage_10": {
		"intro": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage10/Stage10_Intro_The_Star_No_Longer_Smiles.ogg",
		"battle": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage10/Stage10_Battle_The_Star_No_Longer_Smiles.ogg",
		"phase2": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage10/Stage10_Phase2_The_Star_No_Longer_Smiles.ogg",
		"final": "res://assets/audio/bgm/hero_main_theme/phaseBgm/Stage10/Stage10_Final_The_Star_No_Longer_Smiles.ogg",
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
var _user_volume_db: float = PLAY_DB
var _user_muted: bool = false


func _ready() -> void:
	_active_player = player_a
	_standby_player = player_b
	player_a.bus = BGM_BUS
	player_b.bus = BGM_BUS
	player_a.volume_db = SILENT_DB
	player_b.volume_db = SILENT_DB
	player_a.finished.connect(_on_player_finished.bind(player_a))
	player_b.finished.connect(_on_player_finished.bind(player_b))
	if AudioSettings != null:
		AudioSettings.settings_changed.connect(_sync_audio_settings)
	_sync_audio_settings()


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
	_sync_stream_pause_state()

	_active_player = incoming
	_standby_player = outgoing

	var fade_duration := maxf(duration, 0.01)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(incoming, "volume_db", _get_play_db(), fade_duration)
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
	_active_player.volume_db = _get_play_db()
	_active_player.play()
	_sync_stream_pause_state()


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


func set_user_bgm_level(level: int) -> void:
	_user_volume_db = _level_to_db(level)
	AudioSettings.apply_bgm_level_to_bus(level, _user_muted)
	_apply_user_audio_state()


func set_user_bgm_muted(muted: bool) -> void:
	_user_muted = muted
	AudioSettings.apply_bgm_level_to_bus(AudioSettings.bgm_level, muted)
	_apply_user_audio_state()


func refresh_user_audio_settings() -> void:
	_sync_audio_settings()


func _sync_audio_settings() -> void:
	if AudioSettings != null:
		_user_muted = bool(AudioSettings.bgm_muted)
		_user_volume_db = _level_to_db(int(AudioSettings.bgm_level))
		AudioSettings.apply_bgm_level_to_bus(
			int(AudioSettings.bgm_level),
			_user_muted
		)
	_apply_user_audio_state()


func _apply_user_audio_state() -> void:
	if _user_muted:
		_kill_fade_tween()

	for player in [player_a, player_b]:
		if not is_instance_valid(player):
			continue
		player.stream_paused = _user_muted
		if _user_muted:
			player.volume_db = SILENT_DB
		elif player == _active_player and player.playing:
			player.volume_db = PLAY_DB
		elif player != _active_player:
			player.volume_db = SILENT_DB

	if _stopping or _user_muted:
		return

	if (
		is_instance_valid(_standby_player)
		and _standby_player != _active_player
		and _standby_player.playing
	):
		_standby_player.stop()
		_standby_player.stream = null
		_standby_player.volume_db = SILENT_DB


func _sync_stream_pause_state() -> void:
	for player in [player_a, player_b]:
		if not is_instance_valid(player):
			continue
		player.stream_paused = _user_muted
		if _user_muted:
			player.volume_db = SILENT_DB
		elif player == _active_player and player.playing:
			player.volume_db = PLAY_DB


func _get_play_db() -> float:
	return PLAY_DB


func get_audio_debug_summary() -> String:
	var settings_level := -1
	var settings_muted := false
	var settings_db := PLAY_DB
	if AudioSettings != null:
		settings_level = int(AudioSettings.bgm_level)
		settings_muted = bool(AudioSettings.bgm_muted)
		settings_db = _level_to_db(settings_level)

	var bgm_bus_index := AudioServer.get_bus_index(BGM_BUS)
	var bgm_bus_line := "BGM bus=MISSING"
	if bgm_bus_index >= 0:
		bgm_bus_line = "BGM bus=%d mute=%s db=%.1f" % [
			bgm_bus_index,
			str(AudioServer.is_bus_mute(bgm_bus_index)),
			AudioServer.get_bus_volume_db(bgm_bus_index),
		]

	var master_index := AudioServer.get_bus_index(&"Master")
	var master_line := "Master=MISSING"
	if master_index >= 0:
		master_line = "Master=%d mute=%s db=%.1f" % [
			master_index,
			str(AudioServer.is_bus_mute(master_index)),
			AudioServer.get_bus_volume_db(master_index),
		]

	var phase_key := _phase_key(current_phase)
	var expected_path := ""
	var stage_data = STAGE_BGM.get(current_stage_id, {})
	if typeof(stage_data) == TYPE_DICTIONARY:
		expected_path = String(Dictionary(stage_data).get(phase_key, ""))

	var bus_names: PackedStringArray = []
	for index in range(AudioServer.bus_count):
		bus_names.append("%d:%s" % [index, AudioServer.get_bus_name(index)])

	return "\n".join([
		"BGMDBG-3",
		"stage=%s phase=%s(%d)" % [current_stage_id, phase_key, current_phase],
		"settings level=%d mute=%s db=%.1f" % [
			settings_level,
			str(settings_muted),
			settings_db,
		],
		"manager mute=%s db=%.1f stopping=%s" % [
			str(_user_muted),
			_user_volume_db,
			str(_stopping),
		],
		_player_debug_line("A", player_a),
		_player_debug_line("B", player_b),
		bgm_bus_line,
		master_line,
		"buses=%s" % ", ".join(bus_names),
		"expected=%s" % expected_path,
	])


func _player_debug_line(label: String, player: AudioStreamPlayer) -> String:
	if not is_instance_valid(player):
		return "%s INVALID" % label

	var active := player == _active_player
	var stream_name := "none"
	if player.stream != null:
		stream_name = player.stream.resource_path
		if stream_name.is_empty():
			stream_name = player.stream.get_class()

	return "%s active=%s playing=%s paused=%s db=%.1f bus=%s stream=%s" % [
		label,
		str(active),
		str(player.playing),
		str(player.stream_paused),
		player.volume_db,
		String(player.bus),
		stream_name,
	]


func _level_to_db(level: int) -> float:
	return AudioSettings.bgm_level_to_db(level)


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
