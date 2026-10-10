# 용사 공포·마비·석화 결과 연결

feature/stage10-astra 기준 `5db316b133ec5fd4b49045ba2a933518ffb7617c`.
수정 전 Hero blob `542cf80f630ab0930f5a1130ee179e88899a2cfc`.
Medusa Catalog blob `c7856da44c988a82f82b03414819f891c668cb9c`.
main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 추가 API와 계약

| 상태 | API | requested/applied 강도 |
|---|---|---|
| 공포 | apply_fear_with_result(source, duration, receipt, speed_multiplier=1.5) | 요청 speed multiplier / 적용 fear_speed_multiplier |
| 마비 | apply_paralysis_with_result(ratio, duration, receipt) | 요청 ratio / 적용 paralysis_ratio |
| 석화 | apply_petrify_with_result(duration, receipt, release_slow=1.0, release_duration=0.0) | 1 / 1 |

기존 BattleStatusReceipt를 재사용한다. complete만 신뢰하며 API true는 완료 여부다. 거절은 true+accepted=false다. null receipt/파생 Hero는 기존 메서드를1회 실행하고 결과 미지원 false다. false일 때 재시도하면 안 된다. applied 값은 상태 쓰기 시점의 전체 duration/strength snapshot이며 증가량이 아니다. source/석화 잔여 둔화 설정/시각은 receipt가 소유하거나 복제하지 않는다. identity_verified는 begin 시 registry 확인이며 완료까지의 생존 보증이 아니다.

기존 void/bool API는 동일 helper를 호출한다. 실제 상태 쓰기 후 공포 결과를 기록하며 마비/석화 결과는 visual callback 전에 기록한다. 같은 버퍼 재진입은 이전 revision record/finish를 거절하고 최신 payload를 유지한다. 다른 버퍼는 각각 적용 시점의 snapshot을 유지한다. 원래 callback 순서나 후속 상태 mutation을 막지 않는다.

## 보존한 규칙

- 공포: HP0/is_dying 거절, 음수/0 duration은 기존 최소0.05초. timer max, possession immunity max(fear_timer+3), speed 최소1, 유효 source 좌표 또는 global_position-Vector2.RIGHT fallback.
- 마비: HP0/is_dying·duration<=0·ratio<=0 거절. clamp0..1, 활성 상태의 더 약한 강도 거절. 같은/강한 강도는 duration을 그대로 새 값으로 바꾸므로 짧아질 수도 있다. ratio>=1의 최소 attack/rogue cooldown 처리 유지.
- 기존 마비는 record_status_effect_event를 호출하지 않는다. 이 단계에서 AI/성장·해금에 새 raw 이벤트나 credit를 추가하지 않았다.
- 석화: HP0/is_dying·이미 활성·duration<=0 거절. 저항 적용 후 최소0.05초, 기존 cast token 캡처→raw event→timer/anchor/velocity/tint/active→visual 순서 유지.
- 석화 해제의 tint/active 복구, 원래 cast token으로 apply_slow, ambient scope 복원, 저장 token 해제를 변경하지 않았다. 따라서 석화와 잔여 둔화는 같은 originating action credit다.

전투 hot path에 배열/객체/스캔 추가 없음. caller-owned scalar receipt 비용 O(1). 기존 효과 객체·status event memory·원래 action token 수명은 그대로다. 실제 성능/로딩 개선을 측정한 단계는 아니다.

기존 기술 호출자는 새 API로 전환하지 않았다. 이번 준비 단계가 매칭/상태 동기화/모든 상태 완료를 뜻하지 않는다. DOT와 다른 상태는 다음 조사 범위다.

## 검증

Godot4.5.1 headless 신규 **12,988** + 기존 제어 상태 **19,462** = **32,450**, 실패0. 최종 두 실행 로그에 error/warning/leak 없음. 원래 Hero618함수와 직전625함수의 hook 역변환 비교 통과. gdparse/Python compile/fixture import/diff 통과.

실제 apply/_tick_petrify/get_paralysis_attack_multiplier, 기존 status_action_scope와 AI timed_event_buffer, Medusa Catalog를 추출/복사해 실행했다. HP·dying·음수/0/양수 duration·저항0/50/100%·기존 timer·강도 조합에서 원본과 신규 상태, 메타, raw/credit 이벤트, sprite speed/tint, source 좌표, 시각 호출을 비교했다.

검사에는 약한 마비 거절·같은 강도 짧은 duration, null source 공포, 석화 cast/residue/ambient scope 복원, 같은/별도 버퍼 callback 재진입, null/파생 override, visual callback 직전 기록 및 후속 timer mutation이 포함된다.

sprite·시각 show_on·저항 provider는 spy다. 전체 Hero 초기화/게임4.7/모바일/실제 시각·AI 결정·물리·성능 미검증. 기존 피해 fixture는 이번 단계에서 재실행하지 않았으며 이전 제어 상태 검사는 현재 확장 fixture에서 재실행했다.

## 재현

HERO_STATUS_RECEIPT.md 기준의 원본 Hero `475a91879a505829001c9f1a24335021d4287847` 및 scope/buffer/catalog를 준비한다. 직전 Hero와 Medusa Catalog는 본 문서 기준 커밋에서 받는다. checkout 밖 target을 사용한다.

```bash
python3 tests/build_hero_extended_status_fixture.py /tmp/extended-status \
  --hero-baseline /tmp/r-hero-before.gd \
  --control-hero-baseline /tmp/t-hero-before.gd \
  --action-scope-baseline /tmp/r-action-scope.gd \
  --event-buffer-baseline /tmp/r-event-buffer.gd \
  --monster-catalog-baseline /tmp/r-monster-catalog.gd \
  --medusa-baseline /tmp/t-medusa-catalog.gd
Godot --headless --path /tmp/extended-status --editor --import
Godot --headless --path /tmp/extended-status --script res://tests/hero_extended_status_smoke.gd
Godot --headless --path /tmp/extended-status --script res://tests/hero_status_receipt_smoke.gd
```

원래 build_hero_status_receipt_fixture의 inverse comparison만6종 상태까지 확장했다. 기존3종 fixture 실행도 유지한다. 확장 builder는 누수 방지를 위해 공용 factory를 SceneTree를 새로 만드는 대신 RefCounted helper로 추출한다.

## 검토 / 롤백

1. 전체 게임에서 공포 이동·마비 공속·석화/해제 잔여 둔화·원래 성장 집계 확인.
2. 화상·독·출혈 등 결과 계약 조사 후 검증된 상태 API 호출자를 점진 연결.
3. feature 브랜치에서 git revert <이번 커밋>으로 롤백. 이전 둔화/기절/침묵 API는 유지. main 병합은 별도 요청 시 진행한다.
