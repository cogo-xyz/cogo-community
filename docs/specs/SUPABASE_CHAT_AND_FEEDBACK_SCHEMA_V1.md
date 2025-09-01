# Supabase Chat & Feedback & Jobs Schema v1

분산 Agent v1에서 채팅, 피드백, 보정 루프 잡/큐를 위한 스키마 초안입니다.

## 1) 채팅 테이블
- chat_sessions(id uuid pk, tenant_id text, user_id text, created_at timestamptz, metadata jsonb)
- chat_messages(id uuid pk, session_id uuid fk, role text check in ('user','assistant','system','critic'), content jsonb, created_at timestamptz, citations jsonb, model text)
- 인덱스: chat_messages(session_id, created_at)

메시지 content는 `docs/specs/LLM_RESPONSE_JSON_V1.md` 응답 스키마를 따릅니다(assistant 메시지 기준).

## 2) 피드백 테이블
- feedback(id uuid pk, session_id uuid fk, message_id uuid fk, kind text, reason text, created_at timestamptz)
- kind 예: thumbs_up, thumbs_down, correction_request

## 3) 보정 루프용 큐(잡)
- jobs(id uuid pk, type text, status text, payload jsonb, created_at, updated_at, scheduled_at, attempts int)
- job_events(id uuid pk, job_id uuid fk, ts timestamptz, kind text, detail jsonb)
- 타입 예: index.file, index.module, evidence.inject, schema.link.suggest

## 4) 실시간 채널
- topic: `<tenant>.chat.<session_id>`
- 이벤트: message.created, feedback.created, job.created

## 5) RLS 요약
- 각 테이블은 `tenant_id` 또는 세션 소유자 기준 RLS 적용
- Edge Functions에서 JWT 검증 후 pub/sub 권한 위임

---
Back to plan: [docs/DEVELOPMENT_EXECUTION_PLAN_NEXT.md](../DEVELOPMENT_EXECUTION_PLAN_NEXT.md)
