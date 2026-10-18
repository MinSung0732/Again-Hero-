# 전투 최적화 3단계 — 2026-10-17

현재 상태: **사용자 승인 후3단계 검증 완료 / 합의한 작업 범위100% / 최종 브랜치 feature/stage10-astra**.

사용자 지시: 전체 작업을 세 단계로 나누고, 각 단계 완료 뒤 다음 단계에 대한 승인을 받는다. 최종100% 완료 때 현재 사용 중인 `feature/stage10-astra`에 커밋·푸시한다. 이 지시가 AGENTS의 매 작업 커밋 기본 규칙보다 우선한다. 1/2단계에서는 커밋·푸시하지 않는다. 33.33%는 합의한 작업 분량의 진행률이며 성능 개선율이나 소요 시간의 균등 분할이 아니다.

기준: 로컬 HEAD `720e57597aa0dcc5d4f6fd0c5d34b0aa73a094ec`, 원격 feature `b1e70d279c587b6aa8d3e8f6a7a164c63e99f7a8`는 동일한 트리. origin/main `10c9805842d745412ffe9b45e822896001ef27cb`. 시작 시 작업 트리 깨끗함.

## 단계와 승인 경계

| 단계 | 범위 | 완료 기준 | 상태 |
| --- | --- | --- | --- |
| 1 · 33.33% | 반복 가능한9스테이지 CPU 기준·선택적 계측·공간 후보 조회 재사용 | 기존 후보/순서·공격 결과 보존, 전후 측정/안전성·온라인 경계 검사 | 완료 |
| 2 · 66.67% | 피해·연쇄·다단히트의 반복 계산/후속 처리 개선, 밀집 물리 비용 추가 분해 | 피해/치명/흡혈/사망/세대·순서 보존과 실제 부하 비교. 계측에 따라 다음 최적화 우선순위 확정 | 승인받아 완료 |
| 3 · 100% | 이동·표현 병목 개선과 통합, 서버 계산/상태 직렬화 부하 검증 | 다중 방·실제 전투·기능 회귀, 남은 실기 검증 항목 명시, 최종 검토 후 커밋·푸시 | 승인받아 검증 완료 |

2단계의 피해 큐/3단계의 경량 이동·배치 렌더링은 동작 보존과 계측 결과를 보고 구현 범위를 확정한다. 프레임 끝 피해 처리, 전체 ECS 전환, 물리 무조건 제거를 먼저 강제하지 않는다. 이계5레벨 슬롯 성장·문지기 자리·모달 정지·용사별 특색·범위/타격 수·보상/저장 정책을 유지한다.

## 1단계 구현

- `CombatPerformanceProbe`: 기본 비활성. Battle/용사 물리/무기 tick/그리드/공간 조회/온라인 snapshot의 CPU 호출 수·평균·p95·최대를 기록한다. 구간당 최근512샘플의 고정 PackedArray만 유지한다. 보고서 생성 시에만 정렬/Dictionary를 만든다. 프레임 간격은 CPU 시간이 아니며, 중첩된 구간 시간을 합쳐 전체 프레임 시간으로 해석하지 않는다.
- `SpatialCandidateCache`: Battle마다16개의 후보 Array와 한정된 인덱스를 보유한다. 같은 공간 스냅샷에서 같은 패딩된 칸 사각형을 다시 조회할 때 후보 목록만 재사용한다. 스냅샷 revision 변경 시 폐기한다. 시작/리셋 시 이전 세션 내용도 제거한다.
- 후보 순서는 기존 x→y→bucket 순서를 유지한다. 캐시 적중 때도 유효/삭제예약 상태를 확인한다. 숨김·HP·현재 위치/실제 반경·세대 판정은 기존 소비자가 그대로 수행한다. 최근접 표적/최종 피해 결과를 캐시하지 않으며, 호출자 scratch 수정이 캐시를 바꾸지 않는다.
- 기존 `_process`, `_physics_process`, `tick`, `snapshot` 진입점은 유지하고 계측 외 로직은 본문 함수로 그대로 이동했다. 서버 전송 필드·주기·권위·인증은 변경하지 않았다.
- 각 Battle의 `combat_profiling_enabled`를 켜거나 `battle.combat_profile.start()`로 캡처를 시작한다. `stop()` 후 `report()`를 호출한다. `battle.monster_candidate_cache.enabled=false`는 기존과 같은 후보 순회의 비교/복귀 경로다. 일반 플레이에는 보고서 생성·출력·파일 쓰기가 없다.

