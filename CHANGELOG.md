# CHANGELOG

이 파일은 **「용사, 또 너야? / Again, Hero?」** 프로젝트의 기능 추가, 패치, 개선, 제거, 밸런스 변경을 기록한다.

앞으로 저장소에 의미 있는 변경을 할 때마다 이 문서를 함께 갱신한다.

---

## 2026-09-20

### Project Bootstrap
- Godot 4.x 프로젝트 기본 구조 생성.
- Android 우선 모바일 프로젝트로 시작.
- `README.md`, `PROJECT_CONTEXT.md`, `AGENTS.md`, GDD, ROADMAP 추가.
- 초기 메인 씬 및 플레이스홀더 전투 화면 추가.

### Milestone 1 — 최소 자동전투
- Hero 자동 이동, 가장 가까운 적 탐색, 자동 공격 추가.
- Slime 추적, 공격, HP, 사망 처리 추가.
- Hero/Slime HP바 및 간단한 코드 기반 플레이스홀더 그래픽 추가.
- Hero 1명 vs Slime 6마리 자동전투 추가.
- 전투 승패 판정, 결과창, "다시 실험하기" 버튼 추가.
- Android Godot Editor 실기기에서 정상 동작 확인.

### Portrait 전용 전환
- 프로젝트 기준 해상도를 1080×1920으로 변경.
- Android Portrait 고정.
- 가로 회전 미지원으로 방향 확정.
- 전장, 상단 HUD, 하단 상태영역, 결과창을 세로 화면 기준으로 재배치.
- Android 실기기에서 세로 레이아웃 정상 동작 확인.

### Milestone 2 — Hero EXP / Level (초기)
- Slime에 EXP 보상값 추가.
- Slime 처치 시 Hero가 EXP를 획득하도록 추가.
- Hero Level / EXP / 다음 레벨 필요 EXP 추가.
- 레벨업 시 임시 성장 효과 추가:
  - 공격력 +3
  - 최대 HP +10
  - 현재 HP +10 회복
- 레벨업 시 간단한 시각 효과 추가.
- 상단 HUD에 Hero Lv, EXP 수치, EXP Bar 추가.
- 다음 단계에서 레벨업 3택 AI 증강 선택 시스템으로 확장 예정.

### Design Decision — 마왕 증강
- 마왕도 Run 안에서 3개 증강 중 1개를 선택하는 구조를 채택.
- 증강은 용사의 매 레벨업과 동일한 방식이 아니라 특정 전황/기믹 시점에 발생하도록 설계.
- 증강 선택지 새로고침은 **Run당 총 3회 공유**.
- 새로고침 시 현재 3개 후보를 모두 교체.
- 직전 새로고침에서 버린 후보가 즉시 동일하게 재등장하는 것은 방지하는 방향.
- 마왕 증강은 Run 종료 시 초기화되고, 영구 연구/내실과 분리.
- 증강은 단순 수치 증가보다 몬스터 조합/지휘/AI 유도를 변화시키는 효과를 우선.

### Development Process
- 앞으로 기능 추가, 패치, 개선, 제거, 밸런스 변경마다 `CHANGELOG.md` 기록을 필수로 남기는 규칙 추가.


## 2026-09-21

### Milestone 2 완료 — Hero 3택 증강
- Hero 레벨업 시 증강 후보 3개를 생성하도록 추가.
- Hero 증강 카탈로그를 `src/data/hero_augment_catalog.gd`로 분리.
- 초기 증강 6종 추가:
  - 검술 단련: 공격력 +8
  - 속공: 공격속도 +12%
  - 강인한 육체: 최대 HP +45 및 HP +45
  - 추격 본능: 이동속도 +25
  - 긴 사거리: 공격 사거리 +20
  - 전투 회복: HP 90 회복
- 기존 레벨업 시 자동 공격력/HP 증가를 제거하고 증강 효과로 대체.
- 같은 증강은 이후 레벨업에서 다시 선택되어 중첩될 수 있도록 구성.

### Build AI v0
- `src/ai/hero_build_ai.gd` 추가.
- AI가 3개 후보의 기본 선호도에 작은 랜덤값을 더해 1개를 자동 선택.
- 아직 몬스터 구성이나 전황은 읽지 않으며, 다음 단계에서 Utility AI로 확장 예정.
- 하단 UI에 레벨업 후보 3개, AI 선택 결과, 선택 이유 표시.
- 현재까지 선택된 용사 빌드 요약 표시 추가.


### Build AI v1 — 전황 기반 Utility AI
- Hero가 레벨업할 때 현재 전투 상황을 분석하도록 변경.
- AI 판단 컨텍스트에 다음 정보를 추가:
  - 주변 320px 내 몬스터 수
  - 전체 생존 몬스터 수
  - 현재 Hero HP 비율
  - 가장 가까운 몬스터 거리
  - 이미 선택한 동일 증강의 중첩 수
- 증강마다 상황별 Utility 보정을 추가:
  - 적이 많이 붙으면 `속공` 선호 상승
  - HP가 낮으면 `강인한 육체`, `전투 회복` 선호 상승
  - 적이 멀면 `추격 본능`, `긴 사거리` 선호 상승
  - 적이 적고 HP가 안정적이면 `검술 단련` 선호 상승
- 동일 증강을 이미 보유하면 소폭의 빌드 관성 보너스를 적용.
- 완전히 결정적인 AI가 되지 않도록 작은 랜덤값은 유지.
- 선택 로그에 실제 판단 이유와 최종 Utility 점수를 표시.
- 마지막 몬스터 처치 직후 레벨업 시 잘못된 거리값이 들어가지 않도록 보정.


### Monster Archetypes + Type-aware Build AI
- Slime에 `monster_type=slime`, `monster_role=swarm` 메타데이터 추가.
- Spider 전투 프로토타입 추가:
  - 역할: controller
  - HP 45 / 이동속도 150 / 공격력 5 / EXP 30
  - 공격 적중 시 Hero 이동속도를 1.5초 동안 72%로 둔화.
  - 보라색 거미 플레이스홀더 그래픽 추가.
- Orc 전투 프로토타입 추가:
  - 역할: tank
  - HP 140 / 이동속도 78 / 공격력 18 / EXP 40
  - 갈색 대형 오크 플레이스홀더 그래픽 추가.
- Hero에 일시적 이동속도 둔화 상태를 추가하고 화면에서 보라색 링으로 표시.
- 기존 Slime 6마리 고정 테스트를 3종 랜덤 테스트 웨이브로 교체:
  - 물량형: Slime 4 / Spider 1 / Orc 1
  - 제어형: Slime 2 / Spider 3 / Orc 1
  - 탱커형: Slime 2 / Spider 1 / Orc 3
- 재시작할 때 테스트 웨이브가 다시 선택되도록 변경.
- Build AI가 Slime / Spider / Orc 타입 비율과 swarm / controller / tank 역할 비율을 읽도록 확장.
- Slime 비중이 높으면 속공, Orc 비중이 높으면 검술/생존, Spider 비중이 높으면 추격/사거리 계열의 Utility 점수가 상승하도록 추가.
- AI 선택 이유 로그에 실제 몬스터 비율 기반 설명이 표시되도록 개선.
- 상단 표기를 `슬라임 N`에서 `몬스터 N`으로 변경하고, 하단에 현재 테스트 웨이브 구성을 표시.
- 혼합 웨이브 난이도 조정을 위해 Orc 초기 수치를 HP 160→140, 공격력 22→18, EXP 45→40으로 조정.


### Milestone 4 v1 — 마왕 직접 소환
- 기존 자동 랜덤 테스트 웨이브를 제거하고 플레이어 직접 소환 방식으로 전환.
- 전투 시작 시 자동 몬스터를 생성하지 않으며 Hero만 중앙에서 시작하도록 변경.
- 마왕 지휘력 자원 추가:
  - 최대 100
  - 시작 60
  - 초당 3 자동 회복
- 몬스터 소환 비용 적용:
  - Slime 3
  - Spider 7
  - Orc 18
- 하단 모바일 UI에 지휘력 수치/게이지 및 Slime / Spider / Orc 소환 버튼 추가.
- 지휘력이 비용보다 부족하면 해당 소환 버튼을 자동 비활성화.
- 터치 버튼으로 몬스터를 즉시 소환할 수 있도록 연결.
- 현재 스폰 위치는 전장 가장자리 6개 후보 중 자동 선택하며, 겹침을 줄이기 위해 작은 랜덤 오프셋을 적용.
- 몬스터가 전멸해도 Run이 종료되지 않도록 변경. 지휘력 회복 후 다음 공세를 계속 보낼 수 있음.
- 플레이어가 직접 만든 몬스터 구성은 Hero Build AI의 Slime / Spider / Orc 비율 및 역할 분석에 그대로 사용.
- 세로 UI 공간 확보를 위해 전투 영역 높이를 1360→1280으로 조정하고 하단 조작 패널을 360px로 확장.
- 다음 단계에서는 자동 스폰 위치를 제거하고 플레이어가 직접 배치 위치를 선택하도록 확장 예정.


### Ranged Hero v1 + Command Start Balance
- 마왕 시작 지휘력을 60→0으로 변경.
- Run 시작 시 지휘력을 모은 뒤 첫 공세를 시작하도록 템포를 변경.
- 기존 Hero의 즉시 근접 타격 방식을 제거하고 **원거리 투사체 공격**으로 전환.
- `HeroProjectile.tscn` / `hero_projectile.gd` 추가.
- 투사체에 실제 이동속도와 최대 이동 사거리 적용:
  - 초기 투사체 속도 680
  - 초기 공격/투사체 사거리 430
  - 최대 사거리 도달 시 투사체 소멸
  - 몬스터 충돌 시 피해를 주고 소멸
- Hero 이동 AI를 단순 추적에서 카이팅형으로 변경:
  - 가까운 몬스터에서 이탈
  - 공격 사거리 밖이면 접근
  - 안전 거리에서는 측면 이동하며 계속 자동 사격
  - 전장 밖으로 이탈하지 않도록 위치 제한
- 기존 검/근접 느낌의 플레이스홀더 표현을 지팡이 + 발광 탄환 표현으로 변경.
- 원거리 Hero에 맞춰 증강명을 정리:
  - 검술 단련 → 탄환 강화
  - 속공 → 연사 강화
  - 추격 본능 → 민첩한 발놀림
  - 긴 사거리 → 사거리 확장
- 사거리 확장 효과를 +20→+35로 조정.
- 현재 기본 Hero는 원거리 카이팅형으로 유지하고, **근접 공격 Hero는 추후 별도 아키타입**으로 추가하기로 결정.


### Design Decision — Stage별 용사 / 챕터형 진행
- 장기 진행 구조를 하나의 Hero를 무한히 상대하는 방식이 아니라 **Stage/Chapter 진행형**으로 설계하기로 결정.
- 각 Stage는 특정 Hero 또는 특정 Hero 세팅을 상대하도록 구성.
- Stage가 상승할수록 Hero의 기본 스탯, AI 성향, 시작 무기/기믹, 증강 풀 등을 변경할 수 있도록 설계.
- 현재 원거리 카이팅 Hero를 Stage 1의 초급 Hero로 사용하는 방향.
- 이후 Stage에는 연사/기동 특화 원거리 Hero, 근접 전사형 Hero 등 다른 아키타입을 순차적으로 배치.
- 플레이어가 연구/내실을 쌓으면 이미 클리어한 초반 Stage는 점차 쉽게 압도할 수 있도록 허용.
- 새로운 Stage가 다음 난이도 벽이 되어 내실 성장의 목적과 체감이 유지되도록 한다.
- Stage 클리어 → 다음 Stage 해금 → 막히면 연구/파밍 → 재도전의 모바일 챕터형 진행 루프를 목표로 한다.
- 향후 Stage 데이터와 Hero profile 데이터를 분리해 밸런스를 Stage 단위로 조정하기로 결정.


### Placement v2 — 자동/수동 소환 + Hero 상시 이동
- 몬스터 배치 방식을 자동/수동 두 모드로 분리.
- 하단에 Godot `CheckButton` 기반 스위치형 배치 모드 UI 추가.
- **자동 배치**:
  - 몬스터 버튼을 누르면 기존처럼 전장 가장자리 후보 위치에서 즉시 소환.
- **수동 배치**:
  - 몬스터 버튼을 눌러 Slime / Spider / Orc 중 하나를 선택.
  - 이후 전장을 터치한 위치에 선택한 몬스터를 소환.
  - 선택 상태를 유지해 같은 몬스터를 연속 배치할 수 있음.
- 수동 배치는 전장 내부 유효 영역에서만 허용하고 바깥 터치는 무시.
- 지휘력 비용/부족 판정은 자동/수동 모드 모두 동일하게 적용.
- Hero가 몬스터 0마리 상태에서도 정지하지 않고 전장 안의 임의 목표 지점을 향해 계속 배회하도록 변경.
- Hero가 배회 목표에 도달하거나 일정 시간이 지나면 새로운 목표 지점을 선택.
- 몬스터가 등장하면 배회 행동을 즉시 중단하고 기존 카이팅/원거리 공격 AI로 전환.


### Input Patch — 수동 배치 터치 안정화
- 수동 배치 전장 터치를 `_unhandled_input` 대신 `_input`에서 처리하도록 변경해 전체 화면 Control UI 구조에서도 모바일 터치가 안정적으로 인식되도록 보완.
- 결과창이 표시된 동안에는 전장 배치 입력을 무시해 재시작 버튼 터치와 충돌하지 않도록 처리.


### EXP Orb v1 — 뱀서형 경험치 획득
- 몬스터 처치 시 Hero EXP를 즉시 지급하던 방식을 제거.
- 몬스터 사망 위치에 `ExpOrb` 경험치 구슬을 생성하도록 변경.
- 구슬 가치는 기존 몬스터 EXP 보상값을 그대로 사용:
  - Slime 25
  - Spider 30
  - Orc 40
- Hero에 `exp_pickup_radius` 스탯 추가.
- 기본 경험치 획득 범위는 **150px**.
- 구슬은 범위 밖에서는 정지해 있고, Hero가 획득 범위 안으로 들어오면 자석처럼 Hero를 추적.
- 한 번 자석화된 구슬은 Hero가 이동해도 계속 따라오도록 구성.
- Hero와 충분히 가까워지면 구슬이 사라지고 그 시점에 EXP가 증가.
- 경험치 구슬에 청록색 펄스 플레이스홀더 비주얼 추가.
- 향후 획득 범위 증가 증강, 자석 효과, Hero별 기본 흡수 범위 차이를 추가할 수 있도록 획득 범위를 Hero 스탯으로 분리.


### Stage / Hero Data v1
- Stage와 Hero 스탯을 전투 코드에서 분리하는 데이터 구조 추가.
- `src/data/stage_catalog.gd` 추가:
  - Stage id / 번호 / 표시 이름 / hero_id / 시작 레벨 / 최초 클리어 보상 / 다음 Stage id 관리.
- `src/data/hero_profiles.gd` 추가:
  - Hero id / 이름 / archetype / HP / 이동속도 / 공격력 / 사거리 / 공격주기 / 투사체속도 / EXP 획득범위 / 감지범위 / 카이팅 거리 관리.
- Stage 1을 현재 원거리 카이팅형 **견습 마도사**에 고정.
- Stage 2용 **기동 사냥꾼** profile을 데이터 placeholder로 추가하고 Stage 2는 잠금 상태로 유지.
- Hero가 고정 하드코딩 값만 사용하는 대신 Battle이 Stage의 `hero_id`를 읽어 Hero profile을 적용하도록 변경.
- Hero의 AI 감지 범위와 카이팅 거리도 profile에서 바꿀 수 있도록 데이터화.
- 상단 HUD의 부제에 `Stage 번호 · Stage 이름 · Hero 이름` 표시.
- Hero 처치 결과를 `STAGE CLEAR`로 변경하고 현재 Stage/용사 이름을 결과 메시지에 표시.
- 다음 단계는 Stage 진행 상태와 Stage 1 최초 클리어 → Stage 2 해금 흐름.


### Finite World Camera + Stage Progress v2
- 기존 한 화면 고정 전장을 **유한 대형 월드 + Hero 추적 카메라** 구조로 전환.
- Stage 데이터에 맵 크기를 추가:
  - Stage 1: 3200×3200
  - Stage 2: 3600×3600
- Hero scene에 `Camera2D` 추가.
- Camera2D가 Hero를 부드럽게 추적하고 Stage 맵 경계를 넘지 않도록 limit 적용.
- Hero 배회/카이팅 경계도 기존 화면 크기 하드코딩 대신 현재 Stage 맵 크기를 사용하도록 변경.
- 전투 월드에 320px 간격 테스트 그리드를 추가해 카메라 이동을 시각적으로 확인할 수 있도록 함.
- HUD를 `CanvasLayer`로 분리해 카메라가 움직여도 상단/하단 UI는 화면에 고정.
- 수동 배치 입력을 카메라 canvas transform의 역변환으로 실제 월드 좌표에 매핑.
- 상단/하단 HUD 영역 터치는 수동 배치로 처리하지 않도록 제한.
- 자동 배치를 맵 고정 스폰 지점에서 **현재 Hero 기준 560~720px 거리의 외곽 스폰**으로 변경.
- `stage_progress.gd` 추가:
  - 현재 Stage id
  - 최고 해금 Stage 번호
  - Stage 클리어 여부
  - `user://stage_progress.cfg` 저장
- Stage 1 클리어 시 Stage 2를 영구 해금하도록 연결.
- 결과창에 **다음 스테이지** 버튼 추가.
- Stage 2의 기동 사냥꾼을 실제로 진입 가능한 프로토타입 Stage로 연결.
- Stage 2는 현재 마지막 프로토타입 Stage라 다음 Stage 버튼이 표시되지 않음.


### Stage 1 Pixel Hero Art v1
- 사용자가 제공한 Stage 1 원거리 마법사 도트 시안에서 대기 포즈 1프레임을 게임용 32×32 투명 픽셀 텍스처로 정리.
- `assets/art/heroes/stage1_mage_idle.svg` 추가.
- Stage 1 `견습 마도사` Hero profile에 sprite_path 연결.
- Hero scene에 nearest filtering을 사용하는 `Sprite2D` 추가.
- Stage 1에서는 기존 코드 드로잉 원형 Hero 대신 실제 마법사 도트가 표시됨.
- sprite_path가 없는 Hero profile은 기존 플레이스홀더 그래픽으로 자동 fallback.
- 현재는 정지 프레임 v1이며, 이후 걷기/공격/피격/사망 애니메이션으로 확장 예정.

### Demon Augment v1 — 3택 + Run당 리롤 3회
- 마왕이 한 Run 안에서 성장할 수 있는 첫 증강 시스템 추가.
- 증강 발생 조건을 **누적 지휘력 사용량 30 / 75 / 130**으로 정의.
- 한 Run 최대 3회의 마왕 증강 선택 발생.
- 매번 후보 3개 중 1개를 플레이어가 직접 선택.
- 새로고침은 Run 전체에서 총 3회 공유.
- 새로고침 직전 버린 후보는 즉시 재등장하지 않도록 제외.
- 증강 선택 중 Hero / 몬스터 / EXP 구슬 / Hero 투사체의 physics를 정지.
- 초기 마왕 증강 9종 추가:
  - 어둠의 순환: 지휘력 회복 +0.8/초
  - 전쟁 경제: 모든 소환 비용 -15%
  - 군단 훈련: 새 몬스터 이동속도 +15%
  - 시체 재활용: 몬스터 사망 시 실제 소환 비용 25% 환급
  - 분열 실험: Slime 사망 시 30% 확률 무료 Slime 1체 생성
  - 독거미 둥지: 새 Spider 둔화 지속시간 +40%
  - 오크 중장갑: 새 Orc 최대 HP +30%
  - 잔혹한 명령: 새 몬스터 공격력 +12%
  - 마력 비축: 최대 지휘력 +25 및 즉시 지휘력 +25
- 소환 비용 감소 증강 적용 시 하단 몬스터 버튼 비용 텍스트도 실시간 갱신.
- 마왕 증강 선택 팝업과 현재 남은 새로고침 횟수 UI 추가.


### Stage 1 Pixel Art Import Patch
- Stage 1 마법사 도트 SVG를 embedded raster 방식에서 **순수 SVG path 픽셀 데이터**로 변환.
- Godot Android SVG importer 호환성을 높이고 32×32 픽셀 형태를 그대로 유지.


