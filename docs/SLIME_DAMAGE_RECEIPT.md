# 슬라임 피해 결과 버퍼 — 첫 opt-in API

2026-10-10. 기준 feature `4e50e15ce201d25025167d1da5410ee518af0801`. 작업 `feature/stage10-astra`. main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

수정 전 blob: slime `b2713a409f13067aa8c5c9bb4ff4d7d69697bf7f`, common `47e5300c523542d073d7690f1f58dfb9b652ddab`. 다운로드 뒤 hash-object로 확인했다. 얇은 checkout에 없던 원격 파일 전체를 보존하고 해당 피해/사망 함수만 수정했다.

## API와 의미

caller는 battle_damage_receipt.gd 인스턴스를 한번 생성하여 재사용한다. `slime.take_damage_with_result(amount, receipt) -> bool`은 피해를 적용하고 반환 true일 때만 해당 호출의 완성된 결과를 읽도록 한다. 기존 `take_damage(amount)->void` API는 같은 실제 처리 본문으로 위임하고 결과 없이 실행한다. 실전 caller는 이번 단계에서 기존 API를 유지한다. 새 API 최초 연결은 다음 파동 단계다.

| 결과 | 의미 |
|---|---|
| revision | begin마다 증가, 같은 buffer의 이전 쓰기 거절 |
| victim_life / victim_instance_id | 호출 시작 당시 대상의 값 식별자, Node 소유하지 않음 |
| identity_verified | 시작 때 scope registry handle이 같은 대상을 resolve했는지 |
| requested_damage | 호출자가 요청한 정수 피해 |
| hp_damage | HP 감소 계산 직후 확정한 실제 HP 감소량 |
| shield_absorbed | 공통 shield 계산 직후 확정한 흡수량 |
| accepted | HP 또는 shield에 양수 피해가 적용됨 |
| death_started | 실제 begin_standard_death의 dying guard를 통과하여 사망 처리를 시작함 |
| complete | 같은 revision의 처리가 반환까지 완료됨 |

complete는 피해 수락과 다르다. 죽은 대상/0피해/막힌 피해도 호출 처리가 정상 종료되면 true이며 accepted=false일 수 있다. 죽음은 HP 전후 추정으로 기록하지 않는다. 실제 공통 death guard 뒤에 기록하므로 이미 dying인 대상은 death_started가 false다. HP/흡수량은 popup/hit callback 이전에 기록하고, death_started는 died 신호 전에 기록한다. 사망 신호에서 대상이 재사용돼도 결과에는 원래 수명/피해가 남는다. 사망 animation 완료나 서버 승패 확정이라는 뜻은 아니다.

등록되지 않은 actor도 기존 피해를 적용하지만 victim_life=ZERO 및 identity_verified=false다. 이 결과는 서버 권한 판단에 사용할 수 없다. identity_verified도 로컬 시작 시점의 registry 관측이며 실제 권한 서버 검증을 대체하지 않는다.

## 재진입과 상속

buffer는 invocation revision을 가진다. 같은 buffer로 중첩 피해가 begin되면 새 revision/결과를 만들고, 이전 호출의 shield/hp/death/finish 쓰기는 무시한다. 이전 take_damage_with_result는 false를 반환한다. 이때 피해 자체는 기존대로 실행되며 false를 재시도 사유로 삼으면 안 된다. caller는 결과 사용만 중단한다. 두 결과를 모두 유지해야 하는 중첩 경로는 각각 caller-owned buffer를 준비해야 한다. 외부 루프에서 다음 begin 전에 필요한 값만 읽어 복사한다. 모든 source/shot 수명 검증도 별도로 유지해야 한다.

slime의 receipt 구현을 상속한 다른 script가 자체 take_damage를 override할 경우 이를 우회하면 안 된다. supports_damage_receipt는 구현 소유 script 경로를 확인한다. unsupported script는 동적 legacy take_damage를 1회 호출하고 false/incomplete를 반환한다. null receipt도 기존 피해를 1회 적용하고 false다. export에서 script 경로 guard가 unsupported로 판정돼도 legacy 피해 fallback은 유지되지만 opt-in 결과 지원 여부는 실기기 확인 대상이다.

