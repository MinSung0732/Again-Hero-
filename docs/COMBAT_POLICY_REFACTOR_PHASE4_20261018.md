# 하드코딩 정리 4차: 공용 기본 투사체 — 2026-10-18

## 기준·선택 범위
- feature/stage10-astra 최신 `50c45b938694ddd8fa52d5bb3550bb54e356f69f`, origin/main `10c9805842d745412ffe9b45e822896001ef27cb` 확인 후 별도 clean worktree. main 병합 없음.
- 전투 전체를 한 번에 변경하지 않고 hero_projectile.gd의 반복된 용사 ID 기반 정책을 분리. 기본 투사체의 견습/정화 용사 정책과 나머지 ID의 원형 대체 표시가 이번 범위.
- 공격력/배수/거리/속도/타격 순서·반사·광역·다발 중복 방지·풀 반환·성장/EXP·AI 판단·보상·네트워크/저장 변경 없음.

## 구조
- hero_basic_projectile_catalog: 기존 초기값680/420/34, 상자 swept 판정 반경36, pool key,4+6+4 프레임 경로·순서·속도12/14/18fps·크기1/0.46, impact animation·holy multiplier method를 데이터로 관리.
- runtime에는 특정 hero ID 비교/프레임 경로 목록 없음. source_hero_id setter에서 변경된 ID의 immutable profile을1회 참조하고 impact/multiplier method만 저장. 같은 ID의 풀 재사용은 metadata를 다시 찾지 않으며 ID 변경/직접 대입은 즉시 캐시 갱신.
- 두 전용 SpriteFrames 캐시를 프로필별 공용 Dictionary로 일반화. 실제 등록된 두 프로필만 캐시, 불명 ID는 캐시를 늘리지 않음. 한 프로필의 SpriteFrames를 여러 투사체가 공유하는 기존 방식 유지. 피해 수치/배수 결과·source 객체·대상 HP는 캐시하지 않고 각 hit의 원래 시점에서 판독.
- setup/deactivate/이동·공간 조회/원본 PNG fallback/풀 반환 함수는 그대로. 새 매 프레임 배열/스캔/instantiate/free·O(n²) 루프 없음. 프레임 구성은 cold cache에서만 수행.

## 검증
- Godot4.5.1 실제 변경 전/후 스크립트와 동일 HeroProjectile.tscn으로 headless 격리 실행. before는 수정 전 SHA의 파일을 그대로 사용, scene의 script 참조만 교체. MonsterHitContext/ProjectileVolley도 실제 코드.
-300조합: hero4종(ID 없음/견습/정화/불명)×피해5×광역 반경3×배수5. 직접/광역 피해·반올림·최소값·조회/holy 호출 횟수·반사 호출·active/impact/physics/연출/scale·풀 반환 상태가 before/after 일치.
- 반사/상자 직접·sweep/사거리 종료, 피해 callback 후 변화한 holy 배수가 후속 광역에 적용, 직접 ID 대입·동일 volley 중복/다른 대상 허용, 프레임 수/속도·공유 cache, 정화→견습→불명 재사용 포함323검사 PASS.
- PNG가 전혀 없는 별도 프로젝트에서도 before/after 피격·원형 fallback·impact 미존재 즉시 풀 반환4검사 PASS. 합계327검사.
- 정적: lifecycle/query/movement 등11개 함수 본문 동일,14개 frame 경로와 순서 동일, runtime content ID 제거, git diff --check 및 두 fixture editor import/parse/실행 오류0.
- 테스트는 실제 Area2D/AnimatedSprite2D와 production hit/lifetime 메서드를 쓰며 피해 입력은 명시적 메서드 호출. Caster 공간조회/대상/풀 owner는 fixture, 그림은 placeholder. 실제 물리 접촉·전체 Battle/Hero AI/온라인·Android/GPU·15분 완주/청감/FPS는 미검증. FPS 개선율을 주장하지 않음.

## 재현
1. `git show 50c45b938694ddd8fa52d5bb3550bb54e356f69f:src/hero/hero_projectile.gd > /tmp/basic-projectile-before.gd`
2. `python tools/build_basic_projectile_policy_fixture.py /tmp/projectile-policy --baseline-file /tmp/basic-projectile-before.gd`
3. Godot editor import 후 `--headless --path /tmp/projectile-policy --script res://tests/basic_projectile_policy_smoke.gd` 실행.
4. 다른 새 fixture 경로에 `--without-art`로 생성하고 같은 script 실행 인자 뒤 `-- --missing-art`를 추가해 누락 asset fallback 확인.

## 남은 감사 후보
- Battle의 bomb_rat fuse/explosion·orc/skeleton 특수 소환/강화 분기.
- Hero의 archetype별 실행은 고유 게임 규칙과 연출이 섞여 있어 범위를 다시 나누어 비교해야 함.
- 기본 투사체의 source 미존재 시 몬스터 그룹 fallback 및 프레임별 chest 그룹 캐시는 이번에 그대로 보존. 향후 명시적 소유자/registry 전환은 여러 방·pool 재사용·source 교체 동등성 검증이 필요.
