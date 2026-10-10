# 성스러운 힘 지연 타격 수명 검증

## 후속 진행 — 연소 지속 피해·방출·충전 FX (2026-10-10)

실제 combustion의 충전 범위 tick와 corridor 방출을 보호했다. 충전 FX 반납은 재생 revision/원래 부모를 확인한다. 별도 fire field/둔화 스킬을 추가한 것이 아니다. 범위·비용·검증14,495검사·한계·후속·롤백은 [COMBUSTION_LIFETIME.md](COMBUSTION_LIFETIME.md). 전체 게임/모바일/서버·실측 성능은 미검증이다.


2026-10-10. 기준 feature `b9714d4a806faba67a7ac49c1cb4590aecab0453`, 작업 `feature/stage10-astra`. main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 이번 변경

성스러운 힘의 burst 시작, 각 피해 대상 직전, 피해 callback 직후, 다음 timer 생성 직전에 공격자·전투 수명을 확인한다. 개체 retirement/재활성화, epoch 변경, 부모 변경, HP0, queued source/scope이면 이후 타격을 중단한다. 종료 cleanup은 같은 수명일 때만 casting counter를 줄인다. 이미 생성된 이펙트는 기존 재생을 유지한다.

피해 callback이 대상 Node를 삭제하거나 같은 Node를 새 generation으로 재사용하면 이전 공격의 둔화 metadata를 새 대상에 쓰지 않는다. 피해 직전 Vector3i handle을 저장하고 이후 resolve 결과를 확인한다. 미등록 대상의 범위 피해 자체는 기존대로지만, registry가 있는 전투에서 ZERO handle 대상에는 수명을 증명할 수 없으므로 후속 둔화를 쓰지 않는다. registry 없는 독립 씬에서는 valid/not-queued 검사로 기존 동작을 유지한다. 이 fallback은 pool generation 구분이 불가능하다.

타깃 배열의 다른 항목이 피해 callback에서 free되는 경우, 탐지 정책의 Node 타입 인자에 넘기기 전에 is_instance_valid로 검사한다. 현재 AoE 조회는 매 burst 유지하므로 최초 cluster target이 사라져도 유효한 공격자는 시전 중심의 현재 적을 공격할 수 있다.

## 공통 예약 비용 및 await 정리

독립 검사에서 queued scope가 피해 callback에서 무효화됐는데도 다음 timer를 만들면, 삭제된 coroutine의 RefCounted source 예약이 Godot4.5.1 종료 진단에 남는 것을 관측했다. 얼음 기둥·대지 가시·성스러운 힘의 공통 예약을 scalar Vector3i(epoch/slot/generation) + 부모 instance ID 값으로 변경했다. instance ID는 로컬 부모 경계 검사용이며 네트워크 ID가 아니다. 각 coroutine의 값 복사이므로 동시 시전이 서로 예약을 덮어쓰지 않는다.

- 새 예약 RefCounted/WeakRef 생성 없음. 기존 레지스트리 조회 평균 O(1).
- 시전별 예약 저장 공간 O(1), 전체 그룹 스캔·프레임 임시 배열·피해 대상별 참조 객체 생성 없음.
- 취소된 시전은 callback 이후 새 timer를 만들지 않는다. 기존 정상 SceneTreeTimer와 scaled delay는 유지한다.
- 다른 caller의 범위 helper는 source_scope_id 기본0으로 기존 동작 유지.
- 모든 엔진 await/외부 삭제/타이머 수명 문제를 해결했다는 의미는 아니다. 타이머 대기 도중 외부에서 owner를 free하는 엔진의 취소 동작과 장기 메모리는 추가 실게임 검증 대상이다. 실제 FPS/RAM 개선량은 측정하지 않았다.

## 유지되는 규칙

정상 생성 수, RNG 순서, 좌표, 효과 프레임/크기, 음향, burst_delay(최소0.02), 시전 시 공격력, empowered 배율, undead_damage_multiplier, 둔화 multiplier clamp와 duration clamp를 유지한다. HP0인 같은 수명의 caster cleanup은 정상 처리하고 새 수명의 counter는 건드리지 않는다. 기존 공용 query buffer의 reentrant mutation 문제나 서버 권한/결정론적 RNG는 별도 작업이다.

## 검증

실제 Hero holy/casting/source 함수와 실제 registry/reference를 추출했다. FX/audio/타깃 조회/cluster 선정/언데드 Catalog/배율은 명시 spy다. 실제 SceneTreeTimer와 Godot4.5.1 headless를 사용했다.

| 검사 | 결과 |
|---|---:|
| holy power: 일반/강화·언데드 before-after FX·좌표·RNG·피해·음향·둔화 시간, source 재사용/epoch/HP0/부모 변경, 피해 callback 재사용200회/queued/free/신규 AoE/동시 시전/빈 타깃/미등록/fallback, 원래 버그 재현 | 445 통과 |
| 얼음 기둥·대지 가시 scalar 예약 회귀 | 239 통과 |
| 공통 행동 | 6,255 통과 |
| 전용 이동 | 6,143 통과 |
| 돌진 | 420 통과 |
| 체인 투사체 | 759 통과 |
| 합계 | 14,261 통과, 실패0 |

최종 holy fixture의 verbose 종료 진단에는 ERROR/WARNING/잔류 객체가 없었다. 최적화 이후 신규 기준 Hero616함수를 정확한 변경 문자열 역변환 후 비교했다. 이전 기준613/611함수 비교도 통과한다. 함수명 whitelist로 본문 검사를 생략하지 않는다. gdparse/Python compile/diff 및 독립 editor import 확인. 전체 게임 Godot4.7, 실제 물리·GPU·모바일·서버와 장기 성능/메모리는 미검증이다.

```sh
git show b9714d4a806faba67a7ac49c1cb4590aecab0453:src/hero/hero.gd > /tmp/hero-holy-before.gd
python3 tests/build_holy_power_fixture.py /tmp/holy-power-fixture --baseline-file /tmp/hero-holy-before.gd
godot --headless --path /tmp/holy-power-fixture --script res://tests/holy_power_lifetime_smoke.gd
```

## 다음 단계 / 롤백

다음 후보는 fire field의 지속 피해·둔화 callback 경계다. 서버 동기화, player hero 입력, 나머지 장판/특수 이동의 수명 및 상용 매칭 구현은 아직 남아 있다. 이번 커밋 전체를 `git revert <commit>`하면 scalar helper의 signature/caller/test와 holy 보호를 함께 복원한다. helper만 따로 되돌리면 타입·호출 인자가 맞지 않는다. main 병합/강제 push 없음.
