# 용사 2차 밸런스 패치 — 2026-10-11

기준 커밋 `34ff22fe769994210bc56923a2961c49d99101d0`. 작업 브랜치 `feature/stage10-astra`, main 변경 없음.

## 의도

1~3단계는 기본 소환·물량/탱커/제어 조합·빌드 관찰을 배우는 구간입니다. 4단계부터 탄창·회피·집중 사격을 통한 난이도 상승을 분명히 하고, 이후 원소/광기/독/소환/정화/응축의 카운터를 요구합니다. 4단계 이후를 일괄 쉽게 만들거나 초월 한 마리의 단독 승리를 보장하는 패치는 아닙니다.

기존 원본 스탯과 스테이지 배율의 겹침을 정리했습니다. 1~3단계는 입장 배율 1배, 4~10단계는 HP1.25/공격1.15/공격간격1배입니다. 아래 표는 배율 적용 후 Lv1·증강 없는 실제 입장값이며 Godot 계산 결과입니다. 화학/소환 용사의 기본공격 수치만으로 여러 장판·소환체의 총 피해를 비교할 수 없습니다.

## 입장 스탯 전후

| 단계 | 용사 | HP | 공격력 | 공격간격(초) | 이속 |
|---|---|---:|---:|---:|---:|
| 1 | 견습 마법용사 | 375 → 360 | 37 → 32 | 0.6076 → 0.7 | 230 → 220 |
| 2 | 날렵한 용사 | 598 → 600 | 46 → 42 | 1.127 → 1.2 | 275 → 255 |
| 3 | 검과 방패의 용사 | 1485 → 1100 | 54 → 50 | 0.8924 → 1 | 200 → 205 |
| 4 | 권총의 용사 | 2400 → 2000 | 90 → 81 | 0.384 → 0.44 | 300 → 285 |
| 5 | 대마법 용사 | 2790 → 2625 | 138 → 132 | 1.083 → 1.2 | 250 → 245 |
| 6 | 광기의 용사 | 4480 → 3875 | 183 → 173 | 1.045 → 1.2 | 225 → 230 |
| 7 | 화학의 용사 | 5610 → 4750 | 180 → 173 | 2.162 → 2.5 | 285 → 270 |
| 8 | 이계의 용사 | 4125 → 4250 | 126 → 126 | 0.893 → 1.1 | 260 → 255 |
| 9 | 정화의 용사 | 3740 → 4500 | 134 → 144 | 1.2555 → 1.4 | 250 → 245 |
| 10 | 대현자 용사 | 6840 → 6250 | 206 → 195 | 1.0856 → 1.25 | 225 → 225 |

4단계는 3단계보다 HP 약1.82배, 장전 제외 기본 사격 DPS 약3.68배입니다. 장전 포함 무증강 12발 주기의 이론 평균은 약133.5 DPS(12×81 / (12×0.44+2.0))입니다. 실제 사격 도달률·헤드샷·회피·데드아이·각 기술 행동 시간은 별도입니다. 이 값은 실제 시뮬레이션 승률이 아닙니다.

- 1단계: 공격·장벽·비전 집중과 충전을 낮춰 물량/접근형 압박을 배우도록 조정.
- 2단계: 연격 정체성을 유지하고 접근 속도·난도질 보호막·급습 빈도를 조정.
- 3단계: 높은 기존 HP와 막기 중 보호막/감소율을 낮춰 반격을 관찰하고 공격 타이밍을 배우도록 조정.
- 4단계: 여전히 강한 초당 화력. 회피 확률40→30%, 회피 무적0.9→0.6초, 회피CD4.5→5.5초, 장전1.8→2초. 장전과 회피 직후에 복수 방향 압박/상태이상으로 대응할 여지를 확보.
- 5단계: 중첩 광역 피해·도탄 증가·게이지 반환·추가 시전 연쇄를 완화. 원소 순환/조화 초기화는 유지.
- 6단계: 빈사 화력과 광기 속도, 반복 회복을 완화하고 처치 게이지1→1.25로 광기 정체성을 유지. 한 번 부활/체력 소모 규칙 유지.
- 7단계: 독 반복 피해와 현자의 돌의 HP/공격/이속/CD 복합 배율을 낮춤. 재료 공급과 가스 관리에 빈틈을 확보. 변신 후 자동 가스는12/6초로 종전10/5초와 같은 초당2.
- 8단계: 본체 체력은 소폭 보강하되 소환 빈도/여러 소환체 피해·슬롯 방벽을 완화. 소환수 누적 역할과 5레벨마다 슬롯 추가는 유지.
- 9단계: 본체 HP/공격을 보강하고 반복 보호막/왕관 회복/구체 연쇄/정화의 빈도를 낮춰 후반 난이도와 집중 공세 대응 여지를 함께 확보.
- 10단계: 초반 마력 회복은1→1.5, 5레벨당 증가는1→0.5. 응축 영구 공격/HP3→2%, 소멸 반복 피해/지속시간·흑점 발동을 완화. 해금 조건·위상 이동·응축 완성 방식은 유지.

