extends RefCounted
const ROOT := "res://assets/audio/sfx/interface/"
const FRONTEND_BGM := "res://assets/audio/bgm/frontend_loop.ogg"
const FRONTEND_DB := {"title": -3.0, "lobby": -3.0, "result": -8.0}
# Keep dialogue gain relative to the lobby; the bus owns user volume/mute.
const DIALOGUE_BGM_LOBBY_OFFSET_DB := -5.0
const DIALOGUE_BGM := {
	"path": "res://assets/audio/bgm/talk_background.wav",
	"db": FRONTEND_DB["lobby"] + DIALOGUE_BGM_LOBBY_OFFSET_DB,
	"fade_out_seconds": 1.0,
}
const CONTEXT := preload("res://src/data/contextual_audio_catalog.gd")
static func ui_cues() -> Dictionary:
	var cues := CONTEXT.UI_CUES.duplicate(true)
	cues["click"] = {"path": CONTEXT.ROOT+"confirm.wav", "db": -20.0, "interval": 0.22}
	return cues
const BATTLE_CUES := {
	"summon": {"path": ROOT+"summon.wav", "db": -23.0, "interval": 0.22},
	"ultimate": {"path": ROOT+"ultimate.wav", "db": -12.0, "interval": 0.15},
	"elite_skill": {"path": ROOT+"ultimate.wav", "db": -24.0, "pitch": 0.8, "interval": 1.0},
	"chest": {"path": ROOT+"reward.wav", "db": -16.0, "interval": 0.2},
}
