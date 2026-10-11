# 내부 구조 개선 — 3묶음 종료 체크포인트

기준: `feature/stage10-astra` / `701a74134cf3873605185343de69cc3180049644`.
`main`은 `4122adb73e14552aae7c0aa7edefb2827f5d08d0` 유지.
이번 체크포인트는 기존 마왕 솔플의 피해·상태 결과 경계를 정리하는 작업이다.
용사 플레이 모드, 본게임 매칭, 서버 권한 전투, 실서비스 동기화는 추가하지 않았다.

## 1묶음 — 남은 기술·투사체·적중 경계

기존 호출에는 직접 `apply_*`뿐 아니라 `call("apply_*")`도 있다.
호출자별로 같은 관찰 코드를 복제하는 대신, 실제 상태 적용을 소유한 수신 경계에
재사용 버퍼를 연결했다. 제우스·불가살·만티코어·일반/엘리트·투사체에서
용사의 기존 API를 호출해도 결과가 기록된다. 기존 호출자의 void/bool 반환값은 유지한다.
서큐버스/메두사의 적중 누적은 실제 매혹/석화 적용 시 기존 API 경계에서 기록되며,
아직 상태가 발동하지 않은 적중을 적용 성공으로 만들지 않는다.

| 경계 | 이번 연결 | 버퍼 소유 |
|---|---|---|
| Hero 구형 상태 API 13종 | 둔화·기절·침묵·공포·마비·석화·두 독 경로·출혈·화상·매혹·치유감소·받는피해증가 | Hero당 `legacy_status_receipt` 1개 |
| 불가살 고유 제어 | 기절·침묵, 5초월 정신집중 면역/취소 규칙 유지 | 불가살당 legacy 1개, opt-in 결과 API 제공 |
| 대마법 원소 상태 | 기존 화상·빙결 및 물리 처리 복구 유지 | 기존 원소 상태 컴포넌트당 1개 |
| 설녀 별도 둔화 | 별도 중첩/저항/눈꽃/메타 규칙 유지 | 기존 설녀 런타임당 1개 |
| 이자나미·슈텐도지 | 이전 단계의 명시적 결과 호출 유지 | 기존 caller-owned 버퍼 |

`tests/audit_status_receipt_boundaries.py`로 현재 지원 상태의 수신 함수 23개와
설녀 특수 경계를 감사했다. 직접/동적 호출 37줄, 15파일을 출력한다.
이 숫자는 스킬 개수나 런타임 실행 횟수가 아니다. 새 상태 종류를 추가할 때
감사의 `KINDS`/`EXPECTED`도 검토해야 하며, 정적 감사가 모든 대상 조합을 증명하지는 않는다.

## 2묶음 — 일반 상태 컴포넌트 결과

ReceivedAfflictions의 기존 화상/피해량 독/둔화/기절/침묵/현재HP 출혈 6종이
실제 적용 타이머·강도·예약 DOT 예산을 retained 컴포넌트 버퍼에 기록한다.
기존 4개 결과 adapter는 이제 generic 대상도 결과를 반환하며,
화상·피해량 독 결과 adapter 2개를 추가했다. native Hero/불가살은 opt-in API를 사용한다.
미지원 native/파생 대상은 구형 API를 한 번만 호출하고 결과 unavailable이다.

- legacy 적용/반환/저항/갱신/거절/physics/시각/틱 순서는 보존한다.
- 같은 상태의 갱신도 기존 규칙대로 수락될 수 있으며 새 디버프 개수라는 뜻은 아니다.
- DOT 예산은 예약 값이며 실제 HP 피해가 아니다. 대마법 화상은 tick당 피해를 강도로 기록하고 고정 총 예산을 추정하지 않는다.
- generic 출혈의 0초·최소예산1 등 기존 예외도 유지했다. 이를 native Hero와 통일하는 밸런스 변경은 하지 않았다.
- clear/reset과 generic early guard에서 오래된 결과 가용성을 무효화한다. early guard만으로 새 컴포넌트를 만들지 않는다.
- 새 매프레임 처리, 전체 그룹 스캔, 적용당 버퍼/배열 생성, 재적용 재시도를 넣지 않았다.

## 결과 사용 계약과 범위

`*_with_result`의 bool은 결과의 완성 여부다. 실제 수락은 `receipt.accepted`로 확인한다.
사용 후 버퍼를 참조로 저장하면 다음 호출이 덮어쓰므로 필요한 scalar만 복사해야 한다.
같은 버퍼로 중첩 호출하면 revision이 바뀌고 바깥 호출은 결과 unavailable이 된다.
상태는 이미 한 번 적용됐으므로 unavailable이라고 재시도하지 않는다.

수신측 legacy 캐시는 **그 수신 API의 마지막 실제 호출**이다. 다른 API/adapter가
선행 guard에서 종료한 경우까지 해당 캐시가 현재 호출의 결과라고 추정하지 않는다.
동기 호출 전후 revision, 가용성, victim ID/life를 확인하거나 caller-owned API를 사용한다.
명시적 결과 API는 caller 버퍼에 기록하므로 legacy 캐시와 별개다.
이번 변경은 결과 접근 경계이며 모든 결과를 영속 journal/네트워크로 송신하지 않는다.
기존 raw AI 관측·기술당1회 성장/해금 집계도 바꾸지 않았다.

