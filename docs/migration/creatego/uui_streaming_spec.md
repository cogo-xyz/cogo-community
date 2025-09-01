### UUI Streaming Spec (Draft)

Message Types
- pageChunk: full fragment payload
- pagePatch: JSON Patch (RFC 6902) or Merge Patch (RFC 7386)
  - JSON Patch utility: src/ast/uuis/utils/JsonPatch.ts

Fields
- pageId (string), fragmentId? (string), seq (int), total (int), contentHash (string), parentHash? (string)
- deps?: string[] (other required fragments), meta?: object
- payload: { chunk?: object, patch?: object }

Client Behavior
- Validate seq/total, apply chunk or patch, verify contentHash
- Build registry for fragments by id; store meta.hash for later verification
- Re-render only changed subtrees (guided by subtree __hash)
 - Metrics: cogo_ui_fragment_hash_check_total{status=ok|mismatch}
 - Enforce mode: UUI_ENFORCE_FRAGMENT_HASH=true → mismatch 시 안전 대체 노드 삽입

Transport
- SSE/WS/Realtime channel; NDJSON or framed JSON messages

Fragment Registry Hints
- fragments: inline registry { id: UiNode }
- fragmentsMeta: { id: { hash } }
- fragmentsUrl: string (absolute/repo-relative/http(s))
  - Loader env: UUI_FRAGMENT_LOADER_TTL_MS, UUI_FRAGMENT_LOADER_MAX_ENTRIES
  - HTTP opts: UUI_FRAGMENT_HTTP_TIMEOUT_MS, UUI_FRAGMENT_BREAKER_THRESHOLD, UUI_FRAGMENT_BREAKER_COOLDOWN_MS
  - Security: UUI_FRAGMENT_ALLOWED_HOSTS="example.com,cdn.example.com" (allowlist), UUI_FRAGMENT_ALLOW_FILE=false (default)
  - Mirrors/Retry: UUI_FRAGMENT_MIRRORS, UUI_FRAGMENT_HTTP_RETRY, UUI_FRAGMENT_HTTP_RETRY_DELAY_MS
  - Offline cache: artifacts/uui/fragment-cache (auto read/write), metric result=cache
  - Version pin: UUI_FRAGMENT_REGISTRY_VERSION (캐시 키에 버전 포함)