### Demon EXP v2 + Gameplay Viewport / EXP Cleanup AI
- 마왕 증강 트리거를 누적 지휘력 사용량 체크 방식에서 **마왕 Lv / EXP 방식**으로 전환.
- 몬스터 소환 성공 시 실제 소비한 소환 비용만큼 마왕 EXP를 획득.
- 마왕 초기 Lv.1 / 첫 필요 EXP 30, 이후 레벨마다 필요 EXP +15.
- 마왕 레벨업 시 증강 3택 팝업 발생.
- Run당 새로고침 3회 공유 규칙은 유지.
- 하단 HUD에 마왕 Lv / EXP 수치와 EXP 게이지 추가.
- 증강 선택 팝업 문구를 누적 지휘력 기준에서 마왕 레벨업 기준으로 변경.
- 소환 후 레벨업한 경우 방금 소환된 몬스터까지 증강 선택 중 정상 정지하도록 처리 순서 보완.
- 이미 선택한 마왕 증강이 후보 풀에 다시 섞이지 않도록 후보 생성 로직 수정.
- 상단/하단 HUD가 월드 화면을 가리던 문제를 해결하기 위해 전투 월드를 별도 `SubViewport`로 분리.
- 전투 화면은 상단 270px 아래부터 하단 조작 UI 위까지만 렌더링.
- 수동 배치 터치 좌표도 SubViewport 카메라 좌표계에 맞게 변환.
- 몬스터가 0마리일 때 EXP 구슬이 남아 있으면 Hero가 랜덤 배회보다 **가장 가까운 EXP 구슬 회수**를 우선하도록 변경.
- EXP 구슬이 없을 때만 기존 랜덤 배회 행동 사용.
- Stage 1 견습 마도사 도트가 확실히 로드되도록 텍스처를 직접 preload하는 경로 추가.


### Demon EXP Feedback Patch
- 소환 성공 메시지에 획득한 마왕 EXP를 함께 표시.
- 소환 성공 UI가 먼저 갱신된 뒤 마왕 레벨업/증강 팝업이 열리도록 신호 순서를 조정해 안내 문구가 덮이는 문제를 방지.


### Critical Fix — Hero 0/0 / Stage 1 Sprite Loader
- SubViewport 전환 이후 Stage 1에서 Hero가 보이지 않고 HUD가 `HP 0 / 0`으로 표시되는 문제 수정.
- 원인: Stage 1 SVG를 Hero script 상단에서 직접 `preload()`하면서 Android Godot의 리소스 import 실패가 Hero script 로딩 전체에 영향을 줄 수 있었음.
- Hero script에서 Stage 1 SVG 직접 preload 의존성을 제거.
- 사용자가 제공한 실제 **32×32 RGBA PNG**를 Base64 데이터로 내장하고 런타임에 `Image.load_png_from_buffer()` → `ImageTexture`로 안전하게 생성하도록 변경.
- PNG 디코딩/아트 로딩이 실패해도 Hero script와 전투 로직은 정상 유지되며 기존 플레이스홀더 Hero를 표시하도록 fallback 보장.
- 아트 리소스 실패가 다시 전투 전체 생성 실패로 이어지지 않도록 게임 로직과 비주얼 로딩을 분리.


### Stage Select + First Clear Research Reward v1
- 상단 HUD에 `스테이지` 버튼 추가.
- 전투 중 Stage 선택 메뉴를 열면 Hero / 몬스터 / EXP 구슬 / 투사체 및 지휘력 회복을 일시 정지.
- Stage 선택 메뉴에 현재 영구 자원 **연구 포인트** 표시.
- Stage 1 / Stage 2 카드에 다음 정보 표시:
  - Stage 번호 / 이름
  - 상대 Hero 이름
  - 잠김 / 해금 / 클리어 완료 상태
  - 최초 클리어 연구 포인트 보상
- 해금된 과거 Stage를 선택해 즉시 재도전할 수 있도록 구현.
- 전투 결과창에도 `스테이지 선택` 버튼 추가.
- `stage_progress.gd` 저장 구조에 영구 `research_points` 추가.
- Stage별 최초 클리어 보상 지급:
  - Stage 1: 연구 포인트 +100
  - Stage 2: 연구 포인트 +150
- Stage마다 `reward_claimed`를 별도 저장해 최초 보상이 중복 지급되지 않도록 처리.
- 기존 버전에서 이미 Stage를 클리어한 저장 데이터도 reward_claimed가 없다면 다음 클리어 때 해당 보상을 1회 받을 수 있도록 마이그레이션 호환.
- 클리어 결과 메시지에 실제 지급된 최초 연구 포인트 보상을 표시.
- 다음 단계에서 연구 포인트를 소비하는 영구 연구/내실 시스템으로 연결 예정.


### Stage 1 Mage Animation v1
- Stage 1 마법사 정지 1프레임 표시에서 실제 전투 상태 기반 도트 애니메이션 구조로 확장.
- `src/data/stage1_mage_pose_data.gd` 추가.
- 제공된 도트 시트의 대표 32×32 포즈를 팔레트 + RLE 텍스트 데이터로 저장하고 런타임에 `ImageTexture`로 복원.
- Hero 상태와 다음 포즈를 연결:
  - idle: 대기 2프레임 교대
  - walk: 일반 이동
  - run: 빠른 이동 / 카이팅
  - attack: 투사체 발사
  - hit: 피격
  - death: 사망 2단계
- 걷기/달리기에 작은 상하 보빙을 추가해 정지 그림처럼 보이지 않도록 개선.
- 이동 방향이 왼쪽일 때 Sprite 좌우 반전.
- 공격 포즈 유지시간 0.24초, 피격 포즈 유지시간 0.20초.
- Hero가 0 HP가 되자마자 즉시 사라지지 않고 사망 포즈를 약 0.68초 보여준 뒤 사망 신호를 보내도록 변경.
- 아트 데이터 로딩 실패 시 기존 Stage 1 정지 도트/플레이스홀더 fallback 구조는 유지.


### Stage 1 Mage Animation Corruption Fix
- Stage 1 마법사 애니메이션 프레임이 깨져 보이던 문제 수정.
- 원인: 팔레트 + RLE 방식으로 도트를 재구성하면서 원본 픽셀 색상/프레임 정보가 손실됨.
- `stage1_mage_pose_data.gd`의 RLE/팔레트 복원 방식을 제거.
- 사용자가 제공한 Stage 1 마법사 시트에서 추출한 **정확한 32×32 PNG 프레임**을 Base64로 저장하고 런타임에 직접 디코딩하도록 변경.
- 현재 상태 애니메이션 연결은 그대로 유지:
  - idle 2프레임
  - walk
  - run
  - attack
  - hit
  - death 2단계
- 아트 디코딩 실패 시 기존 Hero fallback 구조는 유지.


### Stage 1 Game-Ready Sprite Sheet v2 — No Base64
- 사용자 제공 `stage1_mage_game_ready.zip` 구조를 기준으로 Stage 1 마법사 애니메이션을 재구성.
- 기존 Base64 PNG 문자열, RLE/팔레트 복원, 대표 단일 포즈 방식 전부 제거.
- Hero visual node를 `Sprite2D` → `AnimatedSprite2D`로 전환.
- 하나의 384×256 스프라이트시트(64×64 셀, 6×4)에서 `AtlasTexture` 프레임을 런타임에 구성.
- 실제 애니메이션:
  - idle: 4프레임 / 5.5 FPS / loop
  - move: 6프레임 / 10 FPS 기반 / 실제 이동속도 비례 재생속도
  - attack: 6프레임 / 18 FPS / non-loop
  - hit: 3프레임 / 14 FPS / non-loop
- 공격 시 프레임 0부터 다시 재생하고 약 0.34초 동안 공격 모션 우선.
- 피격 시 3프레임 hit 모션을 프레임 0부터 재생.
- 이동 방향이 좌측이면 AnimatedSprite2D flip_h 적용.
- 제공 팩에는 death 전용 프레임이 없어, 사망은 hit 모션 후 0.48초 fade + 약간의 tilt로 처리.
- Stage 1 Hero profile을 `sprite_sheet_path` 기반으로 변경.
- 스프라이트시트가 없거나 import 실패해도 전투 로직은 깨지지 않고 기존 코드 드로잉 Hero로 fallback.
- `tools/install_stage1_mage_art.sh` 추가: 원본 zip에서 PNG spritesheet와 manifest를 프로젝트 경로로 직접 복사. Base64 사용 없음.
- 이전 `src/data/stage1_mage_pose_data.gd` 및 구형 `stage1_mage_idle.svg` 삭제.


### Fix — Stage 1 Sprite Falls Back to Placeholder on Android
- 스프라이트 설치 성공 후에도 Stage 1 Hero가 기존 원형 도형으로 표시되던 문제 수정.
- 원인: Android Godot Editor에서 Termux가 새 PNG를 프로젝트 폴더에 복사한 직후 import/cache가 갱신되기 전에는 `ResourceLoader.exists()`가 false를 반환할 수 있었고, 코드가 raw 파일을 확인하기도 전에 fallback 처리함.
- 이제 Stage 1 스프라이트 로더는 imported Texture2D를 먼저 시도하고, 실패 시 실제 `res://` PNG 파일을 `Image.load()`로 직접 읽어 `ImageTexture`로 생성.
- Base64 사용 없음.
- `tools/install_stage1_mage_art.sh`에 PNG 추출 파일 크기 검증 추가.


### Stage 1 Mage Projectile Animation v1
- Stage 1 견습 마도사의 기존 노란 원형 테스트 투사체를 전용 마법탄 애니메이션으로 교체.
- 사용자 제공 4프레임을 하나의 PNG 스프라이트시트로 정리해 사용.
- **Base64 사용 없음.**
- `HeroProjectile.tscn`에 `AnimatedSprite2D` 추가.
- fly: 4 frames / 12 FPS / loop.
- 스프라이트시트 셀 크기: 128×128.
- 발사 방향에 맞춰 projectile node를 회전시켜 상/하/대각선 발사에도 자연스럽게 진행.
- `Hero._fire_projectile()`가 source hero id를 투사체에 전달하도록 변경.
- Stage 1 `ranged_rookie`에서만 전용 마법탄 표시, 다른 Hero는 기존 원형 테스트 탄환 유지.
- PNG import/cache가 늦는 Android Editor에서는 raw PNG 직접 로드 fallback 지원.
- 기존 투사체 속도 / 사거리 / 피해 / 충돌 판정 로직 유지.
- `tools/install_stage1_projectile_art.sh` 추가.


### Stage 1 Projectile Animation Apply Fix
- 사용자가 제공한 마법탄 4프레임을 투명 배경 게임용 리소스로 정리:
  - projectile_01~04
  - 128×128 공통 셀
  - 512×128 sprite sheet
  - fly 4프레임 / 12 FPS / loop
- 투사체 코어/진행축을 공통 anchor로 맞춤.
- 치명적 적용 순서 버그 수정:
  - 기존에는 `_ready()`에서 비주얼을 먼저 적용해 `source_hero_id`가 비어 있었고 Stage 1 애니메이션이 항상 fallback 됨.
  - 이제 `setup()`에서 Hero id를 받은 뒤 Stage 1 projectile visual을 적용.
- AnimatedSprite2D offset을 조정해 빛나는 코어가 충돌/회전 중심에 오도록 정렬.
- 기존 데미지/속도/사거리 로직은 유지.


### Fix — Stage 1 Projectile Still Showing Yellow Fallback
- Stage 1 투사체 PNG 설치 후에도 기존 노란 원형탄이 표시되던 문제 수정.
- 원인 후보였던 합본 spritesheet 로딩/AtlasTexture 프레임 절단 경로를 제거.
- 이제 `projectile_01.png ~ projectile_04.png` 개별 PNG 4장을 직접 AnimatedSprite2D `fly` 애니메이션에 등록.
- Android Godot Editor의 import cache가 늦을 경우 `FileAccess`로 PNG 원본 bytes를 읽고 `Image.load_png_from_buffer()`로 Texture2D를 생성.
- Base64 사용 없음.
- 4프레임 중 일부만 읽혀도 읽힌 프레임으로 애니메이션을 구성하고, 전부 실패한 경우에만 기존 노란 원형탄 fallback 사용.


### Permanent Research / Meta Progression v1
- 최초 클리어로 모은 연구 포인트를 실제로 소비하는 영구 연구 시스템 추가.
- `src/data/research_catalog.gd` 추가. 연구 이름/설명/최대 레벨/레벨별 비용을 데이터로 분리.
- `stage_progress.gd`에 연구 레벨 저장 및 연구 포인트 결제 로직 추가.
- 연구 레벨과 잔여 연구 포인트는 기존 `user://stage_progress.cfg`에 영구 저장.
- Stage 선택 메뉴에 `마왕 연구` 버튼과 연구 메뉴 추가.
- 초기 영구 연구 5종:
  - 마력 저장고 Lv.1~3: 최대 지휘력 +10 / Lv
  - 마력 순환 Lv.1~3: 지휘력 회복 +0.25/초 / Lv
  - 슬라임 배양 최적화 Lv.1~3: Slime 소환 비용 -5% / Lv
  - 전술 기록 노트 Lv.1~3: Run당 마왕 증강 새로고침 +1 / Lv
  - 고속 실험법 Lv.1~3: 소환 시 마왕 EXP 획득 +5% / Lv
- 연구 구매는 진행 중인 Run을 즉시 변형하지 않고 **다음 Run 시작 시 적용**.
- 시작 지휘력은 기존 설계대로 0 유지.
- Slime 연구 비용 감소는 Run 내 `전쟁 경제` 소환 비용 감소와 곱연산으로 함께 적용.
- 전술 기록 노트 연구가 있으면 마왕 증강 UI의 새로고침 최대 횟수 표기도 자동 증가.
- 고속 실험법이 있으면 소환 성공 메시지에 실제 보너스가 포함된 마왕 EXP 획득량을 표시.
- 영구 연구와 Run 내 마왕 증강을 별도 성장축으로 유지.
- 다음 기초 개발 우선순위는 최근 공세의 시간 흐름/기록을 Hero AI 판단에 반영하는 것.


### Hero AI Offensive Memory v1 + Data-Driven Refactor
- Hero가 최근 20초 동안 플레이어가 직접 소환한 몬스터 공세를 기억하도록 구현.
- 최근 기록은 시간이 지날수록 가중치가 감소하며 20초 후 제거.
- 현재 전장 구성뿐 아니라 최근 type / role 비중도 Hero 레벨업 증강 Utility 점수에 반영.
- Slime 계열 물량 공세 → 연사 계열, Spider/Controller 공세 → 기동/사거리 계열, Orc/Tank 공세 → 단일 화력/생존 계열 점수에 영향을 주는 v1 데이터 설정 추가.
- 자동 생성된 분열 몬스터는 플레이어 공세 기억에서 제외.
- AI 선택 이유 문자열도 최근 공세 데이터가 주요 근거일 경우 해당 내용을 표시.
- 확장성을 위해 몬스터 ID별 하드코딩을 정리:
  - `src/data/monster_catalog.gd` 추가
  - 몬스터 이름 / 역할 / 기본 비용 / PackedScene을 Catalog에서 관리
  - Battle의 몬스터 Scene 선택, 이름, 기본 비용, AI 기록 역할 조회를 Catalog 기반으로 변경
- Hero 증강의 AI 가중치를 `hero_augment_catalog.gd`의 `ai_rules` 데이터로 이동.
- `hero_build_ai.gd`에서 증강 ID별 대형 match문 제거.
- Build AI는 `current_type_ratio / current_role_ratio / recent_type_ratio / recent_role_ratio / hp_missing / distance / count condition` 등 공통 규칙을 평가하는 방식으로 변경.
- Hero의 현재 전장/최근 공세 집계 Dictionary에서 Slime/Spider/Orc 고정 초기값 제거. 새 type/role 키를 동적으로 집계.
- 프로젝트 코딩 원칙으로 **업데이트를 고려한 데이터 중심 설계**를 `AGENTS.md`에 명시.


### Critical Fix — Hero Missing After Data-Driven AI Refactor
- 데이터 중심 리팩터링 직후 Hero가 생성되지 않고 HUD가 `용사 HP 0 / 0`으로 표시되던 문제 수정.
- 원인: 기존 `_role_for_monster_type()` helper를 제거한 뒤, 최근 공세 메모리 집계 코드에 해당 함수 호출이 1곳 남아 Hero script 컴파일이 실패함.
- 남아 있던 참조를 `MONSTER_CATALOG.get_role(monster_type)`로 교체.
- 데이터 중심 구조는 유지하면서 Hero script가 정상 로드되도록 복구.


### Hero AI Decision Delay + Build Inertia v1
- Hero AI가 레벨업 순간의 실시간 전황을 즉시 읽던 구조를 **주기적 관측 스냅샷 방식**으로 변경.
- Hero는 profile의 `ai_settings.observation_interval`마다 전황/최근 공세 데이터를 관측하고 저장.
- 레벨업 증강 선택은 가장 최근에 저장된 관측값을 사용하므로 최대 관측 주기만큼 정보 지연이 발생.
- AI 선택 이유에 `x.x초 전 관측`을 표시해 플레이어가 판단 지연을 이해할 수 있게 함.
- Build AI의 기존 동일 증강 누적 관성을 Hero profile 데이터 `stack_inertia`로 조절하도록 변경.
- 이미 하나 이상의 빌드가 쌓인 뒤 처음 고르는 새 증강에는 `new_branch_penalty`를 적용해 무분별한 즉시 전환을 억제.
- 특정 증강별 분기 없이 모든 후보에 공통 계산으로 적용.
- Stage 1 견습 마도사: 관측 4.0초 / stack inertia 1.25 / 새 갈래 penalty 0.70.
- Stage 2 기동 사냥꾼: 관측 2.8초 / stack inertia 0.95 / 새 갈래 penalty 0.40.
- Stage별 AI 성향을 코드 분기가 아니라 `hero_profiles.gd` 데이터로 확장할 수 있도록 구성.


### Hero Augment Synergy v1
- Hero Build AI에 **현재 빌드 시너지 점수** 추가.
- `hero_augment_catalog.gd`의 각 증강에 `tags`와 `synergy_rules` 데이터를 추가.
- 기존 build_counts를 태그 스택으로 변환하는 `get_build_tag_counts()` 추가.
- Build AI에 범용 synergy rule evaluator 추가:
  - `build_tag_stacks`
  - `build_tag_present`
  - `build_augment_stacks`
  - `build_augment_present`
- 시너지 수치와 cap은 증강 데이터에서 조정 가능하며 특정 증강 ID별 match문은 추가하지 않음.
- 초기 시너지 방향:
  - 탄환 강화 + 연사 강화 = 화력/공속 빌드
  - 민첩한 발놀림 + 사거리 확장 = 카이팅 빌드
  - 강인한 육체 + 전투 회복 = 생존 빌드
- AI 최종 점수는 전황 + 최근 공세 + 시너지 + 동일 증강 관성 - 새 갈래 전환 저항 + 작은 랜덤값으로 구성.
- AI 선택 이유에 `기존 공격속도 2스택 시너지 +1.8` 같은 설명을 추가해 플레이어가 빌드 연결을 읽을 수 있게 함.
- 후보별 total score뿐 아니라 synergy score도 내부 debug data에 저장.


### Hero Area Augment v1 + Data-Driven Effect Application
- 핵심 재미 검증을 위해 Hero의 실제 광역 대응 증강 **폭발 탄환** 추가.
- 폭발 탄환 AI 성향:
  - 현재 Slime/swarm 비중
  - 최근 20초 Slime/swarm 공세 비중
  - 근처 적 수
  - 최근 플레이어 소환 횟수
  를 데이터 기반 Utility rule로 반영.
- 폭발 탄환 선택 시 projectile splash 스탯 증가:
  - 반경 +70 / stack, 최대 180
  - 주변 피해 비율 +0.28 / stack, 최대 0.70
- HeroProjectile이 직접 대상 피해 후 splash 반경 내 다른 몬스터에게 광역 피해를 적용하도록 구현.
- 중복 body_entered 처리 방지를 위해 projectile impact guard 추가.
- 단일 고체력 Orc/tank 비중은 기존 탄환 강화 점수를 높여 광역 투자와 단일 화력 투자 방향을 구분.
- Hero 증강 효과를 증강 ID별 match문에서 데이터 기반 `effects`로 리팩터링.
- 기존 6개 증강도 모두 effects 데이터로 이전:
  - stat add
  - stat multiply + min/max clamp
  - heal
- 새 Hero 증강 추가 시 Hero 로직 파일을 직접 수정하지 않는 구조를 강화.


### Actual Status-Effect Memory + Slow Resistance v1
- Hero AI가 몬스터 종류뿐 아니라 **실제로 적중한 상태이상**을 최근 전투 기억으로 저장하도록 확장.
- `src/data/status_effect_catalog.gd` 추가. 현재 slow(둔화) 등록, 이후 다른 상태이상으로 확장 가능.
- Hero에 최근 20초 status-effect event history 추가.
- 상태이상별 실제 적중 횟수와 시간 감쇠 weight를 AI context에 포함.
- Spider 공격으로 `apply_slow()`가 실제 호출될 때만 slow event가 기록됨.
- Build AI에 범용 `recent_status_weight` rule source 추가.
- AI 선택 이유가 해당 rule을 주요 근거로 사용하면 `최근 20초 둔화 N회` 형식으로 표시.
- 기존 민첩한 발놀림에 실제 둔화 적중 기반 가중치 추가.
- 신규 Hero 증강 **둔화 적응** 추가:
  - base score 4.8
  - slow resistance +18% / stack
  - 최대 slow resistance 65%
  - 최근 slow 적중 weight가 높을수록 강하게 선호
  - Spider/controller 공세 정보도 보조 점수로 사용
