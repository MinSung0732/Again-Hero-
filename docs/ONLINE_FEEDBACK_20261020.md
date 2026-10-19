# 온라인 피격·회복·공통 도형 효과·기존 SFX — 2026-10-20

## 연결

사용자는 Windows 로컬2인 실행에서 역할별 로딩/맵/전투/거미 투사체가 정상이라고 확인했다. 이번 단계는 실제 서버의 피해·회복 피드백과 남은 공통 도형 표시, 기존 효과음 연결이다.

- DamageNumberSpawner의 실제 표시 요청을 merge/풀 한도 이전에 관측한다. 피해를 다시 계산하거나 HP 차이를 추측하지 않는다. 용사의 숫자는 기존과 같이 방어막 흡수분을 포함할 수 있으므로 전부 HP 손실이라고 해석하지 않는다. 기존 popup 풀/merge/난수는 유지한다.
- Battle의 온라인 전용 signal→Room 고정32개 이벤트 슬롯. 용사 피격8개를 별도 예약해 몬스터 다중 타격으로 전부 밀리지 않게 한다. 회복·소환·실제 기본 공격 cue를 포함한다. 이벤트 번호·tick·위치·량·색만 보내며 Node나 리소스를 네트워크로 보내지 않는다.
- 클라이언트는 고정32슬롯의 피격/소환 링과 떠오르는 숫자를 Canvas draw로 처리한다. 공격 cue에는 숫자나 가짜 투사체를 생성하지 않는다. 고정 AudioStreamPlayer5개와 공유 EventSfxBank를 사용한다. 게임의 SFX bus 음량·뮤트/앱 pause와 기존 cue gain·피격650ms 최소 간격을 따른다.
- 이벤트 high-water cursor를 상태에 포함하고, matched/resume 시 서버의 최신 cursor로 baseline을 잡는다. 동일/이전 이벤트는 재생하지 않는다.0.6초보다 오래된 이벤트는 생략한다. 로딩/연결 일시정지 중에는 소리를 재생하지 않고, pause/취소/오류/계정·모드 전환/퇴장 시 정리한다. 결과 cue는1회, 무효는 승패음 없음.
- 공통 장판, beam/slash/capsule polygon·윤곽선, chain/combo/bolt line, orbit 링/PNG 없는 orb fallback을 원본 effect 상태에서 샘플링한다. 최대24개 일반 도형 명령과70개 좌표값/명령. 기존 geometry/색·폭 상수를 공유하고, 클라이언트 점 배열은10Hz snapshot 수신 때만 만든다. 기존 PNG 아래 도형을 그리며 판정/충돌을 만들지 않는다.

## 원본 음원

신규 다운로드/합성/바이너리 변경 없음. 이미 저장소에 있는 아래5개를 그대로 연결했다. 기존 출처/라이선스 기록을 유지한다.

- assets/audio/sfx/contextual/mage_hit.wav
- assets/audio/sfx/stage1_mage_v4_basic.wav
- assets/audio/sfx/interface/summon.wav
- assets/audio/sfx/contextual/victory.wav
- assets/audio/sfx/contextual/defeat.wav

기본 공격 cue 선택은 online_feedback_catalog의 archetype 정책으로 관리한다. 현재 온라인 룰의 견습마도사만 등록하며 다른 용사의 기술음을 임의로 모두 같은 소리로 대체하지 않는다. 모든 몬스터별 고유 사망음·개별 특수기, 사망 잔상·각성/모든 고유 VFX까지 연결했다는 의미는 아니다.

## 검증과 한계

Godot4.5.1 headless 격리 fixture에서 새61검사: 실제 몬스터 피해/용사 피격/회복, 실제 기본 공격→cue, 원본 stream 재생 시작/SFX bus, 반복10회 중복 억제, 복귀 baseline, pause 중 누적 재생 방지·오래된 이벤트·잘못된 payload, 용사 우선 슬롯/포화 한도,8종 도형/원본 polygon 일치·전처리, 결과1회·rematch 정리·PNG drain을 검증했다.

기존 UI51/버튼48/로딩63/lifecycle53/transport18/reconnect66/PNG155/로스터35/전투44/마왕성146=679검사, 솔로 공급456, 새61 합계1196검사 PASS. 별도3프로세스 동일 경기/승자·양쪽29상태 수신과8.5초 cold-load 지연 회귀 통과.3프로세스 종료 검사는 서버 자식을 명시적으로 해제하고 callback이 정리된 뒤 종료하도록 했다. 최종 ERROR0, fixture의 다른 누락 아트 경고는 남아 있다.

원본 WAV5개는 저장소 blob과 fixture 바이트 일치를 확인했고 실제 import·AudioStreamPlayer 재생 시작을 실행했다. 실제 스피커로 청취하거나 Windows/Android/GPU/WSS 화면을 검수한 것은 아니다. 대표128PNG+24개 capsule polygon/outline+이벤트 포화 payload53951bytes, 기존98304byte 예산 이내. 최악의 모든 데이터 조합/실기 FPS·RAM/네트워크 지연 개선율은 측정하지 않았다. 용량 초과 시 기존 서버 snapshot 예산 경계가 적용된다.

프로토콜은5. 최신 feature/stage10-astra를 서버/양쪽 게임에 함께 적용하고 서버를 재시작한다. 기존15초 복귀 유예/20초 준비 제한과 전투/AI/스탯·보상·계정 데이터는 유지한다. main은 변경하지 않는다.

실기에서는 맞을 때 숫자/링, 회복 숫자, 소환/마법 공격/피격/승패음, SFX 뮤트, 연결 끊기→복귀 후 과거 소리 미재생을 확인한다.
