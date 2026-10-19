# 온라인 연결 복구·이탈 유예

## 기준

- 시작 로컬/원격 feature/stage10-astra: `a9cfba60d37013e24118e1b7b62cf09db79694fc`, 작업 트리 clean. main: `6f22053f462e1176ec2ecde131d589d5491791b2`. main 병합 없음.
- 사용자가 PC↔모바일 Cloudflare localtest 매칭, 양쪽 승패, 용사 레벨업·증강 UI의 기본 동작을 실기 확인했다고 보고했다. 이 보고는 아래 새 재접속 기능의 실기 검증을 뜻하지 않는다.
- 콘텐츠/180초/5몬스터·견습마도사/무랭킹·무보상 룰은 유지한다. wire protocol만 2로 올렸으므로 서버·두 클라이언트를 함께 업데이트한다. 콘텐츠 rule ID `duel_smoke_v1`은 그대로다.

## 정책

모든 수치는 `src/online/match_rules.gd`에서 관리한다.

| 항목 | 기본값/동작 |
|---|---|
| 끊김 감지 | 2초 heartbeat, 서버 수신8초/경기 중 클라이언트 응답6초 초과 감지 |
| 복귀 유예 | 서버가 끊김을 감지한 때부터 15초 |
| 유예 중 전투 | Battle의 기존 external pause 사용. 이동 입력0, 전투 시간·HP/마나·성장·증강 자동 선택 시간 정지, 양쪽 입력 거부 |
| 복귀 | 같은 서버·방·역할·Battle 인스턴스 복원. 최신 snapshot/증강 선택을 전송하고 ready ACK까지 정지 유지 |
| 재시도 | 1초 간격, 클라이언트 복구 시도 최대30초. 재시도 자체는 서버 유예·클라이언트 기한을 연장하지 않음 |
| 만료 | 연결 및 ready 완료된 상대만 승리. 양쪽 모두 부재/미준비 상태면 무효 |
| 명시적 나가기 | `leave`를 수신하면 즉시 상대 승리. 통신이 이미 끊겨 leave를 전달할 수 없으면 서버 유예 만료로 처리 |
| 종료 결과 보관 | 기존과 동일한 10초. 끊겼던 클라이언트는 이 기간에 경기 재개 없이 확정 결과만 수신 가능 |

- TCP가 살아 보이는 통신 먹통은 감지까지 약8초가 추가될 수 있다. UI 대기15초는 서버 감지 이후의 유예다. 정상 초기 계정 인증/대기열에는 기존 join timeout을 사용한다.
- Android application pause 알림은 포기 대신 복귀 경로로 들어간다. 복귀 중 접속 버튼/이동·소환·증강 입력을 막고, 상대 화면에 일시정지·남은 유예 시간을 표시한다. 서버가 재개를 통지하기 전에는 로컬 타이머만으로 전투를 재개하지 않는다.
- 복귀 snapshot은 tick/증강 revision이 같아도 UI를 다시 구성한다. 이미 선택한 증강은 중복 적용하지 않으며 아직 선택하지 않은 후보는 서버 상태를 그대로 사용한다. 복귀 후 입력 sequence는 새 연결에서 재설정하고 서버는 중복/역순 입력을 계속 거부한다.
- 종료 결과는 서버 BattleRoom의 기존 1회 finish guard를 사용한다. 클라이언트/화면도 중복 result를 무시한다. 실패한 클라이언트가 임의로 승패를 만들지 않는다.

## 인증·수명·성능