## 전후 CPU 결과

Godot4.5.1, Linux headless. 1배치=12개 스냅샷×48조회=576조회, 준비 실행 제외 후7회. 전후 실행 순서를 번갈아 측정했다. 표의 시간은 **576회 조회 전체의 CPU 시간**이며 프레임 시간이나 FPS가 아니다. 분산/밀집100/300/600은 합성 자료이며 실제9스테이지 상한208을 늘리지 않았다.

| 조회 배치 | 이전 중앙값 | 이후 중앙값 | 변화 |
| --- | ---: | ---: | ---: |
| 분산 100개체 | 2.467ms | 0.839ms | 감소 66.0% |
| 분산 300개체 | 13.591ms | 9.968ms | 감소 26.7% |
| 분산 600개체 | 23.509ms | 19.610ms | 감소 16.6% |
| 밀집 100개체 | 16.143ms | 13.752ms | 감소 14.8% |
| 밀집 300개체 | 40.937ms | 37.280ms | 감소 8.9% |
| 밀집 600개체 | 78.731ms | 76.971ms | 감소 2.2% |
| 재사용 없는 빈 조회 | 2.328ms | 2.577ms | 증가 10.7% |

반복 배치의 캐시 적중은516/576이다. 재사용 없는 경우의 소폭 오버헤드도 그대로 공개한다. 단일 호스트 측정은 CPU 스케줄링 영향을 받으므로 이 비율을 실제 Android FPS 개선율로 옮겨 해석하지 않는다. 원본 샘플: [query_cpu.json](optimization/20261017_phase1/query_cpu.json).

## 실제9스테이지 부하 진단

실제 Stage9 Battle/Hero/오크, 정화의 용사6무기 Lv10/MAX로48/120/208마리. 각 설정20물리 프레임 준비 후60프레임 캡처, 캐시 전후×3회=18캡처. 일반 적은10,000,000HP, 용사는 무적을 부여해 개체 수를 유지했고 자동 공세는 연결하지 않았다. 계정/성장/범위/공격 로직은 실제 소스를 사용한다. 프레젠테이션 누락분은 대역이다.

- 48개체: 물리 처리 평균의 캡처별 범위 14.66~1120.50ms, 용사 물리 함수 평균 1.38~1.57ms.
- 120개체: 물리 처리 평균의 캡처별 범위 25.78~36.30ms, 용사 물리 함수 평균 1.81~2.27ms.
- 208개체: 물리 처리 평균의 캡처별 범위 39.46~63.65ms, 용사 물리 함수 평균 2.44~2.91ms.

전체 물리 시간은 용사/무기 구간보다 크다. 남은 몬스터 이동·충돌·밀집 회피 비용을2단계에서 세분화할 근거이며, 아직 어느 하나가 정확히 몇%인지 확정한 것은 아니다. 별도 캡처는 인스턴스ID 기반 회피/RNG 및 실행 환경의 영향을 받으므로 전체 프레임 전후 성능의 인과 비교로 사용하지 않는다. **이번 캐시만으로 끊김이 해결됐다고 주장하지 않는다.** 원본: [stage9_cpu.json](optimization/20261017_phase1/stage9_cpu.json).

## 안전성 검증

- 원본 조회 함수 frozen fixture와400개 무작위 원/사각형·캐시 적중·호출자 수정·삭제·revision·저장 상한·통계2009검사.
- 실제 정화6무기 MAX,80마리,180프레임의 매프레임 HP 벡터와 난수 진행이 캐시 전후 완전히 일치. 숨김/사망/강제 이동/중간 소환 포함. 실제 계측/정지까지206검사.
- 별도 SubViewport 두 온라인 방의 후보/통계 분리, snapshot 내용·키 보존12검사.
- 기존 무기·공격·MAX·각성·수량·소환 성장/광역·5레벨 슬롯·정지·실제 온라인/WebSocket 회귀 포함 **10,715검사 통과**, 최종 실행 오류0. [요약](optimization/20261017_phase1/regression_summary.json).
- 실기 Android/GPU/렌더링/FPS/15분 완주·혼합 몬스터 전체 로스터·공용 인터넷/서버 동접은 미검증이다. 실제 피해/순서 검증과 headless 성능 진단을 구분한다.

