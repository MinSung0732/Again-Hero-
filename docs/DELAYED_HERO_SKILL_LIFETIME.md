# 용사 지연 범위 스킬 수명 검증

## 후속 진행 — 성스러운 힘 및 scalar 수명 예약 (2026-10-10)

holy power 지연 피해·후속 둔화에 source/target 수명 검증을 연결했다. ice/earth/holy 공통 source 예약은 시전당 RefCounted에서 Vector3i+부모ID 값으로 전환해 예약 객체 생성과 취소된 시전의 새 timer를 제거한다. 현재 비용·범위·검증14,261검사·한계·후속·롤백은 [HOLY_POWER_LIFETIME.md](HOLY_POWER_LIFETIME.md). 아래 이전 구현의 RefCounted/WeakRef 비용 설명은 이력이다. 전체 게임/모바일/서버·실측 성능 검증은 미완료다.


2026-10-10. 기준 `cc5e6aed0cdfee9c4993c384cb624d5d62383bc1`, 작업 `feature/stage10-astra`. 사용자가 던전 입장 정상 동작을 확인해 중단했던 확장 기반 작업을 재개했다. main은 변경하지 않는다.

## 문제와 변경

얼음 기둥은 타이머 이후 수명 확인이 없었다. 대지 가시는 tree/HP만 확인해 같은 Node가 새 전투나 새 generation으로 돌아오면 이전 시전이 이어질 수 있었다. 두 시전의 시작에서 기존 BattleTargetReference로 공격자와 부모 battle의 수명을 캡처하고 매 생성 단계 및 각 피해 대상 직전에 검증한다. HP 0, registry retirement, 재활성화, epoch 교체, 부모 교체, queued deletion이면 남은 생성을 취소한다. 기존에 생성된 FX의 재생은 유지한다.

대지 가시의 좌측 분기 피해 callback이 공격자 수명을 바꾸면 우측 분기를 생성하지 않는다. 종료 시 같은 개체 수명일 때만 casting counter를 정리한다. 같은 수명의 HP 0은 정리하지만 새 수명의 counter는 건드리지 않는다. 캐스팅 수명 변경 시 새 수명의 카운터 초기화는 기존 생성/초기화 경로의 책임이다.

동시 시전을 지원하므로 source 예약은 시전당 독립 RefCounted 하나와 WeakRef 최대 두 개를 생성한다. 매 프레임/피해 대상별 새 배열이나 예약 객체는 생성하지 않는다. resolve는 기존 레지스트리 평균 O(1) 조회다. 추가 비용은 각 pulse/피해 후보의 상수 시간 검사이며 피해 조회 자체의 복잡도는 유지한다. 실제 FPS/메모리 개선을 측정한 패치는 아니다.

## 유지되는 의미와 한계

- 정상 시전의 수, 좌표 RNG, 시전 당시 공격력, 효과 프레임/크기, 간격(얼음 0.045초, 대지 기존 spike_delay), 분기 순서, 음향, instance ID 기반 중복 피해 차단은 그대로다.
- 범위 피해는 매 단계 현재 대상 조회를 유지한다. 예약 이후 등장한 주변 적도 피해를 받는다. 두 범위 피해 helper의 추가 source 인자는 optional이므로 다른 호출은 기존 동작을 유지한다.
- registry API가 없는 독립 씬은 기존 WeakRef fallback이며 Node 풀 재사용 generation은 구분할 수 없다. 불완전 registry 및 미등록 개체는 fail closed다.
- 이번 범위는 후속 얼음 기둥과 대지 가시다. 얼음 투사체의 최초 impact, holy power/fire field/기타 장판, reentrant shared scratch, 피해 대상의 별도 수명 claim은 후속 작업이다. 서버·동기화 구현 완료를 뜻하지 않는다.

## 검증

Godot 4.5.1 headless 독립 fixture에서 실제 두 스킬, 범위 피해 helper 두 개, casting begin/end, 새 수명 helper와 실제 registry/reference를 사용했다. 타깃 조회, 시각 효과, 음향, 설정/배율은 spy다. 실제 SceneTreeTimer를 실행했다.

| 검사 | 결과 |
|---|---:|
| 지연 스킬: 일반/강화 before-after FX 위치·순서·프레임·피해·음향 비교, await 중 재사용/epoch/HP0/부모 교체, callback 중 무효화, 동시 시전, 신규 AoE, 200회 generation 재사용, queued/detach/미등록 | 239 통과 |
| 공통 행동 회귀 | 6,255 통과 |
| 전용 이동 회귀 | 6,143 통과 |
| 돌진 수명 회귀 | 420 통과 |
| 체인 투사체 수명 회귀 | 759 통과 |
| 합계 | 13,816 통과, 실패 0 |

현재 기준 Hero의 원래 613개 함수는 정확히 검토한 변경 행만 역변환한 뒤 본문 동일성을 확인했다. 이전 행동/이동/돌진 builder도 같은 제한된 변환을 사용해 이전 기준과 비교한다. whole-function whitelist는 사용하지 않는다. gdparse/Python compile/diff 확인 및 독립 editor import 수행. 전체 게임 Godot 4.7, 실제 물리/GPU/모바일/서버 및 성능 측정은 미검증이다.

```sh
git show cc5e6aed0cdfee9c4993c384cb624d5d62383bc1:src/hero/hero.gd > /tmp/hero-delayed-before.gd
python3 tests/build_delayed_hero_skill_fixture.py /tmp/delayed-hero-fixture --baseline-file /tmp/hero-delayed-before.gd
godot --headless --path /tmp/delayed-hero-fixture --script res://tests/delayed_hero_skill_smoke.gd
```

## 후속과 롤백

다음 후보는 holy power의 지연 burst 및 피해 후 target 접근 검증이다. 불꽃 장판과 나머지 await 경로는 개별 의미를 확인한 후 순차 적용한다. 이번 커밋 전체를 `git revert <commit>`하면 코드·테스트·문서를 함께 복원할 수 있다. 개별 helper만 삭제하면 호출이 깨진다. main 병합/강제 push는 하지 않는다.
