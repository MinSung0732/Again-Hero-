# 지연 대상 수명 검증 — 용사 돌진 첫 적용

2026-10-10. 작업 feature/stage10-astra, 기준 e684443eb878f43bc438a8b95fdb1017ff37590b. main4122adb73e14552aae7c0aa7edefb2827f5d08d0 유지.

## 문제와 변경

이전 돌진은 Node2D 참조를 보관했다. 같은 몬스터 Node가 풀에서 반납·재활성화되면 is_instance_valid는 여전히 참이라 이전 수명의 돌진이 새로운 몬스터를 타격할 수 있었다. 이제 시작 시 battle의 Vector3i(epoch, slot, generation)를 캡처하고 이동 전·타격 직전에 같은 scope에서 resolve한다. 실패하면 기존 _finish_fighter_charge로 종료한다. 연쇄는 새 목표를 다시 캡처한다.

BattleTargetReference는 Hero마다 하나 생성하는 RefCounted다. target/scope는 WeakRef로 보관한다. 레지스트리 인터페이스가 있는 scope에서는 미등록 ZERO handle 및 불완전 API를 거절한다. API가 없는 기존 독립 씬은 valid/not-queued WeakRef 검사로 호환하지만 이 fallback은 풀 재사용 수명을 구분하지 못한다. 향후 그런 씬에 풀을 추가한다면 registry도 함께 연결해야 한다. 참조는 서버 인증·적아/체력/탐지 판정·공격자 수명 검증을 대체하지 않는다.

## 유지되는 규칙

- 유효한 대상의 보간, 이펙트, 잔상 주기, 직접 피해, 착지 피해, 연쇄 횟수/RNG, 치유, 종료 쿨타임은 그대로다.
- 타깃 사망/비탐지의 기존 physics gate도 유지한다. 수명 guard는 추가 보호다.
- 착지 AoE는 그 순간의 공간 조회를 사용한다. 예약 이후 등장한 주변 몬스터도 정상적으로 피해를 받는다.
- 일반 직선 투사체는 충돌 시 새로 만난 대상을 공격한다. 발사 당시 목표만 허용하는 검사를 붙이지 않는다.

## 비용

capture는 WeakRef 최대2개를 생성한다. resolve는 참조·scope 및 레지스트리 평균 O(1) 조회만 수행하고 프레임 컨테이너를 만들지 않는다. 대상 목록 전체 스캔을 추가하지 않는다. 종료 clear는 참조와 handle을 비운다. actual FPS/메모리 개선은 측정하지 않았다.

## 검증과 재현

Godot4.5.1 headless 독립 fixture. 돌진 begin/update/complete/damage/finish 본문은 실제 Hero에서 추출하고 registry/reference도 실제 코드다. 시각 효과·충돌/clamp·주변 조회·다음 타깃 선정은 명시 spy다.

| 검사 | 수 | 범위 |
|---|---:|---|
| charge_lifetime_smoke |420| 정상 직접+범위 피해, 동일 Node200회 재사용, 이동/완료 guard, epoch 교체, 이동 callback 중 재사용, 현재 AoE, 연쇄, ZERO/불완전 API, fallback/scope/삭제/weak clear |
| hero_action_port_smoke |6,255| 기존 공통 행동/타이머/status/port 회귀 |
| hero_movement_port_smoke |6,143| 기존 전문 직업/무타깃 이동 및 port 회귀 |
| 합계 |12,818| 실패0 |

새 builder는 기준 Hero611개 원래 함수의 정확히 검토한 guard 행만 역변환하여 본문 동일성을 확인한다. 기존 builder에도 같은 제한된 역변환을 적용했다. Hero 전체를 로드하는 테스트는 아니다. gdparse, Python compile, diff --check 및 독립 fixture editor import도 확인한다. 전체 게임4.7, GPU/모바일, 실제 물리 충돌과 프레임 성능은 미검증이다.

```sh
# full clone에서 기준 파일 준비; thin checkout은 보관한 원본 파일 사용
git show e684443eb878f43bc438a8b95fdb1017ff37590b:src/hero/hero.gd > /tmp/hero-life-baseline.gd
python3 tests/build_charge_lifetime_fixture.py /tmp/charge-lifetime-fixture --baseline-file /tmp/hero-life-baseline.gd
godot --headless --path /tmp/charge-lifetime-fixture --script tests/charge_lifetime_smoke.gd
```

## 다음 작업과 롤백

다음은 chain dagger 등 다른 예약 타깃 투사체의 setup/attach/tick/recycle 수명 연결이다. 공격 source 수명, await area effect, 다중 타격 claim, 상태 직렬화·서버 권한·보간/재접속은 별도 단계다. 이 커밋 전체를 git revert하면 기존 돌진과 테스트/문서가 함께 복원된다. 새 helper만 삭제하면 preload가 깨지므로 단독 삭제하지 않는다. main 병합이나 강제 push는 하지 않는다.
