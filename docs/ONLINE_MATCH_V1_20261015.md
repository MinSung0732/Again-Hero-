# 온라인1:1 연결 테스트 v1 — 2026-10-15

경쟁 점수 없는 연결/전투 검증 단계다. 공용 서버는 아직 배포하지 않았다. 다른 인터넷의 친구끼리 플레이하려면 아래 서버 배포가 먼저 필요하다.

## 첫 룰

| 항목 | v1 |
|---|---|
| 프로토콜 / 룰 ID | 1 / duel_smoke_v1 |
| 매칭 | 서로 다른 로그인 계정, 용사1명 + 마왕1명, 역할별 FIFO |
| 용사 | 견습마도사 고정, 직접 이동 + 기존 자동 무기/레벨업/증강 |
| 마왕 | 슬라임·거미·오크·폭탄쥐·해골궁수, 전장 터치 배치 |
| 전투 | 기존 Battle.tscn·Hero·몬스터·피해/충돌 판정 재사용 |
| 종료 | 용사 사망=마왕 승리,180초 생존=용사 승리, 이탈=상대 승리 |
| 자원 | 지휘력48 시작, 초당12 회복, 활성 몬스터48 상한 |
| 성장 | 개인 연구/수집 성장 미적용, 마왕 증강 자동, 용사 선택8초 후 자동 선택 |
| 계정 | 스테미너/솔로 진행도/골드/연구/랭킹 점수 변동 없음 |
| 진입 해금 | 기존 마왕 쉬움10 + 용사 쉬움10 클리어 조건 유지 |

현재 화면은 상태 검증용 간단한 전장이다. 용사/몬스터 아이콘·HP·기본 투사체 위치를 표시한다. 기존 솔로의 전체 애니메이션·장판·스킬 연출·EXP 오브젝트를 재현하지 않는다. 최종 전투 UI나 밸런스 완료를 뜻하지 않는다.

## 확장 경계

- `src/online/match_rules.gd`: 프로토콜/룰 버전, 콘텐츠 ID, 시간·자원·상한. 버전 불일치 거부.
- `match_queue.gd`: 계정 중복 방지, 반대 역할 FIFO. 이후 MMR/지역/대기시간 가중 매칭으로 교체할 위치.
- `auth_verifier.gd`: Supabase `/auth/v1/user`로 기존 access token 확인. 서버가 확인한 UID 사용. 토큰 URL/파일/로그 저장 없음. service-role 키 불필요.
- `match_server.gd`: 접속·인증·큐·준비·입력 순번/역할/방 검증·결과. 접속24/방8/동시 인증8 제한은 안전 상한이며 처리 성능 보증이 아님.
- `battle_room.gd`: 실제 Battle 어댑터. 별도 World2D/전투 레지스트리. 로컬 command router를 외부에 개방하지 않고 검증된 서버 소환만 전달.
- `match_client.gd`: 이동20Hz·상태10Hz. 이동 입력0.35초 이상 끊기면 정지. 입력8KiB/상태96KiB, 클라이언트당 초당60요청 제한.
- `battle_view.gd`/`match_scene.gd`: 읽기 전용 표시와 입력. 모바일 전장 드래그/PC WASD·방향키, 마왕 터치/클릭 소환. 서버 승패만 사용.
- Battle의 `online_match_mode`: 솔로 저장·성장·상자·보상 차단. 방 간 타깃 검색/일시정지/자석 적용 격리. 솔로 기본값false.

새 룰은 별도 rule ID/version과 룸의 초기화·승패 규칙으로 추가한다. 큐/인증/전송/뷰에 전투 규칙을 붙이지 않는다. 실제 랭킹 도입 시 서버 측 해금 검증, 결과 영수증/중복 방지 트랜잭션, MMR 저장이 추가로 필요하다. 현재 해금 UI는 기존 클라이언트 규칙이며 서버 인증은 계정 확인만 한다.

미구현: 재접속/이탈 유예, 보간·예측·지연 보정, 친구방/초대, 분산 서버/큐 영속화, 전체 VFX 동기화, 시즌/MMR/보상. 서버 재시작 시 진행 경기 복구 없음.

## 서버 배포 준비

