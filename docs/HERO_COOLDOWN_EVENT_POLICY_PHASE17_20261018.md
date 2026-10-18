# 하드코딩 정리 17차: 쿨다운·사망/레벨업 이벤트 연결

## 기준과 범위

- 시작 HEAD/원격 feature/stage10-astra: `a57335969cdcb0a6b50585a0b617932128fd72c1`. 원격 main: `6f22053f462e1176ec2ecde131d589d5491791b2`. 시작 작업 트리 clean, 작업 브랜치 feature/stage10-astra. main 병합 없음.
- 공격·이동·AI·피해·사망의 남은 후보를 조사한 뒤, 이번에는 여러 상태 처리에서 공유하는 쿨다운 목록/해금 조건과 사망·레벨업 오디오 연결을 정리했다. 고유 공격/이동·피해 판정·AI 관측 계산은 그대로 둔다.
- 새 `hero_runtime_binding_catalog`에 9종 용사의 쿨다운 property 목록과 3종의 조건부 확장 목록, 대마법 용사의 dictionary/config property·순서 있는 skill key를 선언했다. Hero의 기존 ARCHMAGE_SKILL_KEYS는 동일한 typed Array의 별칭이다.
- `hero_presentation_catalog.EVENT_AUDIO`에 6종의 사망 메서드 및 견습마도사 계열의 레벨업 오디오 호출을 선언했다. 공통 호출기가 event에 맞는 메서드/인자를 전달한다. 실제 음원·플레이어·음량은 바꾸지 않았다.
- 직접 archetype ==/!= 비교 10곳, 별도로 쿨다운 accessor의 콘텐츠별 match arm 9개를 제거했다. 두 숫자는 같은 조사 범위가 아니며 합산한 전역 점수가 아니다.

## 쿨다운과 목록 소유권

- 공포 tick/무작위 쿨다운 지연/전체 쿨다운 부여는 공유하는 base/expanded 목록을 읽기만 한다. 목록 선택은 그때의 조건부 스킬 해금 상태나 summoner_open_gate_unlocked를 읽으므로 해금/용사 변경 시 오래된 캐시가 남지 않는다.
- 매혹 진입은 기존 `_get_external_skill_cooldown_properties`에서 독립 복사본을 받는다. 매혹은 그 목록을 보관하고 `_clear_charm`에서 clear하므로 공유 목록을 직접 넘기면 안 된다. 기존 accessor의 mutable snapshot 의미를 유지했다.
- 대마법 용사의 random delay는 설정이 nonempty Dictionary인 key만 같은 순서로 후보화한다. 후보가 없으면 난수를 소비하지 않는다. 선택된 기존 timer를 max(0,timer)+delay로 변경하고, 다른 용사의 선택/누락 값 처리도 동일하다. 전후 다음 randi 결과까지 비교했다.
- 공포는 모든 dictionary key를, 전체 부여는 기존 imposed_skill_cooldown/archmage_blink_cooldown_timer 갱신 뒤 모든 key를 처리한다. property 경로도 기존 순서와 clamp를 유지한다.
- 공포 경로에서 목록을 새로 만들지 않는다. 매혹 시 1회 snapshot 복사는 유지하며, 대마법 random delay의 후보 Array는 기존과 같이 이벤트 시 생성한다. 새로운 매 프레임 Array/Dictionary·캐시·그룹 조회·노드 생성/해제는 추가하지 않는다.

## 사망·레벨업 이벤트

- 사망 오디오는 기존처럼 is_dying 설정/시작 신호/상태 정리 후, invulnerability·색/속도·충돌 초기화 전에 호출한다. 등록되지 않은 archetype은 오디오 호출만 no-op이며 나머지 사망 절차는 계속한다.
- 레벨업은 효과 초기화/재생 뒤 오디오를 호출한다. 기존 ranged_kiter 연결이 있으면 그 호출만 선택하며 오디오가 실제로 준비되지 않았다고 일반 fallback을 추가 실행하지 않는다. 다른 용사는 기존 level_up_audio가 유효할 때 stop→play한다.
- 실제 사망 Tween·0.52초 timer·트리 이탈 검사·died/queue_free 코드는 변경하지 않았다. 같은 사망 요청을 다시 받으면 기존 is_dying gate에서 반환한다.

## 검증

