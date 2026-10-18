# 하드코딩 정리11차: 소환 합체 정책·잔여 상황 — 2026-10-18

## 기준과 구현
- 수정 전 HEAD/origin feature/stage10-astra `e68693a032d2f6dc12a84f04c86bc65c8b37a05d`, 최신 origin/main `6f22053f462e1176ec2ecde131d589d5491791b2`, clean 확인. feature만 수정, main 병합 없음.
- 코볼트 소환 후 합체의 콘텐츠ID/증강ID, 필요 개체 수 key/default4/min2, 반경 key/default180/min1, 제외 외형elite·크기 default1/상한1.001, 합체 표식/출처, 생성 modifier를 MonsterCatalog.summon_fusion에 선언.
- `_perform_summon`은 shared opt-in profile이 있는 몬스터만 `_try_fuse_nearby_monsters`로 처리. 불명/나머지64종은 공용 empty 정책을 반환. 콜백/임시 Dictionary를 만들지 않음.
- 후보 판별은 `_is_normal_fusion_candidate(actor,profile)`. 같은 콘텐츠·생존/삭제예정/정예/거대몹/이미합체/합체출처/크기 조건과 판독 순서 유지. 개별 ID/증강 key·합체 수치가 Battle에 남지 않음.
- 공간그리드 `fill_monsters_near`와 radius² 판정·조회 순서대로 count 충족 시 break, 평균 좌표/기존 clamp·재료별 비용 합산·직접 인구수 OR, 실제 `_consume_monster_for_fusion`과 registry 정리 순서 그대로.
- 기존 코드와 마찬가지로 재료를 먼저 소비하고 합체몹 생성. 생성 실패 시 null을 반환하며 이미 소비한 재료를 새롭게 복원하지 않음. `_perform_summon`의 후속 보상·EXP/메시지 처리도 보존.
- scratch/candidate 배열은 일반 합체 명칭으로 바꾸고 전투 시작 시 기존처럼 clear. 재사용 배열/공간조회 횟수 동일, 프레임 루프·그룹 스캔·O(n²)·노드 생성/해제 추가 없음. 결과 modifier는 공유 정책을 shallow duplicate 후 인구수만 입력: 기존 생성당 Dictionary1개와 같은 수명이며 spawn의 수정으로 공유 정책이 변하지 않음. FPS 개선율은 미측정.

## 검증
- Godot4.5.1 headless 격리 fixture에서 실제 이전/현재 `_perform_summon` 전체·합체·후보 판별·재료 소비 함수를 실행. 실제 Catalog 의존32개, 누락 scene preload만 null. 공간조회·spawn/정예 registry 해제·metrics·UI/EXP/궁극기 소비자는 통제 어댑터.
- 1133검사 PASS: 증강 없음/빈/부분 config·count0/2/3.9/6·radius 음수/20/180/200, 주변0/1/2/3/4/6개, 타종/HP0/정예/거대/합체 marker·출처/크기 경계/삭제예정/null, 범위 안·경계·밖, 주체 자체의 허용/제외 조건 비교.
- 생성 성공/실패, 직접·자동 생성 개체 혼합, 비용/인구수 이전·registry/정예 등록 해제·queued 상태·후보 버퍼·이벤트/순서·다음 RNG 일치. 실제 소환 owner는 코볼트/슬라임/제우스, 최초·합체 생성 실패/성공을 비교.
- 독립 sanity: 기본4체→1체, 평균 위치(115,100), 합산 비용7, 인구수 슬롯1 유지, 합체 결과 재합체 차단. 다른 콘텐츠/증강/설정 key·합체 marker/출처로 재바인딩 성공. 공유 정책 불변·해당 정책 외 저작 데이터 동일. 65종 opt-in/불명 opt-out 확인.
- 기존 소환 EXP smoke 어댑터를 새 함수 인자로 갱신, 실제 `_gain_demon_exp`/필요 EXP 계산/소환 owner 실행83검사 PASS. 할인된 소환/추가 소환·실패 환급·초월/튜토리얼/배틀 종료·연구배율 보존. 합계1216검사, 정상 fixture script/runtime 오류0.
- 나머지 Battle236함수는 scratch 명칭 치환 외 동일. 소환 owner는 합체 바인딩 외 본문/순서 동일, 재료 소비 본문 동일. 밸런스 감사 issues0, Python compile·git diff --check 통과.
- 기존 population_summoner_smoke의 직접 호출도 새 profile 인자로 수정. 이 전체 Battle/실제800개체 통합 테스트는 이번에 실행하지 않음. 에셋 생략 환경이므로 실제 몬스터 spawn·공간그리드·물리·풀/합체 생명주기·실제 EXP UI·전체 전투·Windows/Android/FPS 미검증. 격리 실제 메서드 검증을 전체 게임 검증이라고 부르지 않음.

