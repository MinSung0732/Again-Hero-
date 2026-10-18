# 결과창 높이 축소·중앙 정렬 — 2026-10-14

115911에서 결과창의 확장 ScrollContainer가 화면 끝까지 늘어나 기록/보상과 버튼 사이에 큰 빈 공간을 만들었다. 결과 패널은 화면 세로 중앙 anchor0.5를 사용하고, `parent.get_combined_minimum_size()`(제목/버튼/간격)와 본문 최소높이 및 panel margin48을 더해 실제 필요한 높이를 계산한다. 최대높이는 화면 높이-48이며, 화면이 작으면 본문만 스크롤한다.

원본 프레임과 무기 아이콘을 재사용한다. 아이콘72px, 본문 섹션 간격12px. 제목/실제 시간/처치/레벨/장착 무기와 rank/실제 보상/필요한 행동버튼은 유지한다. 저장 실패도 같은 중앙 배치로 재시도를 제공하며 기존 보상 캐시/단회 정산/진입·해금 가드는 변경하지 않는다.

fit는 parent resize/본문 minimum_size_changed와 최초 deferred 호출에서만 실행한다. parent를 재사용해도 연결을 중복하지 않고 ResultScroll이 없는 다른 overlay에서는 적용하지 않는다. 프레임별 측정·전투 핫패스 변경은 없다.

검증: build_hero_result_fixture.py → hero_result_smoke.gd135 PASS. 실제 production _show_result와 UI를 사용하는 격리 host에서 승리·패배×1080×1920/540×960/1920×1080/960×540 중앙 정렬/화면 경계/본문 빈 공간 제거/높이 축소/버튼·본문 접근, 저장 실패/성공/재그림 단회 보상/마지막 스테이지/실클릭·합성터치를 검사했다. 전투·정산 host는 mock이며 실제 전체게임 GPU/Android 화면 검증은 아니다.