각 적용의 관찰 추가 비용은 O(1) scalar 기록과 기존 entity registry 조회다.
버퍼 메모리는 해당 actor/component/runtime당 O(1)이다. 이는 비용 상한의 설명이며
FPS·로딩속도 개선 실측이나 전체 전투의 결정론 보장이 아니다.

## 3묶음 — 검증과 종료 기준

실제 사용한 엔진: Godot **4.5.1**, Linux headless. 저장소는 4.7 feature 표기를 사용한다.
전체 소스/에셋 archive를 받아 프로젝트 import 후 테스트를 실행했다.

| 검사 | 결과 / 의미 |
|---|---|
| 상태/호출 회귀 fixture 6개 | 100,596 assertions, 실패0; 실제 상태/호출 함수 slice, 전체 actor 초기화는 별도 |
| 새 전체 프로젝트 경계 통합 | 62 assertions, 실패0; 실제 Battle/Hero/Bulgasal/ReceivedAfflictions/원소/설녀 리소스 사용 |
| `status_action_growth_smoke.gd` | PASS; 실제 밴시 공격/중첩 거미줄/설녀 투사체·시전당 집계·소환 전 성장 스냅샷 |
| 제우스/불가살/만티코어/슈텐 통합 smoke | 4개 PASS; 각 테스트가 다루는 전투/수집/연출 경로에 한정 |
| 원래 gameplay body 비교 | 728함수 역변환 동일; 일반 결과 adapter 4개는 의도적 변경으로 동적 검증 |
| 정적 검사 | 수신 경계 감사, gdparse, Python compile, diff whitespace 검사 |

전체 프로젝트 테스트에는 기존 PNG fallback의 export 경고가 있다.
불가살 smoke는 셰이더 custom-sampler 오류 로그와 종료 시 Shape2D RID1개/resources4개
잔존 로그를 남긴다. 이번 5개 production 파일을 수정 전으로 되돌린 격리 프로젝트에서도
동일한 경고/오류 로그와 PASS를 확인했다. 이 테스트를 로그 오류0/누수0라고 보고하지 않는다.
이 기존 export/종료 정리 문제는 별도 수정 대상으로 남는다.

재현(전체 프로젝트 및 정상 import cache 필요):

```bash
python3 tests/audit_status_receipt_boundaries.py
python3 tests/verify_status_boundary_preservation.py --baseline-ref 701a74134cf3873605185343de69cc3180049644
godot --headless --editor --import --path .
godot --headless --path . --script res://tests/status_boundary_integration_smoke.gd
godot --headless --path . --script res://tests/status_action_growth_smoke.gd
godot --headless --path . --script res://tests/zeus_combat_smoke.gd
godot --headless --path . --script res://tests/bulgasal_integration_smoke.gd
godot --headless --path . --script res://tests/manticore_integration_smoke.gd
godot --headless --path . --script res://tests/shuten_doji_integration_smoke.gd
git diff --check
```

fixture 구축 명령과 기존 baseline SHA는 [SHUTEN_STATUS_CALLER.md](SHUTEN_STATUS_CALLER.md)의
재현 절차를 사용한다. 최신 `normalize_*`는 수신측 관찰 hook만 역변환한다.
Shuten generic 결과 지원으로 fixture assertion 수가 기존 단계의 12,159에서 12,142로 바뀌었다.
완료 정책을 잘못 가정하던 assertion을 교체했으며 실패를 숨기기 위해 제외하지 않았다.

## 이제 새 콘텐츠/UI 업데이트를 시작할 수 있는 범위

이 체크포인트로 1·2묶음 코드 연결과 3묶음 자동 검증/문서화를 종료한다.
추가 actor별 수신 결과 패치를 무한히 이어가지 않는다. 기존 마왕 솔플 위에 새 콘텐츠,
아이콘/UI/연출 업데이트를 작업할 수 있다. 출시/main 병합 전에는 아래 실기기 확인이 남는다.

1. 프로젝트 목표 엔진에서 PC 실제 화면으로 최초 입장·편성·재입장·일시정지/증강·승패/보상 확인.
2. 일반/엘리트/초월 소환과 마왕 포위 3종, 제어/DOT 중첩·불가살 채널면역·만티코어 생존·슈텐 부활 확인.
3. Android 실제 설치/첫 입장/장시간 전투/화면전환, FPS·메모리·로딩 실측. headless를 모바일 검증으로 부르지 않는다.
4. 실제 Android export에서 기존 PNG fallback과 불가살 셰이더/종료 정리 문제 확인 및 필요 시 별도 수정.

이 환경에서는 PC 그래픽 조작/청감·Android 실기기·전체 사용자 시나리오·성능 수치를 검증하지 않았다.
본게임 온라인 서비스는 추후 별도 설계/구현/검증이 필요하다. 현재 매칭 플레이가 가능한 것으로 표기하지 않는다.

롤백: 실제 GitHub 체크포인트 커밋을 `git revert <commit>`하여 5개 production 파일과 문서/검증 변경을 함께 되돌린다.
저장 데이터/스키마/에셋을 변경하지 않아 별도 save migration은 필요 없다.
