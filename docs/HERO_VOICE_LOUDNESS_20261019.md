# 용사 음성 음량 균일화 — 2026-10-19

- 기준 feature/stage10-astra `660be6900be47e33ca3f3a0caa16a152173e42b4`, main 조회 `6f22053f462e1176ec2ecde131d589d5491791b2`. 시작 clean. main 병합 없음.
- 사용자가 올린 진입/용사승리/용사패배30개와 해금3개, 총33개 WAV를 같은 기준으로 보정했다. 신규 음원/대사 생성·런타임 Base64/AGC는 없다.

| 지표 | 수정 전 | 수정 후 |
| --- | ---: | ---: |
| 파일별 integrated loudness 범위 | -31.31~-11.67LUFS | -18.10~-17.98LUFS |
| 가장 큰/작은 파일의 차이 | 19.64LU | 0.12LU |
| 전체 파일 중 최대 true peak | +3.16dBTP | -2.31dBTP |

- 공통 목표=-18LUFS, 허용오차±0.1LU, 출력 true peak ceiling=-1.5dBTP. peak limiter ceiling=-2.5dB,4배 oversampling,attack5ms/release50ms. 모두 `tools/audio/hero_voice_loudness_policy.json`의 빌드용 데이터다. 용사/이벤트별 if·임의 runtime gain 표는 추가하지 않았다.
- `tools/normalize_hero_voices.py`가 WAV를 자동 조사하고 FFmpeg의 loudnorm 분석으로 integrated LUFS/true peak를 측정한다. 측정 gain+oversampled lookahead limiter로 오프라인 렌더하고, 출력 LUFS를 측정해 필요할 때 원본에서 gain만 재조정한다(최대6회). 실제 적용된 입력 gain/회수/전후 측정값/원본·결과 SHA256은 JSON에 기록했다. limiter는 높은 순간 피크를 제한하므로 해당 부분의 강약은 변할 수 있다.
- 전체33개가 LUFS·피크·포맷 검사를 통과한 후 원본 경로에 결과를 기록했다. 24kHz/mono/PCM16과 파일별 샘플 수가 모두 같다. lookahead latency를 보상하며 trim·무음 제거·속도/피치 변경을 하지 않았다. 원본은 위 기준 커밋의 동일 경로에서 복원 가능하다.
- runtime Catalog/AudioStreamPlayer의 기존 공통 -2dB·SFX 설정·duck·전투/컷신 이벤트·캐시/풀은 그대로다. 추가 실시간 분석·로드·스캔·개별 보정 분기나 프레임 부하는 없다.

## 검증

- FFmpeg 실제 파일 분석/결과 hash33개와 기준 git blob hash33개 비교, 출력 전후 포맷·샘플 수 일치, 목표 LUFS/true peak 한도33개 통과. 측정은 원본/출력 PCM 파일 기준이며 사람의 청취 검사와 구분한다.
- Godot4.5.1 headless: 보정된33개 실제 WAV import/길이/loop/AudioStreamPlayer 재생 및 기존 이벤트/중복/우선순위/슬로우/pause/뮤트/실제 UI 후크 격리 **161검사 PASS**, 최종 import/실행 ERROR/WARNING0. Python compile·git diff --check PASS.
- 기존 fixture의 artwork/font·warmup·일부 Battle 의존성은 대체물이다. 실제 스피커/헤드폰 청감·전체전투·모바일/GPU/FPS는 미검증이다. 측정 loudness를 맞춘 것이며 캐릭터의 음색/연기 차이까지 없애는 작업은 아니다.

```sh
# 측정만 수행한다. 기존 결과 보고서는 덮어쓰지 않도록 별도 경로를 쓴다.
python tools/normalize_hero_voices.py assets/audio/sfx/hero_voices --report /tmp/hero-voice-check.json
# 새 원본 음성이 추가되었을 때 공통 정책으로 적용하려면 --apply를 지정한다.
python tools/build_hero_voice_fixture.py /tmp/hero-voice-normalized
godot --headless --path /tmp/hero-voice-normalized --editor --import
godot --headless --path /tmp/hero-voice-normalized
```

정책을 다시 조정할 때는 최초 원본 버전에서 렌더해 반복 limiter 처리를 피한다. 새 음원 추가 후에도 원본을 먼저 커밋하고 동일 도구로 측정/보정하면 된다.
