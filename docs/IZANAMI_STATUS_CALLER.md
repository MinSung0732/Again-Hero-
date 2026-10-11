# 이자나미 기술의 상태 결과 연결

기준 feature/stage10-astra `8a61af1559b2c238745a438fb37a30e050b28672`.
원래 이자나미 blob `3f6c8ac11b819bc371a509492847370284509c87`.
Hero blob `8c3701d6f8343ccc0b598316a61e424ef3ace20a`는 변경하지 않았다.
main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 범위

이자나미의 실제 _status 공통 경로를 통해 네 상태 결과 API를 호출한다. DATA/피해·기술 발동 타이밍·부모·Hero·다른 actor·공통 ReceivedAfflictions는 변경하지 않았다.

| 기존 kind | 실제 결과 API | 요청 값 |
|---|---|---|
| slow | apply_slow_with_result | multiplier=strength, duration=seconds |
| stun | apply_stun_with_result | duration=seconds |
| silence | apply_silence_with_result | duration=seconds |
| vulnerability | apply_damage_taken_increase_with_result | duration=seconds, increase=strength |

인스턴스당 BattleStatusReceipt 하나를 생성하고 재사용한다. 신규 _apply_hero_status는 결과 API가 있으면 한 번 호출한다. 없다면 원래 legacy 한 번 호출하고 false를 반환한다. 결과 API false는 이미 효과를 시도했으므로 legacy를 재시도하지 않는다. 파생 Hero override 보호는 Hero API의 opt-in 계약에 따른다.

## 결과와 기존 집계

status_result_complete가 true일 때만 이번 _status 호출의 status_receipt를 읽는다. receipt.complete/accepted 및 요청/실제 강도·시간/registry life 계약은 HERO_STATUS_RECEIPT.md와 같다. _status의 bool 반환값은 **기존 raw event 발생 여부**를 유지한다. 결과 가용성과 상태 수락/기존 bool을 혼동하지 않는다.

early guard/unknown kind/미지원/같은 버퍼 재진입이면 status_result_complete는 false다. 과거 payload가 남거나 중첩 호출의 receipt.complete가 true여도 이번 호출 결과로 읽지 않는다. 결과는 즉시 소비하거나 scalar 값만 복사하며 이후 호출을 넘겨 receipt 참조를 보관하지 않는다. 같은 buffer의 최신 중첩 결과를 바깥 결과로 해석하지 않는다.

기존 임시 status_applied observer는 유지했다. 상태 갱신과 동기 callback에서 발생하는 raw 이벤트도 원래처럼 status_depth/passive_statuses에 반영한다. 이를 receipt.accepted 하나로 대체하면 기존 패시브 발동 시점이 달라질 수 있어 이번에는 바꾸지 않았다. count_passive=false, 같은 기술 token당 전투 전역 credit1회, 바깥 scope 복구 및 AI raw memory도 그대로다. status_depth와 status_action credit은 서로 다른 집계다.

추가 기록 O(1), actor당 scalar buffer1개, 매 적용 객체/배열/Dictionary/그룹 스캔 없음. 기존 observer 연결·해제/event 비용은 유지한다. 성능/로딩 개선 벤치마크를 주장하지 않는다.

## 검증과 한계

Godot4.5.1 신규 **32,295** + 기존 기본/확장/DOT/modifier **56,159** = **88,454**, 실패0. 최종 import 및5개 실행 로그 error/leak 없음. gdparse/Python compile/diff 통과. 이자나미 원래34함수는 routing 변경을 역변환해 원래 본문과 비교했다. Hero 초기618/이전625·631/직전639 함수 비교와 Catalog26종 incoming opt-in 감사도 기존 builder에서 통과했다.

실제 이자나미 _status/_count_own_status/_apply_hero_status와 Hero 실제 상태 함수 slice를 함께 실행했다. HP0/1/생존·dying, 음수/0 duration/strength, 저항·활성 timer, count_passive 조합의 기존 return/state/raw/AI/passive/scope/observer 해제를 비교했다. legacy-only 대상과 미지원 파생 override, 반복120회 buffer 재사용/동일 action credit1회, 새 action/ambient scope, early/unknown/missing Hero, raw callback 동일 buffer overwrite도 검증했다.

Fixture 이자나미는 Node2D에 실제 호출 함수/필드를 추출한 것이다. 상속 전체 초기화·DATA/FX·실제 기술 타이밍/AI·sprite/충돌·전체 게임4.7/모바일·성능 검증은 아니다. 기존 상태 fixture의 저항/visual/channel/피해 spy 한계도 그대로다. 네 호출 연결이 모든 outgoing 상태 처리나 매칭 기반 구조의 완료를 의미하지 않는다.

## 재현

HERO_MODIFIER_STATUS_RECEIPT.md의 baseline 파일을 준비한다. 추가 이자나미 baseline은 위 기준 커밋 src/monsters/izanami.gd다.

```bash
python3 tests/build_izanami_status_fixture.py /tmp/izanami-status \
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
  --izanami-baseline /tmp/w-izanami-before.gd
Godot --headless --path /tmp/izanami-status --editor --import
Godot --headless --path /tmp/izanami-status --script res://tests/izanami_status_receipt_smoke.gd
Godot --headless --path /tmp/izanami-status --script res://tests/hero_modifier_status_smoke.gd
Godot --headless --path /tmp/izanami-status --script res://tests/hero_dot_status_smoke.gd
Godot --headless --path /tmp/izanami-status --script res://tests/hero_extended_status_smoke.gd
Godot --headless --path /tmp/izanami-status --script res://tests/hero_status_receipt_smoke.gd
```

## 다음 작업 / 롤백

1. 실제 전투에서 이자나미 네 상태·패시브 발동 타이밍과 actor 재사용 확인.
2. 슈텐도지의 공통 ReceivedAfflictions 경로·다른 기술/적중 bridge를 순차 연결. generic 몬스터 component 정책을 먼저 조사해 보존한다.
3. feature에서 git revert <이번 커밋>으로 호출자 변경만 롤백. Hero 결과 API는 유지하며 main 병합은 별도 요청 시 진행한다.
