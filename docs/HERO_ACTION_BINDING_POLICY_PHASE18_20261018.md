# 하드코딩 정리 18차: 전투·포즈 실행 연결

## 기준과 구현

- 시작 HEAD/원격 feature/stage10-astra: `28dcb7cd6e817624e5f95e1a4ee357f3d5cbac3a`. 원격 main: `6f22053f462e1176ec2ecde131d589d5491791b2`. 시작 작업 트리 clean, 작업 브랜치 feature/stage10-astra. main 병합 없음.
- `hero_runtime_binding_catalog.ACTION_BINDINGS`에 도적/검방패/권총/광전사/연금술사/소환사의 physics 및 player pose 연결을 한 항목으로 선언했다. 대마법 용사의 common runtime 후크와 공용 pose 기본값도 데이터 소유다.
- `_physics_process_actions`의 직접 archetype 비교 7곳 및 별도로 player pose match의 콘텐츠 arm 6개를 제거했다. 고유 기술 본체나 AI 판단·피해/성장/보상은 변경하지 않았다.
- 각 Hero에 pose/특수 physics/common runtime Callable을 보관한다. 최초 필요한 선택 또는 archetype 변경 시에만 공유 metadata를 조회하고 다시 바인딩한다. 안정된 archetype의 매 프레임에는 캐시 키 확인과 기존 Callable 호출만 수행한다.
- 캐시 유효 flag를 별도로 두어 기본/미등록/빈 archetype도 최초 선택을 올바르게 초기화한다. metadata는 정적 상수이며 런타임 편집 대상이 아니다. 노드 교체/글로벌 캐시나 참조 집합은 만들지 않는다.

## 실행 시점 보존

- 용사모드: 무기 tick → 채널/부활 정지 gate → 이동 속도/이동 → 현재 archetype의 pose 선택 → return 순서를 유지한다. 무기 tick/이동 도중 archetype을 바꾸면 바뀐 값을 그 선택 시점에 반영한다.
- NPC/특수 전투: 기존 combat reposition 뒤에 선택한다. 특수 physics를 호출하면 기존처럼 즉시 return하며 공용 AI tick을 추가 실행하지 않는다. player_controlled이지만 weapons=null인 경로도 기존과 같다.
- 공용 AI: 기존 기억/관측·timer/게이지/스킬 update를 실행한 뒤 channel update 다음의 원래 위치에서 common runtime 후크를 선택한다. 앞선 update가 archetype을 바꾸면 그 후크 시점에 다시 갱신한다.
- 특수 physics나 pose 본체 안에서 archetype이 바뀌더라도 이미 선택한 이번 호출의 return 의미는 바꾸지 않는다. 다음 선택 지점에서 키 불일치를 감지한다.
- HP/사망·stun/fear/charm·부활·채널/관통 캐스팅·target/charge target 무효화 gate, retarget/공격/관측 timer와 실행 순서는 그대로다.
- 매 프레임 Array/Dictionary/Callable 생성, 그룹 조회, 노드 생성/해제는 추가하지 않는다. 최초 바인딩과 archetype 변경 시에만 Callable을 만든다. 극단적으로 archetype을 매번 바꾸는 부하는 아래 안정 상태 계측에 포함하지 않는다.

## 검증

- Godot 4.5.1 headless **43,637검사 PASS**, 최종 import/실행 오류·경고 0.
- 실제 수정 전/후 `_physics_process_actions` 전체와 실제 `_prepare_ranged_ai_intent`, 실제 HeroActionIntent/HeroActionPort를 실행했다. 특수 기술 본체·무기/상태 처리·타깃 판별·포즈/충돌 이동 등은 값/호출 기록 어댑터다. 실제 전체 전투/AI 알고리즘이나 물리 충돌 검증은 아니다.
- 12개 archetype × NPC/정상 용사/무기 null 용사/identity null 용사 4모드 × delta0/0.016/0.2 × 정상/HP0/사망/독사/기절/공포/매혹/채널/관통 캐스팅/타깃 없음·은신·원거리/돌진 타깃 무효/재타깃/부활 중·해제/연금술 채널·해금 대기/무기 tick의 채널 진입/이동 후 공격범위 변경 20시나리오를 각각 3프레임 비교했다.
- 12종 from × 12종 to × NPC/용사 × 무기 tick/이동/reposition/channel/궁극기/대마법 runtime/특수 physics/pose 콜백 8개 지점의 archetype 변경도 3프레임씩 비교했다. 비교 도중 캐시를 강제로 수리하거나 별도 refresh를 호출하지 않았다.
- 같은 archetype 캐시를 유지한 NPC↔용사/무기 없음/identity 없음 전환, 미등록/빈 archetype 기본 pose, 특수 physics의 조기 return, 공용 runtime 후크를 독립 확인했다.
- 호출 순서·실행 횟수·속도/위치·target/charge 상태·HP/사망·입력 정지/무기 tick 여부·상태 metadata·각 timer·관측 clock·현재 archetype과 재사용 intent의 내용/인스턴스 유지가 일치한다. 공유 바인딩 불변 및 캐시 pose 유효성 확인.
- 나머지 Hero **661함수**, 캐시 필드를 제외한 Hero 선언, Main/Battle/presentation Catalog 전체, 이전 runtime binding Catalog 텍스트는 동일하다. Python compile·`git diff --check` 통과.
- 실제 특수 기술/몬스터·GPU/PNG·전체 Hero/Battle ready·온라인/실기 터치·전체전투/모바일 FPS는 미검증이다.

