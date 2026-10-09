extends RefCounted
# Read-only projection of authoritative stage/profile/augment data.
const STAGES := preload("res://src/data/stage_catalog.gd")
const HEROES := preload("res://src/data/hero_profiles.gd")
const AI := preload("res://src/data/hero_ai_profiles.gd")
const AUGMENTS := preload("res://src/data/hero_augment_catalog.gd")
const SKILLS := preload("res://src/data/hero_skill_descriptions.gd")
const GUIDES := {
	"ranged_kiter": ["거리를 벌리며 마법탄을 쏩니다. 포위되면 장벽과 비전 집중으로 버팁니다.","가까이 접근하는 몬스터와 둔화를 함께 활용하세요. 한 방향에만 몰리면 관통포에 함께 맞기 쉽습니다.","물량을 보여 광역 투자를 유도한 뒤, 내구가 높은 몬스터로 바꾸는 전략을 시험해 보세요."],
	"rogue_combo": ["연속 찌르기와 약진으로 근접전을 이어갑니다. 급습은 약한 대상을 빠르게 마무리합니다.","약한 몬스터를 따로 보내면 처형과 흡혈의 먹잇감이 되기 쉽습니다. 탱커와 제어형을 함께 압박하세요.","난도질이 끝난 뒤 보호막과 공격의 빈틈을 관찰하세요."],
	"sword_shield": ["피해를 막으며 힘을 모았다가 반격합니다. 무리가 모이면 돌격을 이어갑니다.","막기 중 무작정 화력을 쏟으면 반격을 키울 수 있습니다. 방어가 끝나는 시점을 보고 공세를 바꾸세요.","아군을 흩어 돌격과 반격에 여러 마리가 함께 맞는 상황을 줄여 보세요."],
	"pistol_gunner": ["탄창과 장전을 관리하며 회피와 연속 사격을 사용합니다.","장전 중에도 보호막이나 회피가 있으므로 바로 빈틈이라고 단정하지 마세요. 탄창 소모와 회피 직후를 함께 관찰하세요.","직선으로 모이면 사격에 유리한 표적이 됩니다. 서로 다른 방향에서 접근해 보세요."],
	"archmage_elementalist": ["여러 원소의 기본 공격과 기술을 번갈아 사용합니다. 조화로 기술을 다시 준비합니다.","연소와 신성 폭발에 무리가 함께 맞지 않도록 압박 방향을 나누세요. 얼음기둥이 생성되면 이동 경로도 확인하세요.","원소와 증강의 누적 투자를 관찰하고, 물량과 내구 중심 공세를 바꾸며 대응을 유도하세요."],
	"berserker_madness": ["체력을 소모해 기술을 쓰며, 체력이 낮을수록 공격이 강해집니다. 한 번 부활합니다.","빈사 상태라고 안심하지 마세요. 혈흔과 혈구 회복을 허용하는지 확인하고 치유 감소와 제어를 함께 활용하세요.","첫 사망 이후에도 공세를 유지할 자원을 남겨 두세요."],
	"alchemist_chemical": ["화학가스를 소비하고 재료를 모아 회복합니다. 독과 혼합장으로 이동 경로를 제한합니다.","독 위에 오래 머무는 공세는 손해가 커집니다. 재료 수집과 가스 회복을 관찰하며 접근 방향을 바꾸세요.","현자의 돌을 완성하면 전투 방식이 달라집니다. 변신 전후를 따로 분석하세요."],
	"summoner_gatekeeper": ["상황에 맞는 이계 소환체를 선택해 전장을 구축합니다. 소환 슬롯이 차면 방벽을 얻습니다.","소환체 종류와 위치를 먼저 확인하세요. 용사만 쫓으면 문지기와 감시자의 화력을 오래 허용할 수 있습니다.","소환 횟수가 쌓이면 개방 기술이 해금됩니다. 장기전에서 무엇이 추가되는지 확인하세요."],
	"cleric_purifier": ["신성보호와 왕관으로 생존하며, 구체 연결과 정화로 전장을 정리합니다.","연결된 구체 주변에 아군이 몰리지 않도록 살펴보세요. 언데드는 신성 기술의 추가 피해를 받을 수 있습니다.","왕관 중첩과 정화 사용 횟수가 쌓이면 장기전이 불리해질 수 있습니다. 궁그닐 해금도 관찰하세요."],
	"grand_sage_astra": ["마력응축으로 영구 성장하고, 완성 횟수가 쌓이면 소멸과 흑점폭발을 해금합니다.","얼음기둥과 소멸점에 무리가 묶이지 않도록 공세를 나누세요. 응축 완성 전후의 기술 구성이 달라집니다.","체력이 낮은 아군은 소멸점에 처형될 수 있습니다. 후반에는 회복만으로 버티기 어려운 구간을 구분하세요."],
}
# label / unit. Multipliers remain multipliers; ratios are percentages.
const SYSTEM_TITLES := {"rogue_combo":"연속 찌르기", "fighter_basic":"베기 · 찌르기", "gunner":"탄창 · 회피 · 탄피배출 · 데드아이", "berserker":"광기 · 부활", "alchemist":"화학가스 · 재료", "summoner":"소환 슬롯", "sage":"마력 게이지 · 위상 이동", "purifier_gauge":"신성 게이지", "archmage_skills":"원소 게이지", "archmage_elements":"원소 기본 공격"}
const SYSTEM_DESCRIPTIONS := {
	"gunner":"탄창이 비면 장전하며 보호막을 얻습니다.\n가까이 포위되면 회피와 탄피배출로 거리를 벌리고, 적이 일직선에 모이면 데드아이로 잔탄을 빠르게 발사합니다.",
	"rogue_combo":"연속 찌르기로 전진하고 적을 밀어냅니다. 마지막 공격 뒤에는 회복 시간이 있어 공격 사이의 빈틈을 관찰할 수 있습니다.",
	"fighter_basic":"적의 배치에 따라 넓게 베거나 앞으로 찌릅니다. 여러 마리가 가까이 모일수록 함께 맞기 쉽습니다.",
	"berserker":"잃은 체력에 비례해 공격력이 강해집니다. 처치로 게이지를 모아 광기를 사용하고, 사망해도 한 번 부활합니다.",
	"alchemist":"기본 공격으로 약병을 던져 독을 남깁니다. 재료를 주워 가스를 회복하며, 가스가 부족하면 재료가 더 빠르게 생성됩니다.",
	"summoner":"주변 상황에 맞춰 소환체를 고릅니다. 소환체마다 역할과 수명이 다르며 동시에 유지할 수 있는 슬롯이 제한됩니다.",
	"sage":"매 세 번째 기본 공격은 관통 공격입니다. 주기적으로 위상 이동하며 빨라지고, 종료 후 잠시 보호막을 얻습니다.",
	"archmage_elements":"기본 공격마다 원소가 달라집니다. 대지는 주변 피해, 화염은 화상, 얼음은 빙결, 빛은 연쇄, 바람은 밀어내기, 신성은 회복과 언데드 추가 피해를 가집니다.",
}
const FIELDS := {
	"cooldown":["재사용 대기시간","s"], "initial_cooldown":["첫 사용 대기시간","s"],
	"duration":["지속시간","s"], "cast_time":["시전 준비","s"], "cast_seconds":["시전 준비","s"],
	"charge_duration":["정신집중","s"], "tick_interval":["반복 피해 간격","s"], "damage_interval":["피해 간격","s"],
	"damage":["피해",""], "tick_damage":["반복 피해",""], "damage_ratio":["공격력 대비 피해","%"],
	"base_damage_ratio":["기본 피해 비율","%"], "impact_damage_ratio":["충돌 피해 비율","%"],
	"radius":["효과 반경",""], "aoe_radius":["주변 피해 반경",""], "effect_radius":["효과 반경",""],
	"effect_diameter":["효과 지름",""], "explosion_diameter":["폭발 지름",""], "explosion_radius":["폭발 반경",""],
	"impact_radius":["충돌 피해 반경",""], "hit_radius":["적중 반경",""], "target_radius":["대상 탐색 반경",""],
	"projectile_speed":["투사체 속도",""], "projectile_range":["투사체 거리",""], "throw_range":["투척 거리",""],
	"shield_hp_ratio":["최대 체력 대비 보호막","%"], "hp_trigger_ratio":["체력 조건","%"],
	"damage_reduction":["받는 피해 감소","%"], "slow_multiplier":["둔화 중 이동속도 배율","x"],
	"slow_duration":["둔화 시간","s"], "root_duration":["속박 시간","s"], "execute_hp_ratio":["처형 체력선","%"],
	"execution_hp_ratio":["처형 체력선","%"], "hp_cost_ratio":["현재 체력 소모","%"],
	"gauge_cost":["게이지 소모",""], "gas_cost":["화학가스 소모",""],
	"charge_max":["충전 최대치",""], "charge_per_second":["초당 충전",""], "charge_on_attack":["공격 시 충전",""],
	"charge_per_damage":["피해당 충전",""], "charge_seconds":["충전 시간","s"],
	"enemy_count_trigger":["주변 적 조건","마리"], "trigger_enemy_count":["주변 적 조건","마리"],
	"danger_count":["위험 지역 적 조건","마리"], "danger_radius":["위험 판단 반경",""],
	"force_enemy_count":["집중 사용 적 조건","마리"], "activation_enemy_count":["발동 적 조건","마리"],
	"activation_enemy_radius":["발동 탐색 반경",""], "trigger_radius":["발동 반경",""],
	"max_target_distance":["대상 최대 거리",""], "max_chains":["최대 연계 횟수","회"],
	"hit_count":["타격 횟수","회"], "hit_interval":["연속 타격 간격","s"], "wave_count":["파동 수","개"],
	"orb_count":["구체 수","개"], "pillar_count":["기둥 수","개"], "spike_count":["가시 수","개"],
	"burst_count":["폭발 수","회"], "max_bounces":["최대 도탄","회"], "gauge_refund":["게이지 반환",""],
	"knockback_distance":["밀어내는 거리",""], "dash_distance":["돌진 거리",""], "dash_speed":["돌진 속도",""],
	"dash_duration":["돌진 시간","s"], "dash_damage_ratio":["돌진 피해 비율","%"],
	"move_speed_multiplier":["이동속도 배율","x"], "max_stacks":["최대 중첩","회"],
	"max_hp":["소환체 체력",""], "attack_range":["소환체 사거리",""], "attack_cooldown":["소환체 공격 간격","s"],
	"move_speed":["소환체 이동속도",""], "sense_range":["소환체 탐색 거리",""], "max_active":["최대 동시 유지","개"],
	"open_duration":["문 유지시간","s"], "drone_spawn_interval":["소환 간격","s"],
	"required_count":["해금에 필요한 소환 횟수","회"], "required_materials":["필요 재료","개"],
	"required_cleansing_stacks":["필요 정화 중첩","회"], "unlock_completion_count":["응축 완성 해금조건","회"],
	"flight_distance":["비행 거리",""], "capture_diameter":["끌어당기는 지름",""],
	"link_distance":["구체 연결 거리",""], "chain_damage_growth":["연쇄당 피해 증가","%"],
	"undead_damage_multiplier":["언데드 피해 배율","x"], "elite_damage_multiplier":["엘리트 피해 배율","x"],
	"heal_per_orb":["구슬당 회복",""], "heal_per_touch_tick":["혈흔 접촉 회복",""], "heal_interval":["회복 간격","s"],
	"heal_per_stack":["중첩당 회복",""], "cooldown_reduction_per_stack":["중첩당 재사용 감소","%"],
	"shield_hp_ratio_per_tick":["최대 체력 대비 반복 보호막","%"], "shield_tick_interval":["보호막 획득 간격","s"],
	"holy_damage_multiplier":["신성 피해 배율","x"], "holy_damage_per_stack":["중첩당 신성 피해 증가","%"],
	"move_speed_per_stack":["중첩당 이동속도 증가","%"], "casts_per_extra_target":["대상 증가에 필요한 시전","회"],
	"max_targets":["최대 대상 수","명"], "damage_ratio_min":["최소 피해 비율","%"], "damage_ratio_max":["최대 피해 비율","%"],
	"arrival_delay":["도착 후 폭발 대기","s"], "permanent_attack_ratio":["완성 시 영구 공격력 증가","%"],
	"permanent_hp_ratio":["완성 시 영구 체력 증가","%"], "skill_damage_buff_ratio":["기술 피해 강화","%"],
	"skill_damage_buff_duration":["기술 강화 시간","s"], "skill_damage_bonus_ratio":["기술 피해 증가","%"],
	"trigger_chance":["발동 확률","%"], "kill_heal_current_hp_ratio":["처치 시 현재 체력 회복","%"],
	"spawn_interval":["생성 간격","s"], "meteors_per_volley":["회당 유성 수","개"],
	"spawn_diameter":["생성 지름",""], "impact_diameter":["타격 지름",""], "max_lifetime":["최대 생존시간","s"],
	"hp_multiplier":["체력 배율","x"], "attack_multiplier":["공격력 배율","x"],
	"poison_damage_multiplier":["독 피해 배율","x"], "skill_cooldown_multiplier":["재사용 대기시간 배율","x"],
	"gas_regen_amount":["가스 회복량",""], "gas_regen_interval":["가스 회복 간격","s"],
	"magazine_size":["탄창","발"], "reload_seconds":["장전 시간","s"], "headshot_chance":["헤드샷 확률","%"],
	"headshot_multiplier":["헤드샷 피해 배율","x"], "empty_mag_shield_ratio":["탄창 소진 보호막","%"],
	"backstep_cooldown":["회피 재사용","s"], "backstep_invulnerability":["회피 무적시간","s"],
	"cylinder_cooldown":["탄피배출 재사용","s"], "cylinder_radius":["탄피배출 반경",""],
	"deadeye_cooldown":["데드아이 재사용","s"], "deadeye_shot_interval":["데드아이 사격 간격","s"],
	"missing_hp_attack_bonus_per_percent":["잃은 체력 1%당 공격 증가","%"],
	"revive_delay":["부활 대기","s"], "revive_hp_ratio":["부활 체력","%"],
	"gauge_max":["게이지 최대치",""], "gauge_regen_base":["초당 게이지 회복",""],
	"gauge_per_second":["초당 게이지 회복",""], "gauge_per_kill":["처치 시 게이지",""],
	"basic_gas_cost":["기본 공격 가스 소모",""], "basic_vial_count":["기본 공격 약병 수","개"],
	"gas_per_material":["재료당 가스 회복",""], "material_spawn_interval":["재료 생성 간격","s"],
	"base_slot_count":["기본 소환 슬롯","개"], "cast_interval":["소환 판단 간격","s"],
	"third_attack_interval":["관통 공격 주기","회"], "piercing_damage_ratio":["관통 공격 피해 비율","%"],
	"piercing_range":["관통 거리",""], "phase_interval":["위상 이동 주기","s"],
	"phase_duration":["위상 이동 시간","s"],
	"basic_reach":["기본 공격 도달 거리",""], "piercing_diameter":["관통 지름",""],
	"madness_drain_per_second":["광기 중 초당 게이지 소모",""], "madness_attack_speed_multiplier":["광기 공격속도 배율","x"],
	"gauge_regen_per_5_levels":["5레벨당 초당 게이지 회복 증가",""], "gauge_per_basic_attack":["기본 공격당 게이지",""],
	"charge_per_kill":["처치당 충전",""], "basic_range":["기본 공격 사거리",""],
	"fire_burn_duration":["화염 화상 지속","s"], "fire_burn_tick_damage_ratio":["화염 반복 피해 비율","%"],
	"ice_freeze_chance":["얼음 빙결 확률","%"], "ice_freeze_duration":["빙결 시간","s"],
	"light_chain_range":["빛 연쇄 거리",""], "light_chain_damage_ratio":["빛 연쇄 피해 비율","%"],
	"wind_knockback_distance":["바람 밀어내는 거리",""], "holy_heal_chance":["신성 회복 확률","%"],
	"holy_heal_amount":["신성 회복량",""], "holy_undead_damage_multiplier":["신성 언데드 피해 배율","x"],
	"earth_direct_damage_multiplier":["대지 직격 피해 배율","x"], "earth_splash_radius":["대지 주변 피해 반경",""],
	"earth_splash_damage_ratio":["대지 주변 피해 비율","%"], "backstep_distance":["회피 거리",""],
	"backstep_base_chance":["기본 회피 확률","%"], "surrounded_enemy_count":["포위 판단 적 수","마리"],
	"surrounded_radius":["포위 판단 반경",""], "cylinder_slow_multiplier":["탄피배출 둔화 속도 배율","x"],
	"cylinder_slow_duration":["탄피배출 둔화 시간","s"], "deadeye_move_speed_multiplier":["데드아이 이동속도 배율","x"],
	"deadeye_min_ammo":["데드아이 최소 잔탄","발"], "poison_radius":["독 반경",""],
	"poison_duration":["독 지속시간","s"], "poison_tick_damage_ratio":["독 반복 피해 비율","%"],
	"poison_tick_interval":["독 피해 간격","s"], "hits_per_attack":["공격당 타격","회"],
	"stored_damage_release_ratio":["축적 피해 반격 비율","%"], "release_radius":["반격 반경",""],
	"blood_duration":["혈흔 지속시간","s"], "permanent_move_speed_ratio":["완성 시 영구 이동속도 증가","%"],
	"permanent_attack_speed_ratio":["완성 시 영구 공격속도 증가","%"],
	"post_phase_shield_ratio":["위상 이동 후 최대 체력 대비 보호막","%"], "post_phase_shield_duration":["위상 보호막 시간","s"], "phase_move_speed_multiplier":["위상 이동속도 배율","x"],
}

