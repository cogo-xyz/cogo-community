# Worker Agent Development & Docker Deployment Plan - REVISED
## COGO Framework v2.0 - 기존 에이전트 아키텍처 고려

**Version**: 2.0.0  
**Date**: 2025-01-27  
**Status**: Revised Planning Phase  
**Next Review**: 2025-02-03  

---

## Executive Summary

이 문서는 **기존 COGO Agent Core 아키텍처**를 고려하여 수정된 Worker Agent 개발 계획입니다. 기존 8개 에이전트의 역할과 책임을 분석하고, 이를 오케스트레이터 중심 아키텍처로 전환하는 전략을 제시합니다.

### 기존 에이전트 아키텍처 분석

#### 현재 8개 에이전트 구조:
1. **🧠 Orchestrator Agent** (`cogo-orchestrator-agent`) - **중앙 조정** ✅ 완료
2. **👔 Executor Agent** (`cogo-executor-agent`) - 작업 실행 관리
3. **✍️ Code Generation Service** (`cogo-codegen-service`) - AI 코드 생성
4. **🦾 Sandbox Worker** (`cogo-sandbox-worker`) - 보안 코드 실행
5. **👤 Architecture Gateway** (`cogo-arch-gateway`) - 아키텍처 관리
6. **⚙️ System Gateway** (`cogo-system-gateway`) - 시스템 전체 관리
7. **📚 Indexing Worker** (`cogo-indexing-worker`) - 지식 인덱싱
8. **🔬 Research Worker** (`cogo-research-worker`) - 기술 연구

### 전환 전략

기존 에이전트들을 **Worker Agent**로 전환하면서 기존 기능과 통신 방식을 유지하면서 오케스트레이터 중심으로 재구성합니다.

---

## Part I: 기존 에이전트 → Worker Agent 전환 계획

### 1.1 기존 에이전트 분석 및 전환 매핑

#### **Executor Agent** → **TaskExecutionWorkerAgent**
```typescript
// 기존: cogo-executor-agent.ts
// 전환: TaskExecutionWorkerAgent
class TaskExecutionWorkerAgent extends BaseWorkerAgent {
  // 기존 기능 유지
  async executeTask(task: Task): Promise<boolean> {
    // 기존 실행 로직 유지
    return await this.processTask(task);
  }
  
  // 새로운 오케스트레이터 통신 추가
  async receiveOrchestratorInstruction(instruction: OrchestratorInstruction): Promise<void> {
    // 오케스트레이터로부터 작업 지시 수신
    await this.executeTask(instruction.task);
  }
  
  // 역할 기반 실행 추가
  async executeRole(role: Role, context: RoleContext): Promise<RoleExecutionResult> {
    switch (role.name) {
      case 'task-executor':
        return await this.executeTask(context.task);
      case 'subtask-manager':
        return await this.manageSubtasks(context);
      case 'progress-tracker':
        return await this.trackProgress(context);
      default:
        throw new Error(`Unknown role: ${role.name}`);
    }
  }
}
```

#### **Code Generation Service** → **CodeGenerationWorkerAgent**
```typescript
// 기존: cogo-codegen-service.ts
// 전환: CodeGenerationWorkerAgent
class CodeGenerationWorkerAgent extends BaseWorkerAgent {
  // 기존 AI 코드 생성 기능 유지
  async generateCode(requirement: string, language: string): Promise<GeneratedCode> {
    // 기존 코드 생성 로직
    return await this.aiCodeGeneration(requirement, language);
  }
  
  // 새로운 역할 기반 실행
  async executeRole(role: Role, context: RoleContext): Promise<RoleExecutionResult> {
    switch (role.name) {
      case 'code-generator':
        return await this.generateCode(context.requirement, context.language);
      case 'code-reviewer':
        return await this.reviewCode(context.code);
      case 'code-optimizer':
        return await this.optimizeCode(context.code);
      case 'test-generator':
        return await this.generateTests(context.code);
      default:
        throw new Error(`Unknown role: ${role.name}`);
    }
  }
}
```

