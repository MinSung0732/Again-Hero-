# 용사 진명·계정별 해금 — 2026-10-19

- 기준 feature/stage10-astra `e8dc776fcc2e7386918a88f4edb89a92641ab925`, main 조회 `6f22053f462e1176ec2ecde131d589d5491791b2`. 시작 작업 트리 clean. main 병합 없음.

| 스테이지 | 진명 | 영문 | 해금 |
| --- | --- | --- | --- |
| 1·5·10 | 아스트라 | Astra | 기존 stage10 스토리 공개/스킵 이벤트 유지, 같은 identity 공유 |
| 2 | 아길리스 | Agilis | 같은 용사 쉬움 클리어10회 또는 어려움1회 |
| 3 | 피르무스 | Firmus | 공통 클리어 조건 |
| 4 | 솔리투도 | Sōlitūdō | 공통 클리어 조건 |
| 6 | 데멘티아 | Dementia | 공통 클리어 조건 |
| 7 | 릭소사 | rixosa | 공통 클리어 조건 |
| 8 | 데쿠스 | Decus | 공통 클리어 조건 |
| 9 | 미티스 | Mitis | 공통 클리어 조건 |

## 저장과 표시

- 이름/영문/공유 identity/일반10·어려움1/스토리 전용 정책은 기존 `hero_reveal_catalog.gd` 데이터가 소유한다. runtime의 개별 용사 ID 조건을 추가하지 않고 기존 returning_magic_hero 비교와 Main의1/5 전용 이름 표시 조건을 제거했다.
- 마왕 모드 `complete_stage`/`complete_hard_stage`의 성공 클리어를 stage별 `hero_clear_counts`/`hero_hard_clear_counts`에 기록하고 identity별 조건 충족 시 `hero_true_names`에 영구 표시한다. 카운터와 해금 flag는 기존 클리어·보상 ConfigFile과 같은 AccountSaveScope 트랜잭션에 들어간다. 저장 실패 시 둘 다 반영하지 않으며 재시도에도 실패분을 중복 누적하지 않는다. Battle의 기존 종료1회 gate를 유지한다. 실패/시간 초과/포기/입장 횟수/연습·튜토리얼은 클리어로 세지 않는다. 용사모드 승리 횟수를 마왕의 용사 처치 횟수로 합산하지 않는다.
- 예전 저장에는 일반 클리어 횟수가 없었다. 기존 cleared flag는 최소1회만 인정하고 다음 성공부터 누적한다. 과거 반복 클리어 수를 추정해10회로 만들지 않는다. 기존 hard_cleared는1회를 입증하므로 바로 해금으로 읽는다. 이미 저장된 명시적 진명 flag는 보존한다. 100회 조우/서로 다른3스테이지 조우는 새 일반 해금 조건으로 사용하지 않는다.
- 아스트라는 일반 카운터/어려움 조건으로 추가 해금하지 않는다. 기존 stage10 대사의 진명 공개 이벤트와 apply_on_skip,1/5/10 공유 identity를 그대로 보존했다. 스토리 대사/진행 조건 자체는 바꾸지 않았다.
- `stage_progress.cfg`에 저장하므로 기존 UUID별 계정 bundle·dirty/pending cloud 요청·JSON payload·재접속 복원 경로를 그대로 사용한다. 다른 계정/게스트와 섞지 않으며 새 서버 schema/배포·별도 API를 추가하지 않는다. 실제 로그인/서버/두 기기 왕복 테스트는 이번 검증에 포함하지 않는다.
- 해금 전에는 기존 호칭, 해금 후에는 대화/로비 stage card·용사 선택 초상화·편성 목록·도감·전투/HUD에서 한글 진명을 쓴다. 초상화 로딩의 진명란과 도감 상세에는 영문을 함께 표시한다. 스토리 공개가 저장되면 현재 전투 snapshot도 갱신한다.
- Battle은 개인용 profile 복제본의 display_name만 입장 시 한 번 바꾼다. 원본 HeroProfiles/능력치·AI·보상 수식·무기·직업/기술 설명은 바꾸지 않았다. 권위 온라인 Battle은 개인 계정 이름 조회를 하지 않는다. 온라인 전용 client UI는 이번 범위가 아니다.
- 진명 상태는 화면 입장/새로고침 때 한 번 읽어 목록에 공유한다. 매 프레임 저장 읽기·그룹 스캔·새 배열/Dictionary 생성 경로를 추가하지 않았다. 총계는 stage metadata 한 번 순회로 계산하며 계정 전환 시 보여줄 상태를 다시 읽는다.

## 검증

- Godot4.5.1 headless 실제 Catalog/StageProgress/AccountSaveScope·진행/보상 저장 **571검사 PASS**. 10종 표기,7종9→10 경계/어려움, 아스트라 기존 스토리, 조우101회, 레거시 일반/어려움/명시 해금, 성공/실패·재시도·계정A/B/게스트 분리·재선택·실제 JSON bundle install/pending payload 포함을 확인했다.
- 실제 Main의 두 entry/disclosure owner를 추출해 **46검사 PASS**.10종 잠김/해금 대화, 기존 entry HUD/pause handoff·restart skip·연습 경로와 스토리 공개 후 active/shared 이름 갱신을 확인했다. 하위 Battle/UI 호출은 값 기록 어댑터다.
- 실제 HeroRevealCutscene scene/script·공용 음성 경로 **162검사 PASS**(기존161+실제 `진명 : 데쿠스 (Decus)` 표시). 실제 도감 UI 회귀도 PASS: 캐시가 있어도 진명 list/detail을 갱신하고 계정 변경 시 이전 이름/자료를 숨긴다.
- 숫자를 보고하는 검사는 합계 **779개**, 도감은 별도 PASS다. 최종 core/entry/reveal import·실행 ERROR/WARNING0. 도감은 ERROR0, 기존 Image.load SVG 경로의 export 관련 경고2건이 있다(해당 texture loader는 이번 수정 없음). 기존 도감 테스트의 오래된375HP/37공격력 고정 기대값은 현재 Catalog에서 계산하도록 수정했으며 게임 수치를 변경한 것은 아니다.
- 기존 클리어/어려움 보상 owner는 카운터 기록 호출 외 텍스트 동일, Battle은 display_name2줄 외 동일을 정적 확인했다. Hero 전체/HeroMode/AccountSaveScope/CloudStore/원본 HeroProfiles/StageIntroDialogues/project 설정 동일. Python compile·git diff --check PASS.
- fixture의 Monster actor scene binding만 생략했고 실제 저장/정책/도감 로직을 실행했다. 전체 전투/실제 아트/GPU·모바일·실제 로그인/두 기기 cloud 왕복은 미검증이다.

```sh
python tools/build_hero_true_name_fixture.py /tmp/hero-true-name-final
godot --headless --path /tmp/hero-true-name-final --editor --import
godot --headless --path /tmp/hero-true-name-final --script res://tests/hero_true_name_smoke.gd
godot --headless --path /tmp/hero-true-name-final --script res://tests/hero_true_name_entry_smoke.gd
godot --headless --path /tmp/hero-true-name-final --script res://tests/hero_codex_smoke.gd
python tools/build_hero_voice_fixture.py /tmp/true-name-reveal
godot --headless --path /tmp/true-name-reveal --editor --import
godot --headless --path /tmp/true-name-reveal
```
