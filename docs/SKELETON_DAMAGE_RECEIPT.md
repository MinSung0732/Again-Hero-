# 해골 피해 결과와 부활·사망 구분

2026-10-10. 기준 feature `9da63abaed1b79446aa8ead84e1169d1c95159c5`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0`. 수정 전 skeleton blob `d2567bab473179b102e7e331730cb5f0d3e40ebf` 확인. 작업 `feature/stage10-astra`.

## 변경

해골은 기존 void take_damage와 새 take_damage_with_result가 같은 내부 피해 본문을 사용한다. 다른 일반 actor처럼 script 경로 capability guard로 파생 script override 우회를 차단한다. caller 소유 receipt를 재사용하고 HP/보호막을 실제 계산 지점에서 기록한다. common death guard를 통과한 사망만 death_started=true로 기록한다. 기존 파동은 capability 검사로 자동 연결되며 projectile/receipt/common 자체는 변경하지 않았다.

| 처리 | 결과 의미 |
|---|---|
| 보호막만 소모 | shield_absorbed>0, accepted=true, hp_damage=0 |
| 정상 HP 피해 | 실제 hp_damage, accepted=true |
| 첫 치명타 + 부활 증강 가능 | HP0 피해 기록, accepted=true, death_started=false |
| 부활 중 추가 피해 | 기존 거절, accepted=false, death_started=false |
| 부활을 사용한 뒤 실제 사망 | 실제 common death 시작에서 death_started=true |

complete는 처리가 끝났다는 뜻이다. accepted와 사망은 별개다. 부활 시작을 별도 receipt field로 추가하지 않았으며 현재 actor의 reviving 상태와 기존 lifecycle 동작을 유지한다. 미래 표시/서버 이벤트에서 부활을 표현하는 작업은 별도다. API false/버퍼 재진입은 결과 사용을 중단해야 하며 피해 재시도를 뜻하지 않는다.

## 유지한 전투 동작

- dead/dying/reviving/amount<=0 입력 거절, 엘리트 매복 피해 감소, 생존 엘리트 해골에 따른 necrotic guard, 감소 후 최소 피해/오라/지원 보호막 계산 순서.
- HP 표시·flash·redraw 후 부활 가능 여부 판단. 해골은 치명타에서 play_hit을 호출하지 않는 기존 순서를 유지한다.
- 부활 증강 최초1회 제한, HP0 부활 대기, 후속2연격 취소, 매복 해제, 엘리트 생존 알림false, 시각/충돌 상태와 지연시간.
- 실제 `_tick_revival`의 timer fallback 및 death pose 준비→역재생→ONE_SHOT 완료 신호→설정 비율 HP 회복. 부활 후 alive 알림true 및 회복 재개.
- 부활 중 direct heal 금지. 실제 최종 사망만 died 신호/common 사망 연출을 사용한다. 부활을 신규 소환·새 registry 세션으로 바꾸지 않았다.

첫 부활 치명타를 파동이 맞히면 기존 적중 알림/회복 시도는 유지하고 처치 알림만 거절한다. 새 파동이 부활 후 두 번째 치명타를 맞히면 원래 신원/revision 검증 뒤 실제 사망1회로 집계한다. 미지원 다른 actor는 기존 fallback을 유지한다.

## 비용·검증

새 per-hit result/Array/Dictionary/WeakRef 생성, 그룹 스캔, 예약 객체를 추가하지 않았다. nullable scalar 기록과 기존 공통 함수 위임만 추가했다. 기존 부활 animation의 신호 연결은 변경하지 않았다. 속도/RAM 개선 수치나 전체 전투 안전성을 보장하는 단계는 아니다.

Godot4.5.1 독립 fixture에서 실제 해골 피해·부활·회복·사망 및 실제 common/receipt/registry/파동 관련 함수를 추출해 실행했다. visual/popup/엘리트 제공 authority는 spy다. 역재생 완료 signal은 실제 연결·emit하여 실제 complete 함수를 실행했다. 전체 애니메이션 리소스나 충돌은 실행하지 않았다.

| 검사 | 통과 수 |
|---|---:|
| 해골 기본 receipt 경계·Before/After·재진입·override·64bit | 1,148 |
| 해골 + 실제 파동 경계 | 638 |
| 매복/guard/부활/소진/대기1,152조건×3 및 lifecycle·파동13검사 | 3,469 |
| 기존 슬라임 receipt/파동 회귀 | 1,786 |
| 합계 | 7,041 |

실패0. 최종 스크립트 로그 ERROR/WARNING/잔류 객체 없음. 해골 원래25함수의 기록 hook을 정확히 역변환해 기준 본문과 비교했다. 하위 builder의 slime14/common27/projectile31 및 이전30 본문 비교도 통과했다. gdparse/Python source compile/독립 editor import/staged diff 검사 통과.

fixture는 원래 해골과 같은 visual Node2D 타입을 사용해 메서드 검사 타입 추론을 유지한다. 치명타에서 hit visual이 없으므로 기존 공용 재진입/death guard 테스트는 실제 popup callback 경계에서 실행하도록 대입했다. actor 구현을 바꾸거나 존재하지 않는 hit callback을 만든 것은 아니다.

전체 게임Godot4.7·모바일/export·실제 그림/충돌/상태이상·다른 부활 actor·성능은 미검증이다. 매칭/용사모드/별도 네트워크 시제품은 확장하지 않았다.

## 재현·롤백

skeleton baseline은 위 기준 feature에서 다운로드한다. 다른 baseline SHA는 [WAVE_DAMAGE_RECEIPT.md](WAVE_DAMAGE_RECEIPT.md), [SLIME_DAMAGE_RECEIPT.md](SLIME_DAMAGE_RECEIPT.md)의 기존 기준이다.

```bash
python3 tests/build_skeleton_receipt_fixture.py /tmp/sk-fixture \
  --skeleton-baseline /tmp/sk-before.gd \
  --projectile-baseline /tmp/expand-projectile-before.gd \
  --wave-baseline /tmp/expand-wave-before.gd \
  --slime-baseline /tmp/expand-slime-before.gd \
  --common-baseline /tmp/expand-common-before.gd
godot --headless --path /tmp/sk-fixture --script res://tests/skeleton_revival_smoke.gd
```

나머지는 skeleton_receipt_smoke, skeleton_wave_receipt_smoke, slime_receipt_smoke, wave_receipt_smoke다. fixture는 체크아웃 밖에서 생성한다.

오류 발생 시 이 커밋 revert로 해골의 새 API만 해제하고 파동을 기존 fallback으로 돌릴 수 있다. 기존 receipt/common/projectile와 다른 actor는 그대로다. 다음은 남은 일반 몬스터의 특수 피해/상태이상 처리와 결과 경계 적용 확대이며 부활/무적 특수 actor는 각 lifecycle을 따로 검증한다. main 병합 없음.
