# 하드코딩 정리8차: 증식·추가 소환 정책 — 2026-10-18

## 기준·범위
- 수정 전 HEAD/feature/stage10-astra `ea61cad9fbf2e66084c4d9f309abe50b8290c393`, origin/main `6f22053f462e1176ec2ecde131d589d5491791b2`, clean 상태 확인. 작업 브랜치만 변경, main 병합 없음.
- _process_special_death_spawn의 슬라임/폭탄쥐와 _spawn_extra_normal_summon_monsters의 슬라임/박쥐 ID 분기4곳 제거. 기존4개 특수증강에 의한 추가 개체 생성만 공용화.
- _on_monster_died의 레거시 슬라임 확률 분열·밴시/유령 반응, 실제 보상 지급/환급/개체 등록 해제·초월 연출, 일반 소환 entry와 _spawn_monster/EXP 처리, AI·계정/서버·아트/오디오는 변경하지 않음.

## 구조와 유지 규칙
- MonsterCatalog.secondary_spawns에 on_death/on_normal_summon 이벤트 규칙. 증강 ID·count key/default/minimum, 박쥐 확률/난수 count 범위, 반경34/36/38/0, HP/피해 fallback0.5, mission_summon 및 자식 metadata를 선언. 실제 증강 선택/설정값은 기존 Battle cache getter에서 매 이벤트 판독, 결과 캐시를 추가하지 않음.
- 기존 사망 gate(일반 개체 또는 allow_special_death_split), 폭탄쥐 self_destruct 제외를 유지. 슬라임의 다른 사망 원인 처리 범위는 확대/축소하지 않음.
- 추가 슬라임만 allow_special_death_split=true를 부여. 사망으로 생성한 자식은 재허용하지 않으므로 추가 슬라임→잔여 점액 자식 이후 재귀가 차단되는 기존 의미 유지. 박쥐/폭탄쥐도 기존 split_child=true로 생성.
- _spawn_secondary_monsters는 증강 config1회 조회, 기존 chance clamp/randf 비교, min/max 보정/randi_range, 결정된 count만 순회. 기존 난수 함수와 호출 시점을 유지하며 고정 min=max에서도 randi_range를 생략하지 않음.
- 배치 공식 TAU*(index+1)/(count+1), 반경과 매 자식 clamp 동일. 원점에 생성하는 박쥐에는 원형 offset을 계산하지 않음. clamp→modifier config 판독→spawn→자식 metadata 적용 순서도 유지.
- 자식마다 독립 modifier Dictionary를 생성해 spawn callback의 수정이 다음 자식에 전파되지 않음. 기존 비용0/split_child=true 호출, 실패해도 후속 시도를 계속하는 동작 유지. 실제 비용/EXP 코드 자체는 그대로.
- 공유 규칙/빈 Dictionary·Array 사용. 매 프레임 루프·그룹 스캔·O(n²)/추가 instantiate/free·풀 변경 없음. 기존 자식당 modifier1개 생성은 유지하고 추가 개체 수/생성 횟수를 늘리지 않음. 성능 개선율은 측정하지 않음.

## 검증
- Godot4.5.1 headless: 수정 전 SHA/수정 후 실제 두 함수와 공용 helper를 원문 추출. 실제 clamp/성벽 margin 및 Catalog 의존31개(DemonAugment 포함) 사용, scene preload만 null.
- 저작 데이터는 secondary_spawns3항목 외 이전과 동일. 네 규칙의 증강 ID/owner/effect_type을 실제 DemonAugmentCatalog와 대조. 프로필 반복 조회는 공유 참조이며 불명 ID는 중립.
- 전체65종+불명 ID의 실제 증강 config, 선택된3종+불명의 누락/부분/음수/0/소수 count, 확률 범위 밖·기본값/0·1·0.15·0.5, min>max 등의 설정을 비교. seed4종·split/allow4조합·normal/self_destruct/consumed 사망 원인 포함.
- spawn 요청의 ID/순서/좌표/cost/split flag/modifiers, 성공 자식 metadata, config 조회·clamp 호출 순서, 이벤트 후 RNG3개를 비교. 자식별 modifier 참조 독립성을 확인.
- 소환 실패 전체/부분, spawn callback의 modifier/config 변경, clamp 중 config 변경, spawn 중 RNG 소비도 입력 어댑터로 재현해 전후 일치. 실제 개체 제한 시스템 검증으로 해석하지 않음.
- 연쇄 시나리오: 추가 슬라임2기→사망 자식4기 이후 추가 증식 없음, 폭탄쥐 사망 자식2기 이후 차단, 박쥐 추가3기 이후 사망 증식 없음. 신규3948검사 PASS.
- 7차 소환 수치·독립 EXP 필드/거대화 회귀2961 PASS. 합계6909검사, 정상 경로 script/runtime 오류0. 밸런스 감사 issues0, Python compile/git diff --check 통과.
- 나머지 Battle234함수 본문 동일: 보상/환급·일반 소환 entry/_spawn_monster·캐시 getter까지 그대로임을 확인. 이전 단계 fixture에는 별도로 검증한 후속 두 함수 변경을 명시적으로 허용하고 새 metadata만 authoring 비교에서 제외, 기본 감사는 유지.
- 실제 소환/증강 config 공급은 통제 어댑터, 자식은 metadata 확인용 Node2D. 실제 몬스터 actor/전체 Battle scene·물리·개체 제한·풀·XP 지급/미션 카운트·AI·실기PC/Android·FPS는 미검증. 테스트상 zero-cost/split/mission 인자 보존과 실제 EXP 지급 검증을 구분함.

## 재현
1. `python tools/build_secondary_spawn_policy_fixture.py /tmp/secondary-spawn --baseline ea61cad9fbf2e66084c4d9f309abe50b8290c393`
2. Godot editor import 후 `--headless --path /tmp/secondary-spawn --script res://smoke.gd`.
3. 7차 fixture의 기존 db2ca40 baseline에 `--allow-changed-method _process_special_death_spawn --allow-changed-method _spawn_extra_normal_summon_monsters` 추가 후 기존 smoke 실행.

## 다음 소범위 후보
- 사망 처리에 남은 레거시 확률 분열과 고유 사망 반응 바인딩. 기존 보상/환급/등록 해제와 난수 순서를 보존하는 범위로 별도 조사.
