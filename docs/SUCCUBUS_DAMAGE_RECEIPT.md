# 서큐버스 잠입·회복·실제 사망 결과

기준 feature: eb5772753b5f797ffa5ca312b980e48cb3006b77. main: 4122adb73e14552aae7c0aa7edefb2827f5d08d0. 수정 전 succubus.gd blob: 6151b8a92d3dc5d9614c6becda261f5a11af082a.

## 계약과 보존

서큐버스 자체 incoming 피해 처리에 opt-in take_damage_with_result를 추가했다. caller 소유 scalar receipt를 재사용하며 기존 void take_damage도 같은 본문을 실행한다. canonical script capability guard로 새 파생 스크립트의 take_damage override를 우회하지 않는다. 미지원/null 결과에서는 legacy 호출을 한 번만 수행하고 false를 반환한다.

| 경계 | 유지한 의미 |
|---|---|
| 입력 거절 | amount<=0, dying, HP<=0, 잠입 중에는 피해/보호막 변화 없음 |
| 왈츠 | 기존 감소/round/최소0를 한 번 적용한 뒤 지원 보호막 계산 |
| 보호막 | 실제 흡수량 기록; 완전 흡수는 HP/잠입 조건을 실행하지 않음 |
| 최초 생존 | 치명타 또는 위험 감지 증강 조건이면 HP를 최소1로 제한하고 잠입; 사망 아님 |
| 회복 증강 | HP1 제한 후 실제 피해량을 먼저 기록하고 기존 잠입 회복 실행 |
| HP1 치명타 | 피해0·accepted=false일 수 있어도 잠입이 시작됨; 전환을 피해로 간주하지 않음 |
| 실제 사망 | 잠입 소진 후 common death guard 통과 지점만 death_started=true |
| 사망 정리 | 왈츠 취소→부모 사망→redraw 순서, 기존 zero-argument override 호환성 유지 |

잠입은 기존3초 타이머, Hero 감지 숨김 및 revision 무효화, collision layer/mask와 shape.disabled 저장/복구, separation flag 저장/복구, 이동 lock, alpha 및 종료 후 stat scaling을 그대로 사용한다. 상태이상/공격/텔레포트/AI/증강 수치는 변경하지 않았다.

피해 기록은 popup 및 회복 callback 전에 수행한다. 같은 buffer를 callback에서 begin하면 이전 finish=false로 거절하고 최신 결과를 보존한다. 기존 광전사 파동은 capability를 통해 자동 연결되며 최초 생존을 처치로 집계하지 않는다. 결과 무효화 때 피해 재호출/HP 기반 처치 추론은 없다. 지원 보호막/common/부모/projectile/네트워크 시제품은 이번에 변경하지 않았다.

## 비용과 검증

- 새 capability/dispatch/기록은 O(1), 매 피해 receipt/Array/Dictionary/그룹 스캔을 추가하지 않았다. 메모리는 caller가 보유한 기존 buffer를 재사용한다. 실측 실행시간/RAM 개선 수치는 측정하지 않았다.
- Godot4.5.1 headless: 서큐버스 기본 결과1,148 + 실제 파동638 + 잠입/회복 특수2,009 =3,795검사.
- 기존 Orc1,148/증강1,202 + 슬라임1,148/파동638 + 상속 특수4,030 =8,166검사.
- 총11,961검사, 실패0. 최종 로그 ERROR/WARNING/leak 없음.
- 원래 서큐버스18함수의 hook 역변환 본문 비교 통과. 부모/common/projectile 및 늑대/전갈 기존 본문 검사 통과. gdparse/Python compile/독립 editor import/diff 검사 통과.

fixture는 실제 Orc/Succubus extends 및 실제 피해·잠입·회복·common shield/death·Hero 감지 정책과 파동 함수를 추출한다. 시각/팝업/authority는 spies이며 CollisionShape2D deferred disabled 저장/복구를 확인했다. 전체 프로젝트4.7, 실제 AI/텔레포트·충돌 물리/애니메이션/모바일/부하 성능은 미검증이다. 이것은 온라인 권위 판정이나 실제 매칭 구현이 아니다.

## 재현

build_succubus_receipt_fixture.py는 checkout 외부에 독립 프로젝트를 만든다. succubus/catalog/policy baseline은 위 feature에서 raw source로 추출한다. 나머지 baseline: wolf/scorpion=1f5458d1ec9d81d6b0b0165440eae90a4d6c3564, orc/spider=e0f340f16869a12c0a03594f9d65de2dcbc50b7b, projectile=e4221dfde1ed16f55f51e8fb134857a5659b1ec9, wave=7739fa3d75c25e2fa13ee28e71c5659a7e77756b, slime/common=4e50e15ce201d25025167d1da5410ee518af0801.

```bash
python3 tests/build_succubus_receipt_fixture.py /tmp/s-fixture \
 --succubus-baseline /tmp/s-succubus-before.gd \
 --catalog-baseline /tmp/s-succubus-catalog.gd \
 --policy-baseline /tmp/s-target-policy.gd \
 --wolf-baseline /tmp/inherit-wolf-before.gd \
 --scorpion-baseline /tmp/inherit-scorpion-before.gd \
 --orc-baseline /tmp/inherit-original-orc.gd \
 --spider-baseline /tmp/inherit-original-spider.gd \
 --projectile-baseline /tmp/expand-projectile-before.gd \
 --wave-baseline /tmp/expand-wave-before.gd \
 --slime-baseline /tmp/expand-slime-before.gd \
 --common-baseline /tmp/expand-common-before.gd
```

Godot --headless --path /tmp/s-fixture --script res://tests/NAME_smoke.gd: succubus_receipt, succubus_wave_receipt, succubus_receipt_special, orc_receipt, orc_receipt_augment, slime_receipt, wave_receipt, inherited_damage_receipt.

## 롤백과 다음

이 변경 커밋만 git revert하면 서큐버스는 기존 unsupported/void 경로로 돌아간다. 기존 부모 사망 signature 호환성 복구는 유지된다. main 변경 없음. 다음 후보는 불가살 등의 초월 incoming 피해·생존/부활 및 상태이상 결과 경계이다. 실제 매칭·용사모드 확대는 계속 보류한다.
