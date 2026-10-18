# 신규 원거리 몬스터 투사체 교체

기존 FrontierBolt가 그리던 사각형·마름모 임시탄을 몬스터 테마에 맞춘 실제 투명 PNG 비행 애니메이션으로 교체한다. 일반 공격과 엘리트 부채꼴 공격이 같은 종의 이펙트를 공유한다.

| 몬스터 | 투사체 |
|---|---|
| 임프 | 붉은 화염탄 |
| 사티로스 주술사 | 눈과 뼛조각이 감싼 보라색 저주탄 |
| 밤가시고슴도치 | 올리브색 가시침 |
| 포자버섯 | 붉은 포자 뭉치 |
| 등불도깨비 | 황금빛 도깨비불 |
| 이끼뿔사슴 | 잎으로 감싼 씨앗탄 |
| 잿불도롱뇽 | 용암 균열이 있는 잿불 바위탄 |
| 서리깃올빼미 | 얼음 깃털 |
| 독침전갈 | 맹독을 두른 전갈침 |
| 달가루나방 | 달가루를 흘리는 초승달 |

## 생성·패키징

- 내장 imagegen 사용. 종별 기존 `assets/art/monsters/<id>/frames/idle_01.png`를 팔레트·소재 참조로 사용하며 몬스터 본체는 새 이펙트에 넣지 않는다.
- 원본·2열2행 스프라이트시트·비행4프레임·SpriteFrames·manifest는 `assets/art/projectiles/frontier/<id>/`에 함께 저장한다.
- 정확한 프롬프트·참조·생성 파일 정보: `FRONTIER_PROJECTILE_ART_SOURCES_20261017.json` 및 각 manifest의 generation 항목.
- 프레임은 원본 셀을 1:1 절단하고 코어 anchor에 맞춰 정수 픽셀로 이동한다. RGB 키잉·축소·보간·팔레트 양자화 없음. 생성된 반투명 가장자리는 alpha>=128만 남기는 이진 경계 정리이며 남긴 픽셀 RGB는 원본과 동일하다. 원본 PNG는 그대로 보존한다.
- 본체 앞부분의 연결 영역으로 코어를 찾고 꼬리·파편을 제외해 중심을 맞춘다. 잘림 없는 공통 캔버스/중심과 동일 배율을 사용한다. 실제 화면상 최대 폭48, 12fps·4프레임 반복·nearest 필터. 전투 판정 반경24는 이전과 동일하다.

## 런타임

- FrontierMonsterCatalog의 `behavior.projectile_art` → FrontierProjectileArtCatalog의 공유 SpriteFrames·배율 → 기존 풀링 FrontierBolt 경로.
- `_physics_process`에서 비행 애니메이션 인덱스만 갱신하고 프레임이 바뀔 때만 다시 그린다. 프레임별 리소스 로드·배열/Dictionary 생성·새 노드 생성 없음.
- 재사용 시 프레임·시계·리소스·표시 영역 초기화. 탄의 방향 회전·생성 시 조준·탄속·사거리·스윕 명중·상태이상·세대 핸들·재활용 시점 유지.
- 원본 PNG가 없는 배포에서도 preload된 SpriteFrames가 Godot import 리소스를 참조한다. 알 수 없는 프로필에만 기존 도형 fail-soft 경로를 유지한다.

## 검증

- Godot 4.5.1 headless 격리 fixture: 신규 투사체215검사(실제10종 씬·공유 SpriteFrames·4프레임 진행/루프·풀 재사용/초기화·실제 적중·엘리트 부채꼴 방향/아트 계승), 기존 Frontier27종 전투3796검사 통과. 런타임 로그에 SCRIPT ERROR/ERROR 없음.
- Python PNG 감사300검사:10종40프레임 RGBA/이진alpha/원본 보존 SHA/정수 이동 후 RGB 동일/opaque 픽셀 유실 없음/시트 정합/투명 여백/프레임 중복 없음.
- 원본 PNG 없는 별도 PCK·빈 프로젝트에서 기존 몬스터1238프레임54폼 + 신규 투사체40프레임 로드 통과. 새 아트는 실제 파일이며 누락된 다른 아트/오디오는 기존 fixture 대역. 최종 import/pack/export 오류 없음.
- `git diff --check` 통과. Android/GPU 화면·실제 전투에서의 가독성·기기 FPS는 미검증.

재현: `python tools/package_frontier_projectile_art.py docs/FRONTIER_PROJECTILE_ART_SOURCES_20261017.json` (생성 경로가 없으면 저장소에 보존한 원본 PNG 사용), `python tools/audit_frontier_projectile_art.py`, `python tools/build_frontier_fixture.py /tmp/frontier-vfx-fixture` 후 Godot import·`tests/frontier_projectile_art_smoke.gd` / `tests/frontier_monsters_smoke.gd`. PCK는 `tools/pack_frontier_art_fixture.gd`로 만든 후 빈 `--path`에서 `tests/frontier_art_export_smoke.gd` 실행.
