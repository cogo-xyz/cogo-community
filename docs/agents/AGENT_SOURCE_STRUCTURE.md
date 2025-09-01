# COGO Agent Source Structure

## 📁 전체 소스 구조

```
src/agents/
├── expert/                          # 전문 에이전트들
│   ├── COGOIntelligenceOrchestratorFast.ts
│   ├── architecture/
│   │   ├── RecommendationEngine.ts
│   │   └── ArchitectureAnalysisAgent.ts
│   └── codefix/
│       ├── CodeFixProcessor.ts
│       ├── TestGenerator.ts
│       └── PerformanceOptimizer.ts
├── research/
│   └── GoogleDeepResearchAgent.ts
├── code-generation/
│   └── COGOCodeGenerationAgent.ts
├── worker/
│   └── CogoWorkerManager.ts
├── planner/
│   └── TaskManager.ts
├── gateway/
│   └── ArchGW.ts
├── indexer/
│   └── IndexingWorker.ts
├── chain/                           # 리팩토링된 PromptChain 모듈들
│   ├── ChainTemplateManager.ts
│   ├── AgentRegistry.ts
│   ├── VariableManager.ts
│   ├── ChainExecutionEngine.ts
│   ├── ChainStateManager.ts
│   └── ResultAnalyzer.ts
├── mentoring/                       # 리팩토링된 MentoringPoolManager 모듈들
│   ├── ProfileManager.ts
│   ├── InteractionManager.ts
│   ├── KnowledgeIntegrator.ts
│   ├── SessionManager.ts
│   ├── SessionManagerImpl.ts
│   ├── MatchmakingEngine.ts
│   └── BackgroundProcessor.ts
├── database/                        # 리팩토링된 DatabaseManager 모듈들
│   ├── ConnectionManager.ts
│   ├── SchemaManager.ts
│   ├── QueryExecutor.ts
│   ├── TaskManager.ts
│   ├── AgentManager.ts
│   └── SchedulerManager.ts
├── collaboration/                   # 리팩토링된 CollaborationSessionManager 모듈들
│   ├── SessionManager.ts
│   ├── MessageProcessor.ts
│   ├── CollaborationMetricsManager.ts
│   └── CollaborationBackgroundProcessor.ts
├── blueprint/                       # 리팩토링된 BlueprintManager 모듈들
│   ├── BlueprintCreator.ts
│   ├── CodeGenerator.ts
│   ├── CodeValidator.ts
│   └── LearningManager.ts
├── PromptChainRefactored.ts         # 리팩토링된 메인 클래스들
├── MentoringPoolManagerRefactored.ts
├── DatabaseManagerRefactored.ts
├── CollaborationSessionManagerRefactored.ts
└── BlueprintManagerRefactored.ts
```

## 🔧 리팩토링된 모듈 상세 분석

### 1. PromptChain 모듈화 (`src/agents/chain/`)

#### ChainTemplateManager.ts
```typescript
interface ChainTemplate {
  id: string;
  name: string;
  description: string;
  steps: ChainStep[];
  variables: VariableDefinition[];
}

class ChainTemplateManager {
  createTemplate(template: ChainTemplate): Promise<void>
  getTemplate(id: string): ChainTemplate | undefined
  updateTemplate(id: string, template: ChainTemplate): Promise<void>
  deleteTemplate(id: string): Promise<void>
  listTemplates(): ChainTemplate[]
}
```

#### AgentRegistry.ts
```typescript
interface RegisteredAgent {
  id: string;
  name: string;
  type: string;
  capabilities: string[];
  status: 'available' | 'busy' | 'offline';
}

class AgentRegistry {
  registerAgent(agent: RegisteredAgent): Promise<void>
  unregisterAgent(agentId: string): Promise<void>
  getAvailableAgents(): RegisteredAgent[]
  findAgentByCapability(capability: string): RegisteredAgent[]
}
```

#### VariableManager.ts
```typescript
interface VariableDefinition {
  name: string;
  type: 'string' | 'number' | 'boolean' | 'object';
  required: boolean;
  defaultValue?: any;
}

class VariableManager {
  setVariable(name: string, value: any): void
  getVariable(name: string): any
  validateVariables(variables: Record<string, any>): ValidationResult
  clearVariables(): void
}
```

