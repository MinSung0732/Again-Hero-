# 만티코어 Pixabay 효과음 출처 / 조정 기록

2026-10-10: Pixabay 공개 다운로드 5개 원본에서 오프라인 컷/레이어 믹스. 원본은 임시 작업 폴더에서만 사용하고 게임에는 44.1kHz mono PCM16 WAV 12개를 포함한다. 런타임 네트워크/Base64 디코딩/파형 합성 없음.

라이선스: https://pixabay.com/service/license-summary/ (프로젝트 내 가공 효과음으로 사용; 원본 독립 판매/배포용 라이브러리 아님). 다운로드 URL, 원본 SHA256, 컷 구간/믹스 비율은 manifest.json에 기록.

| 원본 | 제작자 | 출처 |
|---|---|---|
| Lion Snarl Growl | SoundZee | https://pixabay.com/sound-effects/nature-lion-snarl-growl-354324/ |
| acid_spell_cast_bubble_poison_03 | ldc96 | https://pixabay.com/sound-effects/film-special-effects-acid-spell-cast-bubble-poison-03-286746/ |
| Scorpion Claw Attack (4) | Yodguard | https://pixabay.com/sound-effects/film-special-effects-scorpion-claw-attack-4-482507/ |
| Earth Spell Impact 2 | DRAGON-STUDIO | https://pixabay.com/sound-effects/film-special-effects-earth-spell-impact-2-393922/ |
| Fireball Whoosh 1 | floraphonic | https://pixabay.com/sound-effects/film-special-effects-fireball-whoosh-1-179125/ |

## 연결 의도

| 동작 | 소리 및 타이밍 |
|---|---|
| 사냥 | 1초 집중 진입에 짧은 사자 으르렁, 유도 돌진 시작에 분출형 휙 소리 |
| 2/3연격 | 실제 수락된 공격마다 115ms 발톱 충격; 120ms 연격 간격 전에 꼬리 종료 |
| 추적 / 생존 후퇴 | 짧고 작은 휙 소리 / 으르렁+분출; 실패 공격은 타격 소리 없음 |
| 재앙의 불꽃 | 머리 생성에 짐승+화염; 실제 화염 접촉 중에만 0.65초마다 분출; 두 머리·다수 대상 공유 |
| 맹독유성 | 탄환 생성에 작은 독 응축, 실제 목표점 도달에 독+낮은 바위충격; 배치 발사/착탄 공유 제한 |
| 지각분쇄 | 실제 파동 발사 한 번에 지면 분쇄; 개별 기둥/피해 틱은 무음 |
| 소환·뽑기 | 사자+독+지면 충격 공개음. 전투 컷인 0.55초 집중/1.95초 폭발, 뽑기 1.4초 집중/2.2초 공개 |
| 사망 | 기존 전투/컷인 소리 정지 흐름 유지, 짧은 사자 쇠퇴음 |

## 음량 / 성능

각 파일 피크 −6 dBFS. 짧은 4ms 진입 페이드, 최대70ms 종료 페이드로 컷 클릭 방지. 원래 음정 유지, 하드 클리핑/과도한 압축/런타임 랜덤 피치 없음. 전투 은행은 기존 슬로우모션 시계에 맞추고 컷인은 실제 시간 사용. SFX 버스/사용자 볼륨/음소거 준수. 고정12 음성 생성 후 재사용; 공용 스트림 캐시/각 큐 max_polyphony=1, 유성·불꽃 큐 재생 간격 제한. 지속 화상/독/출혈 피해는 추가 효과음 없음.

측정은 샘플 피크/RMS와 가장 조밀한 유성·불꽃 믹스 및 기존 Godot 이벤트 호출 검사 기준. 실제 스피커/헤드폰 청취·모바일 청감은 수행하지 않았으므로 최종 청감은 확인 필요.