- 상태 저항은 `status_resistances` Dictionary로 관리.
- slow resistance는 둔화 이동속도 감소 강도와 지속시간을 모두 완화.
- Hero augment 공통 effect system에 `add_status_resistance` op 추가.
- 상태이상 종류가 늘어나도 Hero AI/증강 적용 구조를 그대로 재사용할 수 있도록 구성.


### Run Timer + Strategy Switch Analysis v1
- 끝없이 이어지던 프로토타입 Run에 Stage별 제한시간 추가.
- Stage 1: 6분, Stage 2: 7분.
- 제한시간 내 Hero 처치 실패 시 시간 초과 패배 처리.
- 상단 HUD에 `남은 시간 MM:SS` 표시.
- 마왕 증강 선택 / 스테이지·연구 메뉴 등 전투 pause 상태에서는 Run timer도 정지.
- `src/systems/run_metrics.gd` 신규 추가. Battle 로직과 분석 로직 분리.
- RunMetrics가 기록하는 항목:
  - 직접 소환 타입별 횟수와 지휘력 소비량
  - 타입별 몬스터 사망 횟수
  - Hero 최저 HP 및 비율
  - Hero 레벨업 증강 선택 시각
  - 주력 공세 전환 시각
- 전략 전환 판정은 최근 15초 직접 소환을 사용.
- 싼 Slime과 비싼 Orc를 단순 개체 수로 비교하지 않고 실제 소비 지휘력을 weight로 사용.
- 최근 지휘력 소비 12 이상 + 60% 이상 점유 시 주력 전략으로 인정.
- 주력 타입이 달라지면 전환 시각을 기록하며 6초 cooldown 적용.
- 전투 종료 결과창 확장:
  - 실제 Run 시간 / 목표 시간
  - Hero 최저 HP
  - 직접 소환 구성
  - 전략 전환 시각
  - Hero 증강 선택 횟수와 마지막 선택
- 현재는 검증용 v1이며 5~10분 실기기 플레이 결과로 threshold/window를 조정 예정.

### Demon Level Monster Scaling + Hero Augment Stack Caps
- 마왕 Lv.1 몬스터 수치를 기존 ×1.00 기준으로 유지하고, Lv.2부터 레벨 상승마다 HP/공격력 ×1.05를 누적 적용.
- 몬스터 이동속도는 마왕 레벨 상승마다 ×1.02를 누적 적용하며, 레벨 성장으로 인한 총 이동속도 배율은 최대 ×1.25로 제한.
- 마왕 레벨 상승 시 이미 생존 중인 몬스터에도 새 레벨 배율을 즉시 반영.
- 생존 몬스터 최대 HP 갱신 시 현재 HP 비율을 보존해 레벨업 직후 체력 비율이 튀지 않도록 처리.
- 기존 군단 훈련 / 잔혹한 명령 / 오크 중장갑의 "소환 시점" 적용 범위는 유지하고, 마왕 레벨 배율만 별도 공통 성장으로 재계산.
- Hero 증강 카탈로그에 `max_stack`을 추가하고 현재 8종 제한을 5 / 5 / 5 / 2 / 3 / 3 / 4 / 3으로 적용.
- 최대 중첩에 도달한 Hero 증강은 이후 레벨업 후보 풀에서 제외하며, 적용 직전에도 상한을 다시 검증.

### Demon Augment Stack Caps + Balance Debug HUD
- 마왕 증강 9종에 최대 중첩을 추가하고, 최대치 전까지 동일 증강이 이후 마왕 레벨업 후보에 다시 등장하도록 변경.
- 최대 중첩 도달 증강은 후보 풀에서 자동 제외하며, 선택 직전에도 상한을 재검증.
- 마왕 레벨 자체가 몬스터 HP/공격력/이동속도를 지속 성장시키므로 Run 증강의 순수 스탯 보너스를 하향 조정:
  - 어둠의 순환 +0.45/초 ×4
  - 전쟁 경제 -10% ×3
  - 군단 훈련 이동속도 +7% ×2
  - 시체 재활용 환급 +12%p ×3 (최대 36%)
  - 분열 실험 +15%p ×3 (최대 45%)
  - 독거미 둥지 둔화 지속시간 +20% ×2
  - 오크 중장갑 HP +12% ×3
  - 잔혹한 명령 공격력 +6% ×2
  - 마력 비축 최대/즉시 지휘력 +15 ×4
- 마왕 증강 수치와 효과 적용 정보를 `demon_augment_catalog.gd`의 effects 데이터로 이동해 설명/밸런스 값과 런타임 적용을 한 곳에서 관리.
- 마왕 증강 선택 카드에 `현재 중첩 → 선택 후 중첩 / 최대 중첩` 표시 추가.
- 전투 HUD에 0.25초 갱신 밸런스 디버그 표기 추가:
  - 마왕 레벨 기반 HP/공격력/이동속도 배율
  - 신규 소환에 적용되는 Run 증강 배율/확률
  - 생존 중인 Slime/Spider/Orc 실제 HP/공격력/이동속도 샘플

### Shared Integer Damage Number Popup
- Hero와 모든 현재 몬스터의 피격 시 월드 공간 데미지 숫자 팝업을 표시.
- 표시값은 공격 원본 수치가 아니라 실제로 감소한 HP를 사용해 막타의 과잉 피해가 부풀려 보이지 않도록 처리.
- 모든 표시값을 정수 문자열로 출력해 소수점이 나타나지 않도록 고정.
- 공통 `DamageNumber.tscn` + `damage_number_spawner.gd`를 추가해 Hero/몬스터가 동일한 표시 시스템을 재사용.
- Hero 기본 투사체와 폭발 탄환 광역 피해는 기존 대상 `take_damage()` 경로를 그대로 사용하므로 직접 피해와 광역 피해 모두 자동 표시.
- 숫자는 대상 위에서 짧게 떠오르며 페이드아웃되고 전투 월드 카메라를 따라 이동.

### Hero Hit Invulnerability + Blink Feedback
- Hero가 피해를 실제로 받은 직후 0.35초 동안 추가 피해를 무시하도록 피격 무적시간 추가.
- 여러 몬스터가 겹쳐 같은 프레임/짧은 간격에 공격해도 첫 유효 타격만 적용되어 중복 폭딜을 방지.
- 무적시간 동안 Hero 전체 비주얼의 알파를 빠르게 전환해 깜빡이는 피격 무적 피드백 제공.
- 무적시간은 `hero_profiles.gd > invulnerability_duration` 데이터로 Hero별 조절 가능.
- `take_damage()`가 실제 피해 적용 성공 여부를 반환하도록 변경.
- Spider 둔화는 실제 피해가 들어간 유효 타격에만 적용해 무적시간 중 중복 둔화/상태이상 기록이 발생하지 않도록 정리.

### Manual Spawn Hero Safety Radius
- 수동 배치 시 Hero 중심 기준 최소 220px 거리 제한 추가.
- Hero와 220px 미만 위치를 터치하면 몬스터를 생성하지 않고 지휘력도 소모하지 않음.
- 너무 가까운 위치를 터치했을 때 하단 상태 UI에 최소 거리 안내 메시지를 표시.
- 자동 배치의 기존 560~720px 소환 거리 규칙은 변경하지 않음.
- 수동 배치 유효성 검사는 전장 경계 + Hero 최소거리 규칙을 하나의 공통 판정으로 유지.

### Touch-local Manual Placement Feedback
- 수동 배치 실패 피드백을 하단 상태문구 중심에서 **사용자가 터치한 전장 위치의 플로팅 텍스트** 중심으로 변경.
- Hero 최소거리 위반 시 터치 위치에 `용사와 너무 가까움 / 220px 이상 거리 필요` 표시.
- 전장 경계 밖/지휘력 부족도 동일한 방식으로 짧은 현장 피드백 표시.
- 기존 데미지 숫자 팝업의 떠오름/페이드 애니메이션을 재사용하도록 공통 텍스트 표시 기능 추가.
- 수동배치 입력 경로에서는 배치 오류를 미리 판정해 하단 상태문구를 중복 갱신하지 않고 터치 위치 피드백을 우선.

### Manual Spawn Proximity Range Feedback
- Hero 근접 수동배치 실패 문구에서 `220px 이상` 같은 개발자 수치 노출을 제거하고 `용사와 너무 가까움`으로 단순화.
- Hero 근처 금지 영역을 잘못 터치하면 Hero 중심의 실제 최소 배치 반경 원형을 약 0.7초 동안 표시.
- 금지 원형은 반투명 영역 + 테두리로 나타나며 짧게 페이드아웃.
- 표시 중 Hero가 이동하면 원형도 Hero 위치를 따라가 현재 금지 영역을 그대로 보여줌.
- 기존 터치 위치 플로팅 텍스트와 함께 사용해 숫자 설명 없이도 공간적으로 배치 제한을 이해할 수 있게 개선.

### Hero Facing Stabilization + Sprite Atlas Bleed Fix
- Hero 방향 전환을 매 프레임 즉시 `flip_h` 하던 방식에서 **지속 방향 확인 후 전환**하는 디바운스 방식으로 변경.
- Stage 1 견습 마도사는 반대 방향 입력이 약 0.14초 유지되어야 좌우가 뒤집혀, 좌우에 몬스터가 동시에 있을 때 와다다다 떨리는 현상을 완화.
- 아주 작은 수평 속도 변화는 방향 전환 후보에서 무시하도록 최소 수평 속도 기준 추가.
- 공격 시작 순간에는 실제 발사 방향으로 한 번 바라본 뒤 공격 애니메이션 약 0.34초 동안 방향을 고정.
- 방향 전환 지연/최소 속도는 `hero_profiles.gd`에서 Hero별 조절 가능.
- Stage 1 64×64 무패딩 스프라이트시트의 AtlasTexture에 `filter_clip`을 활성화하고 nearest 필터를 명시해 인접 셀 픽셀이 공격 모션 가장자리에 비치는 현상을 방지.

### Stage-specific Hero Augment Pools
- Hero profile에 `augment_pool_ids`를 추가해 Stage/Hero마다 레벨업 후보로 등장 가능한 증강 풀을 데이터로 분리.
- `HeroAugmentCatalog.roll_candidates()`가 허용 풀 + 기존 최대 중첩 조건을 함께 적용하도록 확장.
- Stage 1 견습 마도사는 현재 범용 증강 8종 전체를 사용해 다양한 빌드 유도 실험을 유지.
- Stage 2 기동 사냥꾼은 캐릭터 성격에 맞춰 탄환 강화 / 연사 강화 / 민첩한 발놀림 / 둔화 적응 / 사거리 확장 / 폭발 탄환 6종을 사용.
- Stage 2에서는 강인한 육체/전투 회복을 후보 풀에서 제외해 Stage 1보다 기동·공격 중심의 빌드 정체성을 강화.
- 새 Hero를 추가할 때 AI/레벨업 코드를 수정하지 않고 profile의 증강 ID 배열만으로 후보 풀을 구성할 수 있음.

### Stage 1 Attack Stray Pixel Cleanup
- 사용자 실기기 녹화에서 Stage 1 견습 마도사 공격 모션 왼쪽 위/아래에 떨어져 보이던 1~2px급 고립 잡픽셀을 확인.
- 단순 Atlas bleed 문제가 아니라 공격 프레임 내부의 초소형 분리 컴포넌트가 보일 수 있는 케이스를 보정.
- Stage 1 스프라이트 PNG를 raw Image로 읽은 뒤 **attack 6프레임만** 검사하고, 본체보다 왼쪽에 떨어진 6px 이하 고립 컴포넌트만 투명 처리.
- 본체/지팡이/마법구처럼 큰 컴포넌트와 idle/move/hit 행은 수정하지 않음.
- Android Editor import cache 여부와 상관없이 동일 보정이 적용되도록 Stage 1 raw PNG 로드를 imported texture보다 먼저 사용.

### Stage 1 Attack Stray Pixel Cleanup — Video Calibration
- 실기기 녹화 프레임을 다시 확인한 결과, 남아 있던 세로 잡픽셀은 본체 왼쪽 경계에서 약 1 source-pixel 수준으로 매우 가깝게 분리되어 있었음.
- 기존 정리 로직의 `3px 이상 이격` 조건 때문에 해당 조각이 제거 대상에서 제외되던 문제 수정.
- 이제 공격 프레임에서 **본체보다 왼쪽에 분리된 1~2px 폭 / 6px 이하 고립 조각은 이격 거리 없이 제거**.
- 큰 마법구/지팡이/본체 컴포넌트는 기존 크기·폭 조건으로 계속 보존.

### Stage 1 Dedicated Attack Sheet Replacement
- 기존 384×256 통합 시트의 attack row 대신 **전용 384×64 / 64×64 × 6프레임 공격 시트**를 추가.
- 새 공격 시트는 투명 배경으로 정리하고 각 프레임의 발 위치를 공통 anchor(32, 56)에 맞춰 배치.
- Stage 1 공격 애니메이션은 전용 시트를 우선 사용하고, 에셋이 없을 때만 기존 통합 시트 row 2를 fallback으로 사용.
- 이전에 추가했던 런타임 고립 픽셀 탐지/삭제 로직은 제거해 정상적인 작은 마법 이펙트가 오검출될 위험을 없앰.
- idle / move / hit 프레임과 기존 통합 시트는 그대로 유지.
- Android Godot Editor의 import cache가 늦을 때도 raw PNG를 직접 읽는 fallback을 전용 공격 시트에도 동일 적용.

### Stage 1 Unified Spritesheet Restore
- 사용자가 직접 수정한 `attack_01.png` / `attack_05.png`를 원본 **64×64 셀 그대로** Stage 1 384×256 통합 스프라이트시트의 attack row에 교체.
- 공격 시 캐릭터가 커져 보이던 별도 생성 공격 시트 사용을 중단하고, idle / move / attack / hit 모두 동일 통합 시트에서 재생하도록 복귀.
- attack 애니메이션은 다시 row 2의 6프레임을 18 FPS non-loop로 사용.
- `stage1_mage_attack_sheet.png` 전용 에셋과 전용 로더/manifest override를 제거.
- HeroSprite scale, 64×64 AtlasTexture 셀, 기존 anchor/foot 위치는 변경하지 않아 상태 전환 시 크기 차이가 생기지 않도록 유지.

### Stage 1 Attack Frame Transparent Pixel Fix
- 통합 시트 복귀 과정에서 PNG 셀을 알파 마스크로 합성하면 투명하게 지운 픽셀이 원본 아래에 남을 수 있는 문제를 수정.
- 사용자 수정본 `attack_01` / `attack_05`를 **64×64 RGBA 셀 전체 교체** 방식으로 다시 반영.
- `attack_01`에서 제거한 왼쪽 2px 폭 × 12px 높이의 24개 불투명 픽셀이 실제 통합 시트에서도 완전히 투명해지도록 확인.
- 통합 시트 전체 크기 384×256, HeroSprite scale, attack row 위치는 그대로 유지.

### Stage-specific Hero AI Personality Data v1
- Hero 기본 스탯 데이터에서 AI 성향 설정을 분리하고 신규 `hero_ai_profiles.gd` Catalog 추가.
- Stage 데이터에 `hero_ai_profile_id`를 추가해 Stage가 Hero와 AI 성격을 독립적으로 선택하도록 변경.
- Stage 1은 기존 4.0초 관측 / 높은 빌드 관성 / 높은 새 갈래 저항을 유지.
- Stage 2는 2.8초 관측 / 낮은 전환 저항과 함께 연사·기동 증강에 소폭 성향 보정을 적용.
- Build AI에 범용 `augment_biases` 점수 항목을 추가하고 선택 이유에도 성향 보정을 표시.
- Stage ID별 하드코딩 분기 없이 새 AI 성향 프로필 추가만으로 이후 Stage/Hero 성격을 확장할 수 있도록 구성.

### Main Lobby + Five-tab Meta Hub v1
- 신규 `src/lobby/Lobby.tscn` / `lobby.gd` 추가, 앱 시작 씬을 로비로 변경.
- 하단 5탭을 **상점 / 팀 편성 / 메인 / 연구 / 기타** 구조로 구성.
- 메인 탭에 Stage 카드형 선택 UI 추가:
  - 좌우 Stage 이동
  - Stage 이름 / Hero 이름 / 상태 / 제한시간 / 최초 보상
  - Stage 해금 상태에 따른 입장 버튼 활성화
  - 선택 Stage 저장 후 기존 전투 씬 진입
- Stage 데이터에 대표 Hero `portrait_path`와 로비 설명 추가.
- Stage 1 초상화 슬롯은 `stage1_hero_portrait.png`를 읽도록 연결하고, 파일이 없을 때는 Hero 이름 placeholder 표시.
- 초상화 주변을 어두운 던전 패널 + 금색 이중 테두리로 구성해 침입자 기록 카드 느낌의 프레임 적용.
- 연구 탭에서 기존 연구 5종을 직접 구매할 수 있도록 기존 Catalog/Progress 시스템 연결.
- 상점 / 팀 편성 / 기타 탭은 후속 기능 구현을 위한 placeholder 구성.
- 전투 결과 화면에서 메인 로비로 복귀 가능하도록 버튼 동작 변경.

### Battle Pause Menu + Lobby Role Separation
- 전투 HUD의 기존 Stage 선택 / 마왕 연구 팝업을 제거.
- 상단 `스테이지` 버튼을 `메뉴`로 변경.
- 신규 전투 일시정지 메뉴 추가:
  - 계속하기
  - 같은 Stage 다시 도전
  - 로비로 나가기
  - 현재 Stage / 상대 Hero / 남은 시간 표시
- 메뉴가 열린 동안 기존 `Battle.set_external_pause()` 경로로 전투 엔티티와 Run timer를 정지.
- Android 뒤로가기(`ui_cancel`)로 메뉴를 열거나 닫을 수 있도록 입력 처리 추가.
- Stage 선택 / 영구 연구는 메인 로비 전용으로 정리.
- Stage 1 대표 Hero 초상화 PNG가 저장소에 실제 반영된 상태를 ROADMAP에 완료 처리.

### Monster Team Loadout v1
- 신규 `team_loadout.gd` 추가, 로비 편성을 별도 ConfigFile로 영구 저장.
- 로비 팀 편성 placeholder를 실제 편성 화면으로 교체:
  - 현재 3개 편성 슬롯 표시
  - MonsterCatalog의 보유 몬스터 목록 표시
  - 몬스터 탭으로 편성/해제
  - 최대 3종 / 최소 1종 제한
  - 이름 / 역할 / 기본 지휘력 비용 표시
- MonsterCatalog에 고정 ORDER 추가.
- Battle 시작 시 저장된 편성 로드, 미편성 몬스터 직접 소환 요청 차단.
- 전투 하단 3개 소환 버튼을 편성 슬롯 기반으로 동적 구성하고 빈 슬롯은 숨김.
- 메인 UI의 몬스터 이름 표시도 MonsterCatalog 기반으로 정리해 신규 몬스터 추가 시 하드코딩 수정 범위를 축소.

### Battle Menu Touch Regression Fix
- 팀 편성 v1 적용 후 Android에서 전투 상단 `메뉴` 버튼이 반응하지 않는 회귀 문제 대응.
- 메뉴/일시정지 버튼 signal 연결을 Battle signal 초기화보다 먼저 수행해, 전투 초기화 중 오류가 생겨도 메뉴 UI 연결이 끊기지 않도록 변경.
- 일시정지 메뉴를 열 때 `Battle.get_snapshot()` 호출 의존성을 제거하고 이미 표시 중인 상단 Stage/시간 HUD 값을 재사용.
- pause/unpause 호출은 Battle method 존재 여부를 확인한 뒤 실행하도록 안전 처리.
- 전투 `메뉴` 버튼에 높은 z-index와 명시적 touch mouse filter를 적용.
- TeamLoadout ConfigFile 저장값을 PackedStringArray로 통일하고 Array/PackedStringArray 로드를 `typeof()` 기반으로 정규화해 Android 런타임 호환성을 보강.

