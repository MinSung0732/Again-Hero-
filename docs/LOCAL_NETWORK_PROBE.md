# 로컬 서버·두 클라이언트 전투 통신 시제품

2026-10-10. 기준 feature `10e37e61bf0d350930e18362034b4b09d66ca493`, main `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 확인. 작업 브랜치 `feature/stage10-astra`.

## 이번 결과와 현재 단계

`tools/network_probe/`에 독립 Godot 프로젝트를 추가했다. 기존 로비·입장·솔플·전투 Catalog·Hero·몬스터 코드는 수정하지 않았다. `.gdignore`로 상위 게임의 리소스 스캔과 분리한다.

첫 접속자는 용사, 두 번째는 마왕으로 서버가 배정한다. 용사는 이동·범위 공격, 마왕은 몬스터 소환을 요청한다. 서버가 이동 속도·맵 경계·소환 금지 거리·마력·인원 제한·공격 쿨타임·HP·승패를 판정하고, 두 클라이언트는 수신한 상태를 표시한다. 테스트용 원형 유닛과 규칙이며 실제 게임 캐릭터·스킬·성장 시스템은 연결하지 않았다.

이 시제품은 기존 공통 전투 계약 작업과 병행하는 전송 검증 단계다. 일반 몬스터 전체의 receipt 적용, Hero/초월 부활, 기존 전투의 서버화는 여전히 남아 있다. 기존 command router는 로컬 실행만 허용하므로 네트워크 패킷을 넣도록 gate를 풀지 않았다. 기존 Node instance ID나 registry handle도 wire ID로 사용하지 않았다.

## 파일 책임

| 파일 | 책임 |
|---|---|
| rules.gd | 시제품 전용 수치·프로토콜 한도 |
| world.gd | 서버 판정, 고정 8칸 몬스터 풀, 슬롯 generation |
| wire.gd | 숫자만 있는 고정 패킷 encode/검증/decode |
| connection.gd | ENet 수신·peer→역할 배정·순서 검증·상태 전송 |
| client.gd / main.tscn | 테스트 접속 버튼·입력·상태 표시 / 서버 실행 진입 |
| tests/unit.gd | 규칙·패킷·수명 경계 검사 |
| tests/peer.gd / run_loopback.py | 실제 3개 프로세스 통신 및 최종 상태 비교 |

## 실행 방법

Godot 실행 파일을 아래의 `godot` 대신 지정한다. 저장소 루트에서 서버 터미널 하나와 클라이언트 창 두 개를 연다.

```bash
# 터미널 1: 로컬 전용 서버
 godot --headless --path tools/network_probe -- --server
# 터미널 2와 3: 각각 실행 후 접속 버튼 클릭
 godot --path tools/network_probe
