# 용사 모드 첫40초 도전·추격 — 2026-10-14

기존에는 30초까지 이속이 고정되고 역할확장은120초, 포위90초, 정예60초로 초반 변화가 늦었다. 용사 모드에서 첫24초 예고포위, 35초 정예, 40초 원거리협공을 통해 이동/처치/강화의 가까운 목표를 제시한다. 신규/기존 계정 모두 같은 전투시간표를 사용한다. 재미·재도전욕구 개선은 설계목표이며 사람 대상 검증결과가 아니다.

| 항목 | 이전 | 이후 |
|---|---|---|
| 이속 계수 0초 | 0.80 | 0.80 |
| 이속 계수 30초 | 0.80 | 1.00 |
| 이속 계수 40초 | 약0.811 | 1.08 |
| 이속 계수 120초 | 0.90 | 1.20 |
| 이속 계수 300초 | 1.00 | 1.40 |
| 이속 계수 600초 | 1.10 | 1.60 |
| 이속 계수 900초 | 1.20 | 1.75 |
| 첫 포위 | 90초/반경430 | 24초 예고/25.8초부터 소환/초반반경320 |
| 초반 포위 간격 | 105초 | 40초 (24/64/104초, 120초이후105초) |
| 첫 정예 | 60초/거리650 | 35초/거리450 |
| 일반5역할 협공 | 120초 | 40초 |
| 초반 HUD 목표 | 남은15분 | 첫포위→첫정예→정예격파/강화상자→다음공세 |

HP/피해의 기존선형곡선은 보존한다. 12초/40초의 새보간점도 기존HP/피해선상이다. 속도는 기존소환스냅샷에만 적용되며, 이미싸우는몬스터의HP/상처/속도를 매프레임 재계산하지 않는다. 어려움1.05/등급/고유기술속도는 기존별도배율이므로 위계수와실제속도를 구분한다. 초반40초 기본추격계수는입장대비35% 증가한다.

40초 일반공세는2마리/0.85초/한도40/지휘재생24/첫5역할을 사용한다. 이전120초이후 공세의일반수치와15분보스 조건은 유지한다. 포위탈출구는반복시회전하며 1.8초예고/180안전거리/4개씩배치/8벽재사용을 유지한다. 정예는일반공세한도가차더라도전체72상한내에서시도한다. 실제소환실패/전체상한포화시에는기존재시도하며 무조건35초출현을보장하지않는다.

정예/대형사망시 기존상자생성경로를 유지한다. 상자는직접파괴해야 열리고 기존무기진화/강화/보조/회복룰렛을사용한다. 타이머의초반목표완료는 `apply_chest()` 성공뒤에만 기록한다. 실패/중복영수증은성공으로표시하지않는다. 목표완료여부는한전투내UI상태이며새저장/경제보상을추가하지않는다.120초부터원래타이머로돌아오며최종보스표시가우선한다. 기존자원정보표시와HUD높이/이동패드영역은보존한다.

## 검증

수정전 원격feature/stage10-astra `42d45503f6bc9dd8d5315ecc9cfb23fe1ca40758`, main `10c9805842d745412ffe9b45e822896001ef27cb` 확인. 변경범위: Catalog/Director/Encounters/HUD. 마왕캠페인·저장·상자경제·원본몬스터/용사스탯 미변경.

Godot4.7.2 headless 격리6168검사: 0~900초곡선 연속/단조/HP피해기존예산 일치, 첫40초이속차이, 실제Director 1/10전장×쉬움/어려움 첫24초예고/35초정예/일반한도초과 정예슬롯/72상한/일시정지 검사. 기존포위/물리벽/보스종료441검사, 실제HUD함수/UI와상자회귀107검사 PASS. 합계6716. 실제원본몬스터전투/원본정예기술·30~40초재미/원형회피공략실패율/15분완주·GPU/AndroidFPS는검증하지않았다.

재현:

```bash
python tools/build_hero_encounter_fixture.py /tmp/hero-pressure
cp tests/hero_opening_pressure_smoke.gd /tmp/hero-pressure/tests/
godot --headless --path /tmp/hero-pressure --editor --import --quit
godot --headless --path /tmp/hero-pressure --script res://tests/hero_opening_pressure_smoke.gd
godot --headless --path /tmp/hero-pressure --script res://tests/hero_encounters_smoke.gd
python tools/build_hero_hud_fixture.py /tmp/hero-pressure-hud
godot --headless --path /tmp/hero-pressure-hud --editor --import --quit
godot --headless --path /tmp/hero-pressure-hud --script res://tests/hero_hud_inventory_smoke.gd
```

롤백은이번패치커밋revert. main은명시요청시에만병합한다.