- Godot 4.5.1 headless **6,725검사 PASS**, 최종 import/실행 오류·경고 0.
- 12개 archetype, 조건부 해금 조합4종, 시간 -1/0/0.1/1.5/5, 양수/음수/null timer, 살아 있음/HP0/사망 상태에서 실제 random delay·fear tick·전체 부여 함수 원문을 비교했다. random/fear의 null skip을 포함하며 전체 부여는 기존 API가 요구하는 숫자 property 범위 및 조기 반환 경계를 검사한다.
- property 선택 순서·해금 확인 호출·get/set 순서·최종 timer·반환값·다음 RNG 값 일치. 대마법 설정이 없음/빈 Dictionary/잘못된 타입/유효 항목 일부일 때 5개 seed를 추가 비교했다.
- 기존 accessor의 결과를 clear해도 다음 결과가 유지되는지, 실제 `_clear_charm`이 보관 목록을 clear한 뒤에도 원본 규칙이 유지되는지, 이후 해금 변경을 바로 반영하는지 확인했다.
- 12종 × 효과 상태4종 × fallback audio 상태3종에서 실제 레벨업 owner를 반복 실행했다. 효과 생성은 합성 프레임 어댑터, 오디오 플레이어/메서드는 호출 기록 어댑터이며 실제 음원 재생·청감 검증은 아니다.
- 12종 × 사망 상태5종에서 실제 비동기 사망 owner를 실행했다. sprite 숨김/사망 animation 누락/frames null/이미 사망 중/도중 트리 이탈을 포함한다. 실제 Tween·SceneTree timer·시작/종료 신호·queue_free/tree exit를 비교했고 cleanup/오디오/애니메이션 호출은 기록 어댑터다. 즉시 상태와 0.65초 후 최종 이벤트·노드 생존 상태가 일치한다.
- ARCHMAGE_SKILL_KEYS의 내용/순서, 독립 숫자 기대값, 미등록 event no-op, 공유 property/dictionary/audio 규칙 불변 확인.
- 나머지 Hero **654함수**, 새 preload/키 별칭을 제외한 Hero 선언, Main/Battle 전체, 기존 presentation Catalog 텍스트는 동일하다. Python compile·`git diff --check` 통과.
- 전체 실제 Hero/Battle·소환/보상·매혹 진입 통합·원본 디버프 정리·AI 판단·실제 PNG/음원·PC/모바일/GPU/FPS는 미검증이다.

## 계산 비용

- 합성 property/get/set 기록 어댑터에서 10종 용사의 fear cooldown tick을 warmup 후 20,000회/배치 × 5배치씩 실행했다. 전후 순서를 교대로 실행한 중앙값은 **3.4624 → 3.5669µs/호출**, 차이 **+0.1045µs/호출**이다.
- 초기안의 중간 Catalog 함수 호출을 제거해 최종안은 공유 map을 직접 조회한다. 목록 생성은 줄었지만 이 계측으로 CPU/FPS 개선을 주장하지 않는다. 호스트 부하·합성 get/set 및 trace 비용이 포함되고 실제 게임·모바일 계측은 아니다.

## 남은 상황

동일 tracked runtime351개/7개 변수 직접 nonempty 문자열 ==/!= 조사 후보는 **111 → 101곳**. `CONTENT_SELECTOR_INVENTORY_PHASE17_20261018.json`에 위치를 기록했다. 위 수에는 필요한 고유 기술의 실행/자원·상태 gate가 포함되어 있으며 전부 제거할 작업 수가 아니다.

다음 조사 대상은 `_physics_process_actions`의 중복된 기술/포즈 실행 연결과 나머지 고유 조건 분류다. AI context의 용사별 관측, 피해/사망·기술 상태 조건을 숫자 감소 목적으로 임의 삭제하지 않는다. 레지스트리 전환·실제 플레이 검증은 별도이며 전체 종료 차수는 아직 확정하지 않는다.

## 재현

```sh
python tools/build_hero_cooldown_event_fixture.py /tmp/cooldown-events-phase17 --baseline a57335969cdcb0a6b50585a0b617932128fd72c1
godot --headless --path /tmp/cooldown-events-phase17 --editor --import
godot --headless --path /tmp/cooldown-events-phase17 --script res://smoke.gd
godot --headless --path /tmp/cooldown-events-phase17 --script res://benchmark.gd
python tools/inventory_content_selectors.py --output /tmp/content-selector-inventory.json
```

위치 JSON의 base_head는 수정 전 SHA이고 source는 working tree다. 계산 비용은 호스트에 따라 달라질 수 있다.
