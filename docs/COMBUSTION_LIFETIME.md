# 연소 충전 지속 피해·방출·이펙트 수명 경계

## 후속 진행 — 다중시전 예약·공유 목록 경계 (2026-10-10)

archmage multicast timer에 source/battle 수명과 local revision을 연결하고 configure_profile reset도 같은 cancel 경계로 연결했다. 새 예약의 목록·active를 이전 작업이 소비/정리하지 못한다. 정상 RNG/필터/성공 횟수/0.30초 유지. 범위·비용·검증14,735검사·한계·후속·롤백은 [MULTICAST_LIFETIME.md](MULTICAST_LIFETIME.md). 전체 게임/모바일/서버·실측 성능 미검증.


2026-10-10. 기준 feature `ca1fd6b4eb384f96eb667ca91ea3c1f4a5c0a671`. 작업 `feature/stage10-astra`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 실제 범위와 변경

이전 문서의 fire field라는 표현에 해당하는 archmage 코드는 별도 장판/둔화 스킬이 아니라 연소(combustion)의 충전 구체 범위 tick과 마지막 직선 thrust다. 이번에는 이 실제 경로만 보호하며 다른 직업 장판이나 새로운 상태이상을 추가하지 않는다.

시작 시 scalar source handle과 부모 scope ID를 캡처한다. 충전 tick/피해 대상 직전, 다음 timer 생성 직전, 방출 시작과 corridor 피해 대상 직전, 방출 음향과 counter cleanup 전에 같은 수명을 확인한다. retirement/재활성화/epoch 변경/부모 변경/HP0/queued source/scope이면 이후 작업을 취소한다. 동일 수명의 HP0은 counter를 정리하고 새 수명의 counter는 건드리지 않는다. source_scope_id 기본0인 다른 corridor caller는 기존 동작이다.

반경·직선 피해 helper에서 피해 callback이 다른 타깃을 free하면 Node 타입 탐지 정책에 넘기기 전에 valid 확인으로 건너뛴다. 실제 공간 조회·타깃 순서·corridor 투영/거리 계산은 그대로다. shared scratch의 재진입 수정까지 해결한 것은 아니다.

## 충전 이펙트 반납

충전 FX가 대기 중 pool에서 반납·재사용되면 같은 AnimatedSprite2D를 이전 시전이 반납할 수 있었다. _spawn_archmage_fx가 재생마다 해당 FX의 archmage_cast_revision metadata를 증가시키고, 충전 시전은 그 숫자만 저장한다. 종료 helper는 valid/not-queued/visible/revision/원래 부모 ID가 일치할 때만 반납한다. Hero가 다른 부모로 이동해도 FX의 원래 부모를 통해 반납한다. freed FX는 typed helper 호출 전에 제외한다. 리소스 누락/null FX는 피해와 종료를 막지 않는다.

재생 revision은 로컬 비주얼 전용이며 서버 entity ID가 아니다. 일반 animation_finished callback 전체나 외부 pool API의 모든 수명을 재설계한 것은 아니다. 이 번호는 _spawn_archmage_fx를 통한 재생에 적용한다. 다른 코드가 같은 pool key를 직접 재설정한다면 동일한 재생 경계를 연결해야 한다.

## 의미와 비용

- 충전 위치/방향·기간·tick interval·elapsed 누적과 정상 SceneTreeTimer 유지. 충전 피해는 기존 시전 시 계산, thrust 피해는 기존 방출 시 계산이다.
- 강화 배율, 종료 시 현재 nearest 대상 방향, thrust range/폭, FX 프레임·크기·Tween0.22초·음향·정상 casting counter 유지.
- 각 tick의 현재 AoE 조회 유지. 시전 이후 등장한 대상도 남은 피해를 받는다. 동시 시전은 각 coroutine의 scalar 값으로 독립한다.
- source와 FX 예약은 O(1) 값 저장, resolve 평균 O(1). 새 WeakRef/RefCounted 예약·그룹 스캔·프레임 배열/Dictionary·O(n²) 없음. FX metadata는 풀 개체마다 키1개, 재사용 시 숫자만 갱신한다. 기존 pool/cache/시각 자원 생성 방식은 유지한다.
- FPS/RAM/모바일 성능 개선 수치를 측정한 변경은 아니다. 외부에서 await owner를 free하는 엔진 취소 동작과 전체 FX callback 수명은 별도 검증 대상이다.

## 검증

Godot4.5.1 headless에서 실제 Hero 연소/범위·corridor/캐스팅/수명/FX 생성·반납 함수를 추출하고, 실제 battle transient pool acquire/recycle 함수도 실행했다. 질의·nearest 결정·음향은 spy, PNG는 2x2 placeholder Texture2D다. 실제 SpriteFrames/AnimatedSprite2D/Tween/SceneTreeTimer를 사용했다.

| 검사 | 결과 |
|---|---:|
| 연소: 일반/강화 Before/After 전체 FX 인자·음향·충전3tick+방출 비교, source 재사용/epoch/HP0/부모 이동, 원래 버그 재현, 피해 callback 취소, FX pool 실제 재사용200회, freed 후보/FX, 신규 AoE, 리소스 누락, 동시 시전, 미등록 source |234 통과|
| holy power |445 통과|
| 얼음 기둥·대지 가시 |239 통과|
| 공통 행동 |6,255 통과|
| 전용 이동 |6,143 통과|
| 돌진 |420 통과|
| 체인 투사체 |759 통과|
| 합계 |14,495 통과, 실패0|

신규 기준 Hero616함수 본문에서 정확한 변경 문자열만 역변환해 비교했다. 이전 기준616/613/611 비교도 통과한다. 함수 whitelist로 검사를 생략하지 않는다. 최종 연소 verbose 종료 ERROR/WARNING/잔류 객체 없음. gdparse/Python compile/diff 및 독립 fixture editor import 확인. 전체 게임 Godot4.7·실제 텍스처/음향·물리·GPU·모바일·서버·장기 RAM은 미검증이다.

```sh
git show ca1fd6b4eb384f96eb667ca91ea3c1f4a5c0a671:src/hero/hero.gd > /tmp/hero-fire-before.gd
python3 tests/build_combustion_fixture.py /tmp/combustion-fixture --baseline-file /tmp/hero-fire-before.gd
godot --headless --path /tmp/combustion-fixture --script res://tests/combustion_lifetime_smoke.gd
```

## 다음과 롤백

다음 후보는 archmage multicast의 지연 추가 시전 및 공유 후보 목록 정리다. 다른 장판/직업 async·서버 권한·플레이어 용사 입력·동기화는 미완료다. 이번 커밋 전체를 git revert하면 연소/FX metadata/helper/corridor optional 인자/테스트/문서를 함께 복원한다. main 병합·강제 push 없음.
