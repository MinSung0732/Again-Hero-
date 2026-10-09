# 만티코어 뽑기 연출

- `TranscendentCutsceneCatalog`의 `manticore` 항목과 공통 `GachaRevealOverlay`를 사용한다. 5초 실제 시간 연출: 0.3초 실루엣 등장, 0.5초 독기, 1.3~2.6초 위에서 아래로 공개, 2.2초 지면 파열, 3.8~4.3초 이름 표시.
- Live2D **방식**의 Godot 네이티브 `Skeleton2D`/`Polygon2D` 리그다. Cubism SDK/model이 아니다. 저장소의 `manticore_parts_v1.zip`에서 제공된 13개 투명 파츠와 일치하는 정적 재조립 원본을 사용한다. 49×81 공유 메쉬를 7개 가동부 마스크로 가중한다. 꼬리·날개·뒤 머리카락·옷자락의 연속 작은 회전, 원본 얼굴·손·다리 고정. 숨겨진 면이 없는 원본이므로 큰 회전·시점 전환은 하지 않는다.
- 파츠/메쉬/24개 효과 프레임은 뷰 최초 생성 때 준비한다. 프레임 갱신은 7개 bone transform, 기존 Sprite2D 6개, 머티리얼 파라미터만 변경한다. 공통 플레이어의 뷰 캐시·스킵·취소·재사용을 유지한다.
- 독기/파열은 기존 만티코어 effect2/3/4를 재사용. 전투 공격/충돌/피해를 실행하지 않는다. 진동/암석음은 기존 Pixabay 리소스 `bulgasal/burrow.wav`, `rock.wav`를 SFX 버스로 재사용한다. 출처·가공 기록은 `assets/audio/sfx/bulgasal/SOURCES.md`와 `manifest.json`. Base64를 매 프레임 디코딩하지 않는다.
- 배경 `venom_sanctuary.png`는 이번 작업에서 생성한 어두운 보라/금/녹색 폐허 배경이다. 캐릭터 원본을 새로 그리지 않았으며 540×960 논리 스테이지에 contain 배치, 전신 실제 alpha bounds 중심 정렬.

## 실행과 범위

`src/dev/manticore_cutscene_preview.tscn`을 F6 실행하면 컷신만/1회/10+1회(만티코어 3개) 미리보기를 선택할 수 있다. 합성 결과이며 보상·재화·저장 API를 호출하지 않는다.

현재 `MonsterCatalog`/뽑기 풀에는 만티코어가 아직 없다. 결과에 `monster_id: manticore`, `rarity: transcendent`가 들어오면 공통 연출로 자동 연결되지만, 이번 작업은 실제 획득 확률이나 전투 수치를 임의로 등록하지 않는다.

검사: `python tests/run_manticore_cutscene_smoke.py --godot <Godot4 실행파일>`.
격리 프로젝트는 실제 UI/카탈로그/원본 리그/효과음과 효과 프레임을 실행한다. ShopCatalog가 preload하는 전투 PackedScene만 빈 노드로 대체하며 이 테스트에서 전투 개체를 생성하지 않는다. 저장·로그인 autoload를 실행하지 않는다.

Godot 4.5.1 헤드리스: 정상 완료/스킵/취소/동일 뷰 재사용, summon/pickup 합성 11개 결과의 순서 및 전체 스킵, 4개 화면 비율, 원점 재설정/가동 bone/가중치 합/메쉬·노드 개수 고정/효과음 로드 검사 통과. 실제 GPU 화면·모바일 청취·성능/export는 미검증.
