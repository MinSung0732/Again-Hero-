extends RefCounted
const SCENE := "res://src/hero_mode/HeroMode.tscn"
const DURATION := 900.0
const THINK_INTERVAL := 0.75
const OBSERVE_INTERVAL := 4.0
const MONSTER_LIMIT := 72
const STARTING_COMMAND := 48.0
const EXP_REWARD_RATIO := 0.25
const PROJECTILE_SPEED := 720.0
# Role/rarity stats stay canonical; survival applies a spawn-time envelope.
# Hold the opening 30 seconds, then interpolate without phase-boundary jumps.
const MONSTER_SCALE_FIELDS := {"max_hp":"hp","attack_damage":"damage","explosion_damage":"damage","move_speed":"speed"}
const MONSTER_GROWTH := [
	{"time":0.0,"hp":0.18,"damage":0.45,"speed":0.80},
	{"time":30.0,"hp":0.18,"damage":0.45,"speed":0.80},
	{"time":120.0,"hp":0.85,"damage":0.65,"speed":0.90},
	{"time":300.0,"hp":2.80,"damage":0.95,"speed":1.00},
	{"time":600.0,"hp":6.00,"damage":1.30,"speed":1.10},
	{"time":900.0,"hp":10.00,"damage":1.70,"speed":1.20},
]
static func monster_multiplier(stat: String, elapsed: float) -> float:
	if not MONSTER_GROWTH[0].has(stat) or stat == "time": return 1.0
	var clock := clampf(elapsed,0.0,DURATION) if is_finite(elapsed) else 0.0
	for index in range(1,MONSTER_GROWTH.size()):
		var next: Dictionary = MONSTER_GROWTH[index]
		if clock <= float(next.time):
			var previous: Dictionary = MONSTER_GROWTH[index-1]
			var ratio := (clock-float(previous.time))/(float(next.time)-float(previous.time))
			return lerpf(float(previous[stat]),float(next[stat]),ratio)
	return float(MONSTER_GROWTH[-1][stat])
static func required_exp(target_level: int) -> int:
	var rank := maxi(target_level-1,0)
	# About 22k / 48k collected EXP to reach Lv.30 / 40; no level cap.
	return roundi(60.0+18.0*rank+1.6*rank*rank)
const ROSTER := ["slime","spider","orc","bomb_rat","skeleton_archer","ghost","ogre"]
const COUNTERS := {"area":["orc","skeleton_archer"],"mobility":["spider","ghost"],"durability":["bomb_rat","ghost"],"damage":["slime","spider"]}
const PHASES := [
	{"start":0.0,"interval":0.9,"batch":2,"limit":36,"regen":20.0,"roster":3,"name":"탐색 공세"},
	{"start":120.0,"interval":0.8,"batch":3,"limit":48,"regen":30.0,"roster":5,"name":"협공 시작"},
	{"start":300.0,"interval":0.7,"batch":4,"limit":60,"regen":40.0,"roster":6,"name":"혼합 군단"},
	{"start":600.0,"interval":0.6,"batch":5,"limit":68,"regen":50.0,"roster":7,"name":"포위 공세"},
	{"start":780.0,"interval":0.5,"batch":6,"limit":72,"regen":60.0,"roster":7,"name":"최후의 공세"},
]
const ELITE_FIRST := 60.0
const ELITE_INTERVAL := 90.0
const GIANT_TIMES := [180.0,360.0,540.0,720.0,840.0]
static func phase_at(elapsed: float) -> Dictionary:
	var result: Dictionary = PHASES[0]
	for phase in PHASES:
		if elapsed >= float(phase.start): result = phase
	return result
const SKILL_SLOTS := 2
const WIN_RESEARCH := 100
const WIN_GOLD := 60
const PARTIAL_RESEARCH := 5
const PARTIAL_GOLD := 3
const GROWTH := {"vitality":{"name":"생명력","description":"용사 최대 HP +2% / 단계","max":10,"cost":200,"hp":0.02,"damage":0.0},"power":{"name":"전투 숙련","description":"용사 공격력 +1% / 단계","max":10,"cost":200,"hp":0.0,"damage":0.01}}
static func growth_cost(id: String,level: int) -> int:
	return int(GROWTH.get(id,{}).get("cost",0))*(level+1)

const STAGE_ROSTERS := [
	["slime","spider","orc","bomb_rat","skeleton_archer","ghost","ogre"],
	["slime","spider","goblin","bomb_rat","skeleton_archer","ghost","ogre"],
	["slime","goblin","orc","fanatic","skeleton_archer","ghost","ogre"],
	["slime","spider","orc","fanatic","skeleton_archer","gumiho","ogre"],
]
static func roster_for(stage_number: int) -> Array:
	return STAGE_ROSTERS[clampi(int((stage_number-1)/3),0,STAGE_ROSTERS.size()-1)]
static func stage_pressure(stage_number: int) -> float:
	return 1.0+0.055*(clampi(stage_number,1,10)-1)
