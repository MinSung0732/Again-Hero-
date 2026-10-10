# 상속 사망 호환성과 늑대·전갈 피해 결과

2026-10-10. 작업 `feature/stage10-astra`, 기준 `1f5458d1ec9d81d6b0b0165440eae90a4d6c3564`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0`.
수정 전 파일 blob: wolf `eab515b00f6bcd2847bdd8634996c1ef42a65337`, scorpion `cd3b0092b985379c993c35e96963b98fe314476c`, orc `3abb3df361e05c474b3362b12f6b35d375160073`, goblin_thrower `ec0e93a29953cad85c0664a3260a800587aa3298`, mummy `de3dd4e6bcd12542fb08930fbe423d8c6915e3a4`.

## 상속 호환성 수정

이전 receipt 작업에서 부모 Orc/GoblinThrower의 _begin_death()에 optional 인자를 추가했다. 기존 자식의 zero-argument override와 시그니처가 달라 Godot4.5.1 실제 상속 fixture에서 Parse Error가 발생함을 확인했다. 기존 단일 actor 함수 추출 fixture는 이 상속 충돌을 포착하지 못했다. 이번에는 부모·자식 script를 실제 extends로 연결해 검증한다.

기존 _begin_death()는 zero-argument로 복구한다. 새로운 _begin_death_with_result(receipt,revision)가 부모의 고유 표준 사망 helper로 결과를 넘긴다. void 피해 경로는 기존 동적 _begin_death()를 사용한다. 지원 actor의 receipt 경로만 별도 함수로 들어간다. 공통 사망 guard/시각/신호 순서 자체는 그대로다. 미라는 새 별도 함수를 호출하도록 갱신한다.

원격 소스 조사에서 늑대·전갈 외에 medusa/kraken/succubus/bulgasal과 zeus/manticore/shuten_doji/izanami/yuki_onna가 기존 zero-argument override를 가진 것을 확인했다. 이 actor들의 함수/스킬은 수정하지 않고 부모의 기존 signature를 복구한다. 전체 actor scene/assets를 로드한 것은 아니며 모든 초월 전투의 검증 완료를 의미하지 않는다.

## 늑대와 전갈

| 처리 | 보존한 의미 |
|---|---|
| 늑대 감소 | howl_timer>0 및 wolf_iron_howl일 때 양수 피해를50% 반올림·최소1, 음수/0은0; 지원 보호막 이전에1회 |
| 늑대 원래 요청 | receipt.requested_damage는 감소 전 amount, HP/보호막은 실제 감소 후 수치 |
| 늑대 부모 처리 | 기존 Orc 분노/마지막 돌진·popup/hit/사망 순서 유지 |
| 늑대 피격 모션 | howl/pack cast 중 play_hit 억제 유지 |
| 늑대 사망 | 연격 target/울부짖기/무리 cast/적중 카운트 정리→무리 사망 알림→실제 common guard |
| 전갈 피해 | incoming 본문 그대로 부모 API 상속, 자체 script 경로 capability 명시 |
| 전갈 사망 | 연격 target 해제→기존 독장판 생성→실제 common guard→redraw |
| 전갈 흡수 | consume_without_rewards는 consumed metadata와 HP0, 기존 void 사망 경로 유지; 신규 피해 이벤트로 바꾸지 않음 |

늑대는 기존 void와 receipt가 공유하는 _apply_wolf_damage에서 감소를 적용한 뒤 실제 부모 _apply_orc_damage를 호출한다. 전갈은 부모 take_damage_with_result를 그대로 사용한다. 두 actor의 기존 _begin_death는 고유 내부 cleanup helper를 호출하고 결과용 사망 함수도 같은 cleanup을 공유한다. 이미 dying이면 기존대로 알림/독장판을 다시 만들지 않는다. 파생 actor script 경로 guard는 유지한다.

receipt는 caller 소유 재사용 buffer이며 callback 이전 실제 계산 지점에서 기록한다. 같은 buffer의 중첩 hit는 이전 revision을 무효화하며 피해 재시도를 하지 않는다. death_started는 실제 common guard 통과이며 무리/독장판 callback이 먼저 guard를 닫으면 실제 처치로 확정하지 않는다. 이번에는 스킬 상태이상·온라인·네트워크 시제품을 확장하지 않았다.

## 검증과 비용

Godot4.5.1 headless 실제 부모·자식 상속 fixture에서 다음을 실행했다.

- 늑대/전갈 각 receipt1,148+파동638 =3,572검사.
- 감소/round/지원 보호막/부모 분노·돌진/모션 억제/무리 알림/전갈 독장판·흡수/legacy override 컴파일·단일 호출/파동 특수4,030검사.
- 부모 Orc1,148+파동638+증강1,202, 슬라임1,148+파동638 =4,774검사.
- 투척수1,148+파동638 =1,786검사.
- 미라1,148+파동638+보호막/유령 특수1,812 =3,598검사.
- 합계17,760검사, 실패0. 최종 로그에 ERROR/WARNING/leak 없음.

기존 늑대13/전갈11함수는 hook 역변환 후 본문 동일하다. 기존 builder의 부모 Orc17/거미16 및 투척수18/미라14 등 source 보존 검사도 통과했다. Python compile/gdparse 및 독립 fixture editor import/실제 변경 diff 검사 통과.

표시·타겟 권한·무리 runtime·독장판 runtime은 spies다. 실제 부모 damage/죽음 및 자식 cleanup/감소 함수를 연결했고 독장판 피해·전체 AI·애니메이션·충돌은 실행하지 않았다. 전체 Godot4.7/모바일/서버·부하 성능은 미검증이다.

추가 작업은 고정 필드·함수 dispatch의 O(1) 연산이다. 매 피해 새 receipt/Array/Dictionary/그룹 스캔이 없다. 실제 실행시간 개선 수치는 측정하지 않았다.

## 재현

build_inherited_receipt_fixture.py는 checkout 외부에 독립 프로젝트를 만든다. wolf/scorpion baseline은 기준 commit에서, orc/spider baseline은e0f340f16869a12c0a03594f9d65de2dcbc50b7b에서 추출한다. 기존 projectile baseline은e4221dfde1ed16f55f51e8fb134857a5659b1ec9, wave는7739fa3d75c25e2fa13ee28e71c5659a7e77756b, slime/common은4e50e15ce201d25025167d1da5410ee518af0801이다.

```bash
python3 tests/build_inherited_receipt_fixture.py /tmp/inherit-fixture \
 --wolf-baseline /tmp/inherit-wolf-before.gd \
 --scorpion-baseline /tmp/inherit-scorpion-before.gd \
 --orc-baseline /tmp/inherit-original-orc.gd \
 --spider-baseline /tmp/inherit-original-spider.gd \
 --projectile-baseline /tmp/expand-projectile-before.gd \
 --wave-baseline /tmp/expand-wave-before.gd \
 --slime-baseline /tmp/expand-slime-before.gd \
 --common-baseline /tmp/expand-common-before.gd
```

Godot --headless --path /tmp/inherit-fixture --script res://tests/NAME_smoke.gd: wolf_receipt, wolf_wave_receipt, scorpion_receipt, scorpion_wave_receipt, inherited_damage_receipt, orc_receipt, orc_wave_receipt, orc_receipt_augment, slime_receipt, wave_receipt . 투척수/미라 회귀는 기존 ranged/shield builder를 갱신해 각 문서의 baseline/명령으로 생성 후 실행한다.

## 롤백과 다음

호환성 수정과 늑대/전갈 지원은 별도 커밋이다. 새 지원 커밋만 git revert하면 부모 zero-argument 호환성 복구를 유지하면서 두 actor를 기존 void 경로로 되돌릴 수 있다. 호환성 수정까지 함께 revert하면 이전 상속 컴파일 문제가 다시 생기므로 신기능만 되돌리는 것을 권장한다. main 변경 없음.

다음은 남은 상속 actor의 특수 감소/사망·부활 계약과 상태이상 결과 경계다. 실제 매칭/용사모드/온라인 시제품 확대는 보류한다.
