# 마왕 이름·IME·계정 연동 정책

기준 브랜치 `feature/stage10-astra`, 수정 전 `b74481dcbea0e618bdc5211cdfba6dcf766843f0`, main `10c9805842d745412ffe9b45e822896001ef27cb`. main 병합 없음.

## 동작

| 상황 | 정책 |
| --- | --- |
| 신규 계정 이름 | 완성형 한글·영문·숫자 2~6글자. 공백/자모/특수문자/줄바꿈 불가 |
| 이름 선택 | ‘중복 확인’ 성공 후 결정. 입력 변경 시 승인 해제. 영어 대소문자 중복 처리 |
| 최종 저장 | 실제 unique index가 경합을 차단. 검사 통과가 예약을 뜻하지 않으며 결정 시 다시 검사 |
| 게스트 시작 | 로컬 랜덤 이름을 1회 저장하고 이름 선택/프로필 프롤로그 없이 시작. 기존 유효 이름·진행도·튜토리얼 지급 내역 보존 |
| 게스트→계정 연동 | 로컬 이름이 충돌하면 서버에서 고유 랜덤 이름 배정. 진행도/지갑/튜토리얼 지급 내역을 기존 원자적 이전 경로로 유지 |
| 연동 후 변경 | 프로필의 ‘마왕 이름 변경 (계정 연동 1회)’에서 사용. 일반 직접 가입 계정에는 임의 재변경 기회 없음 |
| 변경 실패/재시도 | 중복 실패는 기회 미차감. 성공은 서버 계정 잠금 안에서 1회 차감. operation UUID 재전송은 결과 재생. 연동 재시도는 기회 재지급하지 않음 |
| 기존 한 글자 이름 | 강제 개명·삭제 없이 읽기/진행 보존. 교정 기회 1회 부여. 신규 한 글자 이름 생성/변경은 차단 |

## 입력 수정 범위

- `nickname_line_edit.gd`를 신규 등록/연동 후 이름 변경에 공통 사용. 이름 문자열을 매번 다시 대입하거나 모든 변경에서 커서를 끝으로 보내지 않는다.
- 한글 IME의 조합 중 버퍼를 `max_length`로 자르지 않고, 확정 문자열을 Catalog 규칙으로 검증한다. 초과 입력도 결정/서버에서 차단한다.
- 중복 확인/결정 직전 `apply_ime()`로 마지막 조합 글자를 포함한다. 동작 버튼은 입력 초점을 빼앗지 않는다. 랜덤 버튼은 명시적으로 조합 취소 후 전체 문자열을 바꾸는 별도 경로다.
- 확정 문자열이 삽입됐는데 커서가 그 삽입 시작점에 남은 경우에만 deferred 보정한다. 활성 IME/선택/수동 중간 편집은 끝으로 밀지 않는다. 조합 중 텍스트 교체/프레임 폴링 없음.
- 원래 `text_changed` 검증 함수가 텍스트를 덮어쓰는 코드는 없었다. 실제 사용자 OS에서의 IME 이벤트 열을 이 환경에서 캡처하지 못했으므로 원인을 단정하거나 실제 Windows/Android 재현 해결을 검증했다고 주장하지 않는다. OS 조합 확정과 보고된 커서 정지 경계에 방어를 추가했다.
- PC/모바일은 같은 입력 컴포넌트·검증·중복 확인을 쓴다. 기존 모바일 키보드 inset/스크롤 처리는 유지한다.

## 구조·서버

