# 하드코딩 정리7차: 자폭형 소환·거대화 배율 — 2026-10-18

## 기준과 범위
- 수정 전 HEAD/feature/stage10-astra `db2ca4013e334ed365649e2a8b8597f44e46a497`, origin/main `6f22053f462e1176ec2ecde131d589d5491791b2`, clean 상태 확인. 작업 브랜치만 변경, main 병합 없음.
- 폭탄쥐 거대화1곳과 신규 소환 도화선/폭발 피해2곳의 ID 분기를 데이터 기반 계산으로 변경.
- 실제 사망/피해/EXP 지급·중복 처리/새끼 소환, 승격 규칙/AI·밸런스/저장/아트·오디오 변경 없음.

## 구조와 유지 규칙
- MonsterCatalog.bomb_rat.giant_scaling.property_rules에 기존 적용 순서대로 자폭 범위, 도화선, 용사 처치 EXP, 자폭 EXP, 폭발 반경, 폭발 피해를 선언.
- 공용 _apply_giant_stat_property_rules는 stat 배율 곱셈/역수, 정수 반올림, 선택적 최소값을 처리. 도화선은 기존 나눗셈 후 최소0.10, 세 정수 값은 기존 round→int→최소1. 누락 minimum은 임의 clamp를 추가하지 않음. 거대 배율1.28 및 다른 기존 계수는 유지.
- 규칙은 공유 Catalog 상수이며 소환 시점에만 순서대로 순회. property 읽기/쓰기를 한 번씩 수행해 이전 연산 순서 유지. 이전 공통 거대화 처리·거미 둔화 이후, body scale 변경 이전에 호출.
- 신규 소환은 4차 runtime_scaling.fuse_property/explosion_property를 재사용. 서로 다른 원래 위치에서 null 검사·희귀/컬렉션/전역/몬스터 증강·마왕레벨 배율을 적용. 두 공식을 하나로 합치거나 거대화/정예/승격 시점까지 통일하지 않음.
- augment_raw 원본 기록과 EXP/visual modifier·분열 자식 EXP0 처리는 원래 위치 그대로. 두 XP property를 독립 유지하며 실제 지급/처치 원인 판별을 변경하지 않음.
- 신규 _process/전체 그룹 스캔/프레임별 배열·노드 생성/풀 변경 없음. 거대화 시 등록된 고정 개수의 규칙만 순회. 성능 개선율은 측정하지 않음.

## 검증
- Godot4.5.1 headless: 수정 전 SHA/수정 후 실제 거대화 함수 전체 및 신규 소환의 희귀/컬렉션 입력·raw 캡처부터 EXP/분열 처리까지 전체 수치 블록을 원문 추출해 비교. Catalog 의존 데이터30개 실제 사용, scene preload는 null 대체.
- 65종+불명 ID, 입력 배율5종, 일반/거대·분열 자식 조합. 각 단계 property 값·metadata·scale뿐 아니라 모든 property get/set의 필드명·순서·타입/값과 RNG 소비를 비교. 각 속성 기본값은 서로 다르게 설정해 필드 교환/두 XP 혼용을 탐지.
- 거대화6속성을 개별로 음수/0·최소값 경계·반올림 경계·일반값으로 변경. 전역 피해/공격 간격·마왕레벨 배율 변경을 동일 actor에 재설정해 비교. 신규 소환 nullable 도화선/폭발 피해도 건너뛰기 유지.
- 신규2961검사 PASS. XP 기본 입력19.5/2.5의 거대화 결과25/3, 폭발 피해28.5→36과 도화선0.17→0.1328125도 독립 확인. 정상 경로 script/runtime 오류0.
- 이전 거대화/승격 회귀10829 + 정예/강화 정상732·raw누락732 PASS. 합계15254검사. 기존 누락 raw의 get_meta(key,null) 진단은 before96/after96으로 동일하며 이 단계에서 수정하지 않음.
- Catalog는 폭탄쥐 giant_scaling 선언 외 이전 저작 데이터와 동일. 나머지 Battle233함수 본문 동일. 전체 _spawn_monster 외곽은 두 배율 바인딩 블록을 제외하면 동일. 밸런스 감사 issues0, Python compile/git diff --check 통과.
- 6차 fixture에는 이후 별도 감사된 소환 변경을 명시적으로 허용하는 옵션과 신규 공용 helper 추출을 추가. 기본 정적 감사는 그대로 유지.
- actor는 get/set 추적용 generic Node2D이며 마왕레벨 적용기는 호출을 기록하는 stub. 실제 폭탄쥐 actor/폭발 판정·죽음 원인별 EXP 지급/전체 Battle/물리·풀/AI·실기PC/Android·FPS는 미검증. 전체 게임 런타임 검증으로 해석하지 않음.

## 재현
1. `python tools/build_bomb_scaling_policy_fixture.py /tmp/bomb-scaling --baseline db2ca4013e334ed365649e2a8b8597f44e46a497`
2. Godot editor import 후 `--headless --path /tmp/bomb-scaling --script res://smoke.gd`.
3. 6차 fixture의 기존 e7e31ce baseline에 `--allow-changed-method _spawn_monster`를 추가하고 기존 smoke 실행.
4. 4차 fixture는 6차 문서의 허용 목록과 동일하게 생성해 기본 및 `-- --missing-meta` smoke 실행.

## 다음 소범위 후보
- 사망 시 새끼 소환/일반 소환 후 추가 개체의 ID 분기. 개체 수·코스트/EXP·사망 원인·분열 재귀 차단 조건을 함께 비교하는 별도 범위로 조사.
