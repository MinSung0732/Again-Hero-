# 용사 승리·패배 결과창 — 2026-10-14

사용자114822시안의제목·실제전투기록·무기아이콘·획득보상·다음도전/재도전/로비구조를반영한다. 승리금색/패배붉은제목, 기존frame_06 금색/보라픽셀스킨과고유무기아이콘을재사용한다. 시안07분49초/7066/Lv40/+100/+60을상수로넣지않고실제run_metrics/hero/player_weapons/award_run으로표시한다. 전투수치·보상예산은변경하지않는다.

본문은스크롤·행동버튼은고정,짧은가로화면은재도전/로비를한줄로배치한다. 숫자와rank는AUTOWRAP_OFF로최소폭보호. 다음스테이지버튼은 finished_won 및 STORE.can_enter를모두통과해야표시한다. 마지막스테이지는次stage없음으로숨긴다. 저장실패일때는재시도만제공한다.

기존 _show_result는settled=true뒤화면을다시그리면로컬reward를0으로초기화했다. result_reward를캐시해한번성공한실제보상을유지하고award_run을재호출하지않는다. 입장serial중복지급방지는기존STORE와SCOPE트랜잭션그대로유지한다. 종료시paused=false로바꾸고backdrop을결과창에유지해ESC가일시정지재개를호출하지않게한다.

검증: build_hero_result_fixture.py/hero_result_smoke.gd109: 승리·패배×1080×1920/540×960/1920×1080/960×540, 실패→성공→재그림단회정산/실보상보존,6무기/MAX,마지막stage,scroll/버튼경계,실마우스/합성터치. _show_result와_clear_overlay는실제production을추출하며전투/award host는mock이다. build_mode_progression_fixture.py/mode_progression_smoke.gd87은실제저장·해금stores회귀. 총196 headless격리PASS. 실제전체게임GPU/Android미검증.

## 이펙트 확인 경로

`assets/art/effects/hero_weapon_v2/<weapon_id>/sprite_sheet.png`: 분리정규화된시트.
`frames/effect_01.png`~`effect_08.png`: 실제인게임프레임.
`manifest.json`: crop/공통중심등메타데이터.
Git에는91시트/728프레임이있으며100무기전체새생성이아니라공유90종+실린더스트라이크1종을생성했다. 일부원본네이티브연출은유지한다. 40개새인벤토리아이콘atlas는`assets/art/UI/hero_augments/weapons_unique_v2.png`. 상세연결/보존정책은HERO_WEAPON_ART_20261014.md와HERO_WEAPON_ART_AUDIT_20261014.json에있다. feature/stage10-astra 최신브랜치를확인해야하며main에자동병합하지않는다.