### Rollback: Monster Team Loadout v1
- 팀 편성 v1 이후 Android에서 전투 전체 입력/타이머가 멈추는 회귀가 발생해 해당 기능을 임시 롤백.
- `monster_catalog.gd`, 로비, Battle, 전투 Main UI를 마지막 정상 전투 상태(`4844cd5`)로 복구.
- 전투 타이머 / 슬라임·거미·오크 소환 / 상단 전투 메뉴 동작 복구를 최우선으로 함.
- 팀 편성은 ROADMAP에서 미완료 상태로 되돌리고, Android 오류 로그 확인 후 재구현 예정.

### Team Loadout Rebuild Step 1 — Lobby UI Only
- 롤백 이후 팀 편성을 작은 단계로 재도입.
- 로비 팀 편성 placeholder를 UI-only 편성 화면으로 교체.
- 3개 미리보기 슬롯 + MonsterCatalog 기반 몬스터 목록 + 역할/기본 비용 표시 추가.
- 버튼으로 최소 1종 / 최대 3종 범위의 로컬 미리보기 선택 가능.
- 선택 상태는 저장하지 않고 전투에도 전달하지 않음.
- 이번 변경은 `src/lobby/lobby.gd`와 `Lobby.tscn`에만 런타임 기능을 추가하며 Battle/Main 전투 코드는 변경하지 않음.

### Team Loadout Rebuild Step 2 — Persistence Only
- Step 1 로비 편성 UI에 영구 저장만 추가.
- 신규 `team_loadout_store.gd`에서 `user://team_loadout.json` 사용.
- 저장 데이터는 MonsterCatalog의 현재 ID 목록으로 검증하고 중복/잘못된 ID를 제거.
- 편성 변경 즉시 자동 저장, 로비 재진입 및 앱 재실행 시 복원.
- 최소 1종 / 최대 3종 제한 유지.
- Battle / Main 전투 파일은 수정하지 않았으며 저장된 편성은 아직 실제 전투 소환 슬롯에 적용되지 않음.

### Team Loadout Explicit Remove Controls
- 팀 편성 Step 2 UI에서 선택 토글만으로는 제외 방법이 불명확했던 문제 개선.
- 편성 슬롯 1~3 바로 아래에 각 슬롯 대응 `편성 해제` 버튼 추가.
- 빈 슬롯의 해제 버튼은 숨기고, 마지막 1종만 남았을 때는 해제 버튼을 비활성화.
- 해제 즉시 기존 team_loadout 저장 경로로 자동 저장.
- Battle / Main 전투 코드는 변경하지 않음.

### Team Loadout Slot Input Reliability Fix
- Android에서 별도 `편성 해제` 버튼의 pressed 입력이 반응하지 않는 문제 대응.
- 작은 해제 버튼 행을 제거하고 3개의 큰 편성 슬롯 자체를 Button으로 변경.
- 슬롯 안에 `편성 해제` 문구를 직접 표시하고 슬롯을 누르면 해당 몬스터를 제거.
- 팀 편성 관련 6개 버튼 연결을 런타임 `.connect()` 대신 `Lobby.tscn`의 명시적 signal connection으로 변경.
- 슬롯/몬스터 버튼에 명시적 touch mouse filter를 적용.
- 저장 로직과 Battle/Main 전투 코드는 변경하지 않음.

### Team Loadout Android State Sync Fix
- 모바일에서 편성 슬롯 터치는 들어오지만 화면은 3종, 내부 상태는 1종으로 판단되는 상태 불일치 수정.
- 로비 초기화의 `sort_custom` lambda를 제거해 Android 런타임 경로 단순화.
- `_refresh_team_preview()`의 임시 `Array[Button]` typed-array를 일반 Array로 변경해 노드 배열 변환 오류 가능성 제거.
- team loadout 저장 포맷을 version 2 Dictionary(`version`, `monster_ids`)로 변경.
- 기존 raw JSON Array 저장은 legacy로 간주하고 현재 기본 3종 편성으로 자동 초기화하여 이전 테스트 중 꼬인 저장 상태를 제거.
- 로비 진입 시 실제 로드된 편성 개수를 상태 문구로 표시해 실기기 확인 가능.
- Battle / Main 전투 코드는 변경하지 않음.

### Rollback: Team Loadout Android State Sync Attempt
- `76a51fe` 적용 후 Android에서 lobby.gd가 정상 초기화되지 않아 로비 스타일, 초상화, Stage 진행 표시가 기본 씬 값으로 보이는 회귀 발생.
- 직전 로비가 정상 표시되던 `fc147871880bccf550a537a50e117789097282ac`의 `lobby.gd`와 `team_loadout_store.gd`로 복구.
- 전투 코드와 기존 로비 씬은 변경하지 않음.
- 팀 편성 해제 동작 문제는 별도 로그/원인 확인 후 재수정.

### Team Loadout Android Refresh Fix
- Android에서 팀 편성 슬롯 터치는 들어오지만 실제 슬롯 표시가 갱신되지 않던 문제 수정.
- `_refresh_team_preview()`에서 임시 `Array[Button]` typed-array 생성을 제거.
- 슬롯 1~3 / 보유 몬스터 버튼 1~3을 각각 직접 갱신하는 작은 helper 함수로 교체.
- 편성 요약 문자열도 PackedStringArray 없이 일반 String 누적으로 단순화.
- 저장 모듈, Lobby 씬, Battle/Main 전투 코드는 변경하지 않음.

### Data-driven Monster Collection + Team Loadout UI
- 기존 Slime / Spider / Orc 고정 팀 편성 버튼 제거.
- MonsterCatalog에 명시적 ORDER와 `default_unlocked`, `shards_required` 데이터 추가.
- 신규 `monster_collection_store.gd`:
  - 몬스터별 해금 상태 / 조각 수 저장
  - 현재 해금 몬스터 ID 조회
  - 조각 추가 및 요구량 충족 시 자동 해금
- 팀 편성 UI를 MonsterCatalog 순회 방식으로 재작성:
  - 최대 3개 편성 슬롯 동적 생성
  - 해금 몬스터 카드 동적 생성
  - 미해금 몬스터는 조각 진행도와 함께 잠금 표시
  - 슬롯 또는 컬렉션 카드 탭으로 편성 추가/해제
- TeamLoadoutStore의 public Array 인자를 일반 Array로 완화해 JSON/동적 ID 목록과의 변환 의존을 줄임.
- 향후 상점 뽑기에서 조각 지급 → 자동 해금 → 팀 편성 반영으로 바로 연결 가능한 구조 확보.
- Battle / Main 전투 코드는 변경하지 않음.

### Supabase DB Foundation + Team Loadout Loading Fix
- Supabase `Again-Hero-` 프로젝트에 게임 계정/진행도 DB 기본 스키마 생성:
  - profiles
  - player_progress
  - monster_collection
  - team_loadout
- 모든 테이블에 RLS 및 자기 데이터 전용 정책 적용.
- 신규 Auth user profile/progress 자동 생성 trigger 추가, 외부 RPC 실행 권한은 제거.
- Godot용 Supabase REST client foundation 추가. publishable key만 사용하며 secret/service-role key는 포함하지 않음.
- 팀 편성 무한 `불러오는 중…` 문제 대응:
  - MonsterCollectionStore를 ConfigFile 기반으로 단순화
  - TeamLoadoutStore를 ConfigFile 기반으로 단순화
  - 팀 데이터 로드를 Lobby 시작 시가 아니라 팀 탭 진입 시로 격리
  - 동적 버튼 연결을 명시적 Callable.bind 경로로 정리
- 전투 Battle/Main 코드는 변경하지 않음.

### Team Loadout Infinite Loading Fix — Static Controls
- 팀 편성 탭이 `편성 불러오는 중…`에서 멈추고 슬롯/컬렉션이 표시되지 않는 문제 대응.
- 런타임 동적 Button 생성 방식을 제거하고 Lobby 씬에 편성 슬롯 3개와 ItemList 1개를 고정 배치.
- 몬스터 종류는 MonsterCatalog 순회로 계속 동적 생성되므로 신규 몬스터 추가 시 UI 하드코딩 불필요.
- 팀 탭 진입 즉시 Catalog 기본 해금 몬스터를 먼저 표시한 뒤, 저장 데이터는 다음 프레임에 deferred load.
- 저장/컬렉션 로드 오류가 생겨도 기본 팀 UI가 이미 보이도록 로딩 경로를 분리.
- Battle/Main 및 Supabase DB 스키마는 변경하지 않음.

### Team Loadout UI Recovery — Catalog Only
- 팀 편성 탭이 정적 슬롯까지 표시한 뒤 컬렉션/목록이 비어 있는 문제를 격리.
- 팀 UI 초기화 경로에서 MonsterCollectionStore / TeamLoadoutStore 로드를 임시 제거하고 MonsterCatalog만 순회해 즉시 편성 UI 생성.
- 현재 Catalog의 몬스터를 최대 3종 기본 편성으로 표시하고 ItemList 탭으로 추가/해제 가능.
- 고정되는 것은 슬롯 수 3개뿐이며 몬스터 종류는 Catalog 기반이라 신규 몬스터 추가 시 UI 코드 변경 불필요.
- 저장/조각 해금 데이터 연동은 UI 실기기 동작 확인 후 다시 단계적으로 연결.
- Battle/Main/Supabase DB는 변경하지 않음.

### Team Loadout Catalog-only Hard Isolation
- 팀 탭은 열리지만 Summary/슬롯/ItemList가 씬 기본값에서 갱신되지 않는 문제를 추가 격리.
- Lobby 팀 UI에서 MonsterCollectionStore / TeamLoadoutStore preload 및 런타임 참조를 일시 제거.
- 팀 탭 전환 시 nav 스타일 갱신보다 팀 UI 초기화를 먼저 실행하도록 순서 변경.
- 팀 UI는 MonsterCatalog 하나만 순회해 즉시 최대 3종 기본 편성과 ItemList를 구성.
- 슬롯 수 3은 게임 규칙 상수 `TEAM_MAX_SLOTS`로만 유지하며 몬스터 종류는 하드코딩하지 않음.
- 이 기준점에서 추가/해제 UI 동작을 먼저 실기기 검증한 뒤 저장/해금 상태를 재연결.
- Battle/Main/Supabase DB는 변경하지 않음.

### Team Collection Explicit Tab Handler Fix
- 팀 편성 탭은 열리지만 Monster Collection 목록이 생성되지 않아 편성/해제 테스트가 불가능한 문제 수정.
- TeamButton을 generic `_switch_tab.bind("team")`에서 전용 `_on_team_tab_pressed()` 핸들러로 분리.
- 전용 핸들러가 TeamTab 표시 직후 MonsterCatalog 기반 컬렉션 생성을 직접 호출.
- `_setup_team_preview()`에서 ItemList를 먼저 비우고 Catalog 항목을 즉시 추가한 뒤 슬롯/선택 표시만 갱신.
- 상태 문구에 Catalog 확인 수 / 컬렉션 표시 수를 노출해 PC/Android에서 호출 경로를 화면만으로 검증 가능.
- 편성 변경 시 ItemList를 재생성하지 않고 기존 항목 text만 갱신.
- 저장/해금/Supabase/전투 코드는 변경하지 않음.

### Team Collection Catalog Static-call Bypass
- 팀 전용 handler가 `컬렉션 생성 중…`까지 실행된 뒤 목록 생성 전 중단되는 증상으로 MonsterCatalog static helper 호출 경로를 격리.
- 팀 편성 UI에서는 `MonsterCatalog.get_ids/get_name/get_role/get_base_cost` 호출을 사용하지 않고 `ORDER / MONSTERS / ROLE_LABELS` 데이터 상수만 직접 읽도록 변경.
- 신규 몬스터는 계속 MonsterCatalog 데이터만 추가하면 팀 컬렉션에 자동 포함되므로 콘텐츠 하드코딩은 없음.
- 단계 상태 문구를 `Catalog 원본 데이터 확인 중 → Catalog N종 확인 → 컬렉션 N종 표시 완료`로 세분화.
- 저장/해금/Supabase/전투 코드는 변경하지 않음.

### Team Loadout Persistence Reconnected
- 정상 동작이 확인된 Catalog-only 팀 편성 UI 위에 편성 저장만 재연결.
- 팀 탭은 기존처럼 Catalog 기본 편성을 먼저 즉시 렌더링하고, 다음 프레임에 `team_loadout.cfg` 저장값을 복원.
- 편성 추가/해제 직후 자동 저장 및 성공/실패 상태 문구 표시.
- TeamLoadoutStore의 typed Array 반환/내부 배열을 일반 Array로 단순화해 Android 호환 경로 보강.
- MonsterCollection/조각 해금 및 Battle/Main 전투 편성 연결은 아직 제외.
- 향후 팀 편성 UI의 바둑판형 몬스터 카드 + 도트 이미지 개편을 ROADMAP에 추가.

### Monster Collection Unlock / Shards Reconnected
- 정상 동작이 확인된 팀 편성 UI/저장 위에 MonsterCollection 상태만 재연결.
- Collection 저장은 `user://monster_collection.cfg`를 사용.
- MonsterCollectionStore의 Catalog 접근을 static helper 호출 대신 `ORDER / MONSTERS` 직접 순회로 통일.
- 팀 UI를 먼저 렌더링한 후 deferred 복원 단계에서 해금 몬스터 목록과 저장 편성을 함께 정규화.
- 미해금 몬스터는 조각 진행도를 표시하고 ItemList 선택을 비활성화.
- `add_shards()`는 요구량 도달 시 자동 해금하는 상점 연동용 API로 유지.
- Battle/Main 전투 코드는 변경하지 않음.

### Saved Team Loadout → Battle Summon Slots
- 로비에서 저장한 팀 편성을 전투 하단 소환 슬롯에 연결.
- 전투 진입 시 해금 몬스터 목록과 저장 편성을 로드해 유효한 최대 3종만 사용.
- 미편성 몬스터의 기존 고정 버튼은 숨기고, 편성된 몬스터만 비용과 함께 표시.
- 자동/수동 소환 입력 모두 편성 여부를 추가 검증.
- Battle 로직은 건드리지 않아 기존 소환/남은 시간/메뉴 동작 경로를 유지.

### Team Loadout → Battle Summon UI Step 1
- 저장된 팀 편성을 전투 하단 소환 UI에 연결.
- 기존 3개 버튼의 slime/spider/orc 고정 signal bind 제거.
- 버튼을 편성 슬롯 1~3으로 재사용해 저장된 monster_id 순서대로 동적 소환.
- 편성되지 않은 남는 슬롯 버튼은 숨김.
- 버튼 이름/비용은 실제 편성 monster_id와 Battle의 현재 비용 계산을 사용.
- 전투 편성 로드는 MonsterCollection을 다시 거치지 않고 Lobby와 동일한 `team_loadout.cfg`를 직접 읽어 이전 로딩 회귀 가능성을 줄임.
- Battle.gd는 변경하지 않아 타이머/메뉴/소환 핵심 로직 회귀 범위를 제한.

### Battle Runtime Team Loadout Guard
- 저장 편성에 없는 monster_id가 다른 호출 경로로 Battle에 전달되어도 소환되지 않도록 런타임 guard 추가.
- Main이 로드한 편성 목록을 `Battle.set_allowed_monster_ids()`로 전달.
- Battle은 TeamLoadoutStore/ConfigFile을 직접 읽지 않음.
- 자동 소환과 수동 배치가 공통으로 사용하는 `_can_attempt_summon()`에서 비편성 몬스터 요청을 거부.
- 편성 전달이 비정상적으로 비어 있으면 guard를 활성화하지 않는 fail-open 구조로 기존 전투 회귀 위험 최소화.

### Team Loadout Grid Card UI v1
- 팀 편성 컬렉션을 세로 텍스트 목록에서 3열 바둑판 카드형 ItemList로 개편.
- 기존 안정화된 ItemList 이벤트 경로는 유지해 동적 Button 회귀 위험을 피함.
- 카드에 몬스터 이름 / 역할 / 비용 / 편성 상태 / 잠금 조각 진행도 표시.
- 편성/일반/잠금 상태별 카드 색상 구분 및 잠금 카드 선택 비활성화.
- 실제 몬스터 도트 연결을 위한 optional `card_icon_path` 로딩 훅 추가.
- 현재 monster sprite asset이 저장소에 아직 없으므로 실제 도트 이미지는 후속 에셋 커밋 후 연결.
- 팀 편성 저장 및 Battle 연결 로직은 변경하지 않음.

### Monster Dot Icons Connected to Team Cards
- 새로 추가된 Slime / Spider / Orc 프레임 에셋을 팀 편성 카드에 실제 도트 이미지로 연결.
- 각 몬스터의 `frames/idle_01.png`를 카드 대표 이미지로 사용.
- `MonsterCatalog`에 optional `card_icon_path` 실제 값을 추가해 기존 데이터 기반 카드 로더가 자동 표시.
- 팀 편성 ItemList에 nearest texture filter를 적용해 픽셀아트 확대 시 블러를 방지.
- 전투 애니메이션 자체는 아직 변경하지 않음.

### Monster Battle Pixel Animations v1
- Slime / Spider / Orc 전투 비주얼을 임시 draw 도형에서 실제 사용자 제공 PNG 프레임 기반 AnimatedSprite2D로 전환.
- 공통 `monster_visual.gd`가 idle / move / attack / hit / death 프레임을 런타임 SpriteFrames로 구성하고 캐시.
- 몬스터 행동 상태에 따라 이동/공격/피격/사망 애니메이션 연결.
- Spider는 hit 전용 프레임이 없어 짧은 피격 tint 사용.
- death 판정/보상 신호는 즉시 유지하고 visual queue_free만 death 애니메이션 종료까지 지연.
- 프레임 원본 크기 차이는 몬스터별 target height로 정규화.
- PNG 로딩 실패 시 기존 draw 비주얼 fallback 유지.
- Battle/Main의 소환·편성·시간·메뉴 로직은 변경하지 않음.

### Fix Monster AI Stalling After Pixel Animation
- 실제 도트 애니메이션 연결 후 몬스터가 움직이지 않고 Hero의 `monsters` group 탐색에도 잡히지 않는 회귀를 수정.
- 몬스터 부모 스크립트에서 `MonsterVisual` custom class 타입 의존을 제거.
- 비주얼 호출을 `has_method()/callv()` 기반 optional bridge로 분리해 Visual 초기화 실패가 몬스터 AI 전체를 중단시키지 않도록 변경.
- death animation signal도 동적 존재 확인 후 연결.
- 이동, 공격, group 등록, 충돌, HP 로직 자체는 기존 CharacterBody2D 경로 유지.

### Monster Shard Shop v1
- 로비 상점 탭에 실제 몬스터 조각 상품 UI 추가.
- MonsterCatalog 기반 상품 생성으로 Slime / Spider / Orc 조각 +10 상품 제공.
- 연구 포인트를 임시 상점 재화로 사용하고 StageProgress에 안전한 포인트 차감 API 추가.
- 구매 결과를 MonsterCollectionStore.add_shards()에 연결해 조각 저장 및 요구량 도달 시 자동 해금.
- 상점에서 변경된 Collection 상태는 팀 편성 탭 재진입 시 즉시 반영.
- 현재 기본 3종의 default unlocked 상태는 기존 사용자 편성 회귀 방지를 위해 유지.

### Monster Shard Chest Gacha v2
- 상점을 몬스터별 조각 직접 구매에서 무작위 상자 가챠로 교체.
- 테스트 골드 99,999를 고정 표시하고 구매 시 차감하지 않도록 설정.
- 1회 100골드 / 10+1회 1,000골드 UI 추가.
- `shop_catalog.gd`에 등급별 확률 및 조각 범위 데이터화.
- 현재 확률: 일반 70% / 희귀 25% / 최고등급 5%.
- 현재 조각 범위: 일반 10~30 / 희귀 3~8 / 최고등급 1.
- Slime=일반, Spider=희귀, Orc=최고등급으로 테스트 등급 지정.
- 11연속 추첨 결과를 몬스터별 총 조각으로 합산 표시하고 새 해금 결과도 함께 표시.
- 연구 포인트 상점 소비 제거; 연구 포인트는 연구 시스템에서만 사용.

### Locked Monster Full-loop Test: Bomb Rat
- 4번째 몬스터 `bomb_rat` 추가.
- 기본 잠금 + 희귀 등급 + 해금 요구 조각 30으로 설정해 가챠/조각/자동 해금 흐름을 실제 검증 가능하게 함.
- 소환 비용 12, HP 36, 빠른 이동, 저피해 근접 공격, 사망 시 반경 150 내 Hero에게 28 폭발 피해.
- MonsterCatalog에 burst 역할 및 폭발 역할 라벨 추가.
- 전용 아트가 없어 현재는 코드 드로잉 플레이스홀더 사용.
- 기존 Slime / Spider / Orc와 Battle/Main/Team 로직은 변경하지 않음.

