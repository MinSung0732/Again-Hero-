# 상점 전용 프레임

- SVG는 수정 가능한 원본, PNG는 Godot에서 원본을 래스터화한 런타임 에셋입니다. 128×96, 투명한 외곽, nearest 필터, 24px 9패치 경계.
- shop_panel_frame: 섹션/기본 상품. shop_featured_frame: 추천 상품. shop_button_frame: 보조 버튼. shop_title_frame: 별도 평면 리본형 제목/섹션(128×64). shop_primary_button: 강조 소환 버튼.
- 중앙은 글자/가격을 굽지 않은 빈 영역. 금색 연속 테두리와 자수정 모서리 장식, 어두운 보라색 내부. PNG/SVG를 함께 갱신하세요.
- 상점 전용이며 기존 commerce_v2 에셋을 덮어쓰지 않습니다. 텍스처는 shop_frame_skin.gd에서 캐시합니다.
