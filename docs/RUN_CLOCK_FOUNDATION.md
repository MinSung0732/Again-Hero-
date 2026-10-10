# 2단계 첫 작업 — Run 전투 시계 분리

앞 단계: `c02d96ccba5fa22e04634024243be486d5305c3e`의 증강 명령/후보 revision.
작업 브랜치: feature/stage10-astra. main 변경 없음.

## 적용 범위

RunMetrics가 직접 누적하던 전투 경과 시간을 `battle_run_clock.gd`로 옮겼다. 제한시간, 남은 시간, 소환/전략/증강 관찰 기록, 보상 계산은 기존 `RunMetrics.elapsed_seconds` 접근을 유지한다. 다른 소비자가 별도로 시간 값을 누적하지 않도록 getter가 동일한 시계 값을 반환한다.

| 항목 | 이번 동작 |
|---|---|
| 시계 생성 | RunMetrics마다 1개, reset 때 재생성하지 않음 |
| 진행 호출 | 기존 battle `_process`의 RUN_TIMER gate에서 `run_metrics.tick(delta)` |
| 일시정지/슬로우 | 기존 pause domain 및 전달 delta 그대로 |
| 초기화 | 기존 RunMetrics.reset에서 시계 경과 시간·진행 횟수 초기화 |
| 잘못된 delta | NaN/±INF/0/음수는 시계 진행 안 함 |
| 기록/제한시간/보상 | 기존 알고리즘·값·실행 순서 유지 |
| 진단 | `battle.get_run_clock_diagnostics()` 명시적 호출 시 Dictionary 생성 |
| 비용 | 호출당 O(1), 숫자 갱신·유한 값 검사만; 프레임마다 컨테이너/타이머 생성 없음 |

`advance_count`는 양수 delta를 누적한 호출 횟수다. 고정 simulation tick 또는 물리 프레임 ID가 아니다. 새 고정 tick, 전체 액터 공통 시계, 원격 스냅샷 시간, 서버 입력 큐를 구현했다고 해석하지 않는다.

현재 time_scale의 영향은 기존 `_process` delta를 그대로 따른다. 표시 시간과 전투 시간의 완전 분리, 대전의 개인 선택창/슬로우 정책은 후속 작업이다. 지휘력·마왕 runtime·경험치 자석·용사 공격/상태이상 시간을 이 시계로 일괄 대체하지 않았다. 각 도메인의 기존 의미를 검증한 뒤 이주해야 한다.

## 변경 코드와 이유

이전:

```gdscript
var elapsed_seconds: float = 0.0
func tick(delta: float) -> void:
	elapsed_seconds += maxf(delta, 0.0)
	_prune_recent_summons()
```

이후:

```gdscript
var run_clock = RUN_CLOCK.new()
var elapsed_seconds: float:
	get:
		return run_clock.elapsed_seconds
	set(value):
		run_clock.elapsed_seconds = value
func tick(delta: float) -> void:
	run_clock.advance(delta)
	_prune_recent_summons()
```

타이머를 UI/네트워크 코드마다 다시 작성하는 대신, 시간 누적 책임을 독립적으로 검사하고 이후 전투 driver를 연결할 위치를 확보한다. 현재는 성능 개선이나 로딩 개선을 주장하지 않는다. 숫자 필드만 있던 코드에 작은 객체 하나가 추가되므로 기능 분리를 위한 변경이다.

기존 writable elapsed_seconds API도 호환으로 유지했다. 이 setter는 로컬 디버그 호환이며, 검증 없는 네트워크 상태 입력이나 시계 rewind 용도로 사용하면 안 된다. 이후 서버 스냅샷 복원은 검증된 별도 경로에서 처리한다.

## 검증 범위

```bash
python3 tests/build_run_clock_fixture.py /tmp/run-clock-fixture
godot --headless --path /tmp/run-clock-fixture --script res://tests/run_clock_smoke.gd
```

전체 저장소 체크아웃에서 builder는 기준 커밋의 이전 RunMetrics, 현재 RunMetrics와 실제 timed_event_buffer/시계를 가져온다. 부분 소스 환경은 `--baseline-file`과 `--event-buffer-file`로 동일 SHA에서 가져온 파일을 지정한다. 테스트 양쪽의 카탈로그 표시 이름만 동일한 spy로 대체한다. 전략/메트릭/시간/보상 알고리즘을 stub으로 바꾸지 않는다.

Godot4.5.1 독립 fixture **1,236검사 통과**. 360개 delta 시퀀스에서 기존/신규 경과시간·남은 시간·제한시간, 전략 전환·최근 소환 만료·피해/관찰 기록, 결과 요약, 승리/패배 연구 보상 계산을 비교했다. NaN/INF 안전성, 자율 벽시계 진행 없음, 재시작 초기화, 정확한 전략 창 경계도 확인했다. 기존 battle `_process` 본문은 변경되지 않았음을 비교했다.

전체 Godot4.7 전투, 실제 몬스터 효과, 모바일·GPU 및 성능/첫 로딩 실측은 미검증이다. 독립 테스트가 통과해도 전체 판정 분리를 완료한 것으로 보지 않는다. 다음 큰 변경 전 전체 게임에서 증강·엘리트·튜토리얼·초월·pause/슬로우 회귀가 필요하다.

## 롤백과 다음 작업

이 시계 분리 커밋만 revert하면 앞 단계의 증강 명령화는 유지된다. 저장 schema·DB·밸런스 값은 변경하지 않았다.

다음 순서: (1) 엘리트/돌연변이 선택의 revision·명령화, (2) entity ID/generation 수명 계약, (3) 용사 AI와 플레이어가 공유할 action port, (4) 액터별 규칙 시간/취소 가능한 예약 이벤트 분리. 서버/PvP 활성화는 전체 전투 회귀·실기기 검증 뒤 별도 단계로 진행한다.
