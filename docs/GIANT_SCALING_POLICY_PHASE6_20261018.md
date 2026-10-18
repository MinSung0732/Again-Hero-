# 하드코딩 정리6차: 거미 둔화·거대화 적용 대상 — 2026-10-18

## 기준·범위
- 수정 전 HEAD/feature/stage10-astra `e7e31cef8182a052ed27980cfbbd3355dbeec6b4`, origin/main `6f22053f462e1176ec2ecde131d589d5491791b2`, clean 상태 확인 후 작업. main 병합 없음.
- 거미의 신규 소환 둔화 배율 바인딩, 거대화의 기본 공격10종·원거리5종 판별, 거미 거대화 둔화 property를 데이터화. ID/list 선택6곳을 공용 조회/계산으로 교체.
- 폭탄쥐 거대화/소환의 별도 폭발·보상 규칙, 거대화 확률/해금/계수, 합체/부활/특수기술/AI/진행·보상/저장/리소스는 변경하지 않음.

## 구조
- MonsterCatalog.giant_scaling: basic_attack/ranged_attack/stat_properties. 기존10종과5종만 명시적으로 opt-in. role이나 rarity로 임의 확장하지 않으며 미등록/불명 ID의 기존 기본 처리 유지.
- Battle의 GIANT_RANGED_MONSTER_IDS와 함수 내부10종 배열 제거. 거대화 기본 스탯과 기존 개체 승격이 같은 Catalog 원거리 분류를 참조.
- runtime_scaling.spawn_property_multipliers는 actor property → Battle multiplier property 매핑. 거미 slow_duration → spider_slow_duration_multiplier만 선언. 신규 소환의 기존 위치에서 nullable 값만 곱하며 배율은 현재 Battle 값을 판독, 결과/개체/배율을 캐시하지 않음.
- 기존 거대 배율 적용 → augment_raw 원본 기록 → 신규 소환 둔화 배율 적용 순서를 보존. 이미 살아 있는 개체의 둔화 재계산 범위는 확대하지 않음. 신규 거대화와 기존 개체 승격의 서로 다른 처리도 통일하지 않음.
- 기존 HP1.54/stat1.28/크기2.0, 원거리 사거리/투사체 크기 배율, 반올림·최소값·null 분기·거대/엘리트 거부·공간그리드 무효화·refresh 호출 위치 유지.
- 공유 프로필·빈 Dictionary/Array 사용. 매 프레임 처리/스캔/instantiate/free/풀 수명주기 변경 없음. 신규 소환/거대화 시 고정 조회와 선언된 property만 순회. 프레임 성능 개선율은 측정하지 않음.

## 검증
- Godot4.5.1 headless: 수정 전/후 실제 _apply_giant_monster_base_stats와 promote_monster_to_giant 전체, 신규 소환의 실제 raw 기록 블록·기존 둔화 블록/신규 helper를 원문 추출해 비교. Catalog 의존 데이터30개 실제 사용, scene preload는 null 대체.
- 전체65종+불명 ID, 값8종(음수/0/극소/최소값 경계/반올림 경계/일반), 둔화 배율4종. 기본 거대화 직후/원본 기록+소환 배율 후/중복 승격 거부/일반 소환/기존 개체 승격의 property·metadata·scale·refresh trace·그리드 상태를 비교.
- 같은 fixture Node를 ID·배율별로 재설정해 재사용. null 선택 property/거미 둔화 건너뛰기, 엘리트·ID 불일치·무효 Node의 승격 거부도 확인. 신규10829검사 PASS, 정상 경로 script/runtime 오류0.
- 저작 데이터는 giant_scaling10항목과 거미 runtime_scaling 항목을 제외하면 이전과 동일. 기본 공격/원거리 대상이 수정 전 소스 목록과 일치. 나머지 Battle231함수 본문 동일, _spawn_monster 전체는 기존 둔화 블록을 helper 호출로 대체한 것 외에 동일.
- 5차 회귀10571, 4차 정상732+raw누락732 PASS. 합계22864검사. 기존 raw 누락 get_meta(key,null) 진단은 before96/after96으로 동일하며 이 작업에서 수정하지 않음. Catalog 밸런스 감사 issues0, Python compile/git diff --check 통과.
- 과거 단계 fixture에 이후 단계 변경 함수를 명시적으로 허용하는 옵션과 추가 metadata 제외를 적용. 기본 정적 감사는 유지하고 기존 스탯/정책 검증은 생략하지 않음.
- 이 테스트의 actor는 generic Node2D이며 일반 강화 refresh는 입력 상태를 기록하는 stub. 실제 몬스터 actor/전체 Battle scene·물리/풀·AI·15분 완주·실기PC/Android·FPS는 미검증. 실제 게임을 실행했다고 해석하지 않음.

## 재현
1. `python tools/build_giant_scaling_policy_fixture.py /tmp/giant-scaling --baseline e7e31cef8182a052ed27980cfbbd3355dbeec6b4`
2. Godot editor import 후 `--headless --path /tmp/giant-scaling --script res://smoke.gd`.
3. 5차 fixture의 기존 baseline80f0f69에 `--allow-changed-method _apply_giant_monster_base_stats --allow-changed-method promote_monster_to_giant --allow-changed-method _spawn_monster` 추가 후 기존 smoke 실행.
4. 4차 fixture의 기존 e546bd8 baseline/5차 허용 목록에 `--allow-changed-method _apply_giant_monster_base_stats --allow-changed-method promote_monster_to_giant` 추가 후 기본 및 `-- --missing-meta` 실행.

## 다음 소범위 후보
- 폭탄쥐의 신규 소환/거대화 property 배율과 두 종류 EXP 보상 선택. 서로 다른 계산 시점을 보존하는 범위로 별도 비교.
