# 용사 매혹·치유감소·받는피해증가 적용 결과

기준 feature/stage10-astra `3ff333cb733c45ecdda4b595999791fca5ef6394`.
Hero 원본 blob `1001aabc99b9f09b45897397f97dc3c626ad4c56`.
main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 범위와 API

| 상태 | 결과 API | 기존 규칙 |
|---|---|---|
| 치유감소 | apply_healing_reduction_with_result(duration, reduction, receipt) | 생존·duration>0, 비율0~1, 기존 강도와 시간 각각 max |
| 받는피해증가 | apply_damage_taken_increase_with_result(duration, increase, receipt) | 생존·duration>0, 강도 하한0·상한 없음, 강도/시간 각각 max |
| 매혹 | apply_charm_with_result(source, duration, receipt) | 생존·유효 source 필수, 활성/면역 중 거절, 저항 적용 후 최소0.05 |

기존 bool API는 원래 본문을 옮긴 helper를 호출한다. 새 결과 API도 같은 helper를 사용한다. tick, 회복 계산, 매혹 source 수명/면역, 적중 횟수 bridge와 실제 기술 호출자는 변경하지 않았다. 콘텐츠 수치·AI 판단·연출도 유지한다.

치유감소/받는피해증가는 음수·0 강도 또는 기존보다 약한 요청도 기존 조건을 통과하면 수락한다. 강도/시간이 실제로 증가했는지와 accepted는 다르다. 매혹은 원래 duration<=0을 거절하지 않았으므로 새 API도 최소0.05를 유지한다. 매혹 재적용·면역 중에는 거절한다.

## 결과 계약

기존 BattleStatusReceipt를 그대로 사용한다. 요청 duration/strength는 원래 값, 실제 duration/strength는 적용 직후의 타이머·강도다. 매혹 strength는1. 세 상태는 비DOT이므로 begin에서 requested_damage/applied_damage_budget을0으로 초기화한다. receipt는 source/대상을 소유하지 않는다.

API true는 지원되는 호출이 완료됐다는 뜻이다. 수락 여부는 complete를 확인한 후 accepted로 읽는다. 동일 receipt에 중첩 begin이 발생하면 바깥 호출은 false이며 최신 중첩 payload만 유효하다. 상태를 재시도하지 않는다. null receipt/미지원 파생 actor는 기존 override를 정확히 한 번 호출하고 false로 반환한다. canonical Hero만 명시 지원한다.

세 상태 모두 실제 필드 쓰기 직후 신호/시각 callback 전에 결과를 기록한다. callback에서 상태가 지워져도 최초 적용 snapshot은 유지한다. 치유감소: 쓰기→기록→raw/action event→visual. 받는피해증가: 쓰기→기록→event. 매혹: 쓰기/meta→기록→visual→event→channel 종료→속도0. 기존 게임플레이 순서는 그대로다. raw AI 기억과 기술당1회 status_action 집계도 유지한다.

새 결과 기록은 caller-owned scalar에 O(1) 추가 쓰기만 한다. 적용마다 새 receipt/배열/Dictionary·그룹 스캔을 만들지 않는다. 기존 weakref/외부 쿨타임 목록/이벤트 비용은 그대로다. 성능 또는 로딩 개선 수치를 주장하지 않는다.

## 검증

Godot4.5.1 독립 fixture 신규 **15,748** + DOT **7,961** + 확장 제어 **12,988** + 기본 제어 **19,462** = **56,159**, 실패0. import/4실행 로그 error/leak 없음. gdparse, Python compile, diff 검증 통과. 초기618/이전625·631/직전639 Hero함수는 결과 hook을 제거해 원래 본문과 비교했다.

HP0/HP1/생존·dying, 음수/0 duration·강도, 저항, 기존 강도·시간/활성 매혹·면역 조합을 비교했다. 실제 modifier tick/reset 및 정수 치유 계산, 매혹 적중 bridge/약한 source 소멸·dying/만료·overshoot 면역/clear도 실행했다. action당1회 집계, 동일/별도 버퍼 callback 재진입, null/파생 legacy1회, 신호가 상태를 지우기 전 snapshot과 결과 초기화를 확인했다.

실제 세 적용 함수와 _get_reduced_healing/_tick_received_modifiers/_clear_received_modifiers/register_succubus_hit/_tick_charm_timers/_clear_charm을 추출해 실행한다. 외부 cooldown 목록 제공/채널 종료/visual/저항 조회는 spy다. 따라서 실제 Hero 초기화·채널 기술 종료·매혹 이동/충돌·전체 게임4.7/모바일·최종 피해 엔진·렌더링·성능은 미검증이다. 새 API 호출자로 아직 전환하지 않았다.

## 재현

HERO_STATUS_RECEIPT.md, HERO_EXTENDED_STATUS_RECEIPT.md, HERO_DOT_STATUS_RECEIPT.md에 명시한 원본 baseline을 준비한다. 직전 Hero는 위 기준 커밋, succubus catalog는 같은 커밋의 src/data/succubus_behavior_catalog.gd다.

```bash
python3 tests/build_hero_modifier_status_fixture.py /tmp/modifier-status \
  --hero-baseline /tmp/r-hero-before.gd \
  --control-hero-baseline /tmp/t-hero-before.gd \
  --extended-hero-baseline /tmp/u-hero-before.gd \
  --dot-hero-baseline /tmp/v-hero-before.gd \
  --action-scope-baseline /tmp/r-action-scope.gd \
  --event-buffer-baseline /tmp/r-event-buffer.gd \
  --monster-catalog-baseline /tmp/r-monster-catalog.gd \
  --medusa-baseline /tmp/t-medusa-catalog.gd \
  --burn-baseline /tmp/u-burn_runtime.gd \
  --damage-poison-baseline /tmp/u-damage_poison_tracker.gd \
  --succubus-baseline /tmp/v-succubus-catalog.gd
Godot --headless --path /tmp/modifier-status --editor --import
Godot --headless --path /tmp/modifier-status --script res://tests/hero_modifier_status_smoke.gd
Godot --headless --path /tmp/modifier-status --script res://tests/hero_dot_status_smoke.gd
Godot --headless --path /tmp/modifier-status --script res://tests/hero_extended_status_smoke.gd
Godot --headless --path /tmp/modifier-status --script res://tests/hero_status_receipt_smoke.gd
```

원래 세 builder의 hook 역변환 비교에 이번3경로를 추가했다. 기존 실행 경로와 비교 개수는 유지한다.

## 다음 작업 / 롤백

1. 실제 게임에서 매혹 활성/면역·채널 중단과 modifier 피해/치유 경로 확인.
2. 기존 기술 호출자·적중 bridge를 결과 API로 순차 연결하고 효과당/기술당 집계 유지.
3. feature 브랜치에서 git revert <이번 커밋>으로 이번 API만 롤백. 이전 제어/DOT 결과 API 유지. main 병합은 별도 요청 시 진행한다.
