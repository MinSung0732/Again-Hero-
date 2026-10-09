# 시작 / 로딩 / Windows·Android 로그인

앱 기본 시작 씬은 `src/startup/Startup.tscn`입니다.

1. 터치 시작: 제공된 loadingscreen.png를 그대로 사용합니다. 로고를 중복 배치하지 않습니다.
2. 리소스 준비: 실제 공통 리소스, 소개 효과 30장과 로딩 8장을 비동기로 불러옵니다. 가짜 다운로드 용량/속도를 표시하지 않습니다.
3. 로그인 선택: 카카오·구글은 Windows/Android 기본 브라우저에서 실제 Supabase 인증을 진행합니다. Android APK는 인증 완료 후 게임으로 복귀하는 링크를 자동 시도하며 브라우저가 차단하면 '게임으로 돌아가기' 버튼을 표시합니다. PC는 인증 완료 시 게임 창을 다시 활성화합니다. 게스트는 기존 기기 로컬 저장으로 진입합니다.
4. 로비 진입: 목적지 UI/카드/상점/활성 등급 가챠 이미지 및 넘겨볼 수 있는 모든 스테이지 초상화를 미리 읽습니다. 초상화 알파 영역/크기 보정/최종 텍스처 생성/첫 렌더까지 전체화면 로딩 아래에서 완료한 뒤 로비를 표시합니다. 던전 프레임 전체를 미리 읽는 것은 아닙니다.
5. 던전 진입: 현재 용사 프레임·효과/초상화, 공통 UI, 몬스터 일반/엘리트 캐시, 터치 효과와 소개 효과의 실제 렌더 준비를 마친 뒤 소개 연출을 시작합니다.

## 미리 준비하는 범위

`PresentationWarmup`은 공통 소개 이미지와 현재 목적지/현재 스테이지의 자료를 강한 참조로 보존합니다. 다른 스테이지 전체를 메모리에 무제한 적재하지 않습니다. 로딩의 진행률은 실제 로더 및 완료된 준비 항목에서 계산합니다. 렌더 준비 구간에는 진행률을 90%에서 유지합니다.

소개/대화/용사/UI/가챠는 캐시 우선으로 사용하고 미등록 경로는 기존 로딩으로 안전하게 처리합니다. 필요 리소스 준비 실패가 전투를 막지 않도록 선택적 아트는 경고 후 기존 대체 표시를 유지합니다. 새 콘텐츠가 외부 이미지 경로를 추가하면 해당 카탈로그 또는 준비 목록을 갱신해야 합니다.

처음 사용하는 이미지 I/O와 준비 비용을 로딩으로 옮기는 것이며, 모든 기기의 모든 프레임에서 무조건 무렉을 보장하지는 않습니다. 남은 프레임 저하는 렌더/전투/메모리 등 별도 프로파일링 대상입니다.

## Windows OAuth 설정

기존 프로젝트 `xdmqpsyhtnyzzdhgvfep`를 사용합니다. 서버 공개 설정에서 Google/Kakao 활성화를 확인했습니다.

Supabase → Authentication → URL Configuration → Redirect URLs:

```text
http://127.0.0.1:43817/auth/callback/**
```

브라우저 로그인 후 이 PC에서 실행 중인 게임에 인증 결과를 돌려주기 위한 주소입니다. 정상 응답을 받으면 Windows는 게임 창 활성화를 시도하고 응답 페이지도 탭 닫기를 시도합니다. Windows의 포커스 도용 방지/브라우저 정책에 따라 탭이 남으면 직접 닫을 수 있습니다. 카카오/구글 개발자 콘솔의 Supabase 콜백 URL 및 기존 Site URL은 바꾸지 않습니다. wildcard는 Windows 테스트용 loopback 경로에만 한정하며 웹 서비스의 공개 wildcard를 추가하지 않습니다. 게임을 두 개 실행해 동일 포트를 사용 중이면 다른 창을 닫고 재시도합니다.

`windows_oauth.gd`는 PKCE S256의 랜덤 verifier와 무작위 복귀 경로를 생성합니다. 수신기는 127.0.0.1에만 바인딩하며 경로/Host/중복 쿼리/크기/대기 시간을 검사합니다. 인증 코드를 교환한 뒤 서버 `/auth/v1/user` 응답으로 UUID를 확인해야만 진입합니다. 게스트 전환/취소 이후 늦게 도착하는 응답은 무시합니다. 로그인 대기는 5분이며 HTTP 요청은 20초에 중단합니다.

공개 Publishable key만 사용합니다. secret/service_role/Client Secret, 인증 코드, 토큰은 저장소/로그에 기록하지 않습니다. Windows refresh token은 DPAPI로 암호화 보관하며 다음 실행의 시작 로딩 후 서버 검증으로 자동 로그인합니다. 계정 저장 복구가 끝나야 로비에 진입합니다. 상세 사항은 `CLOUD_SAVE_FLOW.md`를 참고합니다.

## Android Godot 편집기 실행 테스트 (2026-10-06)

프로젝트를 최신화하고 Godot 앱에서 실행 → 구글/카카오 버튼 → 기본 브라우저 인증 → 완료 페이지의 앱 복귀 시도(차단 시 '게임으로 돌아가기' 탭) → 게임 재개 후 인증 코드 교환·서버 사용자 확인·기존 계정 저장 복구가 진행됩니다. 다른 게임 실행 창은 닫아 동일한 loopback 포트의 중복 사용을 피하세요. 브라우저 쿠키/인증 정보가 유지돼 있으면 계정 선택이 생략될 수 있습니다.

