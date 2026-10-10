# 용사 행동 포트 — 공통 원거리 첫 분리

작성: 2026-10-10. 기준 feature `349513c0cc117f06df6228d84b08aced1340a54a`.
브랜치 `feature/stage10-astra`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 이번에 연결한 부분

기존 `Hero._physics_process_actions`의 공통 원거리 경로에서 이동 판단과 이동/기본공격 실행을 분리했다. AI가 재사용 `HeroActionIntent`에 이동 속도 벡터와 관측 거리를 기록하고 `HeroActionPort.execute_ranged`가 기존 이동·경계 제한·투사체 발사를 실행한다. 추후 입력 생성자를 교체할 접점을 확보하는 작업이며 용사 플레이어나 서버 모드를 활성화하지 않는다.

| 책임 | 현재 위치 | 변경 여부 |
|---|---|---|
| 상태이상·사망·직업 분기·쿨타임 진행 | 기존 Hero physics 함수 | 순서와 판정 유지 |
| 아이템 목표·대상 탐색·거리 관측 | 기존 공통 원거리 경로 | 유지 |
| 방향 선택·아이템 보정·경계 회피·속도 계산 | `_prepare_ranged_ai_intent` | 기존 코드를 그대로 분리 |
| 이동·충돌 회피·위치 제한·기본공격 | `HeroActionPort.execute_ranged` | 기존 호출 순서 유지 |
| 무타깃 배회 / 직업 전용 이동·공격·스킬 | 기존 Hero 함수 | 아직 포트로 전환하지 않음 |
| 증강 Utility AI·최근 관측·관성·성향·랜덤 | 기존 BuildAI/Hero | 변경 없음 |

공통 경로의 ranged_kiter / archmage_elementalist / cleric_purifier / grand_sage_astra가 첫 적용 대상이다. rogue/fighter/gunner/berserker/alchemist/summoner는 기존 직업 경로로 그대로 분기한다. 공통 경로에 도달하는 기본공격만 분리했으며 원거리 용사의 직업 스킬 자동 선택까지 모두 분리한 것은 아니다.

## 수명·실행 계약

- 의도 버퍼는 Hero 생성 시 한 번 만들고 계속 재사용한다. Node 참조/Callable/배열/Dictionary를 담지 않으며 큐나 네트워크 패킷이 아니다.
- 매 actions 진입 시 clear하여 사망·기절·공포·매혹·직업/스킬 early return 때도 이전 의도를 남기지 않는다.
- 포트는 값 세 개를 지역 변수에 복사하고 **콜백 전에 소비**한다. 같은 버퍼를 다시 실행하면 false로 끝나며 이동이나 공격을 재생하지 않는다.
- 기존 AI의 이동 방향 계산·아이템 보정·경계 회피 순서를 그대로 유지한다.
- 기존처럼 이동 전 관측 거리를 사용하되 공격 사거리와 쿨타임은 이동 이후의 현재 값을 확인한다. 실제 발사 대상도 이동 이후 `actor.target`을 사용한다. 이 단계에서 새 거리 재검사나 공격 타이밍을 추가하지 않는다.
- petrify의 바깥 위치 복원과 최종 clamp, 기존 status/skill gate, 동작 후 pose 갱신을 유지한다.

이 포트는 현재 Hero가 gate를 통과한 뒤 즉시 호출하는 **신뢰한 로컬 실행 경계**다. 임의 Node/속도/거리 데이터를 외부 입력으로 직접 넘기는 API가 아니다. 플레이어/서버를 붙일 때는 actor 소유권, 현재 수명, 이동 입력 범위, 대상 handle, 비용·상태·쿨타임을 공유 규칙으로 검증하고 서버가 실행 의도를 계산해야 한다. 클라이언트가 제공한 속도/관측 거리 값을 권위 있는 판정으로 사용하지 않는다. 현재 identity registry는 sidecar 상태이며 이 포트의 대상에 handle 검사를 적용하는 단계는 남아 있다.

## 변경 전/후

이전에는 하나의 physics 함수 안에서 방향 보정 → velocity 계산 → move/clamp → 사거리/쿨타임 확인 → 투사체 발사를 모두 수행했다.

