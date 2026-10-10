# 공통 피해 관측과 개체 수명 계약 — 첫 적용

후속: 일반 슬라임의 실제 처리 지점 결과 기록과 재사용 버퍼는 [SLIME_DAMAGE_RECEIPT.md](SLIME_DAMAGE_RECEIPT.md)에 기록했다. 아래 다음 단계는 작성 당시 계획이다.

2026-10-10. 기준 feature `7a3ae7ecf044d862691953b8e2940904db268eea`. 작업 `feature/stage10-astra`. main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

기준 blob: registry `b6efba4b70a35fc97ff6f5f6029f9d2e5caca08c`, battle `8e2ba294185cea6df4913505e8e91346f2a08b14`, projectile `9a945b20fb235705d7a1d8f466e3f89bd1987111`.

## 실제 피해 경로 조사

| 경로 | 현재 계약과 순서 | 영향 |
|---|---|---|
| 일반 slime | take_damage void, shield 소비→HP 감소→damage number/visual→공통 death | 호출 반환값만으로 accepted/applied/kill을 판단할 수 없음 |
| monster_runtime_common death | dying true→정지/충돌 해제→died 신호→사망 animation/해제 | 신호 handler가 피해 호출 반환 전에 registry 상태를 바꿀 수 있음 |
| Hero | take_damage bool, 내부 shield/반사/감소→HP 감소→accepted/health/damage 신호→광전사 부활 또는 death | bool은 실제 HP 피해량이나 사망 확정과 다름 |
| 만티코어 | void, lethal 첫 회피/회복 후 return 가능 | 요청 피해량/HP 전후만으로 확정 처치 추론 금지 |
| 슈텐도지 | void, lethal/50% 조건이면 HP≥1로 유지하고 부활 시작 | 피해와 부활/사망의 의미 구분 필요 |
| 기존 wave | 피해 전 HP/handle→take_damage→피해 후 HP→hit/kill 알림 | ZERO handle을 정상 retire로 보아 재사용 후 retire된 대상도 이전 kill로 계산 가능 |

모든 actor를 한 번에 바꾸지 않는다. 이번에는 기존 take_damage API와 신호/부활 순서를 보존하며 관측 분류와 identity 경계를 먼저 만든다. 조사 대상은 위 경로이며 전체 몬스터·직업 피해 함수 완전 감사로 표시하지 않는다.

## 값 형식 관측 계약

`battle_damage_observation.gd`는 static 함수만 사용한다. Node를 보관하는 인스턴스/receipt Array/Dictionary를 만들지 않는다. 호출자는 피해 전 HP와 victim handle을 값으로 저장하고, 피해 callback 뒤 source/shot을 먼저 재검증한 다음 `observe_legacy_hit(target, scope, victim_life, hp_before)`를 호출한다. 피해나 명령을 실행하지 않으며 결과는 int bit mask다.

| 플래그 | 값 | 의미 |
|---|---:|---|
| HP_UNKNOWN |1|HP 전/후를 관측하지 못함|
| LIFE_CHANGED |2|초기 identity 없음 또는 마지막 대상 수명이 달라짐|
| TARGET_GONE |4|호출자가 원래 대상 객체를 더 이상 관측할 수 없음|
| HP_DEPLETED |8|양수였던 HP가 관측 시 0 이하|
| LEGACY_UNTRACKED |16|registry 계약이 없는 독립 scope|
| IDENTITY_UNVERIFIED |32|legacy scope 또는 마지막 수명 adapter 없어 정체성 확신이 제한됨|

`is_legacy_kill_candidate`는 LIFE_CHANGED/HP_UNKNOWN을 제외하고 HP_DEPLETED/TARGET_GONE을 기존 gameplay의 처치 후보로 분류한다. 레거시 보상을 보존하기 위해 UNVERIFIED도 후보가 될 수 있다. 이 함수는 권한 서버의 사망 확정/랭크 보상 API가 아니다. HP_DEPLETED는 부활/무적/흡수/반사를 판정하지 않으며 실제 피해량도 반환하지 않는다. TARGET_GONE은 identity를 다시 증명할 수 없는 관측으로 기존 wave 정책만 보존한다. 서버에서는 actor가 피해 확정 지점에서 생성한 영수증과 권한 source 검증이 필요하다.

## 마지막 개체 수명

registry.activate의 새 수명 등록 때 Node metadata `_battle_last_entity_handle`에 Vector3i를 저장한다. 기존 활성 등록의 반복 activate는 같은 수명이며 새 generation을 만들지 않는다. retire는 현재 handle의 resolve 권한만 없애고 metadata는 남긴다. 다음 activate는 이 값을 새 handle로 덮는다. get_last_handle은 metadata 형식/양수/현재 epoch를 확인한다.

