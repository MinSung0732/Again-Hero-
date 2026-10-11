# 슈텐도지와 공통 상태 adapter의 결과 연결

기준 feature/stage10-astra `b5672852717a9f0c957c60dcf2863aab38ff0c1b`.
Shuten 원본 blob `982a7171bf1ce8d00bd3acbf78e894c19f10e08d`.
ReceivedAfflictions 원본 blob `e5c35d96ebc488961c57c8b0a53ed23cb1c886cd`.
main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 범위 / API

| 공통 adapter 결과 API | 연결된 실제 슈텐도지 경로 |
|---|---|
| apply_slow_with_result(actor, multiplier, seconds, receipt, action=null) | 안개, 사슬 |
| apply_stun_with_result(actor, seconds, receipt, action=null) | 출혈 대상 폭발, 기본공격 누적 기절 |
| apply_silence_with_result(actor, seconds, receipt, action=null) | 사슬 |
| apply_bleed_current_with_result(actor, seconds, ratio, source, receipt, action=null) | 비출혈 대상 폭발 |

원래 apply API15함수와 ReceivedAfflictions의 필드·component prefix는 변경하지 않았다. 기존 burn/poison/physics tick·clear·시각/출혈 엔진도 그대로다. 새 adapter는 상태 result capability를 명시하는 대상과 해당 결과 API가 있을 때만 native 경로를 사용한다. 현재 canonical Hero가 이 계약을 지원한다.

원래 adapter guard를 Hero 호출 전에 보존한다. slow/stun/silence는 seconds<=0 또는 HP<=0이면 적용하지 않는다. **Hero 자체 slow API는 음수/0 duration도 최소 시간을 적용하므로 adapter를 건너뛰면 기존 효과가 달라진다.** current-HP bleed는 HP<=0 또는 bleed_active meta가 true이면 거절한다. native guard 거절도 completed=true/accepted=false 결과를 기록하고 raw event/action scope를 만들지 않는다.

native current-HP bleed는 원래처럼 float(current_hp)*ratio/max(max_hp,1)을 Hero의 최대HP 비율로 넘긴다. native receipt의 requested_strength도 변환된 최대HP 비율이다. applied_damage_budget은 예약 출혈 예산이며 실제 HP 피해가 아니다. 폭발 피해 이후의 현재HP를 사용한다.

일반 몬스터/결과 capability 미지원·파생 대상은 receipt.begin으로 이전 payload를 초기화한 다음 legacy API를 한 번만 호출한다. 결과는 complete=false/API false로 **사용 불가**다. 이것이 효과 거절을 뜻하지는 않는다. generic 요청 strength는 원래 ratio, native bleed는 변환 비율이므로 complete를 먼저 확인한다. null receipt도 원래 API1회 호출 후 false다. false를 이유로 재시도하지 않는다.

## 호출자와 수명

슈텐도지 인스턴스당 scalar receipt1개를 생성·재사용한다. _apply_fog/_blast_target/_apply_stun/_bind_chain 진입 시 status_result_complete=false, 상태 adapter 호출의 bool을 여기에 기록한다. 이번 호출의 flag가 true일 때만 receipt를 읽는다. early HP/거리/active/면역 guard, 미지원 fallback, 같은 buffer overwrite는 결과 가용성을 false로 만든다.

사슬은 기존대로 둔화 다음 침묵을 적용하며 같은 buffer에는 **마지막 침묵 적용 결과**가 남는다. 두 상태를 합산한 결과가 아니다. 다음 대상/효과를 넘겨 buffer 참조를 보관하지 않는다. callback 재진입 때 중첩 buffer가 complete여도 바깥 결과 flag는 false다. 상태를 다시 적용하지 않는다.

원래 source/action token, 안개 분율 피해/폭발 출혈·기절 선택, 사슬 거리별 쿨타임 환급/면역/피해·음성 순서를 유지했다. 전투 raw memory·동일 originating action당 credit1회 및 ambient scope 복구도 그대로다. generic component는 원래 physics 정지·복구, duration/최소 출혈 예산/약한 source·시각·clear 정책을 유지한다.

