# 시작 / 로딩 / 로그인 화면

앱 기본 시작 씬은 `src/startup/Startup.tscn`입니다.

1. 터치 시작: 전체 화면 터치 또는 시작 버튼/키보드로 한 번만 시작합니다.
2. 리소스 준비: 앱에 포함된 `StartupCatalog.CORE_RESOURCES` 파일 존재와 실제 로딩을 확인합니다. 다운로드/용량/통신 속도를 가짜로 표시하지 않습니다.
3. 로비 로딩: `ResourceLoader.load_threaded_request()`로 Lobby PackedScene과 참조 리소스를 미리 로드합니다. 화면의 진행률은 실제 로더 진행률입니다. 런타임 raw PNG 생성이나 `_ready()`의 모든 비용을 없애는 것은 아닙니다.
4. 로그인 선택: 카카오/구글은 준비 안내만 표시합니다. 게스트는 현재 기기의 기존 로컬 저장 데이터로 로비에 진입합니다.

준비 완료 표시를 읽을 수 있는 짧은 시간 외에는 별도 가짜 진행 타이머가 없습니다. 로딩 실패는 재시도를 제공하고, 중복 시작/게스트 진입/씬 전환을 막습니다. 던전 입장과 로비 복귀에서도 `SceneTransition`이 같은 야영지 로딩 UI를 사용하며 새 씬 초기화 뒤 두 프레임까지 화면을 덮습니다.

## 나중에 실제 인증을 연결할 경계

- `LoginGateway.begin_login(provider)`와 `login_requested`가 인증 어댑터 진입점입니다. 현재 네트워크 요청, OAuth 토큰, 가짜 계정 ID는 생성하지 않습니다.
- 검증된 실제 세션을 얻고 올바른 계정의 저장 데이터를 선택/동기화한 **뒤에만** `authenticated`를 발생시켜야 합니다.
- `local_guest_active`는 이번 실행의 로컬 플레이 상태이며 Supabase 익명 사용자와 다릅니다. 현재 데이터 파일이나 계정 분리 규칙은 변경하지 않았습니다.
- 실제 익명 계정 도입 시 기존 로컬 데이터의 가져오기 여부, 소셜 계정 연결/충돌 정책, 세션 안전 저장, Android 딥링크, 재인증/로그아웃을 별도로 구현해야 합니다.
- 기존 `src/network/supabase_client.gd`와 공개 설정은 변경하지 않았습니다. 서버 복구 전에는 이를 호출하지 않습니다. Client Secret과 service_role/secret 키를 앱이나 GitHub에 넣지 않습니다.
- 실다운로드가 필요해지면 버전 있는 manifest, 파일 검증/서명, 재시작/실패 복구를 구현한 후 현재 리소스 준비 단계를 대체합니다.

## 검증

`godot --headless --path . --script res://tests/startup_smoke.gd`

실제 렌더 캡처는 headless를 제외하고 실행하며 뒤에
`-- --capture-dir=<이미 존재하는 절대 폴더>`를 전달합니다.
인증 성공 검증은 아직 불가능합니다. 모바일 실기기/내보낸 APK도 별도 확인해야 합니다.
