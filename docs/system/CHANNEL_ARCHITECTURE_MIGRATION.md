# COGO Agent Core - 채널 아키텍처 마이그레이션

## 🎯 개요

기존의 단순한 채널 구조에서 **주제별로 명확하게 분리된 채널 아키텍처**로 마이그레이션하여 시스템의 가독성, 유지보수성, 확장성을 크게 향상시킵니다.

## 🏗️ 새로운 채널 구조

### 📊 주제별 채널 분류

```typescript
static readonly CHANNELS = {
  // 1. 시스템 관리 채널
  SYSTEM: {
    GATEWAY: 'system.gateway',           // 시스템 게이트웨이
    HEALTH: 'system.health',             // 시스템 상태
    CONFIG: 'system.config',             // 설정 변경
    EVENTS: 'system.events'              // 시스템 이벤트
  },
  
  // 2. 에이전트 통신 채널
  AGENTS: {
    ORCHESTRATOR: 'agents.orchestrator', // 중앙 조정자
    EXECUTOR: 'agents.executor',         // 작업 실행자
    RESEARCH: 'agents.research',         // 연구 워커
    INDEXING: 'agents.indexing',         // 인덱싱 워커
    SANDBOX: 'agents.sandbox'            // 샌드박스 관리자
  },
  
  // 3. 작업 관리 채널
  TASKS: {
    REQUESTS: 'tasks.requests',          // 작업 요청
    PROGRESS: 'tasks.progress',          // 작업 진행
    RESULTS: 'tasks.results',            // 작업 결과
    ERRORS: 'tasks.errors',              // 작업 오류
    DELEGATION: 'tasks.delegation'       // 작업 위임
  },
  
  // 4. 코드 생성 채널
  CODE: {
    GENERATION: 'code.generation',       // 코드 생성
    COMPILATION: 'code.compilation',     // 컴파일
    VALIDATION: 'code.validation',       // 코드 검증
    TESTING: 'code.testing',             // 테스트
    DEPLOYMENT: 'code.deployment'        // 배포
  },
  
  // 5. AI 처리 채널
  AI: {
    REQUESTS: 'ai.requests',             // AI 요청
    RESPONSES: 'ai.responses',           // AI 응답
    ANALYSIS: 'ai.analysis',             // AI 분석
    FIXES: 'ai.fixes',                   // AI 수정
    LEARNING: 'ai.learning'              // AI 학습
  },
  
  // 6. 병렬 처리 채널
  PARALLEL: {
    SUBTASKS: 'parallel.subtasks',       // 하위 작업
    COORDINATION: 'parallel.coordination', // 작업 조정
    SYNCHRONIZATION: 'parallel.sync',    // 동기화
    MERGE: 'parallel.merge'              // 결과 병합
  },
  
  // 7. 사용자 인터페이스 채널
  UI: {
    CONVERSATION: 'ui.conversation',     // 사용자 대화
    NOTIFICATIONS: 'ui.notifications',   // 알림
    PROGRESS: 'ui.progress',             // 진행 상황
    FEEDBACK: 'ui.feedback'              // 피드백
  }
};
```

## 🔄 마이그레이션 매핑

### 기존 → 새로운 채널 매핑

| 기존 채널 | 새로운 채널 | 설명 |
|-----------|-------------|------|
| `cogo-system-gateway` | `system.gateway` | 시스템 게이트웨이 |
| `cogo-orchestrator-agent` | `agents.orchestrator` | 중앙 조정자 |
| `task-manager` | `agents.executor` | 작업 실행자 |
| `cogo-worker` | `agents.sandbox` | 샌드박스 관리자 |
| `code-agent` | `code.generation` | 코드 생성 |
| `cogo-responses` | `tasks.results` | 작업 결과 |
| `cogo-subtasks` | `parallel.subtasks` | 병렬 하위 작업 |
| `cogo-results` | `tasks.results` | 작업 결과 |
| `cogo-parallel-execution` | `parallel.coordination` | 병렬 작업 조정 |
| `cogo-validation` | `code.validation` | 코드 검증 |
| `archgw` | `ui.conversation` | 사용자 대화 (제거됨) |

## ✅ 완료된 작업