## 레벨 성장

1~3단계: 레벨업마다 **시작 공격력**의1.2%, 4~10단계:1.4%. 모두10레벨마다 시작 공격력3% 추가. 기존 소수 누적기/정수 반영을 유지합니다. 현재 공격력에 곱하는 복리 성장으로 바꾸지 않습니다. 기술과 증강이 실전 빌드를 만드는 중심이고 기본 레벨 성장만으로 모든 역할을 해결하지 않도록 설계했습니다.

## 증강 변경

| 증강 | 이전 | 변경 후 |
|---|---|---|
| 속공 훈련 | 2%×20, 최대40% | 1.5%×20, 최대30% |
| 강인한 육체 | 획득 당시 HP4%×10 | HP3%×10, 증가분 회복 유지 |
| 회복 증폭 | 3%×20, 최대60% | 2%×20, 최대40% |
| 민첩한 발놀림 | +10×10 | +6×10 |
| 둔화 적응 | +7%, 최대56%, 10중첩 | +5%×8, 최대40% |
| 폭발 탄환 | 피해+28%p, 최대70% | +20%p, 최대60%; 범위 유지 |
| 도망자의 본능 | 저HP 회피+8%×5 | +6%×5, 최대30% |
| 다중시전 | 추가 기술 최대3개 | 최대2개; 비재귀/무료 추가 시전 유지 |
| 고속영창 | CD감소5%×5 | 4%×5, 최대20% |

수치/상한은 Catalog effects에서 관리하도록 핵심 특수 연산도 연결했습니다. 속공 훈련의 누적 기여만 별도로 제한하여 대현자 영구 공격속도 증가를 깎지 않습니다. 대현자 응축/스타라이트/소멸 설명도 데이터 수치를 읽도록 연결했습니다. 선택 점수·성향·최근 관측·관성·랜덤은 수정하지 않았습니다. 기타 고유 증강은 기존 규칙을 유지하며, 전체 증강을 동일 비율로 일괄 조정하지 않았습니다. HP 증강은 획득 당시 최대HP 기준으로 매번 반올림하므로 10중첩의 실제 최종 비율은 단순30%와 다릅니다(HP1000→1345 예시).

## 신속 처치 보상

승리 시 **신속 점수 = floor(남은 시간 / 전체 제한시간 ×100)**. 전체 제한시간이 달라도 같은 비율이면 같은 점수를 줍니다. 신속 점수는 기존 기여 점수 상한200 이후 추가되며 합산 상한300입니다. 기여 점수가 상한에 닿아도 빠른 처치가 무의미해지지 않습니다.

- 연구포인트 = round((기여 점수 + 신속 점수) × 기존 스테이지 보상 배율).
- 골드 = floor(지급 연구포인트 ×0.60).
- 최초 클리어 보상은 별도 기존 보상을 유지합니다.
- 제한시간300초에서 60초 처치: 신속80. 150초:50. 240초:20. 300초:0.
- 테스트 예시(기여86·Stage배율1.6): 60초 처치 연구266/골드159, 240초 처치 연구170/골드102. 빠른 처치가 연구96/골드57 더 지급.
- 서로 다른 전투의 기여 점수까지 같다고 가정하는 것은 아닙니다. 더 빨라도 매우 적은 기여만 했다면 총합은 다른 결과일 수 있습니다. 같은 기여 조건에서 시간 보너스는 단조 감소합니다.

## 중도 종료/시간초과 부분 보상

전투 시계30초 이상, 실제 소환 비용 합3 이상, 실제 용사 HP피해1 이상이면 **승리 보너스를 제외한 기여 점수의35%**를 버림하여 지급합니다. 연구 최대60, 골드는 그60%(최대36). 실패/중도 종료에는 스테이지 클리어 배율·신속·승리·최초 클리어 보상이 없습니다. 조건을 충족하지 못한 방치/즉시 퇴장에는0.

