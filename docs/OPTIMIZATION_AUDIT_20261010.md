# Godot 4 최적화·코드 감사 보고서

기록의 앞부분 삭제, 이동·사망 셀의 누적, 피해 숫자의 매번 배열 복사, 로딩 경로의 선형 중복 검색을 개선했다. AI 결정식과 전투 수치는 유지했다. 저장 대기의 불필요한 프레임 재개와 잘못된 응답 처리도 보완했다. 변경한 프로덕션 파일 13개의 **전체 수정 전/후 코드**는 [before_after.zip](optimization/20261010/before_after.zip), 실제 적용 차이는 [changes.patch](optimization/20261010/changes.patch)에 있다.

이 보고서는 전체 파일의 정적 조사와 주요 경로의 실제 헤드리스 실행 결과다. 모든 조합의 완전한 정확성, Android FPS 또는 실기기 메모리 최소화를 보장하는 보고서는 아니다. 기존 전체 테스트 중 실패·시간 초과가 있으며 아래에 별도로 기록한다.

## 조사 기준과 보존한 게임 의미

- 작업 브랜치: `feature/stage10-astra`.
- 수정 전 main/작업 브랜치 SHA: `1d5ad4cedbadc72ea52c2c342946d75dcee96fe7`. 새 checkout에서 시작했다.
- 원격 롤백 기준: `backup/stage10-astra-before-optimization-20261010`. main은 변경하지 않았다.
- `AGENTS.md`, 개발 워크플로, PROJECT_CONTEXT, README, CHANGELOG, ROADMAP을 확인했다. 과거 디자인 제안보다 현재 세로 화면/전투 정책을 우선했다.
- tracked `src/**/*.gd` **287개, 91,126줄, 함수 선언 3,597개**를 목록화했다. [원본 파일별 조사 목록](optimization/20261010/baseline_inventory.json). 문자열 기반 수치는 주석·호환 fallback을 포함하므로 실제 프레임 호출 횟수와 다르다.
- 정적 후보: 그룹 조회 27곳, `pop_front` 10곳, `await` 151곳, `instantiate` 36곳, `queue_free` 93곳. 후보의 호출 경로·기존 캐시·풀·수명 처리를 확인하고 빈번하거나 누적되는 경로를 수정했다. 이 수치 자체를 문제 개수로 해석하면 안 된다.
- AI의 최근 관측, 현재 몬스터 구성, 빌드 관성, 성향, 난수 및 동점 처리 순서 유지. 완벽 최적 선택으로 바꾸지 않았다.
- 원본 상태이상 관측과 상태이상 행동별 성장 카운터는 서로 다른 책임이다. 이자나미/슈텐-도지의 동일 시전 1회 집계·소환 시 스냅샷 정책은 그대로다.
- 피해/쿨타임/사거리/해금/뽑기 확률/연출 프레임/음향/아이콘 데이터와 저장 스키마는 변경하지 않았다.

## 1. 성능 및 실행 속도 최적화

### 구현한 변경과 복잡도

E=살아 있는 최근 기록 수, k=이번 만료 기록 수, N=액터 수, C=활성 공간 셀 수, H=과거에 방문한 셀 수, P=로드 경로 수, D=후보 사전의 깊은 복사 크기, W=최고점 갱신 횟수다.

