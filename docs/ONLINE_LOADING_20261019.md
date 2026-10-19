# 역할별 온라인 매칭과 전장 준비 — 2026-10-19

## 화면

- 마왕: 어두운 보랏빛 소환 제단, 왕관과 전술서. 용사: 달빛 성문, 푸른 마력 지팡이와 마법서.
- 내장 image_gen으로 신규 생성한 불투명 배경2장을 원본 그대로 사용한다. 기존 캐릭터 이미지는 수정하지 않았다. 경로는 assets/art/UI/online_match/, 정확한 프롬프트는 SOURCE.md.
- 매칭 대기에는 역할별 그림/문구/색과 회전 아크/상승하는 픽셀 입자20개를 표시한다. 실제 PNG 프레임 애니메이션 시트가 아니라 생성 PNG와 Godot의 공통 draw 애니메이션이다. 텍스트는 한글 Label로 렌더링한다.
- 매칭되면 전장 준비 진행률을 실제 처리 항목 수로 표시한다. 한쪽만 끝나면 상대 준비 대기, 양쪽 ready 후 서버의 첫 양수 tick을 관측한 화면부터 전투를 표시한다. 클라이언트끼리 같은 렌더 프레임을 보장하지 않는다.
- 화면 전체 입력을 덮고 이동/소환/증강을 준비 동안 차단한다. 취소 버튼은 유지하며 결과/오류/계정·모드 변경/퇴장 때 화면과 이전 작업을 정리한다. 숨겨진 애니메이션은 중단하고 배경 텍스처 참조를 놓는다.

## 로딩과 경계

공유 Stage1Battlefield의 기존 동기 configure 경로는 유지한다. 온라인 표현 전용 경로는 텍스처별 threaded request와 프레임 yield, 기존 카펫 배경 제거 수식의 row 단위4ms 처리 예산을 사용한다. 배치/카펫 판별은 공유하고, 취소된 부분 텍스처 캐시는 다음 준비 시 처음부터 채운다. 중간에 UI가 리사이즈돼도 정적 prop 수집 전에 좌표계를 초기화한다. 취소된 ResourceLoader 요청은 기존 drain으로 회수한다.

마지막 정적 노드 구성·GPU 업로드와 서버 Battle 준비 전체를 별도 스레드로 옮긴 것은 아니다. 용사/몬스터/전투 효과의 나머지 PNG는 기존 비동기 mirror 로더를 유지한다. 이 화면의 진행률은 전장 준비 항목 기준이며 전체 게임의 모든 아트가 준비됐다는 의미는 아니다.

서버는 양쪽 준비 전 정기 snapshot을 보내지 않고 전투를 진행하지 않는다. 준비 중 명시적 취소는 무효, 시작 후 이탈은 기존 상대 승리다. 재접속/준비 제한·protocol4·전투/AI/스탯·보상은 유지한다. 서버/양쪽 클라이언트 함께 갱신한다.

## 검증

Godot4.5.1 헤드리스 격리 fixture. 새 loading63검사: 양쪽 역할의 실제 PNG, 대기/준비/첫 tick 전환, 로딩 동안 소켓·애니메이션 시계, 클라이언트 충돌 없음, 리사이즈 접지점, 같은 맵 재사용, 부분 로드 취소/재시도, 종료 취소, 준비 취소 무효. 기존 UI51/버튼48/lifecycle53/castle146/transport18/reconnect66와 합계445검사 PASS. 버튼 검사는 서버 running만이 아니라 실제 양쪽 로딩 완료를 기다리도록 변경했다.

별도 서버·양쪽 클라이언트3프로세스 동일 경기/승자·각29개 상태 수신 통과, 기존8.5초 cold-load 지연 회귀 통과. 생성 PNG2장의1024x1536/원본 SHA 일치·import와 git diff --check 통과. fixture는 다른 일부 누락 아트를 대체하므로 전체 아트 검증은 아니다. 실제 Windows4.7.2/Android/GPU/WSS·화면 애니메이션/프레임시간은 미검증이다. 새 화면 캡처를 실제 GPU로 검수했다고 주장하지 않는다.

재실행:

```sh
python tools/build_online_fixture.py /tmp/again-online-localtest --art-directory assets/art/UI/online_match
# 기존 원본 마왕성/온라인 PNG overlay도 유지한다.
godot --headless --editor --import --path /tmp/again-online-localtest --quit
godot --headless --path /tmp/again-online-localtest --script res://tests/online_loading_smoke.gd
```
