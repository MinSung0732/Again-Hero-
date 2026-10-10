# 불가살 특수 피해·피격 집계·사망 결과

기준 feature20c6b654609b88cb2c1918cf5424817f4315bcbb, main4122adb73e14552aae7c0aa7edefb2827f5d08d0. 수정 전 bulgasal.gd blob=e947c8bee7681fb7c53a35d7246db9f78cfc0103.

## 보존한 계약

불가살 자체 피해 guard/피격 집계를 shared _apply_bulgasal_damage로 옮기고 opt-in take_damage_with_result를 추가했다. caller가 소유한 기존 scalar receipt에 실제 부모 계산의 HP/지원 보호막 및 실제 common 사망 시작을 기록한다. 기존 void API와 zero-argument 사망 override를 유지한다. canonical capability guard로 파생 take_damage override를 우회하지 않으며 null/미지원 결과는 legacy 호출1회 후 false를 반환한다.

| 상황 | 기존 동작과 결과 |
|---|---|
| dying/HP0/입력0 이하 | 피격 횟수·HP·보호막 변경 없이 거절 |
| 공중, 4초월 이상 잠복 | 피해와 피격 집계를 모두 거절 |
| 3초월 이하 잠복 | 기존40% round 후 부모 aura→보호막→HP 처리 |
| 잠복 round=0 | HP 피해0이어도 입력 피격 횟수1 증가 |
| 보호막 완전 흡수 | 실제 흡수량 기록, HP 피해0이어도 피격 횟수 증가 |
| 피격10회 도달 | 기존처럼10을 한 번 빼고 retreat_pending1 증가; while 처리로 바꾸지 않음 |
| 사망 | 부모 common guard를 실제 통과할 때만 death_started=true |

피격 집계는 감소/보호막 계산보다 먼저다. 실제 HP 피해가 있는 경우 기존 부모 분노/마지막 돌진 순서를 유지한다. 콘텐츠 스탯/후퇴·기둥·투사체·기술/상태이상·AI는 변경하지 않았다.

사망 정리는 기존 순서대로 잠복 충돌 복구→fragment_states.fill(0)/hit 해제→오디오 중지→감지 숨김 해제→정신집중 취소→바위/파동 취소→시각 visible/position 복구→기둥 finish_death→부모 사망→효과/게이지 redraw를 수행한다. 실제 기둥 finish_death는 shatter_all(false) 후 retiring=true, 전장으로 reparent하여 본체 애니메이션 제거가 기둥 파괴를 자르지 않게 한다. 사망 카메라·슬로우·보상/연출 프로필은 변경하지 않았다.

기둥/audio callback이 common guard 전에 dying을 설정하면 HP 피해는 유지하되 새 사망으로 확정하지 않는다. 동일 receipt를 callback이 재사용하면 이전 finish=false, 최신 결과를 보존하며 피해/정리를 재시도하지 않는다. 기존 광전사 파동은 capability로 자동 연결되고 무효 결과에 legacy 처치 추론을 적용하지 않는다. 부모/common/projectile/기둥/audio/channel 구현 자체와 네트워크 시제품은 이번에 변경하지 않았다.

## 비용·검증·한계

- 신규 dispatch/기록은 O(1), 매 피해 객체/Array/Dictionary/전체 그룹 스캔을 추가하지 않았다. 기존 고정8칸 fragment 정리는 그대로다. CPU/RAM 실측 개선 수치는 측정하지 않았다.
- Godot4.5.1 headless: 불가살 기본1,148+파동638+특수8,184 =9,970검사.
- 회귀: Orc1,148/증강1,202+슬라임1,148/파동638+상속 특수4,030 =8,166검사.
- 총18,136검사 실패0. 최종 로그 ERROR/WARNING/leak 없음.
- 원래 불가살42함수 hook 역변환 본문 비교 및 기존 부모/common/projectile·늑대/전갈 본문 보존 검사 통과. gdparse/Python compile/독립 editor import/원격 기준 diff 검사 통과.

fixture는 실제 Orc/Bulgasal extends, incoming 피해/사망/충돌 복구, 실제 common shield/death·channel·Hero 감지 정책, 실제 기둥 finish_death의 reparent와 실제 파동을 추출한다. 시각/오디오/authority 및 기둥 shatter_all은 spies다. 실제 기둥 파괴·물리 충돌/AI/카메라·스킬 FX/청취/전체 게임4.7/모바일/부하 성능은 미검증이다. 본게임 온라인 권위 판정 또는 매칭 완료를 뜻하지 않는다.

## 재현

build_bulgasal_receipt_fixture.py는 checkout 외부에 독립 프로젝트를 만든다. bulgasal/catalog/channel/policy/pillars는 위 기준 feature에서 raw source를 추출한다. 나머지 baseline: wolf/scorpion=1f5458d1ec9d81d6b0b0165440eae90a4d6c3564, orc/spider=e0f340f16869a12c0a03594f9d65de2dcbc50b7b, projectile=e4221dfde1ed16f55f51e8fb134857a5659b1ec9, wave=7739fa3d75c25e2fa13ee28e71c5659a7e77756b, slime/common=4e50e15ce201d25025167d1da5410ee518af0801.

```bash
python3 tests/build_bulgasal_receipt_fixture.py /tmp/b-fixture \
 --bulgasal-baseline /tmp/b-bulgasal-before.gd \
 --catalog-baseline /tmp/b-catalog.gd \
 --channel-baseline /tmp/b-channel.gd \
 --policy-baseline /tmp/s-target-policy.gd \
 --pillars-baseline /tmp/b-pillars-before.gd \
 --wolf-baseline /tmp/inherit-wolf-before.gd \
 --scorpion-baseline /tmp/inherit-scorpion-before.gd \
 --orc-baseline /tmp/inherit-original-orc.gd \
 --spider-baseline /tmp/inherit-original-spider.gd \
 --projectile-baseline /tmp/expand-projectile-before.gd \
 --wave-baseline /tmp/expand-wave-before.gd \
 --slime-baseline /tmp/expand-slime-before.gd \
 --common-baseline /tmp/expand-common-before.gd
```

Godot --headless --path /tmp/b-fixture --script res://tests/NAME_smoke.gd: bulgasal_receipt, bulgasal_wave_receipt, bulgasal_receipt_special, orc_receipt, orc_receipt_augment, slime_receipt, wave_receipt, inherited_damage_receipt.

## 롤백·다음

이 변경 커밋만 git revert하면 불가살은 기존 unsupported/void 경로로 돌아간다. main 변경 없음. 다음은 만티코어 등 다른 초월 몬스터의 치명타 생존/부활과 상태이상 결과 경계이다. 매칭·용사모드 확대는 보류한다.