| 경로 | Before | After | 공간 사용/의미 |
|---|---|---|---|
| Hero 공세/상태, RunMetrics 소환 기록 만료 | 앞 삭제마다 suffix 이동. 대량 만료 O(E²) | head 이동·참조 제거, 지연 압축. 제거당 amortized O(1), 대량 O(E) | 양쪽 O(E). 새 구조는 null 슬롯을 일시 보유하며 압축 후 현재 기록만 유지. 최대 슬롯은 대략 2E+64 이하 |
| Battle/MonsterLocalGrid 공간 셀 | 빈 과거 셀을 계속 보유. O(H) Dictionary | 현재 셀만 보유, 빈 버킷 최대 128개 재사용 | O(C+128), 재구축은 O(N+C)로 유지. 이전 셀용 재사용 scratch 추가 |
| 늑대/유키온나 사망 이벤트 셀 | 처리 후 빈 과거 셀이 남음 | 처리 종료 시 빈 셀 제거/버킷 재사용 | 사망 위치 이력 대신 현재 배치+최대128개 버킷으로 제한 |
| 피해 숫자 풀 정리 | 호출마다 최대48개 배열 복사/메타데이터 재기록 | 정상 풀은 같은 배열 반환, 무효 suffix만 제자리 압축 | 시간 O(48)은 유지. 정상 경로의 별도 임시 배열 O(48)→O(1) |
| 로딩 경로 중복 제거 | `Array.has` 반복, O(P²) | Dictionary membership, expected O(P) | 일시적인 O(P) seen-map을 추가. 순서 유지. CPU와 공간의 명시적인 교환 |
| 증강 후보 선택 | 최고점 갱신 때마다 deep-copy, O(WD) | 참조로 비교한 뒤 최종 승자만 deep-copy, O(D) | 점수 계산 복잡도는 유지. 원본 후보는 수정하지 않고 반환값만 독립 복사 |
| cloud busy 대기 | 대기자마다 매 프레임 재개 | 완료/중단 신호에서만 재개 | 프레임 수에 비례한 재개 제거. 실제 RPC 수·저장 규칙은 유지 |

`TimedEventBuffer`는 만료 항목을 null로 바꾸어 내부 중첩 RefCounted 참조를 즉시 끊는다. head가 64 이상이며 전체의 절반 이상이면 남은 suffix를 앞쪽으로 옮기고 resize한다. 모든 기록이 만료되면 바로 clear한다. 오래된 슬롯을 무한정 보유하는 큐가 아니다. 타임스탬프가 추가 순서대로 증가한다는 기존 전제는 유지한다.

공간 버킷은 오래된 빈 셀만 회수한다. 사용 중 버킷/대상 순서를 바꾸지 않는다. 로컬 분리 계산의 48개 샘플 제한, 속도 기반 padding, 같은 프레임 revision 정책과 판정 필터는 유지했다. 단순히 Dictionary를 매 프레임 새로 만들거나 모든 몬스터를 각 공격마다 다시 검색하는 방식으로 바꾸지 않았다.

피해 숫자는 재사용된 팝업이 다른 대상의 오래된 메타데이터에도 남아 있을 수 있었다. 현재 소유 대상 ID와 삭제 예약 여부를 확인해 다른 몬스터의 숫자에 합산되는 버그를 수정했다. heal/damage 종류별 기존 합산 창과 최대 48개 상한은 유지한다.

### 실제 측정

| CPU 작업 | Before 중앙값(ms) | After 중앙값(ms) | 해당 미세 작업 개선 배수 |
|---|---:|---:|---:|
| `prune_1024` | 0.903 | 0.651 | 1.39× |
| `prune_8192` | 34.329 | 4.861 | 7.06× |
| `prune_32768` | 507.628 | 19.449 | 26.10× |
| `rolling_32768` | 48.387 | 34.919 | 1.39× |
| `dedupe_128` | 0.056 | 0.031 | 1.81× |
| `dedupe_1024` | 2.587 | 0.231 | 11.20× |
| `dedupe_4096` | 37.092 | 1.063 | 34.89× |
| `popup_pool_20000` | 112.376 | 56.074 | 2.00× |


측정은 **Godot 4.5.1 stable Linux headless/dummy display**, 워밍업 제외 **7회 중앙값**이다. 원시 samples/min/max/엔진 정보는 [benchmark.json](optimization/20261010/benchmark.json)에 있다. 최종 측정은 다른 Godot 테스트가 끝난 뒤 단독 실행했다. 기록 벤치는 항목 생성·추가·만료를 모두 포함하고, 경로 벤치는 합성 경로이며, 숫자 벤치는 48개 정상 풀의 정리 호출만 측정한다. 실제 전투 전체 시간·텍스처 업로드·GPU·발열·Android FPS로 환산하지 않는다.

