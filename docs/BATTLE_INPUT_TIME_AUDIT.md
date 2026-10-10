# 전투 입력·시간 의존 경로 조사

기준: feature/stage10-astra `a3b3b7efbd332a17e4b62556179ed40ca9e0f98c`.
소스에서 확인한 범위이며 전체 프로젝트 런타임/성능 측정 결과는 아니다.

## 입력 경로와 소유권

| 입력 / 발생 원인 | 현재 경로 | 이번 처리 / 후속 작업 |
|---|---|---|
| 자동 소환 카드 | main `_on_*` → battle `try_summon` | 기존 명령 1 유지 |
| 수동 소환 터치 | 화면→월드 좌표 → `try_summon_at_position` | 명령 2 유지, 기존 범위 검사 실행부 담당 |
| 초월 소환 | `try_summon_transcendent` | 명령 3 유지, 해금/1회 제한 실행부 담당 |
| 마왕 포위 스킬 / 방향 | main 스킬/방향 확인 → `try_use_demon_ultimate` | 명령 4 유지 |
| 마왕 증강 확인 | main 표시 후보 → `choose_demon_augment` | 신규 명령 5, 표시 후보 revision 전송 |
| 마왕 증강 재뽑기 | main 버튼 → `reroll_demon_augments` | 신규 명령 6, 재뽑기 횟수와 revision 검증 |
| 엘리트/돌연변이 선택 | main → `spawn_selected_mutation` | 명령7로 연결. 표시 후보 revision 검사, legacy void API 유지 |
| 용사 기본공격·스킬·증강 | hero 내부 AI 판단 | 플레이어 용사 action port 구축 후 명령 경계 연결 |
| 마왕 스킬 연속 소환 | `_process_demon_ultimate_spawn_queue` | 확정 스킬의 내부 결과. 매 개체를 새 사용자 명령으로 만들지 않음 |
| 스테이지 공세/변이 | stage director / reinforcement queue | 전투 내부 이벤트. 미래 서버에서만 발생 |
| 사망 분열·추가 소환·장판·상태이상 | combat callbacks / 각 runtime | 내부 규칙 이벤트, 대상 ID+generation 이주 예정 |
| 튜토리얼 강제 선택창 | `open_tutorial_augment`, `open_tutorial_elite` | 기존 경로 유지, 일반 후보 경로 재사용. 네트워크 수신 허용 금지 |
| 테스트 초월 해금 | `debug_unlock_transcendence` | 기존 LocalTestMode 제한 유지. 사용자 네트워크 명령에 등록하지 않음 |
| 일시정지·소개·상세창 | main → `set_external_pause` | 솔플 화면 제어. PvP에서는 로컬 화면만 처리하도록 추후 분리 |
| 팀편성·카메라 조작 | loadout 초기 설정 / hero 카메라 메서드 | 세션 설정/표시 제어, 전투 액션과 분리 |

현재 역할 표는 마왕 명령만 허용하며 용사·대전 모드는 실행 차단한다. 현재 7개 마왕 명령을 구현했다. 용사 AI 액션·튜토리얼/디버그/내부 이벤트 경로는 별도로 남아 있다. 다른 모드 활성화 전에 직접 실행 경로 전체를 재조사한다.

## 후보 revision 계약

protocol v2에 `choice_revision` 필드를 추가했다. 일반 소환/스킬은 0, 마왕 증강 선택/재뽑기는 양수다. 빈 ID 선택, ID를 담은 재뽑기, 좌표/방향을 담은 후보 명령은 거절한다. 실제 후보 일치 여부는 battle 실행부에서 확인한다.

revision은 새 후보 공개·재뽑기·선택 닫기·전투 재시작 때 증가한다. 후보 ID가 우연히 같아도 다른 offer다. main은 표시할 때 revision을 저장하고 확인/재뽑기에 넘긴다. 실행 직전에 현재 revision과 다르면 효과 적용·리롤 소비·창 닫기가 일어나지 않는다. 선택 성공 후 연속 레벨의 창이 동기적으로 열리는 기존 흐름을 유지한다.

기존 호출 호환을 위해 revision 생략은 현재 후보를 사용한다. 이 편의 API는 로컬 호출 전용이며 미래 네트워크 수신기에서 사용하면 안 된다. 네트워크 입력은 표시된 revision을 반드시 전송하고 서버가 검사한다. routing off도 후보 revision 및 미래 모드 차단을 우회하지 않는다.

## 시간 의존과 분리 순서

