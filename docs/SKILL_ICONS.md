# 기술 아이콘 연결

사용자가 c5be225b/0156ee4f 커밋으로 추가한93 PNG 중 실제 대응을 확인한89개를 원본 변경 없이 공용 SkillIconCatalog에 명시적으로 등록했다. 폴더명과 게임 ID가 다른 kobold/kobolt, skeleton_warrior/skeleton, specter_knight/dullahan 등의 차이를 경로표에서 처리한다. 런타임 디렉터리 검색·자동 파일명 추측·전투 데이터 변경은 없다.

도감: 마왕/엘리트/초월/용사 기술 슬롯. 팀 편성 상세: 초월 기술/패시브 및 엘리트 기술의 아이콘+이름/재사용/설명 행. 엘리트 행은 최초 최대 기술 수까지 생성하고 재사용한다. 용사 HUD: 기존 ID의 전용 아이콘을 초기 configure 때 조회하며 미등록은 기존 효과 프레임으로 fallback. 새 PNG의 import가 아직 없거나 null 로딩이면 원본 파일에서 한 번 로딩해 캐시하며 실패한 null은 영구 고정하지 않는다. 마왕: 팀 편성 카드/선택 슬롯/전투 기술 버튼에 같은 캐시 텍스처를 사용한다. 권총 용사의4기술/검방 기본 공격2종은 기존 스칼라 프로필에 존재하는 표시용 슬롯만 추가하고 전투 기술이나 수치는 추가하지 않는다.

## 연결된 경로

