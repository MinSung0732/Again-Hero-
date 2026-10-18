# 하드코딩 정리5차: 정예 소환 정책 — 2026-10-18

## 기준과 범위
- 수정 전 feature/stage10-astra/HEAD `80f0f692a06edab68cf3eaa0fd178c158c60d89f`, origin/main `6f22053f462e1176ec2ecde131d589d5491791b2`, clean 상태 확인. 작업 브랜치에서만 변경, main 병합 없음.
- 코볼트 정예의 사거리 내 최원거리 소환 선택과 해골 정예의 생존 등록 선택 2개 ID 분기만 Catalog로 이동.
- 합체/부활/특수 기술/AI·능력치/증강/보상/온라인·이미지/오디오 변경 없음. registry 자체는 교체하지 않음.

## 구조와 유지 동작
- MonsterCatalog의 elite_spawn metadata: position_policy enum, alive_registration_method. 일반 이벤트 원형 배치/거리720/생존 후크 없음은 공통 기본값이며 코볼트/해골만 해당 항목을 재정의. 프로필은 공유 읽기 전용 참조, getter 호출마다 복사/캐시 증식 없음. 이벤트 spawn_distance가 설정 기본값보다 우선.
- Battle.spawn_special_monster는 기존 유효성·용사 생존모드 허용·후보 대체·엘리트 허용 검사 후 공용 위치 선택기를 호출. 대체된 실제 ID의 정책을 사용. 기존 elite_variant flag와 spawn 실패/통계 갱신 순서 유지.
- 코볼트 전용 이름의 좌표 함수를 _get_farthest_attack_range_spawn_position으로 일반화. 수식/최원거리 동률 선택/맵·성벽 clamp/1픽셀 여유/0거리·hero 미존재 fallback은 동일. 난수를 추가로 소비하지 않음. 일반 이벤트 함수의 기본720도 같은 Catalog 상수 참조.
- 정예 시각 적용 후 Catalog가 지정한 생존 등록 후크를 실행하고 기존 스킬 등록 진행. 기존 set_elite_skeleton_alive/has_living_elite_skeleton/one-shot tree_exited 연결과 사망/퇴장/융합/초기화 삭제 경로는 그대로. skeleton actor의 부활/알림 경로 및 API도 유지.
- 신규 _process/전체 스캔/매 프레임 배열·노드 생성/풀 정책 변경 없음. 기존 소환 시점의 고정 개수 조회만 추가. 성능 개선율을 주장하지 않음.

## 검증
- Godot4.5.1 headless 격리 프로젝트에서 수정 전 SHA/수정 후 Battle의 실제 spawn_special_monster·정예 변환·좌표 계산·생존 등록 함수들을 원문 추출해 비교. Catalog 및 의존 데이터30개 실제 사용, scene preload만 null.
- Catalog 전체65종, 맵2종×성벽2종×용사위치5×거리4의 소환 결과/좌표·정예 metadata·등록 수·실행 trace와 다음 RNG 값 비교. 음수/0/기본/큰 거리, 맵 밖 위치, 최원거리와 용사 위치 일치, 기본 이벤트 포함.
- 용사 모드의 코볼트/해골 대체와 대체 거절·허용 차단, 소환 실패, hero 미존재, 엘리트 비허용/미등록 ID도 비교. 실제 Node 트리에서 해골 정예2개, 중복 등록/해제, tree_exited one-shot, 재진입/재등록, 개별 free 및 마지막 생존 해제를 확인.
- 신규10571검사 PASS. Catalog 데이터는 elite_spawn2항목을 제외하면 이전과 동일. 나머지 Battle229함수 본문 동일, 일반 이벤트 함수는 기본 인자만 Catalog 참조, 사거리 함수는 이름/주석만 변경됨을 정적으로 확인. hobgoblin 기존 소스 추출 테스트의 함수명/공용 선택기 의존성도 갱신.
- 4차 실제 정예 변환·강화/HP 계산 회귀 정상732 + raw 누락732 =1464 PASS. 기존 get_meta(key,null)의 raw 누락 진단은 before96/after96으로 동일하며 이 단계에서 수정하지 않음. 합계12035검사. 정상 경로 script/runtime 오류0, Catalog 밸런스 감사 issues0, Python compile/git diff --check 통과.
- 전체 Battle scene/실제 몬스터 AI·부활/융합·물리/풀 재사용·15분 완주·실기PC/Android·FPS는 미검증. 외부 스탯 적용/시각/스킬 등록/생존모드 공급 판정은 stub이며, 생존 레지스트리와 Node tree_exited는 실제 실행. 전체 홉고블린 actor 테스트는 이번 환경에서 재실행하지 않음.

## 재현
1. `python tools/build_elite_spawn_policy_fixture.py /tmp/elite-spawn --baseline 80f0f692a06edab68cf3eaa0fd178c158c60d89f`
2. Godot editor import 후 `--headless --path /tmp/elite-spawn --script res://smoke.gd`.
3. 4차 회귀: 기존 build_monster_scaling_policy_fixture의 e546bd8 baseline에 `--allow-changed-method spawn_special_monster --allow-changed-method _get_stage_event_spawn_position --allow-changed-method _get_farthest_kobolt_attack_spawn_position`를 추가. 5차에서 별도 검증한 범위만 명시적으로 제외하며 기본 감사 동작은 유지. smoke 기본 및 `-- --missing-meta` 실행.

## 다음 후보
- 기존 거미 둔화·고유 증강 상태 바인딩의 데이터화. 부활·합체는 독립 규칙과 수명주기가 있어 별도 범위로 조사.
