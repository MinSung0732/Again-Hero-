# 얼음 충돌 범위 피해와 기둥 시작 수명 연결

후속: 피해 결과/identity 계약의 첫 적용은 [DAMAGE_OBSERVATION_FOUNDATION.md](DAMAGE_OBSERVATION_FOUNDATION.md)에 기록했다. 아래 다음 작업 설명은 작성 당시 이력이다.

2026-10-10. 기준 feature `ce1da1b938a2bbc43b94ea3f5449a8ddd9ef2176`, Hero blob `01959c984f3b63af93b9348a2dc48c77e776982b`. 작업 `feature/stage10-astra`. main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 문제와 변경

projectile 자체의 수명 검증은 이미 있지만 실제 Hero.resolve_archmage_ice_bolt_hit 내부는 최초 범위 피해에 source reservation을 전달하지 않았다. 피해 callback에서 Hero를 재사용하면 뒤쪽 후보를 새 Hero의 공격으로 타격하고, 기둥 함수가 새 수명을 캡처해 이전 impact의 작업을 계속할 수 있었다. Before 실제 코드 fixture에서 마지막 피해 대상의 callback이 Hero를 재사용한 뒤 기둥이 생성되는 문제를 재현했다.

충돌 함수는 시작 때 scalar Vector3i handle+부모ID를 캡처한다. 기존 범위 helper로 전달하여 후보별로 동일 source 수명을 검사하고, 범위 함수 반환 후 동일 수명일 때만 기둥 함수를 호출한다. source 재사용/epoch/queued/retire/부모 변경이면 이후 피해·기둥을 중단한다. 기둥 자체의 기존 timer/pulse 검증은 유지한다. 타깃을 예약하지 않으며 범위 피해의 현재 대상 조회 규칙은 그대로다. 대상에게 후속 상태 metadata를 쓰는 함수가 아니므로 새로운 target reservation은 필요하지 않다.

## HP0 정책 및 비용

이미 발사된 ice projectile은 Hero HP0만으로 즉시 취소되지 않는다. impact의 기존 범위 피해는 HP0에서도 실행되며 기둥은 기존 alive gate로 생성되지 않았다. 이 의미를 유지하기 위해 capture와 radius helper의 require_alive 인자 기본값을 true로 추가하고 impact만 false를 전달한다. 기본값을 사용하는 모든 기존 지연 피해 호출의 HP0 취소는 유지한다. HP0가 돼도 아직 같은 등록 수명이면 impact 후보 처리는 계속하며 실제 registry retire부터 취소한다. 기둥은 호출되어도 기존 capture의 alive gate에서 멈춘다.

- 기존 피해/강화 배율·범위·RNG·FX 프레임·음향·기둥 개수/간격 유지. null target과 저장 hit_position 처리도 유지.
- source 예약은 값만 저장한다. 새 Array/Dictionary/WeakRef/RefCounted나 프레임 그룹 조회를 추가하지 않는다. 기존 scratch/공간 조회/FX pooling 사용.
- registry 조회 평균 O(1), 기존 후보 n개 범위 검사 O(n), source/부모 ID 추가 공간 O(1). FPS/RAM/로딩 개선은 실측하지 않았다.
- registry 없는 독립 scene fallback은 동일 Node generation을 구분하지 못하는 기존 한계가 있다. 동일 source 안에서 중첩 AoE가 공유 scratch를 재진입하는 일반 문제는 이번 변경 범위가 아니다.

## 검증

Godot4.5.1 headless에서 실제 impact/AoE/source helper/기둥 coroutine과 실제 registry를 실행했다. 실제 타이머와 fixed seed로 FX 위치/피해 순서/기둥 완주를 비교한다. FX 렌더링/오디오/후보 조회/피해 대상은 spy이며 실제 충돌/게임 씬/GPU 실행은 아니다.

| 검사 | 결과 |
|---|---:|
| 신규: 정상·강화×source HP100/0 Before/After FX/RNG/audio/범위·정확한 피해·기둥 개수, source callback 재사용200회, 마지막 피해 뒤 재캡처 원래 버그, epoch/queued/retire/미등록, HP0 callback/기존 default gate, queued target/fresh AoE target |240 통과|
| 공통 행동 |6,255 통과|
| 전용 이동 |6,143 통과|
| 돌진 |420 통과|
| 얼음 기둥·대지 가시 |239 통과|
| holy power |445 통과|
| 연소 |234 통과|
| multicast |240 통과|
| 이번 실행 합계 |14,216 통과, 실패0|

기준618함수는 정확한 변경 문자열 역변환 후 전부 본문 비교했다. 기존 역변환 체인의 공통 multicast_source에 새 reverse를 조합하여 기존617/616/613/611 비교도 유지했다. arbitrary 함수 whitelist를 추가하지 않았다. gdparse/Python compile/git diff check 및 독립 editor import 통과. 최종 impact verbose 종료 스크립트 ERROR/WARNING/잔류 객체 없음. SDL misc2 mapping 출력은 엔진 환경 메시지다. projectile 소스는 이번에 변경하지 않았고 해당 fixture는 다시 실행하지 않았다. 전체 Godot4.7 게임·실제 물리/시각/오디오·모바일·서버·장기 RAM은 미검증이다.

```sh
git show ce1da1b938a2bbc43b94ea3f5449a8ddd9ef2176:src/hero/hero.gd > /tmp/hero-impact-before.gd
python3 tests/build_ice_impact_fixture.py /tmp/ice-impact-fixture --baseline-file /tmp/hero-impact-before.gd
godot --headless --path /tmp/ice-impact-fixture --script res://tests/ice_impact_smoke.gd
```

## 후속과 롤백

다음 후보는 공통 피해 결과와 identity 계약 조사다. 광전사 target이 재사용 후 retire까지 된 경우 현재 ZERO handle만으로는 이전 처치를 구분하지 못한다. damage 호출의 결과/수명 정보를 값 형식으로 반환하는 경계를 설계하면 이후 권한 서버·킬 집계·지연 상태 처리에 활용할 수 있다. 기존 Monster/Hero take_damage API의 수많은 호출과 신호 순서를 조사한 뒤 작은 호환 패치부터 적용한다.

전체 스킬 수명 경계·행동 상태 직렬화·서버 권한/스냅샷·플레이어 용사 입력은 미완료다. 이번 커밋 전체 git revert로 Hero/helper/fixture/docs를 함께 복원할 수 있다. helper 기본 인자만 제거하면 새 impact 호출이 깨지므로 함께 복원해야 한다. main 병합/강제 push 없음.