| 공용 키 | 원본 경로 |
|---|---|
| demon:demon:encirclement | res://assets/art/Icon/demonking/circular_siege.png |
| demon:demon:line_assault | res://assets/art/Icon/demonking/line_assault.png |
| demon:demon:square_siege | res://assets/art/Icon/demonking/square_siege.png |
| elite:banshee:elite_banshee_possession | res://assets/art/Icon/monster/banshee/banshee.png |
| elite:bat:elite_bat_poison_fang | res://assets/art/Icon/monster/bat/poison_fang.png |
| elite:bomb_rat:elite_bomb_rat_vibration | res://assets/art/Icon/monster/bomb_rat/tremor_sense.png |
| elite:ghost:elite_ghost_fear | res://assets/art/Icon/monster/ghost/fear.png |
| elite:goblin:elite_goblin_commander | res://assets/art/Icon/monster/goblin/commander.png |
| elite:goblin_thrower:elite_goblin_thrower_bombardment | res://assets/art/Icon/monster/goblin_bomber/bomb_drop.png |
| elite:kobolt:elite_kobolt_fighting_spirit | res://assets/art/Icon/monster/kobold/fighting_spirit.png |
| elite:medusa:elite_medusa_hidden_poison | res://assets/art/Icon/monster/medusa/hidden_poison.png |
| elite:mummy:elite_mummy_curse | res://assets/art/Icon/monster/mummy/mummy_curse.png |
| elite:powwow_mummy:elite_powwow_mummy_multicast | res://assets/art/Icon/monster/mummy_shaman/multi_cast.png |
| elite:orc:elite_orc_frenzy | res://assets/art/Icon/monster/orc/frenzy.png |
| elite:scorpion:elite_scorpion_consume | res://assets/art/Icon/monster/scorpion/survival_of_the_fittest.png |
| elite:skeleton:elite_skeleton_ambush | res://assets/art/Icon/monster/skeleton_warrior/ambush.png |
| elite:skeleton_archer:elite_skeleton_archer_arrow_rain | res://assets/art/Icon/monster/skeleton_archer/arrow_rain.png |
| elite:slime:elite_slime_proliferation | res://assets/art/Icon/monster/slime/split_growth.png |
| elite:spider:elite_spider_web_nest | res://assets/art/Icon/monster/spider/web_trap.png |
| elite:wolf:elite_wolf_pack_hunt | res://assets/art/Icon/monster/wolf/pack_hunt.png |
| elite:yuki_onna:elite_yuki_snowflake | res://assets/art/Icon/monster/snow_maiden/snow_flower.png |
| elite:dullahan:elite_dullahan_march | res://assets/art/Icon/monster/specter_knight/specter_advance.png |
| elite:dullahan:elite_dullahan_charge | res://assets/art/Icon/monster/specter_knight/spectral_charge.png |
| elite:dullahan:elite_dullahan_slam | res://assets/art/Icon/monster/specter_knight/specter_smash.png |
| elite:succubus:elite_succubus_cut | res://assets/art/Icon/monster/succubus/lacerate.png |
| elite:succubus:elite_succubus_drain | res://assets/art/Icon/monster/succubus/essence_drain.png |
| elite:succubus:elite_succubus_waltz | res://assets/art/Icon/monster/succubus/waltz_of_temptation.png |
| hero:ranged_rookie:arcane_piercer | res://assets/art/Icon/hero/apprentice_mage/arcane_piercer.png |
| hero:ranged_rookie:arcane_barrier | res://assets/art/Icon/hero/apprentice_mage/arcane_barrier.png |
| hero:ranged_rookie:arcane_field | res://assets/art/Icon/hero/apprentice_mage/arcane_focus.png |
| hero:swift_hunter:blade_storm | res://assets/art/Icon/hero/agile_hero/rend.png |
| hero:swift_hunter:shadow_assassination | res://assets/art/Icon/hero/agile_hero/ambush_assassination.png |
| hero:sword_shield_hero:shield_charge | res://assets/art/Icon/hero/sword_and_shield_hero/shield_charge.png |
| hero:sword_shield_hero:shield_guard | res://assets/art/Icon/hero/sword_and_shield_hero/guard.png |
| hero:sword_shield_hero:fighter_slash | res://assets/art/Icon/hero/sword_and_shield_hero/slash.png |
| hero:sword_shield_hero:fighter_thrust | res://assets/art/Icon/hero/sword_and_shield_hero/thrust.png |
| hero:pistol_hero:gunner_backstep | res://assets/art/Icon/hero/gunslinger/backstep.png |
| hero:pistol_hero:gunner_cylinder | res://assets/art/Icon/hero/gunslinger/cylinder_strike.png |
| hero:pistol_hero:gunner_deadeye | res://assets/art/Icon/hero/gunslinger/deadeye.png |
| hero:pistol_hero:gunner_quickdraw | res://assets/art/Icon/hero/gunslinger/quick_draw.png |
| hero:archmage_hero:archmage_combustion | res://assets/art/Icon/hero/archmage/ignite.png |
| hero:archmage_hero:archmage_ice_bolt | res://assets/art/Icon/hero/archmage/ice_bolt.png |
| hero:archmage_hero:archmage_earth_spikes | res://assets/art/Icon/hero/archmage/earth_spike.png |
| hero:archmage_hero:archmage_holy_power | res://assets/art/Icon/hero/archmage/holy_power.png |
| hero:archmage_hero:archmage_chain_dagger | res://assets/art/Icon/hero/archmage/chain_dagger.png |
| hero:archmage_hero:archmage_harmony | res://assets/art/Icon/hero/archmage/harmony.png |
| hero:archmage_hero:archmage_storm | res://assets/art/Icon/hero/archmage/storm.png |
| hero:madness_hero:blood_sword_first | res://assets/art/Icon/hero/mad_hero/blood_sword_form_1.png |
| hero:madness_hero:blood_sword_second | res://assets/art/Icon/hero/mad_hero/blood_sword_form_2.png |
| hero:madness_hero:blood_sword_third | res://assets/art/Icon/hero/mad_hero/blood_sword_form_3.png |
| hero:madness_hero:blood_sword_fourth | res://assets/art/Icon/hero/mad_hero/blood_sword_form_4.png |
| hero:chemical_hero:alchemist_catalyst_field | res://assets/art/Icon/hero/alchemist_hero/catalyst_mixture_field.png |
| hero:chemical_hero:alchemist_mystery_cauldron | res://assets/art/Icon/hero/alchemist_hero/what_will_come_out.png |
| hero:chemical_hero:alchemist_today_failed_again | res://assets/art/Icon/hero/alchemist_hero/another_failure_today.png |
| hero:chemical_hero:alchemist_philosopher_stone | res://assets/art/Icon/hero/alchemist_hero/philosophers_stone.png |
| hero:summoner_hero:summoner_full_slot_shield | res://assets/art/Icon/hero/otherworld_hero/saturation_barrier.png |
| hero:summoner_hero:summoner_gatekeeper | res://assets/art/Icon/hero/otherworld_hero/gatekeeper.png |
| hero:summoner_hero:summoner_scout | res://assets/art/Icon/hero/otherworld_hero/scout.png |
| hero:summoner_hero:summoner_hound | res://assets/art/Icon/hero/otherworld_hero/war_hound.png |
| hero:summoner_hero:summoner_watcher | res://assets/art/Icon/hero/otherworld_hero/watcher.png |
| hero:summoner_hero:summoner_open_gate | res://assets/art/Icon/hero/otherworld_hero/gate_open.png |
| hero:purifier_hero:purifier_divine_protection | res://assets/art/Icon/hero/purifier_hero/divine_protection.png |
| hero:purifier_hero:purifier_crown_of_courage | res://assets/art/Icon/hero/purifier_hero/crown_of_courage.png |
| hero:purifier_hero:purifier_purification_orb | res://assets/art/Icon/hero/purifier_hero/purifying_orb.png |
| hero:purifier_hero:purifier_cleansing | res://assets/art/Icon/hero/purifier_hero/purification.png |
| hero:purifier_hero:purifier_gungnir | res://assets/art/Icon/hero/purifier_hero/gungnir.png |
| hero:sage_astra:freezing_point_explosion | res://assets/art/Icon/hero/archsage/freezing_point_explosion.png |
| hero:sage_astra:radiance_singularity | res://assets/art/Icon/hero/archsage/radiant_singularity.png |
| hero:sage_astra:mana_condensation | res://assets/art/Icon/hero/archsage/mana_condensation.png |
| hero:sage_astra:starlight | res://assets/art/Icon/hero/archsage/starlight.png |
| hero:sage_astra:annihilation | res://assets/art/Icon/hero/archsage/annihilation.png |
| hero:sage_astra:black_spot_explosion | res://assets/art/Icon/hero/archsage/black_sun_explosion.png |
| transcendent:zeus:심판 | res://assets/art/Icon/monster/Transcendent/zeus/judgment.png |
| transcendent:zeus:천둥구체 | res://assets/art/Icon/monster/Transcendent/zeus/thunder_orb.png |
| transcendent:zeus:왕관 | res://assets/art/Icon/monster/Transcendent/zeus/crown.png |
| transcendent:zeus:천둥가르기 | res://assets/art/Icon/monster/Transcendent/zeus/thunder_cleave.png |
| transcendent:zeus:과전압 | res://assets/art/Icon/monster/Transcendent/zeus/overcharge.png |
| transcendent:izanami:요모츠히라사카 | res://assets/art/Icon/monster/Transcendent/izanami/yomi_gate.png |

