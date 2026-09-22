# 《용사, 또 너야?》 모바일 UI 리소스 제작 규격

## 1. 기준 화면
- 기준 해상도: **540 x 960 px**
- 비율: **9:16 세로형**
- 실제 기기에서는 Godot이 이 논리 해상도를 기준으로 확대/축소한다.
- 도트 UI는 540 x 960 기준으로 실제 사용 크기를 설계한다.
- 중요한 정보/장식은 화면 외곽 16~24 px 안전영역 안쪽에 둔다.

## 2. 공통 제작 규칙
- PNG, 투명 배경.
- 안티앨리어싱 금지.
- 블러/소프트 그림자 금지.
- 반투명 외곽 픽셀 금지.
- Nearest Neighbor 확대 기준.
- UI 장식 픽셀은 2 px 그리드 권장.
- 최소 테두리 2 px, 강조선 4 px 권장.
- **한 PNG 안에 서로 다른 여러 UI 파츠를 몰아넣지 않는다.**
- **한 파일 = 한 역할** 원칙.
- 완성 프레임은 9-slice 사용을 전제로 제작한다.
- 모서리 장식 영역은 고정, 상/하/좌/우 직선 구간은 늘리거나 반복 가능하게 만든다.
- 중앙 배경은 가능한 한 단순하게 유지한다.

## 3. 필수 납품 파일과 권장 크기
### Header
파일명: ui_header_frame.png
- 실제 사용 영역: 약 500 x 100~110 px
- 권장 원본: 500 x 108 px
- 좌우 장식은 32~48 px 이내.
- 중앙 텍스트 영역 최소 360 px 확보.
- 타이틀/골드/최고 해금 텍스트는 이미지에 포함하지 않는다.

### Main Content Frame
파일명: ui_content_frame.png
- 실제 사용 영역: 약 500 x 720~750 px
- 권장 원본: 500 x 740 px
- 장식은 외곽 20~32 px 안에서 끝나게 한다.
- 내부 콘텐츠 영역을 넓게 확보한다.
- 9-slice 가능한 구조 필수.

### Stage Card
파일명: ui_stage_card_frame.png
- 실제 사용 영역: 약 400 x 480~520 px
- 권장 원본: 400 x 500 px
- 상단 STAGE 표기/용사 이름/초상화/설명/버튼이 들어갈 내부 공간 확보.
- 내부 장식은 최소화.
- 9-slice 권장.

### Small Card
파일명: ui_small_card_frame.png
- 실제 사용 영역: 약 230 x 280~330 px
- 권장 원본: 232 x 320 px
- 몬스터 카드/연구 카드/상점 결과 카드 공용.
- 2열 배치 기준.
- 카드끼리 붙었을 때 장식이 과하지 않게 한다.

### Bottom Navigation
파일명: ui_bottom_nav_frame.png
- 실제 사용 영역: 약 520 x 84~100 px
- 권장 원본: 520 x 96 px
- 5개 탭 버튼이 들어가는 일체형 바.
- 내부 버튼 구획은 너무 두껍지 않게.
- 중앙/선택 탭이 강조될 수 있는 여유 공간 확보.

### Active Nav Tab
파일명: ui_nav_active.png
- 권장 크기: 96 x 72 px
- 하단 5개 탭 중 선택된 버튼에 얹는 강조 프레임.
- 주변 탭을 침범하지 않게 제작.

### Primary Button
파일명: ui_button_primary.png
- 권장 크기: 360 x 72 px
- 던전 입장/10+1 구매/확인 등 주요 행동.
- 9-slice 권장.
- 내부 텍스트는 이미지에 포함하지 않는다.

### Secondary Button
파일명: ui_button_secondary.png
- 권장 크기: 180 x 64 px
- 상세정보/편성/취소/닫기 등.
- 9-slice 권장.

### Arrow Button
파일명:
- ui_arrow_left.png
- ui_arrow_right.png
- 권장 크기: 56 x 96 px
- 화살표 심볼 포함 가능.
- 배경과 심볼을 분리할 수 있으면 더 좋음.

### Popup Frame
파일명: ui_popup_frame.png
- 권장 원본: 440 x 620 px
- 몬스터 상세/용사 상세/확인 팝업 공용.
- 9-slice 필수.

### Small Slot / Chip
파일명: ui_slot_small.png
- 권장 원본: 150 x 92 px
- 팀 편성 3칸, 연구 포인트/작은 상태 표시 등에 사용.

## 4. 파일 구조 권장
assets/art/UI/mobile/
- ui_header_frame.png
- ui_content_frame.png
- ui_stage_card_frame.png
- ui_small_card_frame.png
- ui_bottom_nav_frame.png
- ui_nav_active.png
- ui_button_primary.png
- ui_button_secondary.png
- ui_arrow_left.png
- ui_arrow_right.png
- ui_popup_frame.png
- ui_slot_small.png

## 5. 9-slice 제작 기준
- 모서리 장식은 절대 늘어나면 안 된다.
- 상/하 중앙선은 가로로 늘려도 형태가 깨지지 않아야 한다.
- 좌/우 중앙선은 세로로 늘려도 형태가 깨지지 않아야 한다.
- 중앙 채움은 단색 또는 반복 가능한 패턴으로 한다.
- 장식이 모서리에서 중앙 영역까지 길게 뻗지 않게 한다.
- 프레임 장식 두께는 실제 사용 크기의 약 5~10% 안쪽 권장.

## 6. 금지 사항
- 한 PNG에 헤더/버튼/카드 등 여러 완성 UI를 같이 넣지 않는다.
- 서로 다른 역할의 스프라이트를 한 이미지에 배치하지 않는다.
- 완성 패널 전체를 나중에 비율 강제 Stretch해야 하는 구조로 만들지 않는다.
- 텍스트를 이미지에 박지 않는다.
- 1 px 반투명 안티앨리어싱 가장자리를 만들지 않는다.
- 실사용 크기와 전혀 다른 초대형 원본으로 제작하지 않는다.

## 7. 납품 시 같이 요청할 것
- 540 x 960 기준 로비 완성 목업 1장.
- 각 PNG가 목업에서 어느 위치/크기로 사용되는지 표시한 가이드 1장.
- 9-slice 가능한 파일은 권장 slice margin 값을 메모로 함께 제공.
- 예: ui_header_frame.png = L40 / T28 / R40 / B28

## 8. 현재 프로젝트 방향
- 모바일 세로 화면 우선.
- 상단 상태바 -> 탭 콘텐츠 -> 하단 고정 네비 3단 구조.
- 장식보다 가독성/터치 영역 우선.
- 주요 버튼 높이 60 px 이상 유지.
- 프레임은 분위기를 만들되 텍스트 영역을 침범하지 않는다.
