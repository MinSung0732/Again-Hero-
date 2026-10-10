# 용사 제어 상태 결과와 몬스터 incoming 감사

브랜치 feature/stage10-astra, 기준 `972c8edda53ce09b879e10075c1360a6233bfd00`.
Hero 원본 blob `475a91879a505829001c9f1a24335021d4287847`.
MonsterCatalog blob `51ff249b981eb32dcd42e93d7063f2311521b02e`.
main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 몬스터 감사 결과

Catalog ORDER26종의 소스를 최신 원격 blob과 대조했다. 각 supports_damage_receipt에 canonical script 경로가 있으며 누락은 없다. 이 검사는 정적 지원 여부 감사이며 26종 전체 게임 실기기 검증을 의미하지 않는다.

일반/상속: slime, spider, orc, bomb_rat, skeleton, skeleton_archer, kobolt, bat,
goblin, goblin_thrower, ghost, banshee, dullahan, kraken, medusa, mummy,
powwow_mummy, scorpion, succubus, wolf, yuki_onna.
초월: zeus, bulgasal, izanami, manticore, shuten_doji.
향후 새 몬스터는 자동 지원하지 않는다. canonical opt-in 정책과 실제 피해/death 결과 연결을 별도로 검증해야 한다.

## 추가 API

| 상태 | API | 강도 표현 |
|---|---|---|
| 둔화 | apply_slow_with_result(multiplier, duration, receipt) | 요청1-multiplier, 결과1-move_multiplier |
| 기절 | apply_stun_with_result(duration, receipt) | 1 |
| 침묵 | apply_silence_with_result(duration, receipt) | 1 |

BattleStatusReceipt는 호출자가 생성해 재사용하는 scalar 버퍼다. revision, victim_life, victim_instance_id, identity_verified, status_id, requested_duration/strength, applied_duration/strength, accepted, complete를 담는다. Node/효과/공격자를 보관하지 않는다. identity_verified는 begin 시점 registry 해석 결과이며 완료 시까지 생존을 보증하지 않는다.

API 반환 true는 해당 revision이 complete임을 뜻한다. 거절도 complete+accepted=false가 될 수 있다. 지원하지 않는 파생 스크립트나 null receipt에서는 기존 메서드를 한 번 실행하고 false를 반환한다. false를 상태 거절로 해석하거나 호출을 재시도하면 안 된다. accepted 및 duration/strength는 complete일 때만 읽는다.

accepted는 기존 상태 적용 경로가 수락했다는 뜻이다. 기존보다 강해졌다는 뜻이 아니다. 이미 강한 둔화·긴 타이머가 유지되어도 기존 raw 적용 이벤트가 발생하면 accepted다. applied 값은 실제 상태 쓰기 직후의 전체 타이머·강도 snapshot이며 이번 호출이 늘린 시간/강도 차이가 아니다. 침묵은 기존 이벤트 전에 기록하고, 둔화/기절은 기존 이벤트 이후 상태 쓰기 직후 기록한다. 기존 callback 관측 순서를 바꾸지 않았다.

같은 버퍼가 signal callback에서 중첩 사용되면 이전 revision은 record/finish할 수 없다. 다른 버퍼는 각 상태 쓰기 시점의 snapshot을 유지한다. 기존 raw signal, status_action credit, AI event memory를 변경하지 않는다. 새 객체/배열/스캔은 hot path에 추가하지 않았다. 다만 기존 raw AI event Dictionary 생성과 action token 수명은 이번 단계의 최적화 범위가 아니다.

## 보존한 기존 예외

- 둔화는 HP만 검사하며 is_dying을 따로 거절하지 않는다. duration<=0도 최소0.05초 적용, multiplier clamp와 저항 보간을 그대로 사용한다.
- 기절은 duration<=0/HP0/is_dying을 거절하지만 최대 저항이어도 최소0.05초 적용한다. 기존 sprite 정지·이속0·max timer를 유지한다.
- 침묵은 duration<=0/HP0/is_dying 거절. 저항100%에서 새 타이머0이면 거절하지만 기존 양수 타이머가 있으면 갱신 이벤트 수락한다.
- 약한 효과나 짧은 지속시간의 새 적용도 raw 이벤트를 남긴다. 동일 action token의 반복 갱신은 전투 성장/해금에는1회만 집계하고 AI에는 raw 이벤트를 유지한다.

기존 기술 호출자는 아직 새 API로 전환하지 않았다. 준비한 내부 API 단계이며 서버 매칭·상태 동기화·전체 상태 완료를 뜻하지 않는다. 공포/마비/석화/DOT 등은 다음 범위다.

## 검증

Godot4.5.1 실제 독립 fixture 신규 **19,462** 검사 + 이전 피해 fixture **29,473** 회귀 = **48,935**, 실패0. 원본 Hero618함수는 세 공유 helper의 기록 hook만 역변환해 동일한 함수 본문임을 비교했다. Catalog26종 canonical opt-in 정적 감사. gdparse/Python compile/fixture import/diff 통과.

HP0·생존·dying, 음수/0/양수 지속시간, 저항0/50/100%, 기존 타이머0/2/20초, multiplier clamp 조합으로 원본과 신규 상태·메타·속도·sprite speed·signal callback 관측·AI memory를 비교했다. 요청·registry identity·거절 reset, same/separate buffer 중첩, null/파생 override 한 번 호출, unregistered/freed actor 수명도 확인했다. 기술당1회 집계와 raw30회, 새 action, 정확한20초 기억 경계/만료를 실제 기존 scope/buffer 함수로 검사했다.

sprite와 resistance provider는 fixture spy다. 전체 Hero 초기화/게임4.7, 모바일, 실제 AI 결정·효과 시각·물리·성능은 미검증이다. 기존 status_action_growth_smoke 전체 Battle 실행은 수행하지 않았다.

## 재현

기준 커밋에서 Hero, status_action_scope, timed_event_buffer, monster_catalog 원본을 다운로드한다. checkout 밖 target을 사용한다.

```bash
python3 tests/build_hero_status_receipt_fixture.py /tmp/status-receipt \
  --hero-baseline /tmp/r-hero-before.gd \
  --action-scope-baseline /tmp/r-action-scope.gd \
  --event-buffer-baseline /tmp/r-event-buffer.gd \
  --monster-catalog-baseline /tmp/r-monster-catalog.gd
Godot --headless --path /tmp/status-receipt --editor --import
Godot --headless --path /tmp/status-receipt --script res://tests/hero_status_receipt_smoke.gd
```

피해29,473 회귀는 ZEUS_DAMAGE_RECEIPT.md의 builder/13스크립트로 재현한다. 새 상태 receipt와 기존 피해 receipt의 책임은 분리되어 있다.

## 다음 검토 / 롤백

1. 전체 게임에서 제어 상태의 실제 sprite·이동·스킬 차단 및 기존 성장/해금 집계를 확인.
2. 남은 상태 결과 계약을 조사하고 호출자는 검증된 API부터 점진 전환. 낡은 void 호출은 유효하다.
3. 문제 발생 시 feature 브랜치에서 git revert <이번 커밋>. 이전 몬스터 피해 연결은 유지한다. main 병합은 별도 요청 시 진행한다.
