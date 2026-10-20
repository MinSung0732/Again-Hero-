# 온라인 상태 패킷 경로 중복 제거 — 2026-10-20

## 적용

**protocol7. 서버와 양쪽 클라이언트를 함께 갱신하고 서버를 재시작한다.** 이전 버전은 join/resume에서 버전 불일치로 거부한다. main 병합 없음, 작업 브랜치는 feature/stage10-astra다.

사용자가 이전 이동 보간 빌드의 정상 동작을 보고했다. 이번 변경은 그 위에서 PNG 경로 중복 전송을 줄인다. 새로운 아트·UI·전투/AI/소환/보상/접속 제한 변경은 없다. 상태 전송은 기존0.1초 주기를 유지한다.

## 형식과 경계

서버가 생성한22필드 visual 명령의 경로 필드만 패킷 내 `visual_paths` 목록의 정수 번호로 바꾼다. 경로·필드 위치·명령 상한은 공통 `online_presentation_catalog.gd`를 참조한다. 특정 몬스터/용사/공격 ID나 리소스 경로 목록을 코덱에 복사하지 않는다. 나머지 좌표·변환·접지점/깊이·색/프레임·HP·입력ACK·이벤트·선택지는 기존 값 그대로다.

목록은 **각 상태 패킷에 포함**한다. 이전 상태/소켓/클라이언트 캐시에 의존하지 않아 입장, 복귀 직후 상태, 틱 건너뜀/폐기에도 별도 목록 전송이나 재동기화 ACK가 필요 없다. 경로 중복의 절약량이 목록 키/구두점/번호 비용보다 작거나 같으면 원래 문자열 형식을 보낸다. UTF-8/JSON 이스케이프·두 자리 이상 번호를 포함한 실제 byte 비용으로 판단하며, 같은 입력의 JSON보다 커지지 않는다. 최종 본문 한도98304bytes는 유지한다.

방당 고정128행×22필드 캐시, 재사용 목록/사전/봉투로 인코딩한다. 서버가 만든 명령의 형태/경로를 검사하며, 신뢰할 수 없는 수신 명령의 전체 숫자/영역 검증은 클라이언트가 한다. 서버 정기 상태는 한 번 인코딩한 문자열을 양쪽에 공유하고 복귀 직후 상태도 동일 코덱을 사용한다. 매 프레임 새 배열/Dictionary나 노드·그룹 스캔, 개체쌍 탐색을 추가하지 않았다. 코덱 작업은 정기 snapshot/복귀 전송 시만 실행한다.

클라이언트는 목록과 모든 명령/번호/유한값/영역을 먼저 검사한다. 하나라도 잘못되면 경로를 일부만 바꾸지 않고 전체 상태를 폐기한다. 검사를 통과한 패킷에서 번호를 원래 경로 문자열로 복원하고 목록 필드를 제거한 뒤 기존 이벤트/전장/보간/PNG 로더에 전달한다. 기존 PNG 허용 루트/확장자·경로 길이·128명령/텍스처 캐시 제한을 그대로 따른다. 수신량과 서버 snapshot_bytes는 복원 전 실제 본문 크기를 센다.

## 검증과 계측 범위

`online_snapshot_codec_smoke.gd`는 UTF-8 경로/최대128행의 무손실 왕복과 정확한 크기 계산, 고유 경로 fallback, 입력 불변·캐시 재사용·패킷 순서 독립, 잘못된 목록/번호/숫자/영역의 원자적 거부, 최종 크기 제한·제어 패킷 불변을 확인한다. 실제 WebSocket 양쪽이 반복 몬스터 명령을 받은 뒤 새 소켓으로 같은 방에 복귀하는 것과 구 프로토콜 거부도 확인한다.

