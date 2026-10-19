# localtest 모드 온라인 연결 테스트

## 범위

- 시작 로컬/원격 feature/stage10-astra: `eac81f385f02806c31700d23d3745244b979247e`, 작업 트리 clean. main: `6f22053f462e1176ec2ecde131d589d5491791b2`. main 병합 없음.
- localtest 쿠폰은 실제 계정 토큰을 비우는 격리 저장 모드다. 기존 랭킹 해금 override는 이미 있었으나 온라인 화면의 Google/카카오 토큰 검사 때문에 매칭하지 못했다.
- LocalTestMode의 온라인 권한은 기존 전체 용사 테스트 해금과 같은 검사를 사용한다. 쿠폰 허용 빌드, active, tutorial_preview=false, 실제 계정 UID 없음, 격리 test_directory가 모두 필요하다. normaltest/튜토리얼 프리뷰/일반 게스트/실제 계정은 이 권한을 사용하지 않는다.
- 온라인 전용 임시 ID로 참가하며 계정/보상/진행 저장을 추가하지 않는다. 기존 견습마도사/5몬스터/180초/무보상 룰, 실제 전투, 일반 계정 검증 경로는 그대로다.

## 사용 순서 (Windows PowerShell)

1. PC/모바일 모두 브랜치를 최신화하고 실행 중인 게임을 종료한다. 현재 Godot 서버 프로세스도 종료한다. Windows GUI exe로 실행해 터미널에 프롬프트가 돌아왔더라도 프로세스가 살아 있을 수 있다. 기존 서버를 실행한 창에서 중지할 수 없으면 작업 관리자에서 **기존 headless 서버에 해당하는 Godot 프로세스만** 종료한다.
2. PC에서 서버 명령 맨 뒤에 `-- --localtest`를 붙여 다시 실행한다. 아래 두 경로는 실제 Godot exe와 project.godot이 있는 폴더로 바꾼다.

```powershell
& "고닷실행파일전체경로" --headless --path "게임폴더전체경로" --script res://src/online/server_main.gd -- --localtest
```

3. `AGAIN_HERO_MATCH_SERVER ready port=24840` 뒤의 `LOCALTEST invitation code:`에 표시된 48자리 코드를 복사한다. 실행할 때마다 새로운 무작위 코드다. 바인딩 기본값 127.0.0.1을 유지한다.
4. 기존 Cloudflare 터널은 같은 포트로 연결하므로 그대로 사용할 수 있다. 터널을 재실행했다면 새 주소를 사용한다. 서버를 재시작하기 전에 진행 중이던 연결은 유지되지 않는다.
5. 두 게임에서 localtest 쿠폰을 적용하고 랭킹 매칭 연결 테스트로 들어간다. 서로 다른 역할(용사/마왕)을 선택한다.
6. 같은 `wss://...` 주소와 같은 입장코드를 입력하고 양쪽에서 매칭 시작을 누른다. 별도 Google/카카오 계정 없이 기기별 무작위 접속 ID로 참가한다. 입력한 코드는 접속 시 입력칸에서 지워지며 저장하지 않는다. 다시 연결하려면 코드를 다시 입력한다.
7. 일반 서버로 돌아가려면 서버를 종료하고 `-- --localtest` 없이 실행한다. 게임은 normaltest로 로컬 테스트를 종료하고 일반 계정으로 로그인한다.

## 인증과 수명