## 재현

```bash
python tools/build_combat_phase1_fixture.py /tmp/hero-perf-phase1
GODOT --headless --path /tmp/hero-perf-phase1 --editor --import --quit
GODOT --headless --path /tmp/hero-perf-phase1 --editor --import --quit
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase1_smoke.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase1_stage9_smoke.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase1_online_smoke.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase1_benchmark.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase1_stage9_benchmark.gd
```

`GODOT`은 설치된 Godot4.5.1 실행 파일로 대체한다. fixture는 누락 표현과 사용하지 않는 몬스터 씬만 격리하고 실제 전투 함수는 보존한다. 성능 측정은 다른 회귀 실행과 동시에 돌리지 않는다. JSON은 fixture 전용 user 디렉터리에 생성된다.

## 2단계 구현 — 게임 전체 공통 경로

사용자가 “9스테이지 다단히트만이 아니라 게임 전체인지” 확인하고2단계 진행을 승인했다. 9스테이지는 실제 부하를 재현하는 사례이며 콘텐츠 전용 최적화 분기를 추가하지 않았다.

- `MonsterHitContext`: 출처→흡혈 런타임/대상HP 조회에서 별도 속성 존재 검사 뒤 다시 읽는 중복을 줄였다. 런타임·대상·HP를 전역 캐시하지 않는다. 현재 소유자/방/강화 수치와 매 타격 결과를 다시 읽는다. 기존 동기 호출, 중첩 피해의 메타데이터 복원, receipt, 보호막·과잉 피해를 제외한 흡혈, 반환값을 보존한다. 변경된 helper는22개 소비자에서 공유되며 용사 공용100무기·기존 투사체·소환수 및 몬스터 방어 전달에 연결된다. 일부 몬스터→용사 직접 공격은 이 helper를 사용하지 않으므로 모든 피해 호출을 새 API로 옮겼다는 뜻은 아니다.
- 공용 `DamageNumber`: 연속 피해/회복 숫자의 `numeric_amount`, 병합 가능 시간, 확대 효과는 즉시 갱신한다. Label 문자열 포맷과 색 테마 적용만 dirty 상태로 모아 다음 `_process`에1회 적용한다. 마지막 타격의 색·숫자 합·기존 병합 시간/48개 풀 상한은 유지한다. 새 소유자/피해→회복/문자 팝업으로 재사용할 때 dirty 상태를 지운다. 화면 갱신은 최대 다음 표시 주기까지 지연될 수 있고, HP·치명타 판정·흡혈·처치·전리품/보상 호출을 지연하거나 여러 타격을 하나로 합산하지 않는다. 이 경로는 helper를 거치지 않는 직접 공격의 숫자 표시에도 적용된다.
- 몬스터 공통5개 기반 actor(오크·슬라임·거미·해골궁수·폭탄쥐)와 상속되는 기반 갱신/명령 이동에 선택적 계측을 추가했다. `monster_base_physics`, `monster_move_and_slide`, `monster_separation`을 분리한다. profile 참조는 생성/권위 재설정 경계에서 Battle별로 갱신한다. 기반 body 밖에서 파생 actor가 수행하는 전용 분기까지 포괄하지는 않는다. 실제 이동·충돌 방식은 바꾸지 않았다.
- 원본 helper/팝업은 `tests/fixtures/combat_phase2`에 고정해 differential oracle로 사용한다. 테스트 종료 시 급격한 정지 MP3 재생으로 생기는 headless dummy audio 참조 잔류는 슬롯 전용 테스트에서 레벨업 음원을 끈 뒤 검증했다. 프로덕션 오디오를 수정하지 않았고 이번 슬롯 검사에서 오디오는 제외했다.

소비자 목록은 [coverage.json](optimization/20261017_phase2/coverage.json), 안전성 결과는 [regression_summary.json](optimization/20261017_phase2/regression_summary.json)에 있다.

## 2단계 전후 CPU