## 얼마나 남았는가
1차 직전 `449a66e98e937c04e0020ad0531f09f5d1dc0223`과 비교한 기존 두 좁은 지표:

| 패턴 | 1차 직전 | 10차 후 | 11차 후 |
| --- | ---: | ---: | ---: |
| Battle monster_type 직접 ==/!=/in 문자열·목록/GIANT_RANGED_MONSTER_IDS | 18 | 1 | 0 |
| 기본 투사체 source_hero_id 직접 ==/!= 콘텐츠 문자열 | 7 | 0 | 0 |

이 두 경로의 추적 패턴25곳 정리는 완료. 다른 이름/접근자·match·각종 수치/경로까지0이라는 의미가 아니다.

이번에는 tracked runtime GDScript351개(src/data 제외)에서 `hero_archetype/hero_id/source_hero_id/monster_type/monster_id/stage_id/current_stage_id`의 비어 있지 않은 문자열 ==/!= 비교를 추가 조사했다.

| 조사된 잔여 후보 | 발생 수 | 판단 |
| --- | ---: | --- |
| src/hero/hero.gd | 140 | hero_archetype136 + hero_id4. 고유 기술/예외 동작이 다수 포함됨 |
| src/main/main.gd | 1 | rogue_combo 전투 정보 UI 설명 분기 |
| 합계 | 141 | 재검토 위치 수. 제거해야 할 작업141개라는 뜻이 아님 |

전체 위치/함수/비교값은 `CONTENT_SELECTOR_INVENTORY_PHASE11_20261018.json`에 기록. 고유 기술을 유지할 분기인지, 중복 바인딩인지 아직 전부 분류하지 않았으므로 전체 제거율/남은 확정 차수를 제시하지 않는다. String/get 접근자·match arm·목록·다른 변수명·경로·숫자 설정은 이141에 포함되지 않는다.

후속 우선순위:
1. 용사 `_apply_profile_visual`의10개 직접 비교와 main 정보 UI1개부터 데이터 연결 가능성을 검토. 피해/AI 선택보다 변경 범위를 좁히기 좋음. 이11곳도 검토 후보이며 무조건 제거할 의무는 없음.
2. 나머지130개는 공격/이동/피해/사망·AI context·개별 기술과 섞여 있음. 예: `_take_damage_internal`10·상태표시8·행동 선택7·AI context6·사망 처리6. 동작별로 바인딩과 고유 규칙을 분리하여 비교해야 함.
3. 기존 projectile 그룹 fallback/chest cache→registry 변경은 별도 성능 작업. 하드코딩 제거 건수에 넣지 않음. 전체게임/실기 검증도 별도 남아 있음.

현재 판단: 몬스터 공통 소환·강화·사망과 기본탄의 추적한 반복 ID 선택은 정리됨. 다음 큰 검토 영역은 용사 본체. 저장소 전체 하드코딩 제거 완료는 아님.

## 재현
1. `python tools/build_summon_fusion_policy_fixture.py /tmp/fusion-phase11 --baseline e68693a032d2f6dc12a84f04c86bc65c8b37a05d`
2. Godot editor import 후 `--headless --path /tmp/fusion-phase11 --script res://smoke.gd` 및 `--script res://summon_exp_smoke.gd` 실행.
3. fixture tools에 `tools/monster_balance_audit.gd`를 복사하여 같은 경로로 실행.
4. `python tools/audit_hardcoding_cleanup.py --baseline 449a66e98e937c04e0020ad0531f09f5d1dc0223`
5. `python tools/inventory_content_selectors.py --output /tmp/content-selector-inventory.json`로 현재 위치 목록 재생성. JSON의 base_head는 작업 직전 SHA이며 source는 working tree임.