## 구조와 비용

slime 기존 본문을 _apply_slime_damage로 분리했다. legacy void와 새 API가 이 본문을 공유한다. common consume_support_shield의 기존 int API는 _consume_support_shield로 위임하며 같은 오라 계산/흡수/metadata/표시를 유지한다. nullable receipt 인자로 흡수량을 표시 전에 기록한다. begin_standard_death에 optional receipt/revision을 추가하며 기존 모든 호출은 기본값을 써서 기존 의미를 유지한다.

caller당 reusable RefCounted buffer1개, 고정 scalar 필드. 매 피해 객체/Array/Dictionary/WeakRef 생성 없음, 과거 receipt 목록 없음. 정수 수치는 GDScript int64로 유지하여 Vector3i packet의 int32 절단을 피한다. identity와 flags는 O(1) 값, registry 조회 평균 O(1). legacy wrapper의 고정 함수 호출은 추가되므로 FPS 개선을 주장하지 않는다. actual shield/death helper의 일부 nullable 분기 비용은 늘지만 루프/스캔/비대칭 성장 비용은 추가하지 않는다.

아직 모든 actor의 callback 재사용/오라·반사 경계를 강화한 것은 아니다. 기존 계산/신호 의미를 보존하며 슬라임의 처리 지점 결과를 기록하는 첫 단계다. Hero/초월의 부활·무적·리액션 결과와 권한 source/피해 sequence/직렬화는 별도 후속이다.

## 검증

Godot4.5.1 headless. 실제 slime 피해/죽음 위임과 실제 common 오라/보호막/표준 death 함수, 실제 receipt/registry를 실행했다. 렌더링/팝업/오라 제공 authority/visual은 spy다. 본래 전체 slime의 이동/콜리전/리소스/실제 화면을 실행한 것은 아니다.

| 검사 | 결과 |
|---|---:|
| Before/After HP4×shield3×amount6×aura3 =216조건, 상태/순서·정확한 HP/shield·accepted/death·identity/request 각5검사 |1,080 통과|
| legacy shared shield wrapper 54조건 |54 통과|
| void/null/derived override, 같은/다른 buffer 중첩, shield popup 상태 변경, death 재사용/queued, 실제 death guard, int64 counts, 등록 confidence |14 통과|
| 합계 |1,148 통과, 실패0|

원래 slime14/common27함수는 분리/기록 hook만 정확히 역변환해 본문 비교했다. gdparse/Python compile/git diff check와 독립 editor import 통과. 최종 verbose 스크립트 ERROR/WARNING/잔류 객체 없음. SDL misc2 출력은 엔진 환경 메시지. 기존 Hero/projectile fixture는 해당 소스가 이번에 변경되지 않아 다시 실행하지 않았다. 전체 Godot4.7 게임·모바일/export·실제 시각·충돌·Hero/초월 부활·서버·성능/장기 RAM은 미검증이다.

```sh
git show 4e50e15ce201d25025167d1da5410ee518af0801:src/monsters/slime.gd > /tmp/receipt-slime-before.gd
git show 4e50e15ce201d25025167d1da5410ee518af0801:src/monsters/monster_runtime_common.gd > /tmp/receipt-common-before.gd
python3 tests/build_slime_receipt_fixture.py /tmp/slime-receipt-fixture --slime-baseline /tmp/receipt-slime-before.gd --common-baseline /tmp/receipt-common-before.gd
godot --headless --path /tmp/slime-receipt-fixture --script res://tests/slime_receipt_smoke.gd
```

## 다음과 롤백

다음은 광전사 파동의 opt-in caller 연결이다. source/shot 검증과 기존 모든 monster fallback은 유지하며 receipt 지원 actor만 확정 결과를 사용한다. 이후 일반 몬스터 확대와 Hero/초월 부활 별도 결과 분리를 진행한다. 같은 buffer 재진입 false의 결과를 보상에 쓰거나 피해를 재시도하지 않는다.

전체 커밋 git revert로 slime/common/receipt/tests/docs를 함께 복원한다. receipt helper만 삭제하면 새 caller/fixture가 깨진다. main 병합/강제 push 없음.