Godot4.5.1 Linux headless, 원본/수정 순서를 교대해7회 측정. 아래 값은 **48개 팝업×120회 합성 표시 갱신 전체**의 CPU 중앙값이다. 단일 프레임이나 게임 전체 FPS가 아니며 실제 GPU/Android 측정도 아니다. 같은 표시 주기에 동일 팝업으로 들어오는 타격 수만 바꿨다.

| 팝업당 타격/표시 주기 | 이전 | 이후 | 감소 |
| --- | ---: | ---: | ---: |
| 1 | 88.868ms | 81.712ms | 8.1% |
| 4 | 326.404ms | 94.099ms | 71.2% |
| 12 | 929.043ms | 97.843ms | 89.5% |

원본 샘플: [popup_cpu.json](optimization/20261017_phase2/popup_cpu.json). 실제 Battle의 전체 성능 향상으로 환산하지 않는다. 병합이 없는 최초 팝업 생성/풀 포화 동작은 그대로다.

공통 hit helper 자체의 별도12,000타격 배치에서는 실제 Hero 스크립트 출처일 때 34.679→34.506ms(흡혈OFF), 44.795→43.335ms(흡혈ON), 투사체 출처는39.188→37.506ms/44.930→44.268ms였다. 출처 없는 경우20.430→20.745ms, 별도 반복20.003→20.745ms로 소폭 증가했다. 이 경로의 차이는 작고 잡음 범위도 겹치므로 큰 개선의 근거로 삼지 않는다. [hit_cpu.json](optimization/20261017_phase2/hit_cpu.json).

## 2단계 밀집 부하 분해

같은 실제 Stage9/정화6MAX/오크48·120·208 구성. 이번에는 초기 생성/엔진 모니터 갱신의 영향을 줄이기 위해120물리 틱 준비 후120틱 기록, 각2회. 원본 [stage9_breakdown.json](optimization/20261017_phase2/stage9_breakdown.json)에 전역 모니터의 샘플열·물리/표시 프레임 수·충돌쌍·구간별 CPU를 함께 보존했다.

아래는 `각 구간 total_us ÷ 실제 물리 틱 수`이며 **actor1마리당 시간이 아닌 전체 개체 합계/틱**이다. 기반 갱신 안에 회피·이동이 중첩되므로 행의 열들을 더하지 않는다.

| 개체 수 | 용사 물리 | 몬스터 기반 갱신 | 그중 공통 회피 | 그중 move_and_slide 호출 |
| --- | ---: | ---: | ---: | ---: |
| 48 | 1.15~1.18ms | 1.13~1.23ms | 0.35~0.37ms | 0.18~0.19ms |
| 120 | 1.98~2.10ms | 3.34~3.47ms | 1.28~1.32ms | 0.56~0.62ms |
| 208 | 3.11~3.46ms | 6.73~7.43ms | 3.07~3.37ms | 1.22~1.31ms |

밀집 시 공통 회피는 계측된 몬스터 기반 갱신의 상당 부분을 차지한다. 이 범위가3단계 우선 조사 대상이다. 별도로 전역 물리 모니터 평균은208개체33.88~41.00ms였다. 전역 모니터와 직접 계측 구간은 보고 시간 창/샘플 시점이 다르므로 차이를 빼서 “나머지 전부 충돌 엔진 비용”으로 단정하지 않는다. 또한120틱 동안 프레임 수/위치/회피가 바뀌므로1단계의20틱 준비·60틱 캡처나 다른 인스턴스의 결과와 인과적 전후 비교를 하지 않는다. **밀집 끊김 해결/FPS 개선을 이번 수치만으로 주장하지 않는다.**

## 2단계 검증

