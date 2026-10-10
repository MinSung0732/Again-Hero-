# 얼음·폭풍 투사체 수명 검증

2026-10-10. 기준 feature `b537ee30f8b538c7e76187f4117bb7caf2fb4673`, projectile blob `ce379d9680830e745b70fe3b522770356b968833`. 작업 `feature/stage10-astra`. main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 문제와 변경

기존 ice_bolt/storm은 source Node가 유효한지만 확인했다. 동일 Node를 풀에서 재사용하거나 전투 epoch가 바뀌면 이전 발사체가 새 용사의 공격으로 실행될 수 있었다. 피해 callback 뒤에는 삭제/재사용된 대상에게 속박을 쓰거나 새로 설정된 투사체를 종료하는 경로도 있었다. 기존 실제 코드 fixture에서 source 재사용 후 피해가 발생하는 버그를 재현했다.

setup에서 이미 개체가 소유한 source/self BattleTargetReference를 재사용해 해당 발사 수명을 캡처한다. 이동·피해·충돌 전 및 외부 피해/게이지 callback 후 현재 battle parent, epoch/slot/generation, local setup/deactivate revision을 검증한다. 취소된 작업은 나머지 피해/속박/게이지를 중단한다. 종료는 같은 local revision에만 적용해 callback에서 설정한 새 shot을 반납하지 않는다.

폭풍은 각 대상의 피해 직전 scalar handle을 저장하고 피해 후 같은 수명인지 확인한 뒤 속박 metadata를 쓴다. 피해 중 대상이 죽어도 source/shot이 유효하면 나가는 구간 게이지 보상은 유지한다. 얼음은 impact 위치를 피해 전에 저장한다. 대상이 사라지거나 재사용되면 후속 함수에 null target과 저장 위치를 전달한다. 실제 Hero.resolve_archmage_ice_bolt_hit는 target 인자를 사용하지 않아 기존 lethal impact/AoE가 유지된다. source/shot이 바뀌면 follow-up은 중단한다. source callback 내부 Hero AoE의 모든 피해 경계는 이번 수정 범위에 포함하지 않는다.

## 유지되는 의미 및 비용

- 얼음은 최초 표적을 예약하지 않으며 직선 경로에서 가로채는 적에게 맞는 규칙을 유지한다.
- 폭풍의 나감/복귀 궤적, 구간별 instance ID 중복 제거, 기본·복귀·강화 피해 배율, 속박 시간, 나가는 구간만 게이지 회복 규칙을 유지한다. target generation별 재적중 규칙으로 바꾸지 않는다.
- Hero HP0만으로 기존 발사체를 즉시 취소하지 않는다. 기존 registry의 died/retire 시점 이후 무효화된다. 별도 사망 gameplay 정책은 추가하지 않는다.
- chain_dagger/berserker_wave의 실제 처리 본문은 변경하지 않는다. 공통 setup/deactivate revision은 기존 것을 사용한다.
- 기존 참조 필드 2개 재사용. setup마다 source/self capture에 WeakRef 최대4개를 만들며 프레임/대상별 예약 객체는 만들지 않는다. per-victim Vector3i handle은 값이다. 조회는 registry 평균 O(1), 범위 후보 n개 처리는 기존 O(n)이다. 기존 공간 조회/풀링을 유지하며 새 그룹 스캔/프레임 배열/instantiate/free를 추가하지 않는다. 취소 시 기존 pool 반납 경로를 사용한다.
- registry API가 없는 독립 씬의 기존 weak fallback은 풀 generation을 구분하지 못한다. battle의 등록/resolve 계약이 있는 경로를 기준으로 검증했다. 실측 FPS/메모리/로딩 개선은 주장하지 않는다.

## 검증과 재현

Godot4.5.1 headless에서 실제 projectile setup/physics/body callback/damage/finish/deactivate와 실제 registry/reference를 실행했다. 렌더링 4함수와 탐지 정책, source 조회/스킬/게이지 및 pool adapter는 spy다. body_entered 및 physics는 수동 호출하므로 엔진 충돌/전체 씬 테스트는 아니다.

| 검사 | 결과 |
|---|---:|
| 얼음/폭풍 Before/After 100frame × 강화 여부, setup/궤적/피해/왕복/중복/게이지 |404 통과|
| source 재사용/epoch/queued/미등록, 기존 버그 재현, 가로채기, target 재사용/queued/null impact 위치, source 피해 callback 취소, damage/impact/gauge callback shot 재설정 및 200회 반복, 복귀 callback, 정확한 왕복·강화 배율/속박 |230 통과|
| 기존 연쇄단검 회귀 |759 통과|
| 이번 실행 합계 |1,393 통과, 실패0|

기준28함수는 정확한 변경 문자열을 역변환하여 모두 본문 비교한다. 연쇄 fixture는 이 역변환을 추가해 기존 기준15본문 보존 검사를 계속 실행한다. gdparse/Python compile/git diff check 및 독립 editor import 확인. 최종 elemental verbose 종료 스크립트 ERROR/WARNING/잔류 객체 없음. SDL 게임패드 mapping의 misc2 출력은 엔진 환경 메시지다. 이전 전체 Hero 회귀14,735검사는 이번에 다시 실행하지 않았다. 전체 Godot4.7 게임·실제 에셋/물리/GPU·Android·네트워크·장기 RAM은 미검증이다.

```sh
git show b537ee30f8b538c7e76187f4117bb7caf2fb4673:src/hero/archmage_skill_projectile.gd > /tmp/elemental-before.gd
python3 tests/build_elemental_projectile_fixture.py /tmp/elemental-projectile-fixture --baseline-file /tmp/elemental-before.gd
godot --headless --path /tmp/elemental-projectile-fixture --script res://tests/elemental_projectile_smoke.gd
```

## 후속과 롤백

다음 후보 berserker_wave의 source/피해 callback 경계. Hero impact 내부 AoE·다른 직업 장판·스킬 상태 직렬화·서버 권한/스냅샷·플레이어 용사 입력은 미완료다. 기존 솔플 행동을 보존하며 경계를 순차 적용하는 단계이며 온라인 모드를 활성화하지 않았다.

롤백은 이번 커밋 전체 git revert로 projectile/helper 및 fixture/doc을 함께 복원한다. 공통 registry나 기존 chain guard를 제거하지 않는다. main 병합/강제 push 없음.
