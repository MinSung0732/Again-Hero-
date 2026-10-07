extends RefCounted
const ROOT := "res://assets/audio/sfx/interface/"
const FRONTEND_BGM := "res://assets/audio/bgm/frontend_loop.ogg"
const FRONTEND_DB := {"title": -3.0, "lobby": -3.0, "result": -8.0}
const UI_CUES := {
	"click": {"path": ROOT+"click.wav", "db": -12.0, "interval": 0.07},
	"success": {"path": ROOT+"success.wav", "db": -13.0, "interval": 0.2},
	"upgrade": {"path": ROOT+"success.wav", "db": -10.0, "interval": 0.2},
	"denied": {"path": ROOT+"denied.wav", "db": -19.0, "interval": 0.4},
	"victory": {"path": ROOT+"victory.wav", "db": -10.0},
	"defeat": {"path": ROOT+"defeat.wav", "db": -13.0},
}
const BATTLE_CUES := {
	"summon": {"path": ROOT+"summon.wav", "db": -23.0, "interval": 0.22},
	"ultimate": {"path": ROOT+"ultimate.wav", "db": -12.0, "interval": 0.15},
	"elite_skill": {"path": ROOT+"ultimate.wav", "db": -24.0, "pitch": 0.8, "interval": 1.0},
	"chest": {"path": ROOT+"reward.wav", "db": -16.0, "interval": 0.2},
}
