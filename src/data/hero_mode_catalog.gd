extends RefCounted
const SCENE := "res://src/hero_mode/HeroMode.tscn"
const DURATION := 180.0
const THINK_INTERVAL := 0.75
const OBSERVE_INTERVAL := 4.0
const MONSTER_LIMIT := 28
const STARTING_COMMAND := 24.0
const ROSTER := ["slime","spider","orc","bomb_rat","skeleton_archer","ghost"]
const COUNTERS := {"area":["orc","skeleton_archer"],"mobility":["spider","ghost"],"durability":["bomb_rat","ghost"],"damage":["slime","spider"]}
const SKILL_SLOTS := 2
const WIN_RESEARCH := 20
const WIN_GOLD := 12
const PARTIAL_RESEARCH := 5
const PARTIAL_GOLD := 3
const GROWTH := {"vitality":{"name":"생명력","description":"용사 최대 HP +2% / 단계","max":10,"cost":200,"hp":0.02,"damage":0.0},"power":{"name":"전투 숙련","description":"용사 공격력 +1% / 단계","max":10,"cost":200,"hp":0.0,"damage":0.01}}
static func growth_cost(id: String,level: int) -> int:
	return int(GROWTH.get(id,{}).get("cost",0))*(level+1)
