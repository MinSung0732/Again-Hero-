# 제우스 Godot 리깅 시안

F6: `src/dev/ZeusRigPreview.tscn`. 5초 동작 +0.7초 유지 후 반복, Space 일시정지. 기존 뽑기 컷신과 독립된 검토 씬이며 확률·재화·저장·보상을 호출하지 않는다.

## 실제 구현과 범위
- Skeleton2D / Bone2D8개, Polygon2D8개, AnimationPlayer cubic 보간으로 연속 동작. 이미지 교체/키포즈 crossfade 없음.
- 기존768×1280 idle_01.png를 수정 없이 모든 파츠에서 공유. Body/Head/CastArm/StaffArm/HairLeft/HairRight/ClothLeft/ClothRight는 독립 PNG가 아닌 **원본 UV 메시 영역**이다. 24×40 격자1025정점·1920삼각형, 동일 경계 정점/가중치를 공유해 연결을 유지한다.
- 현재는 합쳐진 일러스트의 작은 메시 변형 리깅 시안이다. 가려진 몸통을 재작화한 독립 PNG 파츠/레이어 모델이 아니며, 큰 팔 회전·몸통 방향 전환·가림 순서 교체를 지원하지 않는다. 이 범위를 위해 움직임을 작게 제한했다. 원본 독립 파츠가 확보되면 각 mesh.texture/UV/가중치/피벗을 교체하는 구조로 확장한다.
- 머리/팔/지팡이 힘 모으기→방출→반동→정착 곡선을 데이터로 설정. 머리·옷은 지연 반동. 루트와 발 영역은 고정, 전체 이미지 확대/축소·슬라이드쇼 없음. nearest·anti_alias=false.
- SpellOrigin Marker2D는 StaffArm Bone2D 아래에 붙인다. 보석 부근 전기 수렴과 방출 번개가 동일한 마커 위치에서 시작하므로 지팡이와 이펙트가 함께 움직인다.
- 메시/텍스처/가중치/애니메이션은 초기화 때1회 생성. 재생 중에는 seek와 redraw, 고정 개수 즉시 효과 그리기만 수행하며 매 프레임 파츠 생성/삭제나 배열 재생성 없음. 이것은 전투 핫패스 밖의 개발 미리보기다.

## 검증
Godot4.6 headless tests/zeus_rig_smoke.gd: 정점/삼각형/8파츠/8본·공유 텍스처·가중치 정규화/범위·발 고정·60Hz 연속 회전 변화·보석 마커 추종·끝 원점 복귀. PC OpenGL540×960 실제150프레임 렌더를5초30fps MP4로 인코딩해 전신·지팡이·연결 경계·이름 확인. Android 실기기/모바일 성능은 미검증.

## 다음 완성 단계
원본 스타일 그대로 분리된 앞/뒤 머리·얼굴/눈·팔/손·지팡이·몸통·앞/뒤 옷 PNG와 가려진 부분 재작화가 필요하다. 이를 적용해 관절 부근 겹침, 독립 움직임과 큰 스킬 제스처를 확대한다. 이번 영상은 연속 변형/효과 추종을 확인하는 제한된 리깅 시안이다.

## PNG 번개 강화(v2)
- `src/data/zeus_lightning_catalog.gd`: 시트·셀/발생점/끝점·24fps·방출1.9초·세 방향 목적지. `src/ui/zeus_attached_lightning.gd`는 이를 캐시해 사용한다. 스프라이트는 start(256,48)/end(256,464) 기준이며 가장자리 생성 오차는1px 이내다. 발생점/끝점 간 길이에 맞춰 **균일 확대·회전**하며 가로세로를 따로 늘이지 않는다. 프레임 선택은 전체 연출 시간 기준이며 멈춤/seek/루프에도 동기화한다.
- `assets/art/effects/gatcha/zeus/lightning_v2/`: 1024×1024 2×2 시트와 동일512×512 개별4장, 모두 RGBA 투명 PNG. 생성 원본1254×1254를 정확히2×2 분할하고 nearest로416×416에 맞춘 뒤512캔버스 중앙/상단48px에 배치했다. 새로운 번개 생성은 기본 imagegen 도구를 사용했다. 그림 변경/블러 없이 프레임 분할·리사이즈·투명 여백만 처리했다.
- 최종 프롬프트: “transparent PNG 2×2 four-frame lightning sheet; stable top/bottom center origin/end, white jagged core, cyan inner/deep cobalt outer branching thunder, sharp pixel edges, consecutive varied branches, transparent gutters, no background/characters/text/blur.” 전체 생성 목표는1024×1024였으며 실제 결과를 위 규격으로 정리했다.
- 충전0.3–1.65초 → 방출1.72–2.75초(정점1.9초) → 충격파/입자2–3.2초 → 제우스 이름3.8–4.1초. 섬광은 정점±0.07초, 배경 진동은 정점 이후0.35초만 적용. 캐릭터에는 화면 진동을 적용하지 않는다. 후광은 캐릭터 뒤, 번개/입자는 앞, 이름은 마지막 계층이다.
- 검증 실행: `godot --headless --path . --script tests/zeus_lightning_smoke.gd`, 기존 `tests/zeus_rig_smoke.gd`. 테스트는 RNG/재화/보상 저장 없이 실제미리보기4비율·301시점·발생점/캐시/셀 여백을 확인한다. PC OpenGL540×960 실제5초 영상 검수 완료; 모바일 실기기/성능 미검증. 기존 뽑기 적용은 시안 승인 후 연결하며 현재도 F6 ZeusRigPreview에서 확인한다.

## 실루엣 등장(v3)
- 첫0.4초 캐릭터를 숨긴 후0.4–0.85초 어두운 실루엣으로 등장.1.35초까지 색상을 공개하지 않고 기다린 뒤1.35–2.45초 원본UV의 위에서 아래로 본모습을 공개한다.1.9초 기존 PNG 방출과 겹치며 전체5초·전신 구도·연속 동작 유지.
- `zeus_silhouette_reveal.gdshader`와 공유 ShaderMaterial1개를8개 메시가 사용한다. PNG 원본/alpha를 유지하고 공개 경계의 색만 바꾸므로 경계 연결과 원본 색상이 유지된다. 초기화와set_time 모두 동일 함수로 alpha/공개 위치/이름을 갱신해 루프 또는 역방향seek에서도 앞선 상태가 남지 않는다. 새 이미지/재추첨/보상 지급 경로 없음.
- 하단 이름은3.55–3.9초 등장, stage36px·외곽선3px·그림자·배경 음영. 이름 시작Y850은 발바닥Y800보다 아래이며 화면 비율에 따라 공통contain 배치된다. 테스트에서4비율 영역 포함/발 여백/재질 공유/공개 단조 진행/숨김 대기/완전 공개/루프 초기화 확인. Godot PC 실제 렌더로 실루엣/중간 공개/번개/최종 이름 확인; 모바일 실기기는 미검증.