static func _number(value: float) -> String:
	return String.num(value,2).trim_suffix("0").trim_suffix("0").trim_suffix(".") if not is_equal_approx(value,round(value)) else str(int(round(value)))

static func parameters(config: Dictionary) -> String:
	var lines := PackedStringArray()
	for key in FIELDS:
		if not config.has(key) or typeof(config[key]) not in [TYPE_FLOAT,TYPE_INT]: continue
		var field: Array = FIELDS[key]
		var value := float(config[key])
		var unit := String(field[1])
		var formatted := _number(value*100.0) if unit == "%" else _number(value)
		lines.append("%s  %s%s" % [field[0],"×" if unit == "x" else "",formatted+("초" if unit == "s" else "" if unit == "x" else unit)])
	return "\n".join(lines)

static func collect_skills(config: Dictionary, result: Array) -> void:
	for value in config.values():
		if typeof(value) != TYPE_DICTIONARY: continue
		var child: Dictionary = value
		if child.has("name") and child.has("id"):
			result.append(child)
		collect_skills(child,result)

static func overview(stage: Dictionary, profile: Dictionary) -> String:
	var balance: Dictionary = stage.get("hero_balance",{})
	var hp := maxi(1,roundi(float(profile.get("max_hp",0))*maxf(float(balance.get("hp_multiplier",1)),0.01)))
	var damage := maxi(1,roundi(float(profile.get("attack_damage",0))*maxf(float(balance.get("damage_multiplier",1)),0.01)))
	var speed := maxf(1,float(profile.get("move_speed",0))*maxf(float(balance.get("move_speed_multiplier",1)),0.01))
	var interval := maxf(0.1,float(profile.get("attack_cooldown",0))*maxf(float(balance.get("attack_cooldown_multiplier",1)),0.01))
	var growth: Dictionary = profile.get("level_growth",{})
	return "[color=#f0cb68]입장 기본 능력 · Lv.%d[/color]\n체력  %d\n공격력  %d\n공격 간격  %s초\n이동속도  %s\n사거리  %s (반경 기준)\n\n스테이지 보정이 적용된 시작 수치입니다. 전투 중 레벨·증강·기술로 달라집니다.\n\n[color=#f0cb68]성장[/color]\n레벨업마다 시작 공격력의 %s%%를 누적합니다.\n%d레벨마다 시작 공격력의 %s%%가 추가됩니다.\n\n[color=#f0cb68]전장[/color]\n전투 제한시간  %s초\n지도  %d × %d\n\n기술의 반경과 지름은 구분해서 표시합니다. 피해 비율은 별도 표기가 없으면 용사 공격력 기준입니다." % [int(stage.get("hero_level_start",1)),hp,damage,_number(interval),_number(speed),_number(float(profile.get("attack_range",0))),_number(float(growth.get("base_attack_growth_ratio",0))*100),int(growth.get("attack_milestone_interval",10)),_number(float(growth.get("attack_milestone_bonus",0))*100),_number(float(stage.get("run_duration_seconds",0))),int(stage.get("map_width",0)),int(stage.get("map_height",0))]