- 클라이언트 값/문구는 `nickname_catalog.gd`, 서버 값은 `private.nickname_policy()` 한곳에서 관리한다. 최소/최대/허용 문자/연동 기회/랜덤 prefix의 일치 검사 통과. 개별 계정·몬스터 ID에 따른 분기 없음.
- 기존 `lower(nickname)` partial unique index 재사용. 중복 조회는 이 인덱스에서 존재 여부만 반환한다. 계정 UUID·다른 사용자 프로필·목록을 노출하지 않는다.
- 기존 프로필 테이블에는 변경 가능 횟수와 마지막 operation UUID/이름만 추가. 원래 이름을 일괄 교체하지 않았다. 기존 1글자 호환 CHECK는 유지하고, INSERT/실제 이름 변경은 새 정책 trigger로 검증한다. 기존 guest import의 형식 검증은 호환용으로 보존하되 이름은 먼저 신규 정책을 통과시키거나 서버에서 재배정한다.
- public invoker RPC → private definer 연산, 빈 search_path, 활성 계정/실제 Auth session/기기 nonce 검사를 유지. authenticated의 직접 프로필 쓰기 권한 없음. 정상 등록/완료도 같은 서버 연산을 사용한다.
- 변경과 중복 조회를 CloudStore 직렬·자동 재시도에 연결. 변경은 고정 operation UUID로 중복 소비를 막는다. 계정 전환 후 옛 응답을 현재 프로필에 설치하지 않는다.
- Supabase에 `nickname_policy_and_linked_rename` 적용 완료. 저장소 파일 `supabase/migrations/20261017120132_nickname_policy_and_linked_rename.sql`, 서버 기록 `20261017120132`. 기존 지급 내역/저장 snapshot을 재작성하지 않았다.

## 검증과 미검증

- 실제 Supabase 임의 fixture BEGIN/ROLLBACK 65검사: 1/7글자·자모·공백·줄바꿈 거부, 고유 이름 배정, 중복 검사/최종 저장, 게스트 이름 충돌 이전/지갑 유지, 1회 차감/실패 미차감/응답 유실 재생/재연동 재지급 금지/기기 fence/권한. 배포 후 재실행 통과.
- 기존 서버 `cloud_canonical_sessions.sql` 26/26 통과.
- Godot4.5.1 headless 실제 Profile/Scope/공용 입력/Prologue/프로필 UI: 신규 132검사 PASS. 실제 CloudStore 재시도 7검사 PASS. 기존 모바일 키보드 높이/밀도/OS resize/스크롤 회귀 PASS. 마지막 import·실행 ERROR/WARNING 없음, diff 검사 통과.
- fixture는 실제 저장/이름/프로필/연동 편집 UI를 실행하며 로그인/인증 transport·없는 아트/전투 씬은 명시적 대역이다. IME 커서 보정 테스트는 커밋 상태·커서 정지 시뮬레이션이며 실제 OS 한글 조합 테스트가 아니다.
- 실제 Windows Microsoft IME, Android Gboard/삼성 키보드, 실제 OAuth 연동·두 기기 동시 개명, 전체 아트 로비/프롤로그 통합은 미검증. 기존 `player_prologue_smoke`의 정책 기대값은 갱신했으나 전체 테스트는 이번 격리 fixture에서 실행하지 않았다.
- Advisor performance 0건. security는 기존 private no-policy INFO 및 기존 Auth 유출 비밀번호 보호 미사용 WARN만 반환했다. 이 작업은 Auth 설정을 바꾸지 않았다. [private RLS 설명](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy), [기존 Auth 설정 설명](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

재현:

```bash
python tools/build_nickname_fixture.py /tmp/again-hero-nickname
GODOT --headless --path /tmp/again-hero-nickname --editor --import --quit
GODOT --headless --path /tmp/again-hero-nickname --script res://tests/nickname_input_smoke.gd
GODOT --headless --path /tmp/again-hero-nickname --script res://tests/nickname_rpc_retry_smoke.gd
GODOT --headless --path /tmp/again-hero-nickname --script res://tests/player_prologue_keyboard_smoke.gd
```

검토한 1차 자료: [Godot LineEdit/IME](https://docs.godotengine.org/en/4.5/classes/class_lineedit.html), [Supabase 함수/권한](https://supabase.com/docs/guides/database/functions). 2026-10 changelog의 TLS 공지를 확인했으며 기존 HTTPS 경로를 변경하지 않았다.
