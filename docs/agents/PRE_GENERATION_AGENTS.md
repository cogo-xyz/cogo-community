# 사전 생성 프레임워크 - 새로운 에이전트 상세 설명

## 🧠 **Complexity Analyzer Agent** (`cogo-complexity-analyzer-01`)

### 목적
요구사항 복잡도를 정량적으로 평가하고 분류하여 적절한 처리 경로를 결정합니다.

### 핵심 기능
- **CRCD 메트릭 계산**: 요구사항 및 비용 동인 기반 복잡도 측정
- **SMART+C 분석**: 구체적, 측정 가능, 달성 가능, 관련성, 시간제한, 도전적 평가
- **모호성 검사**: 모호한 용어 식별 및 점수화
- **원자성 검사**: 복합 요구사항 분해 필요성 판단
- **신뢰도 계산**: 분석 결과의 신뢰도 수치화

### 처리 과정
```typescript
interface ComplexityAnalysis {
  requirementId: string;
  crcdMetrics: {
    basicFactor: number;        // 기본 요인
    requirementFactor: number;  // 요구사항 요인
    userTerminalFactor: number; // 사용자-터미널 요인
    productFactor: number;      // 제품 요인
    personnelFactor: number;    // 인력 요인
    projectFactor: number;      // 프로젝트 요인
    finalComplexity: number;    // 최종 복잡도
  };
  smartCAnalysis: {
    specific: boolean;
    measurable: boolean;
    achievable: boolean;
    relevant: boolean;
    timed: boolean;
    challenging: boolean;
    overallScore: number;
    issues: string[];
  };
  finalClassification: 'simple' | 'complex';
  confidence: number;
  recommendations: string[];
}
```

### 성능 지표
- **처리 시간**: 1-3초
- **정확도**: 85-95%
- **동시 처리**: 최대 10개 요구사항

---

## 🔍 **Knowledge Base Search Agent** (`cogo-knowledge-search-01`)

### 목적
Neo4j 지식 그래프와 Supabase pgvector를 활용한 하이브리드 검색으로 기존 솔루션을 찾습니다.

### 핵심 기능
- **Neo4j 검색**: 구조화된 지식 그래프 검색
- **pgvector 검색**: 의미론적 벡터 검색
- **하이브리드 통합**: 두 검색 결과의 지능적 통합
- **캐싱 시스템**: 검색 결과 캐싱으로 성능 최적화
- **컨텍스트 제공**: 관련 코드, 문서, 패턴 제공

### 검색 프로세스
```typescript
interface HybridSearchResult {
  query: SearchQuery;
  results: SearchResult[];
  kgResults: SearchResult[];      // Neo4j 결과
  vectorResults: SearchResult[];  // pgvector 결과
  stats: {
    totalResults: number;
    kgResults: number;
    vectorResults: number;
    averageSimilarity: number;
    searchTime: number;
  };
  recommendations: string[];
}
```

### 성능 지표
- **처리 시간**: 2-5초
- **정확도**: 80-90%
- **캐시 히트율**: 60-80%

---

## 🎯 **Prompt Generation Engine Agent** (`cogo-prompt-engine-01`)

### 목적
요구사항과 컨텍스트를 바탕으로 AI 모델용 최적화된 프롬프트를 생성합니다.

### 프롬프트 기술
1. **페르소나 기반**: 시니어 개발자, 아키텍트 등 역할 기반
2. **참조 기반**: 기존 코드 패턴 참조
3. **체인-오브-솝트**: 단계별 사고 과정 유도
4. **하이브리드**: 여러 기술 조합

### 페르소나 정의
```typescript
const COGO_PERSONAS = [
  {
    id: 'senior-architect',
    name: 'Senior Software Architect',
    role: 'Lead the architectural design and technical decisions',
    expertise: ['system design', 'scalability', 'performance', 'security', 'patterns'],
    background: '20+ years of experience in enterprise software development',
    communicationStyle: 'Analytical and strategic, focusing on long-term maintainability'
  },
  {
    id: 'senior-developer',
    name: 'Senior Software Developer',
    role: 'Implement high-quality, maintainable code',
    expertise: ['clean code', 'design patterns', 'testing', 'refactoring', 'best practices'],
    background: '15+ years of experience in software development',
    communicationStyle: 'Practical and pragmatic, focusing on code quality and maintainability'
  }
];
```

