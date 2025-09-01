# COGO Agent Core - 올바른 아키텍처 (수정본)

## 🎯 **COGO Agent Core 핵심 철학**

### 1. **중앙 집중식 Orchestrator Agent**
- **모든 판단과 의사결정**은 Orchestrator Agent가 담당
- **RAG 검색 + LLM(prompt)** 기반의 지능형 의사결정
- **Role 기반 실행**으로 페르소나와 컨텍스트 동적 변경

### 2. **모듈형 기능 확장**
- Pre-generation, Core-generation, Post-generation 기능이 **모듈**로 추가
- 기존 Agent들은 **Orchestrator Agent의 지시**에 따라 동작
- **자율적 판단 없이** 명령 수행만 담당

### 3. **지식 기반 아키텍처**
- **모든 단계가 KG + RAG 기반**
- Orchestrator Agent가 **고급 RAG 검색**으로 컨텍스트 구성
- **Role Schema**에 따라 페르소나와 프롬프트 동적 생성

## 🏗️ **수정된 아키텍처**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           COGO Agent Core v2.0                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                        🧠 Orchestrator Agent (중앙 제어)                     │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                    Role-Based Decision Engine                           │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │ │
│  │  │   RAG       │  │   LLM       │  │   Role      │  │   Session   │   │ │
│  │  │  Search     │  │  Prompt     │  │  Schema     │  │  Manager    │   │ │
│  │  │  Engine     │  │  Engine     │  │  Manager    │  │             │   │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────┤
│                              모듈형 기능 레이어                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │ Pre-Generation  │  │ Core-Generation │  │ Post-Generation │             │
│  │    Modules      │  │    Modules      │  │    Modules      │             │
│  │                 │  │                 │  │                 │             │
│  │ • Complexity    │  │ • CodeGen       │  │ • Validation    │             │
│  │ • Knowledge     │  │ • Refactoring   │  │ • Compilation   │             │
│  │ • Semantic      │  │ • Optimization  │  │ • Testing       │             │
│  │ • Workflow      │  │ • Integration   │  │ • Deployment    │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
├─────────────────────────────────────────────────────────────────────────────┤
│                              실행 Agent 레이어                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │ 👔 Executor     │  │ 🔬 Research     │  │ ✍️ CodeGen      │             │
│  │    Agent        │  │    Worker       │  │    Service      │             │
│  │ (명령 실행)      │  │ (조사 수행)      │  │ (코드 생성)      │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │ 🦾 Sandbox      │  │ 📚 Indexing     │  │ 🚪 Gateway      │             │
│  │    Worker       │  │    Worker       │  │    Agent        │             │
│  │ (실행 환경)      │  │ (지식 인덱싱)    │  │ (외부 통신)      │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
├─────────────────────────────────────────────────────────────────────────────┤
│                              데이터 레이어                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │ Supabase        │  │ Neo4j           │  │ SQLite          │             │
│  │ (PostgreSQL +   │  │ (Knowledge      │  │ (Local Cache)   │             │
│  │  pgvector)      │  │  Graph)         │  │                 │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🧠 **Orchestrator Agent 상세 구조**

### 핵심 컴포넌트

#### 1. **RAG Search Engine**
```typescript
interface RAGSearchEngine {
  // 고급 RAG 검색
  advancedSearch(query: string, context: SearchContext): Promise<SearchResult[]>;
  
  // 하이브리드 검색 (KG + Vector)
  hybridSearch(query: string, options: HybridSearchOptions): Promise<HybridResult>;
  
  // 컨텍스트 기반 검색
  contextAwareSearch(query: string, sessionContext: SessionContext): Promise<ContextualResult>;
  
  // 실시간 검색 업데이트
  realtimeSearch(query: string, callback: (results: SearchResult[]) => void): void;
}
```

#### 2. **LLM Prompt Engine**
```typescript
interface LLMPromptEngine {
  // Role 기반 프롬프트 생성
  generateRoleBasedPrompt(role: Role, context: PromptContext): Promise<GeneratedPrompt>;
  
  // 동적 페르소나 생성
  createDynamicPersona(role: Role, task: Task): Promise<Persona>;
  
  // 컨텍스트 기반 프롬프트 최적화
  optimizePromptWithContext(prompt: string, context: SearchContext): Promise<string>;
  
  // 멀티 모달 프롬프트 생성
  generateMultimodalPrompt(role: Role, task: Task, media: Media[]): Promise<MultimodalPrompt>;
}
```

#### 3. **Role Schema Manager**
```typescript
interface RoleSchemaManager {
  // Role 스키마 정의
  defineRole(roleId: string, schema: RoleSchema): Promise<void>;
  
  // 동적 Role 생성
  createDynamicRole(task: Task, context: TaskContext): Promise<Role>;
  
  // Role 기반 의사결정
  makeRoleBasedDecision(role: Role, options: DecisionOptions): Promise<Decision>;
  
  // Role 전환 관리
  switchRole(currentRole: Role, newRole: Role, context: TransitionContext): Promise<void>;
}
```

