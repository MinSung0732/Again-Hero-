# 클라우드 자동 동기화·재접속·로딩 화면 — 2026-10-17

## 적용한 규칙

| 상황 | 동작 |
| --- | --- |
| Google/카카오 계정 로그인 | 서버 snapshot을 자동으로 설치. 로컬/서버 선택창 제거 |
| 기존 계정 로컬 전용 기록 | 서버 기록이 있으면 서버 우선. 최초 교체 전 `.before_cloud.bak`, 최근 미전송 교체 전 `.unsent_before_cloud.bak` 보존. 재화 최댓값 병합은 하지 않음 |
| 서버 snapshot이 없는 계정 | 검증한 같은 UUID의 계정 캐시만 최초 업로드. 게스트는 명시적 계정 연동 RPC만 이전 |
| 정상 저장 | 로컬 변경과 pending 요청을 같은 atomic bundle에 기록. 전송 전 같은 동작의 연속 저장을 합치고, 첫 전송 전에 `sent` 경계를 기록해 이후 요청 내용을 고정 |
| 응답만 유실 | 같은 operation UUID/내용으로 재시도. 서버 receipt와 revision CAS로 중복 반영 방지. 앱 재시작 시에도 pending 복구 |
| 다른 기기의 새 로그인 | 마지막으로 성공한 claim이 쓰기 권한 보유. 이전 nonce의 재시도/heartbeat/저장/프로필/탈퇴 차단. 로그인 화면으로 돌아가야 새 claim 가능 |
| 연결 장애 | “서버에 연결 중입니다”. 1~15초 backoff, 15초 heartbeat. 일시적 refresh 실패 시 토큰을 삭제하지 않고 재시도 |
| 짧은 정상 저장 | 입력 중복만 막고 전투는 계속. 0.8초 이상 대기하면 표시와 함께 전투 정지. 확인된 장애/인증 확인은 즉시 정지 |
| 정지 중 | 독/지연 공격/전투·보스 시간 중단. 마왕 모드 상태 시계도 대기 시간 제외. 네트워크 정지 사유만 해제하므로 설정·증강 정지 유지 |
| 앱 백그라운드/복귀 | 백그라운드 진입 시 정지, 복귀 시 서버 확인 후 재개 |
| 충돌 복구 | 서버 기록 설치 후 로비를 새로 준비해 메모리의 이전 재화/편성도 교체. 준비 중 생성된 저장까지 flush 후 입력 해제 |
| 게스트/로컬 테스트 | 기존 기기 전용 별도 namespace 유지. 사운드·조작 설정도 기기 전용 |

클라우드를 기준으로 동기화하지만 전투를 매 프레임 서버에서 실행하거나 매번 HTTP로 재화를 조회하지 않는다. 이 변경은 snapshot 동기화의 권위·기기 경합·재시도 안전성을 다룬다. **일반 뽑기 RNG·전투 보상·소비량 계산 자체를 모두 서버 명령/치트 검증으로 이전한 것은 아니다.** 기존 튜토리얼 보상은 서버 ledger를 유지한다. 연결 대기 정지는 현재 기기의 전투에 적용하며, 다른 이용자의 원격 온라인 서버 시계를 멈추는 기능은 아니다.

## 에셋·UI

- `assets/art/UI/cloud_loading/castle_portal.png`: 시작 준비/화면 전환 배경.
- `assets/art/UI/cloud_loading/connection_archive.png`: 재접속/인증 만료 배경.
- image_gen의 새 이미지 생성 2회. 원본 PNG를 그대로 적용했고 생성 프롬프트·해시·크기는 같은 폴더의 `manifest.json`에 기록했다. Godot lossless import, nearest, mipmaps OFF. 재샘플링·감색·런타임 Base64 없음.
- 재접속은 가짜 진행률 대신 8개 도트의 순환 표시. 화면 전환은 기존 실제 로딩 진행률을 유지.
- 로그인 복귀 시 이전 비동기 화면 전환을 세대 번호로 취소. 해제된 로비의 상태 콜백도 연결 해제.

## 서버 반영

기존 Again-Hero Supabase 프로젝트에 다음 두 additive migration을 적용했다. 기존 플레이어 저장을 조회하거나 덮어쓰지 않았다.

