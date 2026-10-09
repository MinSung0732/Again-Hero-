# 슈텐-도지 전용 Pixabay 효과음

2026-10-10: 새 공개 원본7개를 다운로드하여 동작별 컷/필터/레이어 믹스로 제작했다. 이자나미·불가살·만티코어 음원 경로를 사용하지 않는다. 게임에는44.1kHz mono PCM16 WAV12개(약1.14MB)만 포함한다. 원본MP3는 저장소에 배포하지 않는다.

Pixabay Content License: https://pixabay.com/service/license-summary/ . 게임 동작용 가공 소리로 사용하며, 원본 독립 배포/효과음 판매 라이브러리 용도가 아니다. 원본 다운로드 URL/SHA256/제작자/ID, 정확한 컷 구간/레이어 비율/필터/출력SHA256은 manifest.json.

| 원본 | 제작자 | 출처 |
|---|---|---|
| Heavy Chains Dragging | DRAGON-STUDIO | https://pixabay.com/sound-effects/film-special-effects-heavy-chains-dragging-515264/ |
| Dark magic (1) | Yodguard | https://pixabay.com/sound-effects/film-special-effects-dark-magic-1-378650/ |
| Fire Spell Impact | DRAGON-STUDIO | https://pixabay.com/sound-effects/film-special-effects-fire-spell-impact-393921/ |
| Heavy Whoosh 01 | DRAGON-STUDIO | https://pixabay.com/sound-effects/film-special-effects-heavy-whoosh-01-414580/ |
| Metal Whoosh Hit 9 | floraphonic | https://pixabay.com/sound-effects/film-special-effects-metal-whoosh-hit-9-201909/ |
| Gentle Water Bubbling | DRAGON-STUDIO | https://pixabay.com/sound-effects/film-special-effects-gentle-water-bubbling-584723/ |
| Oni Demon Voice - Demonic Laughter | PhatPhrogStudio | https://pixabay.com/sound-effects/horror-oni-demon-voice-demonic-laughter-477923/ |

## 동작 연결

| 동작 | 소리 / 실제 재생 조건 |
|---|---|
| 혈주연무 | 액체 기포+낮은 요기 분출, 시전 시작1회.12/19개 안개 생성·지속 피해 틱에는 추가 재생 없음 |
| 귀염지폭 | 화염 파열+저음 충격, 모든 안개 발화 행동에1회 |
| 쇄혼귀면 발사 | 짧은 사슬 끌림+요기, 실제 사슬 슬롯 생성시1회. 긴 비행 동안 반복하지 않음 |
| 쇄혼귀면 결박 | 사슬 조임+금속 충격, 실제 도달/면역 통과시에만 재생. 둔화/침묵/DOT 틱에는 무음 |
| 기본공격 |300ms 바람·금속 스윙, 실제 수락된 타격에만400ms 둔중한 충격 |
| 귀왕해방 |2600ms 오니 웃음+요기/화염, 최초 부활 진입. 실패/피격마다 반복하지 않음 |
| 해방 후 공격 | 스윙/충격에 전용 화염층 추가, 일반 공격과 구분. 동일 간격/타격 판정 유지 |
| 뽑기/소환 | 전용1500ms 술안개 →2000ms 오니 공개음. 기존 뽑기0.7/2.2초, 전투소환0.45/1.95초 타이밍 유지 |
| 실제 사망 |850ms 요기 쇠퇴+사슬 낙하, 기존 사망 컷인에서 재생하여 본체 제거 후에도 정상 종료 |

## 음량 / 성능 / 검증

각 파일 최대피크−6dBFS,5ms 진입/70ms 레이어 종료/60ms 최종 페이드.65Hz highpass/7.5kHz lowpass로 과도한 저역과 금속 고역을 줄이고 원래 음정을 유지한다. 하드 클리핑/런타임 랜덤피치/네트워크 다운로드/Base64 디코딩/파형 생성 없음. 음량은 전투−13~−20dB, 컷인−13~−18dB; 기존 SFX 설정/버스/음소거/게임 슬로우/일시정지·스킵/취소를 그대로 사용한다.

고정9 전투 음성과 공용 스트림 캐시를 재사용하며 cue별max_polyphony1/반복 제한. 효과마다 새 AudioStreamPlayer를 만들지 않는다. 헤드리스 실제 이벤트/거부타격 무음/면역결박 무음/안개 폭발1음성/해방 별도타격/시계·일시정지 검증. 전큐 최밀도 반복의 AudioEffectCapture 믹스피크0.22842(클리핑경계1.0),36,864샘플 확인. PCM12개 피크/샘플레이트/채널/제로 페이드 끝 검사. 실제 스피커/헤드폰 청취, Android 청감/export는 미검증이다.
