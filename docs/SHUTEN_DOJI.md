# 슈텐-도지

`feature/stage10-astra`, 기준 cffdd61e. 본체/스킬1~4/5초월/해금/뽑기/프로필/도감/편성 연결. 구현 수치는 `shuten_doji_behavior_catalog.gd`, 설명은 `transcendent_detail_catalog.gd`에 있다.

## 전투 정책

- 소환 전 아군이 용사에게 성공적으로 상태이상을 적용한 공격·기술 시전 수를 N으로 확정한다. 공격220+N, 최대HP2500+N; 이후 성장하지 않는다. 복수 상태/다중 장판/반복 갱신/다발 투사체는 동일 시전1회. 해금 상태이상3회도 이 카운터를 사용한다.
- 혈주연무 12개를2초 동안 지름600 안에 고르게 분산. 각 지름200,5~10초,총 공격100% 지속피해. 본인 외 아군 포함. 겹친 안개마다 피해를 받지만 자기방어/둔화/초월1쉴드는 겹침배수로 증폭하지 않는다.
- 귀염지폭은 모든 잔여 안개시간 합10초 이하에서 우선 판단한다. 한 폭발 행동에서 모든 안개 발화. 각 지름300/175%,7초간 현재HP6% 출혈, 이미 출혈하면2초기절. 출혈은 해당 폭발 피해 후 HP 스냅샷, 중첩/갱신 없음. 안개당1기술CD2초 반환.
- 혈주연무의 각 활성 안개는 실제 판정 반경100(지름200)의 얇은 붉은 원형선을 연기 위에 표시한다. 수명 종료 깜박임을 함께 적용하며 만료/발화 시 제거한다. 추가 노드/텍스처/매프레임 배열 할당 없음.
- 사슬 초기생성01~03→03/04유지, 도달06~08결박.3초 총250% DOT·99%둔화/침묵, 이후10초 면역.10~19/20~29/30~40초 도달시60초 기준20/30/40% 반환. 초월3은 항상50%. 대상 사망/비활성화 시 슬롯 회수.
- 귀왕해방은 죽음03→02→01 역재생 이후 effect4의01→02,3초 무적/최대HP100% 분할 회복. 강화 공격03~08에는 본체가 포함되어 기본 본체를 숨겨 이중 표시를 피하고 같은 발바닥 위치/좌우 방향을 사용한다. 공격 완료 후15초 반감안개는 피해/둔화/자기피감·쉴드 강도50%, 범위는 유지한다. 적중 쿨1초/잃은HP1%회복,20적중 기절2.5초. 초월4해방후피감30%/20적중쉴드5%,초월5체력50%발동/초과회복쉴드.
- 미지정 튜닝: 근접70, 사슬40/s, 획득거리600, 최대비행40초. 기본공격6프레임0.6초 후 간격2초. 등장1.25초 느린 걸음. 코드 한 곳에서 조정 가능.

## 성능

64안개·64폭발·4사슬 고정 배열을 계속 재사용. 각 효과는 Draw 기반, 반복 scene 생성/삭제 없음. 텍스처팩과 SFX는 캐시/고정 음성. 대상 질의0.2초 간격 공간 그리드/레지스트리, 대상별 분할피해 소수 캐시는 최초 접촉에만 만들고 약참조로 정리한다. 상태 성장 행동/면역 기록도 주기적으로 만료시킨다.

## 연출과 리소스

기존 `assets/art/Transcendent_monster/Shuten-doji` 원화/도트/일러스트/icon/banner, 기존 `assets/art/Icon/monster/Transcendent/shuten-doji` 기술 아이콘을 사용한다. 원본ZIP의 가시 파츠 중 머리카락/금봉끈/술병/코트자락/허리술6마스크를 추출해 고정 얼굴·손·다리를 유지하는 native Skeleton2D/Polygon2D 공유 메시를 만든다. Cubism 파일/완전한 숨은면 리깅은 아니다.

새 파일 `assets/art/effects/gatcha/shuten_doji/sake_hall_v1.png`: 붉은 달, 낡은 술전당/등롱/술항아리, 중앙 비어있는 바닥, 붉은 요기. 캐릭터/글자 없는 세로 배경. `rig_v1/closed_eyes_v1.png`: 원본 재조합 이미지를 참조한 눈감음 표정. 전체 몸체로 대체하지 않고 shader의 두 눈 영역만 사용한다. `manifest.json`에 실제 사용 마스크와 출처를 적었다.

생성 프롬프트 요지:

1. “Vertical fantasy pixel-art background for Shuten-doji, abandoned Japanese sake hall, crimson lanterns, red moon, blood-sake mist and chain accents, empty central stage, matching existing dark fantasy pixel character, no people, no lettering.”
2. “Edit referenced original Shuten-doji image to close both eyes in a calm, confident expression; preserve the original character, pose, outfit, weapon, gourds and transparent canvas. Only the eyelids should change.” 결과의 몸체 재해석 부분은 사용하지 않는다.

뽑기: 실루엣/연속 파츠 움직임→안개/사슬/귀화 공개→슈텐-도지 이름. 기존 보상 확정 후 재생, 별도 조각 지급 없음. 전투: 삼각형 전신/눈감음/얼굴줌/눈뜸/전신복귀,5초 실제시간, 본체 중심6방향 술안개/사슬 집결/발화. 시각효과에 추가 타격 판정 없음. 실제 등장 본체는 느리게 걸어나오며 붉은 외형을 유지한다.

기존 프로젝트의 라이선스/편집 기록이 있는 이자나미·불가살·만티코어 PCM을 재사용한다. 원본 출처는 각 `assets/audio/sfx/{izanami,bulgasal,manticore}` 자료. 귀염지폭은 안개 묶음1음성만, 각 주요 행동1음성/반복 제한, 음량-13~-23dB, 자연 기본피치. 새 Pixabay 다운로드/실제 청취는 수행하지 않았다.

F6 예시: `src/dev/shuten_doji_cutscene_preview.tscn`, `src/dev/shuten_doji_battle_summon_preview.tscn`. 합성 결과 표시만 하고 재화/계정 보상을 쓰지 않는다.

## 검증

Godot4.5.1 헤드리스 import와 `tests/shuten_doji_{combat,integration,cutscene,battle_summon}_smoke.gd`. 실제40제어형소환과3용사상태, 실제뽑기/조각/프로필/5강화/편성/소환/공통사망·15EXP스톤 확인. 피해 합/기술 비용/시간 환급/면역/부활/초과회복과 아군 상태 컴포넌트 검증. 메시121시점 가중치합/삼각형 무접힘/화면경계, 다중뽑기3개 순서·스킵/취소/재사용·4화면비, 카메라/시간복원·중단6종 확인. 만티코어·이자나미·도감/기술아이콘 회귀.

기존 결과프레임 shader headless compiler 경고, 종료 리소스 경고가 남는다. GPU 캡처·모바일/export·실제청취/실기기 성능은 미검증.
