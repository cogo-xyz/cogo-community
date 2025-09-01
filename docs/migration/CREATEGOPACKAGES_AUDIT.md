

## CREATEGO-PACKAGES Source Analysis & COGO Migration Plan

**Purpose**: Migrate CreateGo packages to COGO standards with 1:1 mapping, identify adapter points, mitigate risks and secrets exposure.

**Analysis Date**: 2025-08-31
**Source Location**: /Users/hyunsuklee/Desktop/Dev/cogo-project/creatego-knowledge-base/working/implementations/creatego-io/creatego-packages
**Project Type**: Flutter Package (Dart/Flutter)
**Analysis Scope**: Complete source code audit

---

### 1) System Overview

| Aspect | Details | COGO Alignment |
|--------|---------|----------------|
| Package Structure | Flutter package with src/ organization<br>- lib/src/api/<br>- lib/src/supabase/<br>- lib/src/websocket/<br>- lib/src/realtime/<br>- lib/src/auth/<br>- lib/src/config/<br>- lib/src/utils/<br>- lib/src/models/ | cogo-packages (SoT, versioned) |
| Responsibilities | - Supabase client management<br>- Real-time subscriptions<br>- WebSocket connections<br>- Authentication handling<br>- API request abstraction<br>- JSON utilities<br>- UI model definitions | SDK wrappers, Realtime helpers, artifact handlers |
| Data Flow | 1. Auth → Supabase client init<br>2. API calls → HTTP requests<br>3. Real-time → Postgres Changes subscriptions<br>4. WebSocket → Custom WebSocket clients<br>5. Storage → Direct Supabase storage operations | streamOrRealtime, presign→ingest→result |
| Dependencies | - supabase_flutter: ^1.10.25<br>- http: ^1.1.0<br>- web_socket_channel: ^2.4.0<br>- json_annotation: ^4.8.1<br>- shared_preferences: ^2.2.2 | Supabase, pgvector, Neo4j |
| Build/Release | Flutter pub publish<br>Dart pub get/pub upgrade<br>No custom build scripts found | Release dir + symlink, no --delete |

**Key Findings**:
- Core modules: API, Supabase, WebSocket, Realtime, Auth, Config
- Tight coupling between modules (direct imports)
- No existing RAG or LLM integration
- Custom WebSocket implementation (not Supabase Realtime)
- Postgres Changes for real-time (not broadcast channels)

---

### 2) API/Event Surface

| Component | HTTP/SSE Calls | Realtime Usage | COGO Standard |
|-----------|----------------|----------------|----------------|
| api/base_api.dart | Custom HTTP client<br>Methods: GET, POST, PUT, DELETE<br>Headers: Authorization, Content-Type | None | @cogo-chat-sdk-ts<br>Bearer + apikey headers |
| websocket/websocket_client.dart | WebSocket connections<br>Custom protocol handling<br>Message parsing/encoding | None | streamOrRealtime<br>queued/handoff handoff |
| realtime/realtime_client.dart | None | Postgres Changes subscriptions<br>Custom channel management<br>Event filtering | trace:{traceId} broadcast<br>Supabase Realtime broadcast |
| supabase/supabase_client.dart | Supabase REST API calls<br>Auth integration<br>Storage operations | Postgres Changes | @cogo-chat-sdk-ts<br>Realtime broadcast |

**Migration Points**:
- Replace custom HTTP client with @cogo-chat-sdk-ts
- Replace WebSocket with streamOrRealtime for SSE
- Replace Postgres Changes with trace:{traceId} broadcast channels
- Standardize auth headers (Bearer + apikey)

---

### 3) Storage/Artifacts Regulation

| Usage | Current Contract | Transformation | COGO Standard |
|-------|-------------------|---------------|----------------|
| supabase_storage.dart | Direct Supabase storage operations<br>Upload/download files<br>Bucket management | No transformation needed | {bucket, key, signedUrl} (key relative) |
| File uploads | Direct upload to Supabase storage | Add presign support | signedUrl for download |
| Large files | No special handling | Add chunking logic | presign→PUT→ingest→result |

**Risks**:
- Direct storage access may expose credentials
- No signed URL support for secure downloads
- File size limits may cause issues

---

### 4) Schema/Types

| Schema | Input | Output | COGO Mapping |
|--------|-------|--------|--------------|
| UI JSON | ui_model.dart<br>Custom UI structure<br>Tree-based layout | JSON serialization | Zod schemas in packages/schemas |
| API Models | Custom model classes<br>JSON annotations | API responses | compat endpoints |
| Auth Models | User authentication data<br>JWT tokens | Auth state | Supabase auth integration |
| Config Models | Environment configuration<br>API endpoints | App config | Centralized config management |

**Type Safety**:
- Uses json_annotation for serialization
- Custom model classes for type safety
- No runtime validation beyond basic JSON parsing

---

### 5) Dependencies/Environment

| Category | Current | COGO Standard | Migration |
|----------|---------|----------------|-----------|
| Supabase | supabase_flutter: ^1.10.25<br>Direct client usage | Latest version<br>Standard auth patterns | Update version + standardize usage |
| Env Keys | Custom config system<br>No standardized env vars | SUPABASE_*, COGO_*<br>Centralized management | Migrate to platform-core |
| Secrets | Hard-coded in code?<br>Config files | Edge env only<br>No code exposure | Security audit required |
| Permissions | Custom auth logic | require-admin, rate limit | Add governance checks |
| Build | Flutter pub commands | Node/Flutter workspaces | pnpm/turbo integration |

**Security Audit**:
- Check for hard-coded secrets in config files
- Verify auth token handling
- Review storage access permissions

