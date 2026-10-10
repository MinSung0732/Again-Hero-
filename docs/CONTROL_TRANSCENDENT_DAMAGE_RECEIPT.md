# 이자나미·슈텐도지 피해 결과 연결

작업 브랜치: `feature/stage10-astra`. 기준 커밋: `bf6f7e58587f964acc66f4551745ff9b0bd8f3ab`.
main 기준: `4122adb73e14552aae7c0aa7edefb2827f5d08d0` (변경 없음).
수정 전 이자나미 blob: `4b137382e9b977375bb35544736b86103a15cad4`.
수정 전 슈텐도지 blob: `62fd7ab28d0eba96c4e6a5535a14f9e0aa91b79f`.

## 범위와 계약

기존 솔플 incoming 피해 경계를 준비하는 단계다. 매칭, 서버 전투, 용사 모드, outgoing 상태이상 집계는 추가하지 않았다. 부모/common/projectile도 이번 단계에서 수정하지 않았다.

| 대상 | 변경 | 보존한 동작 |
|---|---|---|
| 이자나미 | canonical script opt-in, 부모 결과 사망 helper 연결 | Thrower 피해, 기술 배열·교차 기록·보호막 정리, 용사 accepted_damage_hit 연결 해제, redraw 후 부모 사망 |
| 슈텐도지 | void/result가 공유하는 incoming 함수와 사망 helper | 안개 감소·해방 4초월 감소, 지원 보호막, 첫 부활, 5초월 HP50% 조건, 3초 회복, 초과 회복 쉴드, 사망 정리 |

호출자는 기존 BattleDamageReceipt 버퍼를 재사용한다. HP·보호막 실제 차감 직후 기록하고, popup/audio 같은 callback보다 먼저 기록한다. complete 결과만 신뢰하며 같은 버퍼에 중첩 호출이 발생하면 이전 revision은 완료할 수 없다. 결과 실패 시 피해를 재시도하거나 처치를 추론하지 않는다. 파생 스크립트는 opt-in하지 않아 기존 take_damage override를 한 번 호출한다.

슈텐도지 부활은 HP를 최소1로 남긴다. 실제 HP 감소량은 이전 HP에서 이 제한을 적용한 HP를 뺀 값이다. HP1 첫 치명타나 기존 HP0 부활에서는 HP 피해가0일 수 있다. 부활 시작·체력 회복·보호막 생성은 death_started가 아니다. 실제 common 사망 guard가 열렸을 때만 사망을 기록한다. 소비 보호막과 부활 후 새 보호막을 구분한다.

완전 보호막 흡수는 기존처럼 부활 조건 검사 전에 반환한다. 부활 중 피해 거절, 감소 round, overkill popup에 전체 damage를 보여주는 동작, 사망 cleanup→부모 순서를 보존했다. zero-argument _begin_death 시그니처도 유지했다.

## 비용과 한계

추가 비용은 피해마다 O(1)의 scalar 기록과 revision 검사다. 매 피해 객체·배열·전체 그룹 스캔을 만들지 않는다. 사망의 기존 고정 배열 fill/기록 clear 비용은 그대로다. 프레임 시간·메모리 벤치마크나 로딩 속도 개선을 측정한 단계는 아니다.

실제 소스의 _tick_revival은 부동소수 시간·floor로 회복한다. 테스트의 프레임/회복 종료 검사는 정확히 경계값을 더하는 대신 0.16+0.30+2.60초로 마지막 step을 clamp하게 했다. 원본과 신규 코드의 동일 delta 비교도 유지했다. 시간 계산이나 게임 동작을 임의 변경하지 않았다.

## 검증

Godot4.5.1 headless 독립 fixture에서 신규19,484+회귀8,166 = **27,650 검사, 실패0**.

| 검사 | 수 |
|---|---:|
| 이자나미 receipt / wave | 1,148 / 638 |
| 슈텐도지 receipt / wave | 1,148 / 638 |
| 두 초월 특수 경계 | 15,912 |
| Orc / Orc augment / Slime / Wave / inherited 회귀 | 1,148 / 1,202 / 1,148 / 638 / 4,030 |