### 성능 지표
- **처리 시간**: 1-2초
- **정확도**: 90-95%
- **프롬프트 품질**: 높은 AI 모델 이해도

---

## 📋 **Requirement Processor Agent** (`cogo-requirement-processor-01`)

### 목적
자연어 요구사항을 구조화된 요구사항 문서로 변환합니다.

### 처리 과정
1. **자연어 파싱**: 텍스트 분석 및 구조화
2. **요구사항 분류**: 기능적/비기능적 요구사항 구분
3. **정보 추출**: 입력/출력/사용자/터미널 정보 식별
4. **검증 및 보완**: 누락된 정보 자동 보완

### 출력 구조
```typescript
interface RequirementDocument {
  id: string;
  title: string;
  description: string;
  functionalRequirements: FunctionalRequirement[];
  nonFunctionalRequirements: NonFunctionalRequirement[];
  inputs: InputOutput[];
  outputs: InputOutput[];
  externalFiles: ExternalFile[];
  interfaceFiles: InterfaceFile[];
  users: User[];
  terminals: Terminal[];
  metadata: Record<string, any>;
}
```

### 성능 지표
- **처리 시간**: 3-5초
- **정확도**: 85-90%
- **지원 언어**: 한국어, 영어

---

## 🧩 **Semantic Analyzer Agent** (`cogo-semantic-analyzer-01`)

### 목적
요구사항의 숨겨진 의미와 패턴을 발견하여 최적의 기술 스택과 아키텍처를 추천합니다.

### 분석 영역
- **도메인 분석**: 비즈니스 도메인 식별
- **패턴 인식**: 아키텍처 패턴 매칭
- **기술 스택 추천**: 적합한 기술 조합 제안
- **의존성 분석**: 시스템 의존성 식별
- **제약사항 파악**: 기술적/비즈니스 제약사항 분석

### 분석 결과
```typescript
interface SemanticAnalysis {
  domain: string;                    // 도메인 (web, api, data, security 등)
  patterns: string[];                // 아키텍처 패턴
  technologyStack: string[];         // 추천 기술 스택
  architecturePatterns: string[];    // 아키텍처 패턴
  dependencies: string[];            // 의존성 목록
  constraints: string[];             // 제약사항
  recommendations: string[];         // 추천사항
}
```

### 성능 지표
- **처리 시간**: 2-4초
- **정확도**: 80-85%
- **패턴 인식률**: 75-85%

---

## 🚦 **Workflow Router Agent** (`cogo-workflow-router-01`)

### 목적
복잡도 분석 결과를 바탕으로 최적의 워크플로우를 선택하고 에이전트 시퀀스를 결정합니다.

### 라우팅 로직
1. **복잡도 기반 분류**: Simple/Complex 결정
2. **워크플로우 매칭**: 적합한 템플릿 선택
3. **에이전트 할당**: 필요한 에이전트 시퀀스 결정
4. **리소스 최적화**: 처리 시간 및 리소스 예측

### 워크플로우 타입
```typescript
interface WorkflowRoute {
  workflowId: string;
  workflowType: 'simple' | 'complex';
  agentSequence: string[];           // 에이전트 실행 순서
  estimatedDuration: number;         // 예상 처리 시간
  priority: 'low' | 'medium' | 'high';
  dependencies: string[];            // 의존성 목록
  fallbackPlan?: string;             // 대체 계획
}
```

### 워크플로우 템플릿
```yaml
# 단순 워크플로우
simple_workflow:
  - requirement_processing: 10s
  - complexity_analysis: 5s
  - knowledge_search: 8s
  - prompt_generation: 3s
  - code_generation: 30s
  - indexing: 5s

# 복잡한 워크플로우
complex_workflow:
  - requirement_processing: 15s
  - complexity_analysis: 10s
  - semantic_analysis: 12s
  - knowledge_search: 15s
  - workflow_routing: 5s
  - prompt_generation: 8s
  - orchestration: 60s
  - code_generation: 120s
  - research: 30s
  - indexing: 10s
```

### 성능 지표
- **처리 시간**: 1-2초
- **정확도**: 95-98%
- **라우팅 성공률**: 98%+

---

## 🔄 **에이전트 간 통신**

