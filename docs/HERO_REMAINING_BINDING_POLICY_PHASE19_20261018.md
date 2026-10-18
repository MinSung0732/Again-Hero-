# 하드코딩 정리 19차: 남은 반복 연결 14곳

## 기준과 범위

- 시작 HEAD/원격 feature/stage10-astra: `70bc0765281ad4b7470856e0e191d2b6f7f52093`. 원격 main: `6f22053f462e1176ec2ecde131d589d5491791b2`. 시작 작업 트리 clean. main 병합 없음.
- 18차에서 연결 재검토로 분류한 직접 비교 14곳을 모두 구현했다. 고유 기술의 본체·AI 선택 알고리즘·피해/성장/보상 수치는 변경하지 않았다.

| 연결 | 기존 비교 수 | 데이터 소유자 |
| --- | ---: | --- |
| 경계 이동 | 1 | runtime binding Catalog의 기본/예외 steering |
| 기본 투사체 위임·기본 공격 음원 | 4 | runtime projectile override / presentation ordered event |
| 채널·방어막·관통 음원 | 3 | presentation event audio |
| 레벨업 풀 확장·증강 AI 설정 공급자 | 2 | runtime level-up binding |
| 증강 적용 후 후크 | 2 | runtime exact ID/prefix hook |
| 매혹 중 dictionary 쿨다운 | 1 | 기존 runtime dictionary cooldown binding |
| 방어 음원 준비 | 1 | contextual audio block preparation |

## 의미와 성능 보존

- 투사체의 채널/타깃 gate 뒤에 고유 발사를 선택하고 즉시 return한다. 공용 투사체 풀·개수 clamp·방향·volley·타이머·게이지 순서는 그대로다.
- 기본 공격 음원은 두 순차 단계로 선언했다. 첫 단계 호출 중 archetype이 바뀌면 두 번째 단계에서 현재 값을 다시 조회하므로 기존 두 독립 if 의미를 유지한다. 채널/방어막/관통 음원도 원래 실행 위치를 유지한다.
- 경계 steering은 치유/상자/자석 steering 이후 원래 선택 지점에서 캐시를 확인한다. 안정된 archetype에서는 기존 키 확인과 보관한 Callable 호출을 사용하며 최초/변경 시만 바인딩한다.
- 소환 슬롯 확장은 기존 5레벨 단위이며 성장 적용 이후다. AI context 공급자 호출 뒤 현재 archetype으로 설정 공급자를 다시 선택한다. 기본 ai_settings 참조와 소환사 공급자의 의미를 유지한다.
- 증강 효과 → stack 기록 → 일치한 첫 후크 순서를 유지한다. exact ID와 prefix는 공유 데이터이며, stack 제한·빈 ID gate는 그대로다.
- 매혹의 dictionary 쿨다운만 공유 binding으로 선택한다. 다른 용사의 property 쿨다운은 진입 때 보관한 독립 charm_cooldown_properties snapshot을 계속 사용한다.
- hit runtime 준비 후 현재 archetype으로 block resource를 선택한다. 기존 player가 유효하면 재사용하고, null/freed인 경우에만 기존 경로/db로 생성한다. 새 음원은 추가하지 않았다.
- 매 프레임 배열/Dictionary 생성·그룹 스캔·노드 생성/해제를 추가하지 않았다. 모든 목록/기본 빈 값은 공유 상수다. 기존 조건부 풀/음원 초기화 시점은 유지한다.

## 검증

- Godot 4.5.1 headless 전후 **6,517검사**, action owner 회귀 **43,637검사**, 합계 **50,154검사 PASS**. 최종 import/실행 ERROR·WARNING 0.
- 실제 수정 전/후 10개 owner/cache 함수를 추출하고 두 새 dispatch helper 및 실제 HeroActionIntent/HeroActionPort를 실행했다. 모든 archetype 10종 + 미등록/빈 값, 채널/타깃 gate, 투사체 bonus/풀 실패, 효과 frame null, 음원 player null/valid/freed, 증강 ID/prefix/stack 제한, NPC/용사/무기 null 레벨업, 후보 없음/있음, 매혹 snapshot/source/phase/delta를 비교했다.
- 12×12 archetype 전환을 발사·음원·음원 준비·증강 효과·성장/AI context·steering 콜백에서 주입해 원래 선택 시점의 현재 값과 호출 순서를 비교했다. 다음 RNG 결과 및 ai_settings 참조 의미도 일치한다.
- 투사체 setup/특수 기술 본체·오디오 재생·성장 수식·증강 후보/AI 선택·이동/상태 등 하위 의존성은 호출 기록/값 어댑터다. 후보/AI 어댑터의 RNG 순서 검증이며 실제 AI 알고리즘 전체 검증은 아니다. 실제 AnimatedSprite2D/합성 texture/AudioStreamPlayer 노드를 사용했지만 실제 PNG/음원 청취·전체 전투/물리 충돌/PC·모바일 플레이 검증은 수행하지 않았다.
- 나머지 Hero **653함수**, 새 캐시 필드를 제외한 다른 선언, Main/Battle, 기존 runtime/contextual Catalog 부분 및 presentation의 기존 설정/getter 동일을 builder가 검증한다. Python compile·git diff --check 통과.
- 기존 action CPU benchmark를 같은 격리 fixture에서 실행했다. 10종×NPC/용사 각 50 warm-up, 5회×2,000호출, 전후 순서 교대·중앙값의 동일 가중 평균: **6.376575→6.395600µs/호출 (+0.019025µs)**. 하위 어댑터를 포함한 합성 CPU 계측이며 실제 FPS/기기 성능 개선 주장은 하지 않는다. phase18 수치와 fixture가 달라 직접 비교하지 않는다.

재현:

```sh
python tools/build_hero_remaining_binding_fixture.py /tmp/remaining-binding-phase19 --baseline 70bc0765281ad4b7470856e0e191d2b6f7f52093
godot --headless --path /tmp/remaining-binding-phase19 --editor --import
godot --headless --path /tmp/remaining-binding-phase19 --script res://smoke.gd
cp tests/hero_action_binding_policy_smoke.gd /tmp/remaining-binding-phase19/action_regression.gd
godot --headless --path /tmp/remaining-binding-phase19 --script res://action_regression.gd
cp tests/hero_action_binding_policy_benchmark.gd /tmp/remaining-binding-phase19/benchmark.gd
godot --headless --path /tmp/remaining-binding-phase19 --script res://benchmark.gd
```

## 남은 비교의 처리

- 동일한 좁은 조사 패턴(351개 runtime script, 지정 변수 7개와 nonempty double-quoted ==/!=)은 **94→80곳**이다. `CONTENT_SELECTOR_INVENTORY_PHASE19_20261018.json`에 위치를, `CONTENT_SELECTOR_REVIEW_PHASE19_20261018.json`에 이번 해결 14곳과 보존 80곳을 기록했다.
- 기존 분류대로 소유권·진입 가드 54, AI 관측 구성 6, 고유 동작 재검토 20곳을 보존했다. 이 수치는 전체 하드코딩 수나 다음 작업 수가 아니다. 남은 조건이 영구적으로 데이터화 불가능하다는 뜻도 아니다.
- 19차의 검토 약속 14곳은 전부 마쳤다. 추가 차수를 자동으로 늘리지 않는다. 다음 우선순위는 실제 플레이 검증이며, 별도 레지스트리 성능 개선은 실제 병목 확인 후 범위를 정한다. 전체 하드코딩 감사/실제 플레이 완료를 선언하지 않는다.
