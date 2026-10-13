# 용사 모드 — AI 마왕 생존 도전 (2026-10-13)

## 이번 구현

기존 쉬움 Stage10 클리어 후 용사 모드 개방 조건을 유지한다. 로비 용사 선택으로 실제 별도 HeroMode 씬에 입장한다. 현재 해금된1~10단계 캐릭터를 선택하며 기존 도트·고유 공격/기술·피해·EXP·성장 판정을 재사용한다.

- 이동: 왼쪽 터치 패드, PC WASD/방향키. 공격·고유 기술 자동, 레벨업 증강 직접3개 중 선택.
- 목표: AI 마왕의180초 공세 생존. 사망은 용사 패배, 시간 생존은 용사 승리. 마왕 캠페인의 클리어·확정 몬스터 해금·전투기여 보상으로 처리하지 않는다.
- 카메라: 항상 용사 추적. 설정 체크박스는 활성 고정·disabled, Hero.set_camera_view_locked도 player_controlled면false를 거부하고 pan API도 차단. 기존 마왕 카메라 설정 파일을 쓰지 않는다.
- 로비: 캐릭 편성 / 스킬 편성(시작 증강2개), 용사상점 준비중, 성장. 청색·청록·금색 배경/패널/탭으로 전환하고 마왕 선택 시 기존 UI/배경/명칭 복원.
- 캐릭/성장: 원본 캐릭터마다 시작 증강2개와 생명력/전투숙련 각각10단계. 고유 기술 선택적 장착이 아니라 기존 증강을Lv1에 적용하는 시작 스킬 편성임을 UI에 표시한다. 용사 성장에 기존 연구 포인트 사용, 단계비용200×(현재단계+1), HP2%/공격1%씩. 기존 마왕 연구와 몬스터강화는 AI 군단에 적용하지 않는다.
- 입장: 기존 스테미너5/입장 영수증·테스트 면제, 30초 실제 경과시간(일시정지/수면 포함) 내 로비 복귀4환급. 입장 claim 실패 시 인계된 원본 티켓으로 전체 환급 시도. 재도전은 새입장 기록을 발급한다.

AI 마왕은 일반 소환의 지휘력 비용/재생·소환EXP·마왕 증강·엘리트/돌연변이 시간표를 사용한다. 별도 마왕 감독은0.75초 간격 행동/4초 간격 실제 용사 증강태그 관측, 슬라임/거미/오크→폭탄쥐/해골궁수/유령을 시간에 따라 확대하고 관측 대응과55%확률/순환 탐색을 섞는다. 동시 직접소환은28기까지 시도한다(기존 스테이지 증원/분열 개체와 별도). 완벽한 조준·입력 읽기·매프레임 그룹 스캔은 추가하지 않는다. 실제 승률·난이도는 미측정이다.

기절/공포/매혹/석화/채널링과 고유 기술 강제이동은 기존 상태 판정을 유지한다. 상태 처리 이후의 정상 이동만 플레이어 입력으로 바꾸며, 기존 자동방향 장애물 회피는 플레이어에게 강제하지 않는다. 방향키와 터치의 입력 크기를1로 제한하고 비유한 벡터를 거부한다. 터치ID 소유권/화면 밖 드래그·release/포커스 상실 때 입력을 초기화한다. 증강창이 열리는 release로 선택되지 않도록0.25초 버튼 잠금 및 세대 토큰을 사용한다. 한 EXP 묶음의 다중레벨업은 첫 선택까지 정지하고 이후 선택을 순차 처리한다.

## 저장·보상

AccountSaveScope의 기존 team_loadout.cfg에 hero_loadout/hero_growth/hero_progress 별도 section을 추가한다. 마왕 monster_ids/스킬 파일을 덮어쓰지 않는다. 성장 구매는 stage_progress.cfg 통화 차감과 team_loadout.cfg 성장을 한 save_configs 트랜잭션으로 저장한다. 새 저장파일/서버테이블/RPC/SQL migration은 추가하지 않는다.

승리 연구20/골드12. 실패·중단은30초 이상/실제 몬스터 사망1기 이상이면 연구5/골드3, 아니면0. 현재 계정/입장serial/claim/스테이지를 확인하고 hero_progress.last_reward_entry로 중복 지급을 차단한다. 성장·보상·기록 저장 실패는 진행 전에 다시 시도한다. 계정 변경 시 전투 정지·로비 복귀 안내, 다른 계정으로 원래 티켓을 정산하지 않는다. 원래 마왕 스테이지 클리어 보상은 별도로 유지한다. 로컬 JSON bundle 스키마의 기존 허용 파일/일반 section 구조를 사용하지만 실제 클라우드 왕복 검증은 이번 환경에서 하지 못했다.

## 아트

assets/art/UI/hero_mode/hero_guild_lobby.png: 새 이미지 생성 도구로 만든 푸른 깃발/새벽의 성채 길드 홀. 캐릭터·글자/UI를 포함하지 않는다. 원본 PNG 그대로 저장, Godot TextureRect cover/nearest. 원본 도트 캐릭터는 변경하지 않았다.

생성 프롬프트: portrait9:16 production pixel-art mobile game lobby, peaceful heroic stone castle guild hall at dawn, navy/teal shadows and pale gold lighting, blue banners, sharp pixel clusters/stepped outlines, calm low-detail dark-blue central70% for UI, empty environment, no characters/monsters/text/UI/logo/watermark. Built-in image generation을 사용했다.

## 검증과 남은 확인

- 변경 GDScript11개 gdtoolkit 구문 검사·diff 검사, 카메라 API/모드경계/티켓/캐시·리소스 링크 정적 확인. PNG 이미지 육안 확인.
- tests/hero_player_mode_smoke.gd: 캐릭/시작증강/중복·범위/기존마왕편성 보존, 성장가격/캐릭분리, 입장영수증/승리시간/중복보상/소유자, 입력길이·비유한입력, 수동레벨업/후보검증/이중선택, 카메라해제 차단, 게스트격리 회귀 assertion을 추가했다.
- 이 환경에 Godot 실행파일이 없어 테스트 스크립트·실제 전투·UI·BGM·Android를 실행하지 않았다. gdparse는 엔진 컴파일/런타임 검증이 아니다. 현재 기능은 코드 구현 완료/실플레이 검증 전이다.

다음 실제 실행 명령:

```sh
godot --headless --path . --script res://tests/hero_player_mode_smoke.gd
godot --headless --path . --script res://tests/campaign_experience_smoke.gd
godot --headless --path . --script res://tests/campaign_hud_smoke.gd
```

추가로PC/Android에서 용사모드 전환→캐릭/스킬편성→성장→입장→첫소환/직접이동→레벨업선택→멈춤/복귀→죽음/180초생존→보상→재도전→로비·마왕복원 흐름을 확인해야 한다. 모든10종의 고유공격 이동, melee stationary 분기, 상태이상·멀티터치, 화면비/폰트·BGM, 장기성능·클라우드 저장이 미검증이다. 실플레이 전 출시 품질/밸런스를 보장하지 않는다.

롤백: 이번 커밋 revert. 지급된 보상·성장 section은 자동회수하지 않는다. 마왕 저장경로는 보존한다.
