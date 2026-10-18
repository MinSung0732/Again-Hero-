# 용사·마왕 대화 BGM

> 아래 -20dB는 최초 구현 이력이다. 현재 음량 수정은 [2026-10-19 보고서](DIALOGUE_BGM_AUDIBILITY_20261019.md)를 따른다.

- 기준: `feature/stage10-astra`의 `b9f8743baf637a76384d02b9a60116b30bb9543e`; main `10c9805842d745412ffe9b45e822896001ef27cb`. 기존 업로드 WAV를 그대로 연결했다.
- 음원: `assets/audio/bgm/talk_background.wav`, 사용자 제공 「용사, 또 너야_.wav」와 동일. 184.48초 / 48kHz / stereo / PCM16. SHA256 `f8e946b90fae862a1d7085ce51a0565dde032c08741f4f3ba941524ca4900cd8`. 음원 변환·루프 구간·normalize·trim 없음. Godot WAV import는 기존 BGM과 같은 QOA 압축이며 loop disabled.
- `game_audio_catalog.gd`의 `DIALOGUE_BGM`에 경로·초기 플레이어 음량 -20dB·종료 페이드 1초를 일원화했다. 기존 로비 플레이어는 -3dB이므로 초기 설정은 로비보다 플레이어 gain 17dB 낮다. 요청의 -20dB 시작값을 우선한 보수적 설정이며, 4~7dB 상대차/최종 청감 조정은 실제 플레이에서 결정해야 한다. 사용자 BGM bus 음량·음소거는 그대로 유지한다.
- `GameAudio`의 기존 BGM 플레이어를 재사용한다. 최초 대화 요청 시 WAV를 캐시하고 loop disabled 복제본을 0초에서 재생한다. 같은 소유자의 컷신 중에는 재요청/페이지 변경/곡의 자연 종료 뒤에도 재시작하지 않는다. 다음 컷신은 다시 0초에서 시작한다.
- 모든 1~10스테이지가 쓰는 `StageIntroCutscene.play_dialogue`에서 재생하고, 정상 종료·스킵·트리 이탈에서 소유자 확인 후 1초 페이드한다. 페이드 때문에 `finished`나 진행을 기다리지 않는다. 대사·이벤트·카메라·연출 시간은 변경하지 않았다.
- 다음 음악이 시작되면 이전 페이드를 취소하고, 이전 컷신의 정리 요청은 새 음악에 적용하지 않는다. 로비/결과 화면은 원래 루프 스트림을 복구한다. 일시정지·백그라운드는 기존 GameAudio 정책을 따른다. 새로운 `_process`나 페이지별 플레이어 생성 없음.

## 검증

Godot 4.5.1 headless, 실제 `GameAudio`/`StageIntroCutscene`·1~10스테이지 대사 데이터·실제 WAV/로비 OGG로 51검사 PASS. import 및 최종 실행 ERROR/WARNING 없음, `git diff --check` 통과. 플레이어 재사용, 자연 종료 후 중복 호출, 페이지별 재시작 방지, 정상 종료/스킵/트리 이탈, 중간 페이드와 1초 후 정지, 이전 페이드 취소, 로비 복구, 일시정지·백그라운드·음소거 보존을 확인했다.

격리 fixture의 SFX bank/몬스터 catalog/프로필/스킨/워밍업과 그림·테마만 대역이다. 실기 Android·전체 씬·스피커/헤드폰 청감·대사/SFX와의 실제 믹스는 미검증이다. 실제 음원 볼륨 검출은 유효성 확인이며 청취 검증이 아니다.

```bash
python tools/build_dialogue_bgm_fixture.py /tmp/again-hero-dialogue-bgm
GODOT --headless --path /tmp/again-hero-dialogue-bgm --editor --import --quit
GODOT --headless --path /tmp/again-hero-dialogue-bgm --script res://tests/dialogue_bgm_smoke.gd
```
