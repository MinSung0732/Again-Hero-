extends RefCounted
# Existing licensed, edited project SFX. Original source/license records stay with
# manticore, bulgasal and izanami assets; no new download or pitch alteration.
const CUES := {
"mist":{"path":"res://assets/audio/sfx/izanami/prayer_charge.wav","db":-23.0,"interval":2.0},
"ignite":{"path":"res://assets/audio/sfx/manticore/venom_impact.wav","db":-18.0,"interval":0.8},
"chain":{"path":"res://assets/audio/sfx/izanami/spirit_release.wav","db":-23.0,"interval":1.0},
"bind":{"path":"res://assets/audio/sfx/bulgasal/eat.wav","db":-22.0,"interval":0.4},
"swing":{"path":"res://assets/audio/sfx/manticore/hunt.wav","db":-23.0,"interval":0.6},
"hit":{"path":"res://assets/audio/sfx/bulgasal/land.wav","db":-17.0,"interval":0.5},
"release":{"path":"res://assets/audio/sfx/bulgasal/emerge.wav","db":-15.0,"interval":3.0}}
const PRESENTATION_CUES := {
"mist":{"path":"res://assets/audio/sfx/izanami/prayer_charge.wav","db":-22.0},
"reveal":{"path":"res://assets/audio/sfx/bulgasal/emerge.wav","db":-13.0}}
const SUMMON_TIMELINE := [{"at":0.45,"cue":"mist"},{"at":1.95,"cue":"reveal","stop":"mist"}]
