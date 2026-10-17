# 로그인 후 연결 대기 반복 — 저장 버전 RPC 형식

기준: `feature/stage10-astra` `d8f2266db3af88dbaebdd54cb7f177d9d57934af`, main `10c9805842d745412ffe9b45e822896001ef27cb`.

## 원인과 증거

- 사용자 화면은 신규 재접속 overlay다. 스크린샷 시간대(2026-10-17 21:20~21:34 KST)의 프로젝트 로그에서 `cloud_sync` HTTP400 13회와 PostgreSQL22P02 오류를 확인했다. 로그는 경로/상태/오류 코드 집계만 사용했으며 이용자 payload/토큰을 읽지 않았다.
- Godot `JSON.parse_string()`은 정수도 float로 복원한다. 저장 캐시에 보관된 `pending_cloud.expected_revision`이 1 → 1.0으로 바뀌어 `JSON.stringify()`의 요청에도 `1.0`이 들어갔다. SCOPE.revision은 int로 복원했지만 pending 필드는 누락돼 있었다.
- 서버 RPC의 `expected_revision`은 bigint다. 실제 PostgreSQL JSON 레코드 변환에서 JSON1.0은 `22P02: invalid input syntax for type bigint: "1.0"`, JSON1은 정상으로 재현됐다.
- 이전 전송기는 비200 응답의 원인을 버리고 `{}`로 반환했다. 저장기는 이를 통신 장애로 취급해 같은 잘못된 요청을 무한 재시도했다.
- 사용자 PC의 실제 pending 파일/토큰/전체 요청을 수집한 것은 아니다. 로그의 오류 유형과 실제 복원/전송 경로가 일치하는 재현을 확보했다. 실제 사용자 계정의 로그인 완료는 수정 빌드 재실행 후 확인해야 한다.

## 수정

- 캐시 복원 때 검증한 pending의 expected_revision/serial을 int로 복원한다. operation UUID·payload·전송 여부·현재 revision/CAS/백업은 유지한다.
- `rpc_contract_catalog.gd`에서 RPC 정수 인자와 HTTP 재시도 분류를 관리하고 `rpc_request_codec.gd`가 전송 경계에서 정수 토큰을 보장한다. 선택 인자는 생략 상태로 유지한다. 비정수/NaN/무한대/문자열/불리언/정확도 범위 초과는 조용히 반올림하지 않고 거부한다. snapshot의 실제 소수값은 건드리지 않는다.
- 재시도로 해결할 수 없는 HTTP4xx는 terminal 상태로 전환하고 로그인 복귀 버튼을 제공한다. 기존401 refresh/408/429·통신 오류·5xx 재시도는 유지한다. 실패한 pending 저장을 삭제하거나 다른 UUID로 다시 만들지 않는다.
- 진단 로그는 HTTP 상태·서버 오류 코드만 기록하며 토큰·개인 프로필·요청 본문·서버 상세 메시지를 출력하지 않는다.
- 서버 스키마/데이터/사용자 저장의 변경 없음. 고친 클라이언트로 재실행하면 기존 pending 캐시도 복원 경로에서 정수형을 적용한다. 저장 파일 삭제가 필요하지 않다.

## 검증

- Godot4.5.1 headless `cloud_rpc_wire_smoke`: 34검사 PASS. 실제 loopback TCP/HTTPRequest로 구형 JSON1.0 요청400, 새 codec 전송200, 저장 캐시 재시작→claim/read→동일 operation UUID 재전송→저장 승인→연결 차단 해제를 실행했다. 503 자동 재시도, 400 종료 안내/타이머 정지와 미전송 보존도 확인했다.
- 전송 중 실제 HTTP400을 주입하는 음성 대조군은 의도한 `Cloud RPC rejected: HTTP 400, code 22P02` warning 1회를 출력한다. 최종 import/runtime SCRIPT ERROR/ERROR 및 예상 밖 경고 없음.
- 실제 PostgreSQL 임시 BEGIN/ROLLBACK 정수/소수 bigint 변환 2사례 확인. 서버 변경 없음.
- 기존 이름/프로필 UI132검사, RPC 재시도7검사 및 모바일 키보드 레이아웃 회귀 PASS. `git diff --check` PASS.
- 실제 Windows OAuth→사용자 계정 로그인·Android 실기/전체 아트 UI는 미검증. HTTPfixture는 실제 CloudStore/Scope/codec을 사용하고 인증과 응답만 대체한다.

```bash
python tools/build_cloud_rpc_fixture.py /tmp/again-hero-cloud-rpc
GODOT --headless --path /tmp/again-hero-cloud-rpc --editor --import --quit
GODOT --headless --path /tmp/again-hero-cloud-rpc --script res://tests/cloud_rpc_wire_smoke.gd
```
