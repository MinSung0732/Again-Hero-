# 하드코딩 정리 16차: 상태 표시·애니메이션 연결

## 기준과 구현

- 시작 HEAD/원격 feature/stage10-astra: `230c96cb479fbb5e47b8159d6081fb99381bb89b`. 원격 main: `6f22053f462e1176ec2ecde131d589d5491791b2`. 시작 작업 트리 clean, 작업 브랜치 feature/stage10-astra. main 병합 없음.
- `hero_presentation_catalog`에 머리 위 상태바의 기본/용사별 위치, 폭·높이·간격·색상, 자원 표시 종류와 property/config/method 바인딩을 선언했다. Hero는 공유 규칙으로 비율형/칸형 자원바를 그린다. 직접 archetype 비교 8곳을 제거했다.
- 위치는 기본(resource/hp/shield) -79/-64/-49, 소환사 -128/-113/-98, 정화 -100/-85/-70, 아스트라 shield -94를 유지한다. 용사모드 identity가 있으면 기존처럼 세 Y값을 그리기 시점에 덮어쓴다. 조작 게이지는 min(Y)-24이며 그리기 순서도 유지한다.
- 비율형은 기본 궁극기/가스/정화/광기 각각 기존 property·config key·fallback·minimum·색상을 읽고 0~1로 clamp한다. HP는 기존처럼 비율을 clamp하지 않는다. 쉴드는 HP/최대값이 모두 양수일 때만 그린다.
- 권총은 현재 탄약, 재장전 시 floor((1-timer/max(duration,0.1))*capacity)를 기존대로 clamp해 채운 칸 수를 구한다. 소환 슬롯의 capacity/count는 기존 메서드를 같은 순서로 호출한다. 게이지·탄약·최대값·설정·identity는 캐시하지 않고 매번 최신 상태를 읽는다.
- 애니메이션 우선순위는 데이터 표로 이동했다. death100/hit80/dash70/attack60/run·move20/idle10/default40 유지. 보호·재생·중복 재시작 guard 등 고유 동작은 변경하지 않았다.
- 프레임/애니메이션 변경 handler의 정화 용사 선택 1곳은 공유 후크 목록으로 바꿨다. 실제 Stage9 anchor 계산과 기존 signal 연결은 그대로다. 다른 archetype은 빈 공유 목록을 사용한다.
- 신규 매 프레임 Array/Dictionary 생성·전체 그룹 조회·노드 생성/해제·캐시는 없다. 공유 metadata/Vector4와 스칼라를 사용한다. 단, 리플렉션과 공통 처리로 상태바 계산 CPU 비용은 소폭 증가했다(아래 계측).
- 전투·AI·성장·피해·보상·PNG·오디오 및 원본 앵커는 변경하지 않았다.

## 검증

- Godot 4.5.1 headless **15,682검사 PASS**, 최종 import/실행 script/runtime 오류·경고 0.
- 수정 전/후 실제 상태바/우선순위/프레임 변경 handler와 실제 애니메이션 보호·재생·재시작 함수 원문을 추출했다. 상태바 draw_rect/조작 게이지는 호출 기록 어댑터, 소환 getter는 값/호출 순서 어댑터, Stage9 anchor는 호출 기록 어댑터다. GPU 렌더나 실제 소환 registry/anchor 계산을 검증한 것은 아니다.
- 12개 archetype, 사망/HP 음수·초과·최대0, 쉴드 없음·부분·초과·최대0.5, 자원 음수·초과·설정 누락/음수/0/문자열, NPC/용사모드·무기null/identity null/identity override를 비교했다.
- capacity1/3/6/12, 칸수-1/0/1/3/20, 재장전 duration -1/0/0.05/2.4/5, timer -1/0/0.05/1.2/2.4/9 경계에서 명령 좌표·크기·색·순서와 소환 getter 호출 순서가 일치한다.
- 각 상태바 시나리오에서 같은 노드의 설정·자원·archetype·용사 identity를 바꾼 뒤 다시 그려 최신 값 반영을 비교했다. 상태바 시나리오 총1,024개/각2검사.
- 실제 AnimatedSprite2D/SpriteFrames의 9개 current×9개 requested animation, 재생/일시정지·loop/nonloop·표시/숨김, 사망/부활/hit/attack/dash 상태 7종에서 보호 판단·play·restart 최종 상태를 비교했다. 재시작 시간만 고정 시계 어댑터(같은 시각 재호출 및 71ms 경과)다. 실제 COMBAT_DELAY/전투 시간 흐름 검증은 아니다.
- 기존 우선순위 값과 미등록/빈 animation의 default40, 프레임 handler의 12종 후크 라우팅, 독립 layout 예제, 임의 property/max/색/X위치의 비율바 데이터 재바인딩, 공유 규칙 불변을 확인했다.
- 나머지 Hero **655함수**, 다른 Hero 선언, Main/Battle 전체 파일, 기존 Catalog 텍스트 동일. Python compile 및 `git diff --check` 통과.
- 실제 PNG·GPU 표시·전체 Hero/Battle ready·실전 전투/AI·실제 signal과 anchor 통합·PC/Android/FPS는 미검증이다.

## 계산 비용 계측과 제한

- 동일 Godot fixture에서 draw_rect를 아무 작업도 하지 않는 sink로 대체하고 상태바 계산만 계측했다. 기존10종 archetype을 순회하며 warmup 후 30,000회/배치 × 5배치씩 실행, 전후 실행 순서를 교대로 바꿔 중앙값을 사용했다.
- 변경 전 **1.9808µs/표시**, 변경 후 **4.0767µs/표시**, 차이 **+2.0959µs/표시**. 소환 getter의 기록/clear 비용도 양쪽에 동일하게 포함한다.
- 공유 규칙·동적 property/method 조회에 따른 CPU 증가이며 성능 개선이라고 주장하지 않는다. GPU/실제 Canvas draw·전체 게임·모바일을 제외한 합성 계측이므로 실제 FPS 변화를 나타내지 않는다. 이번 범위에서는 별도 상태 캐시/무효화 구조를 추가하지 않았다.

## 남은 상황

동일 tracked runtime351개/7개 변수의 직접 nonempty 문자열 ==/!= 패턴 후보는 **120 → 111곳**. `CONTENT_SELECTOR_INVENTORY_PHASE16_20261018.json`에 현재 위치를 기록했다. 고유 기술 조건을 포함하며 전역 하드코딩 점수나 남은 확정 작업 수가 아니다.

다음은 공격·이동·피해/사망·AI 조건에서 반복 바인딩과 필요한 고유 기술 조건을 구분하는 조사다. 레지스트리 전환·실제 플레이 검증은 별도이며 총 종료 차수는 이 분류 전 확정하지 않는다.

## 재현

```sh
python tools/build_hero_status_fixture.py /tmp/status-phase16 --baseline 230c96cb479fbb5e47b8159d6081fb99381bb89b
godot --headless --path /tmp/status-phase16 --editor --import
godot --headless --path /tmp/status-phase16 --script res://smoke.gd
godot --headless --path /tmp/status-phase16 --script res://benchmark.gd
python tools/inventory_content_selectors.py --output /tmp/content-selector-inventory.json
```

계측값은 호스트 부하에 따라 달라진다. fixture 생성기는 변경 범위 외 함수/선언·기존 Catalog 동일성도 검사한다. 위치 JSON의 base_head는 수정 전 SHA이고 source는 working tree다.
