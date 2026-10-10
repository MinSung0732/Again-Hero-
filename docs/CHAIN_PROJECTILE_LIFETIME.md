# 체인 단검 — 예약 타깃·공격자·비동기 작업 수명

2026-10-10. 작업 feature/stage10-astra, 기준 ededeedb50ceb783072fc0612dda1ac815ca8532. main4122adb73e14552aae7c0aa7edefb2827f5d08d0 유지.

## 실제 문제

chain_dagger는 current_target Node를 여러 프레임에 걸쳐 추적했다. Node가 풀에서 반납·재사용되면 valid 검사는 새 몬스터를 원래 목표로 취급한다. 더 큰 문제는 _apply_chain_current_ticks / _finish_after_chain_ticks가 await 이후 is_inside_tree만 검사했다는 점이다. 반납된 투사체도 tree 안에 남으므로 오래된 timer가 새로운 투사체의 source/query 경로로 피해를 주거나 새 투사체를 종료할 수 있었다. deferred monitoring=false 역시 같은 프레임에 다시 setup된 투사체를 비활성화할 수 있었다.

## 연결과 계약

- target/source/projectile용 BattleTargetReference 객체3개를 Node 생성 때 한 번 보유한다. setup 때 source/projectile 및 초기 타깃 캡처, 연쇄마다 새 타깃 캡처. source를 먼저 캡처하여 projectile/target 등록 실패도 살아있는 source의 active count를 한 번 정리한다.
- chain_dagger의 이동/충돌 전에 source·projectile·타깃 수명을 확인한다. 무효 예약 타깃은 투사체 종료. 탐지 불가하지만 아직 같은 수명인 타깃은 기존대로 homing을 해제하고 직선 비행한다.
- current_target만 공격하도록 제한하지 않는다. 정상 예약 수명 동안 다른 새 몬스터가 가로채면 기존대로 피해를 받는다. hit_ids(instance ID) 중복 제한은 이번에 변경하지 않았다.
- 구간 피해는 각 tick 현재 범위를 조회한다. 구간 내 새 몬스터 수명도 정상 피해 대상이다. 이 영역은 특정 예약 타깃 수명에 묶지 않으며 source와 projectile 수명만 검사한다.
- setup/deactivate마다 로컬 int life revision 증가. await 시작 당시 revision과 현재 revision이 다르면 오래된 작업은 종료한다. deferred monitoring 쓰기도 같은 revision guard를 거친다. 네트워크 번호나 저장용 ID가 아니다.
- 피해/audio/링크 callback 이후 수명을 다시 확인한다. 피해 루프 중 반납/재설정되면 다음 대상부터 중단한다. 충돌 위치는 피해 전에 저장하므로 callback에서 피해 대상이 삭제/재사용되어도 이전 타격의 기점을 안전하게 사용한다.
- _finish는 active를 먼저 소비하고 참조를 해제한다. 중첩 _finish는 알림/반납을 중복하지 않는다. 종료 callback이 새 setup/deactivate를 실행하면 이전 finish는 새 수명을 반납하지 않는다. source 알림은 같은 수명에서만 보낸다.
- source가 사망/삭제된 경우 추가 피해는 중단하고, 현재 로컬 수명의 종료 timer는 기존 투사체를 정리한다. 기존 timer 자체를 취소하는 API를 새로 만들지 않았으며 재개 시 guard로 차단한다.
- registry API가 없는 독립 씬은 기존 WeakRef fallback 계약을 따른다. API가 있는 전투에서 ZERO/미등록 identity는 거절한다. battle acquire_projectile은 반환 전에 등록하므로 정상 경로를 만족한다. 다른 모드가 별도 pool을 만들면 setup/deactivate와 등록/반납 훅을 함께 지켜야 한다.

## 유지 범위와 비용

ice_bolt/storm/berserker_wave의 피해/루트/게이지/왕복/쓸기 함수와 공통 시각 리소스 함수는 그대로다. 공통 setup/deactivate에서 revision/참조 초기화를 하고 finish에서 callback 소비 순서를 안전하게 바꾼다. 정상 피해·속도·사거리·쿨타임·연쇄 성장·강화·tick 수/간격·기존 SceneTreeTimer pause/time-scale 설정은 유지한다. 새로운 clock/tick/network authority를 켜지 않는다.

캡처 시 WeakRef를 생성하지만 프레임마다 객체·Array·Dictionary를 새로 만들지 않는다. 수명 resolve는 registry 평균 O(1). tick은 기존 조회 후보 k개에 O(k) 검사 추가. group scan을 추가하지 않았으며 기존 fallback query/instance ID hit map의 전체 개편은 하지 않았다. 성능 수치 개선을 측정/주장하지 않는다.

## 검증

Godot4.5.1 headless 독립 fixture에서 실제 원래/새 projectile의 setup/physics/body_entered/피해/연쇄/await/finish/deactivate 본문을 실행한다. 시각 reset/apply/hit/frame build만 spy로 교체하고, 탐지 policy·대상 조회는 in-memory spy다. body_entered는 직접 호출하므로 실제 물리 충돌을 검증하지 않는다. 전체 원본 projectile도 별도 파일로 복사하여 engine editor import의 parse 검사를 받는다.

| 테스트 | 수 | 확인 |
|---|---:|---|
| chain_projectile_lifetime_smoke |759| 4종 정상 before/after, 강화/보너스6tick, timer 정상 종료, 원래 timer bug 재현, 같은Node200회 재사용, 새 가로채기·구간 대상, source 삭제/재사용, epoch, 피해/종료 callback 재사용, 타깃 삭제, 미등록 identity, deferred monitoring |
| charge_lifetime_smoke |420| 이전 돌진/registry/reference 수명 계약 회귀 |
| 합계 |1,179| 실패0 |

원래23개 함수 중 무관한15개 함수 본문 동일 확인. gdparse, Python compile, git diff --check, 독립 editor import 통과. 전체 게임4.7·GPU·모바일·실물리·FPS/메모리는 미검증이다.

```sh
git show ededeedb50ceb783072fc0612dda1ac815ca8532:src/hero/archmage_skill_projectile.gd > /tmp/chain-projectile-before.gd
python3 tests/build_chain_projectile_fixture.py /tmp/chain-projectile-fixture --baseline-file /tmp/chain-projectile-before.gd
godot --headless --path /tmp/chain-projectile-fixture --script tests/chain_projectile_lifetime_smoke.gd
```

## 다음 작업과 롤백

다른 target-bound 지연 투사체 및 Hero await 범위 스킬의 source/session 생명주기를 조사하여 같은 계약을 좁게 확장한다. hit claim의 generation 전환, 모든 skill/augment action port, 전투 상태 snapshot/직렬화·서버 권한·보간/재접속은 별도 단계다. 용사 플레이/PvP/서버는 아직 활성화하지 않는다.

문제가 생기면 이 단계 커밋 전체를 git revert한다. 이전 ededeedb50의 돌진 수명 검증은 남고 chain_dagger만 원래 경로로 복원된다. 강제 push/브랜치 reset/main 병합은 하지 않는다.
