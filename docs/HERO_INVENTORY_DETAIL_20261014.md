# 용사 인벤토리 상세 팝업 — 2026-10-14

상단무기/보조슬롯의기존pressed연결을유지하고상세내용을공통`hero_inventory_detail.gd`로분리했다. 사용자참고이미지의큰아이콘/이름/배지→기본능력치→효과→연관강화흐름→계속플레이구조를따른다. 기존골드pixelframe/무기·보조PNG를재사용하며새그림생성이필요하지않았다.

실제100무기현재rank/진화/피해계수/보조power·haste/공격범위·다중발동·무기흡혈을읽는다. 기본타격피해는조건부기술/치명타/적방어적용전수치라고명시한다. 예시1906/90%등가상수치를게임값으로쓰지않는다. 보조효과는보유레벨누적으로표시하며피해감소30%/멀티샷2개/둔화저항실제여유상한을적용한다. MAX는무기실제상자진화완료/보조최대레벨에만표시한다. 레벨10진화전무기는Lv10으로유지한다.

상세창배경은어둡게입력차단하고전투/이동패드를일시정지한다. X와계속플레이는공통재개핸들러를사용해전투/입력을복원한다. ESC/모바일뒤로가기역시기존ui_cancel경로를사용한다. 본문만ScrollContainer에넣고닫기/계속버튼은고정한다. 터치와PC클릭은같은GodotButton을사용하며프로젝트에마우스에뮬레이션을명시했다. 다른증강선택/룰렛중열기거부, 빈슬롯/음수index거부, 계정/입장가드를유지한다. 다른overlay로전환하면원래스타일과backdrop상태를복원한다.

연관콘텐츠는현재상자진화/강화우선순위와보조강화경로를안내하는텍스트다. 전투중상점이동이나즉시무료강화같은새기능은추가하지않는다.

Godot4.7.2 headless격리641검사+기존HUD/룰렛107=748검사PASS. 100무기진화전후/16보조모델,1080×1920·540×960·1920×1080실제UI컨트롤배치/스크롤/마우스pressed·release/합성ScreenTouch탭, production정보·모달·재개·ui_cancel함수추출을검사했다. Battle호스트/아트네이티브전투씬은mock이며실제GPU픽셀렌더/Android터치감은검증하지않았다.

재현:

```bash
python tools/build_hero_inventory_detail_fixture.py /tmp/hero-inventory-detail
godot --headless --path /tmp/hero-inventory-detail --editor --import --quit
godot --headless --path /tmp/hero-inventory-detail --script res://tests/hero_inventory_detail_smoke.gd
python tools/build_hero_hud_fixture.py /tmp/hero-inventory-hud
godot --headless --path /tmp/hero-inventory-hud --editor --import --quit
godot --headless --path /tmp/hero-inventory-hud --script res://tests/hero_hud_inventory_smoke.gd
```

기준원격7006304. 커밋revert로롤백. main은요청시에만병합한다.