#### ChainExecutionEngine.ts
```typescript
interface ChainStep {
  id: string;
  name: string;
  agentId: string;
  inputs: string[];
  outputs: string[];
  timeout?: number;
}

class ChainExecutionEngine {
  executeChain(chainId: string, variables: Record<string, any>): Promise<ChainResult>
  executeStep(step: ChainStep, context: ChainContext): Promise<StepResult>
  handleStepError(error: Error, step: ChainStep): Promise<void>
}
```

#### ChainStateManager.ts
```typescript
interface ChainState {
  chainId: string;
  status: 'running' | 'completed' | 'failed' | 'paused';
  currentStep: string;
  variables: Record<string, any>;
  results: Record<string, any>;
  startTime: Date;
  endTime?: Date;
}

class ChainStateManager {
  createState(chainId: string): ChainState
  updateState(state: ChainState): void
  getState(chainId: string): ChainState | undefined
  clearState(chainId: string): void
}
```

#### ResultAnalyzer.ts
```typescript
interface ChainResult {
  success: boolean;
  data: any;
  errors: string[];
  performance: PerformanceMetrics;
  recommendations: string[];
}

class ResultAnalyzer {
  analyzeResult(result: ChainResult): AnalysisReport
  generateRecommendations(result: ChainResult): string[]
  calculatePerformanceMetrics(result: ChainResult): PerformanceMetrics
}
```

### 2. MentoringPoolManager 모듈화 (`src/agents/mentoring/`)

#### ProfileManager.ts
```typescript
interface MentorProfile {
  id: string;
  name: string;
  expertise: string[];
  experience: number;
  rating: number;
  availability: boolean;
  currentSessions: number;
  maxSessions: number;
}

interface MenteeProfile {
  id: string;
  name: string;
  level: 'junior' | 'mid' | 'senior';
  interests: string[];
  goals: string[];
  currentMentor?: string;
  progress: number;
}

class ProfileManager {
  createMentorProfile(profile: MentorProfile): Promise<void>
  createMenteeProfile(profile: MenteeProfile): Promise<void>
  updateProfile(id: string, updates: Partial<MentorProfile | MenteeProfile>): Promise<void>
  getProfile(id: string): MentorProfile | MenteeProfile | undefined
}
```

#### SessionManager.ts
```typescript
interface MentoringSession {
  id: string;
  mentorId: string;
  menteeId: string;
  status: 'scheduled' | 'active' | 'completed' | 'cancelled';
  startTime: Date;
  endTime?: Date;
  topic: string;
  goals: string[];
  notes: string[];
}

class SessionManager {
  createSession(session: MentoringSession): Promise<void>
  startSession(sessionId: string): Promise<void>
  endSession(sessionId: string): Promise<void>
  getActiveSessions(): MentoringSession[]
}
```

#### MatchmakingEngine.ts
```typescript
interface MatchCriteria {
  menteeId: string;
  requiredExpertise: string[];
  preferredExperience: number;
  availability: Date[];
}

interface MatchResult {
  mentorId: string;
  score: number;
  reasons: string[];
  availability: Date[];
}

class MatchmakingEngine {
  findBestMatch(criteria: MatchCriteria): Promise<MatchResult>
  calculateCompatibilityScore(mentor: MentorProfile, mentee: MenteeProfile): number
  rankMatches(matches: MatchResult[]): MatchResult[]
}
```

#### InteractionManager.ts
```typescript
interface MentoringInteraction {
  id: string;
  sessionId: string;
  type: 'question' | 'feedback' | 'guidance' | 'review';
  content: string;
  timestamp: Date;
  sender: 'mentor' | 'mentee';
  importance: 'low' | 'medium' | 'high';
}

class InteractionManager {
  recordInteraction(interaction: MentoringInteraction): Promise<void>
  getSessionInteractions(sessionId: string): MentoringInteraction[]
  analyzeInteractionPatterns(sessionId: string): InteractionAnalysis
}
```

### 3. DatabaseManager 모듈화 (`src/agents/database/`)

#### ConnectionManager.ts
```typescript
interface DatabaseConfig {
  host: string;
  port: number;
  database: string;
  username: string;
  password: string;
  poolSize: number;
}

class ConnectionManager {
  connect(config: DatabaseConfig): Promise<void>
  disconnect(): Promise<void>
  getConnection(): DatabaseConnection
  isConnected(): boolean
  healthCheck(): Promise<HealthStatus>
}
```

