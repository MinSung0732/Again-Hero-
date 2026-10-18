# 하드코딩 정리 2차: 성별·초상화·프로필 기본값 — 2026-10-17

## 기준과 범위
- feature/stage10-astra 최신 `2b21a300502e264afa618ee3de17aa8b7ca38980`에서 별도 clean worktree. origin/main `10c9805842d745412ffe9b45e822896001ef27cb` 확인. main 병합 없음.
- 성별 ID/표시명/기본값·기본 초상화·프로필 초기값과 저장 키의 반복을 정리. DB/API/계정 변경권 정책·전투/대사/프롤로그 타이밍 변경 없음.

## 데이터 책임
- profile_gender_catalog: 기존 기본 성별 male, 선택지/표시명/유효성, 프롤로그 선택 버튼 배치. UI에서 male/female 별 분기를 반복하지 않고 선택지를 순회.
- demon_appearance_catalog: 기본 초상화 경로와 Texture preload 의존성·외형의 avatar/dialogue 연결. player_profile.PORTRAITS는 기존 공개 API를 alias로 유지. 프롤로그와 성별 변경창도 같은 Texture 참조.
- player_profile_catalog: 저장 파일/섹션/키, 최초 프로필 생성과 게스트 플래그. 매번 독립된 Dictionary를 반환하고 알 수 없는 필드와 저장 성별을 유지. 누락 성별만 기존 기본값 적용, 잘못된 서버 성별은 기존처럼 거절.
- Profile→AppearanceStore→Profile 순환 대신 양쪽이 순수 Data를 참조. 기존 unused gender 인자를 optional로 유지해 호출 호환성을 보존하며 profile.appearance_id에서 불필요한 프로필 선조회 한 번 제거.
- authored StageIntroCutscene.tscn의 기본 Texture 리소스 참조는 유지. 실제 대화는 기존 Profile.portrait_path 경로로 선택. 파일/아트·애니메이션/대사 내용 변경 없음.

## 검증
- Godot4.5.1 격리 headless: 새 defaults28 + 성별17 + 한글/프로필132 + 닉네임RPC10 + 실제 HTTP/저장복원34 = 221검사 PASS. 모바일 키보드 레이아웃 PLAYER_PROLOGUE_KEYBOARD_SMOKE_OK.
- defaults28: 기존4필드 기본값/독립 복사·게스트 미지 필드/무변경권·누락/잘못된 성별 구분·기존1글자 계정/각 성별 외형·실제 프롤로그 버튼 클릭/좌표/초상화·무쓰기 조회·통화 유지·JSON 캐시 재시작/독립 변경권 보존. 실제 lobby_settings_view도 autoload 준비 후 로드/컴파일 확인.
- 실제 export-pack PCK 실행: 원본 PNG 파일 없이 import된 male/female Texture 두 종 ResourceLoader/상수 preload/경로2검사 PASS. 그림 내용은 placeholder이며 원본 게임 아트/GPU 시각 검증은 아님.
- 정적: git diff --check, 변경한 runtime5파일의 male/female/초상화 경로 literal 제거, 프롤로그 _process 본문 byte-for-byte 유지, 최종 import/parse 오류0. 새 매 프레임 처리/배열 생성·전투 핫패스 변경 없음. FPS 개선율 미측정.
- fixture closure는 Catalog가 소유한 PNG 경로를 따라가도록 갱신. 인증/그림은 fixture이며 실제 Windows/Android IME/OAuth/터치·전체 화면/계정간 기기 검증은 미실행. 변경권 서버/DB 수정 없음.

## 재현
`python tools/build_cloud_rpc_fixture.py /tmp/profile-defaults-fixture` 후 Godot editor import. 해당 fixture에서 `profile_defaults_smoke.gd`, `profile_gender_smoke.gd`, `nickname_input_smoke.gd`, `nickname_rpc_retry_smoke.gd`, `cloud_rpc_wire_smoke.gd`, `player_prologue_keyboard_smoke.gd`를 순차 --script 실행.

다음3차는 로비 콘텐츠 분기/UI 정책이며 이번 작업에 포함하지 않음.