Windows와 같은 PKCE/무작위 nonce/127.0.0.1 콜백 주소를 사용하므로 현재 PC에서 성공한 Redirect URL 설정을 그대로 사용합니다. Google/Kakao 개발자 콘솔의 Supabase HTTPS callback도 유지합니다. Google/Kakao의 네이티브 SDK나 앱 서명 키를 사용하는 흐름이 아닙니다.

Android가 외부 브라우저를 보여 주는 동안 scene processing이 멈출 수 있으므로 `android_oauth_listener.gd`가 로그인 중에만 별도 수신 스레드를 유지합니다. 소켓은 127.0.0.1에 한정, 8KB 요청/3초 연결/5분 로그인 제한과 Host·nonce 검사를 적용합니다. 스레드는 인증 응답만 반환하고 Node/계정/토큰을 건드리지 않습니다. 게임 복귀 후 main thread에서 기존 PKCE 교환 및 `/user` 검증을 수행합니다. 게스트 전환·취소·종료는 worker를 종료/join하며 이후 인증이 들어올 수 없습니다. 게임 프로세스가 OS에 의해 종료되어도 안전 저장된 세션이 있다면 다음 실행 시 재인증을 시도합니다.

Android 저장은 JavaClassWrapper를 통해 AndroidKeyStore에 생성한 AES/GCM 키로 refresh token을 암호화합니다. `user://android_session.keystore`에는 IV와 인증된 암호문만 저장하며, Android 밖에서는 Windows DPAPI를 사용합니다. 앱 재시작 시 저장된 refresh token으로 서버 세션을 갱신하고 `/user`에서 동일 계정을 확인한 뒤 기존 계정 클라우드 저장을 복원합니다. 자동 로그인 중 네트워크 또는 보안 저장소 문제 발생 시 로그인 UI로 복귀합니다. 로그아웃 및 명시적 게스트 전환 시 저장된 세션 파일을 삭제합니다. 편집기/기기별 JavaClassWrapper 및 KeyStore 오류는 안전하게 저장 실패 처리하며 평문으로 대체하지 않습니다.

**Android 앱 자동 복귀 APK 빌드 설정**: 프로젝트의 `addons/againhero_oauth` EditorPlugin을 활성화하고 **Android Gradle Build**를 사용해 APK를 내보내야 합니다. 플러그인은 `againhero://resume` VIEW/BROWSABLE intent-filter를 Activity manifest에 추가합니다. 게임의 브라우저 콜백 페이지는 자격 증명 없이 이 앱 복귀 주소를 호출하고, 권한 안내/브라우저 정책 때문에 차단될 수 있어 수동 복귀 링크도 표시합니다. 기존 127.0.0.1:43817 PKCE 수신기는 유지되며 OAuth 코드는 앱 링크로 전달하지 않습니다. **Android Godot 편집기 자체의 Manifest에는 이 필터가 없으므로 자동 복귀를 보장하지 않습니다.** Android Gradle 템플릿 설치 및 내보내기 Internet 권한 확인이 필요합니다. Chrome의 외부 앱 실행 정책에 따라 한 번 탭해야 할 수도 있습니다. APK에서 기기 잠금/재실행/Google·Kakao 각각 실제 검증이 필요합니다.

`tests/android_oauth_smoke.gd`: headless 엔진에서 scene process를 정지한 상태의 실제 loopback HTTP 응답, 잘못된 Host/nonce 거부, 복귀 후 PKCE·사용자 검증, 포트 재사용·취소/join·시간 초과·포트 충돌 검사. 실제 Android 브라우저/사람 계정 인증은 사용자의 기기에서 확인해야 합니다.

## 데이터 경계 / 아직 미구현

- 게스트는 Supabase 익명 계정이 아니며 기존 `user://*.cfg` 저장을 그대로 유지합니다.
- 실제 인증 계정은 `user://accounts/<검증된 UUID>/`에 진행/연구/몬스터/팀/스킬/소환내역을 분리합니다.
- 계정별 클라우드 snapshot 저장/복구, 충돌 선택, Windows 영구 세션/자동 로그인 및 기타→계정 로그아웃 UI가 연결되었습니다. 게스트 자료를 계정에 자동 덮어쓰기하지 않습니다.
- 계정 연결/게스트 가져오기는 후속 작업입니다. Android 실제 내보내기/복귀/Keystore는 실기기 검증이 필요합니다.
- 저장 소유권 RLS는 적용했지만 결제/재화/보상을 서버가 권위 있게 계산하는 기능은 아직 없습니다.

## 검증

```text
godot --headless --path . --script res://tests/startup_smoke.gd
godot --headless --path . --script res://tests/windows_oauth_smoke.gd
godot --headless --path . --script res://tests/android_oauth_smoke.gd
```

첫 검사는 실제 시작/리소스/게스트/로비/던전 전환과 캐시를 확인합니다. 두 번째는 실제 loopback HTTP의 잘못된 nonce/취소/idle 종료 및 전송 fixture를 사용한 토큰만으로 성공하지 않음·서버 사용자 확인·취소된 늦은 응답 차단을 검사합니다. 사람의 카카오·구글 계정을 자동 로그인하지 않습니다.

실제 렌더 캡처는 headless 없이 `-- --capture-dir=<존재하는 절대 폴더>`를 붙입니다. 실계정 로그인 성공과 모바일/APK 성능은 사용자/실기기 확인이 필요합니다.
