# 하드코딩 정리10차 및 누적 감사 — 2026-10-18

## 기준과 변경
- 수정 전 HEAD/origin feature/stage10-astra `6282ea70e732b7d5b5e195607383dbf73b9a6a6c`, 최신 origin/main `6f22053f462e1176ec2ecde131d589d5491791b2`, clean 확인 후 작업. main 병합 없음.
- 유령 사망 강화의 owner/증강ID·배율 key/default1.10/min1.0·raw 능력치 순서·곱셈/역수·하한·스택 metadata를 MonsterCatalog.death_reactions.ally_empower로 이동.
- 등록된 pre_reward_method callback은 죽은 actor와 공유 death profile을 받음. 현재 등록은 유령1개뿐. 런타임은 프로필에서 선언한 설정과 능력치를 처리하고 마지막에 기존 일반 증강 refresh 호출.
- 대상 registry 순회·무효/사망/삭제 예정 제외·기존 재사용 후보 배열·randi modulo 선택·후보 clear 시점·raw 읽기/쓰기 순서·스택 증가·refresh 순서 유지. exclude_all_augments를 새로운 대상 제외 조건으로 추가하지 않음. 배율/스탯/AI/보상/풀·기술/진행 타이밍 변경 없음.
- 읽기 전용 공유 프로필과 고정4개 규칙 순회. 새 _process/배열·Dictionary 생성/노드 생성·해제/그룹 스캔 없음. 유령의 기존 사망 시 registry 탐색은 그대로이며 추가 탐색 없음. FPS 개선은 미측정.

## 검증과 한계
- Godot4.5.1 headless: 실제 수정 전/후 유령 강화 함수 원문을 추출한 격리 fixture 실행. 실제 Catalog 의존30개 사용, 누락된 scene preload만 null. actor는 최소 Node, 일반 증강 refresh는 기록 어댑터.
- 정상2054검사 PASS: 증강 없음/빈 config/배율 key 없음/음수·0·1·1.1·2.5, raw0/음수/소수/최소값, 스택0/3·연속2회, 후보 없음/모두 사망/일부 사망·삭제예정/무효/자기 자신, 복수 후보와 seed4개 비교. 최종 metadata·후보 버퍼·config/refresh 이벤트·다음 RNG3개 일치.
- 독립 sanity: 기본1.10 적용·스택1, 사용자 정의 owner/증강/배율 key·raw metadata·역수·최소값·스택 key로 재바인딩 시 적용 확인. shared 정책 불변, ghost 정책 외 Catalog 저작 데이터 동일.
- raw 누락 별도2050검사 PASS. 기존 get_meta(key,null)의 누락 진단은 before/after 각각768개로 메시지 순서 동일. 이 경로는 의도적으로 기존 오류 진단을 보존했으며 오류0이라고 주장하지 않음.
- 기존9차 전체 사망 owner 회귀963검사 PASS: 보상/환급/분열/RNG·callback 순서 유지. ghost callback은 해당 fixture에서 기록 어댑터이며 실제 강화는 위 별도 fixture로 검증. 합계5067검사.
- 나머지 Battle237함수 본문 동일, dispatcher는 callback의 profile 인자 추가 외 동일. 유령 대상 선택 블록과 refresh 호출 원문 동일. 밸런스 감사 issues0, Python compile·git diff --check 통과. 정상 유령/사망 fixture script/runtime 오류0.
- 전체 Battle/실제 몬스터 증강 refresh·실제 전투/보상 수령/물리/풀·Windows/Android/실기 FPS는 미검증. 에셋이 생략된 격리 fixture 검증을 전체 게임 검증과 구분함.

## 1~10차 누적 범위
기준은1차 직전 `449a66e98e937c04e0020ad0531f09f5d1dc0223`. Catalog에 콘텐츠 선언을 모으고 런타임의 중복 선택을 공통 처리로 바꾼 작업이다. 고유 기능 전체를 추상화한 작업이나 모든 상수를 제거한 작업은 아니다.

| 차수 | 정리한 경로 |
| --- | --- |
| 1 | 클라우드 재시도·연결 안내 정책 |
| 2 | 프로필 기본 성별·외형/초상화 참조 |
| 3 | 로비 메뉴·설정/도구 UI 정책 |
| 4 | 기본 투사체 ID/프레임·캐시, 후속 몬스터 HP/도화선/폭발 배율 바인딩 |
| 5 | 정예 소환 위치·생존 등록 정책 |
| 6 | 거대화 공격 대상·거미 둔화 배율 |
| 7 | 폭탄쥐 거대화 속성·신규 소환 배율 |
| 8 | 추가 소환·사망 증식/분열 |
| 9 | 보상 전 사망 반응·레거시 분열 |
| 10 | 유령 사망 강화 설정·누적 감사 |

좁은 정적 지표를 재현 가능한 도구로 추가했다. 각 조건문의 의미를 직접 확인한 두 파일의 특정 변수 선택 패턴만 센 값이다.

| 정적 선택 패턴 | 1차 직전 | 10차 후 |
| --- | ---: | ---: |
| Battle의 monster_type == / != / in 리터럴·목록/GIANT_RANGED_MONSTER_IDS | 18 | 1 |
| 기본 투사체의 source_hero_id == / != 콘텐츠 문자열 | 7 | 0 |

- 이 두 패턴에서24곳의 직접 선택이 제거됨. 별도 변수명·match arm·다른 시스템의 분기·리소스/수치 상수·Catalog 선언은 집계하지 않으므로 **전체 하드코딩 제거율로 환산하지 않음**. 코드 줄 수 감소나 성능 개선율도 의미하지 않음.
- 남은 Battle의 해당1곳은 `_try_fuse_nearby_kobolts`를 호출하는 코볼트 합체 경로. 합체/정예 생명주기 비교가 필요한 별도 범위.
- Hero에는 archetype별 기술/공격 선택·성장 규칙이 남아 있음. 고유 기술 실행과 공통 바인딩을 분리하여 후속 소범위로 검토해야 함.
- 기본 투사체의 source 미존재 시 그룹 fallback, chest 그룹 캐시는 보존. 향후 registry 전환은 source 교체·풀 재사용·다중 방에서 별도 검증 필요.
- 이번10단계 계획은 완료. 반복 콘텐츠 바인딩은 상당 부분 모였지만 저장소 전체의 하드코딩 제거 완료를 선언하지 않음.

## 재현
1. `python tools/build_ghost_empower_policy_fixture.py /tmp/ghost-phase10 --baseline 6282ea70e732b7d5b5e195607383dbf73b9a6a6c`
2. Godot editor import 후 `--headless --path /tmp/ghost-phase10 --script res://smoke.gd` 실행. raw 누락은 뒤에 `-- --missing-raw` 추가, 기존 진단 로그는 별도 저장.
3. `python tools/build_death_reaction_policy_fixture.py /tmp/death-phase10 --baseline feee7ab572de3f51d180850261e3d5d249ffdcee --allow-changed-method _apply_ghost_death_empower` 후 기존 smoke 실행. 추가 allow 옵션은 기본 감사를 유지하고 이번에 별도로 비교한 함수만 명시적으로 허용.
4. `python tools/audit_hardcoding_cleanup.py --baseline 449a66e98e937c04e0020ad0531f09f5d1dc0223`로 선택 패턴 개수/위치 출력. 커밋 후 `--revision <commit>`으로 동일 감사 가능.
5. fixture tools에 `tools/monster_balance_audit.gd` 복사 후 Godot `--script res://tools/monster_balance_audit.gd` 실행.
