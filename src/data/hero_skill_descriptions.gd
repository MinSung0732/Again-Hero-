extends RefCounted
# Shared by battle tooltips and the read-only hero encyclopedia.

const ADDITIONAL := {
	"shield_guard":"방패로 피해를 줄이고 보호막을 얻습니다. 막는 동안 받은 피해를 축적했다가 주변에 반격합니다.",
	"purifier_divine_protection":"보호막을 반복해서 얻으며 신성 공격을 강화합니다. 보호막이 깨지면 주변 적을 밀어내고 둔화합니다.",
	"purifier_crown_of_courage":"왕관을 중첩해 신성 피해와 이동속도를 높이고 재사용 대기시간을 줄입니다. 주기적으로 체력을 회복합니다.",
	"summoner_full_slot_shield":"소환 슬롯이 모두 차면 보호막을 얻어 피해를 버팁니다.",
	"summoner_gatekeeper":"제자리에 머무는 문지기를 소환해 먼 적에게 투사체를 발사합니다.",
	"summoner_scout":"적을 찾아 이동하며 근접 공격하는 정찰병을 소환합니다.",
	"summoner_hound":"투견을 소환해 적에게 접근하고 연속으로 물어뜯습니다.",
	"summoner_watcher":"용사를 따라다니며 원거리 공격을 하는 감시자를 소환합니다.",
	"summoner_open_gate":"소환 횟수 조건을 달성하면 이계의 문을 개방합니다. 유지되는 동안 자폭 소환체를 연속으로 내보냅니다.",
}

static func describe(config: Dictionary) -> String:
	var explicit := String(config.get("description", "")).strip_edges()
	if not explicit.is_empty():
		return explicit

	var skill_id := String(config.get("id", ""))
	if ADDITIONAL.has(skill_id): return ADDITIONAL[skill_id]
	match skill_id:
		"freezing_point_explosion":
			return "지정 지점에 얼음기둥을 생성해 주변 적에게 피해를 주고, 범위 안의 적을 지속 둔화하며 기둥에 끼인 적의 이동을 봉쇄합니다."
		"radiance_singularity":
			return "주변으로 10개의 광휘구체를 순차 방출합니다. 구체는 도착 1초 뒤 폭발해 범위 피해를 주고 2초 동안 적을 둔화합니다."
		"mana_condensation":
			return "8방향에 마력을 하나씩 응축합니다. 스택당 모든 스킬 재사용 대기시간이 2% 감소하며, 8스택 상태에서 다시 사용하면 전부 소모해 쿨감이 초기화되고 영구 스탯을 강화하며 10초간 모든 스킬 피해가 30% 증가합니다. 이 완성을 2회 달성하면 스킬 5·6이 해금됩니다."
		"starlight":
			return "8초 동안 별빛을 전개합니다. 0.75초마다 용사 주변 지름 1200 범위의 무작위 지점 3곳에 유성을 떨어뜨리며, 각 유성은 지름 200 범위에 공격력의 110% 피해를 줍니다."
		"annihilation":
			return "자신의 위치에 15초 동안 소멸점을 생성합니다. 소멸점은 전장의 몬스터를 조금씩 끌어당기고, 지름 400 범위의 적에게 0.5초마다 공격력 70% 피해를 줍니다. 피해 시 체력이 10% 이하인 적은 소멸점에 먹혀 즉시 처형됩니다."
		"arcane_piercer":
			return "전방으로 강력한 마력 관통포를 발사해 일직선상의 적을 공격합니다."
		"arcane_barrier":
			return "마력 장벽을 전개해 일정 시간 피해를 흡수합니다."
		"arcane_field":
			return "제자리에서 비전 집중을 채널링해 전투 능력을 보조합니다."
		"blade_storm":
			return "주변 적을 빠르게 연속 베어 다수의 적을 압박합니다."
		"shadow_assassination":
			return "급습 후 연속 암살 공격으로 단일 대상을 집중 타격합니다."
		"shield_charge":
			return "방패를 앞세워 돌진하며 경로의 적을 밀어내고 피해를 줍니다."
		"archmage_combustion":
			return "화염구를 남겨 지속 피해를 준 뒤 연소 돌진으로 마무리합니다."
		"archmage_ice_bolt":
			return "먼 적에게 얼음 투사체를 발사하고 적중 지점 주변에 얼음기둥을 생성합니다."
		"archmage_earth_spikes":
			return "전방 직선 경로에 땅의 가시를 연속 생성해 적을 관통 공격합니다."
		"archmage_holy_power":
			return "주변 위치에 신성 폭발을 연속 발생시키고 피격 적을 둔화합니다."
		"archmage_chain_dagger":
			return "체인대거가 적 사이를 연속 도탄하며 갈수록 강한 피해를 줍니다."
		"archmage_harmony":
			return "모든 원소를 조율해 다른 대마법 기술의 재사용 대기시간을 초기화합니다."
		"archmage_storm":
			return "8방향으로 폭풍 투사체를 발사해 적을 관통하고 속박합니다."
		"blood_sword_first":
			return "혈기를 소모해 점점 커지는 검기 파동을 연속 발사합니다."
		"blood_sword_second":
			return "갈라지는 혈흔 공격을 전개하고 혈흔 접촉으로 체력을 회복합니다."
		"blood_sword_third":
			return "빠르게 돌진하며 혈구를 생성하고 회수한 혈구만큼 체력을 회복합니다."
		"blood_sword_fourth":
			return "주변을 크게 베어 적에게 피해를 주고 바깥으로 밀어냅니다."
		_:
			return "용사가 전투 상황과 사용 조건에 맞춰 자동으로 사용하는 기술입니다."
