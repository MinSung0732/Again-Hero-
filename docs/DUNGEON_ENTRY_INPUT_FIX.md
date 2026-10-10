# 던전 입장 입력·안내 수정

2026-10-10. 작업 feature/stage10-astra, 기준93a653a958b5cc8a649a46879cc359a4531fd3fb. main4122adb73e14552aae7c0aa7edefb2827f5d08d0 유지.

## 사용자 증상과 확인 범위

던전 입장 클릭 시 경고 문구 없는 스테미너 설명창이 보이고 입장되지 않는다고 보고했다. 사용자 화면/계정 상태를 직접 실행한 것은 아니다. 소스에서 상세창은 비모달 설명카드라고 명시하지만 MOUSE_FILTER_STOP이라 겹치는 버튼을 차단한다. 독립 GUI에서 실제 기존 카드 위에 입장 버튼을 배치한 뒤 mouse motion/press/release로 이 차단을 재현했다. 별도로 편성 제한도 show_info를 사용하여 관련 없는 스테미너 설명에 실패 사유를 섞는 경로를 확인했다. 사용자 화면의 정확한 겹침/계정 원인이 확정되었다고 주장하지 않는다.

## 변경

- 설명 PanelContainer를 MOUSE_FILTER_IGNORE로 설정. 설명 라벨과 내부 column은 이미 IGNORE다. 설명은 읽기 전용이며 겹친 던전 버튼 등 실제 GUI가 클릭을 받는다.
- _enter_selected_stage 진입 시 기존 상세창 닫기. 기존 pending gate는 그대로 유지.
- 편성/스테미너/저장 실패는 전용 AcceptDialog에 원래 안내문 표시. 하나만 lazy 생성하고 반복 재사용한다. 제목은 던전 입장 안내다.
- 헤더 스테미너 직접 클릭/hover, +상점, ESC와 외부 터치 닫기는 유지한다. 입장 제한을 우회하거나 스테미너를 새로 지급하지 않는다.

## 검증

Godot4.5.1 headless 독립 fixture38검사 실패0. 전체 stamina view를 실제 로드하고 카드 및 전용 안내창을 생성한다. 이미지 스타일·재화 read_state는 spy이며 UI window 크기는1080x1920으로 명시한다. 입력 검사는 GUI에 실제 InputEventMouseMotion/MouseButton을 push_input한다. 기존 STOP의 button press0, 신규 IGNORE의 press1을 비교한다. 터치는 외부 닫기 handler를 직접 호출한다. 던전 씬 실제 전환은 포함하지 않는다.

추출한 실제 _enter_selected_stage로 정상, 몬스터/마왕 스킬/둘 다 부족, 스테미너 부족, 저장 실패, 테스트 면제, 이중 진입을 검사한다. 정책은 실제 dungeon_entry_policy, 저장/면제 상태/전환/비용 연출은 spy다. 실제 lobby의 모든 원래 함수는 검토한 상세창 닫기/안내 함수 교체 외 동일함을 확인한다. gdparse/Python compile/diff --check 및 독립 editor import 통과. 전체 사용자 로비, 모바일/실물리, 실제 저장/스테미너 소비/던전 로딩은 미검증이다.

```sh
git show 93a653a958b5cc8a649a46879cc359a4531fd3fb:src/lobby/lobby.gd > /tmp/lobby-entry-before.gd
git show 93a653a958b5cc8a649a46879cc359a4531fd3fb:src/ui/lobby_stamina_view.gd > /tmp/stamina-entry-before.gd
python3 tests/build_dungeon_entry_input_fixture.py /tmp/dungeon-entry-input-fixture --lobby-baseline /tmp/lobby-entry-before.gd --view-baseline /tmp/stamina-entry-before.gd
godot --headless --path /tmp/dungeon-entry-input-fixture --script tests/dungeon_entry_input_smoke.gd
```

thin checkout에는 --policy-file로 원격 원본 dungeon_entry_policy.gd의 위치를 줄 수 있다.

## 확인할 사항과 롤백

pull 후 헤더 상세를 연 상태와 닫은 상태에서 던전 입장을 확인한다. 입장이 제한되면 새 안내창의 원문 사유를 기준으로 편성/스테미너/저장 상태를 확인한다. 별도 잘못된 header hitbox/로컬 수정/신호 연결은 전체 UI 실행에서 확인해야 한다. 이 단계 커밋을 git revert하면 이전 상세카드/안내 경로로 복원한다. 이전 전투 수명 단계는 유지된다. 사용자 요청에 따라 지연 스킬 후속 구현은 잠시 멈췄다.
