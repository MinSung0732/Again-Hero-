# 불가살 원본 기반 Godot 메시 리깅 (2026-10-09)

## 실행과 범위

`src/dev/bulgasal/cutscene_preview.tscn`을 F6 실행. Space 일시정지, R 처음부터.
현재 개발 미리보기는 원본 PNG 위에 Skeleton2D/Polygon2D 리깅을 적용한다. Cubism SDK 모델(.moc3/.model3.json)은 아니다. 16개 별도 생성 파츠를 조립하지 않으며 원본 자세/비율/갑주 디자인을 유지한다. 실제 뽑기/전투/보상 등록은 아직 없다.

## 원본과 움직임

원본 `rig_v1/approved_fullbody.png`는 저장소 `assets/art/Transcendent_monster/Bulgasal/bulgasal_illustration.png`와 SHA256이 같다: `ef97470c3bd6cd836682cc19178983c08c148b3586427b4e38ed96448679d5b9`.
원본971×1619 전체 캔버스를 단일 균일 배율로768×1280 안에 배치한다. 0초의 모든 뼈 rest 상태에서 원본 픽셀/UV 그대로 표시한다.
49×81(3969개) 정점과7680개 삼각형을 공유하는 하나의 연속 메시를 사용한다. 10개 뼈는 고정 몸체, 갈기 뿌리/끝, 천 뿌리/끝, 꼬리 뿌리/끝, 흉부 호흡, 좌/우 팔 호흡이다. 영역별 원본 좌표 마스크와 가장자리 feather 가중치를 준비 시1회 계산하며 가중치 합은1이다. 정점을 공유하여 독립 PNG 회전으로 생기는 관절 틈을 피한다.
얼굴·뿔·발·다리 보호 영역은 고정 뼈만 사용한다. 갈기/천/꼬리 끝에 작은 지연 회전을 주고, 흉부와 팔에는1.1px 이하의 국소 호흡 이동만 적용한다. 전신/파트 배율을 시간에 따라 바꾸지 않는다. 프레임마다 뼈 속성만 변경하고 텍스처/메시/노드/배열을 만들지 않는다.
배경·공개·화염/쇳조각·하단 이름은 별도 레이어. 원본 파츠 시트를 순서대로 넘기거나 원본 전체를 확대/축소하여 호흡을 흉내 내지 않는다. nearest, mipmap 없음.

## 남은 한계

현재는 원본의 보이는 영역에 국소 변형을 주는 native Godot 리그다. 원본의 겹친 부위를 완전히 분리/복원한 모델은 아니므로 큰 팔/고개 동작·눈/입 표정은 하지 않는다. 이런 동작에는 원본 좌표 파츠와 가림부 복원, 눈/눈꺼풀/입 별도 리소스가 필요하다. 원본 재합성 일치 검증 후 이 파츠를 추가해야 한다.
이전 `rig_v1/parts`, `manifest.json`, `layout.json`, `joint_patch_atlas.png`는 미사용·거부된 초안 기록이다. 현재 장면에서 로드하지 않는다. 배경/VFX는 검토용 생성 에셋이며 영상은 무음이다.

## 검증

Godot4.5.1 격리 프로젝트에서 원본 텍스처, 3969정점/10뼈, 정규화 가중치, 얼굴/다리 고정 가중치, 0초 rest 일치, 300회 시간 갱신 중 전체 배율/위치·노드수 유지, 이름 타이밍, 4비율 내부 배치를 검사했다.
Linux OpenGL(Mesa llvmpipe)에서 실제150프레임을 캡처하여30fps/5초 MP4로 인코딩했다. 전체 게임/Android/APK export 미검증.
검사: `godot --headless --path <project> --script res://src/dev/bulgasal/verify_rig.gd`.
캡처: `godot --path <project> res://src/dev/bulgasal/cutscene_preview.tscn -- --capture=<absolute-directory>`.
