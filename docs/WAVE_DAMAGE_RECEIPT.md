# 광전사 파동 피해 결과 caller 연결

2026-10-10. 기준 feature `e4221dfde1ed16f55f51e8fb134857a5659b1ec9`, projectile blob `818d7deb399ab62936971313a365df0f87805eb6`. 작업 `feature/stage10-astra`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 처리 계약

파동은 대상에게 supports_damage_receipt와 take_damage_with_result API가 있고 지원 검사도 true면 opt-in API를 1회 호출한다. 결과 buffer는 첫 유효 wave setup에서만 lazy 생성하고 같은 projectile의 pool 수명 사이에도 재사용한다. ice/storm/chain만 사용하는 Node에는 결과 객체를 만들지 않는다.

피해 전에 source/local shot revision, target handle/ID, 다음 receipt revision을 값으로 저장한다. 지원 검사 callback 뒤에도 source/shot과 대상 valid/queued/현재 handle을 확인한다. 피해 뒤 source/shot이 달라지면 기존 수명 경계대로 후속 처리를 중단한다.

유효 결과 조건은 API 반환 true, complete, 예상 receipt revision, victim_instance_id, victim_life 일치, tracked battle의 identity_verified다. 유효한 결과는 accepted와 death_started가 모두 true일 때 처치로 계산한다. HP 차이로 되돌아가 추론하지 않는다. 기존의 target HP0 추론은 미지원 actor에게만 남는다.

실제 슬라임 death callback에서 target이 재사용되어 HP가 복구돼도 receipt는 원래 사망 시작/수명에 속하므로 원래 처치를 인정한다. 반대로 hit visual callback에서 dying=true가 되어 death guard가 거절하면 HP0이어도 처치 보상이 없다. 이는 이전 HP 관측 추정에서 실제 사망 처리 시작으로 판정을 바꾼 의도된 개선이다.

같은 result buffer가 중첩 호출로 덮이거나 API가 false면 이번 처치 결과를 사용하지 않는다. 피해를 재시도하지 않으며 legacy 관측으로 다른 호출의 결과를 대신 쓰지 않는다. source가 유효할 때 적중 알림/회복 시도는 기존의 적중 시도별 정책으로 유지한다. kill bool은 hit callback 전에 값으로 복사하므로 적중 알림에서 buffer를 재사용해도 이미 확정한 이번 처치 값은 유지된다.

## 보존과 비용

- 미지원 actor의 take_damage 1회 및 기존 BattleDamageObservation fallback, actor 자체 피해/부활 구현 유지. 새 몬스터를 content ID로 분기하지 않는다.
- 파동 관통/선분 판정/속도/범위/피해/instance ID별 중복 제거/적중→처치 알림 순서/HP0 emitted source 정책/풀 반납 유지.
- wave-capable projectile Node당 lazy RefCounted buffer1개, 고정 scalar 필드. 풀 재사용200회에도 같은 객체. 매 피해 새 객체/WeakRef/Array/Dictionary/그룹 스캔 없음. 기존 후보 n개는 O(n), 개체/결과 확인 평균 O(1).
- result 객체는 target/source Node를 보관하지 않으며 과거 결과 목록 없음. 이번 결과를 읽기 전에 다음 begin을 하지 않는 계약이다.
- 지원 검사 및 필드 검증의 고정 비용은 추가된다. 실제 FPS/메모리/로딩 개선량을 측정하지 않았다.

## 검증

Godot4.5.1 headless. 실제 projectile setup/sweep/damage/finish/pool lifecycle과 실제 slime 피해/receipt/common shield/death/registry를 조합했다. visual render/popup/source query/notification/pool authority는 spy이고 physics/body 충돌은 엔진으로 발생시키지 않았다. Slime 전체 이동/실제 에셋을 실행한 검사는 아니다.

| 검사 | 결과 |
|---|---:|
| 실 Slime + 파동 Before/After HP4×shield3×damage4×aura3 =144조건, 피해/FX/shield·hit/kill/legacy 혼재·dedup/buffer 각3검사 |432 통과|
| death callback target 재사용, death guard 거절, 중첩 buffer 무효화/미재시도, hit callback result overwrite, source 재사용/new shot |6 통과|
| pooled wave setup/hit200회 buffer 객체 동일/새 요청 유지 |200 통과|
| 신규 소계 |638 통과|
| 기존 wave |928 통과|
| 얼음/폭풍 |634 통과|
| chain |759 통과|
| slime receipt |1,148 통과|
| 합계 |4,107 통과, 실패0|

기준 현재31 함수와 과거30/28/15함수는 정확한 신규 hook 역변환으로 본문 비교한다. 슬라임14/common27본문 비교도 조합 builder에서 통과. gdparse/Python compile/git diff check/독립 editor import 확인. 최종 receipt integration verbose 스크립트 ERROR/WARNING/잔류 객체 없음. SDL misc2 출력은 엔진 환경 메시지다. 전체 Godot4.7 게임·실제 충돌/시각/모바일/export·서버/장기 RAM은 미검증이다.

```sh
git show e4221dfde1ed16f55f51e8fb134857a5659b1ec9:src/hero/archmage_skill_projectile.gd > /tmp/wave-receipt-before.gd
git show 7739fa3d75c25e2fa13ee28e71c5659a7e77756b:src/hero/archmage_skill_projectile.gd > /tmp/wave-before.gd
git show 4e50e15ce201d25025167d1da5410ee518af0801:src/monsters/slime.gd > /tmp/receipt-slime-before.gd
git show 4e50e15ce201d25025167d1da5410ee518af0801:src/monsters/monster_runtime_common.gd > /tmp/receipt-common-before.gd
python3 tests/build_wave_receipt_fixture.py /tmp/wave-receipt-fixture --projectile-baseline /tmp/wave-receipt-before.gd --wave-baseline /tmp/wave-before.gd --slime-baseline /tmp/receipt-slime-before.gd --common-baseline /tmp/receipt-common-before.gd
godot --headless --path /tmp/wave-receipt-fixture --script res://tests/wave_receipt_smoke.gd
```

## 한계·다음 단계·롤백

현재 receipt 실제 지원은 slime 구현 소유 script만이다. 거미·오크 등 일반 몬스터로 우선 확대하고 이후 Hero/초월의 부활·반사·무적 결과를 분리한다. legacy fallback은 과거 HP 관측 한계를 그대로 가진다. 미확정 결과는 처치 보상을 생략하므로 동일 caller buffer 재진입을 실제 장기 플레이에서 관찰할 필요가 있다. 전체 피해 source/sequence·권한 서버 사망 확정·직렬화/스냅샷·용사 입력은 아직 미완료다. 로컬 receipt가 네트워크 권한 영수증을 대체하지 않는다.

전체 커밋 git revert로 projectile/fixture/docs를 함께 복원한다. 기존 slime API와 receipt helper는 이전 커밋에 남는다. main 병합/강제 push 없음.
