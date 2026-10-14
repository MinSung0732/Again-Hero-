# 보물상자 디자인·스테이지별 물량 — 2026-10-14

첨부 image(20261014-112902).png의 가로3칸·금색 중앙 강조·이름/설명·보라색 계속 구조를 반영한다. 예시의 특정 무기명·레벨·효과를 고정하지 않고 실제 보유 목록과 하나의 확정 receipt를 사용한다. 기존 PNG 프레임을 캐시한 nine-patch와 무기별 아이콘을 재사용한다. 진행 중 새 카드/텍스처를 매 프레임 생성하지 않는다.

본문은 스크롤하고 76px 계속 버튼은 하단에 고정한다. 진행 중 닫기 차단, 전투/패드 정지, backdrop 입력 차단, 적용 후 계속 활성화, 종료 시 backdrop 제거와 입력 재개. 실패 시 실패 문구와 재개 버튼을 제공한다. 회복/보조/진화/무기 우선순위 및 serial 단회 적용은 기존 runtime이 결정한다.

| 스테이지 | 변경 전 전체 상한 | 변경 후 전체 상한 |
|---|---:|---:|
|1|72|72|
|2|72|76|
|3|72|80|
|4|72|84|
|5|72|88|
|6|72|92|
|7|72|96|
|8|72|100|
|9|72|104|
|10|72|108|

쉬움/어려움 공통 천장. 입력 stage는1~10범위로 제한한다. 일반 소환 상한은 min(전체 상한, floor(시간별phase.limit×기존stage pressure×어려움1.2))-2이며 이벤트/정예를 위한 예약칸을 남긴다. 예: 쉬움10 마지막 phase는 floor(72×1.495)-2=105, 어려움10은108-2=106. 전체 active registry 천장은 이벤트/정예/분열에도108이다. 초반부터108마리를 채우는 방식은 아니다.

Battle.get_population_limit도 용사 모드에 공통 계산기를 사용해 지휘력100의 추가 차단을 제거한다. 마왕 모드는 기존 지휘력 기반 인구수를 유지한다. 일반·정예·포위·분열은 최종 _spawn_monster 전체 개체 제한을 사용하므로 우회 소환도 상한을 넘지 않는다. 900초 이후 보스만 허용하는 기존 가드, 한 tick 포위 생성최대4, 벽8개 풀과 용사 기술/탄환 풀 유지. 확장 상한은108로 제한했고 O(1) 정수 계산과 캐시만 추가했다.

상자 일반200처치/첫정예보상/이후정예·대형4처치, 활성상자2개, 전투당 강화횟수 무제한 정책 유지.

검증: build_hero_chest_design_fixture.py → hero_chest_design_smoke.gd 52; build_hero_hud_fixture.py → hero_hud_inventory_smoke.gd107; build_hero_encounter_fixture.py → hero_encounters_smoke.gd446, hero_opening_pressure_smoke.gd6179. 총6784 headless 격리검사. 실 Battle 함수 추출은 일반 factory prefix/encounter/population getter를 사용하며 나머지 전투 host는 mock이다. 전체게임 GPU/Android/실전 완주 밸런스 검증과 구분한다.
