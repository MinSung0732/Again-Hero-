# Battle HUD polish

전투 HUD 상용화 브랜치에서 쓰는 게임 적용용 픽셀 프레임 세트.

- panel_large.png: 하단/카드/대형 패널
- panel_square.png: 메뉴/상세정보 버튼
- panel_wide.png: 상태/카운터 패널
- panel_wide_accent.png: Stage/필살기 강조 패널

모바일 세로 1080x1920 기준. nearest-neighbor와 NinePatch/StyleBoxTexture 사용.
생성 컨셉 이미지는 레이아웃 참고용이며, 런타임에는 프로젝트의 기존 픽셀 프레임을 재사용해 그림체를 통일한다.
