# 전투 유닛 ID·수명 레지스트리 — 2단계 첫 적용

작성: 2026-10-10. 기준 feature `3a56af81f4f40e719ec6edd672bbfec94edd8d37`.
작업 브랜치 `feature/stage10-astra`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 변경 목적과 범위

풀에서 같은 Node를 다시 꺼내면 로컬 instance ID는 그대로다. 이전 공격의 지연 결과가 새 투사체 수명에 적용되지 않도록, 별도 `Vector3i(전투 epoch, 슬롯 ID, generation)`을 부여한다. 슬롯 ID는 1부터 시작하며 ZERO는 무효다. 로컬 instance ID는 내부 Dictionary 조회 키로만 사용한다.

| 대상 | 등록 | 무효화 |
|---|---|---|
| 용사 | battle `_start_battle`의 add_child 이후 | 사망 신호 / tree exit |
| 몬스터 | `_spawn_monster`의 기존 active 등록 이후 | 기존 `_unregister_monster` / tree exit |
| battle 풀 투사체 | `acquire_projectile` 반환 직전 | `recycle_projectile`의 deactivate 이전 / tree exit / queued deletion 조회 |
| 같은 battle의 새 전투 | router의 새 epoch로 registry 초기화 | 이전 epoch 전체 |
| 새 battle Node | 프로세스 공용 router epoch 증가 | 이전 battle의 동일 슬롯·generation도 일치 불가 |

`_spawn_monster`를 통과하는 일반/엘리트/초월 몬스터가 포함된다. 이펙트·EXP 구슬·아이템 및 다른 경로로 생성한 용사 보조 유닛은 아직 미등록이다. 기존 대상 탐색·피해·상태이상·공간 그리드의 instance ID를 한꺼번에 교체하지 않는다. 이번 코드는 identity sidecar이며 실제 게임 판정/네트워크 메시지는 아직 새 handle을 사용하지 않는다.

## 사용 계약

```gdscript
# 지연 작업을 예약할 때 현재 수명의 handle을 캡처한다.
var captured: Vector3i = battle.get_battle_entity_handle(target)
# 작업을 적용할 때 같은 battle의 registry에서 다시 확인한다.
var live: Node = battle.resolve_battle_entity(captured)
if live == null:
    return  # 사망/풀 반납/재사용/전투 교체된 대상에는 적용하지 않는다.
```

- 활성 Node 중복 등록은 동일 handle을 반환하며 active 수를 늘리지 않는다.
- 반납한 슬롯을 다시 사용하면 generation이 증가한다. 이전 handle의 resolve/retire는 실패한다.
- `retire_instance`는 동기 생명주기 훅 전용이다. 미래의 지연 작업이나 네트워크 결과는 캡처한 handle을 검사해야 한다.
- tree_exited는 Node마다 한 번만 연결한다. 매 수명마다 연결하면 풀에서 콜백이 누적되므로 local instance ID에 바인딩한 동일 Callable을 검사한다.
- Node 보관은 WeakRef다. registry가 Node 수명을 연장하지 않는다. battle 훅이 종료 시 메타데이터를 회수하고, 단독 registry에서 직접 free한 Node는 resolve/get_handle 시 정리된다.
- epoch는 동일 프로세스의 router 간 공유 증가 번호다. 저장/재접속/다른 프로세스의 고유 match ID가 아니다. 미래 서버는 신뢰한 match 식별자 및 epoch를 별도 바인딩해야 한다.
- Vector3i 구성 요소의 한계는 2,147,483,647이다. registry는 범위 초과 epoch 및 동일/이전 epoch 초기화를 거절한다. 포화 generation 슬롯은 재사용하지 않아 wrap으로 이전 handle이 부활하지 않는다. 장기 서버는 epoch 한계 전에 프로세스/세션 수명 정책을 적용해야 한다.

## 비용과 기존 의미 유지