#### **Sandbox Worker** → **SandboxExecutionWorkerAgent**
```typescript
// 기존: cogo-sandbox-worker.ts
// 전환: SandboxExecutionWorkerAgent
class SandboxExecutionWorkerAgent extends BaseWorkerAgent {
  // 기존 Docker 컨테이너 관리 기능 유지
  async executeInSandbox(code: string, language: string): Promise<ExecutionResult> {
    // 기존 샌드박스 실행 로직
    return await this.dockerExecution(code, language);
  }
  
  // 새로운 역할 기반 실행
  async executeRole(role: Role, context: RoleContext): Promise<RoleExecutionResult> {
    switch (role.name) {
      case 'code-executor':
        return await this.executeInSandbox(context.code, context.language);
      case 'security-scanner':
        return await this.scanSecurity(context.code);
      case 'resource-monitor':
        return await this.monitorResources(context);
      case 'container-manager':
        return await this.manageContainers(context);
      default:
        throw new Error(`Unknown role: ${role.name}`);
    }
  }
}
```

#### **Architecture Gateway** → **ArchitectureWorkerAgent**
```typescript
// 기존: cogo-arch-gateway.ts
// 전환: ArchitectureWorkerAgent
class ArchitectureWorkerAgent extends BaseWorkerAgent {
  // 기존 아키텍처 분석 기능 유지
  async analyzeArchitecture(project: Project): Promise<ArchitectureAnalysis> {
    // 기존 아키텍처 분석 로직
    return await this.architectureAnalysis(project);
  }
  
  // 새로운 역할 기반 실행
  async executeRole(role: Role, context: RoleContext): Promise<RoleExecutionResult> {
    switch (role.name) {
      case 'architecture-analyzer':
        return await this.analyzeArchitecture(context.project);
      case 'integration-planner':
        return await this.planIntegration(context);
      case 'tech-stack-advisor':
        return await this.recommendTechStack(context);
      case 'performance-optimizer':
        return await this.optimizePerformance(context);
      default:
        throw new Error(`Unknown role: ${role.name}`);
    }
  }
}
```

#### **System Gateway** → **SystemManagementWorkerAgent**
```typescript
// 기존: cogo-system-gateway.ts
// 전환: SystemManagementWorkerAgent
class SystemManagementWorkerAgent extends BaseWorkerAgent {
  // 기존 시스템 관리 기능 유지
  async manageSystemHealth(): Promise<SystemHealth> {
    // 기존 시스템 관리 로직
    return await this.healthMonitoring();
  }
  
  // 새로운 역할 기반 실행
  async executeRole(role: Role, context: RoleContext): Promise<RoleExecutionResult> {
    switch (role.name) {
      case 'health-monitor':
        return await this.monitorHealth(context);
      case 'resource-manager':
        return await this.manageResources(context);
      case 'agent-coordinator':
        return await this.coordinateAgents(context);
      case 'config-manager':
        return await this.manageConfiguration(context);
      default:
        throw new Error(`Unknown role: ${role.name}`);
    }
  }
}
```

#### **Indexing Worker** → **KnowledgeIndexingWorkerAgent**
```typescript
// 기존: cogo-indexing-worker.ts
// 전환: KnowledgeIndexingWorkerAgent
class KnowledgeIndexingWorkerAgent extends BaseWorkerAgent {
  // 기존 인덱싱 기능 유지
  async indexContent(content: string, type: string): Promise<IndexResult> {
    // 기존 인덱싱 로직
    return await this.contentIndexing(content, type);
  }
  
  // 새로운 역할 기반 실행
  async executeRole(role: Role, context: RoleContext): Promise<RoleExecutionResult> {
    switch (role.name) {
      case 'content-indexer':
        return await this.indexContent(context.content, context.type);
      case 'vector-generator':
        return await this.generateVectors(context.content);
      case 'search-optimizer':
        return await this.optimizeSearch(context);
      case 'graph-maintainer':
        return await this.maintainKnowledgeGraph(context);
      default:
        throw new Error(`Unknown role: ${role.name}`);
    }
  }
}
```

