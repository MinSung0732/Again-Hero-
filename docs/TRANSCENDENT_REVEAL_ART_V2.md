# 초월 뽑기 이미지 및 아서왕 돌진 수정 (2026-10-11)

기준 원격 feature/stage10-astra: `809f24978df91743e0610c339415f64ffaa2d2b9`.
main `4122adb73e14552aae7c0aa7edefb2827f5d08d0`은 수정하지 않는다.

## 신규 이미지

내장 image_gen으로 실제 PNG 8개를 생성했다. 런타임 도형만 추가한 작업이 아니다.
원본 생성 결과를 수정 없이 `assets/art/effects/gatcha/reveal_v2/`에 저장한다.
정확한 생성 프롬프트, 원본 기준, 크기, 파일 SHA256은 같은 폴더 `manifest.json`에 기록했다.

| 파일 | 테마 / 용도 |
| --- | --- |
| zeus_aura.png | 청금색 번개·신성한 빛 |
| bulgasal_aura.png | 용광로 화염·철 파편 |
| izanami_aura.png | 명계 영혼불·보라색 요기·피안화 |
| manticore_aura.png | 맹독 녹색·보라 재앙불 |
| shuten_doji_aura.png | 붉은 술안개·귀염·사슬 |
| arthur_aura.png | 원탁 성광·금백색 광선 |
| arthur_avalon_background.png | 새 아발론 성당 뽑기 배경 |
| arthur_closed_eyes_source.png | 원본 기준으로 생성한 눈감은 표정 소스 |

오라는 1254x1254 단일 PNG다. 프레임 시트가 아니라 공통 retained layer에서 확대·미세 회전·방출 파동 3회·입자 24개로 연속 재생한다. 실제 기존 뽑기 결과 경로에서 6종 모두 연결한다. 캐릭터 뒤, 배경 앞에 그리며 원래 리그·본체 앞 기술 이펙트를 유지한다. 공개 시점은 기존 효과음 타이밍에 맞춘다.

nearest, mipmap 없음. 생성된 투명 영역의 미량 alpha(1/255)는 cutout shader에서 제거하고 전체 효과 페이드는 draw tint로 처리한다. 원본 PNG를 재가공하지 않는다. 오라 중앙에 캐릭터 공간을 확보한다.

성당 PNG 배경은 아서왕 뽑기와 전투 소환 삼각형 모두에 연결한다. 전투에서는 사각형 컨테이너를 숨기고 Polygon2D에 같은 텍스처를 종횡비 유지 cover UV로 적용한다. 기존 hall shader는 뽑기 배경에 16% 움직임 레이어로만 사용한다.

찌르기 돌진은 80px 간격, 최대 alpha 0.32, 0.30초 페이드의 본체 잔상을 사용한다. 8개 고정 슬롯과 기존 skill 텍스처/방향/전역 transform을 재사용한다. 일시정지 시 잔상 시간도 멈추며 사망 시 비운다. 피해·충돌 판정은 변경하지 않는다.

눈감은 생성 결과는 원본과 완전히 동일한 전신 픽셀을 보장하지 않으므로 전신 교체에 쓰지 않는다. 기존 arthur_holy_reveal shader가 두 눈 영역만 새 PNG의 정규화 UV로 읽는다. 나머지 얼굴·머리·갑옷·실루엣·메시 좌표는 모두 원본 그대로 유지한다. 전투 0.25~0.5초 눈감음, 1.95~2.2초 눈뜸, 이후 원본 눈으로 복귀한다. 생성 이미지에서 실제 닫힌 눈을 확인했고 원본 파란 홍채 픽셀이 전부 교체 영역 안에 있음을 읽기 전용 픽셀 검사로 확인했다. 실제 GPU에서 최종 표정 정렬은 미검증이다.

기존 player가 뷰 및 새 layer를 재사용한다. 선택된 오라만 최초 load하며 전부 startup preload하지 않는다. 새 전역 강한 텍스처 캐시는 없다. 뷰가 해제되면 layer 참조도 해제된다. 새 이미지 전체를 보았을 때의 RGBA8 이론상 메모리는 manifest에 기록했다. 메모리/프레임 시간 실측 주장이 아니다. 스킵·취소·재사용·5초 종료·알 수 없는 ID에서 상태를 정상 복구한다. 확률·보상·재화·전투 판정에는 이미지 레이어가 관여하지 않는다.

