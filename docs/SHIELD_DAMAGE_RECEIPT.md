# 박쥐·유령·미라 피해 결과 경계

2026-10-10. 작업 `feature/stage10-astra`. 기준 feature `469d20765196e45d5c9bf09c9803ee6a26523a2e`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0`.
수정 전 최신 파일 blob 확인: bat `0b658feeb5e5aa4e02aa0c4a68ac54702a89f4d6`, ghost `0294749d598b7a0eea8d18917c54e216a2e0640d`, mummy `d6ec6cbd5c4bd0299dad1bf331c031a2e51e4aab`.

## 구현

기존 void take_damage와 새 take_damage_with_result가 같은 실제 피해 본문을 사용한다. caller의 재사용 receipt에 지원 보호막/자체 보호막/HP 피해와 실제 사망 시작을 기록한다. script 경로 capability guard를 통해 파생 actor의 take_damage override를 우회하지 않는다. null/미지원 직접 호출은 legacy 피해를 한 번 실행하고 false를 반환한다. false는 결과 사용 불가이며 피해 재시도를 의미하지 않는다.

박쥐는 HP0/dying 거절, 지원 보호막→HP→popup→hit flash→play_hit→redraw→death 순서를 유지한다. 유령은 amount<=0도 거절하고 치명타에서 play_hit 없이 death로 이동한다. 유령 death는 common guard 이전에 phase_shift_active=false 및 visual.modulate=WHITE를 실행하는 기존 순서를 유지한다.

미라는 Orc를 상속하지만 별도 피해 본문을 사용하므로 자체 opt-in을 명시했다. 기존 Orc의 receipt 인자를 지원하는 _begin_death를 사용하며 부모 damage/rage 계산을 호출하지 않는다. 다른 상속 actor의 지원 여부를 임의로 켜지 않았다.

| 미라 상황 | 결과와 기존 동작 |
|---|---|
| 지원 보호막만 소모 | shield_absorbed 기록, accepted=true; 자체 보호막/HP/반격은 기존 early return |
| 자체 보호막만 소모 | 실제 자체 흡수량 기록, accepted=true/hp_damage=0; 기존 popup/hit 재생 |
| 두 보호막+HP | 두 흡수량 합계와 실제 HP 감소량 기록 |
| 자체 보호막 파괴 | 기존 shield_broken 확정 후 봉인 반격, 기존 상태이상, 마지막 death |
| 치명타+보호막 파괴 | 반격 이후 common guard에서 실제 사망 시작 기록 |
| 같은 결과 버퍼로 반격 재진입 | 이전 revision의 writer/finish 거절, 피해 재시도 없음 |

_sync_shield_capacity의 최대체력 비율 재조정·최초 basis 조건·broken 보호막 재생 금지 본문을 유지한다. 자체 보호막 흡수와 HP 결과는 popup callback 전에 기록하므로 표시/반격 callback이 상태를 변경해도 원래 피해 값이 바뀌지 않는다. 기존 _deal_damage/_status_scoped_deal_damage의 status_action_scope 시작/복원, 회복 감소와 저주 적용 순서는 변경하지 않았다. 해당 상태이상 스택/성장 수치 자체를 이번에 바꾸지 않았다.

공통 receipt/common, 투사체 및 네트워크 시제품은 변경하지 않았다. 기존 광전사 파동 capability 경로로 자동 연결된다. 다른 피해 caller·상태이상 결과 이벤트·용사/초월 부활 계약은 미완료다. death_started는 사망 guard 시작이지 애니메이션 종료나 서버 확정 이벤트가 아니다.

## 비용 및 검증

추가 결과 기록은 고정 scalar 필드의 O(1) 연산이다. 매 피해 새 receipt/Array/Dictionary/그룹 스캔을 추가하지 않았으며 caller가 기존 버퍼를 재사용한다. 기존 봉인 반격의 상태이상 scope 토큰 생성 정책은 그대로다. 실행시간/메모리 수치 개선을 입증한 프로파일링 결과는 없다.

- 신규 세 actor 각각 receipt1,148+파동638 =5,358검사.
- 미라의 실제 비율 재조정/두 보호막/반격/상태이상·scope 복원/치명타 순서/버퍼 재진입 및 유령 phase 해제1,812검사.
- 기존 슬라임1,148+파동638 =1,786검사. 합계8,956검사, 실패0.
- 실제 함수 추출을 사용하는 Godot4.5.1 headless 독립 fixture 실행. 표시·scene 초기화·타겟 권한은 spies다. 미라의 실제 반격/상태이상 scope와 상속 Orc death 본문을 추출해 실행한다.
- hook 정확한 역변환 후 원래 박쥐23/유령19/미라14함수 본문 동일. 하위 builder의 slime14/common27 및 현재 projectile31/이전30함수 보존 검사도 통과.
- gdparse/Python compile/독립 editor import 및 실제 변경 diff 검사 통과.
- thin checkout에는 원래 ghost 파일이 없어 staged 전체 추가로 표시된다. 원격 기준 파일의 기존89/91줄 공백은 변경하지 않았으며 해당 파일은 원격 baseline 대비 diff --check로 확인했다. 나머지 staged diff --check는 통과했다.

추가 테스트가 처음 종료되지 않은 원인은 테스트가 투사체의 결과 필드 이름을 잘못 참조했기 때문이다. 실제 _wave_damage_receipt 필드로 수정하고 추가 테스트와 필요한 회귀를 재실행해 통과했다. 제품 코드의 전투 동작 수정은 없었다.

전체 Godot4.7 게임/실제 AI·애니메이션·충돌/모바일/온라인·부하 성능은 검증하지 않았다. fixture는 전체 게임 실행을 대신하지 않는다.

## 재현

baseline 파일을 git show COMMIT:PATH로 추출한다. 박쥐/유령/미라/status_action_scope/mummy_behavior_catalog는 기준 feature에서 가져온다. 기존 fixture의 baseline은 projectile e4221dfde1ed16f55f51e8fb134857a5659b1ec9, wave7739fa3d75c25e2fa13ee28e71c5659a7e77756b, slime/common4e50e15ce201d25025167d1da5410ee518af0801이다.

```bash
python3 tests/build_shield_receipt_fixture.py /tmp/shield-fixture \
 --bat-baseline /tmp/next-bat-before.gd \
 --ghost-baseline /tmp/next-ghost-before.gd \
 --mummy-baseline /tmp/next-mummy-before.gd \
 --status-scope-baseline /tmp/next-status_action_scope.gd \
 --mummy-catalog-baseline /tmp/next-mummy_behavior_catalog.gd \
 --projectile-baseline /tmp/expand-projectile-before.gd \
 --wave-baseline /tmp/expand-wave-before.gd \
 --slime-baseline /tmp/expand-slime-before.gd \
 --common-baseline /tmp/expand-common-before.gd
```

Godot --headless --path /tmp/shield-fixture --script res://tests/NAME_smoke.gd를 실행한다. NAME: bat_receipt, bat_wave_receipt, ghost_receipt, ghost_wave_receipt, mummy_receipt, mummy_wave_receipt, mummy_shield_receipt, slime_receipt, wave_receipt. checkout 밖에 독립 fixture를 생성한다.

## 롤백 및 다음 작업

이 변경 커밋만 git revert하면 세 actor의 기존 void 피해 경로로 복귀한다. 부모 Orc/common 및 기존 receipt actor는 바꾸지 않았다. main 유지, 후속 변경이 있다면 revert 충돌을 검토한다.

다음은 늑대·전갈 등 부모 take_damage를 사용하는 상속 actor의 감소/특수 생존 계약과 상태이상 결과 경계 조사다. 현재 활성 목표는 기존 마왕 솔플의 내부 구조 정리이며 실제 용사모드/매칭/온라인 시제품 확대는 보류한다.