#### **Research Worker** → **ResearchWorkerAgent**
```typescript
// 기존: cogo-research-worker.ts
// 전환: ResearchWorkerAgent
class ResearchWorkerAgent extends BaseWorkerAgent {
  // 기존 연구 기능 유지
  async researchTechnology(topic: string): Promise<ResearchResult> {
    // 기존 연구 로직
    return await this.technologyResearch(topic);
  }
  
  // 새로운 역할 기반 실행
  async executeRole(role: Role, context: RoleContext): Promise<RoleExecutionResult> {
    switch (role.name) {
      case 'technology-researcher':
        return await this.researchTechnology(context.topic);
      case 'trend-analyzer':
        return await this.analyzeTrends(context);
      case 'solution-comparer':
        return await this.compareSolutions(context);
      case 'documentation-gatherer':
        return await this.gatherDocumentation(context);
      default:
        throw new Error(`Unknown role: ${role.name}`);
    }
  }
}
```

### 1.2 기존 통신 시스템 유지 및 확장

#### **Supabase Real-time 통신 유지**
```typescript
// 기존 채널 구조 유지하면서 오케스트레이터 통신 추가
const CHANNELS = {
  // 기존 채널들 유지
  AGENT_MANAGER: 'agent-manager',
  TASK_MANAGER: 'task-manager',
  COGO_RESPONSES: 'cogo-responses',
  COGO_SUBTASKS: 'cogo-subtasks',
  INDEXING_REQUESTS: 'indexing-requests',
  WORKFLOW_EVENTS: 'workflow-events',
  
  // 새로운 오케스트레이터 채널 추가
  ORCHESTRATOR_INSTRUCTIONS: 'orchestrator-instructions',
  WORKER_RESULTS: 'worker-results',
  WORKER_STATUS: 'worker-status'
};
```

#### **기존 메시지 구조 확장**
```typescript
// 기존 AgentMessage 구조 유지하면서 확장
interface AgentMessage {
  id: string;
  sender: string;
  receiver: string;
  type: MessageType;
  payload: any;
  timestamp: Date;
  priority: Priority;
  
  // 오케스트레이터 통신을 위한 추가 필드
  orchestratorId?: string;
  role?: Role;
  context?: RoleContext;
}

// 새로운 오케스트레이터 메시지 타입
enum MessageType {
  // 기존 타입들 유지
  TASK_ASSIGNMENT = 'task-assignment',
  STATUS_UPDATE = 'status-update',
  RESULT_NOTIFICATION = 'result-notification',
  ERROR_REPORTING = 'error-reporting',
  SYSTEM_EVENTS = 'system-events',
  
  // 새로운 오케스트레이터 타입들
  ORCHESTRATOR_INSTRUCTION = 'orchestrator-instruction',
  WORKER_RESULT = 'worker-result',
  WORKER_STATUS = 'worker-status',
  ROLE_ASSIGNMENT = 'role-assignment'
}
```

---

## Part II: 수정된 개발 로드맵

### Phase 1: 기존 에이전트 분석 및 BaseWorkerAgent 구현 (Week 1)

#### Week 1: 기존 에이전트 분석 및 전환 계획
- [ ] **기존 에이전트 코드 분석**
  - `cogo-executor-agent.ts` 분석
  - `cogo-codegen-service.ts` 분석
  - `cogo-sandbox-worker.ts` 분석
  - `cogo-arch-gateway.ts` 분석
  - `cogo-system-gateway.ts` 분석
  - `cogo-indexing-worker.ts` 분석
  - `cogo-research-worker.ts` 분석

- [ ] **BaseWorkerAgent 클래스 구현**
  - 기존 BaseAgent 상속
  - 오케스트레이터 통신 인터페이스 추가
  - 기존 기능 호환성 유지
  - 역할 기반 실행 엔진