### Hero Ultimate Gauge v1
- Hero HP바 위에 노란색 필살기 게이지 추가.
- 시간 경과 / 공격 / 피격으로 게이지가 충전되고 100% 도달 시 자동 발동.
- HeroProfiles에 용사별 필살기 ID/이름/충전 규칙/피해/범위를 데이터화.
- 견습 마도사 `마력 폭발`, 기동 사냥꾼 `사냥꾼의 일제사격` 설정 추가.
- 공통 `area_burst` 실행기로 주변 몬스터에게 기존 take_damage 경로를 통한 피해 적용.
- 발동 순간 노란 원형 플래시 시각 피드백 추가.
- Battle/Main 소환 및 타이머 로직은 변경하지 않음.

### Bomb Rat Pixel Sprite Sheet Connected
- 사용자 제공 `assets/art/monsters/bombrat/bombrat_spritesheet.png`를 전투 폭탄쥐 비주얼에 연결.
- 전용 `bomb_rat_visual.gd`가 통합 시트의 정사각 셀 그리드를 런타임 감지하고 idle / move / attack / hit / death 행을 AnimatedSprite2D로 구성.
- 5행 시트는 idle/move/attack/hit/death, 4행 시트는 idle/move/attack/death로 처리하며 hit 행이 없으면 기존 피격 tint를 fallback으로 사용.
- 폭탄쥐 이동/공격/피격/사망 상태를 애니메이션과 연결.
- 사망 폭발 피해와 died 신호는 기존 시점에 즉시 처리하고, 노드 제거만 death 애니메이션 종료까지 지연.
- 시트 로딩/레이아웃 감지 실패 시 기존 코드 드로잉 폭탄쥐가 그대로 표시되는 fail-safe 유지.
- Battle/Main의 타이머, 소환, 메뉴, 편성 로직과 폭탄쥐 전투 수치는 변경하지 않음.

### Bomb Rat Sprite Sheet Android Loader Fix
- 폭탄쥐 통합 PNG를 CPU Image로 다시 읽어 알파 픽셀을 검사하던 런타임 경로를 제거.
- Android에서도 Godot가 이미 import한 Texture2D의 width/height만 사용해 정사각 셀 그리드를 감지하도록 단순화.
- AtlasTexture가 원본 시트를 직접 참조하도록 변경해 PNG 디코딩/읽기 실패 시 플레이스홀더로 떨어지던 가능성을 제거.
- 3~6행 / 2~12열 범위의 일반적인 통합 시트를 지원하고 4행/5행 레이아웃을 우선 선택.
- 성공 시 실제 감지된 sheet/grid/cell 크기를 로그에 출력해 실기기 확인 가능.

### Bomb Rat Sprite Sheet Exact Grid Fix
- 실제 원본 `bombrat_spritesheet.png`를 직접 확인해 1374×1145 크기, 229×229 셀, 6열×5행 구조로 확정.
- 기존 자동 셀 크기 감지를 제거하고 폭탄쥐 시트 전용 정확한 AtlasTexture 좌표를 사용.
- 애니메이션 프레임 수를 실제 시트에 맞춰 idle 4 / move 6 / attack 6 / hit 3 / death 4로 지정.
- 잘못된 빈 셀 재생과 Android에서 visual fallback으로 떨어지던 원인을 제거.
- 시트 크기가 예상 규격과 다를 경우 기존 코드 드로잉 fallback을 유지.

### Bomb Rat Scene-bound Texture Fix
- 폭탄쥐 PNG를 런타임 경로 문자열로 load하지 않고 `BombRat.tscn`의 Texture2D ext_resource로 직접 참조하도록 변경.
- `bomb_rat_visual.gd`는 씬에서 주입된 `source_sheet`만 사용해 AtlasTexture 프레임을 구성.
- Android/PC에서 런타임 ResourceLoader 경로 차이로 `visual_ready=false`가 되어 코드 드로잉 fallback이 표시될 가능성을 제거.
- 폭탄쥐 시트 규격은 229×229 셀, 6×5 그리드와 실제 프레임 수를 그대로 유지.

### Rollback: Bomb Rat Static SpriteFrames Attempt
- `e79dd94`의 BombRat.tscn 정적 AtlasTexture/SpriteFrames 연결 후 로비 초기화와 버튼 입력이 깨지는 회귀가 발생해 해당 변경을 롤백.
- 로비/전투 안정성을 우선해 BombRat.tscn과 bomb_rat.gd를 직전 정상 상태로 복구.
- 폭탄쥐 도트는 별도 안전한 방식으로 다시 연결 예정.

### Bomb Rat Sprite Sheet — Stage 1 Hero Loader Pattern
- 폭탄쥐 도트 로딩을 Stage 1 견습 마도사의 검증된 통합 스프라이트시트 방식과 동일하게 재구성.
- `BombRat.tscn`의 전용 visual script / Texture2D ext_resource 의존을 제거하고 일반 AnimatedSprite2D만 유지.
- `bomb_rat.gd`가 `ResourceLoader.exists()+load()`를 우선 사용하고, Android Editor import 캐시가 늦을 경우 `FileAccess + Image.load()` fallback을 사용.
- 통합 PNG를 229×229 고정 셀로 AtlasTexture 분할해 idle 4 / move 6 / attack 6 / hit 3 / death 4 SpriteFrames를 런타임 생성.
- Base64, 자동 셀 감지, 씬 정적 AtlasTexture는 사용하지 않음.
- 시트 로딩 실패 시에만 기존 코드 드로잉 폭탄쥐 fallback을 유지하며 전투/로비 로직은 변경하지 않음.

### Bomb Rat Team Card Icon
- 폭탄쥐 팀 편성 카드에 통합 스프라이트시트의 idle 첫 프레임을 대표 아이콘으로 연결.
- MonsterCatalog에 optional `card_icon_region` 데이터를 추가해 개별 PNG 없이 통합 시트 일부 영역을 카드 아이콘으로 사용할 수 있도록 확장.
- 폭탄쥐는 `bombrat_spritesheet.png`의 첫 229×229 셀을 사용.
- 기존 Slime / Spider / Orc 개별 아이콘 경로와 팀 편성 저장/전투 로직은 변경하지 않음.

### Bomb Rat Self-Destruct Combat Identity v1
- 폭탄쥐 이동속도를 145 → 175로 상향하고 반복 근접 평타를 제거.
- Hero와 78px 안으로 접근하면 0.30초 자폭 준비 후 한 번 폭발하고 사망하도록 변경.
- 자폭 성공 시 기존 반경 150 / 피해 28 폭발을 적용하고 EXP 10 구슬을 드롭.
- 자폭 준비 중을 포함해 Hero 공격으로 먼저 처치되면 폭발하지 않고 EXP 30 구슬을 드롭.
- Battle의 기존 사망/EXP Orb 경로는 수정하지 않고, 폭탄쥐가 사망 원인에 따라 `exp_reward`를 설정한 뒤 기존 `died` 신호를 보내는 방식으로 연결.
- HP 36과 소환 비용 12는 유지.

### Character Collision Radius Pass v1
- 실제 도트 몸통 크기에 맞춰 Hero / Slime / Spider / Orc / Bomb Rat의 CircleShape2D 반경을 1차 조정.
- Hero 34→28, Slime 29→22, Spider 25→20, Orc 39→32, Bomb Rat 24→20.
- 무기, 다리 끝, 꼬리, 폭탄 같은 외곽 장식은 물리 충돌 반경에 포함하지 않는 기준 적용.
- 폭탄쥐의 자폭 시작 거리 78px 및 폭발 피해 반경 150px은 충돌 반경과 별도 판정으로 유지.
- 공격 사거리, 이동속도, HP, 피해량, 소환 비용 등 전투 밸런스 값은 변경하지 않음.

### Per-Run Research Point Rewards v1
- 최초 클리어 전에도 패배 Run을 반복해 연구 내실을 쌓을 수 있도록 정상 Run 종료 연구 포인트 지급 추가.
- 기본 +5 / Hero HP 10% 감소마다 +2(최대 20) / 60초마다 +1(최대 10) / Hero 증강 관찰 1회당 +1(최대 5).
- 반복 Run 연구 보상 최대 40.
- 시간 초과 패배와 Stage Clear 모두 반복 보상을 지급.
- 기존 Stage 최초 클리어 연구 포인트 100/150은 별도 보너스로 유지.
- 결과창 메시지에 Run 연구 보상 총량과 기본/피해/시간/관찰 내역 표시.
- 재시작/로비 이탈에는 보상을 지급하지 않아 즉시 반복 파밍을 방지.

### Research Economy Rebalance v2
- 패배 누적 성장 체감을 높이기 위해 반복 Run 연구 보상을 대폭 상향.
- 기본 +80 / Hero HP 10% 감소마다 +6(최대 60) / 60초마다 +5(최대 30) / Hero 증강 관찰 1회당 +4(최대 20).
- 반복 Run 보상 총 상한을 160으로 설정해 일반적인 완료 Run이 약 110~160 포인트를 주도록 조정.
- 최초 클리어 연구 보상: Stage 1 100→500, Stage 2 150→750.
- 연구 비용을 새 경제에 맞춰 상향:
  - 마력 저장고 150/250/400
  - 마력 순환 180/300/450
  - 슬라임 배양 최적화 150/250/400
  - 전술 기록 노트 220/350/500
  - 고속 실험법 200/320/480
- 영구 연구 효과 강화:
  - 최대 지휘력 +10→+20/레벨
  - 지휘력 회복 +0.25→+0.5/초/레벨
  - 슬라임 비용 -5%→-8%/레벨
  - 마왕 EXP 획득 +5%→+10%/레벨
  - 증강 새로고침 +1/레벨은 유지.

### Bomb Rat Explosion Effect Connected
- 사용자 제공 `bombrat_effect_spritesheet.png`를 폭탄쥐 자폭 순간에 실제 전투 이펙트로 연결.
- 시트 규격 2172×724를 724×724 셀 3프레임 가로 애니메이션으로 사용.
- 기존 Stage 1 Hero/Bomb Rat와 동일한 ResourceLoader 우선 + FileAccess/Image fallback 방식으로 Android import 지연에도 대응.
- 자폭 완료 순간 이펙트를 재생한 뒤 기존 폭발 피해/사망/EXP 신호 흐름을 그대로 실행.
- 시각 효과 크기는 기존 폭발 반경 150px에 맞춰 약 300px 지름으로 표시.
- Hero에게 먼저 처치된 폭탄쥐는 자폭 이펙트를 재생하지 않음.
- 로비/UI/팀 편성/EXP 시스템은 변경하지 않음.

### Core Permanent Research Expansion
- 영구 연구를 군단 전체 성장 중심으로 개편.
- 신규 기본 연구 추가:
  - 군단 화력: 모든 몬스터 공격력 +10%/레벨
  - 군단 생체 강화: 모든 몬스터 최대 HP +12%/레벨
  - 군단 기동 연구: 모든 몬스터 이동속도 +8%/레벨
  - 군단 공격 훈련: 공격 주기 -7%/레벨
  - 소환 효율화: 모든 몬스터 소환 비용 -5%/레벨
- 기존 마력 순환 / 마력 저장고 / 고속 실험법을 5레벨 연구로 확장.
- 슬라임 전용 비용 감소 연구를 제거하고 전체 몬스터 비용 감소 연구로 교체.
- 폭탄쥐는 군단 화력 연구가 자폭 피해에, 공격속도 연구가 자폭 준비시간에 적용되도록 연결.
- 모든 몬스터 HP/이동속도/일반 공격 피해에 영구 연구 배율을 소환 시 적용.
- 전술 기록 노트(+증강 새로고침)는 보조 연구로 유지.
- 연구 UI/저장/구매는 기존 Catalog 기반 경로를 그대로 사용해 신규 연구가 자동 표시되도록 유지.

### Research Cost Curve Rebalance v3
- 연구 첫 레벨 비용을 150~220대에서 35~80대로 크게 낮춤.
- 2레벨부터 비용 상승폭을 높여 초반 진입은 빠르고 후반 완성은 오래 걸리는 곡선으로 변경.
- 5레벨 연구 예시 비용:
  - 군단 화력 / 생체 강화: 40 / 90 / 180 / 320 / 520
  - 군단 기동: 35 / 80 / 160 / 290 / 480
  - 군단 공격 훈련: 45 / 100 / 200 / 350 / 560
  - 소환 효율화: 45 / 110 / 220 / 380 / 600
  - 마력 순환: 50 / 120 / 240 / 400 / 620
  - 마력 저장고: 40 / 100 / 200 / 340 / 550
  - 고속 실험법: 50 / 130 / 260 / 420 / 650
- 전술 기록 노트는 80 / 220 / 500으로 조정.
- 연구 효과 수치는 변경하지 않음.

### Long-term Research Progression v4
- 기본 스탯 연구를 5레벨 단기 구조에서 70레벨 장기 성장 구조로 전환.
- 군단 화력: +1% 공격력/Lv, 최대 70레벨.
- 군단 생체 강화: +1% HP/Lv, 최대 70레벨.
- 군단 기동: +0.35% 이동속도/Lv, 최대 70레벨.
- 군단 공격 훈련: +0.5% 공격속도/Lv, 최대 70레벨.
- 공격속도 연구는 공격 쿨다운/폭탄쥐 자폭 준비시간에 안전한 역수 배율로 적용.
- 소환 효율화는 최대 20레벨, -1% 비용/Lv(최대 -20%)로 조정.
- 마력 순환은 최대 30레벨, +0.15 지휘력/초/Lv로 조정.
- 마력 저장고는 최대 30레벨, +5 최대 지휘력/Lv로 조정.
- 고속 실험법은 최대 20레벨, +3% 마왕 EXP/Lv로 조정.
- 기본 스탯 연구는 10~15 포인트에서 시작하고 약 6.5~6.8% 지수 성장.
- 경제/자원 연구는 70~90 포인트에서 시작하고 약 11.5~14% 지수 성장.
- 기존 고정 `costs[]` 배열을 제거하고 레벨 기반 비용 공식으로 변경.
- 기존 연구 저장 ID는 유지해 이미 구매한 연구 레벨은 그대로 이어서 사용.

### Research List Recovery Fix
- 장기 연구 비용 공식 적용 후 연구 탭에서 포인트만 표시되고 영구 연구 버튼이 사라지는 문제 대응.
- 비용 계산에서 `pow()/round()` 의존을 제거하고 레벨 수만큼 성장률을 누적하는 단순 계산으로 변경.
- 연구 목록 재생성 시 `queue_free()` 지연 삭제 대신 기존 버튼을 즉시 제거/해제한 뒤 새 목록을 생성하도록 안정화.
- 연구 탭 상태 문구에 현재 Catalog 연구 항목 수를 표시해 실기기에서 목록 생성 여부를 바로 확인 가능하게 함.
- 저장된 연구 레벨 및 연구 포인트 데이터는 변경하지 않음.

### Research Purchase UI Rebuild Timing Fix
- 연구 구매 버튼을 누른 직후 해당 버튼 자신을 포함한 목록 노드를 즉시 free하면서 앞쪽 연구 항목이 사라지는 UI 문제 수정.
- 구매/저장 처리가 끝난 뒤 deferred 시점에 연구 목록을 다시 생성하도록 변경.
- 연구 포인트, 연구 레벨, 비용 공식, 연구 효과 값은 변경하지 않음.

### Research Cost Growth Rebalance v5
- Stage 1 최초 클리어 후 기본 스탯을 한 번에 약 20레벨까지 올릴 수 있던 연구 성장 속도를 완화.
- 기본 스탯 Lv.1 비용 10~15는 유지.
- 비용 성장률 상향:
  - 군단 화력 6.5% → 15%
  - 군단 생체 강화 6.5% → 15%
  - 군단 기동 6.8% → 16%
  - 군단 공격 훈련 6.7% → 15%
- 전술 기록 노트 비용을 일반 공식에서 분리하고 1000 / 3000 / 5000 연구 포인트로 고정.
- 연구 효과와 최대 레벨, 기존 저장 연구 레벨은 변경하지 않음.

### EXP Stone Pixel Visuals v1
- 기존 코드 드로잉 EXP Orb를 사용자 제공 `assets/art/effects/expstone` 등급별 6프레임 픽셀 애니메이션으로 연결.
- 각 프레임은 64×56이며 nearest 필터로 약 42px 높이로 표시.
- EXP 값에 따라 등급 자동 선택:
  - 1~15 일반
  - 16~30 고급
  - 31~50 희귀
  - 51~80 영웅
  - 81~120 전설
  - 121~200 신화
  - 201+ 초월
- 현재 전투 기준 폭탄쥐 자폭 EXP 10은 일반, Slime 25 / Spider 30 / 폭탄쥐 Hero 처치 30은 고급, Orc 40은 희귀로 표시.
- 기존 EXP 값, 드롭 위치, 자석화, 획득 범위, Hero EXP 지급 로직은 변경하지 않음.
- 프레임 로딩 실패 시 기존 파란 원형 EXP Orb 드로잉으로 자동 fallback.

### Stage 1 Piercing Ultimate v1
- Stage 1 견습 마도사의 기존 자동 광역 폭발 필살기를 `마력 관통포`로 교체.
- 기존 필살기 게이지 충전 로직은 유지하고 100% 충전 시 자동 발동.
- 가장 가까운 몬스터 방향으로 대형 직선 투사체를 발사하며, 동일 몬스터는 1회만 맞고 여러 몬스터를 관통 가능.
- 초기 수치: 피해 110 / 사거리 900 / 속도 950 / 충돌 크기 116×56.
- `assets/art/heroes/stage1_mage/effect_01/frame_01~06.png`를 6프레임 반복 애니메이션으로 연결.
- 기존 일반 Hero 투사체와 Stage 2 `area_burst` 필살기 경로는 변경하지 않음.

### Stage 1 Arcane Barrier v1
- Stage 1 견습 마도사에 관통포와 별도 쿨다운으로 작동하는 두 번째 스킬 `마력 장벽` 추가.
- 초기 8초 후 사용 가능, 사용 후 쿨다운 18초.
- HP 75% 이하 또는 주변 300px 내 몬스터 3마리 이상일 때 자동 발동.
- 최대 HP의 30%만큼 별도 Shield HP 생성, 최대 8초 유지.
- 피격 시 Shield HP가 먼저 피해를 흡수하고 남은 피해만 Hero HP에 적용.
- 보호막 활성 중 HP바 아래에 파란 Shield 게이지 표시.
- `assets/art/heroes/stage1_mage/effect_02/frame_01~06.png`를 루프 애니메이션으로 연결.
- 기존 관통포 게이지/일반 공격/Stage 2 필살기 로직은 변경하지 않음.

### Stage 1 Arcane Barrier Ground Placement Fix
- `effect_02` 보호막 마법진을 Hero 몸 중심에서 발밑으로 이동.
- ShieldEffect 위치를 아래쪽으로 44px 내리고 Y축 스케일을 0.62로 눌러 바닥에 깔린 원형 마법진처럼 보이도록 조정.
- 보호막 HP, 지속시간, 쿨다운, 피해 흡수 로직은 변경하지 않음.

### Stage 1 Arcane Channel v1
- Stage 1 견습 마도사에 세 번째 스킬 `비전 집중` 추가.
- 초기 12초 후 사용 가능, 사용 후 쿨다운 16초.
- 주변 210px 내 몬스터 4마리 이상이면 자동 발동.
- 2.5초 동안 제자리 채널링하며 0.25초마다 반경 210px 내 몬스터에게 14 피해.
- 채널링 중 Hero 이동과 일반 공격을 중단.
- `assets/art/heroes/stage1_mage/effect_03/frame_01~06.png`를 채널링 루프 이펙트로 연결.
- 기존 관통포/마력 장벽/Stage 2 필살기 로직은 유지.

### Stage 1 Shared Ultimate Gauge Fix
- 마력 장벽(2번)은 기존처럼 노란 게이지와 무관한 독립 쿨다운 스킬로 유지.
- 마력 관통포(1번)와 비전 집중(3번)을 동일한 노란 필살기 게이지 100%를 소비하는 구조로 수정.
- 관통포 14초 / 비전 집중 16초의 개별 쿨다운 적용.
- 게이지 100% 시 주변 210px 내 몬스터 4마리 이상이고 3번이 준비됐으면 비전 집중 우선 사용.
- 그 외에는 관통포가 준비됐을 때 관통포 사용.
- 둘 다 쿨다운 중이면 게이지를 100%로 유지하며 준비될 때까지 대기.
- 비전 집중의 기존 독립 자동발동 타이머를 제거.

### Stage 1 Channel Basic Attack Lock Fix
- 비전 집중(3번) 채널링 중 평타가 끼어들어 모션이 겹치는 문제 수정.
- 채널링 중 `_fire_projectile()` 자체를 차단하는 가드 추가.
- 3스 시작 시 평타 공격 타이머를 채널링 종료 시점까지 잠금.
- 채널링 중 일반 이동/포즈 갱신을 중단하고 Hero 본체는 공격 애니메이션 대신 idle 상태를 유지.
- 3스의 실제 시각 표현은 `effect_03`이 담당하도록 정리.
- 관통포/보호막/3스 피해 수치와 쿨다운은 변경하지 않음.

