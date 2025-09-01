# COGO 플랫폼 기반 creatego-packages 리팩토링 계획

**목표**: creatego-packages를 COGO 플랫폼의 핵심 원칙과 아키텍처에 맞게 완전히 리팩토링

**현재 상태**: Flutter 패키지 기반의 독립적 라이브러리
**목표 상태**: COGO 분산 에이전트 시스템의 핵심 컴포넌트

---

## 1. COGO 플랫폼 핵심 원칙

### 1.1 분산 아키텍처 원칙
```typescript
// 현재: 단일 Flutter 패키지
creatego_interface/
  creatego_store/
  creatego_action/
  creatego_layout/

// 목표: COGO 분산 에이전트들
cogo-ui-agent/          // UI 컴포넌트 관리 에이전트
cogo-store-agent/       // 상태 관리 에이전트
cogo-action-agent/      // 액션 실행 에이전트
cogo-layout-agent/      // 레이아웃 관리 에이전트
```

### 1.2 실시간 통신 기반
```typescript
// Supabase Real-time 채널 통합
const CHANNELS = {
  UI_UPDATES: 'cogo-ui-updates',
  STATE_CHANGES: 'cogo-state-changes',
  ACTION_EVENTS: 'cogo-action-events',
  LAYOUT_CHANGES: 'cogo-layout-changes'
};
```

### 1.3 에이전트 중심 아키텍처
```typescript
// 모든 컴포넌트를 에이전트로 변환
export class CogoUiAgent extends BaseCogoAgent {
  readonly agentId = 'cogo-ui-agent-01';
  readonly capabilities = ['ui_component_management', 'widget_lifecycle'];
}

export class CogoStoreAgent extends BaseCogoAgent {
  readonly agentId = 'cogo-store-agent-01';
  readonly capabilities = ['state_management', 'data_persistence'];
}
```

### 1.4 스키마 중심 데이터 관리
```sql
-- cogo 스키마 사용 (public이 아닌)
CREATE SCHEMA IF NOT EXISTS cogo;

-- UI 컴포넌트 메타데이터
CREATE TABLE cogo.ui_components (
  id UUID PRIMARY KEY,
  component_type VARCHAR(50) NOT NULL,
  props JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 상태 관리
CREATE TABLE cogo.agent_states (
  agent_id VARCHAR(50) PRIMARY KEY,
  state JSONB,
  last_updated TIMESTAMP DEFAULT NOW()
);
```

---

## 2. 리팩토링 아키텍처 설계

### 2.1 패키지 구조 재설계

```
cogo-agent-packages/
├── cogo-ui-agent/              # UI 컴포넌트 관리 에이전트
│   ├── src/
│   │   ├── core/               # UI 코어 로직
│   │   ├── widgets/            # 위젯 라이브러리
│   │   ├── themes/             # 테마 시스템
│   │   └── realtime/           # 실시간 UI 업데이트
│   ├── docker/
│   │   ├── Dockerfile
│   │   └── docker-compose.yml
│   └── tests/
├── cogo-store-agent/           # 상태 관리 에이전트
│   ├── src/
│   │   ├── managers/           # 매니저 클래스들
│   │   ├── persistence/        # 데이터 영속화
│   │   ├── realtime/           # 실시간 상태 동기화
│   │   └── schema/             # 데이터베이스 스키마
│   └── docker/
├── cogo-action-agent/          # 액션 실행 에이전트
│   ├── src/
│   │   ├── actions/            # 액션 라이브러리
│   │   ├── workflows/          # LangGraph 워크플로우
│   │   ├── execution/          # 액션 실행 엔진
│   │   └── realtime/           # 실시간 액션 이벤트
│   └── docker/
├── cogo-layout-agent/          # 레이아웃 관리 에이전트
│   ├── src/
│   │   ├── managers/           # 레이아웃 매니저
│   │   ├── responsive/         # 반응형 레이아웃
│   │   ├── grid/               # 그리드 시스템
│   │   └── realtime/           # 실시간 레이아웃 변경
│   └── docker/
└── cogo-shared/                # 공유 라이브러리
    ├── src/
    │   ├── core/               # 공통 인터페이스
    │   ├── types/              # 타입 정의
    │   ├── utils/              # 유틸리티 함수
    │   └── realtime/           # 실시간 통신 래퍼
    └── docker/
```

### 2.2 에이전트 인터페이스 표준화

