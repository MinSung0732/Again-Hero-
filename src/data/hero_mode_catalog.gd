extends RefCounted
const SCENE := "res://src/hero_mode/HeroMode.tscn"
const AUGMENT_REROLLS := 3
static func augment_reroll_limit(research_bonus: int = 0) -> int:
	return AUGMENT_REROLLS+maxi(0,research_bonus)
const DURATION := 900.0
const THINK_INTERVAL := 0.75
const OBSERVE_INTERVAL := 4.0
const MONSTER_LIMIT := 72
const STARTING_COMMAND := 48.0
const EXP_REWARD_RATIO := 0.25
const CHEST_KILLS := 200
const CHEST_ELITE_KILLS := 4
const CHEST_RUN_LIMIT := 3
const CHEST_INTERVAL := 180.0
const PROJECTILE_SPEED := 720.0
# Role/rarity stats stay canonical; survival applies a spawn-time envelope.
# HP/damage keep their opening budget; pursuit ramps after 12 seconds.
const MONSTER_SCALE_FIELDS := {"max_hp":"hp","attack_damage":"damage","explosion_damage":"damage","move_speed":"speed"}
const MONSTER_GROWTH := [
	{"time":0.0,"hp":0.18,"damage":0.45,"speed":0.80},
	{"time":12.0,"hp":0.18,"damage":0.45,"speed":0.80},
	{"time":30.0,"hp":0.18,"damage":0.45,"speed":1.00},
	{"time":40.0,"hp":0.254444444444,"damage":0.472222222222,"speed":1.08},
	{"time":120.0,"hp":0.85,"damage":0.65,"speed":1.20},
	{"time":300.0,"hp":2.80,"damage":0.95,"speed":1.40},
	{"time":600.0,"hp":6.00,"damage":1.30,"speed":1.60},
	{"time":900.0,"hp":10.00,"damage":1.70,"speed":1.75},
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
	{"start":40.0,"interval":0.85,"batch":2,"limit":40,"regen":24.0,"roster":5,"name":"원거리 협공"},
	{"start":120.0,"interval":0.8,"batch":3,"limit":48,"regen":30.0,"roster":5,"name":"협공 시작"},
	{"start":300.0,"interval":0.7,"batch":4,"limit":60,"regen":40.0,"roster":6,"name":"혼합 군단"},
	{"start":600.0,"interval":0.6,"batch":5,"limit":68,"regen":50.0,"roster":7,"name":"포위 공세"},
	{"start":780.0,"interval":0.5,"batch":6,"limit":72,"regen":60.0,"roster":7,"name":"최후의 공세"},
]
const ELITE_FIRST := 35.0
const OPENING_ELITE_DISTANCE := 450.0
const ELITE_INTERVAL := 90.0
const GIANT_TIMES := [180.0,360.0,540.0,720.0,840.0]
static func phase_at(elapsed: float) -> Dictionary:
	var result: Dictionary = PHASES[0]
	for phase in PHASES:
		if elapsed >= float(phase.start): result = phase
	return result
static func opening_objective(elapsed: float, chest_claimed: bool, next_event: float) -> String:
	if elapsed >= OPENING_END: return ""
	if elapsed < EVENT_FIRST: return "첫 포위\n%02d초" % ceili(EVENT_FIRST-elapsed)
	if elapsed < ELITE_FIRST: return "첫 정예\n%02d초" % ceili(ELITE_FIRST-elapsed)
	if not chest_claimed: return "정예 격파\n강화 상자"
	return "다음 공세\n%02d초" % maxi(0,ceili(next_event-elapsed))
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
static func roster_for(stage_number: int, difficulty: String = "easy") -> Array:
	var result: Array = []
	for id in STAGE_ROSTERS[clampi(int((stage_number-1)/3),0,STAGE_ROSTERS.size()-1)]:
		if monster_allowed(id,stage_number,difficulty): result.append(id)
	for tier in [1,2,3]:
		for id in TIER_ADDITIONS[tier]:
			if id not in result and monster_allowed(id,stage_number,difficulty): result.append(id)
	return result
static func stage_pressure(stage_number: int) -> float:
	return 1.0+0.055*(clampi(stage_number,1,10)-1)

