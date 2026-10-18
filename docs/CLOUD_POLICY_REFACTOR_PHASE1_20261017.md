# 하드코딩 정리 1차: 클라우드 통신 정책 — 2026-10-17

## 기준과 범위
- 수정 전 branch/HEAD: feature/stage10-astra `449a66e98e937c04e0020ad0531f09f5d1dc0223`, origin/main `10c9805842d745412ffe9b45e822896001ef27cb`. 신규 sparse checkout의 작업 트리 clean 확인. main 병합 없음.
- CloudStore의 재시도·연결 확인·HTTP 제한·저장 병합·연결 화면 지연과 안내 문구를 데이터로 통합. 프로필/로비/전투 전체를 함께 리팩터링하지 않음.
- Supabase API/DB/권한/저장 포맷·요청 본문·UUID·기기 쓰기 fence 변경 없음. OAuth 공급자/토큰 갱신 주기와 브라우저 콜백 설정은 별도 정책이므로 이번 범위에서 유지.

## 변경
- `cloud_connection_catalog.gd`: 공용 시간·크기·문구18개와 기존 backoff 계산. CloudStore/로그인 gateway/로딩 화면/재접속 overlay가 참조.
- `rpc_contract_catalog.gd`: 프로필 직렬 재시도 허용6종을 정적 Dictionary로 관리. 목록에 없는 요청은 자동 재시도하지 않음. cloud_sync는 기존 외부 잠금/복구 경로 유지.
- 인증401은 한 번 refresh 후 처리하고,408/429·통신 오류/5xx는 기존 지연 재시도. 실패한401 refresh를 무한 지연 재시도로 바꾸지 않음. 클라이언트 오류 분류와 직렬 요청 재시도는 동일 목록을 참조하되 의미를 구분.
- 응답 정수 상한은 기존 RPC contract 값 재사용. 기존 REJECTED_MESSAGE 접근은 alias로 호환 유지. 런타임 분기/기능/함수 수와 사용자 문구는 유지.

| 항목 | 전후 동일한 값 |
|---|---|
| 최초/배수/최대 재시도 | 1초 / 2배 / 15초 |
| 정상 연결 확인 주기 | 15초 |
| 연속 저장 병합 지연 | 0.15초 |
| HTTP 제한 시간 | 20초 |
| HTTP 응답 본문 상한 | 2,000,000 bytes |
| 대기 화면 표시 지연 | 0.8초 |

## 검증
- 변경 전: 실제 HTTP/캐시 복원34, 닉네임RPC10, 성별17 PASS.
- 변경 후 Godot4.5.1 headless: 정책49 + Auth복구7 + 프로필재시도6 + HTTP/캐시34 + 닉네임RPC10 + 성별17 + 한글입력132 = 명시255검사 PASS. 저장복구 CLOUD_SAVE_SMOKE_OK, 모바일 키보드 레이아웃 PLAYER_PROLOGUE_KEYBOARD_SMOKE_OK.
- 정책49에는 HTTP 상태 -1~600의 구 로직 비교, 실제6종 transient 재시도/동일 UUID·본문 유지/소유권 해제, 미등록3종 무재시도,401 refresh 성공/실패,408/429/503 복구, 비즈니스 오류·영구오류 종료, 실제 Timer backoff·빠른저장/긴저장 정지·기존 일시정지 유지·각 terminal 이유/공용 UI 문구 확인 포함.
- 정적검사: git diff --check, 문구18개 원문 동등성/기존 위치의 literal 제거, 수정된 프로덕션4파일 함수 수 불변. 최종 두 격리 프로젝트 editor import/parse 오류0.
- 격리 fixture는 실제 CloudStore/LoginGateway/연결 overlay/화면 스크립트를 사용하고 그림·인증 전송·warmup 일부를 fixture로 대체. Windows DPAPI 항목은 Linux에서 명시적 SKIP. 실제 Windows/Android OAuth·망 전환·GPU 전체 화면/보안 저장소 미검증. FPS 개선율은 측정하지 않았음.

## 재현
1. `python tools/build_cloud_policy_fixture.py /tmp/cloud-policy-fixture`
2. Godot `--headless --path /tmp/cloud-policy-fixture --editor --import`로 새 placeholder PNG를 import한 뒤 동일 명령을 다시 실행해 autoload 초기 스캔 결과를 검증.
3. 해당 프로젝트에서 `tests/cloud_policy_smoke.gd`, `cloud_auth_recovery_smoke.gd`, `cloud_profile_retry_smoke.gd`, `cloud_save_smoke.gd`를 `--script res://tests/<file>`로 순차 실행.
4. 기존 입력/성별·HTTP 회귀는 `build_cloud_rpc_fixture.py` 프로젝트에서 순차 실행. 두 fixture의 저장 폴더는 분리되어 있음.

## 후속 단계
- 2차: 성별·기본 초상화·프로필 기본값 중복.
- 3차: 로비 콘텐츠별 분기와 UI 정책.
- 4차: 전투 콘텐츠 분기/반복 조회를 계측 후 검토.