static func skill_text(profile: Dictionary) -> String:
	var result := PackedStringArray()
	var archetype := String(profile.get("archetype",""))
	var guide: Array = GUIDES.get(archetype,["전투 특성 정보를 준비 중입니다."])
	result.append("[color=#f0cb68]기본 공격 · 전투 특성[/color]\n"+String(guide[0]))
	# Named skills are discovered recursively, not replayed as animation frames.
	var skills: Array = []
	collect_skills(profile,skills)
	for skill in skills:
		result.append("[color=#f0cb68]%s%s[/color]\n%s\n\n%s" % [skill.name," · 패시브" if skill.get("passive",false) else "",SKILLS.describe(skill).replace(". ",".\n"),parameters(skill)])
		if skill.has("unlock_condition"):
			result.append(parameters(skill.unlock_condition))
		if skill.has("drone"):
			result.append("문에서 나온 소환체\n"+parameters(skill.drone))
	# Non-named combat systems: gauges, ammo, revival and automatic passives.
	for key in SYSTEM_TITLES:
		if not profile.has(key): continue
		var summary := parameters(profile[key])
		if not summary.is_empty(): result.append("[color=#f0cb68]%s[/color]\n%s\n\n%s" % [SYSTEM_TITLES[key],SYSTEM_DESCRIPTIONS.get(key,""),summary])
	return "\n\n".join(result)