#### SchemaManager.ts
```typescript
interface TableSchema {
  name: string;
  columns: ColumnDefinition[];
  indexes: IndexDefinition[];
  constraints: ConstraintDefinition[];
}

class SchemaManager {
  createTable(schema: TableSchema): Promise<void>
  alterTable(tableName: string, changes: SchemaChanges): Promise<void>
  dropTable(tableName: string): Promise<void>
  getTableSchema(tableName: string): TableSchema | undefined
  validateSchema(schema: TableSchema): ValidationResult
}
```

#### QueryExecutor.ts
```typescript
interface QueryOptions {
  timeout?: number;
  retries?: number;
  cache?: boolean;
  transaction?: boolean;
}

class QueryExecutor {
  executeQuery(sql: string, params?: any[], options?: QueryOptions): Promise<QueryResult>
  executeTransaction(queries: Query[]): Promise<TransactionResult>
  prepareStatement(sql: string): PreparedStatement
  batchExecute(queries: string[]): Promise<BatchResult>
}
```

#### TaskManager.ts
```typescript
interface DatabaseTask {
  id: string;
  type: 'query' | 'migration' | 'backup' | 'optimization';
  priority: 'low' | 'medium' | 'high' | 'critical';
  status: 'pending' | 'running' | 'completed' | 'failed';
  sql: string;
  params?: any[];
  createdAt: Date;
  startedAt?: Date;
  completedAt?: Date;
}

class TaskManager {
  scheduleTask(task: DatabaseTask): Promise<void>
  executeTask(taskId: string): Promise<TaskResult>
  getTaskStatus(taskId: string): TaskStatus
  cancelTask(taskId: string): Promise<void>
  getPendingTasks(): DatabaseTask[]
}
```

### 4. CollaborationSessionManager 모듈화 (`src/agents/collaboration/`)

#### SessionManager.ts
```typescript
interface CollaborationSession {
  id: string;
  name: string;
  description: string;
  type: 'custom' | 'collaboration' | 'review' | 'mentoring';
  status: 'active' | 'paused' | 'completed' | 'cancelled';
  participants: CollaborationParticipant[];
  messages: CollaborationMessage[];
  decisions: CollaborationDecision[];
  resources: CollaborationResource[];
  createdAt: Date;
  updatedAt: Date;
}

interface CollaborationParticipant {
  agentId: string;
  name: string;
  role: string;
  joinedAt: Date;
  lastActivity: Date;
  contribution: number;
}

class SessionManager {
  createSession(session: CollaborationSession): Promise<string>
  joinSession(sessionId: string, participant: CollaborationParticipant): Promise<void>
  leaveSession(sessionId: string, agentId: string): Promise<void>
  getSession(sessionId: string): CollaborationSession | undefined
  listActiveSessions(): CollaborationSession[]
}
```

#### MessageProcessor.ts
```typescript
interface CollaborationMessage {
  id: string;
  sessionId: string;
  senderId: string;
  type: 'text' | 'code' | 'file' | 'decision' | 'action';
  content: string;
  metadata?: Record<string, any>;
  timestamp: Date;
  importance: 'low' | 'medium' | 'high' | 'critical';
  reactions: MessageReaction[];
}

class MessageProcessor {
  sendMessage(message: CollaborationMessage): Promise<void>
  getSessionMessages(sessionId: string, limit?: number): CollaborationMessage[]
  searchMessages(sessionId: string, query: string): CollaborationMessage[]
  addReaction(messageId: string, reaction: MessageReaction): Promise<void>
}
```

#### CollaborationMetricsManager.ts
```typescript
interface CollaborationMetrics {
  sessionId: string;
  participantCount: number;
  messageCount: number;
  averageResponseTime: number;
  participationRate: number;
  decisionQuality: number;
  collaborationScore: number;
  timestamp: Date;
}

class CollaborationMetricsManager {
  calculateMetrics(sessionId: string): CollaborationMetrics
  trackParticipation(sessionId: string, agentId: string): void
  measureResponseTime(sessionId: string, messageId: string): number
  generateReport(sessionId: string): CollaborationReport
}
```

### 5. BlueprintManager 모듈화 (`src/agents/blueprint/`)