- 최초 계정/초대 인증 후 서버가 각 좌석에 Crypto24바이트 무작위 복귀 토큰을 발급한다. `resume_tokens`와 `reserved_uids` 레지스트리로 방/역할/계정을 찾는다. 클라이언트의 uid/역할 주장으로 복원하지 않는다. 일반 로그인 인증, localtest 입장코드 검증은 변경하지 않았다.
- 토큰은 같은 서버 프로세스의 원래 경기·역할에만 유효하다. 원래 연결이 살아 있으면 takeover를 거부하고 기존 연결 종료를 기다린다. 끊긴 UID는 유예 중에도 새 join에서 중복 계정으로 차단한다. 토큰은 준비 응답/복귀 확인 패킷이 유실돼도 다시 시도할 수 있도록 해당 경기 동안 유지한다.
- 복귀 토큰/접속 주소는 클라이언트 메모리에만 보관한다. URL·계정 저장·클라우드·로그에 복귀 토큰을 쓰지 않는다. localtest 입장코드를 다시 저장하지 않고도 이미 시작한 경기에 복귀한다. 나가기·일반 오류·계정/테스트 scope 변경·복구 실패·확정 결과 수신 시 토큰을 폐기한다.
- 경기 종료 시 UID 예약을 풀고, 보관 기간 종료 시 토큰/좌석/방을 정리한다. 이전 방 cleanup이 새 경기의 UID 예약을 지우지 않도록 해당 방 key를 확인한다. 경기/접속 상한은 기존8방/24접속을 유지한다.
- healthy leave 패킷을 전송 중인 WebSocket은 짧은 socket_drain 노드가 이어받아 씬 파괴 후에도 nonblocking poll/close를 마친다. 최대2초 후 제거하며 명시적 나가기 때만 생성한다. 끊김 재시도/전투 프레임마다 노드를 생성하지 않는다.
- active snapshot은 기존10Hz다. 일시정지/종료 방의 반복 전장 직렬화를 생략하고 heartbeat만 유지한다. 복귀 시 필요한 snapshot만 별도로 보낸다. 기한 검사는 최대8방의 두 좌석이며 전투 전체 그룹 스캔/매 프레임 배열 생성을 추가하지 않았다. 실제 FPS/서버 수용량 개선율은 측정하지 않았다.
- Hero/Battle/몬스터/성장/보상, 계정 저장·CloudStore·해금·프로젝트 설정은 바꾸지 않았다. BattleRoom은 기존 pause API와 입력/step gate만 연결하고 기존 snapshot 계산은 유지한다.

## 실기 확인 순서

1. 서버와 PC/모바일 모두 브랜치 최신화. 기존 서버를 종료하고 같은 `-- --localtest` 명령으로 재실행, 새 입장코드를 두 게임에 입력한다. 같은 포트의 기존 Cloudflare 터널은 유지할 수 있다.
2. 매칭 후 휴대폰의 Wi-Fi와 모바일 데이터를 함께 약10초 끄고 다시 켠다. 또는 게임을 잠깐 백그라운드로 보냈다가 돌아온다. 실제 OS 알림·기기 동작은 다를 수 있다.
3. 상대 화면의 전투가 멈추고 대기 안내가 보이는지, 연결 복구 뒤 같은 HP/레벨/몬스터/증강 후보·남은 전투 시간으로 이어지는지 확인한다.
4. 상대의 대기15초가 끝날 때까지 복구하지 않으면 연결된 쪽만 승리하는지 확인한다. 양쪽 부재 만료는 무효다.
5. 정상 연결 상태에서 ‘로비로’를 누르면 상대 승리, 다시 매칭하면 새 경기로 시작하는지 확인한다.

## 로컬 테스트 연결 버튼 (2026-10-19 추가)

- 시작 SHA: feature/stage10-astra `d7d8f4b5d98e518b8753bc34e25261cb19dc218e`, main `6f22053f462e1176ec2ecde131d589d5491791b2`, 작업 트리 clean. main 병합 없음.
- localtest 쿠폰의 격리 테스트 화면에만 `연결 끊기 (테스트)` / `재접속` 버튼이 표시된다. 매칭 전·종료 후에는 사용할 수 없다. 실제 계정/일반 게스트/튜토리얼에는 생성하지 않으며 API도 현재 테스트 권한과 localtest 연결 여부를 재검증한다.
- 같은 PC에서 게임 두 개 실행 → 양쪽 `ws://127.0.0.1:24840` 및 현재 서버 입장코드 입력 → 용사/마왕 매칭 → 한쪽 `연결 끊기 (테스트)` → 상대의 일시정지 표시 확인 → 유예 만료 전에 끊은 쪽 `재접속`을 누른다. 이미 인증한 같은 좌석으로 복귀하므로 입장코드 재입력이 필요 없다.
- 끊기 버튼은 실제 WebSocket을 닫고 기존 network-loss 경로로 들어간다. leave/새 join을 보내지 않는다. 자동 재시도만 수동 보류하며 재접속 버튼은 그 보류를 해제하고 다음 프레임부터 기존 resume/ready 절차를 즉시 실행한다. 실제 인터넷 먹통/OS 종료를 흉내 내는 기능은 아니다.
- 서버 감지 이후 15초 유예 및 클라이언트 30초 복구 한도는 기존 MatchRules 한 곳의 값을 사용하며 연장하지 않는다. 만료 후에는 상대 승리, 기존 결과 보관 기간 안에 재접속하면 확정 패배만 표시한다. 클라이언트 복구 한도 만료 시 보류/토큰을 폐기하고 로비 복귀를 안내한다.
- 일반 통신 끊김은 기존 자동 재접속을 유지한다. 테스트 보류 상태는 메모리에만 있고 나가기/새 접속/실패 시 초기화한다. 게임 강제종료 후 재실행 복귀는 여전히 별도다.
- `tests/online_connection_buttons_smoke.gd`: 실제 입장코드 서버와 용사/마왕 UI 버튼 신호·소켓·Battle 사용, 양쪽 수동 보류/복귀·같은 방/좌석/증강 후보·전투 정지·권한 거부·유예 만료와 확정 결과 수신·정리 검증. 15초 만료 검사는 서버 좌석 deadline만 테스트에서 과거로 옮긴다.