- 공통 helper198검사:6종 출처×흡혈×중첩×receipt×기존 메타×보호막의 순서/결과 비교, HP 없는 대상·삭제예약·자기 자신·방 이동·강화 즉시 변경·실제 Hero 속성 조회.
- 팝업665검사: 연속 피해/회복 합계 즉시 반영, 표시 주기 후 원본과 문자열/색/수명/위치/확대/투명도/병합 가능 상태 일치, 풀 재사용/정지 중 보류.
- 실제5개 actor의 계측·정지·비활성·권위 재설정25검사. 생존 공세의 출현 시점/종류 한도와 독립적으로 기반 계측을 검증하기 위해 이 검사에서만 일반 소환 경로로5종을 만든다.
- 10용사100무기×Lv1/Lv10/MAX=300시나리오. 원본 helper와 수정 helper를 격리 fixture에서 번갈아 적용해 각각24,000틱의 적HP·회복·보호막·RNG 기록 SHA256이 일치했다. 모의 Hero/대상의 공용 무기 런타임 검증이며 모든 고유 씬의 실전 승률 검증은 아니다. [weapon_replay.json](optimization/20261017_phase2/weapon_replay.json).
- 기존 정화 실제6MAX HP/RNG180프레임, 무기 공격경로·MAX·각성·수량, 소환 성장/광역/5레벨 슬롯, 모달 정지, 온라인 두방/snapshot/transport 회귀 포함 **명시된11,603검사와 추가 최적화 회귀1개 통과**. 테스트19개, 최종 실행 오류0. 위300시나리오의 기록 비교는 이 검사 수에 합산하지 않았다.
- 실제 Android/GPU/FPS·15분 완주·몬스터 전체 로스터 혼합전·공용 인터넷 동접 및 오디오 성능은 미검증이다. 이번 수정은 서버 매칭을 위한 공통 계산/표시 비용 개선의 두 번째 단계다.

## 2단계 재현

앞의 fixture 생성/2회 import 이후 다음을 실행한다.

```bash
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase2_hit_smoke.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase2_popup_smoke.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase2_profile_smoke.gd
python tools/verify_combat_phase2_replay.py /tmp/hero-perf-phase1 GODOT --output /tmp/combat_phase2_replay.json
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase2_hit_benchmark.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase2_popup_benchmark.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase2_stage9_breakdown.gd
```

Replay 도구는 격리 fixture의 helper만 임시 교체하고 실패 시에도 `finally`에서 복원한다. 저장소 자체를 입력하면 거부한다. 성능 측정은 다른 Godot 실행과 동시에 진행하지 않는다.

## 3단계 구현

사용자가3단계 진행과 인벤토리 상세보기의 다음 강화 미리보기 제거를 승인했다.1/2단계 결과를 보존하고 다음을 통합했다.

- **공통 밀집 회피:** 소유자의 비충돌 종족 문자열을 조회당1회 읽고, 실제 반경 안에 들어오는 후보만 이웃 메타데이터를 읽는다. 후보마다 반복하던 bucket 길이/나머지 연산도 순환 인덱스로 바꿨다. 기존48개 밀집 회피 샘플의 선택/순서·중첩 위치의 결정적 방향·가중치·반환 Vector2는 그대로다. 물리 충돌 layer/mask, move_and_slide, 이동·회피 주기, 피해 후보의 전체 집합/타격 수를 줄이지 않았다.
- **온라인 snapshot:** 현재 actor Dictionary를 직접 순회하고 wire 레코드의 seen revision과 재사용 scratch로 사라진 ID를 정리한다. 매 snapshot의 values()/keys() 복사와 별도 living Dictionary를 제거했다. 반환 상태의 actor/shot 배열은 새로 만들어 기존 상태를 보관한 호출자와 공유하지 않는다. 세대 재활성 시 새 wire ID, 순서, 필드/숫자 정밀도,10Hz 목표, 입력/권위/인증·패킷 상한은 유지했다.
- **전송:** 같은 방의 상태를1회 JSON 인코딩/UTF8 크기 검증한 뒤 두 수신자에게 공유한다. 각 socket의 열린 상태·출력 버퍼 상한·느린 수신자 종료는 계속 따로 검사한다. 일반 제어 메시지도 같은 encoder를 사용한다.
- **그리지 않는 서버 팝업:** BattleRoom의 SubViewport는 기존부터 UPDATE_DISABLED다. 그 방에서는 공용 DamageNumber의 숫자/병합/수명/난수 상태는 그대로 실행하되 Label 자식 없는 Node2D를 풀에서 사용한다. 단순히 팝업을 건너뛰면 cosmetic 난수 소비가 달라져 전투 RNG도 달라질 수 있으므로48개 풀의 활성/포화/재사용과 난수 호출을 유지했다. 일반 플레이는 기존 Label 씬을 계속 사용한다. 플래그는 BattleRoom이 _ready 전에 설정하며 전투 중 전환용 UI는 없다.
- **인벤토리 상세:** 무기/보조 증강의 다음 단계 효과 및 ‘다음 강화’ 패널을 제거했다. 현재 능력치·태그는 유지하고 아래에 ‘무기 설명’/‘증강 설명’을 표시한다. 전달/비행 방식은 기존 Catalog의 설명을 사용하고, 소환4종은 역할을 문장으로 설명한다. 현재 배운 소환 광역/이미 보유한 MAX 효과만 덧붙인다. 아직 없는 MAX/소환 광역을 미리 보여주지 않는다. 증강 선택 카드와 상자 보상의 다음 단계 변화 수치는 유지한다.

