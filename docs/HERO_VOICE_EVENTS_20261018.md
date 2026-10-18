# 용사 음성 이벤트 연결 — 2026-10-18

- 기준: `feature/stage10-astra` / `cd691a1ddd48a5a3b962392699f336b6c1a5ae26` (사용자가 업로드한 WAV33개 포함). main 최신 조회 SHA `6f22053f462e1176ec2ecde131d589d5491791b2`. 시작 작업 트리 clean, fast-forward만 수행. main 병합 없음.
- 음원 출처는 사용자가 저장소에 추가한 `assets/audio/sfx/hero_voices/` WAV33개다. 새 외부 음원/합성/런타임 Base64 디코딩은 추가하지 않았다. 원본 오디오와 project.godot은 수정하지 않았다.

## 연결과 정책

| 이벤트 | 실제 연결 지점 | 동작 |
| --- | --- | --- |
| 진입 | HeroRevealCutscene의 기존 loading loop 완료 신호 | 초상화가 보이고 progress=100일 때 시작, 전투로 이어 재생. 완료/초상화 누락 fallback도 같은 영수증으로 중복 방지 |
| 용사 패배 | Battle의 최종 처치/실패 확정 신호 | 기존 처치 slow focus 도중 0.08실시간 초 뒤 시작. 용사 노드 제거 후에도 유지 |
| 용사 승리 | Battle의 제한시간 생존 확정 신호 | 결과창 처리 전에 시작, 결과창 표시를 음성 길이만큼 기다리지 않음 |
| 스킬 해금 | SkillUnlockCutscene intro tween 완료 신호 | artwork alpha/reveal=1인 시점에 시작, 기존 outro 뒤에도 유지 |

- `hero_voice_catalog.gd`가 hero identity→pack 폴더/접두사와 이벤트 suffix/우선순위/지연/음량/duck 수치를 소유한다. 10종×진입/승리/패배=30개, 소환사/정화/아스트라의 unlock3개. 다른 영웅의 unlock은 조용히 생략한다. 전장 번호로 캐릭터를 추측하지 않으므로 용사모드에서 선택한 전장과 용사가 달라도 올바른 pack을 쓴다.
- 공용 `hero_voice_player.gd`를 전투 화면의 자식으로 보관한다. AudioStreamPlayer1/Timer1을 재사용하고 현재 용사 pack의 최대4개 stream만 기존 로딩 준비 단계에서 캐시한다. 리소스 없음/미등록 pack은 전투를 막지 않는다. 매프레임 그룹 조회·배열/Dictionary 생성·로드·instantiate/free는 추가하지 않는다.
- 재생 우선순위는 결과 > 해금 > 진입. 높은/동일 우선순위의 새 이벤트는 이전 음성을 교체하며, 하나의 음성만 재생한다. 진입1회/skill ID별 해금1회/결과1회의 영수증을 전투 화면 수명 동안 유지한다. 결과 이후에는 진입/해금 재생을 차단한다.
- Battle의 새로운 `hero_outcome_confirmed`는 플레이어 승패와 별개인 용사 관점의 의미다. 사망/용사모드 보스 시간 초과는 defeat, 제한시간 생존/용사모드 최종 보스 처치는 victory. 기존 `battle_finished` 인자는 바꾸지 않았다. 포기/중도 종료는 outcome을 전달하지 않아 승리로 오인하지 않으며 진행 중 음성도 중지한다.
- `_finish_battle`은 이미 battle_over이면 return하므로 먼저 확정된 결과만 한 번 알린다. 처치/시간 초과 호출 순서에 따라 기존에 먼저 확정된 결과와 같은 대사만 재생한다. 보상·사망/부활 판정·타이머·AI·수치는 변경하지 않았다. 새 종료 경로는 `_finish_battle`의 선택 인자에 의미 있는 hero outcome을 전달해야 음성이 나온다.
- 사망 시작 death_started 자체에는 음성을 연결하지 않는다. 기존 death animation 후 Battle이 처치를 확정하는 시점에 시작하므로 처치 focus의 첫 프레임보다 늦을 수 있다. 첫 타격음과 간격을 두고 확정 전/다른 결과의 대사가 나오는 것을 피한다. focus/result의 기존 길이와 기다림은 유지한다.
- Main(마왕모드)과 HeroMode의 진입/결과를 연결했다. HeroMode는 기존 보스 종료 규칙 그대로다. 스킬 음성은 Main의 기존 조건부 컷신에 연결하며 HeroMode에 새 컷신 UI를 추가하지 않았다. 온라인 전용 client UI/네트워크 전달은 이번 범위가 아니다. 권위 Battle 신호만 추가되며 서버에 음성 재생기는 설치하지 않는다.