- 같은 Node가 재사용 후 다시 retire되면 마지막 handle이 이전과 달라져 파동이 이전 kill을 집계하지 않는다.
- 다른 Node가 이전 슬롯을 재사용해도 원래 Node의 마지막 값은 바뀌지 않으므로 정상 사망 보상을 유지한다.
- queued 대상도 관측은 가능하지만 resolve는 null. epoch 변경은 기록을 거절한다.
- 마지막 handle은 관측용이다. resolve/command validation을 우회하지 않으며 클라이언트가 만든 metadata를 서버 사망 영수증으로 신뢰하지 않는다.
- 타깃이 풀 재사용 뒤 콜백 안에서 HP0으로 바뀐 경우에도 새 generation으로 구분한다. 완전히 사라진 대상의 과거 피해/사망 확정값은 다음 actor receipt 단계가 맡는다.

광전사 wave에만 최초 연결했다. source/projectile callback 수명 확인, 적중 회복→처치 보상 순서, 정상 피해·관통·중복 규칙은 유지한다. 다른 피해 호출은 아직 이 계약을 쓰지 않는다.

## 비용

Node당 metadata 1개/Vector3i 값, 새 activation 때만 갱신한다. 과거 수명 목록/강한 Node 참조 없음. 이미 살아있는 actor/pool node 수에 비례해 bounded storage를 사용하며 registry 슬롯도 기존 peak capacity 정책을 유지한다. 관측 함수는 scalar bit/HP/handle만 처리하고 조회 평균 O(1). 피해/프레임마다 새 객체/WeakRef/컨테이너/그룹 스캔 없음. FPS/로딩/장기 RAM 개선은 실측하지 않았다.

## 검증

Godot4.5.1 headless. 실제 registry/관측 코드, 실제 battle adapter 추출, 실제 projectile lifecycle/sweep 실행. damage/알림/렌더링/query/pool은 spy이며 실제 slime/Hero/초월 부활 씬을 실행하지 않았다.

| 검사 | 결과 |
|---|---:|
| 새 계약: active/retired/resolve 권한 구분, 다른 Node 슬롯 reuse, 같은 Node reuse→retire, 1,000회 generation/관측/이전 수명 거절, 슬롯1개/metadata1개 유지, epoch/queued/malformed/missing/legacy/fallback/HP0·부활 관측 |3,025 통과|
| 기존 registry |76 통과|
| 파동(기존926 + 재사용→retire/다른 Node 슬롯 reuse2) |928 통과|
| 얼음/폭풍 회귀 |634 통과|
| 연쇄단검 회귀 |759 통과|
| 이번 실행 합계 |5,422 통과, 실패0|

원래 registry9/battle209 함수 본문은 activate의 정확한 metadata hook만 역변환해 비교한다. projectile 기존30 및 이전28/15 함수도 정확한 변경 역변환으로 비교했다. gdparse/Python compile/git diff check/독립 editor import 통과. 최종 관측/wave verbose 스크립트 ERROR/WARNING/잔류 객체 없음. SDL misc2 출력은 엔진 환경 메시지. 전체 Godot4.7 게임·실제 물리/부활/오디오/GPU·모바일·서버·장기 RAM은 미검증이다.

```sh
git show 7a3ae7ecf044d862691953b8e2940904db268eea:src/systems/battle_entity_registry.gd > /tmp/damage-registry-before.gd
git show 7a3ae7ecf044d862691953b8e2940904db268eea:src/battle/battle.gd > /tmp/damage-battle-before.gd
python3 tests/build_damage_observation_fixture.py /tmp/damage-observation-fixture --registry-baseline /tmp/damage-registry-before.gd --battle-baseline /tmp/damage-battle-before.gd
godot --headless --path /tmp/damage-observation-fixture --script res://tests/damage_observation_smoke.gd
```

## 다음 단계

1. 일반 몬스터 실제 피해 확정 지점에 accepted/HP damage/shield absorbed/kill 또는 revival 분리 계약을 작은 호환 API로 추가한다. 기존 void 호출은 유지하며 결과가 필요한 경로만 opt-in한다.
2. 값 버퍼 또는 caller-owned 재사용 buffer를 사용하고, reentrant 피해가 외부 결과를 덮지 않는 invocation revision/sequence를 설계한다. 매 피해 객체/컨테이너 할당은 피한다.
3. Hero와 초월의 무적·반사·부활 순서를 보존하면서 계약 적용을 확대한다. source/target handle과 damage sequence가 실제 확정 시점에 기록되도록 한다.
4. 권한 서버의 피해 영수증/스냅샷은 별도 계약으로 정의한다. 클라이언트 관측 플래그가 랭크 결과를 결정하지 않게 한다. 전체 스킬·행동 직렬화·네트워크/용사 입력은 계속 미완료다.

이번 커밋 전체를 git revert하여 registry/battle adapter/관측 helper/파동/fixture/docs를 함께 복원할 수 있다. helper만 제거하면 projectile preload가 깨진다. main 병합/강제 push 없음.