| 경로 | 현재 시간 기준 | 이주 정책 |
|---|---|---|
| RunMetrics / 제한시간 / stage director | battle `_process` delta, RUN_TIMER pause domain | BattleRunClock으로 경과 시간 분리 완료. 기존 업데이트 빈도·delta·pause gate 유지 |
| 지휘력 회복 | `_process` delta, COMMAND_REGEN domain | 독립 도메인 유지, run timer 정지와 동일하다고 가정하지 않음 |
| 마왕 스킬·아군 보조 runtime·소환 큐 | `_process` delta, DEMON_RUNTIME domain | 액터별 회귀 후 공통 시뮬레이션 driver로 이동 |
| manual spawn 경고·HUD·선택 입력 가드 | 화면 delta / ticks_msec | 표시/입력 안전장치에 유지 |
| spawn resource warmup·경험치 묶음 분산 | ticks_usec 예산 / await process_frame | 프레임 분산 로딩/표시 경로 유지, 규칙 시계로 변환하지 않음 |
| 경험치 자석 활성 남은 시간 | battle wall ticks_msec + orb physics delta | 두 기준 혼합. pause/슬로우 회귀 후 함께 이주; 이번 패치에서 변경하지 않음 |
| 용사 연금술 배치/폭발 | hero await create_timer | 액터 generation/취소 가능한 예약 이벤트로 분리 필요 |
| 용사 일부 둔화 meta | wall ticks_msec | 대상 풀 재사용과 pause 의미 확인 후 규칙 deadline으로 이동 |
| 용사 오디오 rate limit | wall ticks_msec | 소리 재생 보호용, 규칙 시계로 옮기지 않음 |
| 전략 분석·증강 획득/관찰 시각 | RunMetrics.elapsed_seconds | 호환 접근 유지, 전투 run 시계에 연결 |
| 탐색보상·일일/주간 초기화 | 계정 벽시계 | 전투 시계와 분리 유지 |

난수는 소환 위치·사망 분열·아이템·stage 이벤트·용사 회피·증강·스킬에 걸쳐 있다. 현재 글로벌 RNG를 일괄 대체하면 기존 확률 소비 순서가 바뀔 수 있어 이번 패치에서는 변경하지 않는다. 다음에는 규칙/연출 호출을 분류하고 동일 조건의 회귀 기록을 만든 뒤 분리한다. 고정 tick만으로 물리 결과의 플랫폼 간 일치를 보장하지 않는다.

## 검증·실행 방법

```bash
python3 tests/build_battle_boundary_fixture.py /tmp/again-battle-fixture
godot --headless --path /tmp/again-battle-fixture --script res://tests/battle_command_router_smoke.gd
godot --headless --path /tmp/again-battle-fixture --script res://tests/battle_augment_boundary_smoke.gd
```

fixture는 실제 battle public wrapper/dispatch와 증강 실행·다음 후보 공개 함수를 추출한다. 효과 적용/카탈로그/화면/실제 몬스터는 명시적 spy로 대체한다. 후보 ID가 같은 재뽑기와 연속 레벨, 오래된 선택·리롤, 최대 스택·특수 중복, pause 유지/해제, bool 실패 전파, on/off 및 미래 모드 차단을 검증한다. 실제 증강 수치나 몬스터 갱신 결과·전체 UI 렌더링은 이 테스트의 대상이 아니다.

전체 게임 후속 확인: 증강 확인·취소/상세·재뽑기, 연속 레벨 후보, 특수 후보 소진→엘리트 대체, 튜토리얼 후보, 일시정지, 마왕 스킬·소환. 후보 업데이트 시 main의 표시 revision이 같이 바뀌는지 확인한다. 신규 저장 포맷·DB 변경은 없다.

## 후속 — 엘리트 선택 명령 (2026-10-10)

protocol v3 명령7 MUTATION_CHOOSE. `try_choose_mutation(id, revision)`은 bool 반환, 기존 `spawn_selected_mutation(id)` void는 로컬 호환 wrapper로 유지한다. 새 후보·소비·재시작마다 revision 증가. main은 표시 revision 저장/전송하며 오래된 이벤트 카드를 클릭하면 숨기지 않고 거절한다. router는 양수 revision/ID와 빈 좌표·방향을 요구한다. 후보 확인·fallback 스탯·스폰 거리·소환 실패 신호·pause 해제·deferred 다음 증강은 기존 흐름을 유지한다. 실패한 소환도 기존처럼 선택을 소비한다.

독립 Godot4.5.1 router130/증강79/실제 엘리트 경계 함수58검사 통과. fixture는 actual public/선택/open 함수와 explicit 카탈로그·director·소환 spies를 사용한다. 전체 엘리트 몬스터 스탯/전투/UI/모바일은 미검증이다. 추가 실행: `godot --headless --path /tmp/again-battle-fixture --script res://tests/battle_mutation_boundary_smoke.gd`.
