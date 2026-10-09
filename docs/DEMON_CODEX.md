# 마왕 도감

기타 → 마왕도감. 첨부 예시의 고딕 금색/보라색 프레임 구조를 기존 commerce_v2 에셋으로 구성한다. 예시 수치나 미등록 몬스터는 추가하지 않는다.

## 화면과 데이터

| 분류 | 표시 정보 | 원본 |
|---|---|---|
| 마왕 스킬 | 게이지 최대/회복/충전 조건, 실제 3종 소환 기술의 수/비용/거리/재사용 | DemonUltimateCatalog |
| 일반 몬스터 | 현재 21종 도트, 등급/종류/역할/공격 타입, 연구·증강 전 기본 능력/소환 비용, 엘리트 도트·기술 및 전용 증강 | MonsterCatalog, DemonAugmentCatalog |
| 마왕 증강 | 마왕 전체 증강 설명/최대 레벨 및 지휘/성장/경제 필터 | DemonAugmentCatalog.NORMAL_AUGMENTS |
| 초월 몬스터 | 제우스/불가살/이자나미/만티코어 도트, 실제 전투 해금조건, 기술·패시브·5초월 효과, 현재 획득 상태 | MonsterCatalog, TranscendentDetailCatalog, TranscendenceCatalog, MonsterCollectionStore |

일반/초월 목록은 이름·역할·종류 검색 및 등급·역할 필터를 제공한다. 기본 능력은 추가 성장/연구/증강/엘리트 배율을 포함하지 않으며 내부 공격 판정 거리를 표시한다. 초월의 누적 성장 및 명시적인 지름/투사체 거리 등은 기술·강화 효과에 자세히 표시한다. 예시의 추천 조합/위험도 같은 계산되지 않은 평가는 넣지 않는다.

## 일러스트와 배너

초월 일러스트/배너는 원본 비율을 유지해 미리 본다. 제우스 일러스트는 기존 뽑기 초상화이며 다른 세 종은 기존 원본 일러스트다. 5초월 배너는 실제 등록된 제우스와 만티코어만 활성화한다. 불가살/이자나미는 버튼을 비활성화한다. 열람은 소유·강화조건을 바꾸지 않고 장착/보상 지급도 하지 않는다. 계정의 소유/효과 활성 표시는 화면을 다시 열 때 갱신한다.

## 스킬 아이콘 연결

`src/data/skill_icon_catalog.gd`의 PATHS에 명시적으로 경로를 등록한다. 아직 빈 경로표이며 잘못된 임시 아바타/자동 파일명 추측 대신 테두리 있는 기술 자리를 유지한다.

| 키 형식 | 예시/식별 기준 |
|---|---|
| demon:demon:skill_id | demon:demon:encirclement, demon:demon:line_assault, demon:demon:square_siege |
| elite:monster_id:skill_id | MonsterCatalog.get_elite_skills의 id (없으면 name) |
| transcendent:monster_id:skill_id | TranscendentDetailCatalog 기술의 id (현재 없으므로 정확한 name) |
| hero:hero_id:skill_id | HeroProfileCatalog 내 기술 id. 단계 ID와 구분 |

예: `"demon:demon:encirclement": "res://assets/art/UI/skills/demon/encirclement.png"`.

슬롯에는 icon_key 메타데이터가 있다. 용사도감 기술 탭은 슬롯을 재사용하며 미발견 용사, 잠금 열림 연출 및 계정 변경 중에는 슬롯을 숨긴다. 초월 기존 팀 편성 상세와 마왕 도감이 같은 아이콘 경로표를 사용한다. 이미지 등록 후 앱을 재시작한다. PNG를 추가하면 Godot에서 import 후 export 검증도 필요하다.

## 구조·검증

lobby_demon_codex_view는 기존 lobby_settings_view의 메뉴/뒤로 이동과 연결한다. 한 외부 ScrollContainer 아래 페이지를 최초 방문 때 생성한다. 카드/일반 기술 상세/이미지는 캐시하며 입력·페이지 이동에만 필터/상태를 갱신한다. 전투 인스턴스·매 프레임 그룹 조회·배열 생성은 추가하지 않는다.

Godot4.5.1 헤드리스: tests/demon_codex_smoke.gd, tests/hero_codex_smoke.gd, tests/transcendent_detail_smoke.gd, tests/lobby_settings_smoke.gd. 도감 검색/리소스/360~1000 콘텐츠 폭/저장 불변/캐시 재사용, 용사 잠금과 터치, 실제 로비 이동을 검사한다. 기존 로비 종료 리소스잔존/이미지 fallback 경고는 유지된다. GPU 화면 미관, 실제 Android 터치/팝업, export는 별도 기기 검증 대상이다.