새 결과 기록 O(1), caller당 buffer1개, 매 적용 신규 receipt/배열/Dictionary/그룹 스캔 없음. generic lazy component 생성·원래 이벤트/안개 record/token 비용은 유지한다. 성능/로딩 개선 수치는 주장하지 않는다.

## 검증 / 한계

Godot4.5.1 신규 **12,159** + 기존 상태/이자나미 **88,454** = **100,613**, 실패0. import/6개 테스트 최종 로그 error/leak 없음. gdparse/Python compile/diff 통과. 원래 affliction15/Shuten39함수 역변환 비교와 component 전체 prefix 보존 확인, 기존 Hero/Izanami 비교·26종 opt-in 감사도 통과했다.

실제 ReceivedAfflictions 전체 script와 실제 Hero 상태 slice를 실행했다. HP0/1/생존·dying, duration/strength 음수·0, 저항/기존 상태, adapter guard·bleed meta/현재HP 변환·예약 예산을 비교했다. generic component의 실제 field/physics/시각·출혈 tick/만료/reset, 이전 physics 복구, legacy-only/파생/null1회, 동일 buffer 재진입·ambient scope도 검사했다.

실제 Shuten의 _apply_fog/_blast_target/_apply_stun/_bind_chain/_next_action/_action_token/_record를 추출해 native/generic 대상, 거리/HP/active guard, raw/credit·buffer reuse/사슬 면역을 비교했다. source catalog는 원본을 사용했다.

Fixture의 Shuten _damage와 audio, visual 및 Hero 저항/피해/channel 등은 spy다. 따라서 실제 피해·보호막 엔진, 전체 actor 초기화·기술 타이밍/AI·시각/충돌·전체 게임4.7/모바일·성능은 미검증이다. generic component의 적용 결과 지원은 아직 추가하지 않았다. 전체 outgoing 상태 또는 매칭 기반 구조 완료를 뜻하지 않는다.

## 재현

IZANAMI_STATUS_CALLER.md의 baseline을 준비한다. 추가 afflictions/Shuten/카탈로그 원본은 위 기준 커밋의 src/systems/received_afflictions.gd, src/monsters/shuten_doji.gd, src/data/shuten_doji_behavior_catalog.gd다.

```bash
python3 tests/build_shuten_status_fixture.py /tmp/shuten-status \
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
  --succubus-baseline /tmp/v-succubus-catalog.gd \
  --izanami-baseline /tmp/w-izanami-before.gd \
  --afflictions-baseline /tmp/x-afflictions-before.gd \
  --shuten-baseline /tmp/x-shuten-before.gd \
  --shuten-catalog-baseline /tmp/x-shuten-catalog.gd
Godot --headless --path /tmp/shuten-status --editor --import
Godot --headless --path /tmp/shuten-status --script res://tests/shuten_status_receipt_smoke.gd
Godot --headless --path /tmp/shuten-status --script res://tests/izanami_status_receipt_smoke.gd
Godot --headless --path /tmp/shuten-status --script res://tests/hero_modifier_status_smoke.gd
Godot --headless --path /tmp/shuten-status --script res://tests/hero_dot_status_smoke.gd
Godot --headless --path /tmp/shuten-status --script res://tests/hero_extended_status_smoke.gd
Godot --headless --path /tmp/shuten-status --script res://tests/hero_status_receipt_smoke.gd
```

## 다음 작업 / 롤백

1. 실제 게임에서 슈텐도지 안개/폭발/사슬 및 generic 몬스터 상태·재사용 확인.
2. 제우스·불가살 등 다른 outgoing 기술/적중 bridge, generic component result 지원을 순차 조사.
3. feature에서 git revert <이번 커밋>으로 adapter/호출자만 롤백. 원래 component와 Hero 결과 API 유지. main 병합은 별도 요청 시 진행한다.
