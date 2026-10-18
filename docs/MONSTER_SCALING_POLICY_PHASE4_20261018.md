# 하드코딩 정리4차 후속: 몬스터 추가 배율 바인딩 — 2026-10-18

## 기준과 범위
- 작업 전 feature/stage10-astra `e546bd85af8defb2806e7d7330814797e0770348`, origin/main `10c9805842d745412ffe9b45e822896001ef27cb`, clean 상태 확인. 별도 worktree에서 작업하며 main 병합 없음.
- 오크의 추가 HP 배율 선택 3곳(UI 표시/신규 소환/기존 개체 강화 재계산)과 폭탄쥐의 도화선·폭발 피해 선택만 데이터화.
- 기존 orc_hp_multiplier 상태/증강 쓰기 경로는 호환 유지. 특수 소환 위치·해골 생존 등록·거미 둔화·고유 기술/AI/수치/성장/보상·저장·대사/오디오 변경 없음. 전투 전체를 한 번에 정리하지 않음.

## 구조
- MonsterCatalog의 해당 몬스터 항목에 runtime_scaling metadata. HP 배율의 Battle property, 도화선/폭발 피해의 actor property를 지정하고 Battle은 공용 조회로 처리.
- 기존 ID 비교 7곳 제거(HP3, 도화선/폭발4). 중립/알 수 없는 ID는 공유 빈 프로필과 배율1.0. Catalog 프로필을 공유하며 호출자는 변경하지 않음. 배율 값은 매 적용 시 읽어 강화 변경을 즉시 반영.
- 모든 배율 연산 순서·최소값·반올림·null 검사·최대 HP 회복 시점·정예 시각/기술 등록 순서는 유지. 도화선/폭발의 raw metadata 명명은 기존 augment_raw_<property> 규칙을 그대로 사용.
- 신규 _process/전체 스캔/프레임 배열/캐시 수명/풀 반환 변경 없음. 소환/강화 적용 시 고정 개수의 Dictionary lookup 및 설정된 property만 조회. 성능 개선율을 주장하지 않음.

## 검증
- Godot4.5.1 headless에서 수정 전 SHA/수정 후 실제 Battle의 정예 변환·일반 강화 함수 전체를 추출해 비교. 표시/소환 HP 계산 블록도 원문 추출. Catalog 및 의존 데이터 실제 코드 사용, scene preload만 null로 대체.
- 일반/용사 모드, runtime-stat actor 유무, 오크/폭탄쥐/해골/슬라임/불명 ID, 음수/0/극소/기본/강화 배율, raw 존재/누락, 정예→강화→반복 강화의 결과와 적용 시점 trace 비교. null 선택 property 건너뛰기 및 기존 Catalog 데이터 전체 동등성 포함.
- 정상732 + raw 누락732 = 1464검사 PASS. 정상 경로 script/runtime 오류0. 누락 경로는 Godot get_meta(key,null)의 기존 진단이 before96/after96으로 동일(도화선/폭발 raw 메타 누락); 새 회귀가 없음을 확인했으며 기존 진단 동작은 수정하지 않음.
- 나머지 Battle 함수228개 본문 동일. Catalog 데이터는 runtime_scaling 두 항목을 제외하면 이전과 동일. monster_balance_audit issues0, 변경 함수/카탈로그 fixture parse, Python compile, git diff --check 통과.
- 외부 스케일 적용기/시각/엘리트 등록기/플레이어는 fixture stub. 전체 Battle scene 실행, 실제 풀 복귀/물리 충돌/AI·완주·실기PC/Android·FPS는 미검증.

## 재현
1. `python tools/build_monster_scaling_policy_fixture.py /tmp/monster-scaling --baseline e546bd85af8defb2806e7d7330814797e0770348`
2. Godot editor import 후 `--headless --path /tmp/monster-scaling --script res://smoke.gd`.
3. 같은 실행 뒤 `-- --missing-meta`를 추가하면 누락 raw 경로 비교. 누락 경로 진단은 위의 기존 get_meta 동작으로 예상됨.

## 다음 소범위 후보
- 몬스터 고유 소환 위치와 생존 등록 분기를 각 기능의 정책/레지스트리로 분리할지 조사. 실제 의미가 다른 기술 실행부를 무조건 공용화하지 않음.