```typescript
// 모든 COGO 에이전트의 기본 인터페이스
export interface ICogoAgent {
  readonly agentId: string;
  readonly agentType: CogoAgentType;
  readonly capabilities: string[];

  initialize(): Promise<void>;
  executeTask(task: CogoTask): Promise<CogoTaskResult>;
  getStatus(): Promise<CogoAgentStatus>;
  shutdown(): Promise<void>;

  // 실시간 통신
  subscribeToChannel(channel: string): Promise<void>;
  publishToChannel(channel: string, message: any): Promise<void>;

  // 헬스 체크
  healthCheck(): Promise<HealthStatus>;
}

// 에이전트 상태 관리
export interface CogoAgentStatus {
  agentId: string;
  status: 'idle' | 'busy' | 'error' | 'shutdown';
  lastActivity: Date;
  tasksCompleted: number;
  errorCount: number;
  uptime: number;
}
```

---

## 3. 실시간 통신 아키텍처

### 3.1 Supabase Real-time 통합

```typescript
export class CogoRealtimeManager {
  private supabase: SupabaseClient;
  private channels: Map<string, RealtimeChannel> = new Map();

  async initialize() {
    this.supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_ANON_KEY!
    );

    // UI 업데이트 채널
    await this.createChannel('cogo-ui-updates', (payload) => {
      this.handleUiUpdate(payload);
    });

    // 상태 변경 채널
    await this.createChannel('cogo-state-changes', (payload) => {
      this.handleStateChange(payload);
    });
  }

  private async createChannel(channelName: string, handler: (payload: any) => void) {
    const channel = this.supabase.channel(channelName);
    channel.on('broadcast', { event: '*' }, ({ payload }) => handler(payload));

    await channel.subscribe();
    this.channels.set(channelName, channel);
  }
}
```

### 3.2 메시지 프로토콜 표준화

```typescript
export interface CogoMessage {
  id: string;
  traceId: string;           // 모든 메시지에 trace_id 포함
  sender: string;            // 송신 에이전트 ID
  receiver: string;          // 수신 에이전트 ID
  type: CogoMessageType;
  payload: any;
  timestamp: Date;
  priority: 'low' | 'normal' | 'high' | 'critical';
}

export enum CogoMessageType {
  // UI 관련 메시지
  UI_COMPONENT_UPDATE = 'ui_component_update',
  UI_LAYOUT_CHANGE = 'ui_layout_change',
  UI_THEME_CHANGE = 'ui_theme_change',

  // 상태 관련 메시지
  STATE_UPDATE = 'state_update',
  STATE_SYNC = 'state_sync',
  STATE_PERSIST = 'state_persist',

  // 액션 관련 메시지
  ACTION_EXECUTE = 'action_execute',
  ACTION_COMPLETE = 'action_complete',
  ACTION_ERROR = 'action_error',

  // 시스템 메시지
  HEALTH_CHECK = 'health_check',
  AGENT_STATUS = 'agent_status',
  SYSTEM_ALERT = 'system_alert'
}
```

---

## 4. LangGraph 워크플로우 통합

### 4.1 액션 워크플로우 설계

```typescript
// 액션 실행 워크플로우
export class ActionExecutionWorkflow {
  private graph: StateGraph;

  constructor() {
    this.graph = new StateGraph()
      .addNode('validate', this.validateAction.bind(this))
      .addNode('prepare', this.prepareExecution.bind(this))
      .addNode('execute', this.executeAction.bind(this))
      .addNode('verify', this.verifyResult.bind(this))
      .addNode('cleanup', this.cleanupResources.bind(this))

      .addEdge('validate', 'prepare')
      .addEdge('prepare', 'execute')
      .addConditionalEdges('execute',
        this.checkResult.bind(this),
        { success: 'verify', failure: 'cleanup' }
      )
      .addEdge('verify', 'cleanup');
  }

  private async validateAction(state: WorkflowState): Promise<WorkflowState> {
    // 액션 파라미터 검증
    const validation = await this.validateActionParams(state.action);
    if (!validation.isValid) {
      throw new Error(`Action validation failed: ${validation.errors.join(', ')}`);
    }
    return { ...state, validated: true };
  }

  private async executeAction(state: WorkflowState): Promise<WorkflowState> {
    // 실제 액션 실행
    const result = await this.actionExecutor.execute(state.action);
    return { ...state, result };
  }
}
```

### 4.2 UI 컴포넌트 생성 워크플로우

```typescript
export class UiComponentCreationWorkflow {
  private graph: StateGraph;

  constructor() {
    this.graph = new StateGraph()
      .addNode('analyze', this.analyzeRequirements.bind(this))
      .addNode('design', this.designComponent.bind(this))
      .addNode('generate', this.generateCode.bind(this))
      .addNode('integrate', this.integrateComponent.bind(this))
      .addNode('test', this.testComponent.bind(this))

      .addEdge('analyze', 'design')
      .addEdge('design', 'generate')
      .addEdge('generate', 'integrate')
      .addEdge('integrate', 'test');
  }
}
```

