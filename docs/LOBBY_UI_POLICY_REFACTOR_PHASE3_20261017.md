# 하드코딩 정리 3차: 로비 메뉴·설정·도구함 정책 — 2026-10-17

## 기준·범위
- feature/stage10-astra 최신 `6e607c879315dd1b76ae895bb942d88bb0af6c34`, origin/main `10c9805842d745412ffe9b45e822896001ef27cb` 확인 후 clean 별도 worktree. main 병합 없음.
- 기타 메뉴6개/설정 탭5개/게임 옵션2개/사이드 도구함 표시 정책. 메뉴 순서·제목·기능·노출 조건·저장 경로/키·해금 조건·전투/보상/서버 유지.

## 변경
- lobby_ui_policy_catalog에 기타 메뉴 순서/문구·핸들러/대상·노출 predicate, 하위 View/뒤로가기 높이, 설정 탭/기존 노드 바인딩·계정 헤더, 옵션 문구/기본값·용사 강제 설정을 모음.
- 메뉴 활성 여부는 등록된 Callable 유효성으로 판단, 같은 실행 목록을 반복하지 않음. 메서드가 없는 항목은 비활성화, 미등록 노출 predicate는 false. 연습전투는 기존 LocalTestMode.is_practice_allowed를 호출하며 로비 진입 동작도 기존 메서드 유지.
- show_profile/show_hero_codex/show_demon_codex 공개 호출은 유지하고 공용 View 전환으로 연결. 대상 View를 다시 hide/show하지 않고 다른 View만 닫음. 메뉴/설정 복귀에서도 공통 hide 경로 사용.
- sound/account는 기존 버튼/페이지/신호 재사용. 새 탭만 생성/연결. 탭 위치 찾기의 반복 TABS.find 대신 한 번의 순서 인덱스로 배치.
- 카메라 옵션의 용사 모드 강제 ON은 해당 옵션 metadata. 강제 상태에서는 저장을 거절해 마왕 모드에서 저장한 OFF 값을 보존. 다른 옵션 편집은 유지.
- lobby_tool_catalog로 기존 rail 크기/간격/높이·직접 표시 한도·좌우 제목·기본 안내/닫기 문구 이동. 기존 클래스 상수 alias/알림 registry/overflow 재사용/권한 gate 유지.

## 검증
- Godot4.5.1 headless 로비88검사 PASS: 실제 Settings 메서드/버튼 신호·초기6메뉴5탭 순서/문구·기존 sound/account 노드 및 신호1회 재사용·연습 노출/동작·3종 하위 View 상호 숨김/복귀/뒤로가기 높이·설정 탭/헤더·옵션 저장/용사 강제·마왕 원래 설정 복원.
- 실제 ToolTrays 기본 좌3/우1, 좌우 더보기 제목/기본 안내,100도구에서 직접3개/더보기100개, 권한 gate/1회 callback, 같은 더보기 controls 재사용/알림 집계/host hide 시 창 닫기 통과.
- 기존 defaults28+성별17+이름132+RPC10+실제 HTTP/캐시34=221검사도 PASS. 총309검사 및 키보드 레이아웃 PLAYER_PROLOGUE_KEYBOARD_SMOKE_OK.
- git diff --check 및 최종 editor import/parse 오류0. Catalog 메뉴/탭 배열과 옵션 문구·기본값은 git HEAD 원문을 파싱해 동등성 확인. runtime의 콘텐츠별 메뉴 연결 분기/카메라 키 분기 제거, 새 _process/_physics_process 없음.
- fixture는 실제 Settings/ToolTrays 코드와 게임 옵션 저장을 실행하며 로비 host·코덱스 View·계정/알림 sync·그림은 가벼운 대역. 전체 Lobby.tscn/GPU·실제PC/Android 터치/스크롤·실제 코덱스/서버 계정 통합은 미검증. FPS 개선율 미측정. 전투/해금/DB 코드 수정 없음.

## 재현
`python tools/build_cloud_rpc_fixture.py /tmp/lobby-ui-policy-fixture` 후 Godot editor import. `tests/lobby_ui_policy_smoke.gd` 및 profile_defaults/profile_gender/nickname_input/nickname_rpc_retry/cloud_rpc_wire/player_prologue_keyboard smoke를 순차 --script 실행.

새 메뉴는 이 Catalog의 순서와 action 정보를 등록하고 해당 기능의 기존 메서드를 연결. 하위 화면은 OTHER_VIEWS의 property/뒤로가기 높이로 관리. 다음4차 전투 콘텐츠 분기/반복 조회 감사는 별도 범위.
