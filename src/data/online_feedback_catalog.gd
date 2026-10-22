extends RefCounted
const GAME := preload("res://src/data/game_audio_catalog.gd")
const CONTEXT := preload("res://src/data/contextual_audio_catalog.gd")
const CAPACITY := 32
const HERO_RESERVED := 8
const MAX_PRIMITIVES := 24
const MAX_POINTS := 70
const EVENT_SIZE := 10
const MAX_AGE_SECONDS := 0.6
const LIFETIME := 0.55
const FONT_SIZE := 25
const RISE_SPEED := 38.0
const CAST_BY_ARCHETYPE := {"ranged_kiter":"cast"}
const CUES := {
	"hero_hit":{"path":CONTEXT.ROOT+CONTEXT.HITS.ranged_kiter.file,"db":CONTEXT.HIT_DB,"interval":CONTEXT.HIT_INTERVAL_MS/1000.0},
	"cast":{"path":"res://assets/audio/sfx/stage1_mage_v4_basic.wav","db":-23.0,"interval":0.18},
	"summon":GAME.BATTLE_CUES.summon,
	"transcend":GAME.BATTLE_CUES.summon,
	"victory":CONTEXT.UI_CUES.victory,
	"defeat":CONTEXT.UI_CUES.defeat,
}
const KINDS := ["hero_hit","monster_hit","heal","cast","summon","transcend"]
const EMPTY := []
static func valid_cursor(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and value <= 2147483647 and value == floorf(value)
static func valid_events(events: Variant,cursor: Variant,tick: Variant) -> bool:
	if not events is Array or events.size()>CAPACITY or not valid_cursor(cursor) or not valid_cursor(tick): return false
	var previous := 0
	for row in events:
		if not row is Array or row.size()!=EVENT_SIZE: return false
		if not valid_cursor(row[0]) or row[0]<=previous or row[0]>cursor or not valid_cursor(row[1]) or row[1]>tick or row[2] not in KINDS: return false
		previous = int(row[0])
		for index in [3,4,5,6,7,8,9]:
			if not (row[index] is int or row[index] is float) or not is_finite(float(row[index])) or absf(float(row[index]))>1000000: return false
		if row[5]<0 or row[5]!=floorf(row[5]): return false
		for index in [6,7,8,9]:
			if row[index]<0 or row[index]>1: return false
	return true