```gdscript
# After: 기존 상태/직업/무타깃 gate를 통과한 공통 경로
var distance := global_position.distance_to(target.global_position)
_prepare_ranged_ai_intent(delta, distance)
HERO_ACTION_PORT.execute_ranged(self, ranged_action_intent)
_update_stage1_pose_visual(delta)
```

전체 구현은 `src/hero/hero.gd`, `hero_action_intent.gd`, `hero_action_port.gd`에 있다. 단순히 AI 함수 이름을 감싼 구조가 아니라 방향 계산의 결과를 의도 버퍼로 전달하고 실행 순서를 포트에서 담당한다. 다만 공통 원거리 일부부터 옮기는 단계라 모든 AI 의도가 아직 이 포트를 통과하지는 않는다.

## 비용·검증

버퍼 clear/prepare/consume은 O(1), Hero당 버퍼 하나다. 새 프레임 스캔/Node 생성/배열/Dictionary 생성/instantiate/free/await를 추가하지 않았다. 기존 공간/캐시 조회 비용은 그대로다. 함수 호출이 소수 추가되므로 FPS나 로딩 향상을 주장하지 않는다.

Godot **4.5.1 headless 독립 before/after fixture** 비교 **6,255검사, 실패 0**:

- 실제 이전/신규 `_physics_process` 및 `_physics_process_actions`, 신규 `_prepare_ranged_ai_intent`와 실제 포트를 실행한다.
- 공통 네 직업에서 18조건 및 채널 시작, 각 240연속 프레임의 delta 0/0.016/0.033/0.1을 비교한다.
- 정상/쿨타임/범위 밖/무타깃/retarget/숨은 대상/queued deletion/사망/poison 중 사망/기절/공포/매혹/petrify/channeling/Gungnir gate를 확인한다.
- 이동 콜백 중 사거리·쿨타임·대상이 바뀌어도 원래 실행 순서를 보존하는지 확인한다.
- 여섯 직업의 기존 분기, 상태 메타·타이머·속도·좌표·이벤트 순서, 버퍼 객체 재사용·소비·중복 실행 거절을 확인한다.
- 변경 대상 외 실제 Hero 함수 **609개**를 이전 소스와 동일 비교했다. 실제 이동 AI·쿼리·투사체·직업별 본문·BuildAI는 유지한다.
- gdparse, builder Python 컴파일, diff --check 및 생성 fixture 없는 독립 editor import를 확인한다.

타깃 정책, 충돌 이동, 아이템/이펙트·스킬 갱신, 투사체 생성 및 전용 직업 함수는 명시적인 spy다. 실제 게임 **4.7**, 충돌 물리/GPU/전체 전투·모바일·성능은 미검증이다. 테스트의 많은 검사 수가 전체 게임 실행을 대신하지 않는다.

재현(전체 git clone 기준):

```sh
python3 tests/build_hero_action_fixture.py /tmp/hero-action-fixture
godot --headless --path /tmp/hero-action-fixture --script res://tests/hero_action_port_smoke.gd
```

부분 체크아웃에서는 기준 Hero 파일을 `--baseline-file /path/to/hero_before.gd`로 전달한다. 생성 fixture는 게임 저장소 안에 만들지 않으며 테스트 스크립트는 실행할 때만 fixture를 load한다.

## 후속 순서·롤백

1. 실기기에서 네 공통 원거리 용사의 이동/배회/기본공격/상태이상·스킬 연계 회귀 확인.
2. 무타깃 이동 의도와 근접/권총 등의 이동·기본공격을 직업별 작은 단위로 포트에 전환. 돌진/콤보/변신은 별도 검증.
3. 스킬/증강 의도와 타깃 handle 계약, 입력 생성자 소유권 전환을 정리. 현재 AI가 기준 구현이며 플레이어 입력은 별도 단계에서 연결.
4. RNG·공유 시뮬레이션·스냅샷/서버 권한을 구현한 뒤 실제 용사/PvP 모드 활성화.

이 작업은 entity 체크포인트 `349513c0cc117f06df6228d84b08aced1340a54a` 이후 별도 커밋이다. 문제 발생 시 action-port 커밋만 `git revert <commit>`하여 이전 entity/명령/Run 시계 기반을 보존한다. main은 변경하지 않는다.