- 예시: 기여66 → 연구23/골드13. 아주 적게 싸운 기여30 → 연구10/골드6.
- 게임 내 로비 버튼으로 중단 시 기존 결과창에서 정산을 확인한 뒤 로비로 이동합니다. 연습/튜토리얼은 보상 없이 기존 퇴장 흐름 유지.
- 기존30초 이내 스테미너 반환 경로는 유지하며, 부분 보상30초 조건은 정지/로딩 시간을 제외하는 전투 시계로 판정합니다.
- 저장 실패 시 전투를 종료하지 않고 다시 누를 수 있습니다. 성공한 정산은 반복 종료/콜백으로 재지급하지 않습니다. 앱 강제 종료/프로세스 종료의 사후 보상은 이 패치 범위가 아닙니다.
- 서버 권위 보상/온라인 부정행위 검증을 새로 구축한 것은 아닙니다. 기존 저장 지급 경로를 사용하며 DB/계정 데이터 스키마는 변경하지 않습니다.

## 검증과 실전 확인

Godot4.5.1 격리197검사 통과: 실제 Profile/Stage/Codex/RunMetrics, 실제 입장 배율·성장·선택한 증강·정산 함수 추출 shell. 몬스터/초월 회귀411검사 통과. 변경 GDScript parse 및 diff 검사. 실제 전체전투/GPU화면/Android/export/서버 실지급/승률은 미검증입니다.

1. 연구0·강화0에서 Stage1~3의 일반 몬스터 조합으로 통과 가능성과 학습 시간을 확인.
2. Stage4를 같은 비용의 단일 방향/분산 방향, 제어 없음/제어 포함으로 비교. 장전/회피 직후 공격 도달률이 달라지는지 확인.
3. Stage5~10 고정 시드10개 이상으로 0/5초월과 군단 혼합을 비교. 초월 단독 승리를 모든 단계의 목표로 삼지 않음.
4. 빠른/느린 승리, 실제 중도 종료, 무행동 퇴장, 시간초과, 저장 실패/재시도에서 잔고와 결과 표시 확인.
5. 이상치가 확인되면 주요 계수를 ±10~15% 단위로 후속 조정. 현재 승률/평균 처치 시간을 실측 결과처럼 해석하지 않기.

아래 목록은 프로필 원본의 모든 변경 수치입니다. 입장 HP/공격력/간격은 위 표가 권위 있는 실제 시작 값이며 원본 수치와 혼동하지 마세요.

## 기술·게이지·성장 원본 변경 내역

### 1단계 · 견습 마법용사

| 항목 | 이전 | 변경 후 |
|---|---:|---:|
| `max_hp` | 300 | 360 |
| `attack_damage` | 34 | 32 |
| `move_speed` | 230.0 | 220 |
| `attack_cooldown` | 0.62 | 0.7 |
| `invulnerability_duration` | 0.35 | 0.22 |
| `level_growth.base_attack_growth_ratio` | 0.02 | 0.012 |
| `level_growth.attack_milestone_bonus` | 0.05 | 0.03 |
| `ultimate.charge_per_second` | 2.5 | 2.0 |
| `ultimate.charge_on_attack` | 4.0 | 3.0 |
| `ultimate.charge_per_damage` | 0.25 | 0.15 |
| `ultimate.cooldown` | 12.0 | 16.0 |
| `ultimate.damage` | 110 | 100 |
| `shield_skill.cooldown` | 18.0 | 22.0 |
| `shield_skill.duration` | 8.0 | 6.0 |
| `shield_skill.shield_hp_ratio` | 0.30 | 0.25 |
| `channel_skill.cooldown` | 18.0 | 22.0 |
| `channel_skill.tick_damage` | 14 | 10 |

### 2단계 · 날렵한 용사

| 항목 | 이전 | 변경 후 |
|---|---:|---:|
| `max_hp` | 460 | 600 |
| `move_speed` | 275.0 | 255 |
| `attack_cooldown` | 1.15 | 1.2 |
| `invulnerability_duration` | 0.28 | 0.22 |
| `level_growth.base_attack_growth_ratio` | 0.02 | 0.012 |
| `level_growth.attack_milestone_bonus` | 0.05 | 0.03 |
| `rogue_slash_skill.cooldown` | 10.5 | 14.0 |
| `rogue_slash_skill.damage_ratio` | 0.75 | 0.65 |
| `rogue_slash_skill.shield_hp_ratio` | 0.25 | 0.2 |
| `ultimate.charge_per_second` | 2.0 | 1.8 |
| `ultimate.charge_on_attack` | 4.5 | 3.5 |
| `ultimate.charge_per_damage` | 0.18 | 0.12 |
| `ultimate.cooldown` | 8.0 | 12.0 |
| `ultimate.elite_damage_multiplier` | 1.90 | 1.6 |