#### BlueprintCreator.ts
```typescript
interface CodeBlueprint {
  id: string;
  name: string;
  description: string;
  requirements: string[];
  architecture: SystemArchitecture;
  fileStructure: FileStructure[];
  dependencies: string[];
  validationRules: ValidationRule[];
  estimatedComplexity: number;
  createdAt: Date;
  updatedAt: Date;
}

interface SystemArchitecture {
  components: Component[];
  relationships: Relationship[];
  patterns: DesignPattern[];
  constraints: Constraint[];
}

class BlueprintCreator {
  createBlueprint(request: BlueprintRequest): Promise<CodeBlueprint>
  analyzeRequirements(requirements: string[]): RequirementAnalysis
  designArchitecture(analysis: RequirementAnalysis): SystemArchitecture
  generateFileStructure(architecture: SystemArchitecture): FileStructure[]
  estimateComplexity(blueprint: CodeBlueprint): number
}
```

#### CodeGenerator.ts
```typescript
interface CodeGenerationResult {
  id: string;
  blueprintId: string;
  status: 'generating' | 'completed' | 'failed';
  files: GeneratedFile[];
  qualityScore: number;
  validationResults: ValidationResult[];
  generationTime: number;
  createdAt: Date;
  completedAt?: Date;
}

interface GeneratedFile {
  path: string;
  content: string;
  language: string;
  size: number;
  complexity: number;
  quality: number;
}

class CodeGenerator {
  generateCode(blueprint: CodeBlueprint): Promise<CodeGenerationResult>
  generateFile(fileSpec: FileStructure, context: GenerationContext): Promise<GeneratedFile>
  validateGeneratedCode(files: GeneratedFile[]): ValidationResult[]
  calculateQualityScore(files: GeneratedFile[]): number
}
```

#### CodeValidator.ts
```typescript
interface ValidationRule {
  id: string;
  name: string;
  type: 'syntax' | 'semantic' | 'style' | 'security' | 'performance';
  severity: 'low' | 'medium' | 'high' | 'critical';
  rule: string;
  description: string;
}

interface ValidationResult {
  ruleId: string;
  status: 'passed' | 'failed' | 'warning';
  message: string;
  location?: CodeLocation;
  severity: 'low' | 'medium' | 'high' | 'critical';
}

class CodeValidator {
  validateCode(files: GeneratedFile[], rules: ValidationRule[]): ValidationResult[]
  validateSyntax(file: GeneratedFile): ValidationResult[]
  validateSecurity(file: GeneratedFile): ValidationResult[]
  validatePerformance(file: GeneratedFile): ValidationResult[]
  generateReport(results: ValidationResult[]): ValidationReport
}
```

#### LearningManager.ts
```typescript
interface LearningEvent {
  id: string;
  type: 'success' | 'failure' | 'improvement';
  blueprintId: string;
  generationId: string;
  insights: string[];
  patterns: Pattern[];
  recommendations: string[];
  timestamp: Date;
}

class LearningManager {
  recordLearningEvent(event: LearningEvent): Promise<void>
  analyzePatterns(events: LearningEvent[]): PatternAnalysis
  updateKnowledgeBase(insights: string[]): Promise<void>
  generateRecommendations(blueprint: CodeBlueprint): string[]
  improveBlueprint(blueprint: CodeBlueprint, learnings: LearningEvent[]): CodeBlueprint
}
```

## 🔄 메인 리팩토링된 클래스들

### PromptChainRefactored.ts
```typescript
export class PromptChainRefactored extends EventEmitter {
  private templateManager: ChainTemplateManager;
  private agentRegistry: AgentRegistry;
  private variableManager: VariableManager;
  private executionEngine: ChainExecutionEngine;
  private stateManager: ChainStateManager;
  private resultAnalyzer: ResultAnalyzer;

  constructor(aiClients: AIClients, knowledgeManager: HybridKnowledgeManager) {
    // 초기화 로직
  }

  public async executeChain(chainId: string, variables: Record<string, any>): Promise<ChainResult> {
    // 체인 실행 로직
  }

  public async createTemplate(template: ChainTemplate): Promise<void> {
    // 템플릿 생성 로직
  }
}
```