- `supabase/migrations/20261017072109_cloud_canonical_sessions.sql`
- `supabase/migrations/20261017074836_cloud_mutation_fences.sql`

새 테이블은 비공개 schema, RLS 활성화, 클라이언트 테이블 권한 없음. public invoker RPC에서만 비공개 definer 연산을 호출한다. auth.uid, 실제 auth.sessions 존재, nonce와 Auth session의 일치 여부를 검사한다. claim/쓰기의 계정 잠금 순서를 통일하고 기존 직접 REST 쓰기도 statement trigger로 보호한다. receipt는 30일 후 정리되며 오래된 재시도도 revision CAS를 통과해야 한다. 이전 claim nonce는 자동 재접속으로 권한을 되찾지 못한다.

서버 테스트는 매번 임의 fixture UUID를 생성한 BEGIN/ROLLBACK 트랜잭션으로 실행했다. 실제 이용자 payload/토큰을 읽지 않았다. 26검사 통과: claim, 최초 저장, 동일 요청 재전송, ID 재사용 거부, 잃어버린 ack, CAS, 튜토리얼 단일 보상, 다른 기기 takeover, 이전 claim 재시도, 프로필/탈퇴/직접 저장 우회 차단, 취소된 Auth session, anon/테이블 권한.

Advisor: performance 0건. private 테이블의 RLS/no-policy INFO는 클라이언트 전면 거부를 위한 의도적 구성이다([설명](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy)). 기존 Auth 비밀번호 유출 보호 비활성 WARN은 이번 변경으로 추가된 항목이 아니며 설정을 바꾸지 않았다([설명](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)). Supabase 공식 세션 문서와 2026-10 changelog를 확인했다.

## 검증

Godot 4.5.1 headless에서 실제 네트워크/저장/전투/전환 스크립트를 실행했다. 네트워크 전송·vault는 별도 fixture, 없는 기존 그림/소리는 명시적 대체 리소스다. 신규 PNG 2장은 실제 생성 파일이다.

| 검사 | 결과 |
| --- | --- |
| cloud_save_smoke | PASS — 파일 5종, pending 재시작, 응답 유실, 자동 서버 복구, 백업, 이전 기기, 자동 로그인 identity |
| cloud_connection_smoke | 23/23 — 짧은 저장 무정지, UI 표시, 용사/마왕 시계·독·Timer·지연 공격, 중첩 정지, 새 PNG |
| cloud_auth_recovery_smoke | 7/7 — 오프라인 만료 토큰 보존, 복구/회전, 실제 만료 상태 유지 |
| cloud_transition_cancel_smoke | 5/5 — 취소 후 옛 destination/비동기 준비 차단 |
| cloud_profile_retry_smoke | 6/6 — 프로필 요청 자동 재시도·저장과 직렬화·지갑 보존 |
| cloud_tutorial_reward_smoke | 9/9 — 오프라인 미지급, 서버 지급 후 응답 유실, canonical 복구, 중복 미지급 |
| account_transition_smoke | 33/33 |
| guest_link_smoke | 28/28 |
| hero_pause_resume_smoke | 83/83 |
| account_withdrawal_smoke | 75/75 — 실제 로직, transport/vault/관계 없는 guest UI는 fixture |
| mobile_entry_memory_smoke | 660/660 — 실제 전환/해제 로직, destination/warmup은 명시적 fixture |
| PostgreSQL cloud_canonical_sessions.sql | 26/26 — 실제 서버 DB, fixture만 사용 후 ROLLBACK |

최종 대상 검사에서 SCRIPT ERROR/ERROR 없음, editor import와 git diff --check 통과. 전체 프로젝트의 기존 아트가 없는 checkout이므로 전체 화면/실제 GPU 및 Android 실기는 검증하지 않았다. 전체 `tutorial_smoke` UI 시도는 누락된 기존 UI 디렉터리/연출에서 실패해 전체 튜토리얼 통과로 집계하지 않았다. 해당 보상/저장 경로는 위의 별도 실제 로직·서버 검사로 검증했다.

실기 후속: Google/카카오 로그인, AndroidKeyStore/Windows DPAPI, 비행기 모드·Wi-Fi/모바일 전환, 백그라운드 복귀, 두 실제 기기 takeover, 전체 실제 아트로 튜토리얼/로딩 화면 확인. APK 제작·배포는 이번 작업에 포함하지 않았다.