### 메시지 구조
```typescript
interface PreGenerationMessage {
  id: string;
  type: PreGenerationMessageType;
  sender: string;
  receiver: string;
  payload: any;
  timestamp: Date;
  workflowId: string;
  stage: 'pre-generation';
}

enum PreGenerationMessageType {
  REQUIREMENT_PROCESSED = 'requirement_processed',
  COMPLEXITY_ANALYZED = 'complexity_analyzed',
  KNOWLEDGE_SEARCHED = 'knowledge_searched',
  SEMANTIC_ANALYZED = 'semantic_analyzed',
  WORKFLOW_ROUTED = 'workflow_routed',
  PROMPT_GENERATED = 'prompt_generated',
  FRAMEWORK_COMPLETED = 'framework_completed'
}
```

### Supabase Real-time 채널
```typescript
const PRE_GENERATION_CHANNELS = {
  COMPLEXITY_ANALYSIS: 'complexity-analysis',
  KNOWLEDGE_SEARCH: 'knowledge-search',
  PROMPT_GENERATION: 'prompt-generation',
  WORKFLOW_ROUTING: 'workflow-routing',
  PRE_GENERATION_EVENTS: 'pre-generation-events'
};
```

---

## 📊 **성능 모니터링**

### 메트릭 수집
```typescript
interface PreGenerationMetrics {
  totalRequirements: number;
  simpleRequirements: number;
  complexRequirements: number;
  averageProcessingTime: number;
  successRate: number;
  knowledgeSearchHitRate: number;
  promptGenerationAccuracy: number;
  workflowRoutingAccuracy: number;
}
```

### 상태 모니터링
```typescript
interface PreGenerationAgentStatus {
  id: string;
  name: string;
  type: string;
  status: 'idle' | 'processing' | 'completed' | 'error';
  currentTask?: string;
  processedCount: number;
  successRate: number;
  averageProcessingTime: number;
  lastActivity: Date;
  metadata: {
    complexityAnalysisCount: number;
    knowledgeSearchCount: number;
    promptGenerationCount: number;
    workflowRoutingCount: number;
  };
}
```

---

## 🚀 **구현 가이드라인**

### 에이전트 구현 패턴
```typescript
export class PreGenerationAgent extends BaseAgent {
  private service: PreGenerationService;

  constructor() {
    super('cogo-agent-id', 'Agent Name', 'agent-type');
    this.service = new PreGenerationService();
  }

  async initialize(): Promise<void> {
    await this.service.initialize();
    this.status = 'ready';
  }

  async executeTask(task: Task): Promise<boolean> {
    try {
      const result = await this.service.process(task.payload);
      
      task.result = {
        output: result,
        status: 'completed',
        timestamp: new Date().toISOString()
      };
      
      return true;
    } catch (error) {
      task.result = {
        error: error.message,
        status: 'failed',
        timestamp: new Date().toISOString()
      };
      return false;
    }
  }
}
```

### 에러 처리 및 복구
```typescript
async function robustTaskExecution(task: Task, maxRetries: number = 3): Promise<boolean> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const result = await executeTask(task);
      if (result) return true;
    } catch (error) {
      console.error(`Attempt ${attempt} failed:`, error);
      
      if (attempt === maxRetries) {
        task.result = {
          error: error.message,
          status: 'failed',
          timestamp: new Date().toISOString()
        };
        return false;
      }
      
      // 지수 백오프
      await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 1000));
    }
  }
  
  return false;
}
```

---

## 🎯 **결론**

사전 생성 프레임워크의 새로운 에이전트들은 COGO Agent Core에 다음과 같은 혁신적인 기능을 제공합니다:

1. **자동화된 복잡도 평가**: 객관적이고 정량적인 요구사항 분석
2. **지능형 지식 검색**: 하이브리드 검색으로 최적 솔루션 발견
3. **최적화된 프롬프트 생성**: 다양한 기술을 활용한 고품질 프롬프트
4. **차별화된 워크플로우**: 복잡도에 따른 최적 처리 경로
5. **실시간 협업**: 에이전트 간 효율적인 통신 및 협업

이러한 에이전트들이 협력하여 COGO Agent Core를 단순한 코드 생성 도구를 넘어 AI 기반의 지능형 소프트웨어 개발 생태계로 발전시킵니다. 