- [ ] **통신 프로토콜 확장**
  - 기존 Supabase Real-time 채널 유지
  - 오케스트레이터 통신 채널 추가
  - 메시지 구조 확장
  - 하위 호환성 보장

### Phase 2: Worker Agent 전환 (Week 2-3)

#### Week 2: 핵심 Worker Agent 전환
- [ ] **TaskExecutionWorkerAgent 구현**
  - 기존 `cogo-executor-agent.ts` 전환
  - 기존 작업 실행 로직 유지
  - 오케스트레이터 통신 추가

- [ ] **CodeGenerationWorkerAgent 구현**
  - 기존 `cogo-codegen-service.ts` 전환
  - 기존 AI 코드 생성 기능 유지
  - 역할 기반 코드 생성 추가

#### Week 3: 추가 Worker Agent 전환
- [ ] **SandboxExecutionWorkerAgent 구현**
  - 기존 `cogo-sandbox-worker.ts` 전환
  - Docker 컨테이너 관리 기능 유지
  - 보안 실행 환경 확장

- [ ] **ArchitectureWorkerAgent 구현**
  - 기존 `cogo-arch-gateway.ts` 전환
  - 아키텍처 분석 기능 유지
  - 기술 스택 추천 기능 확장

### Phase 3: 시스템 관리 및 지식 Worker Agent 전환 (Week 4-5)

#### Week 4: 시스템 관리 Worker Agent
- [ ] **SystemManagementWorkerAgent 구현**
  - 기존 `cogo-system-gateway.ts` 전환
  - 시스템 관리 기능 유지
  - 에이전트 조정 기능 확장

- [ ] **KnowledgeIndexingWorkerAgent 구현**
  - 기존 `cogo-indexing-worker.ts` 전환
  - 지식 인덱싱 기능 유지
  - 벡터 검색 기능 확장

#### Week 5: 연구 및 통합 Worker Agent
- [ ] **ResearchWorkerAgent 구현**
  - 기존 `cogo-research-worker.ts` 전환
  - 기술 연구 기능 유지
  - 트렌드 분석 기능 확장

- [ ] **오케스트레이터 통합 테스트**
  - 모든 Worker Agent와 오케스트레이터 통신 테스트
  - 기존 기능 호환성 검증
  - 성능 최적화

### Phase 4: Docker 컨테이너화 및 배포 (Week 6-8)

#### Week 6: Docker 컨테이너화
- [ ] **Worker Agent Dockerfile 작성**
  - 각 Worker Agent별 특화 Dockerfile
  - 기존 의존성 및 환경 설정 유지
  - 보안 강화 및 최적화

- [ ] **docker-compose 설정**
  - 기존 서비스와 새로운 Worker Agent 통합
  - 개발/프로덕션 환경 분리
  - 모니터링 및 로깅 설정

#### Week 7-8: 배포 및 테스트
- [ ] **개발 환경 배포**
  - 로컬 Docker 환경 구축
  - 기존 기능 테스트
  - 새로운 오케스트레이터 기능 테스트

- [ ] **프로덕션 배포 준비**
  - Kubernetes 설정
  - 모니터링 및 알림 설정
  - 성능 테스트 및 최적화

---

## Part III: 수정된 Docker 컨테이너화 전략

### 3.1 기존 서비스와 통합된 컨테이너 구조