### Stage 1 Channel Duplicate Hero Visual Fix
- `effect_03` 채널링 프레임 자체에 Hero 캐릭터가 포함되어 있어 기존 HeroSprite와 겹쳐 2명처럼 보이던 문제 수정.
- 비전 집중 시작 시 기존 HeroSprite를 임시 숨기고 `effect_03`만 표시.
- 채널링 종료 시 기존 HeroSprite를 다시 표시하고 idle 애니메이션으로 복귀.
- 3스 피해, 지속시간, 쿨다운, 노란 게이지 운용 규칙은 변경하지 않음.

### Stage 1 Ultimate Selection AI Rebalance
- 노란 게이지 100% 시 1번/3번 선택을 상황형으로 세분화.
- 관통포 쿨다운 14초 → 12초, 비전 집중 쿨다운 16초 → 18초.
- 비전 집중은 반경 210px 내 5마리 이상 또는 4마리 이상 + 135px 내 2마리 이상일 때만 우선 선택.
- 관통포는 가장 가까운 적 단일 조준 대신 사거리 내 후보 방향을 비교해 직선 경로에 가장 많은 몬스터가 들어오는 방향을 선택.
- 둘 다 쿨다운이면 기존처럼 노란 게이지 100%를 유지.
- 마력 장벽의 발동 조건/쿨다운/실드량은 변경하지 않음.

### Demon Ultimate Gauge + Encirclement v1
- 마왕 전용 공용 필살기 게이지와 인게임 3버튼 HUD 추가.
- 게이지 충전: 초당 +1 / 일반 소환 비용×1.2 / Hero 실제 HP 피해×0.25.
- 게이지 100에서 플레이어가 직접 필살기를 선택하며 사용 시 0으로 소모.
- 1번 `원형 포위` 구현: 현재 편성 몬스터 12마리를 Hero 기준 약 700px 원주에 균등 무료 소환.
- 원형 포위 소환은 지휘력과 마왕 EXP를 소비/획득하지 않음.
- 2번 `일직선 공세`, 3번 `사각 포위`는 HUD에 준비중으로 표시하고 비활성화.
- 마왕 필살기 데이터는 `demon_ultimate_catalog.gd`로 분리.
- 기존 일반 소환, 마왕 증강, 용사 필살기/보호막 로직은 변경하지 않음.

### Demon Encirclement Spawn Performance Fix
- 원형 포위 발동 시 12마리를 한 프레임에 모두 생성하던 구조를 분산 스폰 큐 방식으로 변경.
- 기본값은 0.04초 간격으로 2마리씩 생성해 약 0.2초 안에 12마리 소환 완료.
- 필살기 게이지는 기존처럼 버튼 입력 시 즉시 소모하며, 분산 소환 중 중복 원형 포위 시작을 차단.
- 원형 위치, 총 소환 수, 편성 몬스터 순환, 무료 소환 규칙은 유지.
- 분산 스폰 간격/배치 수는 `demon_ultimate_catalog.gd` 데이터로 조정 가능.

### Battle HUD Cleanup v1
- 전투 화면을 가리던 DebugBalance 텍스트를 기본 숨김 처리.
- 마왕 필살기 게이지/3버튼 영역 높이를 줄이고 폰트/간격을 정리.
- 용사 빌드와 상태 문구를 하단 상단부의 한 줄 요약 영역으로 압축.
- 자동 배치 토글을 상태 문구 오른쪽으로 정렬.
- 마왕 Lv/EXP와 지휘력 게이지의 라인 높이/간격을 통일.
- 소환 카드 3개는 하단에서 더 큰 터치 영역을 유지하도록 재배치.
- 전투, 소환, 마왕 필살기, 용사 AI 로직은 변경하지 않음.

### Battle Viewport / Demon Ultimate Strip Separation Fix
- 마왕 필살기 스트립이 전투 화면 위에 겹쳐 몬스터를 가리던 문제 수정.
- BattleViewportContainer 하단을 필살기 스트립 상단까지 올려 전투 영역과 HUD 영역을 물리적으로 분리.
- SubViewport 높이를 1290 → 1174로 맞춰 실제 표시 영역과 렌더 영역 비율을 정리.
- 기존 필살기 스트립 위치/버튼 배치와 하단 소환 UI 배치는 유지.
- 전투/소환/필살기 동작 로직은 변경하지 않음.

### Demon Ultimate 2 — Line Assault v1
- 마왕 필살기 2번 `일직선 공세` 실제 발동 구현.
- 게이지 100에서 2번 선택 시 필살기 스트립 내부가 동/서/남/북/취소 버튼으로 전환.
- 방향 선택 후 Hero 기준 약 700px 떨어진 해당 면에 편성 몬스터 10마리를 약 720px 직선으로 균등 소환.
- 0.04초 간격, 2마리씩 분산 소환해 순간 프레임 부하 완화.
- 방향 선택 취소 시 게이지 미소모.
- 2번 소환 몬스터는 1번과 동일하게 지휘력/마왕 EXP를 소비·획득하지 않음.
- 3번 사각 포위는 아직 준비중 상태 유지.

### Demon Ultimate Cooldown UI v1
- 마왕 필살기별 독립 쿨타임 추가: 원형 포위 18초 / 일직선 공세 16초 / 사각 포위 예약 20초.
- 기술 사용 후 해당 버튼만 쿨타임 상태로 전환.
- 각 필살기 버튼 하단에 회색 ProgressBar를 추가해 남은 쿨타임 비율을 시각적으로 표시.
- 버튼 문구를 `쿨타임 NN.N초` 형식으로 0.1초 단위 실시간 갱신.
- 공용 게이지가 100이어도 개별 쿨타임이 남아 있는 기술은 사용 불가.
- 다른 기술의 쿨타임과 공용 게이지는 독립적으로 유지.

### Demon Ultimate 3 — Square Siege v1
- 마왕 필살기 3번 `사각 포위` 실제 발동 구현.
- Hero 기준 약 ±700px 외곽의 사각형 둘레에 편성 몬스터 16마리를 균등 소환.
- 현재 편성 몬스터를 슬롯 순서대로 순환하며 지휘력/마왕 EXP는 소비·획득하지 않음.
- 0.04초 간격, 2마리씩 분산 소환해 순간 프레임 부하 완화.
- 3번 개별 쿨타임 20초와 기존 회색 쿨타임 게이지/`NN.N초` 텍스트 표시 연결.
- 1번 원형 포위 / 2번 일직선 공세의 동작과 수치는 변경하지 않음.

### Mobile HUD Readability Scale-Up
- 1080×1920 논리 해상도는 유지하고 HUD 가독성만 확대.
- 상단 시간/Stage/HP/몬스터/EXP 폰트를 약 15~25% 확대.
- 마왕 필살기 제목과 1/2/3 버튼, 방향 선택 버튼 폰트를 약 20~25% 확대.
- 필살기 쿨타임 회색 바 두께를 9px → 12px로 확대.
- 하단 용사 상태/자동 배치/마왕 EXP/지휘력 폰트를 약 20~25% 확대.
- 마왕 EXP/지휘력 게이지 높이를 키우고 라벨 폭을 넓혀 큰 글자에서도 잘리지 않게 조정.
- 소환 카드 텍스트를 23 → 28로 확대.
- 전투 Viewport 크기, 전투 로직, 소환/필살기 로직은 변경하지 않음.

### Stage Director v1
- `src/systems/stage_director.gd` 추가: Stage의 `event_timeline`을 읽어 지정 시점 이벤트를 1회씩 발생.
- Stage 1 시간 이벤트 추가: 90초 정예 거미 / 180초 정예 오크 / 240초 오크 대장 / 300초 침공 대장.
- 6분 Run 기준 최종 보스 프로토타입을 종료 1분 전인 5:00에 출현하도록 설정.
- 현재 전용 보스 리소스가 없어 기존 Spider/Orc를 이벤트별 HP/공격력/속도/EXP/크기 배수로 강화해 사용.
- Stage 이벤트 몬스터는 무료 자동 출현이며 마왕 필살기/지휘력 시스템과 분리.
- 이벤트 발생 시 하단 상태 문구로 엘리트/미니보스/보스 출현 알림 표시.
- 기존 일반 소환과 필살기 소환은 선택 인자 기본값으로 기존 동작 유지.

### Stage Director Battle Render Hotfix
- Stage Director 추가 후 Battle 스크립트 로딩을 막을 수 있던 `_spawn_monster()` 내부 지역변수 중복 선언을 제거.
- `stage_director.gd`의 익명 함수 기반 timeline 정렬을 제거하고 Stage 데이터의 선언 순서를 그대로 사용하도록 단순화.
- 전투 화면이 회색으로만 표시되는 회귀 복구를 위한 최소 수정이며 Stage 이벤트 시간/수치/기능은 변경하지 않음.

### Mutation Choice v1
- Stage 1의 90초/180초 엘리트, 240초 미니보스 이벤트를 자동 소환에서 마왕 직접 선택 방식으로 변경.
- 이벤트 시 전투/타이머를 멈추고 현재 팀 편성 3종을 보여주는 `돌연변이 선택` 모달 표시.
- 선택한 일반 몬스터를 90/180초에는 `돌연변이`, 240초에는 `대돌연변이` 강화 개체로 1마리 소환.
- 기존 Stage Director의 HP/공격력/속도/EXP/시각 크기 배율을 선택한 몬스터에 그대로 적용.
- 돌연변이 스폰 거리를 Hero 기준 약 460px로 조정해 선택 직후 카메라 안에서 확인하기 쉽게 개선.
- 300초 보스 이벤트는 다음 보스 편성 슬롯 단계 전까지 기존 고정 프로토타입 유지.

### Mutation Choice Input Hotfix
- 돌연변이 선택 버튼은 눌리지만 모달이 닫히지 않던 입력/처리 흐름 보완.
- 선택 클릭 시 UI 모달을 먼저 닫고 Battle 선택 상태를 확정하도록 순서를 변경.
- 실제 돌연변이 몬스터 생성은 다음 프레임의 deferred 호출로 분리해 UI 버튼 콜백과 스폰 처리를 분리.
- 후보 검증을 명시적 문자열 비교로 변경해 typed/untyped Array 차이에 따른 비교 실패 가능성 제거.
- MutationPanel과 3개 선택 버튼이 마우스/터치 입력을 명시적으로 받도록 설정.

### Mutation Choice State Sync Fix
- 돌연변이 모달 후보와 Battle 내부 일시 상태가 어긋나 선택이 계속 실패하던 구조 수정.
- 모달이 열릴 때 Stage 이벤트 데이터를 Main UI가 함께 보관하도록 변경.
- 버튼 클릭 시 보관된 이벤트 데이터 + 선택 monster_id를 `resolve_mutation_choice()`에 직접 전달해 선택 확정.
- 모달 표시 중 `external_pause`를 함께 사용해 Run 타이머/전투 정지를 UI 상태와 명시적으로 동기화.
- 선택 성공 후 모달/후보/이벤트 데이터를 정리하고 pause를 해제한 뒤 deferred 스폰.
- 기존 `choose_mutation()`은 호환용 래퍼로 유지.

### Mutation Pause Regression Hotfix
- 돌연변이 상태 동기화 수정 이후 전투 시작부터 시간/지휘력/소환 UI가 멈추던 회귀 수정.
- 돌연변이 모달에서 `external_pause`를 별도로 걸던 이중 pause 구조 제거.
- 돌연변이 선택 중 정지는 Battle의 기존 `mutation_selection_active`만 사용.
- 모달에 이미 표시된 monster_id는 카탈로그 존재 여부만 확인하고 직접 선택 확정하도록 단순화.
- Main 초기화 완료 시 Battle external pause를 false로 명시해 정상 Run 시작 상태 보장.

### Battle Runtime Startup Recovery
- Stage Director/돌연변이 작업 이후 일부 실행에서 전투 시작 직후 시간, 지휘력 회복, 소환이 모두 정지하던 문제 대응.
- Battle에 `ensure_runtime_active()` 추가.
- Main 진입 직후 external pause / 돌연변이 선택 / 마왕 증강 선택 상태를 초기화하고 Battle process 및 Hero/몬스터 physics를 명시적으로 활성화.
- 런타임 상태 확인을 위해 snapshot에 external_pause / demon_augment_selection_active를 추가하고 내부 디버그 문자열 제공.
- 실제 전투 종료 상태에서는 복구 함수가 동작하지 않도록 보호.

### Battle Flow Rollback + Mutation Resolver
- 시간/지휘력/소환이 시작부터 정지하는 회귀를 제거하기 위해 Battle/Main 런타임 흐름을 정상 동작이 확인된 `4ea474b` 기준으로 복구.
- 이후 추가했던 mutation용 external pause / startup force recovery 로직을 제거.
- 돌연변이 모달은 기존 `mutation_selection_active`만으로 전투/타이머를 정지.
- UI가 모달 오픈 시 Stage 이벤트 데이터를 보관하고, 선택 시 `resolve_mutation_from_ui()`로 직접 전달.
- 선택 함수는 내부 후보 상태와 재검증하지 않고 카탈로그 유효 monster_id만 확인해 즉시 선택 확정 후 deferred 스폰.

### Mutation Choice Payload Fix
- 돌연변이 버튼 클릭은 되지만 항상 선택 실패 메시지가 나오던 문제 수정.
- Main UI가 Stage 이벤트 Dictionary를 별도로 보관/전달하던 경로 제거.
- UI는 선택한 `monster_id`만 Battle에 전달하고, Battle은 자신이 이미 보관 중인 `pending_mutation_event`를 직접 사용.
- pending event가 비정상적으로 비어 있어도 1차 돌연변이 기본 배율로 fallback하여 선택 자체가 막히지 않도록 보호.
- 시간/지휘력/일반 소환이 정상 동작하는 현재 Battle 루프는 변경하지 않음.

### Revert Mutation Payload Regression
- `10874409` 돌연변이 payload 수정 이후 전투 시작 직후 시간/지휘력/일반 소환이 다시 멈추는 회귀가 확인되어 런타임 파일을 마지막 정상 확인점 `c120248f` 상태로 복구.
- `src/battle/battle.gd`와 `src/main/main.gd`만 정상 확인 버전으로 되돌림.
- 돌연변이 선택 기능 추가 작업은 기본 전투 안정성 확인 후 별도 단계에서 다시 진행.

### Mutation Choice Callback Isolation
- 기본 전투가 정상 동작하는 `48978c67` 런타임 흐름은 유지.
- 시작 시 실행되는 pause/process/시간/지휘력 코드는 변경하지 않음.
- 돌연변이 버튼 클릭 전용 `force_resolve_mutation(monster_id)` 추가.
- UI는 표시된 monster_id만 전달하고 Battle의 `pending_mutation_event`를 직접 사용.
- pending event가 비어 있어도 1차 돌연변이 기본 배율로 fallback.
- 기존 `resolve_mutation_from_ui()`와 `choose_mutation()`은 그대로 유지해 다른 경로에 영향 없도록 함.

### Mutation Choice Direct Spawn
- 돌연변이 선택 경로를 `버튼 → Battle → 즉시 스폰` 한 단계 구조로 단순화.
- 기존 `force_resolve_mutation()`, `resolve_mutation_from_ui()`, `choose_mutation()`, deferred 완료 함수를 제거.
- Main이 Stage 이벤트 Dictionary를 별도로 보관하는 상태도 제거.
- 버튼 클릭 시 `spawn_selected_mutation(monster_id)`가 Battle의 `pending_mutation_event`를 직접 사용해 즉시 강화 개체를 생성.
- 생성 후 돌연변이 선택 상태를 해제하고 전투 physics를 재개.
- 시작 시 시간/지휘력/일반 소환 처리 코드는 변경하지 않음.

### MutationDirector v1 — 구조 정리 1단계
- `src/systems/mutation_director.gd` 추가.
- 돌연변이 active / pending event / candidate 상태를 Battle에서 MutationDirector로 이관.
- Battle 내부의 돌연변이 상태 변수 3개 제거.
- StageDirector → MutationDirector → Main 선택 UI → Battle 스폰으로 책임 경계를 정리.
- Main은 후보 표시와 monster_id 전달만 유지.
- Battle은 실제 몬스터 생성과 전투 physics 정지/재개만 담당.
- 기존 Stage 1 돌연변이 시간/배율/모달 UI는 변경하지 않음.
- 시간/지휘력/일반 소환 루프는 변경하지 않음.

### MutationCatalog v1 — 구조 정리 2단계
- `src/data/mutation_catalog.gd` 추가.
- 1차 돌연변이 / 2차 돌연변이 / 대돌연변이의 배율, 이름 접두사, 모달 문구, 스폰 거리를 데이터 프로필로 이동.
- Stage 1의 90/180/240초 이벤트는 구체 배율 대신 `mutation_profile_id`만 참조하도록 변경.
- MutationDirector가 이벤트 시작 시 MutationCatalog 프로필을 병합해 완성된 선택 이벤트를 생성.
- Battle의 miniboss 이름 분기 및 고정 460px 설정 제거.
- Main의 elite/miniboss 모달 문구 분기 제거.
- 시간/지휘력/일반 소환 루프는 변경하지 않음.

### Special Monster Spawn v1 — 구조 정리 3단계
- Battle의 `_spawn_stage_event_monster()`를 제거하고 범용 `spawn_special_monster(monster_id, special_data)` API로 교체.
- 90/180/240초 돌연변이와 300초 Stage 고정 보스가 동일한 특수 스폰 경로를 사용하도록 통합.
- 특수 스폰 API는 배율/스폰 거리/이벤트 메타 설정과 실제 생성만 담당.
- Stage 이벤트 상태 문구/시그널은 `_emit_stage_event_announcement()`로 분리.
- 향후 `일반 3 + 보스 1` 편성 보스도 같은 특수 스폰 API를 재사용할 수 있는 기반 마련.
- 시간/지휘력/일반 소환 루프 및 `_spawn_monster()` 구현은 변경하지 않음.

### Mutation Spawn Resume Hotfix
- 돌연변이 선택 후 모달은 닫히지만 특수 소환 실패 시 전투 physics가 그대로 멈추던 문제 수정.
- 선택 확정 직후 combat physics를 먼저 재개하도록 순서 변경.
- 실제 특수 몬스터 생성은 `call_deferred()`로 다음 프레임에 실행해 UI 버튼 콜백과 월드 노드 생성을 분리.
- 특수 스폰 실패 시 warning을 남기되 전투 진행은 계속 유지.
- MutationDirector / MutationCatalog / 공통 `spawn_special_monster()` 구조는 유지.

### Mutation Process Decoupling Hotfix
- 돌연변이 선택 상태가 Battle의 전체 `_process()`를 막아 특수 스폰 문제 시 시간/지휘력까지 함께 멈추던 결합 제거.
- `mutation_director.is_active()`를 Battle 전체 process return 조건에서 제거.
- 돌연변이 모달은 기존처럼 Hero/몬스터 physics만 정지하고 Battle 핵심 시간/지휘력 루프와 분리.
- 선택 클릭 시 성공/실패와 무관하게 MutationDirector를 명시적으로 reset하고 combat physics를 재개한 뒤 특수 스폰을 deferred 실행.
- 특수 스폰 문제가 남더라도 기본 Run 루프가 같이 정지하지 않도록 격리.

### Mutation Spawn Queue + Physics Recovery
- 돌연변이 선택 후 Hero physics가 멈춘 채 남는 문제를 UI 선택 처리와 특수 스폰 경로로 분리.
- Main은 모달을 닫은 직후 `resume_after_mutation_choice()`를 먼저 호출해 Hero/몬스터 physics를 복구.
- 실제 돌연변이 생성은 `call_deferred()` 대신 Battle의 `special_spawn_queue`에 요청을 넣고 다음 `_process()`에서 처리.
- 특수 스폰 성공/실패를 `mutation_spawn_result` 시그널로 Main에 전달해 상태창에 실제 결과를 표시.
- 스폰 실패가 발생해도 선택 UI/physics 복구와 분리되어 전투 진행이 유지되도록 구조 격리.

### Mutation Event Reset Ordering Fix
- 돌연변이 모달 선택 후 엘리트가 소환되지 않던 직접 원인 수정.
- `resume_after_mutation_choice()`가 physics 복구 전에 MutationDirector를 reset하여 pending event를 지우던 로직 제거.
- 이제 Main이 먼저 physics를 복구해도 MutationDirector의 선택 이벤트는 유지되고, 이어지는 `spawn_selected_mutation()`의 `commit_selection()`에서 정상적으로 이벤트를 소비/초기화한다.
- 특수 스폰 큐 및 기본 전투 루프는 변경하지 않음.