## 추가 확정 연결

| 몬스터 | 현재 기술 | 파일 |
|---|---|---|
| 불가살 | 바위던지기 | iron_bite.png |
| 불가살 | 바위돌진 | thorn_charge.png |
| 불가살 | 강철도약 | immortal_rampage.png |
| 불가살 | 전략후퇴(패시브) | devour.png |
| 이자나미 | 황천윤무 | soul_lantern.png |
| 이자나미 | 명계귀화 | death_blossom.png |
| 이자나미 | 원혼추살 | yomi_wave.png |
| 이자나미 | 요모츠히라사카(패시브) | yomi_gate.png |
| 만티코어 | 재앙의 불꽃 | manticore_skill1_icon.png |
| 만티코어 | 맹독유성 | manticore_skill2_icon.png |
| 만티코어 | 지각분쇄 | manticore_skill3_icon.png |
| 만티코어 | 살을 찢는 공포(패시브) | manticore_skill4_icon.png |

만티코어 사냥/추적 설명은 살을 찢는 공포 패시브 항목에 소제목과 함께 합쳐 동일 아이콘을 공유한다. 별도의 기본 공격 행/빈 슬롯은 만들지 않는다. 슈텐-도지4개는 혈주연무/귀염지폭/쇄혼귀면/귀왕해방에 순서대로 연결한다. 도감과 팀 초월 상세에서 동일 카탈로그를 사용한다. 마왕 circular_siege→원형 포위, line_assault→직선 포위, square_siege→사각 포위이며 기존 기술 ID/판정/수치는 유지한다.

## 전투 마왕 버튼

Button의 자동 icon/text 대신 고정 Control을 최초3개 생성한다. 버튼 크기/입력 영역을 유지하며 왼쪽60px 아이콘,14px 간격, 이름24px/상태20px의 두 줄을 오른쪽 같은 x위치에 둔다. 부족·방향선택·쿨타임 상태가 이름을 밀지 않는다. 긴 문구는 말줄임하고 전체 내용은 툴팁에 보관한다. 기존 disabled/pressed/쿨타임바/단축키는 부모 Button이 처리한다. 레이아웃은 resize 때, 색은 사용가능 상태전환 때만 갱신한다.

## 작은 화면 식별

256px를 초과하는 큰 원본은 최초 로딩 때만 Lanczos로128px 축소하고 캐시한다. 원본 PNG와 이미 작은 픽셀 아이콘은 변경하지 않는다. 초월 아이콘 칸은64→80 논리px, 공통 기술 슬롯은76→80px. 기존 기술/설명 행 배치는 유지한다. 화면 축척이0.5면 초월 아이콘은32→40 실제px이며 원본의 복잡한 실루엣 자체가 단순해지는 것은 아니다. 다음 에셋 개선은 각 기술의 주된 형상 하나와 명확한 색 차이를32~40px에서 검수하는 방식이 적절하다.

## 검증

Godot4.5.1 헤드리스 tests/skill_icon_smoke.gd:89리소스·import 없는 PNG fallback 로딩/슬롯 placeholder 대체/캐시 재사용/용사 HUD ID 중복 없음·전용아트 우선·기존fallback/실제Main 초기화·마왕3전투버튼/실제Lobby 편성카드·25종 팀 상세/엘리트 아이콘·행 재사용. 도감/용사 잠금·계정·기술 슬롯/초월 상세/실제Lobby 설정 회귀는 기존 smoke를 사용한다. 실제GPU 화면·모바일·export는 별도 검증 대상이다.

편성 아래쪽 마왕 기술 카드는 16px 장식 프레임 안쪽에 24px 여백을 두고 아이콘/본문/편성 버튼을 배치한다. 최소 높이274px로 기존 내용 공간을 유지한다.
