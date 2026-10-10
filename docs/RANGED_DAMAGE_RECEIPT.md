# 원거리 일반 몬스터 피해 결과 경계

2026-10-10. 작업 `feature/stage10-astra`, 기준 feature `8ffdc50776d1f6db9a5a231d750329e634c95e38`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0`.
수정 전 최신 파일 확인: skeleton_archer `22b02b52d9a9dd3bcb1a1b491af3e2ef067a42e6`, goblin_thrower `24050e88d05f032ed046a5bd938cbdbb9060ef33`, kobolt `12e19016fd05d9d942ed764bbbebf6c7b9847cbe`.

## 구현과 의미

세 actor의 기존 take_damage는 공통 내부 본문을 호출한다. supports_damage_receipt는 canonical script 경로를 확인하여 파생 script의 기존 take_damage override를 우회하지 않는다. take_damage_with_result는 caller 소유 receipt의 revision을 시작하고 같은 실제 피해 본문을 사용한다. null 또는 미지원 호출은 기존 동적 take_damage를 한 번 실행하고 결과 false를 반환한다. false는 피해 재시도를 뜻하지 않는다.

지원 보호막은 기존 common helper에서 실제 흡수량을, HP는 실제 변경 직후 표시 callback 전에 기록한다. 실제 death guard만 death_started를 기록한다. 기존 파동은 이미 지원 capability를 확인하므로 caller 변경이 없다. 공통 receipt/common/projectile 및 네트워크 시제품은 변경하지 않았다.

| 상황 | 결과 |
|---|---|
| 보호막만 소모 | shield_absorbed>0, accepted=true, hp_damage=0 |
| HP 피해 | 실제 HP 감소량, accepted=true |
| 해골 궁수 첫 치명타 부활 | accepted=true, death_started=false |
| 부활 중 추가 피해 | accepted=false, death_started=false |
| 실제 사망 | common guard 시작에서 death_started=true |
| 같은 버퍼 재진입 | 이전 writer/finish 거절; 피해 재시도 없음 |

complete는 처리 완료이며 피해 수용·사망 여부와 별개다. 부활 자체의 새 이벤트 필드는 추가하지 않았다. 미래 서버 권한/피해 sequence/직렬화 및 다른 피해 caller 전환은 별도 작업이다.

## 보존한 게임플레이

투척수와 코볼트는 dead/dying/amount<=0을 거절하며 보호막→HP→표시/flash/redraw→치명타 사망의 기존 순서를 유지한다. 치명타에는 play_hit을 호출하지 않는다. 이동·타겟·투사체·공격 AI·증강 계산 본문은 변경하지 않았다.

해골 궁수는 부활 대기 중 피해와 직접 회복을 거절한다. 최초 한 번만 부활하고 부활 후 두 번째 치명타에서 실제 사망한다. 부활 및 사망 시 windup/burst timer와 남은 연사를 취소한다. 실제 사망 전 elite_skill_reviving 메타 초기화 순서도 유지한다. timer fallback 및 death pose 준비→ONE_SHOT 역재생 완료 경로, 설정 HP 비율, 충돌/시각 복구, attack_timer=maxf(attack_cooldown,0.10)을 그대로 유지한다.

파동 첫 치명타는 기존 적중/회복 정책을 유지하되 처치로 집계하지 않는다. 부활 뒤 새 pooled 파동의 실제 치명타는 검증된 처치 한 번을 기록한다.

## 비용 및 검증

추가 기록은 고정 scalar 필드의 O(1) 연산이다. caller의 기존 reusable receipt를 사용하므로 매 피해 배열/Dictionary/새 receipt/전체 그룹 스캔을 추가하지 않았다. 실행시간/메모리 수치가 개선됐다는 프로파일링 결과는 없으며 이번 목적은 판정과 관측 경계의 정리다.

- 신규 세 actor 각각 receipt1,148+파동638 =5,358검사.
- 실제 궁수 부활/공격 준비 취소/회복/공격 대기시간/파동 처치 경계1,162검사.
- 기존 해골1,148+파동638+부활3,469 및 슬라임1,148+파동638 =7,041검사.
- 합계13,561검사, 실패0. Godot4.5.1 headless 실행. 테스트는 실제 함수 추출과 외부 의존성 spies를 사용하는 독립 fixture다.
- hook을 정확히 역변환해 원래 궁수26/투척수18/코볼트19함수 본문이 동일함을 확인한다. 하위 builder의 해골25/슬라임14/common27 및 파동31/이전30함수 보존 검사도 통과한다.
- gdparse, Python compile, 독립 fixture editor import, staged diff 검사 수행.

전체 Godot4.7 게임, 실제 애니메이션/충돌/장판/모바일, 온라인 서버 및 부하 성능은 검증하지 않았다. 단위 검증 통과가 전체 전투 동작 증명을 대신하지 않는다.

## 재현

이 저장소의 tests/build_ranged_receipt_fixture.py는 baseline 함수 보존 검사 및 독립 fixture를 생성한다. baseline은 해당 변경 전 Git 파일이다. fixture는 checkout 외부 경로를 사용한다.

```bash
python3 tests/build_ranged_receipt_fixture.py /tmp/ranged-fixture \
 --skeleton-archer-baseline /tmp/r-skeleton_archer-before.gd \
 --goblin-thrower-baseline /tmp/r-goblin_thrower-before.gd \
 --kobolt-baseline /tmp/r-kobolt-before.gd \
 --skeleton-baseline /tmp/sk-before.gd \
 --projectile-baseline /tmp/expand-projectile-before.gd \
 --wave-baseline /tmp/expand-wave-before.gd \
 --slime-baseline /tmp/expand-slime-before.gd \
 --common-baseline /tmp/expand-common-before.gd
```

세 ranged baseline은 기준 feature에서 추출한다. skeleton은9da63abaed1b79446aa8ead84e1169d1c95159c5, projectile은e4221dfde1ed16f55f51e8fb134857a5659b1ec9, wave는7739fa3d75c25e2fa13ee28e71c5659a7e77756b, slime/common은4e50e15ce201d25025167d1da5410ee518af0801에서 추출한다.

Godot --headless --path /tmp/ranged-fixture --script res://tests/NAME_smoke.gd를 실행한다. NAME: skeleton_archer_receipt, skeleton_archer_wave_receipt, goblin_thrower_receipt, goblin_thrower_wave_receipt, kobolt_receipt, kobolt_wave_receipt, ranged_revival, skeleton_receipt, skeleton_wave_receipt, skeleton_revival, slime_receipt, wave_receipt.

## 롤백 및 다음 작업

이 변경 커밋만 git revert하면 기존 void 경로로 복귀한다. 공통 API/기존 actor 기능은 건드리지 않았고 main은 변경하지 않는다. 후속 변경이 생겼다면 해당 revert 충돌을 검토한다.

다음은 남은 일반 actor의 특수 보호막/죽음/부활 계약 및 상태이상 결과 경계 조사다. 실제 용사모드·매칭·온라인 시제품 확대는 사용자 요청 전까지 보류한다.