`online_snapshot_benchmark.gd`는 동일한 실제 Battle 정지 상태를 기존 JSON과 새 코덱으로 번갈아96회 측정한다(워밍업8회 별도). 0/24/48개체는 테스트 직접 생성한 혼합 로스터이며, 실제 유료 소환의 인구 비용 조합/승률이나 지속 전투 부하의 증거가 아니다. 엔진은 Linux Godot4.5.1 headless 격리 fixture다. encode는 UTF-8 본문 한도 검사, decode는 JSON parse와 새 경로 검증/복원을 포함한다. snapshot 생성/PNG draw·UI/GPU/지속 전투/오디오/소켓/TLS는 계측에서 제외한다.

코덱은 전송량과 CPU 사이의 교환이다. 추가 GDScript 경로 검증/복원 때문에 CPU 시간이 늘 수 있다. FPS/RTT/입력 반응 개선이나 실제 Windows↔Android/WSS 처리량 향상을 주장하지 않는다. 패널의 평균/P95·송수신량과 실제 기기 조작감은 다음 실측 대상이다.

재실행:

```sh
python tools/build_online_fixture.py /tmp/again-online-metrics
# 이전 검사의 원본 역할 로딩/마왕성/로스터/공격 PNG·기존 SFX overlay 유지.
godot --headless --editor --import --path /tmp/again-online-metrics --quit
godot --headless --path /tmp/again-online-metrics --script res://tests/online_snapshot_codec_smoke.gd
godot --headless --path /tmp/again-online-metrics --script res://tests/online_snapshot_benchmark.gd
python tools/run_online_process_smoke.py /absolute/path/to/godot /tmp/again-online-metrics --metrics
python tools/run_online_cold_load_smoke.py /absolute/path/to/godot /tmp/again-online-metrics
```

## 동일 상태 전후 수치

시간 단위 ms, 평균. 아래 값은 단일 격리 프로세스의 관측치이며 실기/WSS 전송속도나 FPS가 아니다.

| 몬스터 | 기존/변경 bytes | 감소 | encode 기존→변경 | decode 기존→복원 포함 |
|---:|---:|---:|---:|---:|
| 0 | 526 / 526 | 0.00% | 0.019 → 0.024 | 0.012 → 0.018 |
| 24 | 7663 / 6557 | 14.43% | 0.222 → 0.311 | 0.130 → 0.258 |
| 48 | 13574 / 11187 | 17.59% | 0.407 → 0.552 | 0.236 → 0.468 |

[원본 평균/P95/최대·표본수](benchmarks/online_snapshot_codec_cpu_20261020.json). 48개체에서는 본문2387bytes(약17.59%)를 줄이는 대신 encode 평균약0.145ms, decode/검증/복원 평균약0.232ms가 추가됐다. 0개체는 크기 증가 없이 기존 형식이며 코덱 호출/검사 비용은 있다. 제어/피격 이벤트/입력 전송률은 바꾸지 않았다.

## 최종 회귀

새 코덱44 + 기존 보간37/UI51/연결버튼48/로딩63/마왕성146/PNG155/피드백61/측정38/재접속66/lifecycle53/transport18/소환35/localtest32/실제Battle44 = 891검사 PASS. 별도 서버·두 클라이언트3프로세스는 양쪽29상태/동일 승자와 protocol7 측정 수집 PASS. 기존8.5초 cold-load3프로세스도 잘못된 복구/승패 없이 PASS. 마지막 import/정적/Python AST 통과. 원본 온라인 PNG/공격·SFX를 적용한 격리 fixture이며 일부 다른 아트는 대체본이다.

전송 검사는 기능18항목 통과 후 종료 때 남던 paused 음원을 명시 정리하고,3프로세스 검사는 guest journal을 역할/PID별 테스트 경로로 분리했다. 초기 cold-load 검사의 경기 결과는 정상이었지만 동시 프로세스가 같은 guest journal을 저장/복구해 종료 오류가 난 것을 해결했다. 둘 다 테스트만 변경하며 게임의 계정/저장/오디오 정책은 바꾸지 않았다.
