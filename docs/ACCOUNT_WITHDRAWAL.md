# 계정 탈퇴 · 30일 보관

설정 → 계정 → 계정 탈퇴 → 확인. 일반 로그인 계정만 사용할 수 있다. 게스트/로컬 테스트/첫 가입 테스트는 제외한다. 저장 충돌이나 동기화 실패는 먼저 해결한다.

## 서버 계약

- `public.request_account_withdrawal()`은 인자를 받지 않는다. 서버의 `auth.uid()`와 실제 `auth.sessions`를 확인하고 자신의 계정만 처리한다.
- `account_private.withdrawals`에 비활성 계정의 UUID, 서버 요청 시각, 삭제 가능 시각을 기록한다. 원래 계정/게임 테이블을 옮기거나 복사하거나 즉시 삭제하지 않는다.
- 요청, 로그인 차단(`auth.users.banned_until`), 세션/refresh token 취소를 하나의 트랜잭션으로 처리한다. Auth 사용자/소셜 identity와 7개 게임 테이블은 30일 동안 보관한다.
- 보관 기간은 서버 시각 기준 정확히 720시간. 반복 요청은 기존 삭제 시각을 유지한다. 로그인으로 탈퇴가 취소되거나 계정이 재활성화되지 않는다. 별도의 복구 기능은 제공하지 않는다.
- 7개 게임 테이블에 기존 소유권 정책과 함께 **restrictive** 활성 계정 정책을 적용한다. 만료 전 JWT로 직접 REST/RPC 요청을 해도 읽기/쓰기/삭제를 차단한다. 사용자 메타데이터나 클라이언트 시각은 권한 판단에 쓰지 않는다.
- 활성 확인은 사용자 PK와 탈퇴 PK 조회이며 RLS는 `(select ...)`를 사용해 요청 내 결과를 재사용한다. 신규 계정 테이블/RPC를 추가할 때도 이 정책을 연결해야 한다. `SECURITY DEFINER` 게임 RPC가 추가되면 내부에 활성 계정 검사를 넣어야 한다.

## 예약 삭제

Supabase 프로젝트 `xdmqpsyhtnyzzdhgvfep`에 마이그레이션 2개를 적용했다. `pg_cron`의 `purge-withdrawn-accounts`는 10분마다 `account_private.purge_expired_withdrawals()`를 실행한다.

만료 계정만 삭제 시각 순으로 최대 500개 처리한다. 트랜잭션 advisory lock/행 잠금으로 중복 실행을 막는다. `auth.users` 삭제 시 외래키 CASCADE로 현재 7개 게임 테이블과 identity/세션/탈퇴 기록이 함께 삭제된다. 삭제는 **30일이 지난 후 다음 예약 실행**에 수행되므로 정상 처리에서 최대 약 10분 늦을 수 있고, 실패/대량 적체 시 지연될 수 있다. 클라이언트 실행이나 접속 여부에 의존하지 않는다.

현재 Storage 객체는 0개다. 향후 사용자 업로드가 생기면 Storage API로 바이너리를 먼저 삭제하는 서버 작업을 추가해야 한다. 현재 purge는 Storage 소유 계정을 건너뛰므로 파일의 DB 메타데이터만 지워 고아 파일을 만들지 않는다. Storage 사용을 시작하기 전에 이 경로와 소유자 조회 인덱스를 검토해야 한다.

운영 확인:

```sql
select requested_at, delete_after from account_private.withdrawals order by delete_after;
select jobname, schedule, active from cron.job where jobname = 'purge-withdrawn-accounts';
select status, return_message, start_time from cron.job_run_details
where jobid = (select jobid from cron.job where jobname = 'purge-withdrawn-accounts')
order by start_time desc limit 10;
```

비활성 테이블은 클라이언트에서 조회/수정할 수 없다. purge 실행 권한도 클라이언트에는 없다. 함수의 search_path를 비우고 PUBLIC/anon 기본 실행 권한을 회수한다. service-role 키는 게임에 추가하지 않는다.

## 클라이언트