등록·조회·해제는 Dictionary 평균 O(1), 슬롯 배열 접근 O(1), 배열 확장은 amortized O(1)이다. 세션 초기화는 기존 슬롯 수에 비례한다. 일반 사용의 메타데이터는 누적 소환 수가 아닌 동시 등록 최대 슬롯 수에 비례한다. generation 포화 슬롯만 예외적으로 남는다. 전체 그룹 스캔이나 프레임 루프를 추가하지 않았으며, 진단 Dictionary는 명시 요청 때만 생성한다. 활성화 시 WeakRef와 Callable 생성 비용은 있으므로 실제 FPS 향상을 주장하지 않는다.

투사체 instantiate/free 및 풀 한도, 소환 비용/배치/인원 계산, 사망 후 기존 결과 처리, delta/일시정지/AI 정책을 유지한다. registry 등록 실패는 ZERO 반환이며 기존 게임 실행을 변경하지 않는다. 이 sidecar는 서버 권한 검사·적아 판정·체력 검사·선택 권한을 대체하지 않는다.

## 검증

Godot **4.5.1 headless 독립 fixture**에서 다음 검사 통과:

| 테스트 | 검사 수 | 검증 내용 |
|---|---:|---|
| battle_entity_registry_smoke | 76 | 무효 handle, 중복/이중 해제, 2,000회 수명 재사용, weak cleanup, queued deletion, epoch/generation 한계 |
| battle_entity_boundary_smoke | 59 | 실제 battle acquire/recycle/unregister/tree_exit 함수 추출, 200회 풀 재사용, deactivate 이전 무효화, 신호 수 유지, 인원 계산, 풀 한도 폐기, 새 battle epoch |
| battle_command_router_smoke | 134 | 기존 명령 경계 및 새 router의 이전 전투 명령 차단 |
| battle_augment_boundary_smoke | 79 | 기존 증강 선택/재뽑기/후보/pause 회귀 |
| battle_mutation_boundary_smoke | 58 | 기존 엘리트 선택/후보/실패/pause 회귀 |
| 합계 | 406 | 모두 실패 0 |

fixture는 실제 registry/router 및 battle의 해당 함수를 추출한다. projectile은 in-memory PackedScene spy이고 게임 카탈로그/증강 효과/director/소환은 spy다. 용사 생성·몬스터 전체 spawn·사망의 게임 씬 실행은 포함하지 않는다. 정적 비교로 `_process`, `_start_battle`, `_spawn_monster`, `_unregister_monster`, acquire/recycle, 용사 사망의 원래 본문이 identity 추가 행 외에는 동일함을 확인했다. gdparse, Python builder 컴파일, diff --check 및 생성 fixture 없는 독립 editor import도 확인한다.

실제 게임 **4.7**, GPU/UI·모바일 전투·FPS/메모리/로딩 측정은 미검증이다. 이번 fixture 통과는 전체 런타임 성공을 의미하지 않는다.

재현:

```sh
python3 tests/build_battle_boundary_fixture.py /tmp/again-battle-fixture
godot --headless --path /tmp/again-battle-fixture --script res://tests/battle_entity_registry_smoke.gd
godot --headless --path /tmp/again-battle-fixture --script res://tests/battle_entity_boundary_smoke.gd
# 같은 경로에서 router / augment / mutation smoke도 실행한다.
```

## 다음 단계·롤백

1. 실제 게임에서 일반/엘리트/초월 생성·사망·풀 재사용·전투 재진입 회귀 확인.
2. 용사 AI의 의도 생성과 기존 실행을 action port로 나누고 현재 AI를 동일 포트에 연결. 플레이어 입력 연결은 별도 단계.
3. 지연 공격·피해 결과에 handle을 점진 적용하고 아직 미등록인 보조 유닛 목록을 조사.
4. RNG·공유 시뮬레이션·스냅샷 schema로 확장한 뒤 서버 권한 및 송수신 계층 구축. 기존 solo 외 모드는 계속 차단.

엘리트 명령 체크포인트 `3a56af81f4f40e719ec6edd672bbfec94edd8d37`와 별도 커밋이다. 이상이 생기면 이 entity 커밋만 `git revert <entity_commit>`하여 증강/엘리트 명령 및 Run 시계를 보존한다. main은 이번 작업에서 변경하지 않는다.
