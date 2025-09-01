## Message Schema v1 (Events & Inter-Agent Requests)

Purpose
- Standardize message envelope for events and inter-agent communications to enable tracing, retries, and evolution.

Envelope
```json
{
  "id": "ulid",
  "version": 1,
  "type": "job_started | job_failed | request | response | heartbeat | metric",
  "ts": "ISO-8601",
  "trace_id": "uuid",
  "correlation_id": "uuid",
  "cause": "parent_message_id | null",
  "tenant_id": "string",
  "actor": {
    "agent": "cogo-...",
    "role": "orchestrator | executor | worker | critic | router"
  },
  "payload": { "...": "domain-specific" },
  "schema": {
    "namespace": "cogo.v1",
    "name": "JobStarted | InterAgentRequest | ...",
    "hash": "sha256-of-jsonschema"
  }
}
```

Conventions
- `id` is unique and immutable; use ULID for sortable IDs.
- `trace_id` spans a request; `correlation_id` ties request/response or related events.
- `cause` links causal parent (optional) for lineage.
- `version` enables additive evolution; never break old fields.

Validation & Storage
- JSON Schema per `schema.name`; store `schema.hash` for integrity.
- Persist envelope fields in primary table; `payload` stored as JSONB.

Retry & Delivery
- Messages are at-least-once; consumers must be idempotent (use `id` or explicit `idempotency_key`).
- Ordering is best-effort within a stream; rely on `ts` and `cause` for reconstruction.

Security
- Include `tenant_id`; enforce RLS by tenant.
- Sanitize payloads; avoid secrets in plaintext; use key-vault for secret material.

Acceptance Checklist
- Envelope implemented consistently across events and inter-agent RPCs.
- JSON Schema registry exists with versioned definitions.
- Tracing confirmed in logs/metrics with `trace_id` and `correlation_id` visible.

## Message Schema v1

Canonical event/request envelope for inter‑agent communication.

Fields (required unless noted)
- `id`: string (ULID/UUID)
- `version`: string (e.g., "1.0")
- `type`: string (event type)
- `correlation_id`: string (ties related events/requests)
- `cause`: string (parent id / causal reference) – optional
- `tenant`: string – optional
- `timestamp`: ISO 8601 string
- `payload`: object – domain specific
- `citations`: array of objects – optional (for RAG/traceability)

JSON Schema (draft)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "MessageV1",
  "type": "object",
  "properties": {
    "id": { "type": "string" },
    "version": { "type": "string" },
    "type": { "type": "string" },
    "correlation_id": { "type": "string" },
    "cause": { "type": ["string", "null"] },
    "tenant": { "type": ["string", "null"] },
    "timestamp": { "type": "string", "format": "date-time" },
    "payload": { "type": "object" },
    "citations": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "source": { "type": "string" },
          "uri": { "type": "string" },
          "snippet": { "type": "string" }
        },
        "required": ["source"]
      }
    }
  },
  "required": ["id", "version", "type", "correlation_id", "timestamp", "payload"]
}
```

Conventions
- Channel naming: `<tenant>.<type_prefix>.<agent>.<topic>`
- All events carry `correlation_id`; requests include a unique `id` and reference parent via `cause` when applicable.