최초 숫자 풀 수정안은 실제 벤치에서 원본보다 느려 폐기했다. 정상 배열은 검사 후 그대로 반환하는 경로로 수정하고 재측정했다. 코드가 짧아졌다는 이유로 빨라졌다고 판단하지 않았다.

### Async/Await 검토

GDScript에는 JavaScript Promise가 없고 await로 신호/코루틴을 기다린다. 저장 busy 대기는 `operation_released`로 바꿨다. 응답으로 revision/conflict를 적용한 **후** 대기자가 재개되도록 완료 신호를 deferred로 내보낸다. 즉시 신호를 내보내면 이전 revision으로 다음 저장을 시작할 수 있으므로 회귀 테스트로 순서를 고정했다. 중단 신호는 즉시 내보내 이전 계정 대기를 취소한다. 대기 전 계정/세대를 캡처하고 재개 후 다시 확인한다.

PresentationWarmup의 threaded request/batch/메인 스레드 예산과 프레임 yield는 유지했다. 이는 로딩 중 화면 응답과 GPU 업로드 분산을 위한 대기이므로 무조건 병렬 로딩이나 yield 삭제를 하지 않았다. 컷신의 tween·타이머 대기도 연출 시간의 의미가 있다. 이번 작업에서 이를 최적화 명목으로 제거하지 않았다.

### 메모리 누수·수명 조사

1. **실제로 수정한 누적:** 이동/사망 공간 Dictionary에 과거 빈 셀이 쌓이는 retention. 이동 비교에서 원본 384개 과거 셀을 새 구현은 활성3개+재사용3개로 제한했다. 사망256개 서로 다른 위치 처리 후 Dictionary가 비어 있고 버킷이 재사용됨을 확인했다.
2. **실제로 검증한 해제:** 만료 이벤트의 중첩 RefCounted가 압축 전에도 weakref에서 사라진다. 피해 숫자는 기존 풀 배열 identity를 유지하며 삭제된 노드를 제자리 제거한다.
3. **HTTP 요청 수명:** 일반 SupabaseClient에 timeout20초/body limit2MB/one-shot 완료 연결을 추가하고 완료·시작 실패 시 해제한다. CloudStore는 이미 같은 HTTP 상한이 있어 재사용했다. HTTP 객체를 임의 풀링하지 않았다.
4. **판단을 보류한 경고:** 기존 테스트의 `ObjectDB instances leaked`/종료 리소스 잔존은 실제 누수 후보다. static 캐시·fixture teardown·엔진 종료 순서도 원인일 수 있어 실전 장기 누수라고 단정하지 않았다. Android에서 전투↔로비 반복 및 RAM/노드 수 추이를 확인해야 한다.

### 남은 병목 후보와 이번에 유지한 이유

- HeroWorldQueryRuntime는 Battle registry와 프레임/revision 캐시를 이미 사용한다. 그룹 조회 중 일부는 고립 테스트 fallback이고, Battle의 마그넷/일시정지는 이벤트성 조회다. 전부 삭제하면 호환 씬과 일시정지 의미가 달라진다.
- 전역 최근접 목표 선택은 registry의 O(N) 순회가 남는다. 공간 nearest 확장은 후보 우선순위·동점 순서·은폐/상자 정책을 증명해야 하므로 다음 단계로 남겼다.
- 반경/직사각 그리드 쿼리는 탐색 셀 수에 비례한다. 넓은 범위는 후보 N이 작아도 많은 빈 셀을 방문한다. 프로파일 후 “셀 수가 N보다 큰 경우 registry 경로”를 검토하되 반환 순서를 보존해야 한다.
- RunMetrics 전략 가중치 합은 소환마다 O(E)다. 이번엔 만료 이동만 제거했다. 증분 가중치 합은 경계·실수 합 순서·전환 시각을 별도 검증한 뒤 적용하는 것이 안전하다.
- 정화 용사의 prism 연결처럼 모든 쌍이 실제 기술 의미인 O(K²)와 작은 연출 큐의 `pop_front`가 남는다. 알고리즘 차수만 보고 연결 수/피해/연출을 줄이지 않았다.
- Hero의 소환수/투사체/음향 등 기존 풀을 유지했다. 초기 생성과 풀 확장은 필요하다. instantiate 호출 문자열 수와 매 프레임 instantiate 수는 다르다.
- 새 헬퍼·바운드 큐는 메모리 상한과 임시 할당을 개선하지만 전체 게임의 최저 RAM을 달성했다고 말할 수 없다. static 텍스처 캐시의 적정 크기는 장치 측정 후 정한다.

