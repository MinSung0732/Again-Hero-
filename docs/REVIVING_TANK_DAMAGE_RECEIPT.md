# 밴시 은신과 듀라한 보호막·부활 피해 결과

2026-10-10. 작업 `feature/stage10-astra`, 기준 `5a150a8f605f08bd17313ed22d74fc290d55255c`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0`.
수정 전 최신 파일 blob: banshee `9b05e54bafcd8671f9691dda847dde734da44405`, dullahan `e41ab708c381a28d960134b136a9afba96dc6381`.

## 변경과 보존

기존 void take_damage와 결과 API가 각 actor의 동일한 실제 피해 본문을 공유한다. caller 소유 receipt의 revision을 시작하고 실제 지원 보호막/자체 보호막/HP 계산 지점에서 기록한다. script 경로 guard는 파생 actor override를 우회하지 않는다. null/미지원 호출은 legacy 피해를 한 번 실행하고 false를 반환하며 피해 재시도는 하지 않는다.

밴시는 죽음/HP0 거절과 기존 은신 감소(설정 multiplier 반올림, 최소0)→지원 보호막→HP→popup/hit/사망 순서를 유지한다. 기존 previous_hp를 지원 보호막 이전에 포착하는 위치도 유지했다. 첫 요청량은 receipt에 그대로 두고 기존 적용 HP 수치를 기록한다. Bat의 기존 사망 helper를 사용하며 부모를 변경하지 않았다.

듀라한은 Orc를 상속하지만 기존 incoming 피해는 부모 분노/돌진 본문을 사용하지 않는다. 자체 본문을 유지하고 실제 사망에서만 부모의 별도 _begin_death_with_result를 호출한다. 기존 _begin_death() signature 및 legacy dispatch는 유지한다.

| 상황 | 결과 및 기존 동작 |
|---|---|
| 지원 보호막만 소모 | 실제 shield_absorbed, accepted=true; 기존 early return |
| 지원+자체 보호막 | 두 흡수량을 합산, 자체 HP 변화 직후 popup 전에 기록 |
| 첫 치명타 | HP 피해 accepted=true, death_started=false; 최초1회 부활 |
| 부활 중 추가 피해 | 기존 거절, accepted=false |
| 부활 소진 뒤 치명타 | 실제 common death guard 시작에서 death_started=true |
| 같은 버퍼 재진입 | 이전 revision writer/finish 거절, 피해 재시도 없음 |

_sync_wall_capacity는 amount/dead/reviving 거절보다 먼저 실행되는 기존 순서를 보존한다. 따라서 거절된 피해에서도 max_hp 변경에 따른 자체 보호막 비율 조정이 일어날 수 있지만 이는 흡수 피해로 기록하지 않는다. 부활 치명타는 실제 _cancel_slam에서 강타 state/target을 해제하고 animation_finished 신호를 disconnect한 뒤 행군/위기 상태를 취소한다. reviving 메타·velocity·collision deferred disable과 death pose 호출 순서를 유지한다.

실제 _tick_revival은 death pose readiness를 기다리고 ONE_SHOT revival_animation_finished 신호로 _complete_revival을 호출한다. 시각 method 미지원 시 기존 즉시 fallback으로 복구한다. 기본 PASSIVE.revive_hp_ratio 또는 immortal_thirst 설정 비율로 HP를 복구하고 reviving/meta/reverse flag·collision을 복원하는 본문을 유지한다. 공격·강타·행군·위기 AI 및 피해를 주는 기술은 변경하지 않았다.

기존 파동 capability가 자동 연결되어 첫 부활 치명타를 처치로 집계하지 않는다. 별도 revival 이벤트 필드는 추가하지 않았다. 상태이상 결과 이벤트/초월 actor 결과 계약 및 다른 피해 caller 전환은 남아 있다.

## 검증과 비용

- 신규 밴시/듀라한 각 receipt1,148+파동638 =3,572검사.
- 듀라한 지원/자체 보호막 비율 동기화·거절 순서/최초 부활·실제 사망/강타 신호 해제/역재생·fallback/파동 부활 및 밴시 감소3,729검사.
- 기존 늑대1,148+전갈1,148+상속 특수4,030+Orc1,148/증강1,202+슬라임1,148/파동638 =10,462검사.
- 총17,763검사, 실패0. Godot4.5.1 headless 실제 Bat/Banshee 및 Orc/Dullahan extends를 사용하는 독립 fixture 실행. 최종 로그 ERROR/WARNING/leak 없음.
- 원래 밴시6/듀라한20함수 hook 역변환 본문 비교 통과. 하위 builder의 기존 actor/common/projectile 본문 보존 검사도 통과.
- gdparse, Python compile, 독립 editor import, staged diff 검사 통과.

fixture의 scene 초기화·시각·타겟 권한은 spies다. 강타 취소 후 실제 signal emit에서 공격 호출이 없음을 확인하며 강타 피해 실행은 spy다. 실제 animation frame/충돌 물리/모바일 및 전체 Godot4.7 게임은 검증하지 않았다. 테스트 helper의 듀라한 전용 초기화가 밴시에도 적용되던 문제를 수정해 추가 테스트와 관련 회귀를 재실행했다.

결과 기록은 고정 scalar O(1) 작업이며 매 피해 새 receipt/Array/Dictionary/전체 스캔을 추가하지 않았다. 실행시간·메모리 개선 수치를 측정한 결과는 없다.

## 재현

build_reviving_tank_receipt_fixture.py의 baseline은 변경 전 Git 파일을 추출한다. banshee/dullahan/catalog는 기준 feature에서, bat는469d20765196e45d5c9bf09c9803ee6a26523a2e, wolf/scorpion은1f5458d1ec9d81d6b0b0165440eae90a4d6c3564, orc/spider는e0f340f16869a12c0a03594f9d65de2dcbc50b7b에서 가져온다. 기존 projectile=e4221dfde1ed16f55f51e8fb134857a5659b1ec9, wave=7739fa3d75c25e2fa13ee28e71c5659a7e77756b, slime/common=4e50e15ce201d25025167d1da5410ee518af0801이다.

```bash
python3 tests/build_reviving_tank_receipt_fixture.py /tmp/more-fixture \
 --banshee-baseline /tmp/more-banshee-before.gd \
 --dullahan-baseline /tmp/more-dullahan-before.gd \
 --bat-baseline /tmp/next-bat-before.gd \
 --catalog-baseline /tmp/more-dullahan-catalog.gd \
 --wolf-baseline /tmp/inherit-wolf-before.gd \
 --scorpion-baseline /tmp/inherit-scorpion-before.gd \
 --orc-baseline /tmp/inherit-original-orc.gd \
 --spider-baseline /tmp/inherit-original-spider.gd \
 --projectile-baseline /tmp/expand-projectile-before.gd \
 --wave-baseline /tmp/expand-wave-before.gd \
 --slime-baseline /tmp/expand-slime-before.gd \
 --common-baseline /tmp/expand-common-before.gd
```

Godot --headless --path /tmp/more-fixture --script res://tests/NAME_smoke.gd: banshee_receipt, banshee_wave_receipt, dullahan_receipt, dullahan_wave_receipt, reviving_tank_receipt, wolf_receipt, scorpion_receipt, inherited_damage_receipt, orc_receipt, orc_receipt_augment, slime_receipt, wave_receipt.

## 롤백과 다음

이 변경 커밋만 git revert하면 두 actor의 기존 void API로 복귀한다. 부모 사망 signature 호환성 복구는 변경하지 않았으므로 그대로 유지된다. main 변경 없음. 다음은 남은 상속 actor·초월 생존/상태이상 결과 경계이며 매칭·용사모드·네트워크 시제품 확대는 보류한다.