const MONSTERS := preload("res://src/data/monster_catalog.gd")
const RARITY_ORDER := ["common","uncommon","rare","legendary","transcendent"]
const EASY_TIERS := [0,0,1,1,1,2,2,2,3,3]
const HARD_TIERS := [0,1,1,2,2,2,3,3,3,3]
const EVENT_FIRST := 24.0
const EVENT_INTERVAL := 105.0
const OPENING_EVENT_INTERVAL := 40.0
const OPENING_END := 120.0
const OPENING_EVENT_RADIUS := 320.0
const EVENT_WARNING := 1.8
const EVENT_KINDS := ["ring","line","square","barricade"]
const EVENT_NAMES := {"ring":"원형 포위","line":"직선 협공","square":"사각 포위","barricade":"바리케이드"}
const BARRIER_SECONDS := 15.0
const TIER_ADDITIONS := {1:["ogre","wolf"],2:["hobgoblin","gargoyle"],3:["gumiho","succubus"]}
const BOSS_CANDIDATES := ["orc","ogre","hobgoblin","gargoyle","gumiho"]
const BASE_HERO_STATS := {"max_hp":1200,"attack_damage":26,"move_speed":270.0,"attack_range":430.0,"attack_cooldown":0.62,"projectile_speed":720.0,"exp_pickup_radius":150.0}
static func rarity_limit(stage: int, difficulty: String) -> int:
	return int((HARD_TIERS if difficulty == "hard" else EASY_TIERS)[clampi(stage,1,10)-1])
static func monster_allowed(id: String, stage: int, difficulty: String) -> bool:
	var rank := RARITY_ORDER.find(MONSTERS.get_rarity(id))
	return MONSTERS.MONSTERS.has(id) and rank >= 0 and rank <= rarity_limit(stage,difficulty)
static func boss_for(stage: int, difficulty: String) -> String:
	var chosen := "orc"
	for id in BOSS_CANDIDATES:
		if monster_allowed(id,stage,difficulty) and bool(MONSTERS.get_monster(id).get("can_be_elite",true)): chosen = id
	return chosen
static func boss_data(stage: int, difficulty: String) -> Dictionary:
	var base := MONSTERS.get_base_stats(boss_for(stage,difficulty))
	var hard := difficulty == "hard"
	var hp := (10000.0+clampi(stage,1,10)*1800.0)*(1.35 if hard else 1.0)
	var damage := (28.0+clampi(stage,1,10)*4.0)*(1.2 if hard else 1.0)
	return {"type":"boss","name":"최종 수문장","hp_multiplier":hp/(maxf(1,float(base.get("max_hp",1)))*monster_multiplier("hp",DURATION)*(1.25 if hard else 1.0)),"damage_multiplier":damage/(maxf(1,float(base.get("attack_damage",1)))*monster_multiplier("damage",DURATION)*(1.15 if hard else 1.0)),"speed_multiplier":0.8,"visual_scale":2.2,"exp_multiplier":0.0,"target_hp":roundi(hp),"target_damage":roundi(damage)}
static func encounter_points(kind: String, center: Vector2, bounds: Vector2, radius: float = 430.0, gap_angle: float = 0.0) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var count := 12 if kind == "ring" else 16 if kind == "square" else 8
	for index in count:
		if index == 0 or index == 1: continue # Always leave an escape opening.
		var offset: Vector2
		if kind == "ring": offset = Vector2.from_angle(TAU*index/count)*radius
		elif kind == "square":
			var side := index/4; var along := -radius+(index%4)*radius*0.5
			offset = Vector2(along,-radius) if side == 0 else Vector2(radius,along) if side == 1 else Vector2(-along,radius) if side == 2 else Vector2(-radius,-along)
		else: offset = Vector2((index-3.5)*100.0,-380.0 if kind == "barricade" or index%2 == 0 else 380.0)
		offset = offset.rotated(gap_angle) if kind != "barricade" else offset
		var point := (center+offset).clamp(Vector2(70,70),bounds-Vector2(70,70))
		if point.distance_squared_to(center) >= 180.0*180.0 and point not in points: points.append(point)
	return points
static func boss_position(center: Vector2, bounds: Vector2) -> Vector2:
	var result := center
	for direction in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
		var candidate: Vector2 = (center+direction*600.0).clamp(Vector2(70,70),bounds-Vector2(70,70))
		if candidate.distance_squared_to(center) > result.distance_squared_to(center): result = candidate
	return result
