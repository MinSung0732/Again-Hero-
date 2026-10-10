# 광전사 파동 수명 검증

후속: 얼음 impact 내부 경계 적용은 [ICE_IMPACT_LIFETIME.md](ICE_IMPACT_LIFETIME.md)에 기록했다. 아래 다음 작업 설명은 작성 당시 이력이다.

2026-10-10. 기준 feature `7739fa3d75c25e2fa13ee28e71c5659a7e77756b`, projectile blob `50f629b99cc0eddf1b4948473242dec0e5557257`. 작업 `feature/stage10-astra`. main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.

## 문제와 변경

berserker_wave는 원래 source가 살아있는 같은 전투 수명인지 확인하지 않고 피해를 주며, take_damage 뒤 적중 회복/처치 알림을 보냈다. callback에서 source 또는 projectile을 재사용하면 이전 작업이 새 개체의 보상과 종료를 실행할 수 있었다. 대상의 HP도 적중 회복 callback 뒤 읽어 다른 수명의 HP가 이전 처치 판정에 쓰일 수 있었다. 실제 Before 코드에서 source 재사용 후 피해/적중 알림을 재현했다.

setup에서 기존 source/self BattleTargetReference를 사용하여 발사 수명을 캡처한다. 파동 이동/선분 피해 전과 damage/hit/kill 외부 호출 직후 source/self/부모/epoch/slot/generation/local revision을 확인한다. 중단 시 같은 local revision의 shot만 종료하므로 재설정된 shot의 traveled/종료/나머지 피해를 건드리지 않는다. 별도 예약 객체나 await를 추가하지 않는다.

처치 결과는 damage 뒤 동일 shot 검증 후, 적중 회복 알림 전에 저장한다. 대상이 새 nonzero handle이면 이전 처치로 계산하지 않는다. 정상 사망은 battle registry에서 제외돼 ZERO가 되므로 기존 대상의 HP가 0이면 보상을 유지한다. queued lethal 대상도 안전하게 HP를 읽어 보상을 유지한다. 이미 HP0이었던 대상은 적중 알림만 받고 처치 보상은 받지 않는다. source/shot 무효화 시 이후 보상은 중단한다.

현재 registry는 retired target의 마지막 generation을 공개하지 않는다. ZERO만으로는 callback 안에서 재사용 후 다시 retire까지 일어난 대상을 완전히 구분하지 못한다. 이번 구현은 정상 사망 보상을 보존하며 현재 nonzero generation 변경을 차단한다. 이중 재사용/retire까지 권한 서버에서 엄격하게 처리하려면 별도 damage-result 계약으로 피해 시점의 kill/identity를 반환하는 후속 작업이 필요하다. 현재 source/projectile 수명 확인은 해당 경로와 별개로 적용된다.

## 보존과 비용

- 기존 선분 capsule 거리 계산, 끝점/경계 포함, hit_radius/속도/거리/피해/시각 설정 유지.
- 기존 공간 후보 조회와 shot별 instance ID 중복 제거 유지. 새 표적 예약이나 generation별 재적중 규칙 없음.
- 기존 Hero.notify_berserker_blood_art_hit의 회복과 notify_berserker_skill_kill의 gauge/광기 계산 본문은 변경하지 않는다. 적중→처치 callback 순서도 유지한다.
- HP0만으로 발사체를 즉시 취소하는 새 규칙 없음. 등록 해제/queued/source scope 변경부터 취소한다.
- 기존 참조 필드 재사용, setup capture에서만 WeakRef 최대4개. 프레임/대상별 새 Array/Dictionary/RefCounted/WeakRef 생성 없음. 대상 handle/처치 bool은 O(1) 값, registry 조회 평균 O(1), 기존 후보 n개 처리는 O(n). 기존 pooling/그리드 유지. 실측 성능 개선량은 측정하지 않았다.
- registry 없는 독립 scene weak fallback은 동일 Node의 풀 generation을 구분하지 못하는 기존 한계가 있다. 전체 네트워크/PvP 권한 경계가 완료된 것은 아니다.

## 검증

Godot4.5.1 headless, 실제 projectile setup/physics/sweep/damage/finish/deactivate와 실제 registry/reference 실행. 렌더링 4함수/탐지 정책/source 후보조회/적중·처치 알림/pool adapter는 spy. physics를 수동 호출하므로 실제 엔진 충돌/GPU/전체 게임 테스트는 아니다.

| 검사 | 결과 |
|---|---:|
| Before/After 100frame × 피해1/100/250, 궤적/관통/피해/중복/적중/처치/반납 |303 통과|
| 피해·적중·처치 callback마다 shot 재설정100회, 새 shot 상태/남은 피해/보상 확인 |600 통과|
| source/self 재사용·epoch·queued·미등록·다른 부모, 원래 버그 재현, 정상 retired kill·새 victim generation·알림 전 kill snapshot·queued lethal·fresh target·이미죽은대상·끝점/제로 선분·반경 경계 |23 통과|
| 얼음·폭풍 회귀 |634 통과|
| 연쇄단검 회귀 |759 통과|
| 이번 실행 합계 |2,319 통과, 실패0|

기준30함수 전체 본문은 정확한 변경 문자열 역변환으로 비교한다. 기존 elemental28/chain15본문 검사도 wave 역변환을 조합해 유지하며 함수 whitelist를 추가하지 않는다. gdparse/Python compile/git diff check와 독립 editor import 통과. 최종 wave verbose 종료 스크립트 ERROR/WARNING/잔류 객체 없음. SDL misc2 mapping 출력은 엔진 환경 메시지. 기존 전체 Hero 회귀는 이번에 다시 실행하지 않았다. 전체 Godot4.7 게임·실제 물리/시각·Android·서버·장기 RAM 미검증.

```sh
git show 7739fa3d75c25e2fa13ee28e71c5659a7e77756b:src/hero/archmage_skill_projectile.gd > /tmp/wave-before.gd
python3 tests/build_wave_projectile_fixture.py /tmp/wave-projectile-fixture --baseline-file /tmp/wave-before.gd
godot --headless --path /tmp/wave-projectile-fixture --script res://tests/wave_projectile_smoke.gd
```

## 후속·롤백

다음 후보 Hero 얼음 impact 내부 범위 피해 및 기둥 생성의 source/target callback 경계. 다른 직업 장판·damage-result 계약·상태 직렬화·서버 권한/동기화·플레이어 용사 입력은 미완료다. 온라인 모드는 활성화하지 않았다.

이번 커밋 전체를 git revert하면 projectile/helper/fixture/docs가 함께 복원된다. 기존 registry/chain/elemental guard를 따로 제거하지 않는다. main 병합/강제 push 없음.