---

## 5. Docker 기반 분산 배포

### 5.1 각 에이전트의 독립적 Docker 구성

```dockerfile
# cogo-ui-agent/Dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]
```

```yaml
# cogo-ui-agent/docker-compose.yml
version: '3.8'
services:
  cogo-ui-agent:
    build: .
    ports:
      - "6101:3000"
    environment:
      - SUPABASE_URL=${SUPABASE_URL}
      - SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
      - AGENT_ID=cogo-ui-agent-01
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### 5.2 전체 시스템 Docker Compose

```yaml
# 전체 시스템 docker-compose.yml
version: '3.8'
services:
  cogo-ui-agent:
    build: ./cogo-ui-agent
    ports:
      - "6101:3000"
    depends_on:
      - supabase

  cogo-store-agent:
    build: ./cogo-store-agent
    ports:
      - "6102:3000"
    depends_on:
      - supabase

  cogo-action-agent:
    build: ./cogo-action-agent
    ports:
      - "6103:3000"
    depends_on:
      - supabase

  cogo-layout-agent:
    build: ./cogo-layout-agent
    ports:
      - "6104:3000"
    depends_on:
      - supabase

  cogo-orchestrator:
    build: ./cogo-orchestrator
    ports:
      - "6105:3000"
    depends_on:
      - cogo-ui-agent
      - cogo-store-agent
      - cogo-action-agent
      - cogo-layout-agent
```

---

## 6. 데이터베이스 스키마 설계

### 6.1 cogo 스키마 중심 데이터 모델

```sql
-- COGO 스키마 생성
CREATE SCHEMA IF NOT EXISTS cogo;