### Mutation Choice Lifecycle Simplification
- 돌연변이 선택 경로를 마왕 증강과 같은 단일 생명주기로 단순화.
- `resume_after_mutation_choice()`와 `special_spawn_queue` 제거.
- 선택 시 MutationDirector의 `commit_selection()`으로 이벤트를 확정/해제한 뒤 같은 함수에서 즉시 `spawn_special_monster()` 실행.
- 스폰 성공/실패와 무관하게 마지막에 combat physics를 재개.
- 성공 시 Stage 이벤트 알림/돌연변이 선택 결과 시그널을 emit.
- 시간/지휘력/일반 소환 루프는 변경하지 않음.

### Special Spawn Post-Ready Fix
- 특수 몬스터가 선택 후 생성되지 않고 Hero physics까지 멈추는 문제 대응.
- 돌연변이 선택 시 combat physics를 특수 스폰 호출보다 먼저 재개.
- `spawn_special_monster()`가 더 이상 생성 전 `spawn_modifiers`를 넣지 않고, 검증된 일반 `_spawn_monster()` 경로로 몬스터를 먼저 생성.
- `_spawn_monster()`가 생성된 몬스터 인스턴스를 반환하도록 확장.
- 생성 완료 후 `_apply_special_monster_modifiers()`에서 HP/공격/속도/EXP/크기/Stage 이벤트 메타를 후처리.
- Bomb Rat 특수 개체는 폭발 피해에도 damage multiplier 적용.
- 특수 HP 배율 적용 후 current_hp를 새 max_hp로 맞춰 실제 강화 체력으로 시작.

### Mutation Direct Event Read Hotfix
- 돌연변이 선택 시 `commit_selection()` 상태 소비 단계에 의존하지 않고 MutationDirector의 현재 이벤트를 직접 복사한 뒤 reset하도록 단순화.
- 선택 함수 진입 즉시 combat physics를 먼저 복구해 이후 로직과 Hero 재개를 완전히 분리.
- 이벤트 데이터가 비어 있어도 1차 돌연변이 기본 프로필로 fallback하여 선택한 몬스터 소환을 계속 시도.
- 테스트 가시성을 위해 돌연변이 스폰 거리를 Hero 기준 최대 260px로 제한.
- 성공 상태 문구에 실제 monster_id를 포함해 생성 경로 확인 가능.

### Mutation Spawn-First Isolation
- 돌연변이 선택 시 엘리트가 보이지 않는 문제를 추적하기 위해 생성과 강화 단계를 완전히 분리.
- `spawn_special_monster()`는 이제 일반 `_spawn_monster()`와 동일하게 기본 몬스터 생성만 수행하고 생성 인스턴스를 반환.
- 선택 직후 기본 몬스터를 먼저 씬 트리에 생성하고, 다음 프레임 `_finish_special_monster_setup()`에서 엘리트 배율/메타를 적용.
- 기본 생성 직후 상태창에 monster_id / instance_id / spawn position / monsters_alive를 표시해 실제 생성 여부 확인 가능.
- 돌연변이 스폰 거리를 Hero 기준 최대 220px로 제한해 화면 내 확인성을 높임.
- Stage 고정 보스도 공통 특수 스폰 반환 인스턴스에 후처리 배율을 적용하도록 맞춤.

### Revert Spawn-First Regression
- `75fff29d`의 특수 스폰 생성/강화 분리 변경 이후 Battle 초기화가 깨져 전투 화면이 회색으로 남고 Run 시간/지휘력이 시작되지 않는 회귀가 발생.
- `src/battle/battle.gd`, `src/main/main.gd`를 기본 전투가 정상 동작하고 엘리트 소환 문제만 남아 있던 `10c9ba70` 상태로 복구.
- 이후 엘리트 수정에서는 공용 `_spawn_monster()` 시그니처/초기화 경로를 변경하지 않는 원칙 추가.

### Mutation Spawn Diagnostic Checkpoints
- 엘리트 선택 시 몬스터가 생성되지 않는 실제 실패 지점을 찾기 위한 진단만 추가.
- 공용 `_spawn_monster()`, Battle 시간/지휘력, physics, MutationDirector 동작은 변경하지 않음.
- 상태창/콘솔에 `[MUT-DIAG D1~D8]` 체크포인트 표시:
  - D1 선택 monster_id / Catalog / Hero 유효성
  - D2 이벤트 데이터 준비
  - D3 특수 스폰 함수 진입
  - D4 PackedScene 조회 결과
  - D5 공용 _spawn_monster 호출 직전 위치/alive 수
  - D6 공용 _spawn_monster 반환 및 alive 증가 여부
  - D7 특수 배율 적용 직전 인스턴스/SceneTree 여부
  - D8 특수 배율 적용 완료
- 실행이 중간에서 끊기면 화면에 마지막으로 남은 MUT-DIAG 번호를 기준으로 실패 지점을 특정한다.

### Mutation Spawn Diagnostic Narrowing
- 이전 진단에서 D1까지만 표시되고 D2에 도달하지 않는 것이 확인됨.
- D1~D2 사이를 D1.1~D1.4로 세분화:
  - D1.1 combat physics 재개 직후
  - D1.2 MutationDirector.get_event() 직후
  - D1.3 MutationDirector.reset() 직후
  - D1.4 이벤트 fallback/거리 정규화 직후
- 동작 로직은 변경하지 않고 진단 체크포인트만 추가.

### Mutation Spawn Diagnostic Narrowing 2
- 이전 진단에서 D1.4까지 도달하고 D2 전에 중단되는 것이 확인됨.
- D1.4~D2 구간을 세분화:
  - D1.5 event_type 읽기 완료
  - D1.6 name_prefix 읽기 완료
  - D1.7 MonsterCatalog 표시명 조회 완료
  - D1.8 mutation_name 문자열 조합 완료
- 동작 로직은 변경하지 않고 진단 체크포인트만 추가.

### Monster Catalog Name Collision Fix
- MUT-DIAG에서 D1.6까지만 도달하고 D1.7의 `MONSTER_CATALOG.get_name(monster_id)` 호출 구간에서 중단되는 것이 확인됨.
- Battle 내부에서 `MONSTER_CATALOG.get_name()` 호출을 제거.
- `_get_catalog_monster_display_name()` 헬퍼가 `MONSTER_CATALOG.MONSTERS[monster_id]["name"]`을 직접 읽도록 변경.
- 돌연변이 이름 생성, 특수 이벤트 메타 이름, Stage 이벤트 알림, 디버그 요약도 같은 안전 헬퍼 사용.
- 엘리트 스폰/physics/일반 소환 로직 자체는 변경하지 않음.

### Elite Monster Visuals + Bomb Rat Explosion Frames
- Slime / Spider / Orc / Bomb Rat에 MonsterCatalog 기반 elite_visual 프로필 추가.
- 돌연변이 소환 시 동일 monster_id를 유지하면서 비주얼만 엘리트 프로필로 교체.
- monster_visual.gd에 frames / numbered sequence / spritesheet 기반 런타임 비주얼 프로필 로더 추가.
- 엘리트 Slime은 elitemonster/slime/frames의 idle/walk/atk/hit/death 프레임 연결.
- 엘리트 Spider는 elitemonster/spider/frames/frame_01~22 시퀀스를 idle/move/attack/death로 연결.
- 엘리트 Orc는 eliteorc_spritesheet.png 6×5 동적 셀 분할 연결.
- 엘리트 Bomb Rat은 elitebombrat_spritesheet.png 6×5 동적 셀 분할 연결.
- Bomb Rat 폭발 효과를 기존 통시트 3프레임 방식에서 frames/frame_01~08.png 개별 PNG 8프레임 방식으로 교체.
- 기존 MUT-DIAG 진단 출력을 제거하고 정상 돌연변이 결과 메시지만 유지.
- 거미 원거리 투사체 로직과 UI 파츠 적용은 다음 단계로 분리.

### Bomb Rat Spawn Visual Regression Fix + Elite Scale
- Bomb Rat 몸체 스프라이트 분할을 기존 검증된 229×229 고정 셀 방식으로 복구.
- 일반 Bomb Rat은 기존 bombrat_spritesheet.png, 엘리트 Bomb Rat은 elitebombrat_spritesheet.png를 같은 셀 규칙으로 사용.
- 폭발 이펙트는 개별 PNG frame_01~08 방식 유지.
- 폭발 프레임 로더가 첫 프레임만 추가하던 문제를 수정해 8프레임 전체를 SpriteFrames에 추가.
- mutation_1 / mutation_2 / greater_mutation의 visual_scale을 모두 1.5로 통일해 엘리트/돌연변이 몬스터를 일반 대비 약 1.5배 크기로 표시.

### Elite Orc/Bomb Rat Frame Sequences + Mutation Modal Summon Lock
- 엘리트 Orc 비주얼을 spritesheet 분할 방식에서 elitemonster/orc/frames/frame_01~23 개별 PNG 시퀀스로 교체.
  - idle 01~04 / move 05~10 / attack 11~16 / hit 17~20 / death 21~23.
- 엘리트 Bomb Rat 비주얼을 elitemonster/bombrat/frames/frame_01~20 개별 PNG 시퀀스로 교체.
  - idle 01~04 / move 05~10 / attack 11~16 / death 17~20.
- Bomb Rat 런타임 비주얼 로더에 numbered sequence 프로필 지원 추가.
- 돌연변이 선택창이 열린 동안 일반 몬스터 소환 버튼을 비활성화하고, 소환 입력 함수에서도 추가 차단.
- 돌연변이 선택 완료 후 현재 지휘력 기준으로 소환 버튼 활성 상태를 다시 계산.
- 기존 combat physics 정지/재개 로직은 변경하지 않음.

### Mutation Command UI Resume Fix
- 돌연변이 선택 완료 후 소환 버튼 복구 시 Battle snapshot의 잘못된 `command` 키를 읽던 문제 수정.
- 실제 snapshot 키인 `command_power`를 사용해 현재 지휘력 UI와 버튼 상태를 정확히 복구.
- `_on_command_changed()`에서도 mutation_panel이 열려 있으면 소환 버튼을 계속 비활성화하도록 보강.
- 선택 완료 후에는 현재 실제 지휘력 기준으로 버튼이 즉시 정상 복구됨.
- Battle의 지휘력 회복/전투 physics 로직 자체는 변경하지 않음.

### Spider Ranged Controller v1
- Spider 공격 방식을 근접 즉시타격에서 짧은 사거리 원거리 투사체 방식으로 변경.
- Spider 기본 공격 사거리 70→300, 공격 주기 1.15→1.35초.
- Spider 투사체 속도 320 / 최대 이동거리 360 추가.
- src/monsters/SpiderProjectile.tscn 및 spider_projectile.gd 추가.
- 투사체가 실제로 이동한 뒤 Hero에 충돌해야 피해가 적용되며, 빗나가거나 최대 사거리를 넘으면 소멸.
- 기존 피해 5와 둔화 72% / 1.5초 효과는 투사체 적중 시 유지.
- 일반 Spider 투사체에 monsters/spider/frames/effect/frame_01~08.png 연결.
- 엘리트 Spider 투사체에 elitemonster/spider/frames/effect/frame_01~08.png 연결.
- monster_projectiles 그룹을 전투 pause 대상에 포함해 돌연변이 선택/일시정지 중 투사체도 함께 정지.
- Spider 이동 AI는 접근 → 사거리 진입 → 정지 → 발사 구조로 단순 유지.

### Spider Projectile One-Take Animation
- Spider 거미줄 투사체의 fly 애니메이션 loop를 제거.
- 일반/엘리트 모두 frame_01~08을 1회만 재생.
- 투사체의 최대 이동시간(max_range / speed)에 맞춰 8프레임 재생속도를 계산해, 비행 중 애니메이션이 반복되지 않도록 조정.
- 투사체가 더 빨리 Hero에 적중하면 기존처럼 즉시 소멸하며, 빗나가 최대 사거리까지 가는 경우 1→8 프레임을 한 번만 재생.

### Lobby Stage Card Information Split
- 메인 로비 침입자 카드의 상/하 정보 영역을 시안 기준으로 재배치.
- 상단 영역을 Stage 번호/침입 순서/용사 초상화/용사 이름 중심으로 확장하고 초상화 표시 높이를 확대.
- 하단 영역으로 침입자 설명/입장 상태/최초 클리어 보상/던전 입장 버튼을 모아 ui10 하단 프레임을 실제 정보 영역으로 사용.
- Stage 1/2 로비 설명 문구를 모바일 카드에 맞게 짧게 정리하고 설명/상태/보상 폰트 크기를 축소.
- 던전 입장 버튼을 하단 프레임 안에서 더 안정적으로 보이도록 높이 76, 폭 420 기준으로 조정.

### Lobby Stage Card Visual Section Alignment Fix
- ui10 카드의 상/하 프레임은 유지하면서 실제 콘텐츠 배치를 두 영역에 맞게 다시 분리.
- 상단 영역은 Stage 번호/침입자 제목/초상화/용사 이름만 유지하고 초상화 프레임 높이를 240으로 조정.
- CardVBox에 SectionGap을 추가해 설명/상태/보상/입장 버튼이 ui10의 두 번째 하단 박스로 내려가도록 정렬.
- 하단 정보는 모바일 카드 폭에 맞춰 폰트/행 높이/버튼 높이를 압축.

### Lobby Stage Card Final Positioning
- Stage 카드 내부 레이아웃을 VBox 흐름 배치에서 고정 상/하 영역 배치로 전환.
- TopPanel은 카드 상단에 고정해 Stage 번호/침입자 제목/초상화/용사 이름이 상단 프레임 안에서 유지되도록 조정.
- BottomPanel은 카드 하단에 직접 앵커링해 설명/입장 상태/최초 보상/던전 입장 버튼이 하단 빈 프레임 안으로 이동하도록 수정.
- 기존 SectionGap 임시 스페이서를 제거해 해상도/남는 공간에 따라 정보 영역이 다시 위로 끌려오는 문제를 방지.

### Lobby Lower Info Panel Vertical Reposition
- 이전 고정 앵커 조정으로 하단 정보 블록이 ui10 하단 프레임보다 아래로 내려간 문제 수정.
- BottomPanel의 높이와 내부 구성은 유지하고, 세로 위치만 약 214px 위로 이동해 설명/상태/보상/던전 입장 버튼이 하단 프레임 안에 들어오도록 조정.
- 상단 Stage/초상화/용사 이름 영역은 변경하지 않음.

### Lobby Lower Info Panel Final Nudge
- 실기기 스크린샷 기준 하단 정보 블록이 하단 프레임 아래쪽 테두리와 겹치던 위치를 보정.
- BottomPanel 전체를 추가로 70px 위로 이동해 설명/상태/보상/던전 입장 버튼이 하단 프레임 중앙 쪽에 안정적으로 들어오도록 조정.
- 상단 Stage/초상화 영역과 하단 정보 블록의 크기/폰트는 유지.

### Lobby Lower Info Panel Micro Alignment
- 실기기 스크린샷 기준 하단 정보 블록이 프레임 하단 테두리에 아직 걸치던 위치를 미세 보정.
- BottomPanel 전체를 추가로 40px 위로 이동해 설명/상태/보상/던전 입장 버튼이 하단 프레임 내부 중앙에 더 가깝게 들어오도록 조정.
- 상단 카드 영역과 정보 블록 크기/폰트/간격은 유지.

### Lobby Lower Info Panel Centering Nudge
- 실기기 스크린샷 기준 하단 정보 블록을 20px 추가 상향해 하단 프레임 내부 중앙 정렬에 가깝게 맞춤.
- 현재 로비 카드의 세로 위치 값은 1080×1920 기준 ui10 프레임 비율에 맞춘 픽셀 오프셋이며, 기능 데이터 하드코딩과는 분리된 UI 레이아웃 상수다.

### Lobby Upper Stage Panel Alignment Pass
- 하단 정보 프레임 정렬 완료 후 상단 영역 배치를 실기기 스크린샷 기준으로 조정.
- STAGE 번호/침입자 제목은 현재 위치를 유지하고, 그 아래에 UpperFrameGap을 추가해 초상화/용사 이름 블록을 ui10의 큰 상단 프레임 안쪽으로 내림.
- 초상화 프레임 높이를 240→360으로 확대해 큰 상단 프레임의 빈 공간을 줄이고 시안의 용사 비중에 가깝게 조정.
- TopPanel 높이를 늘려 새 배치가 하단 정보 영역과 독립적으로 동작하도록 유지.

### Lobby Upper Portrait Block Centering
- 실기기 스크린샷 기준 상단 큰 프레임에서 초상화/용사 이름 블록이 위쪽에 붙고 하단 여백이 크게 남던 위치를 보정.
- STAGE 번호와 침입자 제목 위치는 유지하고 UpperFrameGap을 190→290으로 조정해 초상화/이름 블록만 아래로 이동.
- TopPanel 높이를 700→800으로 늘려 하단 정보 영역과 겹치지 않게 유지.

### Lobby Upper Portrait Grid Fit
- 상단 용사 초상화 프레임이 ui10 내부 네모 영역보다 좌우로 넓게 퍼지던 배치를 조정.
- PortraitFrame을 가로 650 기준 + 중앙 수축 정렬로 변경해 장식 프레임의 내부 직사각형 안에 맞도록 정리.
- 세로 높이 360, STAGE/침입자 제목 위치, 하단 정보 영역은 유지.

### Lobby Portrait Frame Cleanup + Final Lower Centering
- ui10 상단 장식 프레임을 메인 테두리로 사용하도록 초상화용 PortraitFrame/PortraitInner의 추가 테두리를 제거.
- 초상화 영역 여백을 줄이고 670×530으로 확장해 바깥 UI 사각형 내부를 더 자연스럽게 채우도록 조정.
- UpperFrameGap을 290→210으로 줄여 확장된 초상화가 상단 프레임 안에서 위아래 균형을 맞추도록 수정.
- 하단 설명/상태/보상/던전 입장 블록은 18px 추가 상향해 하단 프레임 중앙에 더 가깝게 정렬.

### Lobby Outer Chrome Polish Pass
- 완성된 중앙 StageCard(ui10) 내부는 건드리지 않고 로비 외곽 UI만 정리.
- 헤더를 좌/우 2줄 정보형(골드 / 최고 해금)으로 재배치하고 로고를 수직 중앙에 가깝게 조정.
- 헤더/하단 네비 장식 프레임의 코너와 선 두께를 키워 중앙 카드의 금색/보라 프레임과 시각적 무게를 맞춤.
- 중앙 ContentFrame 외곽 장식도 약간 두껍게 조정해 화면 전체를 하나의 패널처럼 묶도록 개선.
- 하단 5탭의 간격을 10→2로 줄이고 비선택 탭은 얇은 경계, 선택 탭은 보라 배경+금색 강조로 통일.
- Stage 좌우 화살표 버튼 영역을 확대하고 ui8 텍스처의 투명 여백을 잘라 실제 화살표가 더 또렷하게 보이도록 변경.

### Lobby Header Repair Pass
- 중앙 StageCard 내부는 유지하고 헤더만 단독으로 재조정.
- 골드/최고 해금 텍스트가 모서리 장식에 가려지지 않도록 헤더 좌우 안전 여백을 확대.
- 좌우 정보 폰트 크기를 23으로 통일하고 로고와 같은 수직 중심선에 맞춤.
- 헤더 프레임 장식을 하단 네비게이션과 분리하고 코너/선 두께를 한 단계 가볍게 되돌려 과도한 액자 느낌을 완화.
- 로고 위치를 헤더 중앙 쪽으로 소폭 내리고 가로 안전 여백을 늘려 좌우 정보와 겹침을 줄임.

### Main Lobby UICard Frame Unification
- 메인 로비 외곽 장식을 legacy 조립식 part_01~09 프레임에서 assets/art/UI/uicardframes 세트로 전환.
- 헤더는 ui1, 중앙 전체 외곽은 ui9, 하단 네비게이션 외곽은 ui3을 사용하도록 역할을 명시.
- 선택된 하단 탭은 ui5를 버튼 뒤에 오버레이하는 방식으로 연결.
- Stage 좌우 화살표 ui8, 중앙 StageCard ui10은 기존 연결을 유지.
- uicard 완성형 프레임을 NinePatchRect로 적용해 모서리 장식을 보존하면서 화면 크기에 맞춰 늘어나도록 구성.
- 중앙 StageCard 내부의 초상화/설명/보상/던전 입장 배치는 변경하지 않음.
- legacy 프레임 조립 함수는 몬스터 상세 팝업에만 남김.

