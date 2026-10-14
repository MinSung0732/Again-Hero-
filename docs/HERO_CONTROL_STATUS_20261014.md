# 용사 행동제어 표시와 해금 — 2026-10-14

공포/기절/매혹은 Hero의물리행동처리에서조기반환한다. 따라서용사모드무기런타임의tick/queue_redraw가호출되지않고, Hero의CanvasItem에캐시된로컬draw명령이Hero움직임을따라갔다. 이제해당경로에서도발사완료공격/장판/이펙트/보호막수명은tick(delta,false)로진행하며신규캐스팅과identity.tick은차단한다. 발동위치형은기존월드좌표를그리기직전에로컬로변환하고, 의도된추종형은원래설계를유지한다. 일반tick후채널링에들어간경우에도한프레임두번갱신하지않는다. 마왕AI에는이경로를적용하지않는다.

고정5슬롯Gauge는공포/기절/속박또는둔화/석화/매혹의실제수신타이머를읽는다. 타이머최초/갱신시의실제남은시간을분모로흰색6px게이지와소수1자리초표시를그린다. 동시에받으면24px간격으로별도행을쌓으며기존자원/HP/보호막보다위에배치한다. 상태저항후타이머를읽으며정화/만료로0이면숨긴다. 매프레임배열/노드생성/그룹스캔없음. 속박은기존apply_slow(0.01)형태를root_like_slow메타데이터로구분한다. 상태판정/저항/피해/기술수치는미변경.

| 대상 | 조건 |
|---|---|
| 용사 모드 입장 | 마왕 모드 쉬움3클리어 |
| 각 용사 선택 | 용사모드입장해금 + 해당용사의마왕쉬움스테이지클리어 |
| 랭킹 | 마왕쉬움10 + 용사쉬움10클리어 |
| 용사 어려움 | 해당용사전장쉬움클리어(기존) |

캐릭터소유플래그/어려움클리어/단계열람은쉬움클리어의대용이아니다. 기존기록/투자/테스트계정예외를보존하고새저장필드는추가하지않는다. 전장가용성은기존모드입장기준이며이패치는캐릭터선택조건을별도로복구한다.

검증: Godot4.7.2 headless 상태31(실제무기런타임의발동위치/투사체진행/효과만료/새캐스트차단, production물리wrapper조기반환/정상·채널중복tick, gauge실제draw함수호출spy의색/폭/동시행/재적용), 아트1359, 무기2193, 해금87(실제guest저장/쉬움2vs3/개별캐릭터/랭킹/어려움/보상실패·중복/계정분리) PASS. 총3670. 전체Hero/몬스터네이티브씬/실제GPU·Android·실전공포회피는미검증.

재현:

```bash
python tools/build_hero_control_fixture.py /tmp/hero-control
godot --headless --path /tmp/hero-control --editor --import --quit
godot --headless --path /tmp/hero-control --script res://tests/hero_control_status_smoke.gd
godot --headless --path /tmp/hero-control --script res://tests/hero_weapon_art_smoke.gd
godot --headless --path /tmp/hero-control --script res://tests/hero_weapon_extension_smoke.gd
python tools/build_mode_progression_fixture.py /tmp/hero-control-unlocks
godot --headless --path /tmp/hero-control-unlocks --editor --import --quit
godot --headless --path /tmp/hero-control-unlocks --script res://tests/mode_progression_smoke.gd
```

검증기준원격5045972. 커밋revert로롤백하며main병합은명시요청시수행한다.
