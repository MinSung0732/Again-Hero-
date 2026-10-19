# 하드코딩 정리20차: 용사별 증강 중첩 제한

## 기준과 범위

- 수정 전 로컬/원격 `feature/stage10-astra`: `95f0fb088adfee64dfbfd8955302188d30e1ce32`, 작업 트리 clean. 원격 main: `6f22053f462e1176ec2ecde131d589d5491791b2`. main 병합 없음.
- 19차 보존 항목 중 `_get_augment_roll_build_counts`를 함수 전체 및 호출 경로와 함께 검토했다. 연금술사의 민첩한 발놀림 3중첩 제한은 필요한 고유 규칙이다. 이 규칙 자체는 보존하고, 추첨/적용 사이의 중복 ID·상한 설정을 통합했다.
- `hero_augment_catalog.gd`의 `HERO_STACK_LIMITS`가 용사별 제한을 소유한다. Hero 추첨 adapter는 공통 `get_roll_build_counts`로 위임한다. 기존 `get_effective_max_stack`도 같은 정책을 읽으므로 실제 적용, Main 정보창, 도감의 실효 상한이 함께 연결된다.
- 등록 정책은 기존 증강의 양수 상한을 낮추는 제한이다. 공통 최대치를 늘리거나 무제한으로 바꾸는 기능은 이번 범위가 아니다. 신규 용사/증강 제한은 정책에 추가한다.

## 기존 의미와 비용

- 연금술사 민첩한 발놀림은 3중첩, 다른 용사는 원래 공통 10중첩이다. 공통 증강 데이터/설명·효과·AI 가중치·후보 추첨 알고리즘은 그대로다.
- 정책이 없거나 아직 제한 미만이면 원래 build_counts 참조를 반환한다. 제한에 도달하면 추첨용 얕은 복사 한 번만 만들고 해당 항목을 공통 추첨 상한까지 올려 후보에서 제외한다. 저장된 실제 중첩 수는 변경하지 않는다. 여러 제한이 동시에 걸려도 같은 복사를 사용한다.
- 매 선택 시점의 현재 archetype/중첩 수를 읽는다. 별도 캐시나 무효화, 매 프레임 작업, 그룹 조회, 노드 생성/해제는 추가하지 않았다. 기존 제한 도달 경로의 Catalog 조회/증강 복사는 유지한다. 실제 FPS 개선을 주장하지 않는다.

## 검증

- Godot 4.5.1 headless 격리 import 및 전후 **66,826검사 PASS**, ERROR/WARNING 0. 수정 전후 실제 Catalog 전체와 Hero의 추첨 adapter/실효 상한/적용 함수를 추출해 실행했다.
- 10개 archetype과 미등록/빈 값, 모든 기존 증강과 미등록/빈 ID, 중첩 경계·음수·과다 값, 명시/기본 실효 상한을 비교했다. 실제 효과 본체/stack 후크는 기록 어댑터이며, 실행 횟수/순서/인자와 최종 중첩을 비교했다.
- 실제 weighted roll 코드를 동일 seed로 실행해 후보 전체 내용·순서와 다음 RNG 값을 비교했다. 빈/제한/미등록 allowed pool, 요청 수 0/1/3/500과 cap 전후를 포함한다. 원본 Dictionary 보존, 반환 참조/얕은 복사 의미, 선택 사이 archetype/중첩 변경도 검사했다.
- 테스트 전용 Catalog에 새 용사와 두 증강 제한을 데이터만 추가하고 동일 Hero 함수를 실행해 후보 차단/적용 차단/제한 미만 적용을 확인했다. 테스트 전용 콘텐츠는 게임 Catalog에 넣지 않았다.
- builder가 Hero의 나머지 **664함수**와 선언, 기존 모든 증강 데이터 및 추첨 함수 등 다른 Catalog 함수, Main/Battle/도감 Catalog/HeroProfiles의 원본 동일성을 확인한다. Python AST 정적 검사 및 `git diff --check` 통과.
- 전체 게임 장면, 실제 전투·AI 최종 선택, 저장/보상 통합, PC/모바일 플레이는 실행하지 않았다. 이번 실행은 의존성을 제한한 함수 전후 비교이며 전체 실기 검증이 아니다.

재현:

```sh
python tools/build_hero_stack_policy_fixture.py /tmp/hero-stack-phase20 --baseline 95f0fb088adfee64dfbfd8955302188d30e1ce32
godot --headless --path /tmp/hero-stack-phase20 --editor --import
godot --headless --path /tmp/hero-stack-phase20 --script res://smoke.gd
python tools/inventory_content_selectors.py --output docs/CONTENT_SELECTOR_INVENTORY_PHASE20_20261019.json
git diff --check
```

## 남은 비교

- 같은 좁은 직접 비교 패턴은 80→79곳이다. 최신 기준 runtime script 352개(19차 351개 이후 음성 player 추가)를 조사했다. 이번 변화는 Hero adapter의 비교 1곳이며, Catalog 안의 중복 비교는 조사 수에 포함되지 않는다.
- 소유권/진입 가드 54, AI 관측 구성 6, 고유 동작 재검토 19곳을 유지했다. 위치/분류는 이번 inventory/review JSON에 기록했다. 이 수치는 전체 하드코딩 수나 앞으로 필요한 차수의 수가 아니다.
