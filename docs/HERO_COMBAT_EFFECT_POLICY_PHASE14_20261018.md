# 하드코딩 정리 14차: 도적·검방패·권총 효과 초기화

## 기준과 범위

- 시작 HEAD/origin feature/stage10-astra: `390e844701ca3a56e0878a26726886ac85e217e2`.
- origin/main: `6f22053f462e1176ec2ecde131d589d5491791b2`. 시작 작업 트리 clean. main 병합 없음.
- 조사 결과 `_apply_stage2_rogue_effect_visuals`, `_apply_stage3_fighter_effect_visuals`, `_apply_stage4_gunner_effect_visuals`의 프레임 경로·구간·FPS·loop·대상 노드·scale/position/z/filter/modulate 및 누락 정책을 `hero_presentation_catalog.COMBAT_EFFECT_PROFILES`로 이동.
- 세 기존 진입점과 ready 호출 위치는 유지. archetype/event metadata를 공통 초기화기가 읽는다. 새 효과 이름·파일 구간·대상·속성은 데이터에서 바꿀 수 있다.
- 직접 archetype 비교 3곳 제거. 호출이 사라진 전용 프레임 빌더 2개와 Hero의 불필요한 효과 경로 상수 8개 제거. 경로 정의는 Catalog 소유.
- 공격·피해·AI·성장·보상·앵커·PNG·오디오 및 상태 표시 렌더링은 이번 범위에 포함하지 않는다.

## 보존한 동작

- 도적 진입점의 공격 효과 hidden/frames=null 초기화는 다른 archetype에도 무조건 실행한다. 3개 효과를 모두 로드한 뒤 순서대로 할당한다. 한 프레임이라도 누락되면 해당 효과는 할당하지 않고 다른 효과 로딩은 계속한다. 기존 scale 0.65/0.72/0.52, 좌표·z 값 유지.
- 검방패는 해당 archetype에서만 3개 효과를 숨긴다. slash/thrust 묶음 로드·공격 효과 할당 → guard_release/charge_impact 묶음 로드·채널 할당 → guard_aura 로드·쉴드 할당 순서 유지. 누락 시 해당 애니메이션의 나머지 프레임만 중단하고 다음 애니메이션은 계속한다. 부분/빈 SpriteFrames도 기존대로 할당한다.
- 권총은 공격 효과 hidden/null/nearest 초기화 후 flame 5~6 → smoke 7~12 → dust 1~8을 모두 로드한다. 누락은 경고 후 skip. flame/smoke 중 하나라도 프레임이 있어야 공격 효과를 할당하며 dust는 별도로 판정한다. dust가 전부 누락되면 기존 channel 상태를 보존한다. hidden→frames→filter/scale/position/z/modulate 순서 유지.
- SpriteFrames 생성 수와 텍스처 조회 순서는 기존과 같다. 배치별 임시 frame-slot Array와 비어 있는 효과 판정용 animation-name 배열은 초기화 시에만 생성한다. 매 프레임 경로·그룹 스캔·노드 instantiate/free·새 캐시 없음. FPS/메모리 개선율은 측정하지 않았다.

## 검증 결과

- Godot 4.5.1 headless 격리 전후 비교 **376검사 PASS**. 실제 원문 함수와 실제 AnimatedSprite2D/SpriteFrames를 사용하며 텍스처 로더만 합성 GradientTexture2D로 대체했다.
- 12개 archetype(기존 10종+미등록+빈 값), 잘못된 진입점, 정상/전체 누락/프레임별 누락/애니메이션 단위 누락/효과 묶음 단위 누락, 복원 후 같은 노드 재설정, archetype 변경을 검사.
- Stage1 shield/channel → Stage2 → Stage3 → Stage4의 기존 초기화 순서를 rookie/비rookie ID 및 누락 여부 조합으로 비교. 전체 Hero ready나 실제 본체 외형은 실행하지 않았다.
- 로드 경로·순서·각 로드 시점의 3개 효과 상태, animation_changed/sprite_frames_changed/frame_changed 신호 순서와 당시 상태, 최종 프레임/FPS/loop/scale/offset/위치/색/rotation/z/filter/재생 상태를 비교.
- 의도한 누락 경고 내용/횟수는 before/after 각각 **212개**로 일치. 최종 smoke에서 script/runtime error 0. 정상 fixture import 오류·경고 0.
- 사용자 정의 animation/path/FPS/구간/scale의 데이터 재바인딩과 공유 metadata 불변 확인.
- 13차 기존 격리 fixture에 현재 Catalog를 연결한 회귀 **1,666검사 PASS**. 기존 before/after 원문은 그대로이며 그 함수들은 이번 변경 대상이 아니다. 실제 PNG·앵커 계산 검증을 의미하지 않는다.
- 나머지 Hero **651함수 본문**, Main/Battle 전체, 기존 Catalog 텍스트 동일 확인. Python compile 및 `git diff --check` 통과.
- 실제 PNG 표시·전체 Hero/Battle ready·실전 전투/AI·PC/Android/GPU/FPS는 미검증.

## 남은 상황

동일한 tracked runtime 351개/7개 변수 직접 nonempty 문자열 ==/!= 패턴 기준 후보는 **125 → 122곳**. 위치는 `CONTENT_SELECTOR_INVENTORY_PHASE14_20261018.json`에 기록했다. 고유 기술 조건도 포함하므로 전부 제거할 하드코딩 수나 확정 작업 수가 아니다.

다음 조사 후보는 Stage1 shield/channel 효과의 반복 설정과 상태 표시 연결이다. 고유 기술 분기, 그룹 fallback의 레지스트리 전환, 실제 플레이 검증은 각각 별도 범위로 남는다.

## 재현

```sh
python tools/build_hero_combat_effect_fixture.py /tmp/combat-effects-phase14 --baseline 390e844701ca3a56e0878a26726886ac85e217e2
godot --headless --path /tmp/combat-effects-phase14 --editor --import
godot --headless --path /tmp/combat-effects-phase14 --script res://smoke.gd
python tools/inventory_content_selectors.py --output /tmp/content-selector-inventory.json
```

fixture 생성기는 baseline의 변경 대상 외 함수와 기존 Catalog 동일성도 확인한다. 보고 JSON의 base_head는 수정 전 SHA이고 source는 working tree다.
