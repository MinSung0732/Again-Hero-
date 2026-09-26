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
const BGM_MIN_DB := -42.0
const BGM_MAX_DB := -18.0
const SFX_MIN_DB := -30.0
const SFX_MAX_DB := 0.0

var bgm_level: int = DEFAULT_LEVEL
var sfx_level: int = DEFAULT_LEVEL
var bgm_muted: bool = false
var sfx_muted: bool = false


func _ready() -> void:
	load_settings()
	apply_settings()


func set_bgm_level(value: int) -> void:
	bgm_level = clampi(value, MIN_LEVEL, MAX_LEVEL)
	_apply_bus(BGM_BUS, bgm_level, bgm_muted, BGM_MIN_DB, BGM_MAX_DB)
	_save_and_emit()


func set_sfx_level(value: int) -> void:
	sfx_level = clampi(value, MIN_LEVEL, MAX_LEVEL)
	_apply_bus(SFX_BUS, sfx_level, sfx_muted, SFX_MIN_DB, SFX_MAX_DB)
	_save_and_emit()


func set_bgm_muted(value: bool) -> void:
	bgm_muted = value
	_apply_bus(BGM_BUS, bgm_level, bgm_muted, BGM_MIN_DB, BGM_MAX_DB)
	_save_and_emit()


func set_sfx_muted(value: bool) -> void:
	sfx_muted = value
	_apply_bus(SFX_BUS, sfx_level, sfx_muted, SFX_MIN_DB, SFX_MAX_DB)
	_save_and_emit()


func apply_settings() -> void:
	_apply_bus(BGM_BUS, bgm_level, bgm_muted, BGM_MIN_DB, BGM_MAX_DB)
	_apply_bus(SFX_BUS, sfx_level, sfx_muted, SFX_MIN_DB, SFX_MAX_DB)


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


func _apply_bus(
	bus_name: StringName,
	level: int,
	muted: bool,
	min_db: float,
	max_db: float
) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return

	var ratio := float(clampi(level, MIN_LEVEL, MAX_LEVEL) - MIN_LEVEL) / float(MAX_LEVEL - MIN_LEVEL)
	var db := lerpf(min_db, max_db, ratio)
	AudioServer.set_bus_volume_db(bus_index, db)
	AudioServer.set_bus_mute(bus_index, muted)


func _save_and_emit() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "bgm_level", bgm_level)
	config.set_value("audio", "sfx_level", sfx_level)
	config.set_value("audio", "bgm_muted", bgm_muted)
	config.set_value("audio", "sfx_muted", sfx_muted)
	config.save(CONFIG_PATH)
	settings_changed.emit()