Linux x86_64 공용 VM, Docker Compose, 서버를 가리키는 도메인이 필요하다. 정적 웹 호스팅으로는 이 상시 실행 서버를 운영할 수 없다.

1. 전체 저장소와 실제 에셋이 있는 `feature/stage10-astra` 체크아웃을 준비한다. 검사 전용 fixture를 배포하지 않는다.
2. `deploy/match_server/.env.example`을 같은 폴더의 `.env`로 복사하고 MATCH_DOMAIN에 실제 도메인 입력.
3. DNS A레코드를 서버 IP로 지정하고 TCP80/443 개방. 게임 포트24840은 컨테이너 내부에서만 사용한다.
4. 저장소 루트에서 실행:

```sh
docker compose --env-file deploy/match_server/.env -f deploy/match_server/compose.yml up --build -d
docker compose --env-file deploy/match_server/.env -f deploy/match_server/compose.yml logs -f match gateway
```

Godot4.5.1 공식 Linux zip SHA256 고정. Caddy가 TLS를 종료하고 내부 WebSocket으로 전달한다. 일반 사용자로 서버를 실행한다. 기존 Supabase 공개 설정만 사용하며 비밀 키/개인 계정 저장 파일을 넣지 않는다. 전체 에셋 import에 디스크/메모리가 필요하다. Docker/Caddy 실제 빌드·TLS 배포는 이 환경에서 미실행이다.

앱: 로비 → 랭킹 매칭 → 역할 선택 → 매칭 연결 테스트. 두 기기에 같은 `wss://실제도메인`을 입력하고 서로 다른 Google/카카오 계정으로 대기한다. 고정 주소는 `project.godot`의 `[online] match_endpoint`에 설정. 게스트 로컬 계정은 서버 토큰이 없어 참여할 수 없다.

서버만 직접 실행:

```sh
AGAIN_HERO_BIND=127.0.0.1 AGAIN_HERO_PORT=24840 godot --headless --path . --script res://src/online/server_main.gd
```

일반 서버 진입점에는 인증 생략 옵션이 없다. 테스트의 fixture 인증은127.0.0.1 바인딩에만 허용되며 공개 바인딩은 거부한다.

## 검증과 한계

Godot4.5.1 headless. `tools/build_online_fixture.py`는 누락된 시각/오디오만 투명 이미지/무음으로 대체하고 미사용 몬스터 scene preload를 제거한다. 실제 Battle/Hero/선택5종 몬스터의 스탯·이동·충돌·공격·피해·레벨업·소환·승패 코드는 유지한다. GPU/시각/오디오 검증은 아니다.

```sh
python tools/build_online_fixture.py /tmp/again-online-real
godot --headless --editor --import --path /tmp/again-online-real
godot --headless --path /tmp/again-online-real --script res://tests/online_battle_smoke.gd
godot --headless --path /tmp/again-online-real --script res://tests/online_transport_smoke.gd
godot --headless --path /tmp/again-online-real --script res://tests/online_ui_smoke.gd
python tools/run_online_process_smoke.py /absolute/path/to/godot /tmp/again-online-real
```

전투44·WebSocket18·UI14 검사 및 기존 command router134·해금/저장230검사 통과. 별도 서버+용사+마왕3개 OS 프로세스에서 같은 match ID·승자, 양쪽30회 이상 상태 수신 확인. 해당 테스트만 남은 시간을3초로 줄여 실제 타이머 종료 경로를 실행하며 일반 룰180초는 유지한다. 정상 서버 진입/포트 바인딩과 YAML 구조도 확인했다. 환경 정리로 사라진 미커밋 파일을 복구한 뒤 이 검사들을 재실행했다.

미검증: 공용 WSS/TLS 배포, 실제 Google/카카오 토큰 성공 인증을 포함한 외부 인터넷, APK/EXE 두 기기, 원본 에셋 전체 Docker 빌드,180초 완주/승률/다중 방 부하/FPS. 공용 서버 주소 확보 후 진행한다.

참고: [Godot WebSocket](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html), [Supabase getUser](https://supabase.com/docs/reference/javascript/auth-getuser), [Caddy reverse_proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy).
