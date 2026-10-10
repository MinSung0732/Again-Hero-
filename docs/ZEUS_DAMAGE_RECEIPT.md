# 제우스 incoming 피해 결과

브랜치 `feature/stage10-astra`, 기준 `ea2e859996d20409f3d1e59bb74188bc8d87cc91`.
수정 전 제우스 blob `23fed5413eb7899d7435bcb245148fdf5daa27ea`.
main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 변경과 보존

제우스는 부모 Thrower의 incoming 피해를 호출한 후 HP가 감소했고 살아 있을 때 hit cue를 재생한다. 기존 부모의 canonical opt-in 정책 때문에 제우스는 결과 API를 지원하지 않았고 파동은 기존 관찰 경로를 사용했다. 이제 제우스 자체 take_damage_with_result가 부모 실제 피해 함수와 공유 helper를 실행하고 receipt를 완료한다. 부모의 HP/보호막 실제 차감 기록을 사용한다.

부모 피해→생존 HP 감소 검사→hit cue 순서를 그대로 유지했다. 사망은 actor audio stop→부모 common 사망 guard→effect_layer redraw 순서다. 사망 소리는 기존 cinematic이 소유한다. 스킬·상태이상·카탈로그·시각/오디오 리소스, 부모/common/projectile은 변경하지 않았다.

complete만 신뢰한다. popup 또는 audio callback이 같은 버퍼를 재사용하면 이전 revision은 완료할 수 없다. 다른 버퍼는 각각 실제 HP 감소량을 유지한다. 사망 전 audio callback이 guard를 닫으면 death_started를 기록하지 않는다. HP0 대상의 중첩 피해가 새로운 처치를 만들지 않는다. 결과 실패 시 피해 재시도/처치 추론이 없다.

canonical script만 지원한다. 파생 take_damage override는 한 번만 legacy 호출한다. zero-argument _begin_death 시그니처를 유지했다. 호출자 receipt 재사용, scalar 기록 O(1); 매 피해 객체·배열·그룹 스캔 추가 없음. 성능/로딩 벤치마크를 측정한 변경은 아니다.

## 검증

Godot4.5.1 headless 독립 fixture 신규1,823+회귀27,650 = **29,473 검사, 실패0**.

- 제우스 receipt 1,148, wave 638, audio callback 경계37.
- 이자나미/슈텐도지 각 receipt1,148·wave638, 특수 경계15,912.
- Orc1,148, augment1,202, Slime1,148, Wave638, inherited4,030.

제우스 원래27함수는 추가 hook만 역변환해 동일한 본문임을 비교했다. 실제 Thrower·common·파동 코드와 제우스 피해/사망/소리 호출 함수를 추출해 실행했다. gdparse, Python compile, fixture import, git diff whitespace 통과.

시각·소리·authority는 spy로 순서와 호출을 검증했다. 실제 소리 청취, sprite 렌더링, 전체 게임4.7, 모바일, 물리·AI·성능은 미검증이다. outgoing 스킬과 상태이상 결과는 이번 범위가 아니다.

## 재현

CONTROL_TRANSCENDENT_DAMAGE_RECEIPT.md의 모든 원본 baseline을 준비하고 제우스 원본은 본 문서 기준 커밋에서 확보한다. 이전 문서의 builder 명령을 tests/build_zeus_receipt_fixture.py로 바꾸고 --zeus-baseline /tmp/q-zeus-before.gd를 추가한다. 예시 target은 /tmp/q-fixture이며 checkout 밖에 둔다.

```bash
Godot --headless --path /tmp/q-fixture --editor --import
Godot --headless --path /tmp/q-fixture --script res://tests/zeus_receipt_smoke.gd
Godot --headless --path /tmp/q-fixture --script res://tests/zeus_wave_receipt_smoke.gd
Godot --headless --path /tmp/q-fixture --script res://tests/zeus_receipt_audio_smoke.gd
```

나머지10개 회귀 스크립트 이름은 CONTROL_TRANSCENDENT_DAMAGE_RECEIPT.md와 같다. source 기준·fixture 추출·spy 범위는 두 문서를 함께 참조한다.

## 다음 검토 / 롤백

1. 전체 게임에서 HP 피해 시 생존 피격음, 보호막 완전 흡수 시 피격음 제외, 사망 소리 소유·효과 종료를 확인.
2. 남은 actor incoming opt-in 누락을 조사하고 outgoing 상태이상 결과 계약을 검토. 이번 변경이 전체 구조 개선 완료나 매칭 가능을 뜻하지 않는다.
3. 문제 발생 시 작업 브랜치에서 git revert <이번 커밋> 사용. 이전 이자나미/슈텐도지 연결은 유지된다. main 병합은 별도 요청 시 진행한다.
