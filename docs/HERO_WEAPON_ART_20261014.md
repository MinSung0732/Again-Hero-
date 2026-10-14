# 무기 아트 2차 적용 — 2026-10-14

100종 중 고유 아이콘60개를 유지하고 재사용40개를 교체했다. 이펙트는 공유경로90개와 전사연출을 쓰던 실린더스트라이크1개를 무기별로 생성했다. 이미지 생성은 내장 imagegen 도구, 91개 무기별 개별 호출을 사용했다. 검수 중 사람/새 용사 모습이 섞인5개는 동일 도구로 재편집해 추상 이펙트만 남겼다.

- 게임 리소스: `assets/art/effects/hero_weapon_v2/<weapon_id>/`의 `sprite_sheet.png`, `icon.png`, `frames/effect_01.png`~`effect_08.png`, `manifest.json`.
- 실제 추가무기 아이콘: `assets/art/UI/hero_augments/weapons_unique_v2.png`(64×64 타일40개). 기본무기 생성시트의 첫셀 아이콘은 번들/검수용이며 기존 고유60아이콘을 덮어쓰지 않는다.
- [100종 경로와 교체 이유](HERO_WEAPON_ART_AUDIT_20261014.json), [정확한 생성·수정 프롬프트](HERO_WEAPON_ART_PROMPTS_20261014.json).

각 애니메이션의 동일 셀/중심/crop/nearest 배율을 고정했다. 반투명 외곽은 기존 알파만 이진화하며 검정색을 투명색으로 키잉하지 않는다. 투사체·궤도유닛·지속장판은8프레임을12fps왕복(0→7→1→0)으로 재생해 끝점 단절을 줄인다. 단발은 기존0.28초 시각창 안에서8프레임을 순서대로 재생한다. 색상은 냉기/독/혈액 이름과 일치하도록 조정했다.

네이티브 관통포·운석·얼음 기둥·소멸4개는 실제로 서로 다른 원본배우/연출을 사용하므로 유지했다. 원소 평타/아스트라3타 등 원본기술의 속성·관통·자원·오디오는 보존한다. 해당2기본무기의 생성프레임은 보조증강에 따른 추가범용투사체에서도 사용되며 원본6원소/3타의 기본배우 그래픽을 단순그림으로 대체하지 않는다. 도적기본연격은 원본판정·포즈를 유지하고 표적에 새컷효과를 표시한다. 이계소환은 원래소환수/3개제한을 유지하며 성공시에만 고유문양을 띄운다.

## 검증

`python tools/check_hero_weapon_art.py`는91종/728프레임·시트와개별PNG픽셀일치·RGBA/알파·여백·중복·수치전후검사. `python tools/build_hero_weapon_art_fixture.py <저장소밖의폴더>` 다음 Godot `--headless --path <폴더> --editor --import --quit`, `--script res://tests/hero_weapon_art_smoke.gd`, `--script res://tests/hero_weapon_extension_smoke.gd`로 재현한다.

신규1359 + 무기2193 =3552검사 PASS. 100아이콘 고유·무기별8프레임캐시·선/회전/콤보/투사체실제texture dispatch·왕복루프·고정풀·소환성공/실패 가드 검사. ART dispatch는 production draw함수를 추출해 GPU호출만 기록한다. 원본몬스터/네이티브배우의 전체물리전투·GPU장면·모바일FPS/터치·15분실전밸런스는 실행하지 않았다.

각 PNG는 선택한 키트만 로딩에서 준비하고 고정풀에서 참조한다. 전체91종 원본시트를 전투에서 동시에 로드하지 않는다. 새 콘텐츠 값은 Catalog에서 관리하며, 전투 수치·레벨·진화·자원·슬롯은 변경하지 않았다. 모든100종카탈로그의 visual metadata를 제외한 필드는 기준커밋ba50ad8과 동일하다.

## 복구 재검수와 분리 보정

원격 `acb9b73`에 전체 생성·인게임 연결이 완료된 상태였으며 원본91장도 이전 작업 폴더에서 확인했다. 하지만 원본을 직접 검사한 결과 5종14셀은 명목 격자 경계에 닿아 있었다. 최종 정규화 후8px 여백만 검사하면 원본 잘림을 놓칠 수 있다.

붕괴 문양, 정화, 결사의 참수검, 심판 낙인, 안식의 마도서의 수정본은 각 무기 폴더의 `source.png`에 보존했다. 알파0/255 변환 후 연결성분 전체를 하나의 프레임에 배정하므로 명목 격자선을 넘는 성분을 잘라 넣지 않는다. 검수한 원본 코어/진행축 좌표를 공통(64,64)에 배치하고 프레임 전체에 같은nearest배율을 적용한다. 분리 단계의 원본 불투명픽셀 누락/중복이 없음을 확인했으며, 최종 저해상도 변환은 기존처럼nearest 샘플링한다. 무기 아이콘은 기존 것을 유지했다.

재현: `python tools/repair_hero_weapon_sheet.py docs/HERO_WEAPON_ART_REPAIR_LAYOUT_20261014.json` (오프라인 Pillow/NumPy/SciPy 필요). 수정5종의 manifest에는 source SHA/8개anchor/전체성분bounds/공통extent/분리픽셀수를 기록한다. `prepare_hero_weapon_art.py`는 검수분리본을 보존하며 일반 원본의 경계접촉은 오류로 거부한다. 전체 에셋 정적검사와 Godot 격리3552검사를 수정후 다시 통과했다. 실제GPU/Android/완주밸런스는 실행하지 않았다.

수정 이미지 생성은 내장imagegen을 사용했으며 정확한 프롬프트는 `HERO_WEAPON_ART_REPAIR_PROMPT_20261014.json`에 있다. 인게임 경로는 `assets/art/effects/hero_weapon_v2/<weapon_id>/frames/`를 그대로 사용한다.
