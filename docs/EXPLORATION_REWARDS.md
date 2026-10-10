# 탐색보상 / 도구 알림

## 현재 적용 규칙

- 왼쪽 순서: 도전과제, 이벤트, 탐색보상. 오른쪽: 친구목록. 도전과제/이벤트의 기존 내부 ID daily/weekly는 호환성을 위해 유지한다.
- 앱 종료 또는 백그라운드/포커스를 잃은 시간만 적립한다. 로비·상점·팀편성·전투 등 앱을 보고 있는 동안은 적립하지 않는다.
- 3분당 1%, 최대 300% = 15시간. 50% 이하는 획득 불가, 완성된 51%부터 획득 가능 = 2시간 33분.
- 1%당 골드 2, 연구포인트 1. 51%는 골드 102/연구 51, 100%는 골드 200/연구 100, 300%는 골드 600/연구 300. 연구의 초기 비용/전투 보상에 도움이 되면서 전투를 대체하지 않는 초기 고정값이다.
- 결과 팝업: 상자, 현재 %/300%와 게이지, 적립 시간 HH:MM:SS, 골드·연구 아이콘 및 +n, 보상 획득 버튼. 준비되지 않거나 저장 실패 시 수령을 차단한다.
- 수령은 현재 완성된 %의 보상 전체를 지급하고 적립량/시간을 초기화한다. 1% 미만 부분도 함께 초기화한다. 상한에 도달한 뒤의 추가 시간은 저장하지 않는다. 첫 설치 시 이전 시간을 소급 지급하지 않는다.
- 상자의 빨간점은 300%에서만 표시하며 수령 성공 시 즉시 해제한다. 51~299% 수령 가능 상태는 빨간점을 표시하지 않는다.

## 구조와 확장

- 수치/아이콘은 `src/data/exploration_reward_catalog.gd`에서 수정한다.
- `src/systems/exploration_reward_store.gd`: 일정 시간마다 루프를 돌리지 않고 O(1) 계산. 기존 stage_progress.cfg에 exploration_rewards 섹션을 추가한다. 골드·연구와 적립량 차감은 같은 ConfigFile 저장에서 처리한다. 계정 bundle 원자 저장/게스트 저장 오류 처리를 기존 AccountSaveScope에 맡기며 스테미너·연구·클리어 데이터는 보존한다.
- `src/systems/exploration_rewards.gd`: 앱 전체 autoload. 중복 focus/pause/resume 알림을 하나의 idle 전환으로 합치며 foreground 60초 체크포인트/종료 시 정확한 anchor를 저장한다. 프레임별 스캔/배열 생성 없음. 로그인 저장이 준비된 뒤 계정별 세션을 초기화하고 같은 계정의 클라우드 revision acknowledgement에는 쓰기를 하지 않아 재동기화 루프를 방지한다.
- `src/ui/lobby_exploration_rewards_view.gd`: 한 번 만든 팝업을 재사용한다. 수령 시 헤더를 갱신하고 탭 전환 시 창을 닫는다. 가로형 920×560 디자인의 CanvasLayer/Control 모달을 전체 게임 뷰포트 중앙에 고정한다. 왼쪽은 상자·게이지·시간, 오른쪽은 보상·획득 버튼. 운영체제/embedded Window 제목줄과 드래그 동작을 사용하지 않는다. 작은 논리 뷰포트에서는 32px 안전 여백을 두고 패널만 균일 축소한다. 루트 게임의 stretch 규칙과 별도 창 스케일이 충돌하지 않는다.
- 공통 알림은 `main_tools_view.set_notification(&"daily", has_unclaimed_rewards)`로 호출한다. 완료 보상을 모두 받으면 false. 이벤트는 &"weekly". 배지는 클릭을 가로채지 않는다. 숨겨진 도구의 알림은 더보기로 전파되고, 더보기 안의 동일 도구도 같은 상태를 사용한다.
- 현재 도전과제/이벤트 완료 판정·보상 시스템은 기존에도 준비 중이었다. 이번 변경은 명칭/아이콘/공통 완료 알림 API까지 제공하며 실제 미션 조건을 임의로 추가하지 않는다. 탐색보상은 실제 지급까지 구현되어 있다.

## 검증과 한계

- Godot 4.5.1 독립 프로젝트에서 `tests/exploration_rewards_smoke.gd` 통과: 초기 생성, online 제외, offline/중복 resume, 50/51% 경계, 300% 상한, 시간 역행, 지갑/기존 섹션 보존, 동일 보상 재수령 금지, 계정 분리, 저장 실패/복구, revision 변경 시 읽기 전용, 팝업 수치/위치, 작은 PC 창 크기·모든 필드 패널 내부·중앙 고정·드래그 불가·Esc 닫기, 알림/수령/탭 정리/더보기.
- 기존 `docs/tests/lobby_tool_trays_check.gd`도 현재 3개 도구에 맞춰 갱신하고 통과. gdparse 및 staged diff --check 확인.
- 독립 테스트 프로젝트는 account_save_scope.gd + 탐색/도구 스크립트와 아이콘만 포함한 fixture로 구성했다. 전체 로비와 전투, 실제 PC 렌더링/Android/iOS 일시정지·강제 종료·온라인 Supabase 동기화는 실행하지 않았다.
- 강제 종료는 종료 알림을 보장하지 않으므로 마지막 foreground 체크포인트 이후 최대 약 60초를 offline으로 간주할 수 있다. 정상 종료/일시정지에는 실제 anchor를 저장한다. 백그라운드 저장 자체가 실패한 경우에는 오류가 복구될 때 재시도하며 완벽한 앱 종료 시각 복원은 보장하지 않는다.
- 현 프로젝트의 기존 클라이언트 저장 모델을 사용하므로 기기 시간 조작/여러 기기의 동시 플레이를 서버가 검증하는 보상 ledger는 없다. 기기 시간 역행의 중복 적립은 차단한다. 출시 전 서버 시각과 원자 수령 RPC를 추가할 수 있으나 이번에 DB 스키마/정책/RPC를 변경하거나 배포하지 않았다. 기존 snapshot SQL은 stage_progress.cfg 안의 JSON 섹션을 수용한다.
- 생명주기 참고: https://docs.godotengine.org/en/stable/classes/class_node.html (APPLICATION_FOCUS_IN/OUT, PAUSED/RESUMED), 저장 형식 참고: https://supabase.com/docs/guides/database/json 및 현재 저장소 snapshot migration. 계정 bundle 직렬화/원자 저장은 독립 테스트로 확인했으며 실제 서버 테스트와 구분한다.

## 리소스

- 상자: 내장 image_gen으로 생성한 투명 PNG. 원본은 docs/resources/exploration_reward_source.zip. 게임용은 alpha 경계 crop 후 nearest-neighbor로 112×112에 fit, 128×128 투명 캔버스 중앙 배치.
- 알림: 24×24 notification_dot.svg. 정수 좌표와 crispEdges로 작은 빨간 도트/테두리/하이라이트를 구성한 코드 기반 벡터 리소스. 배지 TextureRect는 nearest, mouse_filter IGNORE.
- 팝업은 해상도에 맞는 Godot 기본 패널/StyleBoxFlat/ProgressBar를 사용하여 글자·게이지를 이미지에 굽지 않는다. 통화 아이콘은 기존 리소스를 공유한다.
