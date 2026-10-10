# 용사 DOT 적용 결과

feature/stage10-astra 기준 `b16fe17df54361b3543c2ac9ea8d88dab4ad7864`.
Hero 원본 blob `b125da95359dab1f74cb35791240b4a5b7b41865`.
BurnRuntime blob `65cc53cea57e8b948b637fa6c4ffe674ed4b64c4`.
DamagePoisonTracker blob `614d21ff81fe28581117f2ab70232145ae6cee9b`.
main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## API

| 효과 | API | 기존 정책 |
|---|---|---|
| 현재 체력 비례 독 | apply_poison_with_result(duration, ratio, receipt, tick_interval=0.5, source=null) | 갱신, 최소 시간0.1/tick0.05/총 피해1, 활성 tick 시간 유지 |
| 출처·채널 피해량 독 | apply_damage_poison_with_result(duration, total_damage, source, receipt, channel=0) | 유효 source 필수, 동일 출처·채널 중첩/갱신 거절, 다른 채널 독립 |
| 출혈 | apply_bleed_with_result(duration, receipt, source=null, total_max_hp_ratio=-1, refresh=false) | 활성 중 기본 거절, refresh 허용 시 새 budget, 음수 ratio는 기존 기본 비율 |
| 화상 | apply_burn_with_result(duration, total_damage, receipt, source=null) | 단일 갱신, duration/damage 양수 필수 |

기존 apply API와 새 결과 API는 공유 helper를 사용한다. 기존 void/bool 반환·저항/guard/최소값·signal·시각 순서를 유지했다. 실제 burn/tracker/tick 함수는 변경하지 않았다. source도 기존 strong/weak 보관 정책을 바꾸지 않았다.

## 결과 계약

기존 BattleStatusReceipt에 int64 requested_damage, applied_damage_budget을 추가했다. begin의 선택 인자 damage는 기본0이므로 기존 제어 상태 호출과 호환된다. 비DOT begin과 거절 시 budget0으로 초기화한다.

- requested_damage: 명시적 total_damage 요청이 있는 burn/damage poison 값. ratio 기반 효과는0이며 requested_strength에 원래 ratio를 담는다.
- applied_damage_budget: 실제 적용 시 예약된 총 DOT 예산. **이미 입힌 HP 피해가 아니며**, 최종 HP 차감이나 보호막·감소 후 피해를 보증하지 않는다.
- applied_duration: 적용 직후 예약 지속시간.
- applied_strength: ratio 독은 budget/current_hp, 출혈은 budget/max_hp (0분모 방지1); 명시 피해량 효과는1. 반올림·최소 피해를 반영한 예산 비율이며 추가 HP 피해량이 아니다.

complete 반환과 accepted 의미, canonical 지원/파생 override/null receipt 한 번 호출 정책은 HERO_STATUS_RECEIPT.md와 같다. 결과 미지원/버퍼 재진입 실패는 재시도하지 않는다. 같은 버퍼의 최신 결과가 우선한다. source/channel은 receipt가 소유하지 않으며 나중에 네트워크 명령 데이터로 구성할 때 별도 계약이 필요하다.

burn과 피해량 독은 runtime apply 직후 budget을 기록해 signal callback이 effect를 바꾸어도 최초 수락 budget을 보존한다. ratio 독과 출혈은 원래 raw event 뒤 상태 쓰기를 실행하고 기록한다. 출혈/화상 visual callback 전에 기록한다. 원래 raw AI memory와 기술당1회 action 집계는 그대로다. tick은 receipt를 수정하지 않는다.

매 적용 신규 receipt/배열/그룹 스캔 없음. caller-owned scalar 기록 O(1). 기존 DOT runtime의 entry Dictionary/WeakRef, raw AI event, tick 비용은 이번 변경에서 그대로다. 성능·로딩 개선 벤치마크를 주장하지 않는다.

## 검증

Godot4.5.1 독립 fixture 신규 **7,961** + 기존 제어 상태 **32,450** = **40,411**, 실패0. 최종 import/3실행 로그 error/warning/leak 없음. 초기 Hero618/이전625/직전631함수 hook 역변환 비교, gdparse/Python compile/diff 통과.

실제 네 적용 경로, _update_poison/_set_poison_flash/_update_bleed/_clear_bleed/_clear_burn/_update_damage_poison, take_recorded_poison_damage와 원래 BurnRuntime/DamagePoisonTracker를 실행했다. 피해를 받는 최종 엔진 함수는 fixture spy로 HP를 직접 차감한다. 따라서 이 검증은 원래 DOT의 예산 분배·상태 수명 비교이며 실제 전투 피해 엔진 검증은 아니다.

HP0/HP1/생존·dying, 음수/0 duration/ratio/damage, 기존 효과 여부·refresh 조합의 원본 상태/예산/FX/raw/credit 비교. 여러 delta 분배/단일 긴 tick, source/channel 중복·독립·만료, source 소멸, 버퍼 reset/같은·별도 버퍼 재진입, 파생/null 호출1회, visual effect clear 직전 기록, 50억 int64 예산, nonlethal burn tick 중 갱신 revision도 확인했다.

실제 Hero 초기화/피해 엔진/전체 게임4.7·모바일·AI 결정·sprite 렌더링·성능 미검증. 기존 기술 호출자는 아직 신규 API로 전환하지 않았다. 이번 단계가 모든 상태/매칭 준비의 완료를 뜻하지 않는다.

## 재현

이전 HERO_STATUS_RECEIPT.md/HERO_EXTENDED_STATUS_RECEIPT.md의 baseline을 준비한다. 직전 Hero와 burn/tracker 원본은 본 문서 기준 커밋에서 확보한다.

```bash
python3 tests/build_hero_dot_status_fixture.py /tmp/dot-status \
  --hero-baseline /tmp/r-hero-before.gd \
  --control-hero-baseline /tmp/t-hero-before.gd \
  --extended-hero-baseline /tmp/u-hero-before.gd \
  --action-scope-baseline /tmp/r-action-scope.gd \
  --event-buffer-baseline /tmp/r-event-buffer.gd \
  --monster-catalog-baseline /tmp/r-monster-catalog.gd \
  --medusa-baseline /tmp/t-medusa-catalog.gd \
  --burn-baseline /tmp/u-burn_runtime.gd \
  --damage-poison-baseline /tmp/u-damage_poison_tracker.gd
Godot --headless --path /tmp/dot-status --editor --import
Godot --headless --path /tmp/dot-status --script res://tests/hero_dot_status_smoke.gd
Godot --headless --path /tmp/dot-status --script res://tests/hero_status_receipt_smoke.gd
Godot --headless --path /tmp/dot-status --script res://tests/hero_extended_status_smoke.gd
```

원래 두 builder의 inverse comparison을 DOT4경로까지 확장했다. 기존 fixture 실행 경로는 유지했다.

## 검토 / 롤백

1. 실제 게임에서 DOT 최종 피해 엔진·효과 갱신·출혈 거절·상태 집계 확인.
2. 매혹/치유감소/받는피해증가 결과 조사 후 실제 기술 호출자 연결.
3. feature 브랜치에서 git revert <이번 커밋>으로 롤백. 기존 제어 상태 API 유지, main 병합은 별도 요청 시 진행한다.