## 2. 코드 구조 및 가독성 리팩토링

이번에는 반복되는 큐 수명과 공간 버킷 수명을 두 작은 RefCounted 헬퍼로 분리했다. Hero/RunMetrics는 관측·전략만 담당하고 삭제 비용을 공용 큐에 맡긴다. 네 개의 공간 소비자는 판정 정책을 유지하고 빈 버킷 수명만 공통화했다. 상속 체계와 데이터 ID를 불필요하게 확대하지 않았다.

| 큰 책임 | 원본 규모/함수 | 제안하는 분리 | 주의점 |
|---|---|---|---|
| `hero.gd` | 20,963줄, `configure_profile` 약696줄 | 기존 fighter/summoner/world-query runtime처럼 직업별 전투 runtime으로 이동, 공통 피격/상태/관측 인터페이스 분리 | 직업 하나씩, 동일 seed/입력 타임라인 비교 후 이동 |
| `battle.gd` | 5,734줄, `_spawn_monster` 약346줄 | 생성 설정과 registry/lifecycle, 전투 흐름/보상 책임 분리 | 소환 스냅샷·실제소환 해금·등록/해제 순서를 먼저 문서화 |
| `lobby.gd` | 5,436줄, HUD 설치 약384줄 | 편성/상점/도감 view-controller를 기존 runtime 패턴으로 분리 | 스크롤 위치·계정 변경·드래그 ownership 회귀 필요 |
| `main.gd` | 3,591줄, 상세정보 생성 약197줄 | 공용 스킬/스탯 표시 builder와 입력 흐름 분리 | 도감/편성/인게임의 같은 정보가 다른 정책을 갖는지 확인 |

함수 길이는 다음 함수 선언까지의 정적 span으로 주석/구분선을 포함한다. 큰 파일을 자동 분할하면 reflection/string call·animation callback·저장 ID가 깨질 수 있어 이번 패치에서 대규모 이동을 하지 않았다. 위는 미구현 후속 제안이다.

이름 제안: 문맥 없는 `data`는 `skill_definition`/`cue_definitions`, `authority`는 실제 역할에 따라 `battle_host`, `remaining`은 `remaining_lifetime_seconds`, `tick`은 `tick_remaining_seconds`로 명확히 할 수 있다. 데이터 키와 공개 callback 이름은 전역 치환하지 말고 호출자·저장 호환을 함께 확인한다. 새 헬퍼에는 `_head`, `previous_cells`, `spare_buckets`, `_session_generation`처럼 책임을 드러내는 이름과 복잡도/순서 이유 주석을 넣었다.

## 3. 보안 및 예외 처리 강화

### 구현한 방어

GDScript는 일반적인 try/catch를 제공하지 않는다. Godot API의 `Error`, null/타입 검사, 유효한 Node 검사, 코루틴 세대 검사로 실패 경로를 처리했다.

