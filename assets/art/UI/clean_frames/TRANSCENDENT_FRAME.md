# 초월 카드 테두리

최종 파일: `transcendent_card_frame.png` — 128×128 RGBA, alpha 0/255만 사용, 투명 중심, 32px nine-slice, nearest, no mipmaps. UI 테두리이므로 캐릭터 애니메이션/스프라이트 셀 규칙의 적용 대상은 아니다. 기존 제우스 아이콘은 변경하지 않았다.

게임 내 초월 희귀도 색상 #61e887을 사용하며 짙은 보라 외곽, 은색 선, 녹색 보석, 작은 금색 보석 테두리로 일반 카드와 구별한다. `tools/build_transcendent_card_frame.gd`에서 정수 픽셀만 기록해 재생성할 수 있다. 런타임에는 완성 PNG만 로드하며 픽셀 합성 코드는 실행하지 않는다.

ImageGen built-in으로 생성한 초기 테두리는 반투명 가장자리 검수에 실패해 게임 리소스에 사용하지 않았다. 최종 에셋은 기존 clean-frame UI 제작 방식에 맞춘 네이티브 픽셀 에셋이다. 초기 프롬프트: "Production nine-slice border-only transparent PNG for dark fantasy pixel-art mobile card game; emerald #61e887 jade crystals, dark #171020 outlines, antique silver, tiny gold highlights; four symmetric stepped corners, straight constant edge strips, completely transparent center; no text, blur, antialiasing or translucent pixels."
