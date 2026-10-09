extends RefCounted
const ROOT := "res://assets/audio/sfx/bulgasal/"
# Edited material sounds peak at -6 dBFS; gains precede the user's SFX bus.
# Major actions only. Fragment burst is one cue; pillar batches share a cooldown.
const CUES := {
	"rock":{"path":ROOT+"rock.wav","db":-10.0,"interval":0.4},
	"burrow":{"path":ROOT+"burrow.wav","db":-14.0,"interval":1.0},
	"emerge":{"path":ROOT+"emerge.wav","db":-14.0,"interval":0.4},
	"land":{"path":ROOT+"land.wav","db":-9.0,"interval":0.4},
	"pillar":{"path":ROOT+"pillar.wav","db":-19.0,"interval":0.25},
	"eat":{"path":ROOT+"eat.wav","db":-20.0,"interval":0.4},
}

# Presentation uses real time and separate fixed voices, not the slowed combat bank.
const PRESENTATION_CUES := {
	"rumble":{"path":ROOT+"burrow.wav","db":-18.0},
	"reveal":{"path":ROOT+"rock.wav","db":-12.0},
}
const SUMMON_TIMELINE := [{"at":0.25,"cue":"rumble"},{"at":1.8,"cue":"reveal","stop":"rumble"}]