- 저장 ack/read의 revision은 존재하는 비음수 정수만 허용한다. JSON float는 정수값·유한값·정확한 정수 표현 범위를 검사한다. 누락/string/음수/소수/무한값을 거부해 로컬 dirty 상태가 잘못 지워지거나 dot 접근으로 실패하지 않도록 했다.
- read의 `found`도 bool인지 확인한다. 기존 payload 허용 목록/타입 검사를 유지했다.
- 로컬 선택 시 `SCOPE.persist()` 결과를 확인한다. 쓰기 실패를 성공으로 알리지 않는다.
- CloudStore/일반 SupabaseClient는 JSON parser의 Error를 확인한다. 잘못된 body는 기존 실패/재시도 또는 raw-body 계약으로 반환한다.
- 일반 SupabaseClient는 세션이 바뀐 뒤 도착한 응답을 현재 UI로 전달하지 않고 해제한다. transport failure는 HTTP 성공 상태로 취급하지 않고 status0/null로 전달한다.
- 일반 SupabaseClient는 현재 LoginGateway의 주 저장 transport와 별개다. 이 변경만으로 전체 로그인 구현을 새로 만들거나 실제 OAuth를 검증했다고 말하지 않는다.

### 키·인증·데이터 권한 조사

현재 tracked 텍스트에서 `sb_secret_`, private key, GitHub token, literal password/client_secret 패턴을 확인했고 해당 후보는 발견하지 않았다. [비밀값을 포함하지 않는 조사 결과](optimization/20261010/secret_scan.json). Git 전체 이력·바이너리·외부 서버·이미 폐기된 키까지 조사한 결과는 아니다.

Supabase 설정의 publishable key/프로젝트 URL은 클라이언트에서 사용할 공개 설정이다. 비밀번호나 service_role secret으로 잘못 분류하지 않았다. secret/service_role/서버 전용 키가 필요하면 클라이언트 코드·APK·Git에 넣지 말고 서버 환경변수로 관리해야 한다. 노출된 secret은 삭제만으로 끝내지 않고 회전해야 한다.

현재 snapshot SQL migration에는 auth.uid 기반 select/insert/update 소유권 RLS, authenticated 권한, SECURITY INVOKER/search_path 제한, revision CAS, payload 크기 제한이 있다. 원본 OAuth에는 PKCE/nonce/loopback host/크기·시간 제한, session vault에는 Windows DPAPI 및 Android 저장 경로가 있다. 구조를 유지했으며 실제 Windows/Android 인증 장치와 배포된 DB 정책은 이번 환경에서 확인하지 않았다.

**남은 중요한 보안 설계:** 자기 계정 snapshot 쓰기를 허용하는 RLS는 다른 계정 접근을 막지만 클라이언트의 재화/진행 조작을 막는 서버 권위 검증은 아니다. 유료 재화·순위·경쟁 기능을 출시하기 전 서버에서 보상/재화 변화의 허용 여부를 검증해야 한다. 이는 이번 성능 패치로 해결된 항목이 아니다. `account_tutorial`의 배포 서버 구현 전체도 저장소에서 확인할 수 없어 원자 보상 처리를 서버까지 감사했다고 말하지 않는다.

## 4. 실제 수정 전/후 전체 코드와 검증

### 전체 코드 제공

[before_after.zip](optimization/20261010/before_after.zip)은 아래 모든 프로덕션 파일의 `before/src/...`와 `after/src/...`를 담는다. 큰 Hero 파일도 생략 없는 전체 파일이다. 새 헬퍼는 Before에 존재하지 않으며 manifest에 명시했다. manifest의 SHA256으로 압축 파일 내용을 확인할 수 있다. [changes.patch](optimization/20261010/changes.patch)는 변경 이유 주석을 포함한 적용 가능한 전체 diff다. 프로젝트 에셋/씬은 기존 checkout을 사용한다.

| 파일 | 실제 변경 |
|---|---|
| `src/systems/timed_event_buffer.gd` | 신규 시간순 큐·즉시 참조 제거·지연 압축 |
| `src/systems/spatial_bucket_pool.gd` | 신규 빈 버킷 회수·최대128개 재사용 |
| `src/hero/hero.gd` | 관측 큐 교체/가중치 순회·불필요 keys 복사 제거 |
| `src/systems/run_metrics.gd` | 최근 소환 큐 교체·전략 순회 유지 |
| `src/ai/hero_build_ai.gd` | 최종 후보만 깊은 복사 |
| `src/battle/battle.gd` | coarse grid 과거 빈 셀 회수 |
| `src/systems/monster_local_grid.gd` | local grid 버킷 수명 제한 |
| `src/systems/wolf_pack_runtime.gd` | 사망 배치 셀 회수 |
| `src/systems/yuki_onna_runtime.gd` | 사망 배치 셀 회수 |
| `src/ui/damage_number_spawner.gd` | 정상 풀 무복사·소유대상/삭제예약 확인 |
| `src/systems/presentation_warmup.gd` | first occurrence 해시 중복 제거 |
| `src/network/cloud_store.gd` | 이벤트 대기·계정 경계·revision/read/저장 실패 검사 |
| `src/network/supabase_client.gd` | HTTP 상한/수명·세션 세대·JSON/transport 방어 |

