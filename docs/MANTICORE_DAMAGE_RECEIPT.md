# 만티코어 치명타 생존·후퇴·실제 사망 결과

기준 featurede9eca8aa36e72ae87e57cd38da5eafd6a223b8a, main4122adb73e14552aae7c0aa7edefb2827f5d08d0. 수정 전 manticore.gd blob=d09096ea7881a8fb7638b65423b936f299cd4563, projectile blob=a0fe29aa041ea07005e0ccd3c83cb50f78f0fe70.

## 구현과 기존 의미

만티코어 자체 피해에 caller 소유 재사용 scalar receipt를 받는 take_damage_with_result를 추가했다. 기존 void API와 같은 shared body를 사용하며 canonical capability로 파생 take_damage override 우회를 막는다. null/미지원 결과는 legacy를 한 번만 호출하고 false를 반환한다. 부모 Thrower/common 구현은 변경하지 않았다.

| 경계 | 유지한 동작 |
|---|---|
| dying/amount<=0 | 피해/보호막 변화 없이 거절 |
| 생존 후 guard_remaining>0 | 입력60% round→기존 부모 aura→지원 보호막 순서 |
| 완전 보호막 흡수 | 실제 흡수량만 기록, 생존/HP 변경 없음 |
| 최초 치명타 | escape cue→escaped=true→HP=max(round(max_hp×15%),1)→3초월 guard5초/20%쉴드→유효 Hero가 있으면 사거리2배 후퇴 |
| 이후 피해 | 실제 HP 감소량을 popup 전에 기록; 기존 popup에는 damage 전체 표시 |
| 실제 사망 | 오디오 stop_all/death cue→화염/파동·유성 배열 정리→collision_mask0→effect redraw→부모 common guard |

이번 작업은 기존 밸런스를 유지한다. 현재 구현의 생존 회복은 최대체력15%로 즉시 HP를 지정하며, 이전 요청 문구인 잃은체력15%로 수치를 재설계하지 않았다. 기존 code에는 current_hp<=0 입력 guard가 없어서 최초 HP0도 생존할 수 있고, escaped 상태의 HP0은 기존 사망 guard에 도달할 수 있다. 이를 추가 입력 거절로 바꾸지 않았다.

첫 생존에는 HP0으로 만드는 중간 계산이 원래 없다. receipt.hp_damage는 실제 HP 대입 직전/직후의 양수 감소만 기록한다. 예: max_hp1550에서 HP600→233이면367, HP60→233이면0. 회복량을 음수 피해로 기록하거나 존재하지 않는 HP0 피해 단계를 만들지 않는다. 따라서 보호막도 없고 HP가 늘어난 생존은 accepted=false/death_started=false여도 정상 전환이다. 생성된20% 보호막과 이미 소비한 지원 보호막은 별도이며 receipt에는 소비분만 기록한다.

실제 _start_track/_begin_flight와 _end_motion을 유지한다. Hero 겹침 시 LEFT fallback, effective_range2배 및 4초월 불꽃 사거리 보너스, 기존 전장 clamp, 비행 collision0/ignore separation, 종료 collision 복구·공격 대기시간·idle 정책은 변경하지 않았다. 공격/상태이상/연출/AI는 변경하지 않았다.

HP/보호막은 callback 전 계산 지점에서 기록한다. escape cue는 원래 HP 대입 전에 실행되므로 nested hit가 바꾼 HP를 기준으로 다음 실제 대입의 감소량을 기록한다. 같은 buffer가 재사용되면 outer finish=false로 거절하며 새 결과를 보존한다. HP0 nested hit가 실제 common 사망을 시작하는 경우 새 결과의 death_started=true도 보존한다; 이전 writer의 사망 기록과 구분한다. 사망0인자 override와 결과용 helper를 분리해 부모 시그니처 호환성을 유지했다.

## 파동 보상 경계 보완

