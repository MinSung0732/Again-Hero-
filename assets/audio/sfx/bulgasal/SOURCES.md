# 불가살 전투 / 대마법사 연소 방출 효과음

2026-10-09 Pixabay 원본 상세 페이지와 [Content License](https://pixabay.com/service/license-summary/) 확인. 편집한 녹음을 게임에 통합한다. 원본 MP3는 배포하지 않는다. 제목·제작자·콘텐츠ID·원본/편집 SHA256과 정확한 필터/피크/RMS는 manifest.json.

| 원본 | 제작자 / ID | 연결한 동작 |
| --- | --- | --- |
| [Rock Break Hard](https://pixabay.com/sound-effects/film-special-effects-rock-break-hard-184891/) | LordSonny /184891 | 큰 바위 폭발, 낮고 짧게 편집한 기둥 파괴·섭취 |
| [Heavy Rock Rolling](https://pixabay.com/sound-effects/film-special-effects-heavy-rock-rolling-515254/) | DRAGON-STUDIO /515254 | 지하 바위돌진 진입, 짧은 자갈 굴림으로 지상 복귀 |
| [Boulder Impact](https://pixabay.com/sound-effects/horror-boulder-impact-487673/) | DRAGON-STUDIO /487673 | 등장 낙하와 강철도약의 무거운 지면 착지 |
| [Fire Spell Impact](https://pixabay.com/sound-effects/film-special-effects-fire-spell-impact-393921/) | DRAGON-STUDIO /393921 | 대마법사 연소 설치 이후 불꽃 방출 |

동작을 재질로 구분: 바위가 깨지는 폭발·바위가 구르는 돌진·무게가 내려앉는 착지를 서로 다른 녹음으로 연결한다. 기둥은 바위 파괴 소스의 작은 자갈 부분을 고역/저역 조정하고 낮은 게인으로 사용한다. 조각별 소리8회, 일반몹·불가살의 반복 피격/걷기음은 추가하지 않는다. 정신집중은 기존 원형 표시로 전달하고 소리로 반복 예열하지 않는다.

모노44100Hz/PCM16, 고역 완화·완만한 압축·시작/끝 fade·피크-6dBFS, Godot WAV import compress/mode=0(무손실), normalize=false. 고정 EventSfxBank로 SFX 버스에 연결하고 BGM 설정과 분리. 바위-10dB, 돌진-14dB, 복귀-14dB, 착지-9dB, 기둥-19dB/0.25초 제한, 섭취-20dB/0.4초 제한. 연소 방출-12dB/피치1.0. 기존 파일은 출처 이력을 보존하며 런타임 참조만 새 파일로 바꾼다.

Godot 실제 연소 charge→release 호출 및 동시 믹스 출력 측정: peak0.354640(클리핑1.0보다 낮음). 기존 방출 WAV 측정 peak-1.349dBFS/RMS-12.458dBFS; 새 파일 peak-6/RMS-18.973dBFS로 여유를 확보. 원래 파일에 full-scale 샘플은0개이므로 왜 거칠게 들렸는지 원인 단정은 하지 않는다. 재질/구간과 출력 수치를 검증했으며, 실제 사람 청취·Android 스피커 청감은 미검증이다.

## 뽑기 / 전투 소환 컷신 연결 (2026-10-09)
기존 출처·편집본을 그대로 재사용: Heavy Rock Rolling의 `burrow.wav`(-18dB)로 예열하고 Rock Break Hard의 `rock.wav`(-12dB)로 공개 충격을 강조한다. 뽑기1.75초 예열→2.3초 파편 공개, 전투 소환0.25초 예열→1.8초 눈뜨기. 충격 때 예열음을 끊고 정상 종료/스킵/중단에 고정 플레이어를 정리한다. 컷신 음색은 실제 시간/피치1.0, 기존 실제 낙하 착지 `land.wav`(-9dB)는 느려진 전투 시계대로 유지한다. 기존 보상/확률/피해/착지 타이밍 변경 없음.
