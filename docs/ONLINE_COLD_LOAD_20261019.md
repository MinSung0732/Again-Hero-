# 온라인 첫 입장 로딩 중 연결 종료 — 2026-10-19

## 문제와 변경

사용자는 용사 쪽 전장은 나타나지만 마왕은 연결 직후 끊기고 용사 승리가 표시된다고 보고했다. 동기 matched 콜백에서 마왕성 리소스를 준비하는 동안 네트워크 poll이 정지한다. 클라이언트는 콜백 이전 수신 시점으로6초 응답 제한을 계산하고, 서버는 미준비 클라이언트에도8초 idle 제한을 적용했다. 서버 room.prepare의 시간도 상대 좌석의 수신/준비 시간에 포함됐다.

- 미준비 좌석만 기존 READY_TIMEOUT20초를 사용한다. 준비된 좌석의 idle8초와 클라이언트 응답6초, 재접속15초는 유지한다.
- 서버는 버퍼에 도착한 메시지를 먼저 처리해 오래된 수신 시계만 보고 ready/heartbeat를 버리지 않는다. 서버 전장 준비 완료 후 room 준비 시계와 참여자 수신 시계를 시작한다.
- 클라이언트는 동기 이벤트 콜백이 끝나면 수신 시계를 갱신한다. 콜백에서 종료/교체된 소켓에 이전 수신 루프와 timeout을 이어 적용하지 않는다.
- 전장 로딩 자체를 비동기로 바꾸거나 전투/피해/AI/보상/PNG/프로토콜을 바꾸지 않는다. 준비20초 한도와 준비 제한 만료 시 무효 처리는 기존 정책을 따른다.

## 검증

Godot4.5.1 격리 fixture, 실제 서버와 두 클라이언트를 별도 OS 프로세스로 실행했다. 마왕의 matched 콜백에서 PEER_IDLE_TIMEOUT+0.5초(현재8.5초) 동안 로컬 작업 정지를 주입했다. 수정 전 마왕 복구 진입/방의 잘못된 종료/용사 오류 결과를 확인했고, 수정 후 복구 없이 양쪽 ready→전투 진행→검사 종료 결과1회 수신을 확인했다. Windows 실제 아트 로딩 시간을 측정한 테스트가 아니다.

기존 reconnect66/lifecycle53/transport18/buttons48 총185검사 PASS, ERROR0. fixture에 포함되지 않은 아트 경고 있음. git diff --check와 새 Python runner AST 검증 통과. 실제 Windows4.7.2/Android/GPU/WSS 재현 환경은 미검증이다.

재실행(기존 build_online_fixture 생성 후 원본 마왕성/PNG overlay fixture):

```sh
python tools/run_online_cold_load_smoke.py /absolute/path/to/godot /tmp/again-online-localtest
```

서버와 양쪽 게임 모두 feature/stage10-astra 최신화 후 서버를 재시작한다. 프로토콜은4로 유지한다. 사용자에게 같은 입장 순서의 재검증을 요청한다. main은 변경하지 않는다.