대표적인 전체 함수 대비:

```gdscript
# Before: 만료마다 남아 있는 배열을 이동한다.
func _prune_recent_summons() -> void:
	var cutoff := elapsed_seconds - STRATEGY_WINDOW_SECONDS
	while not recent_summons.is_empty():
		var event: Dictionary = recent_summons[0]
		if float(event.get("time", 0.0)) >= cutoff:
			break
		recent_summons.pop_front()

# After: 공유 큐가 순서·경계를 보존하며 지연 압축한다.
func _prune_recent_summons() -> void:
	recent_summons.prune_before(elapsed_seconds - STRATEGY_WINDOW_SECONDS)
```

```gdscript
# After: 헤드 이동으로 만료 참조를 즉시 끊고 압축 비용을 분산한다.
func prune_before(cutoff: float) -> void:
	while _head < _events.size():
		if float(_events[_head].get("time", 0.0)) >= cutoff:
			break # 기존처럼 정확한 경계는 포함한다.
		_events[_head] = null
		_head += 1
	if is_empty():
		clear()
	elif _head >= COMPACT_MINIMUM and _head * 2 >= _events.size():
		var live_count := size()
		for index in range(live_count):
			_events[index] = _events[_head + index]
		_events.resize(live_count)
		_head = 0
```

### 검증 내용

- Godot4.5.1 실제 editor headless import/스크립트 파싱 및 `git diff --check` 통과. Python 도구 compile 검사 통과.
- 새 성능 회귀: 4,096개 큐, 경계/clear/중첩 참조 해제/보유 슬롯 상한; 실제 Hero 1,200개 관측의 가중치/횟수; AI100seed의 선택·근거·debug·다음난수와 deep-copy 독립성; RunMetrics3,000개 입력의 결과/전환시각; 24액터128회 이동의 원본 대비 대상/순서/분리·범위 일치; 사망256셀 회수; 숫자 풀 기존 오류 재현/수정/48개 제한.
- 새 네트워크 회귀: 가짜 RPC로 동시 flush 직렬화, ack 적용 후 대기 재개, 중단·늦은 ack 취소, malformed read/revision, stale 세션 response 해제, transport failure, 정상/잘못된 JSON 계약. 실제 서버 계정을 호출하거나 수정하지 않았다.
- 기존 cloud_save/슬라임 군집/늑대/유키온나/만티코어·슈텐·이자나미 전투/모바일 편성 드래그/도감/스킬 아이콘/시작 경로 등도 실제 헤드리스로 실행했다. 일부 정상 종료 테스트도 종료 리소스 경고를 출력했다.

전체 `*_smoke.gd` **118개** 실행: **종료 코드0 97개, 종료 코드1 13개, 시간 초과8개**. 코드0 중43개도 ERROR 진단(대부분 종료 리소스/더미 셰이더)을 출력했으므로 경고 없는 전체 성공이 아니다. 첫 넓은 실행은 기존 fixture의 공유 user-data를 사용했다. 실패21개는 Linux XDG 저장 폴더를 매 실행 분리해 원본/수정본 양쪽을 다시 실행했다(각20초 제한).

