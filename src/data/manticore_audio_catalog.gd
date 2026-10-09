extends RefCounted
const ROOT := "res://assets/audio/sfx/manticore/"
# Edited PCM peaks at -6 dBFS. Natural pitch; gains precede user SFX settings.
# One voice per cue; meteor clusters and two flame heads share rate limits.
const CUES := {
	"focus":{"path":ROOT+"focus.wav","db":-23.0,"interval":0.9},
	"hunt":{"path":ROOT+"hunt.wav","db":-19.0,"interval":0.3},
	"hit":{"path":ROOT+"hit.wav","db":-13.0,"interval":0.0},
	"retreat":{"path":ROOT+"retreat.wav","db":-23.0,"interval":0.3},
	"flame_cast":{"path":ROOT+"flame_cast.wav","db":-20.0,"interval":1.0},
	"flame_breath":{"path":ROOT+"flame_breath.wav","db":-25.0,"interval":0.65},
	"venom_launch":{"path":ROOT+"venom_launch.wav","db":-28.0,"interval":0.18},
	"venom_impact":{"path":ROOT+"venom_impact.wav","db":-25.0,"interval":0.14},
	"wave":{"path":ROOT+"wave.wav","db":-17.0,"interval":0.4},
	"escape":{"path":ROOT+"escape.wav","db":-18.0,"interval":1.0},
	"summon":{"path":ROOT+"summon.wav","db":-19.0,"interval":1.0},
	"death":{"path":ROOT+"death.wav","db":-20.0,"interval":1.0},
}
const FLAME_BREATH_INTERVAL := 0.65
# Cutscene banks use real time independently of the slowed combat bank.
const PRESENTATION_CUES := {
	"focus":{"path":ROOT+"focus.wav","db":-21.0},
	"reveal":{"path":ROOT+"summon.wav","db":-11.0},
	"death":{"path":ROOT+"death.wav","db":-17.0},
}
const SUMMON_TIMELINE := [{"at":0.55,"cue":"focus"},{"at":1.95,"cue":"reveal","stop":"focus"}]
const DEATH_TIMELINE := [{"at":0.0,"cue":"death"}]
