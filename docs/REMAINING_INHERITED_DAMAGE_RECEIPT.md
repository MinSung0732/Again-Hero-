# 메두사·설녀·주술 미라·크라켄 상속 피해 결과

2026-10-10. 작업 `feature/stage10-astra`, 기준 `f1670f15d79eaf530ac68327cb69b39517b15784`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0`.
수정 전 최신 파일 blob: medusa `bceefcac6e746d1c1b1431665a0a8907770ae889`, yuki_onna `121e0a9334e23dd471ad873c580d63d0efe31869`, powwow_mummy `a73f34d780d5664759c088d16a7b1218cac882fd`, kraken `7446862df61544ca55abc892157131761c3b49de`.

## 구현 및 보존

네 actor는 기존 부모의 incoming 피해 본문을 그대로 사용한다. 메두사/크라켄은 Orc, 설녀/주술 미라는 GoblinThrower의 take_damage_with_result를 상속한다. 각 script 경로 capability를 명시하고 다른 파생 script override가 자동으로 지원되도록 풀어주지 않는다. 기존 파동 caller가 capability를 확인하므로 새 caller 수정은 없다.

자식 사망이 있는 세 actor는 기존 zero-argument _begin_death를 유지하고 _begin_death_with_result를 추가한다. 두 경로는 actor별 고유 cleanup helper로 모인다. helper는 실제 부모 결과용 사망 함수를 호출하며 null receipt로 실행되는 legacy 결과는 기존 common 동작과 같다. 주술 미라는 사망 override가 없어 부모 전체 경로를 그대로 사용한다.

| actor | 유지한 사망/피해 의미 |
|---|---|
| 메두사 | 부모 Orc HP/분노/돌진, 부모 사망 후 기존 redraw |
| 설녀 | 부모 투척수 HP/보호막, 이미 dying일 때 return, yuki runtime record_death→common guard |
| 주술 미라 | 부모 투척수 HP/보호막/사망, 기존 버프/투사체/쿨타임 처리 함수 본문 unchanged |
| 크라켄 | 부모 Orc HP/분노/돌진, 이미 dying return, burst_count=0→기존8방향 촉수 FX/strike→common guard |

크라켄은 실제 BEHAVIOR.DEATH count/radius/damage_divisor를 유지한다. 촉수는 기존 global_position을 중심으로 위치를 계산하고 기존 scale.x를 FX에 전달한다. 기존 _strike가 유효 target/피해 method/실제 hit radius를 검사하고 damage를 적용한다. 사망 공격에는 grow=false를 전달하는 기존 정책을 유지하며 growth_hits/stacks를 추가하지 않는다. 공격 패턴·회피·성장·스킬 상태이상·AI는 변경하지 않았다.

receipt는 caller 소유 재사용 scalar buffer다. HP/보호막은 실제 부모 계산 지점에서, death_started는 실제 common guard에서 기록한다. 자식 사망 callback이 먼저 dying을 설정하면 HP 피해는 기록하지만 실제 사망 시작은 확정하지 않는다. 사망 촉수 callback이 같은 buffer를 재사용하면 이전 revision finish=false로 결과 사용을 거절하며 damage를 재호출하지 않는다.

common/receipt/projectile 및 부모 actor는 이번에 변경하지 않았다. 온라인 시제품·용사모드·매칭을 확대하지 않았다. 다른 특수 incoming actor/초월 부활·상태이상 결과 계약은 남아 있다.

## 비용 및 검증

- 신규 네 actor 각각 receipt1,148+파동638 =7,144검사.
- 크라켄 HP/지원 보호막/실제8방향 위치·scale·범위/피해·성장 제외·버퍼 overwrite 및 설녀 알림/guard 특수652검사.
- 기존 Orc1,148/증강1,202+슬라임1,148/파동638+상속 특수4,030 =8,166검사.
- 총15,962검사, 실패0. Godot4.5.1 headless 실제 부모·자식 extends 및 크라켄 _strike를 실행했다. 최종 로그 ERROR/WARNING/leak 없음.
- 원래 메두사10/설녀11/주술 미라9/크라켄11함수 hook 역변환 본문 비교 통과. 기존 하위 builder의 actor/common/projectile 보존 검사도 통과.
- gdparse/Python compile/독립 editor import/staged diff 검사 통과.

fixture의 scene 초기화·시각·촉수 표시와 yuki runtime은 spies다. 대상 HP/피해 callback은 spy이고 크라켄이 해당 target에 실제 _strike를 수행하는 범위·피해 경로를 확인한다. 전체 게임4.7/실제 animation/FX·충돌·AI/모바일/부하 성능은 미검증이다. 이 문서의 remaining은 이번 남은 상속 조사 묶음이며 모든 몬스터 작업 완료를 뜻하지 않는다.

새 capability/dispatch는 O(1) 고정 작업이며 매 피해 receipt/Array/Dictionary/전체 스캔을 추가하지 않았다. 크라켄 사망의 기존8회 loop는 그대로다. 실행시간·메모리 개선 수치는 측정하지 않았다.

## 재현

build_remaining_inherited_receipt_fixture.py는 checkout 외부에 독립 프로젝트를 생성한다. 네 actor/catalog baseline은 기준 feature에서 추출한다. wolf/scorpion baseline=1f5458d1ec9d81d6b0b0165440eae90a4d6c3564, orc/spider=e0f340f16869a12c0a03594f9d65de2dcbc50b7b, projectile=e4221dfde1ed16f55f51e8fb134857a5659b1ec9, wave=7739fa3d75c25e2fa13ee28e71c5659a7e77756b, slime/common=4e50e15ce201d25025167d1da5410ee518af0801이다.

```bash
python3 tests/build_remaining_inherited_receipt_fixture.py /tmp/finish-fixture \
 --medusa-baseline /tmp/finish-medusa-before.gd \
 --yuki-onna-baseline /tmp/finish-yuki_onna-before.gd \
 --powwow-mummy-baseline /tmp/finish-powwow_mummy-before.gd \
 --kraken-baseline /tmp/finish-kraken-before.gd \
 --catalog-baseline /tmp/finish-kraken-catalog.gd \
 --wolf-baseline /tmp/inherit-wolf-before.gd \
 --scorpion-baseline /tmp/inherit-scorpion-before.gd \
 --orc-baseline /tmp/inherit-original-orc.gd \
 --spider-baseline /tmp/inherit-original-spider.gd \
 --projectile-baseline /tmp/expand-projectile-before.gd \
 --wave-baseline /tmp/expand-wave-before.gd \
 --slime-baseline /tmp/expand-slime-before.gd \
 --common-baseline /tmp/expand-common-before.gd
```

Godot --headless --path /tmp/finish-fixture --script res://tests/NAME_smoke.gd: medusa_receipt, medusa_wave_receipt, yuki_onna_receipt, yuki_onna_wave_receipt, powwow_mummy_receipt, powwow_mummy_wave_receipt, kraken_receipt, kraken_wave_receipt, remaining_inherited_receipt, orc_receipt, orc_receipt_augment, slime_receipt, wave_receipt, inherited_damage_receipt.

## 롤백과 다음

이 변경 커밋만 git revert하면 네 actor가 기존 unsupported/void 경로로 돌아간다. 부모 사망 signature 호환성 복구는 유지된다. main 변경 없음. 다음은 서큐버스 등 특수 incoming actor 및 초월 생존/상태이상 결과 경계이며 실제 매칭·용사모드 확대는 보류한다.
