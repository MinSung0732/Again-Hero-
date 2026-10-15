# 엘리트 미믹

일반 미믹의 상자·이빨·혀 실루엣을 유지하고 보라색 목재, 금색 뿔·보강재, 루비 자물쇠로 구분한 신규 이미지 생성 에셋.

- `mimic_elite_source.png`: 생성 원본(1374×1145). 원본은 균일 그리드가 아니므로 직접 등분하지 않는다.
- `mimic_elite_spritesheet.png`: 정렬된 6열×5행 시트(576×360).
- `frames/`: 투명 PNG 23장, 모두 96×72. 실제 몸체 약32×32, 중심X48/발Y60. 사망은 같은 기준에서 주저앉는 동작.
- `manifest.json`: 동작별 FPS/루프/프레임 목록, 원본 분리 좌표, 축, 생성 프롬프트, 알파 처리 기록.
- `mimic_elite_animations.tres`: 실제 개별 PNG를 명시 참조하는 Godot SpriteFrames. 파일 내보내기에 안전한 리소스 연결.
- `MimicElitePreview.tscn`: Godot에서 열어 각 애니메이션을 확인하는 미리보기 노드. 충돌·공격·스탯 없는 아트 전용 씬.

| 모션 | 프레임 | FPS | 반복 |
|---|---:|---:|---|
| idle | 4 | 6 | O |
| move | 6 | 10 | O |
| attack | 6 | 14 | X |
| hit | 3 | 12 | X |
| death | 4 | 10 | X |

생성은 내장 imagegen 사용. 원본은 보존하고 알파만128기준 이진화한 후 공통 배율 nearest 축소·정렬했다. 검은 입/짙은 목재 RGB로 배경을 제거하지 않는다. 파일명의 move는 프로젝트 MonsterVisual 규격이며 walk에 해당한다.

미믹은 `src/monsters/FrontierMimic.tscn`과 MonsterCatalog에 등록되어 일반 소환·엘리트 전환 모두 연결됐다. 실제 체급·축 값은 `src/data/frontier_monster_catalog.gd`의 mimic normal_visual/elite_visual을 사용한다. 아래는 프레임 목록 예시이며 실제 target_height는 원본 알파 높이에서 정규화한다.

```gdscript
{"mode":"frames", "asset_dir":"res://assets/art/elitemonster/mimic/frames",
 "target_height":144.0, "animations": {
 "idle":{"count":4,"fps":6.0,"loop":true},
 "move":{"count":6,"fps":10.0,"loop":true},
 "attack":{"count":6,"fps":14.0,"loop":false},
 "hit":{"count":3,"fps":12.0,"loop":false},
 "death":{"count":4,"fps":10.0,"loop":false}}}
```
