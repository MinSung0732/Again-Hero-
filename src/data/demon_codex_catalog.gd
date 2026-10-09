extends RefCounted
## Read-only projection; numerical values come from gameplay catalogs.
const SHOP := preload("res://src/data/shop_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const ULTIMATES := preload("res://src/data/demon_ultimate_catalog.gd")
const COSMETICS := preload("res://src/data/profile_cosmetic_catalog.gd")
const DETAILS := preload("res://src/data/transcendent_detail_catalog.gd")
const RULES := preload("res://src/data/transcendence_catalog.gd")
const CATEGORIES := [["skills","마왕 스킬"],["monsters","일반 몬스터"],["augments","마왕 증강"],["transcendent","초월 몬스터"]]
const CATEGORY_SHORT := {"skills":"스킬","monsters":"몬스터","augments":"증강","transcendent":"초월"}
const ART := {
	"zeus":{"illustration":"res://assets/art/effects/gatcha/zeus/portrait/idle_01.png"},
	"bulgasal":{"illustration":"res://assets/art/Transcendent_monster/Bulgasal/bulgasal_illustration.png"},
	"izanami":{"illustration":"res://assets/art/Transcendent_monster/Izanami/izanami_illustration.png"},
	"manticore":{"illustration":"res://assets/art/Transcendent_monster/manticore/manticore_illustration.png"},
}
const STAT_FIELDS := [["max_hp","체력"],["attack_damage","공격력"],["move_speed","이동속도"],["attack_range","공격 판정 거리"],["attack_cooldown","공격 간격"],["base_cost","소환 지휘력"]]
const AUGMENT_CATEGORIES := {"command":"지휘","growth":"성장","economy":"경제"}
static func monster_ids(transcendent: bool) -> Array[String]:
	var result: Array[String] = []
	for id in MONSTERS.ORDER:
		if (MONSTERS.get_rarity(id)=="transcendent")==transcendent: result.append(id)
	return result
static func stats(id: String) -> String:
	var data := MONSTERS.get_base_stats(id)
	var lines: Array[String] = []
	for pair in [["max_hp","체력"],["attack_damage","공격력"],["move_speed","이동속도"],["attack_range","공격 판정 거리"],["attack_cooldown","공격 간격"]]:
		if data.has(pair[0]): lines.append("%s %s%s"%[pair[1],str(data[pair[0]]),"초" if pair[0]=="attack_cooldown" else ""])
	lines.append("소환 지휘력 %s"%str(MONSTERS.get_base_cost(id)))
	return " · ".join(lines)
static func related_augment_groups(id: String) -> Dictionary:
	var data := MONSTERS.get_monster(id)
	var normal := AUGMENTS.get_monster_normal_augments(id,MONSTERS.get_monster_name(id))
	var special: Array = []
	for augment_id in data.get("special_augment_ids",[]):
		var entry := AUGMENTS.get_augment(augment_id)
		if not entry.is_empty(): special.append(entry)
	return {"normal":normal,"special":special}

static func related_augments(id: String) -> Array:
	var groups := related_augment_groups(id)
	return groups.normal + groups.special

static func artwork(id: String, kind: String) -> String:
	if kind=="illustration": return String(ART.get(id,{}).get(kind,""))
	var reward_id := id+"_plus_banner" if kind=="plus_banner" else id
	return COSMETICS.path(reward_id,"banner")
static func ultimate_stats(id: String) -> String:
	var skill := ULTIMATES.get_skill(id)
	var result := "소환 %d기 · 게이지 %s · 재사용 %s초"%[skill.spawn_count,str(skill.mana_cost),str(skill.cooldown)]
	for pair in [["spawn_radius","반경"],["spawn_distance","거리"],["line_span","라인 폭"],["half_extent","중심→변 거리"]]:
		if skill.has(pair[0]): result += " · %s %s"%[pair[1],str(skill[pair[0]])]
	return result

static func rarity_label(id: String) -> String:
	return SHOP.get_rarity_label(MONSTERS.get_rarity(id))

static func elite_portrait(id: String) -> String:
	var visual := MONSTERS.get_elite_visual_profile(id)
	var idle: Dictionary = visual.get("animations", {}).get("idle", {})
	if visual.get("mode", "") != "frames" or idle.is_empty(): return ""
	return "%s/%s_01.png" % [visual.get("asset_dir", ""), idle.get("prefix", "idle")]

static func stat_values(id: String) -> Array[String]:
	var result: Array[String] = []
	var stats := MONSTERS.get_base_stats(id)
	for field in STAT_FIELDS:
		var key: String = field[0]
		var value = MONSTERS.get_base_cost(id) if key == "base_cost" else stats.get(key,null)
		result.append("—" if value == null else (str(value).trim_suffix(".0") + ("초" if key == "attack_cooldown" else "")))
	return result
