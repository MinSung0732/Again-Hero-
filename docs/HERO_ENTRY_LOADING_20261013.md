# 용사 첫 던전 입장 로딩 준비 — 2026-10-13

기준: feature/stage10-astra f6bd0a05b54c16b3881b491734c38f767506b48c. main은 변경하지 않는다.

## 원인과 수정

PresentationWarmup.prepare_scene는 로비와 마왕 Main만 준비하고 HeroMode는 그대로 반환했다. HeroMode._ready가 선택 용사/무기 효과와 풀을 동기 생성한 뒤 즉시 전투를 시작했고 Battle의 몬스터 normal/elite 준비는 deferred로 겹쳤다. 따라서 초기 전투와 첫 리소스 준비가 동시에 실행됐다.

SceneTransition에서 소모 전 입장 옵션을 warmup에 전달한다. 선택 용사의 profile.sprite_frame_dir/스프라이트시트, 전용 6종 effect_dir, 공통 레벨업/높이기준/성/전투 UI를 기존 배치·4ms 메인스레드 예산으로 준비한다. 모든 용사 프레임을 미리 읽는 구조는 아니다. HeroWeaponArt.sequence는 PresentationWarmup의 텍스처를 먼저 사용해 raw PNG 폴백에서도 중복 디코딩/업로드를 피한다.

HeroMode는 UI와 입장 검증/receipt claim 이후 전투 생성을 지연한다. prepare_presentation 훅 안에서 리소스 → 실제 Battle/무기풀·고유기믹·BGM → prepare_spawn_resources → 레이아웃 프레임 순서로 준비한다. 생성 직후 external_pause로 용사 물리를 정지하며 mode._process/AI마왕·이동패드는 아직 시작하지 않는다. 기존 로딩 화면은 훅 완료까지 유지되고 transition_completed 이후 전투와 입력을 1회 시작한다. 15분 시계와 조기퇴장 환불용 실제시각 모두 로딩 시간을 제외한다.

편집기 직접씬 실행에는 로컬 CanvasLayer 로딩 화면을 제공하고 같은 훅을 사용한다. 직접씬 실행 역시 기존의 유효한 입장기록이 필요하며 이미 claim된 기록으로 중복 입장할 수 없다. prepare 훅은 재진입/중복 호출을 직렬화하고 완료 이후 다시 풀을 만들지 않는다. UI/무기/성장/피해/몬스터수치·마왕 Main의 흐름은 유지한다.

## 실제 검증

Godot 4.7.2 stable 전체 프로젝트 headless 실행:

| 회귀 | 결과 |
| --- | --- |
| hero_loading_gate_smoke.gd | 350 검사 PASS; 실제로딩703프레임/몬스터준비71프레임 관측 |
| hero_mode_startup_smoke.gd | 42 PASS; 직접씬 로딩/입장·증강·룰렛·정지/재개 |
| hero_survival_revision_smoke.gd | 344 PASS |
| hero_presentation_range_smoke.gd | 943 PASS |
| hero_weapon_growth_smoke.gd | 1479 PASS |
| hero_survival_identity_smoke.gd | 182 PASS |
| local_test_hero_unlock_smoke.gd | 45 PASS |

실제 선택은 sage_astra/전장stage_1로 두어 캠페인/기본용사와 독립된 옵션 전달을 확인했다. 로딩 중 entry_ready=false, 이동불가, mode._process 정지, 용사물리정지, 시계0초/몬스터0명, 환불시각 미시작을 확인했다. 몬스터 준비 완료 후 오버레이 해제/AI 소환·시계 재개, 보통 일시정지 유지, 선택무기 텍스처 재사용/동일킷 재준비 로딩횟수 불변, 중복 claim 차단을 확인했다. 로딩프레임 기반 검사수와 프레임수는 실행환경에 따라 변하며 성능 개선 퍼센트/FPS 수치가 아니다.

실행:

```sh
godot --headless --path . --script tests/hero_loading_gate_smoke.gd
godot --headless --path . --script tests/hero_mode_startup_smoke.gd
```

기존 PNG raw 폴백/export 경고와 일부 회귀 종료리소스 경고는 남아 있다. 이번 검증은 실제 로딩/전투 게이트와 리소스 재사용에 대한 엔진 실행이다. 실제화면/첫 GPU 셰이더 컴파일, Android 실기기 입장 체감·FPS·메모리, 오디오 청감/export 및15분 완주는 확인하지 않았다. 준비 작업 자체의 비용을 없앤 것은 아니며, 전투와 겹치지 않도록 로딩 화면 안으로 이동했다.
