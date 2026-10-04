# 계정 저장 / 자동 로그인

## 사용 방법

1. Windows에서 카카오 또는 구글로 한 번 로그인합니다. 서버 저장 확인과 필요한 동기화 후 로비가 열립니다.
2. 진행/연구/몬스터 조각/강화/팀 편성/스킬 편성/최근 소환 내역 100회는 변경 후 4초에 업로드됩니다. 기타→계정에서 저장 상태 확인과 수동 동기화를 할 수 있습니다.
3. 게임을 다시 켜고 터치 시작하면 로딩 뒤 기존 계정의 인증을 갱신하고 서버 저장을 불러옵니다. 세션 취소/네트워크 실패 시 로그인 화면에 안내가 표시됩니다.
4. 계정 변경은 기타→계정→로그아웃. 저장 실패/충돌 시 로그아웃을 중단합니다. 충돌은 동기화 버튼으로 시작 화면에 돌아가 서버/이 기기 저장 중 하나를 선택합니다.

다른 기기에서 수정된 서버 저장을 자동으로 덮어쓰지 않습니다. 서버 선택 시 기존 로컬 묶음을 `save_bundle.json.before_cloud.bak`으로 보관합니다. 기존 UUID별 cfg도 삭제하지 않습니다. 게스트는 별도 로컬 저장이며 자동 병합하지 않습니다.

## 저장과 보안

- `user://accounts/<UUID>/save_bundle.json`: 다섯 ConfigFile의 JSON-compatible sections와 revision/dirty/serial. 임시 파일 flush 후 원자적 rename. dirty는 강제 종료/오프라인 시 다음 로그인에서 복구합니다.
- `user://windows_session.dpapi`: Windows 사용자 계정에 묶인 DPAPI 암호화 refresh token. access token은 메모리에만 둡니다. PowerShell helper는 숨김 실행되며 토큰은 인수가 아닌 UTF-8 pipe로 전달합니다. Windows 외 보안 credential 저장은 아직 없습니다.
- 서버 `account_save_snapshots`: UUID PK, revision, payload, 서버 updated_at. 인증된 본인만 select/insert/update 가능. 익명 역할의 테이블 접근 및 RPC 실행 금지. RPC는 security invoker, 빈 search_path 및 명시적인 auth.uid 필터 사용.
- `read_game_save()`는 snapshot이 없으면 기존 player_progress를 읽어 이관합니다. rollout 때 monster_collection/team_loadout은 비어 있었으며 기존 테이블 자체는 보존합니다.
- `save_game_snapshot(expected_revision,new_payload)`는 버전이 일치해야 저장합니다. 실패 응답은 업로드 성공으로 간주하지 않습니다. 업로드 도중 추가 변경되면 dirty가 유지됩니다.
- Supabase migration `20261004135929_account_save_snapshots.sql`은 실제 서버 적용 버전과 일치합니다. 기존 테이블 삭제/초기화는 하지 않았습니다.

## 검증 / 제한

`tests/cloud_save_smoke.gd`: 무작위 테스트 UUID/격리 DPAPI 파일, 재시작 복구, offline pending, revision 충돌, 서버 선택/로컬 백업, invalid payload, 토큰 암호화/복호화/갱신/삭제, 자동 로그인 refresh 및 사용자 검증 fixture. 테스트는 사람의 세션 파일을 읽거나 삭제하지 않습니다.

`tests/startup_smoke.gd`: 자동 로그인 보관을 끄고 실제 시작/게스트/준비된 로비/던전을 검사합니다. `tests/windows_oauth_smoke.gd`: 실제 loopback callback 회귀. 서버 테스트는 임시 auth 사용자 두 명을 transaction 내 생성하고 RLS/CAS를 assertion으로 확인한 후 rollback했습니다.

실계정에서 로그인→연구/편성 변경→기타의 저장 완료→재실행 후 자동 복구, 이후 같은 계정으로 다른 PC 복구는 사용자 최종 검증 대상입니다. 계정별 RLS는 소유권 보호이지 재화 치트 방지나 서버 권위형 보상 검증은 아닙니다. Android secure storage, 기기 딥링크, 게스트 import/account linking은 미구현입니다.

서버 보안 점검에서 새 저장 테이블/RPC 관련 경고는 없었으며 기존 [유출 비밀번호 보호 비활성화 경고](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)는 남아 있습니다. 현재 SNS 로그인 연결과 별개이며 이 작업에서 비밀번호 인증 정책은 바꾸지 않았습니다.
