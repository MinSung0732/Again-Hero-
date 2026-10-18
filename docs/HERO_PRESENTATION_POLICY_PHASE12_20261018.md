# 하드코딩 정리12차: 용사 외형·전투 정보 — 2026-10-18

## 기준·범위
- 수정 전 HEAD/origin feature/stage10-astra `ce9cd56f0646bbc09563461448b3e3e80d43c231`, 최신 origin/main `6f22053f462e1176ec2ecde131d589d5491791b2`, clean 확인 후 작업. main 병합 없음.
- `_apply_profile_visual`의 콘텐츠 선택10곳과 `_refresh_hero_info_panel`의 능력 설명 선택1곳을 `hero_presentation_catalog.gd`로 이동. PNG·캐릭터 디자인·대사·기술/피해·성장/AI/밸런스 값 변경 없음.
- 첨부 프로젝트/용사 규격과 기존 코드의 프레임/정규화 정책 확인. 모든 리소스 경로·fps·순서·크기/앵커 처리·누락 시 동작은 기존 구현 기준으로 유지.

## 구조·동작 보존
- Catalog는10개 용사 외형의 기본 경로, 애니메이션 이름/접두사·count/fps/loop·필수 여부, 일부 indices, 그리기 속성, 정규화 전/후 및 재생 후 후크를 소유. Hero의 기존 STAGE1~10_FRAME_DIR 상수는 같은 경로의 Catalog 별칭이므로 다른 고유 기술 함수는 그대로 사용.
- 선택 우선순위도 데이터로 명시: 기존 상위6 archetype → ranged_rookie hero ID → 나머지3 archetype. ID/성향이 엇갈린 입력의 기존 결과까지 보존. 불명/빈 ID는 이전처럼 sprite 초기화만 수행하고 반환.
- Hero 공통 초기화기는 기존 sprite reset 후 프로필 애니메이션을 순서대로 구성. 모든 idle은 필수, Stage1은 전부 필수. 다른 용사의 일반 시퀀스는 이전처럼 실패를 무시하고 후속 애니메이션 구성을 계속함.
- Stage7 공격 `[1,2,5]`/7fps, Stage6 공격 `[1,5,2,6]`/10fps·dash_start1/dash_finish2를 데이터로 처리. 기존처럼 공격 애니메이션은 로드 전 생성하고, dash는 texture 로드 성공 후 생성. 특수 프레임 실패 경고 문구와 즉시 반환 유지.
- Stage9 z_index=-2/show_behind_parent=true → anchor cache → 정규화 → anchor, Stage8/7 정규화 후 anchor, Stage7 idle 재생 후 philosopher effect 호출 순서 보존. 정규화/앵커/효과 함수 자체는 변경 없음.
- Main은 Catalog의 능력 문구/스냅샷 key·기본값·표시 배율·포맷을 사용. rogue4줄/나머지2줄, 빈 입력/불명 archetype의 기존 원거리 설명 fallback·반올림·순서·공백을 그대로 유지. 새 용사의 설명을 임의로 추가하지 않음. 현재 스냅샷을 매번 읽고 실제 능력값은 캐시하지 않음.
- 공유 프로필·공용 empty 배열/Dictionary 참조, 초기화 때만 고정 규칙 순회. 기존처럼 초기화당 SpriteFrames1개, 같은 수의 텍스처 로드/프레임 추가. 프레임 루프·그룹/registry 스캔·노드 생성/해제 추가 없음. SpriteFrames 캐시나 렌더 정책 변경 없음. UI는 기존처럼 출력 PackedStringArray1개 생성. FPS 개선율은 측정하지 않음.

