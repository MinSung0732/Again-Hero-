extends RefCounted
# Dedicated Pixabay excerpts; fixed players, capped peaks, source hashes in audio manifest.
const ROOT := "res://assets/audio/sfx/izanami/"
const CUES := {
	"attack":{"path":ROOT+"attack.wav","db":-24,"interval":0.8},
	"haunt":{"path":ROOT+"haunt.wav","db":-19,"interval":1},
	"bind":{"path":ROOT+"bind.wav","db":-17,"interval":0.5},
	"fire":{"path":ROOT+"fire.wav","db":-19,"interval":0.6},
	"spirits":{"path":ROOT+"spirits.wav","db":-20,"interval":1},
	"torii":{"path":ROOT+"torii.wav","db":-20,"interval":1},
}