## 계산 비용

- 합성 owner fixture에서 10종 × NPC/용사 20개 조건을 각각 warmup50회 후 2,000회/배치 × 5배치 계측했다. 전후 실행 순서를 교대로 바꿔 각 조건의 중앙값을 구한 뒤 같은 가중치로 평균했다. 상태·기술/이동 등 어댑터 비용이 포함된다.
- 변경 전 **5.777325µs/owner 호출**, 변경 후 **5.765625µs/owner 호출**, 차이 **-0.0117µs**로 이 환경에서는 사실상 비슷했다. GPU/전체 게임·모바일/FPS 개선을 뜻하지 않는다. 수치는 호스트 부하와 시나리오에 따라 달라진다.

## 남은 94곳의 보수적인 1차 분류

동일 tracked runtime351개/7개 변수 직접 nonempty 문자열 ==/!= 패턴 기준 후보는 **101 → 94곳**이다. 위치 목록은 `CONTENT_SELECTOR_INVENTORY_PHASE18_20261018.json`, 조건 주변 코드와 검토 메모는 `CONTENT_SELECTOR_REVIEW_PHASE18_20261018.json`에 기록했다.

| 분류 | 비교 위치 수 | 다음 판단 |
| --- | ---: | --- |
| 반복 연결 재검토 | 14 | 투사체/오디오/증강·성장/매혹 쿨다운/경계 이동 연결. 전체 owner·이벤트 순서 검증 후 데이터화 가능 여부 판단 |
| 소유권·진입 가드 | 54 | 다른 용사의 기술/런타임/포즈/앵커 실행을 막는 조건. 동작 보존, 단순 삭제 대상 아님 |
| AI 관측 구성 | 6 | 용사 고유 상태의 관측값/default/순서를 유지하며 별도 검증 필요 |
| 고유 동작 재검토 | 20 | 이동/피해/회복·성장 예외 등. 도메인·전체 함수 검토 전 보존 |

- 이 분류는 일치 위치와 주변 조건의 1차 검토이며 전체 소스의 하드코딩 감사 완료 선언이 아니다. 54/20/6곳이 영구적으로 데이터화 불가능하다는 뜻도 아니다.
- 14곳 또한 확정 삭제 수가 아니다. 94를 없애기 위해 기술 소유권이나 전투 의미를 바꾸지 않는다. 남은 연결 검토·레지스트리 성능 작업·실제 플레이 검증을 완료했다고 보고하지 않는다.
- 앞서 제시한 17~18차는 예상 범위였으며, 이번 결과로 모든 하드코딩 정리가 끝난 것은 아니다. 추가 연결 정리 범위는 위 기록을 기준으로 정한다.

## 재현

```sh
python tools/build_hero_action_binding_fixture.py /tmp/action-binding-phase18 --baseline 28dcb7cd6e817624e5f95e1a4ee357f3d5cbac3a
godot --headless --path /tmp/action-binding-phase18 --editor --import
godot --headless --path /tmp/action-binding-phase18 --script res://smoke.gd
godot --headless --path /tmp/action-binding-phase18 --script res://benchmark.gd
python tools/inventory_content_selectors.py --output /tmp/content-selector-inventory.json
```

위치 JSON의 base_head는 수정 전 SHA이고 source는 working tree다.