검사에서 기존 HP0+보호막 상태의 만티코어가 보호막을 소모하고 common 사망을 시작하는 예외를 확인했다. accepted/death_started만 사용하면 이전 HP 기반 caller에서 주지 않던 처치 보상이 생긴다. 기존 hp_before scalar를 재사용해 receipt 처치 조건에도 hp_before>0을 추가했다. 새 HP 조회·배열·재호출 없이 원래 보상 정책을 보존한다. 실제 사망 결과는 기록하되 이미 HP0인 대상의 새 처치 보상은 제외한다. 적중 알림·기존 피해·pool/수명·미지원 경로는 그대로다.

## 비용·검증

- 신규 dispatch/record/reward gate는 O(1). 매 피해 receipt/Array/Dictionary/전체 그룹 스캔 추가 없음. 기존 고정10/12칸 사망 배열 정리 유지. CPU/RAM 개선 수치는 미측정.
- Godot4.5.1 headless: 기본1,148+실제 파동638+특수7,225 =9,011검사.
- Orc1,148/증강1,202+슬라임1,148/파동638+상속 특수4,030 =8,166회귀.
- 총17,177검사 실패0. 최종8개 실행 로그 및 독립 import ERROR/WARNING/leak 없음.
- 만티코어 원래48함수 hook 역변환 본문 비교 통과. 기존 projectile 보존 검사에 HP0 gate 역변환을 반영했고 부모/common/다른 actor 보존 검사 통과. gdparse/Python compile/독립 editor import/diff 통과.

fixture는 실제 Manticore/Thrower extends, incoming 피해/지원 보호막/생존·후퇴·종료/사망, common guard와 파동을 추출한다. 시각/오디오/authority/전장 clamp는 spies다. 전체 게임4.7/실제 추적 이동·충돌·AI/FX·카메라/청취/모바일/부하 성능은 미검증이다. 본게임 온라인 권위 판정·매칭 완성을 뜻하지 않는다.

## 재현과 롤백

build_manticore_receipt_fixture.py는 checkout 외부 독립 프로젝트를 생성한다. manticore/catalog baseline=위 feature. wolf/scorpion=1f5458d1ec9d81d6b0b0165440eae90a4d6c3564, orc/spider=e0f340f16869a12c0a03594f9d65de2dcbc50b7b, projectile=e4221dfde1ed16f55f51e8fb134857a5659b1ec9, wave=7739fa3d75c25e2fa13ee28e71c5659a7e77756b, slime/common=4e50e15ce201d25025167d1da5410ee518af0801.

```bash
python3 tests/build_manticore_receipt_fixture.py /tmp/m-fixture \
 --manticore-baseline /tmp/m-manticore-before.gd \
 --catalog-baseline /tmp/m-catalog.gd \
 --wolf-baseline /tmp/inherit-wolf-before.gd \
 --scorpion-baseline /tmp/inherit-scorpion-before.gd \
 --orc-baseline /tmp/inherit-original-orc.gd \
 --spider-baseline /tmp/inherit-original-spider.gd \
 --projectile-baseline /tmp/expand-projectile-before.gd \
 --wave-baseline /tmp/expand-wave-before.gd \
 --slime-baseline /tmp/expand-slime-before.gd \
 --common-baseline /tmp/expand-common-before.gd
```

Godot --headless --path /tmp/m-fixture --script res://tests/NAME_smoke.gd: manticore_receipt, manticore_wave_receipt, manticore_receipt_special, orc_receipt, orc_receipt_augment, slime_receipt, wave_receipt, inherited_damage_receipt.

이 커밋만 git revert하면 만티코어는 기존 unsupported/void 경로로 돌아가고 파동 HP0 gate도 이전으로 돌아간다. main 변경 없음. 다음은 이자나미·슈텐도지 등 남은 초월 피해/부활·상태이상 결과 경계 조사이다. 매칭·용사모드 확대는 계속 보류한다.
