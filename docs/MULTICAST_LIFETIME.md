# 다중시전 지연 예약·공유 후보 목록 수명 검증

후속: 얼음·폭풍 투사체 경계 적용은 [ELEMENTAL_PROJECTILE_LIFETIME.md](ELEMENTAL_PROJECTILE_LIFETIME.md)에 기록했다. 아래 다음 작업 설명은 작성 당시 이력이다.

2026-10-10. 기준 feature `c2c1f38410dd2b97936913c834e0959fd787b402`. 작업 `feature/stage10-astra`. main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 문제와 변경

archmage multicast는 후보 배열 하나를 재사용한다. 예전에는 tree/HP만 확인하므로 프로필 초기화나 새 예약 뒤 이전 타이머가 새 목록을 pop하고 새 active 상태를 꺼버릴 수 있었다. 독립 실제 타이머로 같은 Node 수명 내 reset/new start 후 이전 시전이 새 목록을 소비하는 경로를 재현했다.

시작 시 기존 scalar source handle과 부모 ID를 캡처한다. 새 예약 및 configure_profile 초기화는 _cancel_archmage_multicast를 통해 revision을 증가시키고 후보/active를 정리한다. coroutine은 시작 당시 revision을 저장하고 timer 전후에 동일 revision과 source/battle 수명을 확인한다. 피해/시전 callback에서 새 예약이 생겨도 이전 반복이 새 타이머를 만들거나 새 목록을 정리하지 못한다.

종료 cleanup은 같은 revision 및 같은 개체 수명일 때만 실행한다. 같은 수명의 HP0이면 기존 후보/active를 정리하지만 새 generation/epoch/부모의 상태는 건드리지 않는다. 새 수명 초기화는 configure_profile 등 생성·초기화 경로의 책임이다. 미등록 source는 목록을 변경하기 전에 거절한다. registry 없는 독립 씬의 기존 scalar fallback과 한계는 유지한다.

## 유지되는 의미와 비용

- 기존 원래 스킬 제외, 설정에 없는 스킬 제외, 활성 chain_dagger 제외, 기존 shuffle/RNG 순서와 pop 순서 유지.
- 최대 추가 횟수는 min(stacks, candidate count). 실패한 시전은 성공 횟수에 포함하지 않고 다음 후보로 진행하는 기존 규칙 유지.
- 추가 시전 인자는 false/false로 유지하므로 gauge 소비/재귀 추가 시전 정책은 바뀌지 않는다. 실제 skill body/음향/FX는 변경하지 않는다.
- 기존 0.30초 SceneTreeTimer/시간 배율 규칙 유지. 유효한 예약은 동일 주기로 진행한다.
- 후보 배열은 기존 Array를 clear/append/shuffle/pop으로 재사용한다. 예약별 복사·새 Array/Dictionary/WeakRef/RefCounted 생성 없음. source/revision/scope ID는 O(1) 값이고 수명 조회 평균 O(1)이다. 후보 구성은 기존 스킬 수 k에 대한 O(k).
- 이미 만들어진 타이머는 timeout까지 남지만 이후 cast/cleanup 권한은 잃는다. 정상 진입의 기존 active gate는 유지한다. FPS/RAM 개선량·장기 pending timer 수는 실측하지 않았다.

## 검증

Godot4.5.1 headless. 실제 _start_archmage_multicast/cancel/source helper와 실제 registry를 실행했다. configure_profile의 multicast reset 부분은 실제 코드에서 추출했고 나머지 configure_profile은 전체 본문 역변환 비교로 보존을 확인했다. 스킬 실행 본문/결과는 spy이며 전체 profile loader나 게임 전체를 실행한 검사는 아니다. offensive key 상수는 실제 소스에서 가져왔다.

| 검사 | 결과 |
|---|---:|
| 다중시전: fixed seed Before/After 순서/필터/false-false 인자/성공·실패 횟수/첫 호출 및 후속0.30초 간격, reset/new 예약 원래 버그 재현, source 재사용/epoch/HP0/부모/프로필 reset, 200회 재예약, callback reentrant 시작/수명 변경, 빈 후보/미등록 source |240 통과|
| 연소 |234 통과|
| holy power |445 통과|
| 얼음 기둥·대지 가시 |239 통과|
| 공통 행동 |6,255 통과|
| 전용 이동 |6,143 통과|
| 돌진 |420 통과|
| 체인 투사체 |759 통과|
| 합계 |14,735 통과, 실패0|

기준 Hero617함수는 정확한 변경 문자열을 역변환해 본문 비교했다. 기존 기준616/613/611 비교도 통과한다. 함수 whitelist로 검사를 생략하지 않는다. 최종 multicast verbose 종료 ERROR/WARNING/잔류 객체 없음. gdparse/Python compile/diff 및 독립 editor import 확인. 전체 Godot4.7 게임·실제 스킬/계정 profile 로딩·물리/GPU·모바일·서버·장기 RAM은 미검증이다.

```sh
git show c2c1f38410dd2b97936913c834e0959fd787b402:src/hero/hero.gd > /tmp/hero-multicast-before.gd
python3 tests/build_multicast_fixture.py /tmp/multicast-fixture --baseline-file /tmp/hero-multicast-before.gd
godot --headless --path /tmp/multicast-fixture --script res://tests/multicast_lifetime_smoke.gd
```

## 후속과 롤백

다음 후보는 ice bolt/storm 등 chain 외 투사체의 source/풀 수명 경계다. 다른 직업 장판·특수 이동/피해 상태 claim·서버 권한/동기화·플레이어 용사 입력은 미완료다. 이번 커밋 전체를 git revert하면 revision field/configure reset/helper/start/test/docs를 함께 복원한다. helper만 삭제하면 configure_profile/start 호출이 깨진다. main 병합/강제 push 없음.