- 20개: 원본에서도 같은 실패/시간 초과 재현.
- `gacha_conversion_smoke`: 첫 실행의 “exact conversion once” 실패가 격리 재실행에서는 원본/수정본 모두 재현되지 않았다. 무시드 난수·fixture 정책을 검토해야 하며 해결됐다고 처리하지 않았다.
- 마지막 새 성능 회귀/새 네트워크 회귀/기존 cloud_save 3개는 격리 실행에서도 코드0·ERROR/WARNING0.

| 기존 검사 (`_smoke` 접미사 생략) | 격리 Before / After | 관측한 실패 또는 제한 |
|---|---|---|
| `monster_buff_scale` | timeout / timeout | 생성 결과 Nil에 set_physics_process |
| `loading_pipeline` | 1 / 1 | 기존 로딩 fixture fail flag; 단계별 texture 로그 보존 |
| `battle_summon_cinematic` | 1 / 1 | view/radial 재사용 기대값 |
| `battle_result_readability` | 1 / 1 | 균일 테두리 기대값, 빈 Tween |
| `bulgasal_presentation` | 1 / 1 | 초월별 cached view 개수 기대 |
| `collection_filter_shop_funds` | 1 / 1 | 목록 수/필터/기술 기대값 |
| `formation_card_presentation` | 1 / 1 | Zeus 원화 icon 기대(현재 도트 정책과 비교 필요) |
| `gacha_conversion` | 0 / 0 | 초기 랜덤 환산 합 실패, 격리 비교에서는 양쪽 통과 |
| `gacha_door_palette` | 1 / 1 | 빈 rarity opening 기대 |
| `mode_unlock` | timeout / timeout | StyleBoxTexture의 bg_color 접근 SCRIPT ERROR 후 미종료 |
| `monster_first_unlock` | 1 / 1 | 현재 common 해금 비용 기대 |
| `monster_upgrade_balance` | 1 / 1 | 비용/활성화 기대값 |
| `pickup_probability` | timeout / timeout | 현재 초월 분포와 다른 assert 후 미종료 |
| `pixel_panel_skin` | timeout / timeout | nine-patch 기대 및 Nil.texture 접근 후 미종료 |
| `player_prologue` | 1 / 1 | withdrawal 핸들러 기대 |
| `powwow_mummy` | timeout / timeout | 생성 결과 Nil에 set_physics_process/set_meta |
| `practice_presentation` | timeout / timeout | headless에서 무조건 frame_post_draw 대기 |
| `stamina` | 1 / 1 | 실제 lobby 입장/피드백/중복 입력 기대 |
| `support_shield_visual` | timeout / timeout | GPU 픽셀 검사, headless frame_post_draw 대기 |
| `test_forced_gacha` | timeout / timeout | 현재 초월 목록/확률과 다른 assert 후 미종료 |
| `transcendent_upgrade` | 1 / 1 | 초월 버튼 활성/상한 기대 |


원시 조사 결과/전체 진단/원본 비교는 [regression_summary.json](optimization/20261010/regression_summary.json)과 [검증 로그](optimization/20261010/regression_logs.zip)에 남긴다. 전체 suite의 exit0을 “모든 경고 없음”으로 계산하지 않았다. 실패한 기존 fixture를 삭제하거나 assert를 완화해 성공으로 만들지 않았다.

재실행:

```bash
godot --headless --path . --editor --quit
python3 tools/run_optimization_checks.py --godot godot --output /tmp/again-checks/results.json
godot --headless --path . --script res://tests/optimization_20261010_benchmark.gd
python3 tools/audit_gdscript.py --revision 1d5ad4cedbadc72ea52c2c342946d75dcee96fe7 --output /tmp/baseline_inventory.json
git diff --check
```

Godot 실행파일 이름이 `godot4`이면 명령을 그 이름으로 바꾼다. 테스트 runner는 Linux XDG_DATA_HOME/CONFIG_HOME을 실행마다 분리한다. 기본 목록은 이번 변경의 주요 경로이며 118개 전체 테스트를 뜻하지 않는다. 기존 fixture는 일부 headless 부적합 대기/오래된 콘텐츠 개수 기대값/무시드 난수를 포함한다.

## 5. 아침 Action Items와 롤백