### Lobby Outer UI Rollback to Verified StageCard Baseline
- uicard 외곽 프레임 실험 과정에서 헤더/하단 높이와 Content 영역이 변하면서 완성된 StageCard 내부 정렬까지 간접적으로 깨진 문제 확인.
- src/lobby/Lobby.tscn을 StageCard가 실기기에서 정상 확인된 116dbb5 시점으로 복구.
- src/lobby/lobby.gd를 초상화 내부 중첩 테두리 제거가 완료된 c8882cf 시점으로 복구.
- 중앙 카드의 검증된 초상화/이름/설명/보상/입장 버튼 배치를 우선 보존하고, 외곽 UI는 이후 Header / Content outer / BottomNav 순으로 한 영역씩 별도 수정하기로 함.

### Lobby Header UICard-Only Frame Pass
- 검증된 중앙 StageCard 레이아웃을 유지하기 위해 Lobby.tscn 및 Content/BottomNav 크기는 변경하지 않음.
- 메인 로비 헤더의 legacy 03_middle_right_panel 조립 프레임만 제거하고 uicardframes/ui1.png로 교체.
- ui1은 NinePatchRect로 적용해 모서리 장식을 보존하면서 기존 Header 크기에 맞게 늘어나도록 처리.
- HeaderMargin, 로고 위치, 골드/최고 해금 텍스트 위치는 이번 패스에서 변경하지 않음.
- 중앙 외곽 프레임과 하단 네비게이션은 기존 검증 상태를 그대로 유지하고 다음 패스에서 각각 별도로 수정.

### Header Frame Layout Isolation Fix
- ui1 헤더 프레임을 NinePatchRect child로 추가하던 방식이 PanelContainer 최소 크기 계산에 참여해 중앙 Content를 아래로 미는 문제 수정.
- 헤더 프레임을 child Control이 아닌 StyleBoxTexture panel override로 변경해 시각 프레임과 레이아웃 크기를 분리.
- Header의 기존 높이/내부 Margin/중앙 StageCard 및 Content 배치는 변경하지 않음.

### Lobby Central Outer Frame UICard Pass
- 헤더/중앙 StageCard가 정상인 기준 상태를 유지한 채 중앙 바깥 ContentFrame만 uicardframes/ui9.png로 교체.
- 기존 01_large_left_panel part 조립식 외곽 프레임은 ContentFrame에서만 제거.
- ui9는 child Control이 아닌 StyleBoxTexture로 적용해 Content 높이/StageCard 위치/하단 네비 위치 계산에 참여하지 않도록 분리.
- StageCard(ui10), 초상화, 설명/보상/입장 버튼, 헤더, 하단 네비게이션의 크기와 위치는 변경하지 않음.

### Header ui1 9-Slice Margin Fix
- 실기기에서 ui1 헤더가 완전한 사각 프레임 대신 중앙 금색 띠처럼 찌그러지는 문제 수정.
- 원인: 2172x724 원본에 10%/22% 9-slice 고정 마진을 사용해 158px Header 높이보다 상하 고정 영역 합이 커졌음.
- 헤더 slice margin을 X 4.5% / Y 7.5%로 축소해 실제 Header 높이 안에서 모서리/상하선이 정상적으로 보이도록 조정.
- 중앙 ContentFrame(ui9), StageCard(ui10), 하단 네비 및 모든 레이아웃 크기는 변경하지 않음.

### Lobby Vertical Space Rebalance
- 중앙 StageCard 내부 배치는 유지하고 화면 세로 공간 배분만 재조정.
- Header 최소 높이를 158→192로 확대해 ui1 헤더 프레임이 세로로 눌리지 않고 로고/좌우 정보가 숨 쉴 공간을 확보하도록 변경.
- BottomNav 높이를 150→180으로 확대해 향후 uicard 하단 프레임/선택 탭 장식을 넣을 공간을 확보.
- SafeArea 하단 여백을 -166→-196으로 맞춰 늘어난 BottomNav와 겹치지 않도록 조정.
- 결과적으로 중앙 Content 영역에서 약 64px를 헤더/하단에 재배분하며, StageCard 자체 크기와 내부 위치 값은 변경하지 않음.

### Lobby Header Height + Bottom Border Join Pass
- 중앙 StageCard/Content 내부 배치는 유지하고 Header와 BottomNav 외곽만 조정.
- Header 높이를 192→216으로 늘려 ui1 프레임의 세로 공간을 확보하고 골드/최고 해금 텍스트가 프레임 안쪽에 들어올 여유를 추가.
- Header 좌우 내부 여백을 24→42로 늘려 상태 텍스트가 모서리 장식과 겹치지 않도록 조정.
- BottomNav의 분할된 legacy part 조립 프레임을 제거하고 uicardframes/ui3.png 단일 프레임으로 교체.
- BottomNav ui3도 StyleBoxTexture로 적용해 높이/버튼/중앙 Content 레이아웃 계산에는 영향을 주지 않도록 유지.

### Revert Header/BottomNav Regression
- Header 216px 확대가 중앙 Content를 아래로 밀어 StageCard 내부 텍스트 정렬이 깨지는 문제를 확인하고 Header를 검증된 192px로 복구.
- HeaderMargin도 마지막 정상 상태(24/86/24/10)로 복구.
- BottomNav ui3 StyleBox 실험에서 외곽 테두리가 사라지는 문제가 있어 해당 적용을 제거.
- BottomNav는 마지막 정상 상태의 legacy 조립 프레임으로 복구.
- ContentFrame ui9, Header ui1, StageCard ui10은 유지.

### Lobby Header Interior Safe Pass
- PC 작업 기준점에서 중앙 StageCard/Content/BottomNav 레이아웃을 잠그고 헤더 내부 요소만 조정.
- Header 높이, SafeArea, Content 높이는 변경하지 않음.
- 골드/최고 해금 정보가 ui1 모서리 장식 바깥으로 튀어나오지 않도록 HeaderMargin 좌우를 24→54로 확대.
- 좌우 상태 텍스트 폰트를 26→24로 소폭 축소.
- 로고 가로 점유 폭을 줄여 좌우 상태 정보와 겹침을 완화.

### Responsive StageCard Layout v1
- 모바일 긴 화면에서 맞춘 StageCard 내부가 9:16 PC 창에서 겹치던 원인을 수정.
- ui10 원본 비율(1049×1499)을 기준으로 StageCard 높이를 현재 카드 폭에서 계산해 aspect ratio를 고정.
- StageCard를 StagePicker 내부 세로 중앙 정렬로 전환해 긴 모바일 화면의 추가 세로 공간이 카드 내부 좌표계에 영향을 주지 않도록 변경.
- TopPanel의 고정 800px 높이와 UpperFrameGap 210px 하드코딩을 제거하고, 상단 79% 영역 + 가변 Spacer로 변경.
- BottomPanel의 -530/-370 픽셀 오프셋을 제거하고 카드 내부 80%~98% 비율 영역에 고정.
- PortraitFrame 가로 670px 고정을 제거하고 카드 내부 폭에 맞춰 확장하도록 변경.
- PC 창 크기/viewport 크기 변경 시 StageCard aspect를 다시 계산하도록 resized/viewport size_changed 동기화 추가.
- 목표: 9:16 PC와 19.5:9~20:9 모바일에서 ui10 내부의 이름/초상화/설명/보상/입장 버튼이 동일한 프레임 구획을 유지.

### Revert Broken Responsive StageCard v1
- Responsive StageCard v1 적용 후 lobby.gd가 정상 실행되지 않아 헤더 로고/프레임, ui10 카드 스킨, 초상화 로딩 등 런타임 UI 초기화가 전부 빠지는 회귀 발생.
- Lobby.tscn / lobby.gd를 PC 실행 직전 마지막 정상 기준점(719b01e / 99bcaf6)으로 즉시 복구.
- 다음 반응형 작업은 런타임 스크립트에 resize signal/동적 minimum size를 한 번에 추가하지 않고, 검증 가능한 단계별 구조 변경으로 진행.

### StageCard Aspect Lock - Declarative Step 1
- 이전 런타임 반응형 패치 회귀를 피하기 위해 스크립트 변경 없이 TSCN 레이아웃만 단계적으로 수정.
- StageCard를 ui10 원본 비율(1049×1499)에 가까운 780×1115 논리 크기로 고정.
- StagePicker 안에서는 가로/세로 모두 SHRINK_CENTER로 두어 9:16 PC와 세로가 긴 모바일에서 남는 공간만 달라지고 StageCard 자체 좌표계는 동일하게 유지.
- 이번 단계에서는 TopPanel/BottomPanel/초상화/설명/버튼 내부 배치 값은 변경하지 않음.

### StageCard Responsive Anchors - Declarative Step 2
- StageCard 780×1115 고정 비율은 유지하고 내부 배치만 TSCN anchor 비율 기반으로 전환.
- TopPanel을 VBoxContainer에서 Control로 변경해 Stage 번호/침입자 제목/초상화/용사 이름이 카드 높이에 종속되지 않도록 고정 비율 배치.
- 기존 UpperFrameGap 210px 하드코딩 제거(노드는 호환을 위해 숨김 유지).
- PortraitFrame은 카드 내부 4%~96% 가로, 24.5%~61.5% 세로 영역에 배치.
- HeroName은 61.5%~66.5% 영역에 고정.
- BottomPanel을 VBoxContainer에서 Control로 변경하고 카드 내부 78.5%~96.5% 하단 영역에 고정.
- 설명/상태/보상/입장 버튼도 BottomPanel 내부 anchor 비율로 배치해 -530/-370 오프셋과 컨테이너 흐름 의존성 제거.
- lobby.gd 경로와 노드 이름은 유지해 런타임 데이터/초상화 로딩 코드는 변경하지 않음.

### StageCard Responsive Anchor Micro-Alignment
- PC 9:16 실기기 화면 기준으로 반응형 StageCard 비율 앵커를 미세 조정.
- STAGE 번호 영역을 카드 상단 0.5%~3.5%로 올리고 침입자 제목을 3.5%~8.5%로 이동해 ui10 상단 프레임 장식과 겹치지 않도록 정리.
- 용사 이름 영역을 58.5%~62.5%로 올려 상/하 섹션 경계선과 겹치지 않도록 보정.
- 초상화 영역 및 하단 설명/상태/보상/던전 입장 영역은 변경하지 않음.

### StageCard Group Upward Nudge
- PC 9:16 화면 기준 반응형 StageCard 구조는 유지하고 StagePicker 전체 묶음만 위로 소폭 이동.
- StageLayout의 StageTopSpacer를 42→10으로 줄여 STAGE 제목/초상화/용사 이름/하단 설명·버튼이 함께 위로 이동하도록 조정.
- StageCard 내부 anchor 비율, ui10 크기, 하단 정보 상대 위치는 변경하지 않음.

### StageCard Responsive Visual Alignment Pass 2
- PC 9:16 스크린샷 기준으로 ui10 실제 금색 프레임 선과 텍스트/콘텐츠 앵커를 다시 맞춤.
- STAGE 번호/침입자 제목을 소폭 위로 이동해 상단 장식선과 겹침을 완화.
- 초상화 영역을 카드 높이 기준 2% 위로 이동.
- 용사 이름을 54.5%~58.5% 구간으로 올려 중앙 구분선 위쪽에 안정적으로 배치.
- 하단 정보 영역을 78.5%~96.5%에서 74.5%~92.5%로 이동해 설명/보상/버튼이 하단 프레임 안쪽 중앙에 오도록 조정.
- 던전 입장 버튼도 BottomPanel 내부 60%~92%로 올려 하단 테두리와 겹치지 않도록 수정.
- 구조/노드 경로/lobby.gd는 변경하지 않음.

### StageCard Content Group Upward Shift
- PC 9:16 스크린샷 기준 ui10 카드 프레임 자체는 고정하고 내부 콘텐츠 전체만 위로 이동.
- CardMargin의 상단/하단 여백을 28/32에서 0/60으로 재배분해 내부 가용 높이는 유지하면서 콘텐츠 좌표계만 약 28px 위로 이동.
- STAGE 번호, 침입자 제목, 초상화, 용사 이름, 설명/상태/보상/던전 입장 버튼이 모두 동일한 양만큼 위로 이동.
- ui10 스킨 크기/위치와 StageCard 자체 크기, 각 요소의 상대 anchor 비율은 변경하지 않음.

### StageCard Overlap Spacing Pass
- PC 9:16 기준으로 카드 내부 요소의 겹침만 해소하고 전체 카드/프레임 위치는 유지.
- STAGE 번호와 침입자 제목 사이 간격을 늘려 상단 텍스트 중첩 제거.
- 초상화 영역 하단을 소폭 줄이고 용사 이름을 바로 아래 별도 영역으로 이동해 초상화와 이름 겹침 제거.
- BottomPanel 상단을 74.5%→71.5%로 확장해 하단 정보 영역의 세로 공간을 확보.
- 설명/상태/보상 행의 높이를 재분배하고 던전 입장 버튼을 더 아래에 배치해 보상 문구와 버튼 겹침 제거.
- ui10 프레임, StageCard 크기, 외곽 헤더/하단 네비 및 lobby.gd는 변경하지 않음.

### Stage Metadata Moved Outside Card
- PC 9:16 기준으로 카드 상단 테두리와 겹치던 STAGE 번호/침입자 제목을 StageCard 내부에서 분리.
- StageLayout에 StageMetaBox를 추가해 침입자 기록/설명과 StageCard 사이의 외부 여백에 STAGE 번호와 침입자 제목을 배치.
- 기존 TopPanel 내부 StageNumber/StageName 노드는 제거하고, lobby.gd의 onready 경로만 새 StageMetaBox 경로로 갱신.
- _refresh_stage_card() 데이터 갱신 로직은 그대로 유지.
- ui10 카드/초상화/용사 이름/하단 설명·상태·보상·던전 입장 버튼의 내부 배치는 변경하지 않음.

### Lobby Stage Swipe + Slide Transition
- 침입자 기록/안내문 아래 StageMetaBox 내부 텍스트만 약 10px 아래로 내려 바깥 프레임과 카드 사이 여백 중앙에 더 가깝게 배치. StageCard 위치는 유지.
- 좌/우 스테이지 버튼 터치 영역을 64×124→84×168로 확대.
- ui8 화살표 이미지는 투명 여백을 crop한 텍스처를 사용해 실제 보이는 화살표도 더 크게 표시.
- 메인 StageCard 영역에서 좌우 스와이프/마우스 드래그로 이전·다음 침입자를 선택할 수 있도록 입력 추가.
- 수평 이동 90px 이상이며 세로 이동보다 충분히 큰 제스처만 스와이프로 판정해 버튼 탭/세로 터치와 충돌을 줄임.
- 좌/우 버튼 클릭과 스와이프 모두 동일한 _change_stage()를 사용하며, 현재 카드+StageMetaBox가 진행 방향 반대로 빠지고 다음 카드가 반대편에서 슬라이드 인하는 전환 애니메이션 추가.
- 스테이지 끝에서는 기존 clamp 동작을 유지하며 추가 전환을 실행하지 않음.

### Revert Swipe/Slide Runtime Regression
- Stage swipe/slide transition 패치 이후 lobby.gd 런타임 초기화가 중단되어 로고/프레임/ui10/초상화 스킨이 적용되지 않는 회귀 확인.
- Lobby.tscn을 마지막 정상 화면(96f0e654)으로 복구.
- lobby.gd를 StageMetaBox 경로 갱신까지만 포함된 마지막 정상 상태(54dc8709)로 복구.
- 좌우 버튼 확대, ui8 crop, 스와이프 입력, tween 전환 코드는 모두 제거.
- 다음 단계에서는 버튼 크기 조정과 스와이프/애니메이션을 분리해서 한 기능씩 검증 후 적용.

### Fix TSCN/Script Version Mismatch After Rollback
- 이전 롤백에서 Lobby.tscn은 96f0e654 시점으로 복구했지만 lobby.gd는 이후 StageMetaBox 경로를 사용하는 54dc8709 시점으로 복구되어 노드 경로가 불일치했음.
- 그 결과 @onready StageMetaBox 경로 해석 실패로 로비 스크립트 초기화가 중단되어 좌우 버튼 연결 및 초상화 로딩이 실행되지 않는 문제 발생.
- lobby.gd를 Lobby.tscn과 동일한 96f0e654 시점 파일로 복구해 씬/스크립트 버전을 다시 일치시킴.
- 버튼/초상화 기능 정상화 후 StageMetaBox 이동은 이후 한 단계로 다시 적용 예정.

### StageMeta Fix + Safe Swipe Input
- 카드 상단 테두리와 겹치던 STAGE 번호/침입자 제목을 StageCard 내부에서 제거하고 StageLayout의 별도 StageMetaBox로 이동.
- StageMetaBox는 안내문 아래와 ui10 카드 사이 92px 공간을 사용하며 텍스트를 아래쪽으로 내려 프레임 사이 여백 안에 배치.
- lobby.gd onready 경로를 새 StageMetaBox 경로와 동시에 갱신해 씬/스크립트 버전 불일치를 방지.
- 좌/우 버튼 클릭 영역을 64×124→82×160으로 확대.
- 스와이프/PC 마우스 드래그는 애니메이션 없이 먼저 단독 구현: StageCard 내부에서 시작해 수평 72px 이상 이동 시 이전/다음 스테이지 선택.
- Tween/await 전환 애니메이션은 이번 패스에서 제외해 런타임 안정성을 우선 검증.

### Stage Slide-In Animation + Meta Nudge
- 정상 동작 중인 StageMetaBox/스와이프 구조는 유지하고 STAGE 번호/침입자 제목만 같은 92px 슬롯 안에서 약 4~6px 아래로 이동.
- 좌우 버튼과 스와이프가 공통으로 호출하는 _change_stage()에 런타임 안정성이 높은 slide-in 전환 추가.
- await/동적 minimum-size/노드 재배치 없이 create_tween()만 사용해 새 StageCard가 진행 방향 쪽에서 92px 이동하며 0.18초 동안 자연스럽게 들어오도록 구현.
- StageMetaBox도 카드 이동량의 45%만큼 함께 이동/페이드해 제목과 카드가 따로 노는 느낌을 줄임.
- 전환 중 중복 입력은 _stage_transition_running으로 차단하고 tween.finished 시 자동 해제.
- 스와이프 판정 로직, 좌우 버튼 연결, 초상화 로딩 경로 및 ui10 내부 배치는 변경하지 않음.

### Stage Browser Lock Rule + Real Slide Transition
- STAGE 번호/침입자 제목을 기존 92px StageMetaBox 안에서 조금 더 아래로 배치하고, 하단에는 여백을 남겨 카드 상단 테두리와 겹치지 않도록 조정.
- StagePicker의 HBoxContainer가 StageCard 위치 tween을 덮어써 애니메이션이 보이지 않던 원인을 수정: HBox에는 StageCardSlot만 배치하고 실제 StageCard는 plain Control 슬롯 내부 자식으로 이동.
- StageCard 전환을 2단계 slide-out → 데이터 교체 → slide-in 방식으로 변경. 버튼/스와이프 모두 동일 전환 사용.
- 진행 방향 기준 150px 슬라이드와 페이드를 적용하고 전환 중 중복 입력 차단.
- 스테이지 탐색 한계를 highest_unlocked_stage + 1로 제한: 현재 최고 해금이 2면 3까지만 미리보기 가능, 4부터 탐색 불가. 최고 해금이 3이면 4까지만 가능.
- 미리보기 가능한 다음 스테이지는 기존 is_stage_unlocked 규칙에 따라 입장 버튼은 잠긴 상태 유지.
- 이전/다음으로 이동할 수 없는 방향의 화살표는 Button disabled 처리와 함께 회색/반투명으로 표시.
- 향후 StageCatalog에 stage_3 이상이 추가되어도 동일 규칙이 자동 적용됨.

### Smooth Scale/Fade Stage Transition + Portrait Cache
- 스테이지 전환 영상에서 카드 교체 순간이 끊겨 보이는 현상을 완화.
- 기존 단순 좌우 slide/fade를 '작아지며 사라짐 → 새 카드가 작은 크기에서 커지며 들어옴' 방식으로 변경.
- 카드 pivot을 중앙으로 설정하고 out 시 94%, in 시작 시 91% 크기를 사용해 자연스러운 축소/확대 감각 추가.
- 이동 거리를 150→118px로 줄이고 out 0.16초 / in 0.24초로 조정, cubic/quint/back easing 적용.
- STAGE 번호/침입자 제목도 카드와 함께 약하게 scale/fade되어 데이터 교체 순간이 덜 튀도록 보정.
- 전환 중 끊김의 주요 원인이 될 수 있는 초상화 alpha-visible-rect 스캔/리사이즈를 매번 반복하지 않도록 normalized portrait texture 캐시 추가.
- 현재 탐색 가능한 스테이지 초상화는 로비 초기화 시 한 번 미리 캐시하고, 이후 전환에서는 캐시된 Texture2D를 즉시 사용.
- 스와이프/드래그, 좌우 버튼, 탐색 제한(highest_unlocked + 1), 비활성 화살표 규칙은 유지.
