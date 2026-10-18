# 계정 연동 후 성별 변경 1회 — 2026-10-17

## 적용
- 기준 branch feature/stage10-astra `1e1d695e388d33517f7bc5a974735eec475454c6`, origin/main `10c9805842d745412ffe9b45e822896001ef27cb`. main 병합 없음.
- 게스트 진행도를 계정에 연동하면 프로필에서 성별을 별도로 1회 변경. 기존 연동 계정에도 지급. 일반 직접 가입 계정/게스트에는 연동 혜택을 자동 지급하지 않음.
- 닉네임 변경권과 독립. 현재 성별 선택/취소/잘못된 값은 차감 없음. 성별이 확정되면 새 기본 마왕 외형/아바타/대화 초상화로 fallback. 다른 유효한 코스메틱 선택은 기존 보유/선택 규칙 유지.
- 클라이언트 profile_gender_catalog에 횟수/선택지/문구, 서버 private.profile_gender_policy에 검증 정책. UI는 프로필 버튼→성별 선택→되돌릴 수 없음 안내→변경 확정. 컷신·전투 타이밍 변경 없음.
- 서버 gender_changes_remaining/마지막 UUID·값을 행 잠금 안에서 갱신. 기존 계정·Auth session·활성 계정·device fence 검증 재사용. 재시도는 동일 UUID/성별로만 처리. 재연동/재로그인으로 충전되지 않으며, 계정 변경 뒤 늦게 온 응답은 로컬에 설치하지 않음.
- 서버 migration `20261017125551_linked_gender_reset` 배포 완료. public RPC는 security invoker, private에서 인증 후 쓰기. 익명 실행과 직접 UPDATE 차단 유지. 비밀키/매 프레임 처리 추가 없음.

## 검증
- migration 선적용 트랜잭션+전체 rollback: 기존 연동/일반 계정 backfill 2검사, 이름/성별·재전송·재연동·세션/기기 fence·익명/직접 쓰기 방지 83검사 통과. 배포 후 동일 83검사 통과. 테스트 계정/저장은 rollback.
- Godot 4.5.1 headless 격리 프로젝트: 성별 실제 프로필 UI/확정/취소/실패 재시도/계정 전환/외형 fallback 17검사, 기존 이름 입력132, RPC 재시도10, 실제 HTTP/복원34, 모바일 키보드 레이아웃 smoke 통과. 공유 저장 폴더 충돌 방지를 위해 최종 검증은 순차 실행.
- editor import/parse 및 git diff --check 통과. 격리 테스트는 실제 스크립트를 사용하고 누락 artwork/Auth는 fixture로 대체. Windows/Android 실기 OAuth·터치·전체 원본 아트 화면은 미검증.
- Supabase security advisors 변경 전후 동일: private 내부 테이블 RLS 무정책 INFO5와 기존 leaked password protection WARN1. 새 경고 없음. 기존 비밀번호 경고: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection
