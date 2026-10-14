# 배포 프로필·픽업 이미지 복구

프로필선택목록을만드는profile_cosmetic_store와lobby_profile_icon_picker가FileAccess.file_exists(PNG)를사용해원본없는배포PCK에서목록을비웠다. selected_id는빈문자열을반환하고계정/프로필loader가null로표시했다. ResourceLoader.exists로변경해importremap을인식한다. 캐릭터소유/성별/초월해금·5초월보상·저장ID/지갑은변경하지않는다.

shop_pickup_view는원본PNG직접읽기만있어배포본에서null이었다. 공용warmup Texture2D캐시→ResourceLoader→미import개발원본fallback 순서로복구했다. 동일경로는뷰의textures사전재사용,빈경로는null. 프레임/크기/픽업확률/로그인기능변경없음.

이전export최적화는무기제작source/icon/sheet와raw증강원본만제외하며프로필·제우스픽업이미지를제외하지않는다. 제작원본을배포에다시넣는방법이아니라실제imported이미지의존성을사용한다.

정적검증: GDScriptparser4파일,Python buildercompile,preload45스크립트의존성,실제7PNG무결성,imported경로·diff검사PASS. Godot실행파일이이환경에서없어이번실행검증없음. tools/build_profile_export_fixture.py <outside-repo>→Godot --headless --path <fixture> --editor --export-pack Pack <out.pck>→Godot --headless --main-pack <out.pck>로남녀기본avatar/banner·소유잠금/제우스보상선택·프로필/계정loader·픽업이미지·캐시를검사한다. monsterscene는격리에서null치환;실제Windows/Android화면검증은별도.

Godot종료→feature/stage10-astra최신받기→import완료→EXE/APK다시내보내기. 기존게스트/계정저장은유지한다. 새exe와그에맞는pck를함께사용해야하며기존APK에는패치가자동적용되지않는다.