### MentoringPoolManagerRefactored.ts
```typescript
export class MentoringPoolManagerRefactored extends EventEmitter {
  private profileManager: ProfileManager;
  private sessionManager: SessionManager;
  private matchmakingEngine: MatchmakingEngine;
  private interactionManager: InteractionManager;
  private knowledgeIntegrator: KnowledgeIntegrator;
  private backgroundProcessor: BackgroundProcessor;

  constructor(knowledgeManager: HybridKnowledgeManager, aiClients: AIClients) {
    // 초기화 로직
  }

  public async createMentoringSession(mentorId: string, menteeId: string, topic: string): Promise<string> {
    // 멘토링 세션 생성 로직
  }

  public async findBestMentor(menteeId: string, requirements: string[]): Promise<string> {
    // 최적 멘토 매칭 로직
  }
}
```

### DatabaseManagerRefactored.ts
```typescript
export class DatabaseManagerRefactored extends EventEmitter {
  private connectionManager: ConnectionManager;
  private schemaManager: SchemaManager;
  private queryExecutor: QueryExecutor;
  private taskManager: TaskManager;
  private agentManager: AgentManager;
  private schedulerManager: SchedulerManager;

  constructor() {
    // 초기화 로직
  }

  public async initializeDatabase(): Promise<void> {
    // 데이터베이스 초기화 로직
  }

  public async executeQuery(sql: string, params?: any[]): Promise<QueryResult> {
    // 쿼리 실행 로직
  }
}
```

### CollaborationSessionManagerRefactored.ts
```typescript
export class CollaborationSessionManagerRefactored extends EventEmitter {
  private sessionManager: SessionManager;
  private messageProcessor: MessageProcessor;
  private metricsManager: CollaborationMetricsManager;
  private backgroundProcessor: CollaborationBackgroundProcessor;

  constructor() {
    // 초기화 로직
  }

  public async createCollaborationSession(
    name: string,
    description: string,
    sessionType: string,
    participants: CollaborationParticipant[]
  ): Promise<string> {
    // 협업 세션 생성 로직
  }

  public async sendMessage(sessionId: string, message: CollaborationMessage): Promise<void> {
    // 메시지 전송 로직
  }
}
```

### BlueprintManagerRefactored.ts
```typescript
export class BlueprintManagerRefactored extends EventEmitter {
  private blueprintCreator: BlueprintCreator;
  private codeGenerator: CodeGenerator;
  private codeValidator: CodeValidator;
  private learningManager: LearningManager;

  constructor(aiClients: AIClients, knowledgeManager: HybridKnowledgeManager) {
    // 초기화 로직
  }

  public async createCodeBlueprint(request: any): Promise<CodeBlueprint> {
    // 코드 블루프린트 생성 로직
  }

  public async executeParallelGenerationWithValidation(blueprint: CodeBlueprint): Promise<CodeGenerationResult> {
    // 병렬 코드 생성 및 검증 로직
  }
}
```

## 📊 모듈 간 의존성 관계

```
COGOWorkflowManager
├── MentoringPoolManagerRefactored
│   ├── ProfileManager
│   ├── SessionManager
│   ├── MatchmakingEngine
│   └── InteractionManager
├── CollaborationSessionManagerRefactored
│   ├── SessionManager
│   ├── MessageProcessor
│   └── CollaborationMetricsManager
├── DatabaseManagerRefactored
│   ├── ConnectionManager
│   ├── SchemaManager
│   └── QueryExecutor
└── BlueprintManagerRefactored
    ├── BlueprintCreator
    ├── CodeGenerator
    ├── CodeValidator
    └── LearningManager

HybridKnowledgeManager
├── VectorStoreService
└── Neo4jKnowledgeGraph

AIClients
├── ClaudeClient
├── GeminiClient
└── OpenAIClient
```

## 🎯 리팩토링 효과

### 1. 단일 책임 원칙 (SRP)
- 각 모듈이 하나의 명확한 책임을 가짐
- 코드의 가독성과 유지보수성 향상

### 2. 의존성 주입 (DI)
- 모듈 간 느슨한 결합
- 테스트 용이성 향상
- 확장성 개선

### 3. 이벤트 기반 아키텍처
- EventEmitter를 통한 모듈 간 통신
- 비동기 처리 최적화
- 실시간 상태 업데이트

### 4. 인터페이스 분리
- 명확한 계약 정의
- 구현체 교체 용이
- API 안정성 보장

---

**문서 생성일**: 2025년 7월 31일  
**리팩토링 완료일**: 2025년 7월 31일  
**문서 버전**: 2.0 