-- 에이전트 메타데이터
CREATE TABLE cogo.agents (
  id VARCHAR(50) PRIMARY KEY,
  type VARCHAR(30) NOT NULL,
  capabilities JSONB,
  status VARCHAR(20) DEFAULT 'idle',
  last_heartbeat TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- UI 컴포넌트 레지스트리
CREATE TABLE cogo.ui_components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id VARCHAR(50) REFERENCES cogo.agents(id),
  component_type VARCHAR(50) NOT NULL,
  component_name VARCHAR(100) NOT NULL,
  props JSONB,
  styles JSONB,
  dependencies JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 상태 스냅샷
CREATE TABLE cogo.state_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id VARCHAR(50) REFERENCES cogo.agents(id),
  state_key VARCHAR(100) NOT NULL,
  state_value JSONB,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 액션 로그
CREATE TABLE cogo.action_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trace_id VARCHAR(50) NOT NULL,
  agent_id VARCHAR(50) REFERENCES cogo.agents(id),
  action_type VARCHAR(50) NOT NULL,
  action_params JSONB,
  result JSONB,
  status VARCHAR(20) DEFAULT 'pending',
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 실시간 이벤트 로그
CREATE TABLE cogo.realtime_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trace_id VARCHAR(50) NOT NULL,
  channel VARCHAR(50) NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  payload JSONB,
  sender_agent_id VARCHAR(50),
  receiver_agent_id VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 6.2 pgvector를 활용한 벡터 검색

```sql
-- 벡터 확장 설치
CREATE EXTENSION IF NOT EXISTS vector;

-- 컴포넌트 임베딩
ALTER TABLE cogo.ui_components
ADD COLUMN embedding vector(1536);

-- 벡터 검색 인덱스
CREATE INDEX ON cogo.ui_components USING ivfflat (embedding vector_cosine_ops);

-- 유사 컴포넌트 검색 함수
CREATE OR REPLACE FUNCTION find_similar_components(query_embedding vector(1536), limit_count integer DEFAULT 10)
RETURNS TABLE (
  id UUID,
  component_name VARCHAR(100),
  similarity float
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    uc.id,
    uc.component_name,
    1 - (uc.embedding <=> query_embedding) as similarity
  FROM cogo.ui_components uc
  ORDER BY uc.embedding <=> query_embedding
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;
```

---

## 7. 구현 우선순위 및 단계

### Phase 1: 기반 인프라 구축 (2주)
1. **프로젝트 구조 재설계**
   - 패키지 이름을 cogo-*로 변경
   - 에이전트 기반 폴더 구조 생성
   - Docker 구성 파일 준비

2. **공통 라이브러리 개발**
   - ICogoAgent 인터페이스 구현
   - CogoRealtimeManager 개발
   - 공통 타입 정의

3. **데이터베이스 스키마 구축**
   - cogo 스키마 생성
   - 기본 테이블 및 인덱스 생성
   - 마이그레이션 스크립트 작성

### Phase 2: 코어 에이전트 개발 (3주)
1. **cogo-ui-agent 개발**
   - UI 컴포넌트 관리 로직 마이그레이션
   - 실시간 UI 업데이트 구현
   - 테마 시스템 구축

2. **cogo-store-agent 개발**
   - 상태 관리 로직 마이그레이션
   - 데이터 영속화 구현
   - 실시간 상태 동기화

3. **cogo-action-agent 개발**
   - 액션 실행 엔진 구축
   - LangGraph 워크플로우 통합
   - 액션 라이브러리 마이그레이션

### Phase 3: 고급 기능 및 통합 (2주)
1. **cogo-layout-agent 개발**
   - 레이아웃 관리 시스템 구축
   - 반응형 디자인 구현
   - 그리드 시스템 개발

2. **전체 시스템 통합**
   - 에이전트 간 통신 테스트
   - 워크플로우 검증
   - 성능 최적화

### Phase 4: 배포 및 모니터링 (1주)
1. **Docker 배포 환경 구축**
   - 각 에이전트 Docker 이미지 생성
   - docker-compose 설정
   - 헬스 체크 구현

2. **모니터링 시스템 구축**
   - 메트릭 수집
   - 로그 집계
   - 알림 시스템

---

## 8. 테스트 전략

### 8.1 단위 테스트
```typescript
describe('CogoUiAgent', () => {
  let agent: CogoUiAgent;

  beforeEach(() => {
    agent = new CogoUiAgent();
  });

  it('should initialize successfully', async () => {
    await agent.initialize();
    const status = await agent.getStatus();
    expect(status.status).toBe('idle');
  });

  it('should handle UI component updates', async () => {
    const updateTask = {
      id: 'test-update',
      type: 'ui_component_update',
      payload: { componentId: 'comp-1', props: { color: 'red' } }
    };

    const result = await agent.executeTask(updateTask);
    expect(result.success).toBe(true);
  });
});
```

### 8.2 통합 테스트
```typescript
describe('Cogo Agent System Integration', () => {
  let uiAgent: CogoUiAgent;
  let storeAgent: CogoStoreAgent;
  let realtimeManager: CogoRealtimeManager;

  beforeAll(async () => {
    // 전체 시스템 초기화
    realtimeManager = new CogoRealtimeManager();
    await realtimeManager.initialize();

    uiAgent = new CogoUiAgent(realtimeManager);
    storeAgent = new CogoStoreAgent(realtimeManager);

    await Promise.all([
      uiAgent.initialize(),
      storeAgent.initialize()
    ]);
  });

  it('should handle end-to-end component creation', async () => {
    // 컴포넌트 생성 워크플로우 테스트
    const workflow = new UiComponentCreationWorkflow();
    const result = await workflow.execute({
      requirements: 'Create a red button',
      agent: uiAgent
    });

    expect(result.component).toBeDefined();
    expect(result.component.props.color).toBe('red');
  });
});
```

### 8.3 성능 테스트
- 에이전트 응답 시간 측정
- 실시간 메시지 처리량 테스트
- 메모리 사용량 모니터링
- 데이터베이스 쿼리 성능 테스트

---

## 9. 마이그레이션 이점

### 기술적 이점
1. **확장성**: 독립적인 에이전트들이 수평 확장 가능
2. **내결함성**: 하나의 에이전트 실패가 전체 시스템에 영향 미치지 않음
3. **실시간성**: Supabase Real-time을 통한 즉각적인 데이터 동기화
4. **유지보수성**: 모듈화된 구조로 개별 컴포넌트 관리 용이

### 비즈니스적 이점
1. **개발 생산성**: 에이전트 기반 협업으로 개발 속도 향상
2. **품질 향상**: 자동화된 워크플로우로 일관성 있는 결과물
3. **확장 가능성**: 새로운 기능의 에이전트 추가로 시스템 확장
4. **모니터링**: 실시간 헬스 체크와 메트릭으로 안정성 확보

---

## 10. 결론 및 다음 단계

creatego-packages를 COGO 플랫폼에 맞게 리팩토링하는 것은 단순한 코드 재구성이 아닌, 완전히 새로운 분산 아키텍처로의 전환입니다.

### 즉각적인 다음 단계:
1. **프로젝트 구조 재설계** 시작
2. **공통 인터페이스 및 타입** 정의
3. **첫 번째 에이전트 (cogo-ui-agent)** 구현
4. **실시간 통신 인프라** 구축

### 장기적 비전:
- 완전한 COGO 생태계 통합
- AI 기반 자동화 강화
- 실시간 협업 환경 구축
- 엔터프라이즈급 확장성 확보

이 리팩토링을 통해 creatego-packages는 COGO 플랫폼의 핵심 컴포넌트로 거듭나게 될 것입니다.