#### 4. **Session Manager**
```typescript
interface SessionManager {
  // 세션 생성 및 관리
  createSession(userId: string, task: Task): Promise<Session>;
  
  // 세션 컨텍스트 관리
  updateSessionContext(sessionId: string, context: SessionContext): Promise<void>;
  
  // 세션 상태 추적
  trackSessionState(sessionId: string, state: SessionState): Promise<void>;
  
  // 세션 히스토리 관리
  getSessionHistory(sessionId: string): Promise<SessionHistory>;
}
```

## 🔄 **수정된 워크플로우**

### Orchestrator Agent 중심 워크플로우

```
1. 🧠 Orchestrator Agent (시작)
   - 사용자 요청 수신
   - 초기 Role 결정 (예: "Requirements Analyst")
   - RAG 검색으로 컨텍스트 수집
   - LLM 프롬프트 생성
   ↓

2. 🧠 Orchestrator Agent (Pre-Generation)
   - Role: "Complexity Analyzer"
   - RAG 검색: 복잡도 분석 패턴
   - LLM 프롬프트: 복잡도 평가 지시
   - 모듈 호출: Complexity Analysis Module
   ↓

3. 🧠 Orchestrator Agent (Core-Generation)
   - Role: "Senior Developer" 또는 "Architect"
   - RAG 검색: 코드 패턴 및 아키텍처
   - LLM 프롬프트: 코드 생성 지시
   - 모듈 호출: CodeGen Module
   ↓

4. 🧠 Orchestrator Agent (Post-Generation)
   - Role: "Code Reviewer" 또는 "QA Engineer"
   - RAG 검색: 검증 패턴 및 테스트 케이스
   - LLM 프롬프트: 검증 및 테스트 지시
   - 모듈 호출: Validation Module
   ↓

5. 🧠 Orchestrator Agent (완료)
   - 결과 통합 및 최종 검증
   - 세션 종료 및 정리
   - 지식 베이스 업데이트 지시
```

### Role 기반 실행 예시

```typescript
// Orchestrator Agent의 Role 기반 실행
class OrchestratorAgent {
  async executeTask(task: Task): Promise<TaskResult> {
    // 1. 초기 Role 결정
    const initialRole = await this.roleManager.determineInitialRole(task);
    
    // 2. 세션 생성
    const session = await this.sessionManager.createSession(task.userId, task);
    
    // 3. Pre-Generation Phase
    await this.executePreGenerationPhase(task, session, initialRole);
    
    // 4. Core-Generation Phase
    await this.executeCoreGenerationPhase(task, session);
    
    // 5. Post-Generation Phase
    await this.executePostGenerationPhase(task, session);
    
    // 6. 결과 통합
    return await this.integrateResults(task, session);
  }
  
  private async executePreGenerationPhase(task: Task, session: Session, role: Role) {
    // Role: "Requirements Analyst" → "Complexity Analyzer" → "Knowledge Seeker"
    const phases = [
      { role: 'requirements-analyst', module: 'requirement-processing' },
      { role: 'complexity-analyzer', module: 'complexity-analysis' },
      { role: 'knowledge-seeker', module: 'knowledge-search' }
    ];
    
    for (const phase of phases) {
      // Role 전환
      await this.roleManager.switchRole(session.currentRole, phase.role, session);
      
      // RAG 검색으로 컨텍스트 수집
      const context = await this.ragEngine.search(phase.role, task);
      
      // LLM 프롬프트 생성
      const prompt = await this.promptEngine.generate(phase.role, context);
      
      // 모듈 실행 (명령 기반)
      await this.executeModule(phase.module, prompt, context);
    }
  }
}
```

## 📋 **모듈형 기능 구조**

### Pre-Generation Modules
```typescript
interface PreGenerationModules {
  // 복잡도 분석 모듈
  complexityAnalysis: {
    analyze: (requirement: RequirementDocument) => Promise<ComplexityAnalysis>;
    validate: (analysis: ComplexityAnalysis) => Promise<ValidationResult>;
  };
  
  // 지식 검색 모듈
  knowledgeSearch: {
    search: (query: SearchQuery) => Promise<SearchResult[]>;
    rank: (results: SearchResult[]) => Promise<RankedResult[]>;
  };
  
  // 의미론적 분석 모듈
  semanticAnalysis: {
    analyze: (requirement: RequirementDocument) => Promise<SemanticAnalysis>;
    extractPatterns: (analysis: SemanticAnalysis) => Promise<Pattern[]>;
  };
}
```

### Core-Generation Modules
```typescript
interface CoreGenerationModules {
  // 코드 생성 모듈
  codeGeneration: {
    generate: (prompt: GeneratedPrompt) => Promise<GeneratedCode>;
    optimize: (code: GeneratedCode) => Promise<OptimizedCode>;
  };
  
  // 리팩토링 모듈
  refactoring: {
    analyze: (code: GeneratedCode) => Promise<RefactoringSuggestions>;
    apply: (suggestions: RefactoringSuggestions) => Promise<RefactoredCode>;
  };
}
```