```yaml
# docker-compose.yml (기존 서비스 + Worker Agent 통합)
version: '3.8'
services:
  # 기존 오케스트레이터 (완성됨)
  cogo-orchestrator:
    image: cogo/orchestrator:latest
    container_name: cogo-orchestrator
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - NEO4J_URI=${NEO4J_URI}
      - REDIS_URL=${REDIS_URL}
    ports:
      - "3000:3000"
    volumes:
      - orchestrator_logs:/app/logs
      - orchestrator_data:/app/data
    networks:
      - cogo-network
    depends_on:
      - postgres
      - neo4j
      - redis

  # 기존 에이전트들을 Worker Agent로 전환
  cogo-task-execution-worker:
    image: cogo/task-execution-worker:latest
    container_name: cogo-task-execution-worker
    environment:
      - ORCHESTRATOR_URL=http://cogo-orchestrator:3000
      - WORKER_TYPE=task-execution
      - WORKER_ID=task-exec-001
    volumes:
      - task_execution_workspace:/app/workspace
    networks:
      - cogo-network
    depends_on:
      - cogo-orchestrator
    deploy:
      replicas: 2

  cogo-codegen-worker:
    image: cogo/codegen-worker:latest
    container_name: cogo-codegen-worker
    environment:
      - ORCHESTRATOR_URL=http://cogo-orchestrator:3000
      - WORKER_TYPE=code-generation
      - WORKER_ID=codegen-001
    volumes:
      - codegen_workspace:/app/workspace
    networks:
      - cogo-network
    depends_on:
      - cogo-orchestrator
    deploy:
      replicas: 2

  cogo-sandbox-worker:
    image: cogo/sandbox-worker:latest
    container_name: cogo-sandbox-worker
    environment:
      - ORCHESTRATOR_URL=http://cogo-orchestrator:3000
      - WORKER_TYPE=sandbox-execution
      - WORKER_ID=sandbox-001
    volumes:
      - sandbox_workspace:/app/workspace
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - cogo-network
    depends_on:
      - cogo-orchestrator
    deploy:
      replicas: 2

  cogo-architecture-worker:
    image: cogo/architecture-worker:latest
    container_name: cogo-architecture-worker
    environment:
      - ORCHESTRATOR_URL=http://cogo-orchestrator:3000
      - WORKER_TYPE=architecture
      - WORKER_ID=arch-001
    volumes:
      - architecture_workspace:/app/workspace
    networks:
      - cogo-network
    depends_on:
      - cogo-orchestrator
    deploy:
      replicas: 1

  cogo-system-management-worker:
    image: cogo/system-management-worker:latest
    container_name: cogo-system-management-worker
    environment:
      - ORCHESTRATOR_URL=http://cogo-orchestrator:3000
      - WORKER_TYPE=system-management
      - WORKER_ID=system-001
    volumes:
      - system_data:/app/data
    networks:
      - cogo-network
    depends_on:
      - cogo-orchestrator
    deploy:
      replicas: 1

  cogo-knowledge-indexing-worker:
    image: cogo/knowledge-indexing-worker:latest
    container_name: cogo-knowledge-indexing-worker
    environment:
      - ORCHESTRATOR_URL=http://cogo-orchestrator:3000
      - WORKER_TYPE=knowledge-indexing
      - WORKER_ID=indexing-001
    volumes:
      - knowledge_data:/app/data
    networks:
      - cogo-network
    depends_on:
      - cogo-orchestrator
    deploy:
      replicas: 1

  cogo-research-worker:
    image: cogo/research-worker:latest
    container_name: cogo-research-worker
    environment:
      - ORCHESTRATOR_URL=http://cogo-orchestrator:3000
      - WORKER_TYPE=research
      - WORKER_ID=research-001
    volumes:
      - research_data:/app/data
    networks:
      - cogo-network
    depends_on:
      - cogo-orchestrator
    deploy:
      replicas: 1

  # 기존 인프라 서비스들
  postgres:
    image: postgres:15
    container_name: cogo-postgres
    environment:
      - POSTGRES_DB=cogo
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - cogo-network

  neo4j:
    image: neo4j:5.27
    container_name: cogo-neo4j
    environment:
      - NEO4J_AUTH=${NEO4J_USER}/${NEO4J_PASSWORD}
    volumes:
      - neo4j_data:/data
    networks:
      - cogo-network

  redis:
    image: redis:7-alpine
    container_name: cogo-redis
    volumes:
      - redis_data:/data
    networks:
      - cogo-network

volumes:
  orchestrator_logs:
  orchestrator_data:
  task_execution_workspace:
  codegen_workspace:
  sandbox_workspace:
  architecture_workspace:
  system_data:
  knowledge_data:
  research_data:
  postgres_data:
  neo4j_data:
  redis_data:

networks:
  cogo-network:
    driver: bridge
```