### 3단계 · 검과 방패의 용사

| 항목 | 이전 | 변경 후 |
|---|---:|---:|
| `attack_damage` | 48 | 50 |
| `move_speed` | 200.0 | 205 |
| `attack_cooldown` | 0.92 | 1.0 |
| `invulnerability_duration` | 0.30 | 0.22 |
| `level_growth.base_attack_growth_ratio` | 0.02 | 0.012 |
| `level_growth.attack_milestone_bonus` | 0.05 | 0.03 |
| `fighter_charge_skill.cooldown` | 17.0 | 20.0 |
| `fighter_charge_skill.dash_damage_ratio` | 1.20 | 1.0 |
| `fighter_charge_skill.impact_damage_ratio` | 1.70 | 1.4 |
| `ultimate.charge_seconds` | 20.0 | 24.0 |
| `ultimate.duration` | 10.0 | 8.0 |
| `ultimate.shield_hp_ratio` | 0.60 | 0.45 |
| `ultimate.damage_reduction` | 0.30 | 0.25 |
| `ultimate.stored_damage_release_ratio` | 0.50 | 0.4 |

### 4단계 · 권총의 용사

| 항목 | 이전 | 변경 후 |
|---|---:|---:|
| `attack_damage` | 78 | 70 |
| `move_speed` | 300.0 | 285 |
| `attack_cooldown` | 0.40 | 0.44 |
| `level_growth.base_attack_growth_ratio` | 0.0125 | 0.014 |
| `gunner.reload_seconds` | 1.8 | 2.0 |
| `gunner.empty_mag_shield_ratio` | 0.10 | 0.08 |
| `gunner.backstep_invulnerability` | 0.90 | 0.6 |
| `gunner.backstep_cooldown` | 4.5 | 5.5 |
| `gunner.backstep_base_chance` | 0.40 | 0.3 |
| `gunner.surrounded_backstep_bonus` | 0.55 | 0.4 |
| `gunner.cylinder_cooldown` | 8.0 | 10.0 |
| `gunner.deadeye_cooldown` | 16.0 | 20.0 |
| `gunner.deadeye_shot_interval` | 0.08 | 0.1 |

### 5단계 · 대마법 용사

| 항목 | 이전 | 변경 후 |
|---|---:|---:|
| `max_hp` | 1800 | 2100 |
| `attack_damage` | 118 | 115 |
| `move_speed` | 250.0 | 245 |
| `attack_cooldown` | 1.14 | 1.2 |
| `invulnerability_duration` | 0.30 | 0.25 |
| `level_growth.base_attack_growth_ratio` | 0.016 | 0.014 |
| `level_growth.attack_milestone_bonus` | 0.04 | 0.03 |
| `archmage_skills.gauge_per_second` | 3.0 | 2.5 |
| `archmage_skills.gauge_per_basic_attack` | 4.0 | 3.0 |
| `archmage_skills.combustion.cooldown` | 22.5 | 26.0 |
| `archmage_skills.combustion.charge_tick_damage_ratio` | 0.44 | 0.32 |
| `archmage_skills.ice_bolt.cooldown` | 25.0 | 28.0 |
| `archmage_skills.ice_bolt.pillar_damage_ratio` | 0.85 | 0.65 |
| `archmage_skills.earth_spikes.cooldown` | 27.5 | 30.0 |
| `archmage_skills.earth_spikes.damage_ratio` | 1.40 | 1.25 |
| `archmage_skills.holy_power.cooldown` | 30.0 | 32.0 |
| `archmage_skills.holy_power.damage_ratio` | 0.90 | 0.8 |
| `archmage_skills.chain_dagger.cooldown` | 25.0 | 28.0 |
| `archmage_skills.chain_dagger.max_bounces` | 14 | 10 |
| `archmage_skills.chain_dagger.damage_growth_per_bounce` | 0.20 | 0.12 |
| `archmage_skills.harmony.cooldown` | 100.0 | 110.0 |
| `archmage_skills.storm.cooldown` | 32.5 | 36.0 |
| `archmage_skills.storm.gauge_restore_per_hit` | 4.0 | 2.5 |

