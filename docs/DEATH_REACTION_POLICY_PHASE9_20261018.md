# 하드코딩 정리9차: 사망 반응 바인딩 — 2026-10-18

## 기준·범위
- 수정 전 HEAD/feature/stage10-astra `feee7ab572de3f51d180850261e3d5d249ffdcee`, origin/main `6f22053f462e1176ec2ecde131d589d5491791b2`, clean 상태 확인. 작업 브랜치만 변경, main 병합 없음.
- _on_monster_died의 밴시 카운터/정예 전환, 유령 반응 호출, 레거시 슬라임 확률 분열의 ID 분기3곳을 Catalog 기반 정책으로 변경.
- 유령의 기존 대상 registry 탐색/난수 선택/실제 강화 함수, 보상/환급·처치 수·초월/밴시 본체·8차 추가 소환/분열 및 _spawn_monster·AI/계정/서버·리소스는 변경하지 않음.

## 구조와 유지 동작
- MonsterCatalog.death_reactions: 밴시는 counter_elite에 증강 ID·카운터 property·임계 key/default30·증강 제외 spawn modifier·정예 이름/type을 선언. 유령은 pre_reward_method로 기존 callback을 연결. 슬라임은 legacy_split에 현재 확률 property와 반경42 선언.
- 무효 monster 입력에서 기존 기본 ID를 쓰던 부분도 Catalog.DEFAULT_DEATH_MONSTER_ID로 이동. 기본값slime과 기존 fallback 동작은 유지.
- 보상 전 _apply_pre_reward_death_reactions 호출. 밴시는 유효 monster/증강 제외 gate·비어 있지 않은 config 조건을 유지하고 카운터를 증가. 임계값에 도달하면 spawn 성공 여부와 관계없이 먼저0으로 초기화. 소환·정예 modifier는 기존처럼 매번 독립 Dictionary로 전달. 유령은 증강 제외 flag와 무관하게 유효 monster일 때 기존 callback 호출.
- EXP 전달·영웅 처치 통지·드롭 카운터·비용/등록 해제·환급 신호 이후 _try_spawn_legacy_death_child 호출. 확률 값은 이 시점의 Battle property에서 읽으므로 앞선 콜백의 변경을 반영.
- 원래 split 자식은 레거시 확률 분열을 하지 않으며 allow_special_death_split과 구분. 확률>0일 때만 randf, 원래 <= 비교·성공 시 randf_range/반경42·비용0/split=true 호출 유지. 확률을 임의 clamp하지 않음. 이어서 기존8차 특수 사망 소환 처리.
- shared 읽기 전용 프로필, 고정 개수 조회/등록된 callback만 호출. 신규 _process/전체 스캔/프레임별 배열·노드 생성·O(n²)/풀 변경 없음. 유령의 기존 registry 순회는 그대로이며 추가 순회하지 않음. FPS 개선율은 미측정.

## 검증
- Godot4.5.1 headless에서 수정 전 SHA/수정 후 _on_monster_died 전체를 원문 추출해 실행 비교. 현재 실제8차 소환·clamp 코드와 Catalog 의존33개(초월/용사모드 포함) 사용, scene preload만 null.
- 전체65종+불명 ID, normal/self_destruct/consumed 원인, split/추가 분열 허용/증강 제외 조합, 확률 음수/0/0.15/1/2. 밴시의 빈/부분 config·임계값0/1/2/30/소수/음수와 현재 카운터0/1/28/29/30·소환 성공/실패 비교.
- 유령 callback/밴시 정예화/EXP 전달·영웅 처치 통지·metrics·비용/등록 정리·환급 신호·분열·stats/초월 사망 연출 호출 순서와 인자, 카운터·metadata·command/alive 상태·다음 RNG3개 비교.
- hero/refund 콜백 중 확률 변경, spawn 중 RNG 소비·modifier 수정, battle_over/용사모드 정예 카운터/이미 처리된 초월·기록 flag·보상0·환급0/음수·무효 source도 포함. 신규963검사 PASS.
- 독립 sanity: 실패해도 밴시 카운터 초기화, 생성 밴시는 증강 제외, 환급 콜백 후0→1 확률을 읽어 split 자식 생성, consumed는 EXP/처치/metrics 통지 없음, shared 정책 Dictionary 수정 없음 확인.
- 8차 증식·분열 회귀3948 PASS. 합계4911검사, 정상 경로 script/runtime 오류0. 저작 데이터는 death_reactions3항목 외 이전과 동일, 밸런스 감사 issues0·Python compile/git diff --check 통과.
- 나머지 Battle236함수 본문 동일. 사망 owner의 두 이동 블록과 기본 ID 바인딩만 제외하면 함수 전체의 보상/정리 순서가 동일함을 정적으로 확인. 8차 fixture는 이후 별도 감사된 _on_monster_died만 명시적으로 허용하고 새 metadata만 authoring 비교에서 제외, 기본 감사 유지.
- EXP orb 생성기/드롭·metrics·anubis registry/일부 신호 외부 소비자·유령 실제 강화/정예화·실제 spawn은 통제 어댑터. 실제 몬스터 전투·실제 보상 수령/물리/풀/유령 대상 선택·실기PC/Android/FPS는 미검증. 전체 사망 처리 함수를 실행한 검증과 전체 게임 검증을 구분함.

## 재현
1. `python tools/build_death_reaction_policy_fixture.py /tmp/death-reaction --baseline feee7ab572de3f51d180850261e3d5d249ffdcee`
2. Godot editor import 후 `--headless --path /tmp/death-reaction --script res://smoke.gd`.
3. 8차 fixture의 기존 ea61cad baseline에 `--allow-changed-method _on_monster_died` 추가 후 기존 smoke 실행.

## 다음 소범위 후보
- 유령 사망 강화 본문의 설정/기본 배율·스택 key. 대상 registry 선택 알고리즘은 동작·난수·성능을 별도로 비교할 수 있는 범위로 조사.