- `local_test_access.gd`에 코드/ID 형식과 생성·검증을 모았다. 입장코드는 Crypto 24바이트(48 hex), 접속 ID는 Crypto 16바이트(32 hex)다. 고정 localtest 비밀번호/fixture 토큰/계정 ID를 클라이언트에 넣지 않았다.
- 기본 서버는 테스트 입장을 받지 않는다. 서버 명시 옵션과 올바른 코드가 동시에 있어야 한다. invitation 서버는 loopback bind만 허용하며, Cloudflare 같은 명시적 중계로 연결한다. 기존 fixture_auth와 혼용하거나 공개 인터페이스 바인딩으로 켜면 시작을 거부한다.
- 같은 코드를 가진 참가자에게 연결 테스트 권한을 부여하는 방식이다. 서버는 상대 기기의 localtest 쿠폰/저장 상태를 원격 증명하지 않는다. 클라이언트 쿠폰만 신뢰해 인증을 우회하지 않으며, 코드 소유자가 테스트 참가자다. 코드가 알려지면 재시작해 폐기한다. 코드/로그 전체를 공개 저장소에 올리지 않는다.
- join의 선택적 `local_test` payload를 검증하고 일반 JWT와 동시에 보내면 거부한다. 기존 프로토콜 v1/일반 계정 join 형식은 바꾸지 않았다. 코드/세션은 게임 URL이나 계정 파일에 저장하지 않는다. handshake 후 클라이언트 임시 코드와 토큰을 지운다. 서버 코드 출력은 운영자가 참가자에게 전달하기 위한 명시적 1회 출력이다.
- 동일 접속 ID 중복은 기존 중복 계정 규칙으로 차단한다. 별도 클라이언트는 서로 다른 임시 ID를 가진다. 동일 클라이언트의 재시도에서는 ID를 유지한다. 테스트 모드/계정 전환 시 UI가 재검사해 연결을 닫고 로비 재입장을 요구한다.
- 보상/계정 저장/클라우드·AI/전투 수치·project.godot 변경 없음. 추가 조회는 모드의 O(1) 권한 검사이며 프레임 배열 생성/그룹 스캔을 추가하지 않는다.

## 검증

- Godot 4.5.1 headless에서 새 초대 인증/실제 WebSocket+Battle **32검사**, UI/권한 **31검사**, 기존 실제 전투 **44검사**와 transport **18검사**, 합계 **125검사 PASS**. 수정한 소스 그대로 사용하며 온라인 fixture의 누락 아트/오디오는 대체 리소스다.
- 일반 서버의 테스트 코드 거부, 명시 옵션·코드 형식·오답/재시작 코드 거부, 공개 bind/fixture 혼용 거부, 일반 계정 verifier 위임, 두 임시 ID·동일 ID 중복 방지, 매칭/ready/이동/소환/양쪽 결과1회·무랭킹 확인. 일반 계정 성공 인증 검사에는 verifier 응답 어댑터를 사용했고 실제 OAuth 성공을 검증한 것은 아니다.
- 실제 server_main 진입점 두 번을 별도 프로세스로 실행해 기본 코드 미출력/옵션 지정 시 48자리 코드 출력을 확인했다. 기존 서버+용사+마왕 3프로세스 회귀에서 동일 match/winner, 양쪽 상태31회 수신 PASS. 이 회귀는 기존 loopback fixture 인증이다.
- 새 localtest 전투 실행 ERROR 0, 누락된 presentation의 의도된 경고50건. UI ERROR/WARNING 0. 최초 신규 이미지 import 전에는 로더 오류가 발생했으며 리소스 import 후 최종 import ERROR/WARNING 0 확인. Python AST·git diff --check 통과.
- fixture builder는 상수로 간접 preload하는 literal texture 경로와 공백/개행 preload도 포함한다. sparse checkout의 누락된 비시각 descriptor는 git HEAD의 원본 bytes만 사용한다. 게임 설정/기술을 임의로 대체하지 않는다.
- PC Godot4.7.2/Android 실기, 실제 Cloudflare WSS 경유 두 기기·패킷 지연/중단, 전체 PNG/음원·GPU/FPS, 실제 계정 OAuth/랭킹은 미검증이다.

```sh
python tools/build_online_fixture.py /tmp/again-online-localtest
godot --headless --editor --import --path /tmp/again-online-localtest
godot --headless --path /tmp/again-online-localtest --script res://tests/online_local_test_smoke.gd
godot --headless --path /tmp/again-online-localtest --script res://tests/online_ui_smoke.gd
godot --headless --path /tmp/again-online-localtest --script res://tests/online_battle_smoke.gd
godot --headless --path /tmp/again-online-localtest --script res://tests/online_transport_smoke.gd
python tools/run_online_process_smoke.py /absolute/path/to/godot /tmp/again-online-localtest
```