### 6단계 · 광기의 용사

| 항목 | 이전 | 변경 후 |
|---|---:|---:|
| `max_hp` | 2800 | 3100 |
| `attack_damage` | 155 | 150 |
| `move_speed` | 225.0 | 230 |
| `attack_cooldown` | 1.10 | 1.2 |
| `invulnerability_duration` | 0.28 | 0.25 |
| `level_growth.base_attack_growth_ratio` | 0.015 | 0.014 |
| `level_growth.attack_milestone_bonus` | 0.035 | 0.03 |
| `berserker.missing_hp_attack_bonus_per_percent` | 0.02 | 0.018 |
| `berserker.madness_attack_speed_multiplier` | 3.00 | 2.6 |
| `berserker.gauge_per_kill` | 1.0 | 1.25 |
| `berserker.skill_1.cooldown` | 15.0 | 17.0 |
| `berserker.skill_1.damage_ratio` | 1.10 | 1.0 |
| `berserker.skill_2.cooldown` | 19.0 | 22.0 |
| `berserker.skill_2.damage_ratio` | 0.85 | 0.75 |
| `berserker.skill_2.heal_per_touch_tick` | 10 | 8 |
| `berserker.skill_3.cooldown` | 30.0 | 32.0 |
| `berserker.skill_3.heal_per_orb` | 70 | 60 |
| `berserker.skill_4.cooldown` | 8.0 | 10.0 |

### 7단계 · 화학의 용사

| 항목 | 이전 | 변경 후 |
|---|---:|---:|
| `max_hp` | 3400 | 3800 |
| `move_speed` | 285.0 | 270 |
| `attack_cooldown` | 2.30 | 2.5 |
| `invulnerability_duration` | 0.27 | 0.25 |
| `level_growth.base_attack_growth_ratio` | 0.012 | 0.014 |
| `alchemist.poison_tick_damage_ratio` | 0.18 | 0.14 |
| `alchemist.material_spawn_interval` | 4.0 | 5.0 |
| `alchemist.low_gas_spawn_interval` | 2.0 | 2.5 |
| `alchemist.mixture_field.cooldown` | 20.0 | 24.0 |
| `alchemist.mixture_field.tick_damage_ratio` | 0.20 | 0.18 |
| `alchemist.mixture_field.heal_max_hp_ratio` | 0.01 | 0.008 |
| `alchemist.mystery_cauldron.cooldown` | 20.0 | 24.0 |
| `alchemist.mystery_cauldron.great_success_damage_ratio` | 0.45 | 0.4 |
| `alchemist.emergency_escape.cooldown` | 10.0 | 12.0 |
| `alchemist.philosopher_stone.hp_multiplier` | 1.40 | 1.25 |
| `alchemist.philosopher_stone.attack_multiplier` | 1.50 | 1.35 |
| `alchemist.philosopher_stone.move_speed_multiplier` | 1.22 | 1.12 |
| `alchemist.philosopher_stone.skill_cooldown_multiplier` | 0.70 | 0.8 |
| `alchemist.philosopher_stone.gas_regen_amount` | 10.0 | 12.0 |
| `alchemist.philosopher_stone.gas_regen_interval` | 5.0 | 6.0 |
| `alchemist.philosopher_stone.trail_tick_damage_ratio` | 0.18 | 0.14 |

### 8단계 · 이계의 용사

| 항목 | 이전 | 변경 후 |
|---|---:|---:|
| `max_hp` | 2500 | 3400 |
| `attack_damage` | 105 | 110 |
| `move_speed` | 260.0 | 255 |
| `attack_cooldown` | 0.95 | 1.1 |
| `invulnerability_duration` | 0.26 | 0.25 |
| `level_growth.base_attack_growth_ratio` | 0.012 | 0.014 |
| `summoner.cast_interval` | 1.0 | 1.2 |
| `summoner.full_slot_shield.cooldown` | 40.0 | 45.0 |
| `summoner.full_slot_shield.shield_hp_ratio` | 0.15 | 0.12 |
| `summoner.gatekeeper.cooldown` | 10.0 | 12.0 |
| `summoner.gatekeeper.damage_ratio` | 0.70 | 0.6 |
| `summoner.scout.cooldown` | 20.0 | 24.0 |
| `summoner.scout.damage_ratio` | 0.50 | 0.45 |
| `summoner.hound.cooldown` | 30.0 | 34.0 |
| `summoner.hound.damage_ratio` | 0.35 | 0.3 |
| `summoner.watcher.cooldown` | 7.0 | 9.0 |
| `summoner.watcher.damage_ratio` | 0.10 | 0.08 |
| `summoner.open_gate.cooldown` | 100.0 | 110.0 |
| `summoner.open_gate.drone.damage_ratio` | 0.30 | 0.25 |

