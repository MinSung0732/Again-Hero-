extends RefCounted
# Dedicated Pixabay excerpts; fixed players, capped peaks, source hashes in audio manifest.
const ROOT := "res://assets/audio/sfx/arthur/"
const CUES := {
	"swing":{"path":ROOT+"swing.wav","db":-22,"interval":0.6},
	"charge":{"path":ROOT+"charge.wav","db":-20,"interval":0.5},
	"dash":{"path":ROOT+"dash.wav","db":-15,"interval":0.4},
	"gate_charge":{"path":ROOT+"gate_charge.wav","db":-19,"interval":1},
	"gate":{"path":ROOT+"gate.wav","db":-16,"interval":1},
	"blessing":{"path":ROOT+"blessing.wav","db":-16,"interval":1},
	"block":{"path":ROOT+"block.wav","db":-23,"interval":0.25},
	"arrival":{"path":ROOT+"arrival.wav","db":-18,"interval":2},
	"reveal":{"path":ROOT+"reveal.wav","db":-13,"interval":2},
}
const PRESENTATION_CUES := {"charge":CUES.gate_charge,"reveal":CUES.reveal}
const SUMMON_TIMELINE := [{"at":0.5,"cue":"charge"},{"at":2.05,"cue":"reveal","stop":"charge"}]