### Phase 1: 기본 구조 설정 ✅
- [x] 새로운 주제별 채널 구조 정의
- [x] 기존 호환성을 위한 LEGACY_CHANNELS 별칭 추가
- [x] archgw 채널 제거 및 ui.conversation으로 대체
- [x] 컴파일 오류 해결

### 변경된 파일들
- `src/services/SupabaseRealtimeQueue.ts` - 새로운 채널 구조 정의
- `src/agents/cogo-arch-gateway.ts` - archgw → ui.conversation
- `src/agents/cogo-orchestrator-agent.ts` - archgw → ui.conversation
- `src/services/SupabaseRealtimeService.ts` - archgw 제거
- `src/services/RealtimeMonitor.ts` - archgw 제거
- `src/tests/*.ts` - 테스트 파일들에서 archgw 제거

## 🚀 다음 단계

### Phase 2: 점진적 마이그레이션 (진행 예정)
- [ ] 각 에이전트에서 새로운 채널 구조 적용
- [ ] 기존 채널 사용 코드를 새로운 채널로 변경
- [ ] LEGACY_CHANNELS 별칭 제거

### Phase 3: 새로운 채널 활용 (진행 예정)
- [ ] 컴파일 오류 수정을 위한 AI 채널 구현
- [ ] 병렬 처리를 위한 PARALLEL 채널 활용
- [ ] 코드 생성 워크플로우 개선

### Phase 4: 최적화 및 모니터링 (진행 예정)
- [ ] 채널별 성능 모니터링
- [ ] 채널별 권한 관리
- [ ] 채널별 로깅 및 디버깅

## 🎯 사용 예시

### 컴파일 오류 수정 흐름
```typescript
// SandboxManager → OrchestratorAgent
await this.realtimeQueue.broadcastMessage({
  type: 'compilation_error',
  payload: {
    requestId: uuidv4(),
    sourceCode: code,
    language: 'typescript',
    errorInfo: error
  },
  source: 'agents.sandbox',
  target: 'agents.orchestrator'
});

// OrchestratorAgent → SandboxManager
await this.realtimeQueue.broadcastMessage({
  type: 'ai_fix_response',
  payload: {
    requestId: requestId,
    fixedCode: fixedCode,
    analysis: analysis
  },
  source: 'agents.orchestrator',
  target: 'agents.sandbox'
});
```

### 작업 위임 흐름
```typescript
// OrchestratorAgent → ExecutorAgent
await this.realtimeQueue.broadcastMessage({
  type: 'task_delegation',
  payload: {
    taskId: uuidv4(),
    taskType: 'code_generation',
    requirements: requirements
  },
  source: 'agents.orchestrator',
  target: 'agents.executor'
});
```

## 📊 장점

### 1. 명확한 책임 분리
- 각 채널이 특정 주제에만 집중
- 시스템 복잡도 감소
- 디버깅 및 모니터링 용이

### 2. 확장성
- 새로운 기능 추가 시 해당 주제의 채널만 확장
- 기존 채널에 영향 없음
- 점진적 기능 추가 가능

### 3. 유지보수성
- 주제별로 코드 분리
- 채널별 독립적 테스트 가능
- 명확한 의존성 관리

### 4. 성능 최적화
- 필요한 채널만 구독
- 불필요한 메시지 필터링
- 채널별 최적화 가능

## 🔧 개발 가이드라인

### 채널 사용 원칙
1. **주제별 분리**: 각 채널은 명확한 주제를 가져야 함
2. **단방향 통신**: 채널은 특정 방향의 통신에만 사용
3. **명확한 네이밍**: 채널명은 기능을 명확히 표현
4. **일관성**: 전체 시스템에서 일관된 채널 사용

### 채널 구독 패턴
```typescript
// 에이전트별 구독 전략
await this.realtimeQueue.subscribeToChannel('agents.orchestrator', this.handleOrchestratorMessage);
await this.realtimeQueue.subscribeToChannel('ai.requests', this.handleAIRequest);
await this.realtimeQueue.subscribeToChannel('tasks.delegation', this.handleTaskDelegation);
```

---

**작성일**: 2025-08-04  
**버전**: 1.0.0  
**상태**: Phase 1 완료 