## 3단계 전후 CPU

Godot4.5.1 Linux headless,7회 중앙값, 실행 순서 교대. **아래는 각 배치 전체의 CPU 시간**이며 게임 FPS나 Android/GPU 향상률이 아니다. 다른 Godot 검사와 동시에 측정하지 않았다.

| 회피 조회 배치 | 이전 | 이후 | 감소 |
| --- | ---: | ---: | ---: |
| 분산48개체 /576조회 | 8.201ms | 4.997ms | 39.1% |
| 분산120개체 /1440조회 | 30.363ms | 17.115ms | 43.6% |
| 분산208개체 /2496조회 | 55.800ms | 30.042ms | 46.2% |
| 밀집48개체 /576조회 | 31.558ms | 20.621ms | 34.7% |
| 밀집120개체 /1440조회 | 126.326ms | 86.631ms | 31.4% |
| 밀집208개체 /2496조회 | 349.395ms | 216.586ms | 38.0% |

원본과 수정 grid에 **같은 actor/instanceID/좌표**를 넣은 합성 조회다. [grid_cpu.json](optimization/20261017_phase3/grid_cpu.json).

| 온라인 상태 생성+인코딩 / 방마다48개체·80상태·2수신자 | 이전 | 이후 | 감소 |
| --- | ---: | ---: | ---: |
| 1방 | 24.047ms | 19.472ms | 19.0% |
| 2방 | 49.600ms | 38.871ms | 21.6% |
| 8방 | 221.181ms | 178.292ms | 19.4% |

실제 격리 BattleRoom과 frozen 이전 snapshot을 사용한다. 이전은 수신자마다2회, 이후는1회 JSON/크기 검증. socket I/O는 제외한다. [online_cpu.json](optimization/20261017_phase3/online_cpu.json).

서버용 팝업은48개×120합성 주기에서 매번 setup 후1/4/12회 병합 조건으로 측정했다. Label이 있는2단계 상태 대비200.760→7.604ms /214.417→15.499ms /218.219→30.128ms. 초기 숫자 포맷·테마·Label 작업을 제외한 해당 배치 효과이며 전체 서버 CPU 감소율이 아니다. [server_popup_cpu.json](optimization/20261017_phase3/server_popup_cpu.json).

## 실제 여러 방 부하와 한계

실제 MatchServer.step, 개별 World2D/Battle/Hero/오크48마리, 방마다 견습 마도사6MAX,120물리 틱 준비 후120틱 기록. 몬스터HP10,000,000·용사 무적으로 개체를 유지한 집중 부하이며 일반 승률/완주 검사가 아니다. loopback listener와 테스트 인증 모드, 상태 인코딩은 실행했지만 이 부하 캡처에는 socket 수신자가 없다. 실제 소켓 통신은 별도의 transport 회귀로 검사했다.

| 방 수 | 전체 개체 | 기록 물리 틱 | 기록 벽시계 | 이 캡처의 처리율 |
| --- | ---: | ---: | ---: | ---: |
| 1 | 48 | 120 | 1999.975ms | 약60Hz |
| 2 | 96 | 120 | 1995.827ms | 약60Hz |
| 8 | 384 | 120 | 4132.934ms | 약29Hz |

