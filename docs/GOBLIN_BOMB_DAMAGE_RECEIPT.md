# 고블린·폭탄쥐 피해 결과 지원

2026-10-10. 기준 feature `57859a30d12a284cc5967030f781aa3918c0a281`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0`.
수정 전 고블린 blob `bdb43bc26d7f4f1b5299b3874d19a63bdc0605c9`, 폭탄쥐 blob `3a3965c7e30e14a2d44948430a88582a17586b81`을 최신 파일 다운로드 및 git hash-object로 확인했다. 작업 브랜치는 `feature/stage10-astra`다.

## 범위와 방향

사용자 지시에 따라 기존 마왕 솔플의 내부 구조 개선으로 돌아왔다. 매칭·용사모드·로컬 대전 시제품의 기능 확장은 진행하지 않는다. 현재 실제 게임을 유지하면서 향후 입력/판정/표시 분리를 수월하게 하는 계약 적용을 계속한다.

고블린과 폭탄쥐에 `supports_damage_receipt`, `take_damage_with_result(amount, receipt)`를 추가했다. 기존 void API는 동일한 내부 피해 본문을 사용한다. caller가 준비한 결과 버퍼에 실제 HP 피해·지원 보호막과 엘리트 보호막의 총 흡수·일반 사망 처리 시작을 기록한다. 광전사 파동은 기존 capability 검사로 자동 연결되며 별도 콘텐츠 ID 분기나 재시도를 추가하지 않았다.

## 특수 처리 보존

| 대상 | 유지한 순서와 규칙 |
|---|---|
| 고블린 | amount<=0 거절 → 은신 피해 감소 → 공통 오라/지원 보호막 → 엘리트 보호막 → HP 피해 → 표시/hit → 표준 사망 |
| 폭탄쥐 | 기존 amount clamp → 공통 오라/지원 보호막 → 엘리트 보호막·flash → HP 피해·flash → 일반 사망 또는 자폭 준비 중 hit animation 생략 |
| 폭탄쥐 일반 사망 | 실제 dying guard → LOD 복구 → dying 설정/receipt 기록 → warning 갱신 → fuse 취소 → normal death_type → HP0·용사 처치 EXP·collision disable → died → death visual |
| 폭탄쥐 자폭 | 기존 `_complete_self_destruct` 본문 그대로. 남은 HP 비율·자폭 EXP·폭발 표시/피해 → died → death visual 유지 |

고블린과 폭탄쥐 모두 지원 보호막 다음에 엘리트 보호막을 소모한다. 엘리트 흡수량은 해당 metadata 변경 직후 표시 callback 전에 기록한다. HP 피해도 표시 전에 기록한다. 지원 보호막은 기존 common helper의 기록 지점을 이용한다. 음수/0 입력의 기존 정책을 통일한다는 이유로 바꾸지 않았다. 특히 폭탄쥐의 기존 clamp/common 최소 피해 계산도 유지한다.

자폭 준비 중 용사가 처치하면 기존대로 일반 사망이며 자폭 폭발을 새로 실행하지 않는다. 자폭 자체에 공격 receipt를 붙이거나 일반 처치로 바꾸지 않았다. 일반 사망은 HP0 추론으로 기록하지 않고 실제 dying guard 이후에 기록한다.

## 결과·상속·비용

receipt의 complete와 accepted는 별개다. 보호막만 흡수되면 accepted=true, hp_damage=0일 수 있다. dead/dying/blocked는 완료되더라도 accepted=false일 수 있다. 같은 버퍼가 중첩 begin되면 이전 writer/finish는 새 결과를 덮지 않고 API false를 반환한다. false를 이유로 피해를 다시 적용하지 않는다. 파동은 원래 수명/신원/revision 검증 뒤 유효한 accepted+death_started만 처치에 사용한다.

부모 script의 구현을 상속한 파생 actor는 자신의 take_damage override를 우회하지 못하도록 정확한 script 경로에서만 opt-in 지원한다. 미지원 direct 호출 또는 null 버퍼는 기존 피해 1회 경로를 유지하며 결과 false를 반환한다.

actor가 피해마다 result/Array/Dictionary/WeakRef를 만들지 않는다. 새 기록과 optional 분기는 고정 비용이고 기존 루프·스캔·공간 조회는 변경하지 않았다. 실행 시간/메모리 개선을 실측했다는 뜻은 아니다. 피해 결과의 정확한 관측 경계 확대가 목적이다. 이동·AI·공격·엘리트 증강·비주얼/사운드 리소스·저장 형식은 변경하지 않았다.

## 검증과 한계

Godot4.5.1 독립 프로젝트에서 실제 actor damage/death 함수, common shield/death, receipt/registry 및 파동 관련 코드를 추출해 실행했다. visual/popup/LOD·폭발 실행은 spy다. 폭탄쥐의 `_complete_self_destruct`는 실제 본문을 실행하되 내부 폭발 helper를 spy로 대체하여 호출 순서와 보상·비율을 비교했다. 실제 범위 폭발 피해 판정이나 화면을 검증한 것은 아니다.

| 검사 | 통과 |
|---|---:|
| 고블린 receipt 경계·Before/After·중첩·파생 override·64bit | 1,148 |
| 폭탄쥐 receipt 같은 경계 | 1,148 |
| 고블린 + 실제 파동 | 638 |
| 폭탄쥐 + 실제 파동 | 638 |
| 특수 조합1,944조건×4 + 자폭/처치/흡수 기록8검사 | 7,784 |
| 기존 슬라임 receipt 및 파동 회귀 | 1,786 |
| 합계 | 13,142 |

모든 검사 실패0, 최종 로그 ERROR/WARNING/잔류 객체 없음. 고블린 원래19함수·폭탄쥐29함수는 정확한 기록 hook 역변환으로 원래 본문과 비교했다. 하위 builder의 slime14/common27/projectile31 및 이전30 본문 비교도 통과했다. gdparse, Python source compile, 독립 editor import, staged diff 검사 통과.

전체 게임Godot4.7·모바일·실제 화면/충돌/폭발·장기 RAM·실측 성능은 미검증이다. 이번 작업에 온라인 또는 용사 플레이 기능은 포함되지 않았다. script path capability가 export에서 활성화되는지도 실기기 확인 대상이다.

## 재현

두 actor baseline은 위 기준 feature에서 가져온다. 다른 baseline은 [WAVE_DAMAGE_RECEIPT.md](WAVE_DAMAGE_RECEIPT.md), [SLIME_DAMAGE_RECEIPT.md](SLIME_DAMAGE_RECEIPT.md)의 기준과 동일하다.

```bash
python3 tests/build_goblin_bomb_receipt_fixture.py /tmp/goblin-bomb-fixture \
  --goblin-baseline /tmp/expand-goblin-before.gd \
  --bomb-rat-baseline /tmp/expand-bomb_rat-before.gd \
  --projectile-baseline /tmp/expand-projectile-before.gd \
  --wave-baseline /tmp/expand-wave-before.gd \
  --slime-baseline /tmp/expand-slime-before.gd \
  --common-baseline /tmp/expand-common-before.gd
godot --headless --path /tmp/goblin-bomb-fixture --script res://tests/goblin_bomb_special_smoke.gd
```

나머지 script는 goblin_receipt_smoke, bomb_rat_receipt_smoke, goblin_wave_receipt_smoke, bomb_rat_wave_receipt_smoke, slime_receipt_smoke, wave_receipt_smoke다. fixture는 체크아웃 밖에 생성하며 generated smoke는 기존 경계 테스트에 실제 actor를 대입한 것이다.

## 다음과 롤백

다음은 해골의 부활 처리다. HP0이 부활 시작이면 일반 사망/처치로 집계하지 않는 경계를 검증하고, 상태이상 및 callback 순서를 유지하며 결과 지원을 확대한다. 다른 특수 일반/엘리트/초월 actor는 순차 적용한다. 서버·매칭 확장은 보류한다.

오류가 발생하면 이 커밋을 revert한다. 두 actor는 기존 void API로 돌아가고 파동은 legacy fallback을 사용한다. common/receipt/projectile 자체를 변경하지 않아 이전 actor 지원과 솔플은 그대로 유지된다. main은 병합하지 않는다.
