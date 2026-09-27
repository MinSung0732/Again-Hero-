extends Node

signal settings_changed

const CONFIG_PATH := "user://audio_settings.cfg"
const BGM_BUS := &"BGM"
const SFX_BUS := &"SFX"

const DEFAULT_LEVEL := 10
const MIN_LEVEL := 1
const MAX_LEVEL := 10

# Level 10 preserves the project's intended mix ceiling.
# BGM stays behind combat sounds even at maximum.
# 1~10 각 단계가 체감상 확실히 구분되도록 dB 간격을 크게 둔다.
# BGM 10은 기존 -18 dB 상한을 유지해서 전투음 뒤에 깔리게 한다.
const BGM_LEVEL_DB := PackedFloat32Array([
	-54.0, -48.0, -43.0, -38.0, -34.0,
	-30.0, -27.0, -24.0, -21.0, -18.0,
])
const SFX_LEVEL_DB := PackedFloat32Array([
	-45.0, -38.0, -32.0, -27.0, -22.0,
	-18.0, -14.0, -10.0, -5.0, 0.0,
])

var bgm_level: int = DEFAULT_LEVEL
var sfx_level: int = DEFAULT_LEVEL
var bgm_muted: bool = false
var sfx_muted: bool = false


func _ready() -> void:
	_ensure_audio_buses()
	load_settings()
	apply_settings()


func set_bgm_level(value: int) -> void:
	bgm_level = clampi(value, MIN_LEVEL, MAX_LEVEL)
	_apply_bgm_bus_state()
	_save_and_emit()


func set_sfx_level(value: int) -> void:
	sfx_level = clampi(value, MIN_LEVEL, MAX_LEVEL)
	_apply_bus(SFX_BUS, sfx_level, sfx_muted, SFX_LEVEL_DB)
	_save_and_emit()


func set_bgm_muted(value: bool) -> void:
	bgm_muted = value
	_apply_bgm_bus_state()
	_save_and_emit()


func set_sfx_muted(value: bool) -> void:
	sfx_muted = value
	_apply_bus(SFX_BUS, sfx_level, sfx_muted, SFX_LEVEL_DB)
	_save_and_emit()


func apply_settings() -> void:
	_apply_bgm_bus_state()
	_apply_bus(SFX_BUS, sfx_level, sfx_muted, SFX_LEVEL_DB)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return

	bgm_level = clampi(
		int(config.get_value("audio", "bgm_level", DEFAULT_LEVEL)),
		MIN_LEVEL,
		MAX_LEVEL
	)
	sfx_level = clampi(
		int(config.get_value("audio", "sfx_level", DEFAULT_LEVEL)),
		MIN_LEVEL,
		MAX_LEVEL
	)
	bgm_muted = bool(config.get_value("audio", "bgm_muted", false))
	sfx_muted = bool(config.get_value("audio", "sfx_muted", false))


func _ensure_audio_buses() -> void:
	_ensure_bus(BGM_BUS)
	_ensure_bus(SFX_BUS)


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return

	var bus_index := AudioServer.bus_count
	AudioServer.add_bus(bus_index)
	AudioServer.set_bus_name(bus_index, bus_name)


func get_bgm_volume_db() -> float:
	var level_index := clampi(bgm_level, MIN_LEVEL, MAX_LEVEL) - MIN_LEVEL
	level_index = mini(level_index, BGM_LEVEL_DB.size() - 1)
	return BGM_LEVEL_DB[level_index]


func _apply_bgm_bus_state() -> void:
	var bus_index := AudioServer.get_bus_index(BGM_BUS)
	if bus_index < 0:
		return

	# HeroBGMManager applies the user level directly to its players so
	# crossfades and mute cannot be bypassed by a missing/misrouted bus.
	AudioServer.set_bus_volume_db(bus_index, 0.0)
	AudioServer.set_bus_mute(bus_index, bgm_muted)


func _apply_bus(
	bus_name: StringName,
	level: int,
	muted: bool,
	level_db: PackedFloat32Array
) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0 or level_db.is_empty():
		return

	var level_index := clampi(level, MIN_LEVEL, MAX_LEVEL) - MIN_LEVEL
	level_index = mini(level_index, level_db.size() - 1)
	AudioServer.set_bus_volume_db(bus_index, level_db[level_index])
	AudioServer.set_bus_mute(bus_index, muted)


func _save_and_emit() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "bgm_level", bgm_level)
	config.set_value("audio", "sfx_level", sfx_level)
	config.set_value("audio", "bgm_muted", bgm_muted)
	config.set_value("audio", "sfx_muted", sfx_muted)
	config.save(CONFIG_PATH)
	settings_changed.emit()
