# LLM Response JSON Contract v1

분산 Agent v1 단계에서 모든 LLM 응답은 JSON 전용으로 강제합니다. 본 문서는 표준 스키마와 검증 규칙을 정의합니다.

## Envelope
- 상위 메시지 스펙: `docs/specs/MESSAGE_SCHEMA_V1.md`
- LLM 응답은 `payload` 안에 `response` 객체를 포함

## JSON 스키마 (operational)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "LLMResponseV1",
  "type": "object",
  "properties": {
    "intent": { "type": "string" },
    "answer": { "type": "string" },
    "actions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "type": { "type": "string" },
          "params": { "type": "object" }
        },
        "required": ["type"]
      }
    },
    "citations": {
      "type": "array",
      "items": {
        "oneOf": [
          { "type": "string" },
          {
            "type": "object",
            "properties": {
              "source": { "type": "string" },
              "uri": { "type": "string" },
              "start_line": { "type": "number" },
              "end_line": { "type": "number" }
            }
          }
        ]
      }
    },
    "confidence": { "type": "number", "minimum": 0, "maximum": 1 },
    "must_include_satisfied": { "type": "boolean" }
  },
  "required": ["intent", "answer", "citations", "confidence"]
}
```

## 프롬프트 규약
- “Return only JSON. No prose.”
- `intent`은 분류 태그(chat.ask|task.create|index.request 등)
- `citations`는 빈 배열 허용. 가능하면 코드 스니펫 범위를 제공(start_line/end_line)
- `must_include_satisfied`는 런타임 체크 결과를 반영(없다면 false)

## 검증 실패 처리
1) JSON 파싱 실패 → 수정 지시 재프롬프트
2) 스키마 검증 실패 → 누락 필드/형식 지정하여 재프롬프트
3) 재실패 → 모델 스위치 후 1회 재시도, 이후 실패 이벤트 기록 + 보정 액션 발행

---
Back to plan: [docs/DEVELOPMENT_EXECUTION_PLAN_NEXT.md](../DEVELOPMENT_EXECUTION_PLAN_NEXT.md)