1. **최우선 — 작업 브랜치 업데이트:** 로컬 변경이 있으면 먼저 보존한 뒤 `git fetch origin`, `git switch feature/stage10-astra`, `git pull --ff-only origin feature/stage10-astra`. 이번 변경을 main에 병합할 필요는 없다.
2. **실기기 회귀:** Android에서 편성 드래그/도감/스킬 아이콘과 실제 전투를 확인한다. 만티코어 사냥→후퇴, 지각분쇄, 슈텐19안개/폭발, 이자나미 상태행동 집계, stage10을 우선 본다. 이번 작업은 실기기 화면을 검증하지 않았다.
3. **성능 프로파일:** 같은 seed/설정에서 128/512/1,000 슬라임 및 안개/투사체 중첩 장면을 비교한다. 첫 로딩과 이후 전투를 나누고 physics/process CPU 시간, GPU frame, draw calls, 노드/객체 수, RAM을 5~10분 기록한다. 헤드리스 미세 벤치를 FPS 개선률로 사용하지 않는다.
4. **저장/인증:** 자신의 테스트 계정에서 저장→오프라인→재접속, 로그아웃→다른 계정 로그인, 저장 중 계정 전환, conflict 선택을 확인한다. 실제 Windows DPAPI/Android vault와 배포 서버 응답 형태를 확인한다. 현재 검증은 가짜 RPC/로컬 격리 데이터다.
5. **기존 검사 정리:** 아래 실패 목록을 현재 초월5종·최신 UI/확률 정책에 맞춰 검토한다. raw PNG fallback의 export 경고를 실제 Android export로 확인한다. headless에서 기다릴 수 없는 frame_post_draw와 assert 이후 무종료 fixture는 runner 제한과 구분한다.
6. **장기 구조/보안:** Hero runtime을 직업 하나씩 추출한다. 최근접/대형 범위 쿼리는 프로파일로 병목을 확인한 뒤 순서 보존 테스트와 함께 개선한다. 유료 재화/순위 도입 전 서버 권위 보상 검증을 별도 설계한다.

검토/되돌리기 가능한 변경 커밋:

- 성능·공용 수명 구조: `b9cc83a526b8d852867ef90d7945d54c69c7b975`.
- 저장/일반 HTTP 방어: `ca279f54b8dbe8bfee7984fd807c495c2e9aca5d`.
- 보고서/근거 묶음은 위 코드 커밋 뒤의 별도 문서 커밋이다. `git log -3 --oneline`으로 확인한다.

먼저 원본에서 비교만 하려면:

```bash
git fetch origin
git switch -c verify/pre-optimization origin/backup/stage10-astra-before-optimization-20261010
```

작업 브랜치에서 두 코드 변경을 실제로 되돌릴 때는 최신 코드부터 revert한다. 로컬 작업을 먼저 보존하고 실행한다.

```bash
git switch feature/stage10-astra
git revert ca279f54b8dbe8bfee7984fd807c495c2e9aca5d
git revert b9cc83a526b8d852867ef90d7945d54c69c7b975
git push origin feature/stage10-astra
```

후속 편집이 같은 부분을 수정했다면 revert에도 충돌이 생길 수 있다. 그 경우 원본과 현재 코드를 비교해 필요한 변경만 복구한다. 백업 브랜치는 이번 시작점의 정확한 파일/커밋을 보존한다.

패치 파일과 ZIP은 설명/검토용이다. 이미 Git 브랜치에 반영된 코드를 다시 덮어쓰거나 중복 적용하지 않는다. 다른 작업을 계속한 뒤 전체 브랜치를 과거로 hard-reset하지 말고 필요한 변경 커밋만 revert한다.

공식 근거: [Godot Array](https://docs.godotengine.org/en/stable/classes/class_array.html), [GDScript reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html), [Godot optimization](https://docs.godotengine.org/en/stable/tutorials/performance/general_optimization.html), [Godot FAQ](https://docs.godotengine.org/en/stable/about/faq.html), [Supabase API keys](https://supabase.com/docs/guides/api/api-keys).
