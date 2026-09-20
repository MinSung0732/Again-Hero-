# AGENTS.md

이 저장소를 수정하는 AI/코딩 에이전트는 작업 전에 반드시 다음 파일을 읽는다.

1. `PROJECT_CONTEXT.md`
2. `README.md`
3. `docs/ROADMAP.md`
4. `CHANGELOG.md`

핵심 규칙:
- 게임명은 **「용사, 또 너야? / Again, Hero?」**.
- Godot 4.x + GDScript 기반 모바일 게임.
- 핵심은 **AI 용사의 빌드를 관찰 → 유도 → 카운터**하는 역뱀서라이크 구조.
- 핵심 재미 검증 전에 불필요하게 시스템/콘텐츠를 크게 확장하지 않는다.
- 중요한 설계 결정이 바뀌면 `PROJECT_CONTEXT.md`도 함께 갱신한다.

- 기능 추가, 패치, 개선, 제거, 밸런스 변경이 발생하면 작업 완료 전에 반드시 `CHANGELOG.md`를 갱신한다.
