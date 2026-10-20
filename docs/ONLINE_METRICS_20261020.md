# 온라인 지연·부하 측정 — 2026-10-20

최신 적용은 [protocol7 경로 중복 제거](ONLINE_SNAPSHOT_CODEC_20261020.md)를 따른다. 아래 protocol6은 패널 도입 당시 기록이다.

후속: [용사·몬스터 표시 이동 보간과 격리 CPU 계측](ONLINE_MOTION_20261020.md). 아래는 측정 패널 도입 당시 기록이다.

## 사용하는 방법

feature/stage10-astra를 서버와 양쪽 게임에 적용하고 서버를 재시작한다. protocol6. 기존 localtest 방식으로 연결한다. 매칭 화면의 **연결 측정 보기**로 패널을 연다. 전투가 시작되면 **측정 초기화**를 눌러 입장·대기 구간을 제외하고 움직임/소환/증강/다수 투사체/재접속을 구간별로 측정한다. **측정값 복사**는 JSON을 클립보드에 넣는다. 복사 동작은 실제 사용자의 버튼 클릭으로만 수행한다.

패널을 접어도 localtest 수집은 유지한다. 패널 갱신은1초 간격이다. 초기화는 이 클라이언트의 표본/누계/시계만 비우고 경기·입력 seq·서버의 공용 측정 창은 바꾸지 않는다. 값을 붙여넣으면 역할/OS/프로토콜과 수치만 포함된다. 주소, 입장코드, 인증 토큰, 계정ID, 원본 패킷은 저장/복사하지 않는다. 서버에 새 로그 파일/DB/외부 텔레메트리 전송은 추가하지 않았다.

## 값의 뜻

| 값 | 정의와 한계 |
|---|---|
| RTT | 기존 heartbeat에 nonce를 붙여 동일 nonce 응답까지의 클라이언트 단조 시계 경과시간. 대기·서버 처리·poll 스케줄링을 포함하며 순수 회선 지연/편도 지연이 아니다. |
| 수신간격 | 동일 경기의 더 새로운 server tick 상태가 WebSocket에서 소비된 시점 간격. 화면 렌더링 간격이나 패킷 손실률이 아니다. |
| 입력 처리 확인 | 성공적으로 전송 큐에 넣은 입력의 seq가 서버 처리 seq로 다음 정기 snapshot에 포함돼 돌아올 때까지의 시간. snapshot 대기·네트워크/poll 지연을 포함한다. 거부된 입력도 처리 seq는 증가하므로 성공/화면 반응의 증거가 아니다. 최신 seq 하나당 표본을 남기며 모든 입력을 각각 ACK하지 않는다. |
| 평균/P95/최대·count | 최근 최대96표본. P95는 nearest rank. RTT와 상태/입력은 표본 주기가 달라 창의 시간 길이도 다르다. 표본0은 null/미측정. |
| FPS | 해당 게임 프로세스의 Engine FPS. 서버 FPS/기기 GPU 벤치마크가 아니다. |
| 송수신 KiB/s | 약1초 창의 WebSocket 메시지 본문 byte/1024/경과초. TX는 send_text가 성공한 전송 큐 투입량, RX는 소비한 메시지 양이다. WebSocket/TCP/TLS 헤더·재전송 등 실제 회선 총량은 제외한다. 누적 bytes/packets는 복사 JSON에 포함한다. |
| 서버 physics_ms/process_ms | Godot Performance가 제공하는 프로세스 전체 엔진 monitor를 ms로 변환. 모든 방/다른 autoload를 포함하고 CPU 사용률(%)·특정 방 단독 시간이 아니다. |
| snapshot_ms/encode_ms | 서버 정기 snapshot 생성/JSON 인코딩·기존 크기 검사 구간의 최근96표본 평균. 제어용 Room.step만 전투 전체 CPU인 것처럼 보고하지 않는다. 표본수도 제공한다. |
| 방/연결/몬스터/투사체 | 보유 방(종료 유예 방 포함)/연결 socket/준비된 미종료 방 active_monsters/활성 projectile registry+공통 무기탄 집계. 모든 고유 연출 노드 수가 아니다. |
| snapshot_bytes | 마지막 정기 상태 본문 크기. 양쪽에 같은 본문을 보내며 송신량은 두 실제 성공 전송을 각각 센다. |