원본 이자나미31함수·슈텐도지34함수는 기록 hook만 역변환해 함수 본문이 동일함을 비교했다. 실제 부모 피해·common 사망·파동 함수와 실제 슈텐도지 부활 함수를 추출해 실행했다. 신규 gdparse, Python compile, fixture import, git diff whitespace 검사를 수행했다.

검사 범위: 감소 조합/보호막/HP0·HP1/음수·0 피해, 첫 치명타/5초월 threshold equality, 부활 면역/회복·초과 쉴드, 실제 후속 사망, signal 해제와 배열 정리 순서, callback 재진입/같은·별도 버퍼, 파생 override, 파동 처치 보상 제외·실제 처치.

시각·오디오·authority는 spy다. 이자나미 outgoing handler는 연결 해제 확인용 handler로 대체했고 실제 outgoing 스킬·상태이상은 실행하지 않았다. 전체 게임4.7, 모바일, AI·실제 물리, 실제 sprite 렌더링·사운드, 성능은 미검증이다.

## 재현

기존 각 단계 문서의 기준 커밋에서 원본 파일을 확보한다. 이자나미·슈텐도지와 두 behavior catalog는 본 문서 기준 커밋에서 받는다. 테스트 builder는 기준 파일을 변경하지 않는다.

```bash
python3 tests/build_control_transcendent_receipt_fixture.py /tmp/control-receipt \
  --izanami-baseline /tmp/z-izanami-before.gd \
  --shuten-baseline /tmp/z-shuten_doji-before.gd \
  --izanami-catalog-baseline /tmp/z-izanami-catalog.gd \
  --shuten-catalog-baseline /tmp/z-shuten-catalog.gd \
  --wolf-baseline /tmp/inherit-wolf-before.gd \
  --scorpion-baseline /tmp/inherit-scorpion-before.gd \
  --orc-baseline /tmp/inherit-original-orc.gd \
  --spider-baseline /tmp/inherit-original-spider.gd \
  --projectile-baseline /tmp/expand-projectile-before.gd \
  --wave-baseline /tmp/expand-wave-before.gd \
  --slime-baseline /tmp/expand-slime-before.gd \
  --common-baseline /tmp/expand-common-before.gd
Godot --headless --path /tmp/control-receipt --editor --import
```

`--script res://tests/NAME_smoke.gd`로 이름별 실행:
izanami_receipt, izanami_wave_receipt, shuten_doji_receipt, shuten_doji_wave_receipt,
control_transcendent_receipt, orc_receipt, orc_receipt_augment, slime_receipt,
wave_receipt, inherited_damage_receipt.

원본 기준: wolf/scorpion `1f5458d1ec9d81d6b0b0165440eae90a4d6c3564`,
orc/spider `e0f340f16869a12c0a03594f9d65de2dcbc50b7b`,
slime/common `4e50e15ce201d25025167d1da5410ee518af0801`.
projectile blob `e4221dfde1ed16f55f51e8fb134857a5659b1ec9`,
wave blob `7739fa3d75c25e2fa13ee28e71c5659a7e77756b`.

## 검토와 롤백

1. 전체 게임에서 이자나미 사망 시 남은 효과 정리·용사 signal 해제 확인.
2. 슈텐도지 최초 치명타/5초월 HP50% 부활·무적·회복·초과 쉴드·두 번째 실제 사망 확인.
3. 다음 단계에서 제우스 등 남은 incoming·상태이상 경계를 조사한다. 이번 단계가 전체 구조 개선의 완료를 뜻하지 않는다.

롤백은 이번 커밋을 작업 브랜치에서 `git revert <이번 커밋>`으로 되돌린다. 기준 커밋 이전 단계의 결과 API는 유지된다. main 병합은 별도 요청 시 진행한다.
