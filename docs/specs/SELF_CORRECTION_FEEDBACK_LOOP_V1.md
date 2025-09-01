# Self‑Correction Feedback Loop v1 (Distributed Agent Phase 1)

본 문서는 “분산 Agent v1(자기 색인 + 채팅)” 단계에서 최소 자기 보정(Feedback Loop)을 구현하기 위한 방법론/설계를 정의합니다. 목표는 결정론적·안전한 자동 수정 루프를 제공하는 것입니다.

## 1) 목적과 원칙
- 실패 신호를 표준화하여 수집하고, 증분 재색인·증거 주입·재시도·모델 전환·스키마 연결 제안을 자동화
- 전 과정은 추적 가능(JSON 메시지/메트릭/로그), 재현 가능(표준 스키마/아티팩트)
- JSON 응답 강제 및 인용 의무화(0‑hallucination)

## 2) 실패 신호(Signal)
- RAG 실패: insufficient_evidence, citation_missing
- 검색 미스: CBO evidence 0, vector hit 0
- 게이트 하락: IO Gate/Coverage 전일 대비 하락
- 사용자 피드백: thumbs_down + reason

## 3) 자동 액션(Action)
- 증분 재색인 index.file → import 체인 확장 시 index.module
- Evidence 주입: local_file 스니펫, params/returns/fields 요약을 vector_documents에 추가
- 프롬프트 재시도: 인용 강제 + JSON 스키마 검증, 모델 전환(sonnet↔haiku)
- 스키마 연결 제안: schema.link.suggest (승인 전까지 제안 상태)

## 4) 잡/큐(분산)
- Supabase jobs
  - index.file: { path }
  - index.module: { path, recursive: true }
  - evidence.inject: { id, kind, content }
  - schema.link.suggest: { code_symbol, schema_ref, reason }
- Orchestrator → Indexer/GraphRAG/ChatGateway가 비동기 소비

## 5) 저장 테이블(권장)
- feedback(chat_id, message_id, kind, reason, created_at)
- knowledge_gaps(topic, file, symbol, reason, created_at)
- fix_suggestions(action, target, details, status[pending|applied], created_at)

## 6) 표준 메시지(JSON)
- Envelope: docs/specs/MESSAGE_SCHEMA_V1.md 준수
- 예시
```json
{
  "id": "ulid",
  "type": "feedback.signal",
  "timestamp": "2025-08-11T12:00:00Z",
  "trace_id": "uuid",
  "payload": {
    "source": "chat|critic|gate",
    "session_id": "sess_...",
    "reason": "insufficient_evidence|citation_missing|io_gate_drop",
    "context": { "file": "src/knowledge/SupabaseVectorStore.ts", "symbol": "searchSimilar" }
  }
}
```

## 7) LangGraph 흐름(Phase 1 최소)
- Retrieve(vector/graph/schema 병렬) → Generate(상/중층 LLM) → Critique(근거/인용/계약) → Repair(재시도/모델스위치/증거보강) → Act(응답/잡 발행) → Learn(재색인/스키마 제안)

## 8) LLM 프롬프트 계약(JSON 전용)
- “Return only JSON. No prose.”, 스키마: docs/specs/LLM_RESPONSE_JSON_V1.md
- 검증 실패: 1) 수정 재프롬프트 2) 모델 전환 3) 실패 이벤트와 보정 액션 생성

## 9) 의사코드(핵심 루프)
```ts
if (!isValidJson(llmOutput)) retryWithFix();
if (insufficientEvidence || citationFail) {
  enqueue('index.file', { path });
  enqueue('evidence.inject', { id, kind: 'local_file', content: snippet });
  retryAskRagWithStrictCitation();
}
if (ioGateDrop) enqueue('index.module', { path, recursive: true });
```

## 10) 수락 기준
- 동일 질문 2회 내 개선(Insufficient → 인용 답변) 비율 상승
- 실패 케이스에서 index.file 자동 실행 후 성공까지 평균 1–2 루프
- 사용자의 thumbs_down 후 1분 내 개선 응답 또는 진행 알림

## 11) 운영 메트릭
- evidence hits by source(`/api/metrics/cbo/series`), IO Gate/coverage 스냅샷, feedback count, jobs 처리량/p95, 재시도율

---
Back to plan: [docs/DEVELOPMENT_EXECUTION_PLAN_NEXT.md](../DEVELOPMENT_EXECUTION_PLAN_NEXT.md)
