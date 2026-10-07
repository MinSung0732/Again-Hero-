extends RefCounted
const ROOT := "res://assets/audio/sfx/zeus/"
# Asset peaks are -3 dBFS. These gains precede the user's SFX bus level.
const CUES := {
	"judgment": {"path": ROOT+"judgment.wav", "db": -14.0, "interval": 0.25},
	"charge": {"path": ROOT+"charge.wav", "db": -15.0},
	"thunder": {"path": ROOT+"thunder.wav", "db": -7.0},
	"crown": {"path": ROOT+"crown.wav", "db": -10.0},
	"slash": {"path": ROOT+"slash.wav", "db": -12.0},
	"slash_hit": {"path": ROOT+"judgment.wav", "db": -17.0},
	"orb": {"path": ROOT+"orb.wav", "db": -22.0, "interval": 0.12},
	"hit": {"path": ROOT+"judgment.wav", "db": -19.0, "pitch": 0.8, "interval": 0.2},
	"death": {"path": ROOT+"death.wav", "db": -9.0},
	"summon": {"path": ROOT+"thunder.wav", "db": -8.0},
	"summon_echo": {"path": ROOT+"thunder.wav", "db": -18.0, "pitch": 0.85},
}
const SUMMON_TIMELINE := [
	{"at": 0.0, "cue": "charge"}, {"at": 1.9, "cue": "summon", "stop": "charge"},
	{"at": 2.08, "cue": "summon_echo"}, {"at": 2.26, "cue": "summon_echo"},
]
const DEATH_TIMELINE := [{"at": 0.0, "cue": "death"}]