## 검증
- Godot4.5.1 headless: 실제 이전/현재 외형 owner·named sequence 함수 및 전체 전투 정보 owner를 원문 추출해 실행. 실제 AnimatedSprite2D/SpriteFrames와 현재 Catalog 사용. texture loader는2×2 합성 ImageTexture, 정규화/anchor/effect 후크와 UI 외부 서비스는 기록 어댑터.
- 정상396검사 PASS: 3개 hero ID×12개 archetype×2개 기본/override 경로, 반복 초기화·불명/빈 입력·우선순위 충돌 비교. 프로필별 프레임 파일 경로·호출 순서·프레임 개수·fps/loop·sprite 상태·후크 순서 일치.
- 추가 sanity: 서로 다른 정체성으로 같은 노드 재사용, Stage6 attack1/5/2/6 및10fps/비반복, 상위 archetype과 rookie ID의 우선순위·기본 정보 줄 수/문구, 공유 프로필 불변 확인.
- 프레임 누락748검사 PASS: 기존10개 외형 전체 로드 요청248위치에 각각 실패 주입. 필수/선택 시퀀스·공격/대시·부분 로드/중단/재초기화 상태 일치. 기존 실패 경고 메시지 순서도 before/after 각각248개로 일치. 이 경로는 의도한 경고를 포함하며 script/runtime 오류는0.
- 두 실행 모두 실제 Main 전체 정보 owner도 비교:12개 archetype×값5개×HUD/스냅샷 fallback2개, 수치 음수/0/소수/과대·누락 필드·스냅샷 갱신·증강0/일반/MAX, 나머지 능력/스탯/빌드·관측 문구/portrait 로드 요청 동일. 고유기술 실제값 판정은 테스트하지 않음.
- 합계1144검사. 변경 외 Hero652함수/Main144함수 본문 동일. 외형 reset 원문 동일·Main은 능력 블록 외 전체 본문 동일. Python compile·git diff --check 통과, 실제 추출 스크립트 및 신규 Catalog의 Godot parse/import·실행 확인.
- 실제 PNG 렌더/프레임별 시각 비교·정규화/anchor 계산/후광·카메라·전체 Hero/Battle/Main 씬·물리/AI·Windows/Android/GPU/FPS는 이번 미검증. 합성 텍스처/기록 후크의 격리 검증을 실제 게임 플레이 검증이라고 부르지 않음.

## 남은 상황
11차와 같은 tracked runtime351개/7개 변수의 nonempty 문자열 ==/!= 패턴 기준:

| 위치 | 11차 후 | 12차 후 |
| --- | ---: | ---: |
| Hero | 140 | 130 |
| Main 정보 UI | 1 | 0 |
| 합계 | 141 | 130 |

- 이번에 계획한 외형 연결10곳/정보 UI1곳 정리 완료. 위치 목록은 `CONTENT_SELECTOR_INVENTORY_PHASE12_20261018.json`.
- 남은130개는 고유 행동·피해/상태·사망/AI context, 일부 정규화/효과 연결 등 Hero에 집중. 다음은 표시/연출 연결과 고유 전투 동작을 구분해서 검토해야 함.
-130개는 재검토 위치 수이며 제거해야 할 확정 작업 수가 아님. 다른 변수명·String/get 접근자·match·in·경로/숫자 상수·Catalog 선언은 제외한 조사다. 전체 하드코딩 제거율이나 남은 확정 차수를 추정하지 않음.
- 앞서 추적한 Battle monster_type18→0·기본 투사체 source_hero_id7→0은 이 변경과 무관하게 유지. 그룹 fallback→registry는 별도 성능 범위.

## 재현
1. `python tools/build_hero_presentation_policy_fixture.py /tmp/presentation-phase12 --baseline ce9cd56f0646bbc09563461448b3e3e80d43c231`
2. Godot editor import 후 `--headless --path /tmp/presentation-phase12 --script res://smoke.gd`.
3. 동일 실행 뒤 `-- --missing-art`로 누락 테스트. 경고 로그는 별도 저장하고 before/after 메시지 순서 비교.
4. `python tools/inventory_content_selectors.py --output /tmp/content-selector-inventory.json`로 위치 목록 재생성. 기록된 JSON의 base_head는 작업 전 SHA, source는 working tree임.
