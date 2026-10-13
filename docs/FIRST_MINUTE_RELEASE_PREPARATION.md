# 첫 1분 전략 안내 / Android 출시 준비 — 2026-10-13

## 플레이에서 바뀌는 것

| 실제 상태 | 안내와 행동 |
|---|---|
| 첫 소환 전 | 마왕의 목표는 용사 HP 0. 실제 자동/수동 모드에 맞는 조작 안내 |
| 첫 성공 소환 | 몬스터 역할과 용사의 처치→성장 관계 설명 |
| 용사 증강 선택 | 실제 선택명과 후보 태그를 사용. 편성된 대응 역할 카드를 금색으로 표시 |
| 지휘력 부족 / 인구 가득 | 회복 중인 지휘력·다음 공세를 기다릴 이유 표시 |
| 다른 몬스터를 실제 소환 | 공세 변경을 확인하고 실제10초 HP피해 관찰. 효과가 좋아졌다고 단정하지 않음 |
| 패배 | 실제 소환/주력전환/마지막 용사증강과 다음 실험 제안 |

튜토리얼 순서·체크포인트·스킵·소환보상·스테미너를 변경하지 않았다. 추가 강제 모달, AI 선택 강제, 적 약화, 무료 소환, 자동 편성은 없다. 안내는 제안이며 필승 전략이 아니다. 다수 몬스터가 제공하는 EXP와 용사의 성장 관계를 첫 안내부터 설명한다.

실제 선택 후보의 tags를 우선해 스테이지 전용 증강도 공통 태그로 안내한다. 대상을 현재편성으로 제한하며 없는 몬스터를 추천하지 않는다. 기존 Catalog 역할을 사용한다. 성공 소환 신호로만 안내 단계를 진행하며 실패 소환·저장·재화는 건드리지 않는다. 모드 변경 때 안내를 즉시 갱신한다. 기본 HUD의 두 줄을 재사용하며 상세창이 열리면 숨긴다는 직전 패치를 유지한다.

연산은 소환/선택 이벤트와 기존1초 피해 샘플 주기에 묶인다. 카드는 추천 ID가 바뀔 때만 색을 갱신한다. 3개 편성 후보만 비교하며 전장 개체·그룹·투사체를 스캔하지 않는다. 기존 고정21샘플 피해 버퍼를 유지한다.

## 검증 범위

- 수정 GDScript 10개를 gdtoolkit gdparse로 구문 검사, git diff --check.
- tests/first_minute_strategy_smoke.gd에23개 assertion: 실제 자동/수동 안내, 무편성 회복, 유효소환, 성장 설명, 실제 선택태그, 보유카드만 추천, 지휘력/인구, 공세 변경과 가짜 성공 구분, 10초 피해, 재시작, 결과 기록. 기존 캠페인 모델/HUD 기대값 갱신.
- Godot 실행파일이 없으며 GitHub release 바이너리 다운로드도 네트워크 타임아웃. 이번 전략/HUD 테스트는 실행하지 못했다. 구문 검사를 엔진 컴파일/런타임·사람의 이해도 검증으로 취급하지 않는다.
- 기존10초 피해/보상/계정/튜토리얼 검사 전체 재실행, 실제 모바일 폰트/겹침/터치·GPU·성능·청취는 남아 있다.

## Android 배포 설정

새 export_presets.cfg의 Android Release는 Gradle AAB·targetSdk36·ARM64·버전0.1.0/code1·패키지com.minsung.againhero. 테스트/개발문서/SQL 등을 배포에서 제외한다. 앱 인증에 필요한 기존 OAuth export plugin은 project.godot에서 유지한다. API36 기준 출처: https://developer.android.com/google/play/requirements/target-sdk (2026-10-13 확인).

패키지/서명은 영구 배포 식별자다. 이미 Play Console에 등록된 앱이나 Google Android OAuth 클라이언트가 있으면 그 패키지와 서명을 사용해야 하며 versionCode도 기존 업로드보다 커야 한다. 이번 preset은 저장소에 기존 preset이 없어서 만든 시작 구성이다. 기존 등록 여부나 OAuth 일치는 검증되지 않았다.

서명 키를 새로 만들거나 기존 키를 바꾸지 않는다. 비밀은 Git에 넣지 않는다. Godot의 GODOT_ANDROID_KEYSTORE_RELEASE_PATH / GODOT_ANDROID_KEYSTORE_RELEASE_USER / GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD 환경변수를 사용한다. 출처: https://docs.godotengine.org/en/4.4/classes/class_editorexportplatformandroid.html

release 빌드는 localtest/normaltest/tutorialtest 개발자 쿠폰을 실행하지 않으며 테스트 marker를 복원하지 않는다. debug 빌드/Editor 개발검증은 유지한다. 일반 계정/저장파일을 삭제하지 않는다.

실행 명령:

```sh
python tools/check_android_release.py
godot --headless --path . --script res://tests/first_minute_strategy_smoke.gd
godot --headless --path . --script res://tests/campaign_experience_smoke.gd
godot --headless --path . --script res://tests/campaign_hud_smoke.gd
godot --headless --path . --export-release 'Android Release' exports/again-hero.aab
```

Godot Android build template와 SDK/JDK 설치, 서명자격이 필요하다. 현재 구성 점검은 서명자격·build template·엔진 부족으로 BLOCKED. API36을 적는 것만으로 APK/AAB의 최종 manifest/네이티브16KB 지원이 검증되지는 않는다. 최종 서명 AAB, 실기기 로그인·백그라운드/복귀·저장실패, 터치, 안정성, 사람의1분 이해도, 개인정보/데이터안전/등급/해당계정 필수테스트·Play Console 심사를 완료해야 등록 가능 판단을 내릴 수 있다.

## 다음 실행의 통과 기준

신규 사용자가60초 안에 (1) 마왕이 몬스터를 소환한다 (2) 용사는 몬스터 처치로 성장한다 (3) 용사의 선택을 보고 다른 몬스터를 시험한다를 설명하고, 관찰창의 선택 또는 역할을 근거로 직접 공세를 바꾸는지 관측한다. 안내 문구를 읽었다는 사실만으로 전략 이해/재도전 의향을 인정하지 않는다. 측정 결과는 아직 없다.

롤백은 이번 변경 커밋 revert. 지급/저장 스키마를 변경하지 않았으므로 지급 보상을 회수할 필요는 없다. 출시 상태는 준비 중이며 완료로 표시하지 않는다.