## 음량·속도·수명

- Voice bus는 SFX 슬라이더/뮤트와 같은 설정을 적용한다. 전투 효과음 bus를 낮춰도 음성 자체는 낮아지지 않도록 별도로 Master에 보낸다. 새 사용자 설정/슬라이더는 추가하지 않았다.
- 초기 relative voice=-2dB, 음성 중 BGM=-7dB / SFX=-5dB 추가 attenuation. 사용자 bus volume/mute를 덮어쓰지 않고 각 bus에 소유한 Amplify effect만 적용한다. attack0.08초/release0.22초 tween은 실시간이며 화면 종료 때 자기 effect만 제거한다.
- 음성 pitch=1, 지연 Timer와 duck tween은 Engine.time_scale을 무시한다. 실제 tree pause/앱 background에서는 player와 지연을 일시 정지한다. 효과음 뮤트는 진행 중 음성도 중지하며 unmute가 지난 음성을 재시작하지 않는다.
- 원본 대사는 약2.88~14.20초다. 길어도 로딩창/전투/결과/컷신 화면을 음성 때문에 붙잡지 않는다. 로비/재시작 등 전투 화면을 떠나면 소유 player가 제거되어 끊기며 duck도 복구된다.

## 검증

- Godot4.5.1 headless 격리 프로젝트 실제 실행 **161검사 PASS**, WAV **33개 모두 import/비어 있지 않은 길이/loop 비활성/AudioStreamPlayer 시작** 확인. 실제 오디오 출력 장치 청취 검증이 아니다.
- 실제 player/settings/Catalog/UI script·scene 및 추출한 Main 완료/컷신 후크와 Battle6개 종료 owner를 실행했다. 12개 보스 deadline 기존 회귀도 PASS. 최종 import/실행 ERROR·WARNING0, 합계173검사.
- 초기 재생/중복/우선순위·결과 latch·마왕/용사/온라인 권위/연습/튜토리얼 종료·같은 프레임의 반대 종료 순서·포기·미등록 pack·볼륨/뮤트·pause/background/resume·effect 복구/수명·100% loading과 실제 artwork intro/outro 신호를 확인했다. 시간배율0.05에서 실제 지연과 짧은 합성 무음 stream의 자연 종료/duck release가 실시간으로 완료되는 것도 확인했다.
- UI artwork/font와 warmup texture cache는 fixture 대체물이다. Battle의 진행 저장/보상/registry/하위 gameplay는 어댑터다. Main/HeroMode 전체 화면 또는 실제 전체 전투·AI/보상 저장·부활/모바일 export·실제 PNG/GPU/실기FPS·음성 청감은 미검증이다.
- 변경 함수 외 Battle234/Main142/HeroMode43/reveal10/unlock5/AudioSettings11 함수 동일을 정적으로 비교했다. Hero 전체와 project.godot·기존 오디오 asset은 그대로다. Python compile 및 git diff --check PASS.

재현:

```sh
python tools/build_hero_voice_fixture.py /tmp/hero-voice-fixture
godot --headless --path /tmp/hero-voice-fixture --editor --import
godot --headless --path /tmp/hero-voice-fixture
python tools/build_hero_encounter_fixture.py /tmp/voice-encounter-regression
cp tests/hero_boss_deadline_smoke.gd /tmp/voice-encounter-regression/tests/
godot --headless --path /tmp/voice-encounter-regression --editor --import
godot --headless --path /tmp/voice-encounter-regression --script res://tests/hero_boss_deadline_smoke.gd
```

실제 기기에서 1/6/8/9/10 진입, 용사 처치 focus→결과, 시간 초과→결과, 8/9/10 조건부 컷신, 뮤트/배경 복귀/로비·재시작 중단, 용사모드의 서로 다른 캐릭터/전장 및 보스 승패를 청취하고 최종 믹스를 조정해야 한다.