### 9단계 · 정화의 용사

| 항목 | 이전 | 변경 후 |
|---|---:|---:|
| `max_hp` | 2200 | 3600 |
| `attack_damage` | 110 | 125 |
| `move_speed` | 250.0 | 245 |
| `attack_cooldown` | 1.35 | 1.4 |
| `invulnerability_duration` | 0.28 | 0.25 |
| `level_growth.base_attack_growth_ratio` | 0.012 | 0.014 |
| `purifier_gauge.charge_per_kill` | 2.0 | 1.5 |
| `purifier_gauge.protection.cooldown` | 30.0 | 36.0 |
| `purifier_gauge.protection.duration` | 20.0 | 16.0 |
| `purifier_gauge.protection.shield_hp_ratio_per_tick` | 0.01 | 0.008 |
| `purifier_crown.cooldown` | 20.0 | 24.0 |
| `purifier_crown.cooldown_reduction_per_stack` | 0.04 | 0.03 |
| `purifier_crown.heal_per_stack` | 20 | 16 |
| `purifier_orb.cooldown` | 10.0 | 12.0 |
| `purifier_orb.chain_damage_growth` | 0.15 | 0.1 |
| `purifier_cleansing.cooldown` | 3.0 | 4.0 |
| `purifier_cleansing.base_damage_ratio` | 0.80 | 0.75 |
| `purifier_gungnir.cooldown` | 90.0 | 100.0 |
| `purifier_gungnir.damage_ratio` | 1.50 | 1.6 |

### 10단계 · 대현자 용사

| 항목 | 이전 | 변경 후 |
|---|---:|---:|
| `max_hp` | 3800 | 5000 |
| `attack_damage` | 165 | 170 |
| `move_speed` | 225.0 | 225 |
| `attack_cooldown` | 1.18 | 1.25 |
| `invulnerability_duration` | 0.28 | 0.25 |
| `level_growth.base_attack_growth_ratio` | 0.012 | 0.014 |
| `sage.gauge_regen_base` | 1.0 | 1.5 |
| `sage.gauge_regen_per_5_levels` | 1.0 | 0.5 |
| `sage.gauge_per_kill` | 1.0 | 0.75 |
| `sage.skill_1.cooldown` | 25.0 | 28.0 |
| `sage.skill_1.damage_ratio` | 1.0 | 0.9 |
| `sage.skill_2.cooldown` | 45.0 | 48.0 |
| `sage.skill_2.damage_ratio_max` | 1.0 | 0.9 |
| `sage.skill_3.cooldown` | 13.0 | 16.0 |
| `sage.skill_3.permanent_attack_ratio` | 0.03 | 0.02 |
| `sage.skill_3.permanent_hp_ratio` | 0.03 | 0.02 |
| `sage.skill_3.skill_damage_buff_ratio` | 0.30 | 0.25 |
| `sage.skill_3.cooldown_reduction_per_stack` | 0.02 | 0.015 |
| `sage.skill_4.cooldown` | 60.0 | 65.0 |
| `sage.skill_4.damage_ratio` | 1.10 | 0.95 |
| `sage.skill_5.cooldown` | 60.0 | 70.0 |
| `sage.skill_5.damage_ratio` | 0.70 | 0.55 |
| `sage.skill_5.duration` | 15.0 | 12.0 |
| `sage.skill_6.trigger_chance` | 0.50 | 0.4 |
| `sage.skill_6.damage_ratio` | 0.80 | 0.7 |

## 자료 / 롤백

`hero_balance_20261011.csv`: 입장 스탯10종 전후. `hero_skill_balance_20261011.csv`: 프로필 원본 수치 변경 상세. 이 패치 커밋 revert로 용사와 보상 규칙을 함께 되돌릴 수 있습니다. 직전 몬스터/초월 성장 패치는 유지됩니다.