- 버튼 추가 후 Godot4.5.1 headless 새 통합45 + UI51 + 기존 자동 복귀66 + localtest32 + transport18 = **212검사 PASS**. 최종 import 오류/경고0, 모든 실행 ERROR0. fixture 누락 아트 경고: 버튼50/UI0/복귀214/localtest50/transport50. 실제 Windows4.7.2/Android/WSS·전체 아트 시각 검증은 별도다.

## 검증과 한계

- Godot4.5.1 headless에서 실제 TCP/WebSocket/Client/Server/Battle/Hero/선택5종 몬스터 경로를 사용한다. fixture의 누락된 아트/음원은 대체하거나 누락 경고를 유지한다. 전체 GPU/시각 검증이 아니다.
- `online_reconnect_smoke`는 같은 Battle 인스턴스/상태 복원, 실제 레벨업 후보 복귀·선택, 유예 중 시계/HP/마나/레벨/build/choice_age 보존, 입력 차단/sequence 재설정·재생 방지, 잘못된 토큰·다른 방·활성 좌석 takeover·중복 계정 차단을 검사한다. Android pause 알림 경로를 코드로 주입하고 heartbeat loss도 검사한다.
- 한쪽/양쪽 만료, ready 전 끊김·복귀·미준비 만료, 명시적 포기, 늦은 확정 결과 복구/중복 무시, 종료/복귀 레지스트리 cleanup, 클라이언트 실패 기한·토큰 폐기·승패 미추정을 확인한다. 15/30초 만료 경계는 테스트에서 저장된 monotonic deadline을 과거로 이동해 검사하고 배포 정책 상수는 바꾸지 않는다.
- UI와 기존 localtest/실제 전투/transport 회귀, 기존 3개 OS 프로세스(서버·용사·마왕)의 동일 match/winner 검증을 함께 수행한다. 해당 3프로세스 회귀는 정상 연결 경로이며 재접속 테스트 자체는 한 OS 프로세스의 실제 loopback 소켓들이다.
- 최종 복귀66 + UI47 + localtest32 + 기존 전투44 + transport18 = **207검사 PASS**, 기존 3프로세스의 양쪽 상태30회/동일 match·승자 PASS. 최종 import ERROR/WARNING0, 실행 ERROR0. 복귀 테스트의 누락 아트 경고214건, UI 경고0; 실제 전투/기존 회귀에도 fixture 아트 누락 경고가 있으며 이를 숨기지 않았다. Python AST/git diff --check 통과.
- 앱 강제종료/재실행 시 복귀 토큰 복원, 서버 재시작/장애 복구, 보간/예측/지연 보정, 랭킹·보상·누적 이탈 페널티는 이번 범위가 아니다. ready 완료 후 다시 끊기면 새 유예를 주며 경기당 누적 이탈 제한은 아직 없다.
- 실제 PC4.7.2↔Android의 Wi-Fi/LTE 전환·Cloudflare WSS 재접속·OS 백그라운드, OAuth 계정 인증 성공, 앱/native export, 전체 원본 VFX/GPU/FPS/다중 방 부하는 미검증이다.

재현:

```sh
python tools/build_online_fixture.py /tmp/again-online-localtest
godot --headless --editor --import --path /tmp/again-online-localtest
godot --headless --path /tmp/again-online-localtest --script res://tests/online_reconnect_smoke.gd
godot --headless --path /tmp/again-online-localtest --script res://tests/online_ui_smoke.gd
godot --headless --path /tmp/again-online-localtest --script res://tests/online_local_test_smoke.gd
godot --headless --path /tmp/again-online-localtest --script res://tests/online_battle_smoke.gd
godot --headless --path /tmp/again-online-localtest --script res://tests/online_transport_smoke.gd
python tools/run_online_process_smoke.py /absolute/path/to/godot /tmp/again-online-localtest
```