ready/연결 일시정지/소켓 교체 때 pending ping·입력 timestamp와 상태 간격 기준점을 버린다. 재접속 대기나 전장 준비 시간이 새 수신간격 표본에 섞이지 않게 하고, 이미 수집한 rolling 값은 보존한다. 새 join/명시적 초기화는 누계도 초기화한다. 과거 pong/seq, 덮어쓴64개 pending 입력의 예전 timestamp는 사용하지 않는다. RTT 요청은 최대1개만 대기하며 응답 timeout 이후 교체한다. 서로 다른 기기의 절대 시각을 빼지 않는다.

## 비용과 범위

일반 인증 경로의 수집은 기본 off. localtest client와 invitation/development 테스트 서버에서만 기본 on이다. 기존2초 heartbeat를 사용해 ping 빈도를 늘리지 않는다. seq ACK는 기존 정기 상태에 hero/demon 두 숫자를 붙인다. 입력별 응답 패킷은 만들지 않는다. 기록은 고정 Packed 배열에 O(1), P95 배열 복사/정렬·보고서 생성은 패널/복사 요청 때만 한다. 서버 상태 생성/인코딩 타이머도 측정 off일 때 건너뛴다. 서버 개체 집계와 monitor dictionary는1초 공용 캐시로 여러 클라이언트가 공유한다. 측정 on에서는 payload byte 계수를 위한 UTF-8 변환·clock 호출/표본 기록 등 소량의 추가 비용이 있으므로 오버헤드0/FPS 향상을 주장하지 않는다.

전투, 이동 보간, 전송률, 스탯·AI·매칭/재접속 제한, 계정/보상 정책은 바꾸지 않았다. 이번 작업은 개선 전 측정 기반이다.

## 검증

Godot4.5.1 headless 격리 fixture. 새38검사는 rolling mean/P95/한도, 무표본 null, 비활성 수집, nonce/중복pong/재접속 과거pong 거부, 역할별 seq·중복 state·pending 덮어쓰기, 단조시간과 정확한 byte/rate, 일반 서버 off·수치 schema, 실제 양쪽 UI/매칭/로딩/heartbeat/입력 ACK·클립보드용 JSON·초기화가 경기를 바꾸지 않는 것을 확인했다. 실제 OS 클립보드 쓰기/GUI 클릭은 headless에서 실행하지 않았다.

기존 UI51/버튼48/로딩63/lifecycle53/transport18/reconnect66 합계299, 새38과 총337검사 PASS. 최종 세션 관련 수정 후 새38/버튼48/재접속66 재실행 통과. 별도 서버·두 클라이언트3프로세스 --metrics 모드도 양쪽29상태/동일 승자, RTT·입력 ACK·서버 snapshot/encode 표본 수집 통과. Python AST·git diff --check·최종 import 통과. fixture의 다른 누락 아트 경고는 존재한다.

작은 Linux loopback 예에서는 첫 전투 상태에서 초기화 후 hero RTT 평균 약6.91ms(2표본), 수신간격 평균103.50ms(27표본), 입력 처리 확인 평균29.14ms(28표본)를 관측했다. demon 입력 확인은 소환1표본뿐이다. **Windows↔Android/WSS/실제 다수 몬스터 부하 측정이 아니며 성능 개선 결과가 아니다.** 실제 기기에서 구간별 JSON을 모은 뒤 보간·전송량/처리량 개선을 결정한다.

재실행:

```sh
python tools/build_online_fixture.py /tmp/again-online-metrics
# 원본 온라인 PNG/마왕성/역할 로딩 이미지와 기존5개 SFX overlay를 유지한다.
godot --headless --editor --import --path /tmp/again-online-metrics --quit
godot --headless --path /tmp/again-online-metrics --script res://tests/online_metrics_smoke.gd
python tools/run_online_process_smoke.py /absolute/path/to/godot /tmp/again-online-metrics --metrics
```

feature/stage10-astra만 변경, main 병합 없음.
