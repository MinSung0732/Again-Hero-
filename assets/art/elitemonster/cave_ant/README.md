# 동굴개미 — 엘리트폼

일반 등급 후보의 에셋만 준비했다. MonsterCatalog/배우/소환/가챠/도감에는 아직 등록하지 않았다.

- 원본: `cave_ant_elite_source.png` (생성 원본 그대로 보존)
- 정규화 시트: `cave_ant_elite_spritesheet.png` — RGBA576×400,6열5행
- 개별: `frames/` — 96×80,총23장,몸통 중심X48/발끝 경계Y68
- 순서: idle4/6fps,move6/10fps,attack6/14fps,hit3/12fps,death4/10fps. idle/move만loop.
- `cave_ant_elite_animations.tres`: Godot SpriteFrames. `cave_ant_elite_preview.tscn`을 열어 AnimatedSprite2D animation을 바꿔 확인한다. nearest/공통발pivot/3배미리보기.
- `manifest.json`: 실제프레임순서·원본crop·중심/발좌표·동일배율·소스SHA·생성프롬프트.
- 오른쪽방향. RGB검정제거없음,알파128이진화+nearest만사용. 투명간격 또는2D연결영역으로이웃프레임분리.
- 본체 기준높이 24px. 엘리트도 같은 기준높이로 제작했으며 추후전투체급 배율은 런타임데이터에서 명시한다.

검증: 전체14폼/322프레임 정적1891검사통과. 실제Godot프리뷰재생·GPU·모바일체감검수는미실행.

디자인: Obsidian carapace with copper armored thorax plates, larger ivory mandibles, two short amber crystal spines on abdomen. Same ant anatomy, not a humanoid.