## 아서왕 실제 전투 수정

- 실제 Hero는 `is_dying`, 일반 몬스터는 `dying`을 사용한다. 이전 `_alive`가 실제 Hero의 없는 `dying`을 `bool(null)`로 변환해 오류를 내면서 돌진 시작이 실패했다. Mock에는 dying이 있어서 기존 검사가 놓쳤다. 이제 두 플래그를 null-safe 비교하고 실제 Hero를 넣은 전체 physics 상태 머신 검사로 보완했다.
- 집중과 돌진 동안 skill_01을 정지 유지한다. Visual 자체의 대기 중 locomotion tick이 집중 포즈를 덮지 않도록 멈추고 pose lock을 유지한다. 완료·제어 중단·대상 삭제 후 명시적으로 해제하고 일반 프레임으로 복귀한다.
- 엑스칼리버·축복·가호 이펙트는 캐릭터 root의 `_draw` 대신 하나의 retained CombatEffectsFront(z absolute 5)에 그린다. 성의 depth normalization이 본체를 z0으로 바꿔도 가리지 않는다. 상태바는 기존 absolute z12다.
- 본체 표시 높이를 120→108(90%)으로 바꾸고 동일 발 anchor로 위치·체력바 기준을 다시 계산한다. 피해·체력·충돌 반경은 변경하지 않는다.
- 게이트는 CollisionObject나 target registry에 등록하지 않는 Node2D이며 z0으로 CastleDepthProp과 같은 발 위치 Y-sort에 참여한다.
- 돌진 방향은 시작할 때 고정하며 기본 1000거리/900속도를 유지한다. 실제 Battle의 기존 wander clamp 경계에서 각 축의 허용 직선 이동 거리를 계산해 맵 밖으로 뚫지 않는다. 장식물은 비행 중 collision layer/mask0으로 통과한다.
- 최종 착지와 중단 시, 충돌 복구 전에 decor/hard-wall mask만 검사한다. 보관한 KinematicCollision2D로 test_move를 사용해 장식물 footprint에서 뒤로 벗어난다(최대48회). 출발점부터 겹쳤던 예외는 경계 안 4반경×8방향 한정 복구를 시도한다. 일반 actor 밀집은 착지 검사에서 제외한다. 매 프레임 그룹 스캔/배열 생성/instantiate를 추가하지 않는다.
- 아주 비정상적인 맵에서 모든 유한 탐색 후보가 막혔다면 유효 위치를 보장할 수 없다. 정상 성 footprint 실제 검사에서는 장식물 밖 착지 및 collision restore를 통과했다.

## 검증

Godot 4.5.1 실제 headless:

- 새 뽑기 아트:90개 PASS(6종·실제 resource 연결·중앙 투명·종횡비·스킵/취소/재사용/종료·아서왕 닫힌눈 sampler).
- 아서왕 combat:179개 PASS(기존0~5초월 판정 및 hold pose/foreground/gate depth).
- 아서왕 integration:54개 PASS(실제 Hero와 physics 이동·900속도·충돌무시·맵4방향·실제 StaticBody2D 장식물 밖 착지·기존 보상/배너).
- 제우스/이자나미/만티코어/슈텐도지 기존 컷신 회귀 PASS.
- 불가살 presentation PASS. 기존 fixture의 초월2종 캐시 가정을 현재 catalog의 고유 prewarm 경로 기준으로 교체했다.
- import, 리소스 경로/이미지 SHA 확인, git diff --check.

기존 raw PNG export 경고와 headless 종료 시 RID/resource 잔류 경고는 남는다. 로그 오류0/누수0라고 주장하지 않는다. PC 실제 화면/모바일/소리 청취/목표 Godot4.7/export/성능 실측은 미검증이다.

수동 확인: 초월6종 뽑기에서 얼굴 가독성·파동·스킵, 아서왕 전투 눈감음/눈뜸 확대 시 경계, 중앙과 벽/기둥 근처 돌진 및5초월3돌진, 장식물 앞뒤 게이트 깊이, 휴대기기 프레임 시간을 확인한다.
롤백은 이 변경 커밋을 revert한다. 기준809f2497의 전투/연출로 돌아간다.
