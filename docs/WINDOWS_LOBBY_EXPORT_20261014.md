# Windows 로비 진입 배포 오류

사용자 Godot4.7.2 Windows 출시 로그에서 hero_hud_art.gd:3의 `res://assets/art/ui/hero_hud/hero_hud_atlas.png` preload 누락과 PresentationWarmup 컴파일 실패가 확인됐다. 종료 직전 로비의 raw SVG 누락 경고, 빈 avatar 경로 load가 res://로 해석되는 오류도 발생했다. 로그에 네이티브 크래시 stack은 없어 종료 원인 전체를 확정하지 않는다.

## 변경

UI/ui 대소문자 중복 폴더를 assets/art/UI 하나로 통일. hero_augments7파일과 hero_hud1파일의 내용은 변경하지 않는다. 로비 PNG/SVG helper는 imported resource를 우선 읽으며 crop/top region은 원래 texture를 사용하는 AtlasTexture로 처리한다. 게스트 avatar 미선택은 null로 유지한다.

## Windows 적용

Godot을 닫고 feature/stage10-astra 최신 커밋을 받는다. 프로젝트를 다시 열어 import가 완료될 때까지 기다린다. FileSystem에서 assets/art/UI/hero_hud/hero_hud_atlas.png가 보여야 한다. 이전 case 경로 cache가 남으면 Godot을 닫고 프로젝트의 .godot 폴더(에디터 cache)만 재생성한다. user:// 저장 파일이나 assets 원본은 삭제하지 않는다. Windows Desktop/all_resources/release로 새 폴더에 다시 내보내고 새 exe와 pck를 함께 실행한다. 기존 바이너리에는 소스 패치가 자동 반영되지 않는다.

## 검증

`python tools/build_lobby_export_fixture.py <outside-repo-path>`로 실제 HUD/증강 atlas와 production 로비 텍스처 함수만 포함하는 격리 프로젝트를 만든다. catalog의 몬스터 scene preload는 null로 치환한다(배우 검증 아님). Godot --headless --editor --export-pack Pack로 PCK를 생성하고 --headless --main-pack으로 실행한다. 원본 PNG/SVG 제외 상태를 검사하며133검사 통과. Python compile과 diff 검사 통과. 전체 로비·실제 Windows exe/GPU·Android 미검증.