- 기존 계정 탈퇴 준비 중 버튼을 실제 확인창에 연결한다. 확인 전에는 서버 요청을 보내지 않는다.
- 현재 진행 저장 후 기존 snapshot/tutorial 작업과 직렬화하여 탈퇴 요청한다. 중복 클릭/계정 변경/늦은 OAuth 응답을 막는다.
- 응답이 유실되면 lifecycle RPC로 서버의 비활성 상태를 확인한다. 확인 실패 시 성공으로 처리하지 않는다.
- 성공하면 자동 로그인 설정과 관계없이 보안 vault, 메모리 토큰, 타이머와 클라우드를 정리하고 시작 화면으로 돌아간다. 기존 logout의 저장 절차를 다시 호출하지 않는다.
- 로그인 시 활성 상태를 먼저 확인한다. 다른 기기의 저장 요청이 거절된 경우에도 비활성 상태를 확인해 세션을 정리한다. 세션 generation으로 이전 계정 응답을 무시한다.
- 기기에 보관된 과거 계정 진행 파일은 서버 삭제의 대상이 아니며, 로그아웃된 저장 scope에서 사용하지 않는다. OS 앱 데이터 삭제로 제거할 수 있다.

## 도감 5초월 배너

6종 모두 `몬스터 해금 && 초월 단계 >= 5`를 충족해야 볼 수 있다. 미해금은 픽셀 자물쇠 아이콘/잠김 문구/비활성 버튼으로 표시한다. 직접 preview 호출도 최신 계정 상태를 다시 검사하고 이미지 로드/캐시 전 차단한다. 기존 일반 일러스트/배너 미리보기 규칙은 유지한다. 자물쇠 텍스처는 한 번 생성해 재사용한다.

## 검증·적용

- `tests/account_withdrawal.sql`: 실제 서버의 임의 UUID 테스트 계정에만 적용하고 전체 ROLLBACK. 보관/정확한 30일/동일 deadline/세션 취소/이전 JWT 접근/익명 및 purge 권한/만료 후 CASCADE 검증. 실제 사용자 탈퇴는 실행하지 않았다.
- `tests/account_withdrawal_smoke.gd`: Godot 4.5.1 headless. 실제 전체 LoginGateway/CloudStore 로직을 네트워크·vault·scope fixture로 실행하며, 실제 확인창 생성 구간과 도감 guard/preview 함수를 실행한다. 75검사 PASS. UI 확인/취소, 실패/응답 유실/중복 클릭/일반 로그인/다른 기기 비활성/6종 단계별 잠금/열기/콜백 정리를 포함한다.
- 예약 작업 활성 및 실행 `succeeded` 확인. Supabase performance advisor 0건. Security advisor: private 테이블의 의도적인 정책 없음 INFO, 기존 유출 비밀번호 보호 비활성 WARN. 이번 작업에서 Auth 전체 설정을 변경하지 않았다.
- gdparse 및 git diff --check 통과. 실제 PC 화면·Android 실기기·실제 소셜 로그인/보안 vault·30일 실시간 경과·스토어 export는 이번에 검증하지 않았다.

클라이언트는 `feature/stage10-astra`를 pull한다. 서버 마이그레이션은 이미 적용됐으므로 사용자 기기에서 별도 SQL을 실행할 필요가 없다.

롤백은 해당 Git 커밋의 클라이언트 변경을 revert한다. 서버의 비활성 접근 차단과 이미 접수된 30일 삭제 예약은 유지하여 기존 탈퇴 약속을 지킨다. 삭제된 계정은 Git revert로 복구되지 않는다. 서버 수정이 필요하면 후속 마이그레이션으로 수정하고 기존 기록/삭제 기한을 보존한다. 운영 계정을 테스트용으로 탈퇴하거나 삭제 기한을 앞당기지 않는다.

공식 참고: [사용자 관리](https://supabase.com/docs/guides/auth/managing-user-data), [사용자 세션](https://supabase.com/docs/guides/auth/sessions), [Cron](https://supabase.com/docs/guides/cron/quickstart). 작업 전 최신 changelog.md를 확인했다.
