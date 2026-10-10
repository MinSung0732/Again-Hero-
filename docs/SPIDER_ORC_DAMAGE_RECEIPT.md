# 거미·오크 피해 결과 지원

2026-10-10. 기준 feature `e0f340f16869a12c0a03594f9d65de2dcbc50b7b`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0`.
수정 전 spider blob `a76b83f9635305aeb5d69803c128e34d2bc5351c`, orc blob `d1f790ed1791d60d448db0451b01b4bc74641f2e` 확인.
작업은 `feature/stage10-astra`에서 진행했다.

## 변경과 보존

거미·오크는 슬라임과 같은 `supports_damage_receipt()` 및 `take_damage_with_result(amount, receipt)` 계약을 지원한다. 기존 void `take_damage`도 같은 내부 피해 함수로 위임한다. 결과 객체는 caller가 재사용하며 actor가 피해마다 생성하지 않는다. 기존 파동 caller의 capability 검사로 자동 연결되므로 projectile 분기는 추가하지 않는다.

보호막 흡수는 기존 공통 계산에서, HP 피해는 HP 변경 후 표시 callback 전에 기록한다. 사망 시작은 common의 실제 death guard를 통과해야 기록한다. 완료와 accepted는 별개이며, 같은 버퍼의 중첩 호출로 결과가 무효화되면 API는 false를 반환한다. 피해 자체를 재시도해서는 안 된다. 등록 handle 신원과 수명 정보는 기존 receipt 계약을 따른다.

오크의 처리 순서는 보호막 → HP 변경 → 분노 증가 → 마지막 돌진 검사 → HP 피해 기록 → 피해 표시 → hit 연출 → 사망 검사다. 분노 상한, 돌진 HP 비율·최초 1회·시간, 보호막만 소모된 경우 분노 미증가, 치명타에서 돌진 미발동을 유지한다. 거미 hit flash 0.10초와 오크 0.12초, died/사망 animation 순서, 이동/공격/AI/증강 계산은 유지한다.

파생 script는 부모 receipt 구현으로 자신의 take_damage override를 우회할 수 없다. 현재 script 경로가 정확히 해당 actor일 때만 지원하며 직접 호출된 미지원 API는 legacy 피해 1회 후 false를 반환한다. 새 actor에서 별도로 지원하려면 자체 구현과 수명/부활 검증이 필요하다.

## 비용과 한계

새 피해 경로에는 추가 함수 위임과 null/revision 검사, scalar 결과 기록만 있다. 새 per-hit Array/Dictionary/WeakRef/result 객체, 전체 그룹 스캔 또는 pair loop를 추가하지 않았다. 기존 오크 증강 Dictionary 조회는 변경하지 않았다. 이번 단계는 신뢰할 수 있는 결과 경계 확대이며 실행 속도 향상을 실측했다는 의미가 아니다.

death_started는 로컬 사망 처리 시작이다. 서버 사망 확정이나 네트워크 payload가 아니며, process-local instance ID·handle을 그대로 서버 식별자로 사용할 수 없다. Hero 및 초월 부활 actor는 아직 이 API로 확대하지 않았다.

## 검증

Godot 4.5.1 독립 fixture에서 실제 함수 본문을 추출해 실행했다. 시각 표시·authority 조회는 spy이고 damage/common shield/death/receipt/registry 및 파동의 관련 함수는 실제 코드다.

| 검사 | 통과 수 |
|---|---:|
| 거미 receipt 경계·Before/After·재진입·파생 override·64bit | 1,148 |
| 오크 receipt 같은 경계 | 1,148 |
| 실제 거미 + 파동 통합 | 638 |
| 실제 오크 + 파동 통합 | 638 |
| 오크 증강 300조건 및 callback 순서 | 1,202 |
| 기존 슬라임 receipt 회귀 | 1,148 |
| 기존 슬라임 + 파동 회귀 | 638 |
| 합계 | 6,560 |

실패 0. 거미 원래 16함수·오크 17함수의 변경 hook을 정확히 역변환해 기준 본문과 비교했다. 하위 builder는 slime14/common27/projectile31 및 이전 projectile30 본문 검사를 수행한다. gdparse, Python compile, diff 검사, 독립 editor import 통과. 로그에서 ERROR/WARNING/잔류 객체 없음.

전체 게임은 Godot4.7 대상이며 전체 게임 실행·실제 충돌/애니메이션·모바일·서버·프레임 시간/RAM 측정은 수행하지 않았다.

재현은 이전 문서의 baseline 파일에 더해 spider/orc를 위 기준 feature에서 다운로드해 다음을 실행한다. projectile/slime/common baseline SHA는 [WAVE_DAMAGE_RECEIPT.md](WAVE_DAMAGE_RECEIPT.md)와 [SLIME_DAMAGE_RECEIPT.md](SLIME_DAMAGE_RECEIPT.md)에 기록되어 있다.

```bash
python3 tests/build_spider_orc_receipt_fixture.py /tmp/spider-orc-receipt-fixture \
  --spider-baseline /tmp/receipt-spider-before.gd \
  --orc-baseline /tmp/receipt-orc-before.gd \
  --projectile-baseline /tmp/wave-receipt-before.gd \
  --wave-baseline /tmp/wave-before.gd \
  --slime-baseline /tmp/receipt-slime-before.gd \
  --common-baseline /tmp/receipt-common-before.gd
godot --headless --path /tmp/spider-orc-receipt-fixture --editor --import
godot --headless --path /tmp/spider-orc-receipt-fixture --script res://tests/orc_receipt_augment_smoke.gd
```

나머지 여섯 script는 `spider_receipt_smoke`, `orc_receipt_smoke`, `spider_wave_receipt_smoke`, `orc_wave_receipt_smoke`, `slime_receipt_smoke`, `wave_receipt_smoke`다. 임시 fixture는 체크아웃 밖에 생성한다. 자동 생성된 거미·오크 smoke는 기존 테스트를 실제 해당 actor로 치환하며 damage 구현을 모사하지 않는다.

## 롤백과 다음 단계

문제가 생기면 이 변경의 커밋을 revert하면 된다. 두 actor의 API 지원이 없어져 파동은 기존 legacy 관측 fallback으로 돌아간다. 공통 receipt/registry/projectile 변경은 이번 커밋에 포함하지 않았다.

다음은 다른 일반 몬스터의 피해 특수 처리·상속 관계를 조사해 지원 범위를 확대하는 단계다. 부활·무적 actor는 독립 검증 이후 연결하고, 이후 결과 sequence·직렬화·서버 권한 경계를 설계한다.