static func augment_text(profile: Dictionary) -> String:
	var lines := PackedStringArray(["[color=#f0cb68]선택 가능한 증강[/color]\n아래 목록은 후보가 될 수 있는 증강입니다. 매번 모두 등장하거나 같은 순서로 선택하지 않습니다.\n중첩 제한·조건·현재 빌드에 따라 실제 후보가 달라집니다."])
	for id in profile.get("augment_pool_ids",[]):
		var entry := AUGMENTS.get_augment(String(id))
		if entry.is_empty(): continue
		var tags := PackedStringArray()
		for tag in entry.get("tags",[]): tags.append(AUGMENTS.get_tag_label(String(tag)))
		lines.append("[color=#f0cb68]%s[/color] · 최대 %d중첩\n%s\n%s" % [entry.get("name",""),AUGMENTS.get_effective_max_stack(String(id),String(profile.get("archetype","")))," · ".join(tags),entry.get("description","")])
	return "\n\n".join(lines)

static func strategy_text(stage: Dictionary, profile: Dictionary) -> String:
	var ai := AI.get_profile(String(stage.get("hero_ai_profile_id","")))
	var guide: Array = GUIDES.get(String(profile.get("archetype","")),["","현재 행동을 관찰해 공세를 바꿔 보세요.",""])
	var lines := PackedStringArray(["[color=#f0cb68]AI 성향 · %s[/color]\n주변 상황을 약 %s초마다 관측합니다. 최근 피격·현재 몬스터 구성·기존 빌드·성향·랜덤성이 증강 선택에 함께 영향을 줍니다.\n한 번 투자한 빌드를 이어가는 경향이 있어, 상황이 바뀌어도 즉시 최적 대응하지 않습니다." % [ai.get("display_name","기본 성향"),_number(float(ai.get("observation_interval",4)))],"[color=#f0cb68]관찰할 부분[/color]\n"+String(guide[0]),"[color=#f0cb68]대응 아이디어[/color]\n"+String(guide[1])+"\n"+String(guide[2]),"위 전략은 확정 공략이 아닙니다. 실제로 고른 증강과 기술 사용 직후를 보고 조합을 조정하세요."])
	var favored := PackedStringArray()
	for id in ai.get("augment_biases",{}):
		if float(ai.augment_biases[id]) <= 0: continue
		var entry := AUGMENTS.get_augment(String(id))
		if not entry.is_empty() and id in profile.get("augment_pool_ids",[]): favored.append(String(entry.get("name","")))
	if not favored.is_empty(): lines.append("[color=#f0cb68]성향상 선호하는 증강[/color]\n"+" · ".join(favored)+"\n선호는 선택 확률을 보장하지 않습니다.")
	return "\n\n".join(lines)

static func get_entry(stage_id: String) -> Dictionary:
	var stage := STAGES.get_stage(stage_id)
	if stage.is_empty(): return {}
	var profile := HEROES.get_profile(String(stage.get("hero_id","")))
	if profile.is_empty(): return {}
	return {"name":profile.get("display_name","용사"),"portrait":stage.get("portrait_path",""),"description":stage.get("lobby_description",""),"number":stage.get("number",0),"pages":[overview(stage,profile),skill_text(profile),augment_text(profile),strategy_text(stage,profile)]}