### 3.2 기존 기능 호환성을 위한 Dockerfile 전략

#### **기존 의존성 유지를 위한 Dockerfile**
```dockerfile
# Worker Agent Dockerfile (기존 의존성 유지)
FROM node:18-alpine AS base

WORKDIR /app

# 기존 의존성 설치 (기존 package.json 유지)
COPY package*.json ./
RUN npm ci

# 기존 소스 코드 복사
COPY . .

# TypeScript 컴파일 (기존 설정 유지)
RUN npm run build

# 프로덕션 이미지
FROM node:18-alpine AS production

# 보안 사용자 생성
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

WORKDIR /app

# 프로덕션 의존성 및 소스 복사
COPY --from=base --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=base --chown=nodejs:nodejs /app/dist ./dist
COPY --from=base --chown=nodejs:nodejs /app/package*.json ./

# 기존 설정 파일들 복사
COPY --from=base --chown=nodejs:nodejs /app/config ./config
COPY --from=base --chown=nodejs:nodejs /app/src/types ./src/types

# 워크스페이스 생성
RUN mkdir -p /app/workspace && chown nodejs:nodejs /app/workspace

# 헬스체크
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node dist/healthcheck.js

USER nodejs

EXPOSE 3000

# 기존 시작 스크립트 유지하면서 Worker Agent 모드 추가
CMD ["node", "dist/index.js", "--worker-mode"]
```

---

## Part IV: 수정된 성공 지표 및 KPI

### 4.1 기존 기능 호환성 지표
- **기존 기능 유지율**: 100% (모든 기존 기능 정상 작동)
- **기존 API 호환성**: 100% (기존 API 엔드포인트 정상 작동)
- **기존 통신 채널 유지**: 100% (Supabase Real-time 채널 정상 작동)

### 4.2 새로운 오케스트레이터 기능 지표
- **Worker Agent 응답 시간**: < 100ms
- **오케스트레이터 처리량**: > 1000 requests/min
- **역할 기반 작업 분배 성공률**: > 99%
- **Worker Agent 등록 성공률**: 100%

### 4.3 시스템 성능 지표
- **컨테이너 가동률**: > 99.9%
- **배포 성공률**: > 99%
- **기존 워크플로우 성공률**: 100% (기존 LangGraph 워크플로우 유지)
- **새로운 오케스트레이터 워크플로우 성공률**: > 95%

---

## 결론

이 수정된 계획은 **기존 COGO Agent Core 아키텍처를 완전히 고려**하여 작성되었습니다. 기존 8개 에이전트의 기능과 통신 방식을 유지하면서 오케스트레이터 중심 아키텍처로 점진적으로 전환하는 전략을 제시합니다.

### 핵심 원칙
1. **기존 기능 100% 유지**: 모든 기존 기능이 정상 작동
2. **점진적 전환**: 기존 에이전트를 하나씩 Worker Agent로 전환
3. **하위 호환성**: 기존 API와 통신 채널 완전 호환
4. **확장성**: 새로운 오케스트레이터 기능 추가

### 다음 단계
1. **기존 에이전트 코드 분석** 시작
2. **BaseWorkerAgent 클래스 구현**
3. **첫 번째 Worker Agent 전환** (TaskExecutionWorkerAgent)
4. **기존 기능 호환성 테스트**

이 계획을 통해 **안전하고 점진적인 전환**을 통해 COGO Framework v2.0의 완전한 오케스트레이터 중심 아키텍처를 실현할 수 있습니다! 🚀

---

**Document Version**: 2.0.0  
**Last Updated**: 2025-01-27  
**Next Review**: 2025-02-03  
**Status**: Revised Planning Phase 📋 