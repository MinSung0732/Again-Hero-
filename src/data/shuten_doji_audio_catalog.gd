extends RefCounted
# Dedicated Pixabay edits; provenance and exact layer cuts in shuten_doji/manifest.json.
const ROOT := "res://assets/audio/sfx/shuten_doji/"
const CUES := {
"mist":{"path":ROOT+"mist.wav","db":-18.0,"interval":2.0},
"ignite":{"path":ROOT+"ignite.wav","db":-13.0,"interval":0.8},
"chain":{"path":ROOT+"chain.wav","db":-18.0,"interval":1.0},
"bind":{"path":ROOT+"bind.wav","db":-15.0,"interval":0.4},
"swing":{"path":ROOT+"swing.wav","db":-20.0,"interval":0.6},
"hit":{"path":ROOT+"hit.wav","db":-15.0,"interval":0.5},
"swing_released":{"path":ROOT+"swing_released.wav","db":-20.0,"interval":0.6},
"hit_released":{"path":ROOT+"hit_released.wav","db":-15.0,"interval":0.5},
"release":{"path":ROOT+"release.wav","db":-15.0,"interval":3.0}}
const PRESENTATION_CUES := {
"mist":{"path":ROOT+"presentation_mist.wav","db":-18.0},
"reveal":{"path":ROOT+"reveal.wav","db":-13.0},
"death":{"path":ROOT+"death.wav","db":-17.0}}
const SUMMON_TIMELINE := [{"at":0.45,"cue":"mist"},{"at":1.95,"cue":"reveal","stop":"mist"}]
const DEATH_TIMELINE := [{"at":0.0,"cue":"death"}]
