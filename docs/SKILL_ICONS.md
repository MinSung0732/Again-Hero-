# 기술 아이콘 연결

사용자가 c5be225b 커밋으로 추가한89 PNG 중 실제 대응을 확인한78개를 원본 변경 없이 공용 SkillIconCatalog에 명시적으로 등록했다. 폴더명과 게임 ID가 다른 kobold/kobolt, skeleton_warrior/skeleton, specter_knight/dullahan 등의 차이를 경로표에서 처리한다. 런타임 디렉터리 검색·자동 파일명 추측·전투 데이터 변경은 없다.

도감: 마왕/엘리트/초월/용사 기술 슬롯. 용사 HUD: 기존 ID의 전용 아이콘을 초기 configure 때 조회하며 미등록은 기존 효과 프레임으로 fallback. 마왕: 팀 편성 카드/선택 슬롯/전투 기술 버튼에 같은 캐시 텍스처를 사용한다. 권총 용사의4기술/검방 기본 공격2종은 기존 스칼라 프로필에 존재하는 표시용 슬롯만 추가하고 전투 기술이나 수치는 추가하지 않는다.

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

## 대응 확인이 필요한 파일

- assets/art/Icon/monster/Transcendent/izanami/yomi_wave.png
- assets/art/Icon/monster/Transcendent/izanami/soul_lantern.png
- assets/art/Icon/monster/Transcendent/izanami/death_blossom.png
- assets/art/Icon/monster/Transcendent/shuten-doji/shuten-doji_skill3_icon.png
- assets/art/Icon/monster/Transcendent/shuten-doji/shuten-doji_skill4_icon.png
- assets/art/Icon/monster/Transcendent/shuten-doji/shuten-doji_skill1_icon.png
- assets/art/Icon/monster/Transcendent/shuten-doji/shuten-doji_skill2_icon.png
- assets/art/Icon/monster/Transcendent/bulgasal/immortal_rampage.png
- assets/art/Icon/monster/Transcendent/bulgasal/devour.png
- assets/art/Icon/monster/Transcendent/bulgasal/iron_bite.png
- assets/art/Icon/monster/Transcendent/bulgasal/thorn_charge.png

불가살 현재 기술: 바위던지기/바위돌진/강철도약/전략후퇴. 제공된 devour/iron_bite/thorn_charge/immortal_rampage는 이 기술명과 일치하지 않아 임의 순번 배정하지 않는다.
이자나미 현재 기술: 황천윤무/명계귀화/원혼추살/요모츠히라사카. yomi_gate는 토리이 패시브에 연결했고 나머지3개는 대응 확인이 필요하다.
슈텐도지는 아직 MonsterCatalog/TranscendentDetailCatalog 등록이 없어 기존 아이콘4개를 보관한다. 만티코어 아이콘은 이번 추가분에 없다.

## 검증

Godot4.5.1 헤드리스 tests/skill_icon_smoke.gd:78리소스 로딩/슬롯 placeholder 대체/캐시 재사용/용사 HUD ID 중복 없음·전용아트 우선·기존fallback/실제Main 초기화·마왕3전투버튼/실제Lobby 편성카드. 도감/용사 잠금·계정·기술 슬롯/초월 상세/실제Lobby 설정 회귀는 기존 smoke를 사용한다. 실제GPU 화면·모바일·export는 별도 검증 대상이다.
