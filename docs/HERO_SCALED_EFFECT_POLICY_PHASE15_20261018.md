# 하드코딩 정리 15차: 견습마도사 쉴드·채널 효과

## 기준과 구현

- 시작 HEAD 및 원격 feature/stage10-astra: `d5f5044945daa68bdd804d629812033f7c2e5c60`. 원격 main: `6f22053f462e1176ec2ecde131d589d5491791b2`. 시작 작업 트리 clean, 작업 브랜치 feature/stage10-astra. main 병합 없음.
- `_apply_stage1_shield_visual` 및 `_apply_stage1_channel_visual`의 경로·프레임 구간·애니메이션/FPS/loop·노드·대상 ID·초기화 순서·크기 계산 정책과 경고를 `hero_presentation_catalog.SCALED_EFFECT_PROFILES`로 이동했다. 기존 진입점과 ready 호출 순서는 유지한다.
- Hero의 효과 경로/프레임 수/크기 관련 상수 7개는 Catalog로 이동했고 직접 hero_id 비교 2곳을 제거했다. 공통 초기화기는 해당 데이터로 처리하며 콘텐츠별 ID/효과 이름을 판별하지 않는다.
- 쉴드는 대상 ID 판정 전에 hidden → frames=null → nearest 순서로 항상 초기화한다. 대상이 아니면 로딩하지 않는다. 정상 프레임 6개를 할당한 뒤 고정 canvas 폭 512에 대한 목표 180의 비율로 scale을 설정한다. 로드한 텍스처 크기는 이 배율에 영향을 주지 않는다.
- 채널은 대상 ID가 맞을 때만 초기화한다. 다른 용사의 기존 채널 프레임/재생/속성은 보존한다. 각 프레임을 로드할 때 실제 Texture2D 크기의 x/y 최대값을 누적하고, 전체 프레임의 최대 extent에 대해 목표 300의 비율로 scale을 계산한다. 모든 크기가 0이면 기존 경고 후 frames=null로 종료한다.
- 두 효과 모두 첫 누락 프레임에서 기존 경고 → frames=null → return 순서를 유지한다. 실패 시 이전 scale 등 나머지 속성은 보존한다. 성공 시에도 frames 할당 신호가 scale 설정보다 먼저 발생한다.
- 초기화당 SpriteFrames 생성 1회, 동일한 프레임 경로·조회 순서를 유지한다. 공유 metadata를 읽으며 매 프레임 작업, 그룹 조회, 임시 배열/Dictionary, 캐시, 노드 생성/해제는 추가하지 않는다. FPS/메모리 개선율은 측정하지 않았다.
- 본체/앵커·전투/AI·스탯/보상·PNG·오디오는 변경하지 않는다.

## 검증

- Godot 4.5.1 headless 격리 전후 **1,154검사 PASS**. 수정 전/후 실제 함수 원문과 실제 AnimatedSprite2D/SpriteFrames/ImageTexture를 사용한다. 정상 텍스처는 PNG 대신 합성 ImageTexture이며, 크기 0 경계만 Texture2D 어댑터를 사용한다.
- ID 4종, 4개 크기(0, 1×1, 64×96, 512×256), 기존 재생 중/frames=null 상태, 정상/전체 누락/각 6개 프레임 누락을 비교한다. 실패/성공 뒤 같은 노드에서 크기를 바꿔 재설정하는 경계도 포함한다.
- 각 프레임 위치에 x 또는 y가 최대인 다른 크기의 프레임을 배치해 마지막 프레임을 포함한 전체 최대 extent 사용을 확인했다. 독립 기대값: 쉴드 180/512, 채널 300/20=15 및 300/240=1.25.
- Stage1 shield/channel → Stage2 → Stage3 → Stage4 순서로 12개 archetype × ID4종 × 누락 여부2종의 96개 조합을 비교했다. 이는 효과 초기화 부분만 실행한 것이며 전체 Hero ready나 실제 본체 초기화 검증은 아니다.
- 로드 경로·조회 순서·각 로드 시점의 세 효과 상태, animation_changed/sprite_frames_changed/frame_changed 신호 순서와 당시 상태, 최종 프레임/FPS/loop·scale/offset/위치/색/rotation/z/filter/재생 상태가 일치한다.
- 다른 ID의 쉴드 무조건 초기화/채널 무변경, 임의 ID·대상 노드·animation/path/구간/FPS/loop·고정 크기 정책의 데이터 재바인딩, 공유 metadata 불변을 독립 확인했다.
- 동일 fixture에서 기존 14차 smoke를 실행해 **376검사 PASS**. 이번 시작점의 기존 도적·검방패·권총 초기화와 15차 변경 후 초기화를 비교한 회귀다.
- 총 **1,530검사 PASS**. 의도한 누락/무효 크기 경고는 15차 before/after 각각 234개, 14차 회귀 각각 212개로 내용과 횟수 일치. script/runtime 오류 0, 정상 fixture import 오류·경고 0.
- 나머지 Hero **654함수**, 해당 상수를 제외한 다른 선언, Main/Battle 전체 파일, 기존 Catalog 텍스트가 동일함을 검사했다. Python compile·`git diff --check` 통과.
- 실제 PNG/원본 경계·전체 Hero/Battle ready·실제 전투/AI·PC/Android/GPU/FPS는 미검증이다.

## 남은 상황

동일한 tracked runtime 351개/7개 변수 직접 nonempty 문자열 ==/!= 패턴 기준 후보는 **122 → 120곳**. 위치는 `CONTENT_SELECTOR_INVENTORY_PHASE15_20261018.json`에 기록했다. 고유 기술 조건도 포함하므로 남은 제거 작업 수나 전역 하드코딩 점수가 아니다.

다음은 상태 표시·애니메이션 연결의 반복 설정을 조사한다. 고유 기술 조건, 그룹 fallback의 레지스트리 전환 및 실제 플레이 검증은 별도 범위다. 전체 종료 차수는 남은 조건 분류 전에 확정하지 않는다.

## 재현

```sh
python tools/build_hero_scaled_effect_fixture.py /tmp/scaled-effects-phase15 --baseline d5f5044945daa68bdd804d629812033f7c2e5c60
godot --headless --path /tmp/scaled-effects-phase15 --editor --import
godot --headless --path /tmp/scaled-effects-phase15 --script res://smoke.gd
cp tests/hero_combat_effect_policy_smoke.gd /tmp/scaled-effects-phase15/combat_regression.gd
godot --headless --path /tmp/scaled-effects-phase15 --script res://combat_regression.gd
python tools/inventory_content_selectors.py --output /tmp/content-selector-inventory.json
```

fixture 생성기는 baseline의 변경 대상 외 함수·선언 및 기존 Catalog 동일성도 확인한다. JSON의 base_head는 수정 전 SHA이며 source는 working tree다.
