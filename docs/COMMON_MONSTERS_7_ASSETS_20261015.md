# 일반 몬스터 후보7종 — 에셋 전용 2026-10-15

기존 등록 일반등급16종에 추가할7종을 제작했다. 준비된 종류는 총23종이지만 **이번 작업은 에셋만 추가**했으므로 실제게임의 등록 일반등급은16종 그대로다. 전투수치/스킬/특수증강/소환/뽑기/컬렉션/도감/승률은 바꾸지 않았다.

| 이름 | 폴더ID | 기준 본체높이 |
|---|---|---:|
| 동굴개미 | `cave_ant` | `24px` |
| 밤가시고슴도치 | `thorn_hedgehog` | `28px` |
| 포자버섯 | `spore_mushroom` | `32px` |
| 돌껍질소라게 | `shell_crab` | `28px` |
| 늪지두꺼비 | `swamp_toad` | `24px` |
| 누더기허수아비 | `rag_scarecrow` | `34px` |
| 녹슨태엽병 | `rust_automaton` | `34px` |

일반 `assets/art/monsters/<id>/`, 엘리트 `assets/art/elitemonster/<id>/`로 정리했다. 각 폼마다 원본PNG·정규화시트·개별23프레임·manifest·Godot SpriteFrames/프리뷰씬·README를 제공한다. 일반/엘리트 총14폼,분리322장. 초상화/스탯/게임등록은 포함하지 않는다. ZIP중복본은 저장소에 넣지 않았다.

## 확인

![대표 동작](art/common_monsters_7/overview.png)

[23프레임 동작 미리보기](art/common_monsters_7/animations.gif). 문서프리뷰는 배경/영문라벨이있는합성확인용이며,실제시트/프레임은배경·라벨없는투명PNG다. Godot에서는 각폴더 `*_preview.tscn`의 AnimatedSprite2D animation을 선택한다. 이번 환경에서 Godot실행검사는 하지 않았다.

## 원본 해상도 보존 재정리

초기 24~34px 축소본은 명암·선 디테일이 손실되어 폐기하고, 생성 원본의 실제 픽셀 크기로 재분리했다. 원본PNG는 변경하지 않았다. 전체14폼/322프레임을 배율1.0으로 보존하며 셀만 동작 최대크기에 맞춰 넓힌다. 동일폼의23프레임은 공통셀·몸통중심X·발끝Y를 사용한다. 폼마다 셀크기는 다르며 정확한 값은 각 manifest에 있다. 시트는6열5행, idle4/move6/attack6/hit3/death4다.

RGB 검정 제거 없이 알파128 이진화 정책은 유지한다. 따라서 보존 검증은 원본의 알파128이상인 픽셀의 RGB/불투명도 기준이다. 원본 반투명 경계까지 그대로 복사했다는 의미는 아니다. 투명골 또는2D연결영역 분리로 이웃프레임을 제외한다. 프레임을 줄였다가 재확대하는 과정은 없다. Godot 미리보기만 노드 표시배율로 기존 체급을 유지한다. 런타임의 실제 체급·HP바·그림자는 이번 작업에 연결하지 않았다.

프롬프트는 COMMON_MONSTER_ART_SOURCES_20261015.json과 각 manifest에 유지한다. 재정리/감사는 아래와 같다.

```bash
python tools/package_common_monster_art.py docs/COMMON_MONSTER_ART_SOURCES_20261015.json
python tools/audit_common_monster_art.py
```

정적2213검사PASS: 원본14장SHA,322프레임의원본유지픽셀1:1일치,RGBA/알파0·255,공통셀/축/여백,빈셀투명,시트-프레임완전일치,중복없음,manifest/FPS/loop/SpriteFrames/pivot. 대표일반·엘리트 대기/공격 이미지도확인. diff검사PASS. Godot실제재생/GPU/모바일·루프체감·메모리사용량은미검증. 원본해상도복원으로시트/텍스처메모리는이전축소본보다증가하므로실게임연결시별도검토한다.