### Post-Generation Modules
```typescript
interface PostGenerationModules {
  // 검증 모듈
  validation: {
    validate: (code: GeneratedCode) => Promise<ValidationResult>;
    checkQuality: (code: GeneratedCode) => Promise<QualityReport>;
  };
  
  // 컴파일 모듈
  compilation: {
    compile: (code: GeneratedCode) => Promise<CompilationResult>;
    build: (project: Project) => Promise<BuildResult>;
  };
  
  // 테스트 모듈
  testing: {
    generateTests: (code: GeneratedCode) => Promise<TestSuite>;
    runTests: (tests: TestSuite) => Promise<TestResult>;
  };
}
```

## 🤖 **실행 Agent들의 역할**

### 명령 기반 실행 Agent들

#### 👔 **Executor Agent**
```typescript
class ExecutorAgent extends BaseAgent {
  async executeTask(task: Task): Promise<boolean> {
    // Orchestrator Agent의 명령만 실행
    const command = task.payload as OrchestratorCommand;
    
    switch (command.type) {
      case 'EXECUTE_MODULE':
        return await this.executeModule(command.module, command.parameters);
      case 'COLLECT_RESULTS':
        return await this.collectResults(command.targets);
      case 'UPDATE_STATUS':
        return await this.updateStatus(command.status);
      default:
        throw new Error(`Unknown command type: ${command.type}`);
    }
  }
}
```

#### 🔬 **Research Worker**
```typescript
class ResearchWorker extends BaseAgent {
  async executeTask(task: Task): Promise<boolean> {
    // Orchestrator Agent의 조사 명령 실행
    const researchCommand = task.payload as ResearchCommand;
    
    const results = await this.performResearch(
      researchCommand.topic,
      researchCommand.sources,
      researchCommand.criteria
    );
    
    task.result = {
      output: results,
      status: 'completed',
      timestamp: new Date().toISOString()
    };
    
    return true;
  }
}
```

#### ✍️ **CodeGen Service**
```typescript
class CodeGenService extends BaseAgent {
  async executeTask(task: Task): Promise<boolean> {
    // Orchestrator Agent의 코드 생성 명령 실행
    const codeGenCommand = task.payload as CodeGenCommand;
    
    const generatedCode = await this.generateCode(
      codeGenCommand.prompt,
      codeGenCommand.context,
      codeGenCommand.requirements
    );
    
    task.result = {
      output: generatedCode,
      status: 'completed',
      timestamp: new Date().toISOString()
    };
    
    return true;
  }
}
```

## 🔄 **통신 구조**

### Orchestrator Agent → 실행 Agent 명령
```typescript
interface OrchestratorCommand {
  id: string;
  type: 'EXECUTE_MODULE' | 'COLLECT_RESULTS' | 'UPDATE_STATUS' | 'RESEARCH' | 'GENERATE_CODE';
  targetAgent: string;
  payload: any;
  priority: 'low' | 'medium' | 'high';
  timeout: number;
  expectedResult: string;
}

// 명령 전송
await orchestratorAgent.sendCommand({
  type: 'EXECUTE_MODULE',
  targetAgent: 'cogo-executor-agent',
  payload: {
    module: 'complexity-analysis',
    parameters: { requirement: requirementDocument }
  },
  priority: 'high',
  timeout: 30000,
  expectedResult: 'ComplexityAnalysis'
});
```

### 실행 Agent → Orchestrator Agent 응답
```typescript
interface AgentResponse {
  commandId: string;
  agentId: string;
  status: 'success' | 'failed' | 'in_progress';
  result?: any;
  error?: string;
  timestamp: Date;
  metadata: {
    processingTime: number;
    resourceUsage: ResourceUsage;
  };
}
```

## 🎯 **핵심 차이점**

### 기존 제안 vs 올바른 구조

| 구분 | 기존 제안 (잘못된) | 올바른 구조 |
|------|-------------------|-------------|
| **의사결정** | 각 Agent가 자율적 판단 | Orchestrator Agent만 판단 |
| **RAG 검색** | 각 Agent가 개별 검색 | Orchestrator Agent가 중앙 집중식 검색 |
| **Role 관리** | 고정된 Agent 역할 | 동적 Role 기반 실행 |
| **프롬프트 생성** | 각 Agent가 개별 생성 | Orchestrator Agent가 Role 기반 생성 |
| **세션 관리** | 분산된 상태 관리 | Orchestrator Agent가 중앙 집중식 관리 |
| **모듈 구조** | Agent별 기능 분산 | 모듈형 기능 + 명령 기반 실행 |

## 🚀 **구현 방향**

### 1. **Orchestrator Agent 강화**
- RAG 검색 엔진 통합
- LLM 프롬프트 엔진 통합
- Role Schema 관리자 구현
- 세션 관리자 구현

### 2. **모듈형 기능 구현**
- Pre-Generation 모듈들
- Core-Generation 모듈들
- Post-Generation 모듈들

### 3. **명령 기반 실행 Agent**
- 모든 Agent를 명령 수신자로 변경
- 자율적 판단 로직 제거
- Orchestrator Agent 명령만 실행

이제 **COGO Agent Core의 올바른 철학**에 맞는 아키텍처로 수정되었습니다! 🎉 