**이 호스트에서8방 모두6MAX인 최대 부하는60Hz를 유지하지 못했다.** 기존 MAX_ROOMS=8을 낮춰 통과시킨 것이 아니며,8방 동접 보장을 주장하지 않는다. 서버 배포 시 방당 빌드/혼합 로스터·하드웨어·프로세스 분산과 수용량을 추가 검증해야 한다. 현재 실제 전투를 유지한1/2방 캡처와8방 과부하 경계를 함께 보존한다. [multiroom_load.json](optimization/20261017_phase3/multiroom_load.json). 전역 엔진 모니터와 직접 구간의 시간 창은 다르므로 중첩 구간을 합치거나 차감해 전체 CPU의 원인을 단정하지 않는다.

## 최종 통합 검증

- 원본 grid와 동일 actor를 사용한9604검사: 밀집 샘플 순서·겹침·비충돌 종족·제외 플래그·현재 좌표/메타 변경·고속 패딩·사망/삭제예약/해제·전체 rect/group 결과. 회피 Vector2까지 정확히 일치했다.
- 실제 두 방48개체·원본 snapshot 비교263검사: 상태 문자열/필드/순서·세대 재활성·퇴장 ID 정리·방 간 격리·UTF8 크기 거부·서버 팝업 동작.
- 렌더/서버 팝업9000검사: 동일 이벤트와 dt에서 숫자/병합/수명/포화/활성/위치 상태 및 글로벌 RNG 소비 일치.
- 상세보기784검사:100무기 Lv10/MAX 현재 능력치/설명, Lv1~10의 미래 MAX 제외·현재 MAX 설명·현재 소환 광역·보조 설명,540/1080 세로와960/1920 가로 레이아웃·스크롤/닫기·실제 인벤토리 handler의 일시정지/복원.
- 기존 무기100종 공격/각성/MAX/수량·간결한 선택 카드, 실제 Stage9 HP/RNG, 소환 성장/광역/5레벨 슬롯·정지·온라인 snapshot/WebSocket 및 레지스트리/기존 최적화 회귀 포함 **25개 테스트 통과, 명시35,571검사·최종 실행 오류0**. aggregate pass/fail만 출력하는 기존 최적화 테스트의 내부 반복 수는 검사 수에 넣지 않았다. 슬롯 전용 테스트는 반복 정지 MP3 재생을 제외했다.
- 최종 공통 helper로100무기×Lv1/Lv10/MAX300시나리오를 다시 실행. 각각24,000틱의 HP/회복/보호막/RNG SHA256은 `aa9c858c3851a98d94c51c377997fbd2edc8cfd8976b477bb8ee810e88918b0c`로 일치. 이 기록 비교는 위 검사 수와 별도다.
- 최종 editor import/구문·git diff --check 통과. 실제 Godot4.5.1 headless 검증이며, 누락 표현은 fixture 대역·UI는 제어된 전투 host를 사용한다. Android/GPU/실제 FPS·15분 완주·전체 몬스터 로스터 혼합/승률·공용 인터넷 동접·오디오 청감은 미검증이다.

[최종 회귀 요약](optimization/20261017_phase3/regression_summary.json), [최종 무기 기록](optimization/20261017_phase3/weapon_replay.json).100%는 세 번으로 합의한 작업 범위를 완료했다는 뜻이며 모든 조건의 렉 제거/성능 개선율100%를 뜻하지 않는다. 최종 변경을 기존 feature/stage10-astra에 커밋·푸시하고 main은 변경하지 않는다.

## 3단계 재현

앞의 combat fixture 생성/import 후 아래를 실행한다. 인벤토리 UI fixture는 별도 만든다.

```bash
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase3_grid_smoke.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase3_online_smoke.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase3_popup_smoke.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase3_grid_benchmark.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase3_online_benchmark.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase3_popup_benchmark.gd
GODOT --headless --path /tmp/hero-perf-phase1 --script res://tests/combat_phase3_mult_room_benchmark.gd
python tools/build_hero_inventory_detail_fixture.py /tmp/hero-inventory-phase3
GODOT --headless --path /tmp/hero-inventory-phase3 --editor --import --quit
GODOT --headless --path /tmp/hero-inventory-phase3 --editor --import --quit
GODOT --headless --path /tmp/hero-inventory-phase3 --script res://tests/hero_inventory_detail_smoke.gd
```
