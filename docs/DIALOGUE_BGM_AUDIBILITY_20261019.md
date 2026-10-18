# 대화 BGM 음량 수정 — 2026-10-19

- 기준 feature/stage10-astra `244b27d565c24c5743ab1cf6f9a0e948026f35e3`, main 조회 `6f22053f462e1176ec2ecde131d589d5491791b2`. 시작 clean, main 병합 없음.
- 기존 경로와 StageIntroCutscene→GameAudio 연결은 존재했다. 문제로 확인한 설정은 dialogue player=-20dB, lobby player=-3dB의 17dB 상대차다. 기본 사용자 BGM bus=-27dB이 추가되어 도입부 약-20dBFS RMS의 원본은 출력에서 약-67dBFS RMS가 된다. 이는 연결 실패와 달리 재생 중이어도 매우 작게 들릴 수 있다. 특정 사용자 기기의 뮤트/스피커 상태까지 재현한 것은 아니다.
- Catalog에 `DIALOGUE_BGM_LOBBY_OFFSET_DB=-5.0`을 선언하고 dialogue gain을 `FRONTEND_DB["lobby"] + offset`으로 계산한다. 현재 player=-8dB, 기존보다+12dB이다. 로비 gain이 바뀌어도 상대차를 유지하며 runtime/스테이지별 분기는 추가하지 않았다.
- 기존 WAV/대사/진입·전환 순서·0초 시작1회/페이지 재시작 없음/무루프/종료1초페이드·사용자 음량/뮤트·소유권 정책은 그대로다. GameAudio/UI/Hero/Battle 스크립트와 project 설정은 수정하지 않았다.

## 검증

- Godot4.5.1 headless 실제 GameAudio/StageIntroCutscene·10스테이지 데이터·실제 WAV/로비 OGG 기존51검사 PASS.
- 추가 실제 Master bus AudioEffectCapture **7검사 PASS**. 기본 사용자 설정에서 같은 원본 도입부의 구 설정 -20dB와 수정 Catalog gain을 비교했다. before RMS **0.00042713**, after **0.00187073**, 약**+12.83dB**. 설정 gain 차이는+12dB이며 capture 시점/프레임 창의 내용 차이가 포함된 단기 측정이다. 사용자 bus gain 보존 및 BGM mute 시 실제 출력 RMS **0** 확인.
- 합계58검사, import/최종 실행 ERROR/WARNING0. Python compile 및 git diff --check PASS. 원본 WAV SHA256 `f8e946b90fae862a1d7085ce51a0565dde032c08741f4f3ba941524ca4900cd8` 유지.
- 격리 fixture는 SFX bank/몬스터 catalog/프로필/스킨/워밍업/그림·테마 대체물을 사용한다. 실제 스피커/헤드폰 청취·전체 게임 화면·Android 실기 믹스는 미검증이다. 실제 기본 출력이 매우 작았다는 원인을 수정한 것이며 모든 기기의 무음 원인을 확정한 보고는 아니다.

```sh
python tools/build_dialogue_bgm_fixture.py /tmp/dialogue-bgm-fix
godot --headless --path /tmp/dialogue-bgm-fix --editor --import
godot --headless --path /tmp/dialogue-bgm-fix --script res://tests/dialogue_bgm_smoke.gd
godot --headless --path /tmp/dialogue-bgm-fix --script res://tests/dialogue_bgm_mix_smoke.gd
```
