# 회복 아이템 PNG 직접 읽기 경고 수정

- 시작 로컬/원격 feature/stage10-astra: `785cbe7f16b7eab056c0ebab7538959af9be06ea`, 작업 트리 clean. main: `6f22053f462e1176ec2ecde131d589d5491791b2`. main 병합 없음.
- 사용자 PC Godot4.7.2 대전 중 heal_item._load_texture의 float_01~04.png `Loaded resource as image file, this will not work on export` 경고를 보고받았다.
- 기존 함수가 원본 PNG를 Image.load로 먼저 읽고 ImageTexture를 만들었다. 이제 ResourceLoader를 통한 Texture2D 리소스만 사용한다. 원본 파일 존재 여부에 의존하지 않고 Godot import remap을 따른다. 경고를 숨기는 설정은 추가하지 않았다.
- Texture import의 fix_alpha_border=true가 기존 원본 직접 읽기와 달리 반투명 경계 RGB도 변경하는 것을 실제 픽셀 비교로 확인했다. 해당 회복 PNG4장의 `.import`에서 이 옵션만 false로 바꿔 원래 RGBA 픽셀을 보존한다. PNG 바이너리/경로·lossless 압축/크기·filter는 변경하지 않았다.
- 기존 공용 SpriteFrames/visible_height 캐시와 최초 생성 시점, float4프레임·8fps·loop, 첫 프레임 used_rect 기반54px 크기, 회복량70·줍기거리·수명·블링크·배치·그룹 조회는 그대로다. 소스 함수는 raw Image 경로4줄만 제거했다. 프레임별 작업/배열·새 노드/그룹 스캔은 추가하지 않았다.

## 검증

- Godot4.5.1 실제 heal actor/HealItem.tscn/pickup_placement 및 실제 PNG4장으로 격리 import·실행. 원본 이미지가 있는 프로젝트 **47검사**, 원본 PNG가 없는 PCK **47검사**, 합계 **94검사 PASS**, 최종 import/실행 ERROR/WARNING0.
- 원본 전체 RGBA SHA256·치수·불투명 영역이 Godot imported texture와 일치하는지 확인했다. import alpha border 보정을 끄기 전의 픽셀 차이와 끈 뒤의 일치를 확인했다.
- float 프레임 순서·속도/loop·재생/표시·정규화 크기, ResourceLoader texture 참조 재사용, 추가16아이템의 공용 SpriteFrames 캐시, 누락/잘못된 타입의 fail-soft, 실제 _physics_process에서 기존 회복량 호출/중복 수령 차단을 검사했다. 회복 수신 Hero는 호출 기록 어댑터이며 전체 Hero 회복 수식을 다시 검증한 것은 아니다.
- PCK는 기존 frontier fixture 방식처럼 `.png.import`와 `.godot/imported/*.ctex`를 포함하고 원본 PNG를 제외했다. **프로젝트 폴더 밖의 빈 디렉터리에서 실행**해 실제 파일 시스템의 원본으로 fallback하지 않는 것을 검사했다. FileAccess 원본 없음/ResourceLoader 로드 성공을 함께 확인한다. 이는 리소스 패키지 검증이며 APK/EXE native export 검증은 아니다.
- builder가 _load_texture 앞의 모든 actor 함수·선언 동일성을 확인한다. PNG4장 원본 해시 동일, `.import`는 fix_alpha_border 옵션만 변경, Python AST와 git diff --check 통과.
- PC4.7.2·Android 실기 재실행, 전체 전투/온라인 대전 회귀·GPU 화면·실제 APK/EXE export는 이번에 실행하지 않았다. 다른 스크립트의 raw Image fallback 전체를 수정한 것은 아니다.

재현 (`godot`은 실행 파일 경로로 교체):

```sh
python tools/build_heal_resource_fixture.py /tmp/heal-resource-fix --baseline 785cbe7f16b7eab056c0ebab7538959af9be06ea
godot --headless --path /tmp/heal-resource-fix --editor --import
godot --headless --path /tmp/heal-resource-fix --script res://tests/heal_item_resource_smoke.gd
godot --headless --path /tmp/heal-resource-fix --script res://pack.gd -- /tmp/heal-resource-fix.pck
```

그 다음 프로젝트 밖의 빈 폴더를 만들고, 그 폴더에서 실행한다:

```sh
godot --headless --main-pack /tmp/heal-resource-fix.pck --script res://tests/heal_item_resource_smoke.gd -- --packed
```