---

### 6) Performance Hotspots/Long-running Tasks

| Pattern | Current Implementation | Issues | COGO Improvement |
|---------|-----------------------|--------|-------------------|
| WebSocket | Custom WebSocket client<br>Manual reconnection | Connection management overhead | streamOrRealtime with auto-reconnect |
| Real-time | Postgres Changes subscriptions | Database load, not scalable | Broadcast channels (trace:{traceId}) |
| HTTP Requests | Custom HTTP client | No retry logic | @cogo-chat-sdk-ts with retry/retry |
| File Operations | Direct storage calls | No progress tracking | signedUrl with progress callbacks |
| Auth | Custom auth flow | Token refresh issues | Supabase auth integration |

**Optimizations**:
- WebSocket reconnection logic may have race conditions
- Real-time subscriptions may cause database performance issues
- No connection pooling or request deduplication

---

### 7) Refactoring Candidates

| Category | Current | COGO Replacement | Effort |
|----------|---------|------------------|--------|
| HTTP Clients | Custom base_api.dart | @cogo-chat-sdk-ts | Medium |
| WebSocket | Custom websocket_client.dart | streamOrRealtime | High |
| Real-time | Postgres Changes | trace:{traceId} broadcast | Medium |
| Storage | Direct Supabase calls | signedUrl + presign flow | Low |
| Auth | Custom auth_client.dart | Supabase auth | Low |
| Models | json_annotation | packages/schemas (Zod) | Medium |
| Config | Custom config.dart | platform-core centralization | Low |
| Utils | json_utils.dart | cogo-cli-flutter json ops | Low |

**Deprecation Candidates**:
- Custom WebSocket implementation (replace with SSE/Realtime)
- Direct Postgres Changes (replace with broadcast)
- Hard-coded configurations (centralize)

---

### 8) Migration Map: CreateGo → COGO (Priority Order)

| Priority | CreateGo Component | COGO Component | Difficulty | Test Cases |
|----------|-------------------|----------------|------------|------------|
| 1 | supabase_client.dart | @cogo-chat-sdk-ts | Medium | Auth, API calls |
| 2 | realtime_client.dart | trace:{traceId} broadcast | High | Event delivery, performance |
| 3 | websocket_client.dart | streamOrRealtime | High | SSE streams, reconnection |
| 4 | supabase_storage.dart | signedUrl downloads | Low | Upload/download flows |
| 5 | auth_client.dart | Supabase auth | Low | Login/logout flows |
| 6 | config.dart | platform-core | Medium | Environment management |
| 7 | ui_model.dart | packages/schemas | Low | JSON validation |
| 8 | json_utils.dart | cogo-cli-flutter | Low | JSON operations |

**Timeline Estimate**: 4-6 weeks (2 weeks core, 2 weeks testing, 2 weeks rollout)

---

### 9) Checklist: Migration Steps & Validation

#### Phase 1: Preparation (Week 1-2)
- [ ] Complete source audit (this document)
- [ ] Create migration branch (feature/cogo-migration)
- [ ] Set up COGO environment variables
- [ ] Add feature flag (CRETEGO_USE_COGO=true/false)
- [ ] Security audit for secrets/configs
- [ ] Performance baseline measurements

#### Phase 2: Core Migration (Week 3-4)
- [ ] Replace supabase_client with @cogo-chat-sdk-ts
- [ ] Migrate realtime_client to broadcast channels
- [ ] Replace websocket_client with streamOrRealtime
- [ ] Update storage operations to use signedUrl
- [ ] Migrate auth to Supabase standard
- [ ] Update models to use packages/schemas
- [ ] Unit tests updated (60%+ coverage maintained)

#### Phase 3: Integration & Rollback (Week 5-6)
- [ ] E2E tests passing (flag on/off)
- [ ] Performance validation (<10% regression)
- [ ] Integration tests with COGO platform
- [ ] Documentation updates
- [ ] Rollback procedures documented
- [ ] Production canary deployment
- [ ] Full rollout with monitoring

#### Ongoing
- [ ] Monitor error rates and performance
- [ ] Update usage documentation
- [ ] Gradually deprecate legacy components

**Success Criteria**:
- All existing functionality preserved
- Performance maintained or improved
- Zero security incidents
- Smooth rollback capability
- Documentation current and accessible

---

### 10) Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| WebSocket compatibility | High | High | Thorough testing of streamOrRealtime replacement |
| Real-time performance | Medium | Medium | Load testing before/after migration |
| Auth integration issues | Medium | High | Gradual migration with feature flags |
| Storage access changes | Low | Medium | Test all upload/download scenarios |
| Breaking API changes | High | Critical | Maintain backward compatibility layer |
| Performance regression | Medium | Medium | Establish performance baselines |
| Rollback complexity | Low | High | Document and test rollback procedures |

**Contingency Plans**:
- Feature flag rollback: Immediate switch to legacy mode
- Module-level rollback: Isolate problematic components
- Full rollback: Previous version deployment
- Emergency: Database state preservation

---

### 11) Next Steps
1. Begin Phase 1 preparation
2. Set up COGO test environment
3. Start with low-risk components (auth, storage)
4. Weekly progress reviews
5. Phase completion gates

**Contacts**: [Migration team contacts]
**Last Updated**: 2025-08-31

---

**Appendices**:
- A: Detailed module dependency graph
- B: API call inventory and mappings
- C: Real-time subscription patterns
- D: Storage operation flows
- E: Environment variable inventory
- F: Performance benchmark results
- G: Security audit findings

This document serves as the single source of truth for CreateGo packages migration to COGO.