```

첫 창 접속 → 용사, 다음 창 접속 → 마왕. 용사는 WASD/방향키 이동, Space 공격. 마왕은 전장 마우스 왼쪽 클릭으로 소환한다. 용사가 6마리를 처치하면 용사 승리, 용사 HP0이면 마왕 승리다. 어느 쪽이든 진행 중 연결을 끊으면 중단 결과가 된다. 종료된 승패는 연결 끊김으로 덮어쓰지 않는다. 새 경기는 서버를 종료하고 다시 실행한다. 본 게임 던전입장 버튼에 온라인 UI를 추가하지 않았다.

## 전송·수명 계약

- ENet 서버는 `127.0.0.1:24731`에만 bind한다. 클라이언트 주소도 loopback 고정. 계정 인증 전 개발용이며 인터넷/LAN 매칭 서버가 아니다.
- 한 서버 프로세스당 한 경기·최대 두 연결. 클라이언트는 role/peer/entity ID, 피해량, 자원, 체력을 입력 패킷에 넣지 않는다. 실제 송신 peer로 서버 슬롯을 찾는다.
- server-run epoch는 양수 random 값이다. 인증 티켓·전역 match UUID는 아니다. 두 역할이 연결되면 시작하고 새 연결을 거절한다. 재접속 복구는 미구현.
- 입력은 24 bytes, 상태는 176 bytes. magic/version/epoch/sequence/kind/범위 검사 후만 규칙 실행. 입력에 Godot Object/Variant/NodePath deserialization 없음. gameplay 실패도 sequence를 소비해 나중에 마력/쿨타임이 회복되어 같은 입력이 실행되는 것을 막는다.
- 서버는 60Hz step, 상태는 20Hz. 입력 channel0은 reliable, 상태 channel1은 unreliable ordered. 이동은 20Hz 의도 벡터이며 좌표를 직접 보내지 않는다. 입력이 12 tick 동안 갱신되지 않으면 정지한다.
- 수신 처리량은 tick당64패킷, 역할당8입력으로 제한. 종료/대기 상태에서 규칙 실행 없음. 서버 snapshot은 각 수신자 role만 다르게 담는다. 클라이언트는 서버 peer1의 channel1만 읽는다.
- 클라이언트는 전체 패킷 크기·헤더·모든 개체 필드를 먼저 검증한 뒤 view를 갱신한다. epoch 불일치/이전 tick/비정상 수치를 거절한다. hero id는 이 테스트에서 암묵적으로1, 몬스터는 고정 슬롯+generation이다.

## 성능 범위

몬스터 스탯/위치/generation/쿨타임 배열은 시작 때8칸 할당 후 재사용한다. step에 새 Array/Dictionary/Node/스폰 씬/전체 그룹 스캔/개체 쌍 비교 없음. 입력·상태 송신 buffer도 재사용한다. 수신 패킷 객체와 ENet 내부 할당은 전송 라이브러리 경계에서 발생하므로 무할당 네트워크라고 주장하지 않는다.

8개 대상의 고정 순회와 full snapshot은 최소 시제품에만 적용된다. 수백 몬스터의 실전에서는 기존 공간 그리드·registry·풀과 변경 목록을 활용할 계획이다. 이 단순 pool을 본 게임의 충돌/AI/초월 행동 대신 사용하지 않는다. 페이로드 계산상 상태는 수신자당176×20=3,520bytes/s이며 ENet/UDP overhead·실제 대역폭·모바일 성능은 측정하지 않았다.

## 검증 결과

Godot4.5.1에서 독립 프로젝트 editor import와 실행을 수행했다. gdparse, Python source compile, staged diff 검사를 통과했다.

- `unit.gd`: **144검사 실패0**. 역할/명령, 세션·중복·sequence 상한, 정확한 크기, 좌표·finite·대각 속도·입력 만료, 대기·마력·소환 제한·고정 풀·generation 재사용, 피해·쿨타임·처치, malformed snapshot 필드·과거 상태 거절, 종료 gate, 마왕 승리, disconnect handler·결과 보존·close 초기화.
- `run_loopback.py`: 서버1개+클라이언트2개를 별도 OS 프로세스로 실행. 연결/역할 배정 완료를 관측하고 다음 클라이언트를 시작해 순서를 확인. 실제 remote 입력으로 이동·소환·공격·피해·처치·승패·잘못된 역할과 이동 범위 초과 거절 확인. 최종 전체176bytes(수신자 role만0으로 정규화)가 서버·용사·마왕에서 정확히 같음을 확인.
- 최종 통신 실행: 동일 epoch `1649242052`, 종료 tick124, 용사 승리, 6처치. 용사52·마왕48 snapshots 수신, server18입력 거절(악성 인자·역할 및 정상 공격의 쿨타임 거절 포함). 이 숫자는 실행 타이밍에 따라 달라진다.
- 실제 main scene의 headless 서버 실행도 `PROBE_SERVER 0`으로 시작하고 정상 종료했다.

GUI 조작/그림 배치·전체 게임Godot4.7·모바일·실제 본게임 충돌/스킬·인터넷 지연/손실·부하·악의적 네트워크 flood·실제 disconnect 전송·재접속은 검증하지 않았다. disconnect 판정은 unit에서 실제 handler를 실행한 범위다.

```bash
 godot --headless --path tools/network_probe --script res://tests/unit.gd
 python3 tools/network_probe/tests/run_loopback.py /path/to/godot
```

## 아직 남은 작업과 다음 순서

1. 입력 tick/ACK·유효 시간·독립 이동/액션 sequence 채널, 늦게 도착한 입력·손실·중복의 정책을 추가한다. 현재 reliable 이동은 혼잡 시 지연 입력이 남을 수 있으므로 운영용 예측·보정 프로토콜이 아니다.
2. 신뢰된 서버 슬롯을 기존 전투 세션 구성·Hero action 경계·마왕 명령에 연결할 adapter를 설계하고, 기존 전투의 서버 tick/표시 분리를 한 경로씩 적용한다. 이번 toy world를 실제 게임에 복사해 기능을 단순화하지 않는다.
3. 기존 몬스터/투사체/상태이상·부활/성장·증강을 서버 판정과 상태 표현으로 확대한다. UI 컷신/선택창이 서버를 일시정지시키지 않도록 분리한다.
4. client interpolation/로컬 용사 예측·보정, 기준 snapshot/재접속, 서버 결과 확정을 검증한다.
5. 이후 계정 인증 티켓·매치 배정·온라인 방·랭크 결과 저장·운영 서버를 붙인다. 현재 자동 매칭·공개 PvP는 불가다.

롤백은 이 커밋 revert 또는 독립 시제품 실행 중단이다. 본 게임의 runtime 수정이 없어 솔플/저장 데이터 migration은 없다. main은 유지한다.

API 확인: [Godot4.5 ENetMultiplayerPeer](https://docs.godotengine.org/en/4.5/classes/class_enetmultiplayerpeer.html), [MultiplayerPeer](https://docs.godotengine.org/en/4.5/classes/class_multiplayerpeer.html). 공식 API의 bind/생성/poll·packet/채널·전송 모드에 근거하고 실제 loopback 실행으로 구현을 검증했다.
