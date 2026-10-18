# 하드코딩 정리13차: 크기 정규화·채널 효과 — 2026-10-18

## 기준·구현
- 수정 전 HEAD/origin feature/stage10-astra `3c1ffbe1321f951759a95a80e97493edaeb6d1a6`, origin/main `6f22053f462e1176ec2ecde131d589d5491791b2`, clean 및 원격 최신 확인 후 작업. main 병합 없음.
- Hero 정규화의 rookie ID 예외1곳, 방패/권총 효과 종료2곳, 광전사/연금술사 효과 초기화 guard2곳을 hero_presentation_catalog에 선언. 직접 선택5곳 제거. 효과·피해/성장/AI·PNG·대사/타이밍 변경 없음.
- 정규화 기준 경로/64×64 참조 영역·배율3·fallback108과 고정 높이 hero 집합을 Catalog로 이동. Hero의 기존 상수는 동일 값의 별칭. 여전히 opaque used_rect 높이로 나누며, ID가 rookie여도 기존 참조 이미지 조회를 먼저1회 수행. 참조가 유효한 다른 용사는 실제 참조 높이, 참조 누락/투명은108을 사용. body idle/texture/이미지/실제 영역이 없으면 기존처럼 scale을 바꾸지 않음.
- 방패 종료는 애니메이션 종류와 무관하게 visible=false/position=0, 권총은 cylinder_dust 때만 추가 modulate=WHITE, 다른 archetype/다른 권총 animation은 no-op. 속성 적용 순서 보존.
- 광전사 persistent/연금술사 channelled 규칙은 서로 다른 이벤트로 opt-in. 기존 private 진입점 이름/호출 위치 유지, 다른 archetype에 호출하면 상태/로드/프레임 생성 없이 반환.
- 광전사: visible=false/frames=null/nearest 초기화 후 madness1fps/loop, special08 필수1프레임, 누락 시 즉시 반환. 기존 좌표(0,-126)·scale0.48/z9/WHITE 유지.
- 연금술사: config channel_fps를 매 호출 판독(default8/min1), brew1~8→cast1~4 순서/누락 시 skip. frames 구성 후 stop→assign→animation/hidden/nearest→manifest offset(64,-144)/position0/scale0.5/z10/WHITE 순서 보존. 모두 누락돼도 기존처럼0프레임 animation을 할당.
- 공유 metadata를 읽는 공통 처리기 사용. profile에 선언된 속성을 직접 적용하며 신규 프레임 루프·전체 스캔·임시 Array/Dictionary·노드 생성/해제 없음. 효과 초기화당 SpriteFrames1개/기존과 같은 텍스처 조회, 정규화 시 같은 참조 조회 수. 새 캐시를 만들지 않고 동적 config/FPS는 저장하지 않음. FPS 개선율은 미측정.

## 검증
- Godot4.5.1 headless에서 수정 전/후 실제 정규화/참조 높이 함수, 두 효과 초기화/종료 함수와12차 외형 owner/helper를 원문 추출하여 실행. 실제 AnimatedSprite2D/SpriteFrames/ImageTexture/Image.get_used_rect/get_region 사용. PNG 대신 투명/불투명 영역을 가진 합성 이미지, Stage7/8/9 본체 anchor 후크는 기록 어댑터.
-1666검사 PASS. 정상 fixture parse/import/실행에 script/runtime 오류·경고0.
- 정규화384조합: ID4개×body 실제 높이0/1/36/108×참조 누락/투명/1/10/36/64×frames없음/idle없음/idle빈/idle텍스처. 실제 scale 및 참조 로드 경로/횟수 전후 동일. 독립 sanity: rookie108/36=3, 타종 참조10×3/36, rookie도 참조1회 판독 확인.
- 효과 초기화468조합과 각각 재설정 비교936검사: archetype12개, fps key누락/음수/0/0.5/1/8/12.5/숫자 문자열, 잘못된 setup 진입점, 정상/전체누락/12개 프레임 각각 누락. config를7.25로 변경해 같은 노드 재설정 시 최신 값 반영 확인.
- 실제 animation_changed/sprite_frames_changed/frame_changed 신호 순서와 당시 animation/frame/playing/position/modulate, 최종 프레임 경로/순서/fps/loop·visible/scale/offset/rotation/z/filter/speed/playing 상태 일치. 재사용 시작 상태는 재생 중/frame2/색·좌표·크기가 있는 상태.
- 종료 처리192조합: archetype12×animation4×위치2×색2, 방패·권총 조건 및 다른 archetype no-op 확인.
- 외형 owner144조합: archetype12×ID3×참조 누락/유효×기본/override dir. 이번에는 실제 정규화와 실제 연금술사 후크·광전사 setup을 연결하여12차의 경로/초기화와 함께 실행. 중간 stage1~4 효과 및 Hero 전체 ready는 실행하지 않음.
- 독립 sanity: 연금술사12프레임·manifest좌표/scale·FPS최소1, custom animation/fps/파일 패턴·구간·좌표/크기 재바인딩 적용, 공유 규칙 불변 확인.
- 나머지 Hero651함수 본문, Main/Battle 전체 파일, 이전 presentation 데이터/함수는 동일. Python compile·git diff --check 통과. 고유 전투 로직/보상·물리/캐시/풀 변경 없음.
- 실제 PNG 표시·원본 이미지 경계·전체 Hero/Battle ready·전투·AI·카메라/실제 후광/anchor계산·PC/Android/GPU/FPS는 이번 미검증. 합성 이미지의 실제 크기 계산/효과 상태 검증을 전체 게임/실기 검증이라고 부르지 않음.

## 남은 상황
같은 tracked runtime351개/7개 변수 직접 nonempty 문자열 ==/!= 패턴:

| 위치 | 12차 후 | 13차 후 |
| --- | ---: | ---: |
| Hero | 130 | 125 |
| Main | 0 | 0 |

- 이번5곳 정리. 현재 위치 목록은 CONTENT_SELECTOR_INVENTORY_PHASE13_20261018.json.125는 재검토 위치 수이며 전부 제거할 작업이 아님.
- 다음 검토 영역은 다른 효과/애니메이션 연결·상태 표시, 이후 고유 공격/이동·피해/사망/AI 조건의 반복 바인딩. 고유 기술에 필요한 분기는 유지해야 하며 다음 차수의 범위는 조사 후 정함.
- 이 도구는 다른 변수명·String/get·match·in·수치/경로 상수·Catalog 선언을 집계하지 않음. 전역 제거율/남은 확정 차수는 제시하지 않음. 별도 성능 작업인 그룹 fallback→registry와 전체게임/실기 확인도 남아 있음.

## 재현
1. `python tools/build_hero_effect_policy_fixture.py /tmp/effects-phase13 --baseline 3c1ffbe1321f951759a95a80e97493edaeb6d1a6`
2. Godot editor import 후 `--headless --path /tmp/effects-phase13 --script res://smoke.gd`.
3. `python tools/inventory_content_selectors.py --output /tmp/content-selector-inventory.json`로 현재 위치 재생성. 기록 JSON의 base_head는 수정 전 SHA이며 source는 working tree.
