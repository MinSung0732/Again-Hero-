# 용사 전투당 상자 예산 — 2026-10-14

일반50처치상자와정예/대형매처치상자가중첩되어과다공급되던경로를하나의용사전투예산으로통합했다.

| 항목 | 이전 | 이후 |
|---|---|---|
| 일반 처치 기준 | 50회 | 200회 |
| 정예/대형 기준 | 매처치 | 첫처치보상유지, 이후4회 |
| 전투당 공급 한도 | 없음 | 두경로합계최대3개 |
| 최소 공급 간격 | 없음 | 성공생성후180초 |
| 동시 활성 상자 | 2개 | 2개 유지 |
| 마왕 모드 | 일반50처치 | 유지 |

첫상자는초반정예보상으로예약한다. 레벨업강화는기존처럼계속되며, 상자는전투당최대3회의기존룰렛보상기회를준다. 서로다른무기3개확정/무기슬롯3개제한은추가하지않는다. 기존진화→보유무기강화→보조강화→회복우선순위를유지한다.

실제물리상자생성성공직후에만누적공급수와다음가능시각을변경한다. 두처치진척도그때초기화하며활성2상한/오래된세션/종료가드/실패생성에서는보존한다. deferred실행시에도예산/간격을재검증해한프레임에일반/정예콜백이함께예약돼도중복생성하지않는다. 한도/간격중불필요한예약을피하고새전투에서예산을초기화한다. 새저장필드는없다.

검증: Godot4.7.2 headless Battle의실제상자함수추출15검사(생성팩토리만아트없는Node2D로대체), 실제HUD/룰렛107검사PASS. 첫상자/200처치/4정예/3분공유간격/동일프레임중복/활성포화/세션/종료/총3개한도/마왕모드회귀를확인했다. 고밀도공급모델은35초첫정예즉시처치·초당7처치·상자즉시수집가정에서35/215/395초3개이며, 실제이동·처치·빌드·수집결과가아니다. 실제15분밸런스·GPU/Android미검증.

재현:

```bash
python tools/build_hero_chest_budget_fixture.py /tmp/hero-chest-budget
godot --headless --path /tmp/hero-chest-budget --editor --import --quit
godot --headless --path /tmp/hero-chest-budget --script res://tests/hero_chest_budget_smoke.gd
python tools/build_hero_hud_fixture.py /tmp/hero-chest-hud
godot --headless --path /tmp/hero-chest-hud --editor --import --quit
godot --headless --path /tmp/hero-chest-hud --script res://tests/hero_hud_inventory_smoke.gd
```

기준원격b0633ef. 해당패치revert로롤백. main병합은명시요청시에만수행한다.
