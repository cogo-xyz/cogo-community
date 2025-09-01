# Sandbox Worker 통합 계획서

## 📋 **개요**

COGO Agent Core 시스템에 **실시간 통신이 가능한 Python Sandbox Worker**를 통합하여, 실제 컴파일, 빌드, 테스트를 수행하는 완전한 개발 환경을 구축합니다.

---

## 🎯 **목표**

### **주요 목표**
1. **실시간 통신**: WebSocket 기반 실시간 stdin/stdout/stderr 스트리밍
2. **Block 감지**: 무한 루프, 타임아웃 등 Block 상태 자동 감지
3. **자동 복구**: Block 발생 시 자동 복구 및 대체 전략 실행
4. **대용량 분석**: Repository 단위 소스 분석 및 점진적 처리
5. **실시간 피드백**: 개발자에게 즉시 피드백 제공

### **성공 지표**
- 컴파일 오류 감지 시간: < 1초
- Block 감지 시간: < 5초
- 자동 복구 성공률: > 90%
- 실시간 응답성: < 100ms

---

## 🏗️ **통합 아키텍처**

### **A. 전체 시스템 구조**
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           COGO Agent Core                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    cogo-orchestrator-agent                          │   │
│  │  (중앙 지능체 - 의사결정 및 전략 수립)                              │   │
│  │                                                                     │   │
│  │  • RAG + LLM 기반 의사결정                                          │   │
│  │  • 개발 요청 분석 및 분류                                           │   │
│  │  • COGO Knowledge-Based Development Methodology                     │   │
│  │  • 품질 보증 및 리팩토링 전략                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                      │
│                                      ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    cogo-executor-agent                              │   │
│  │  (작업 실행 관리자 - 계획 및 분배)                                  │   │
│  │                                                                     │   │
│  │  • 작업 계획 수립 및 분해                                           │   │
│  │  • Agent 선택 및 작업 분배                                          │   │
│  │  • 실행 순서 관리 및 의존성 처리                                     │   │
│  │  • 실시간 진행률 모니터링                                           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                      │
│                                      ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      Sandbox Manager                                │   │
│  │  (Worker 풀 관리자 - 리소스 관리)                                   │   │
│  │                                                                     │   │
│  │  • Worker Agent 풀 관리                                             │   │
│  │  • 작업 분배 및 스케줄링                                            │   │
│  │  • 실시간 통신 관리 (WebSocket)                                     │   │
│  │  • Block 감지 및 복구 조정                                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                      │
│                                      ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      Sandbox Worker                                 │   │
│  │  (실제 실행 엔진 - Python 기반)                                     │   │
│  │                                                                     │   │
│  │  • 실제 코드 컴파일/빌드/테스트                                     │   │
│  │  • 실시간 stdout/stderr 스트리밍                                    │   │
│  │  • Block 감지 및 프로세스 관리                                      │   │
│  │  • Repository 분석 및 데이터 저장                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### **B. 통신 프로토콜**
- **Orchestrator ↔ Executor**: HTTP API + Supabase Realtime
- **Executor ↔ Sandbox Manager**: HTTP API + WebSocket
- **Sandbox Manager ↔ Sandbox Worker**: WebSocket (실시간)

---

## 📋 **시나리오 정의**

### **시나리오 1: 코드 생성 → 컴파일 → 빌드 → 테스트 전체 플로우**
```
1. cogo-orchestrator-agent: 개발 요청 분석 및 의사결정
2. cogo-executor-agent: 작업 계획 수립 및 분해
3. Sandbox Manager: Worker 풀 관리 및 작업 분배
4. Sandbox Worker: 실제 코드 실행 및 결과 반환
5. 실시간 피드백 루프: 오류 발생 시 자동 복구
```

### **시나리오 2: 대용량 Repository 분석**
```
1. cogo-orchestrator-agent: 분석 요청 수신 및 전략 결정
2. cogo-executor-agent: 분석 작업을 단계별로 분해
3. Sandbox Manager: 여러 Worker에 병렬 분석 작업 분배
4. Sandbox Worker: Repository 클론 및 점진적 분석 실행
5. 실시간 결과 수집: DB/KG/Vector에 실시간 저장
```

### **시나리오 3: 실시간 개발 피드백**
```
1. 개발자: 코드 수정
2. cogo-orchestrator-agent: 변경사항 감지 및 영향도 분석
3. cogo-executor-agent: 즉시 테스트/빌드 작업 생성
4. Sandbox Manager: 우선순위 높은 Worker 할당
5. Sandbox Worker: 실시간 컴파일/테스트 실행
6. 결과 스트리밍: 개발자에게 즉시 피드백 전송
```

### **시나리오 4: Block 감지 및 자동 복구**
```
1. Sandbox Worker: Block 상태 감지
2. Sandbox Manager: 즉시 cogo-executor-agent에 보고
3. cogo-executor-agent: 복구 전략 결정
4. cogo-orchestrator-agent: 복구 방법 분석
5. Sandbox Manager: 대체 Worker 또는 복구 명령 실행
6. Sandbox Worker: 복구된 환경에서 작업 재시작
```

---

## 🔍 **현재 구현 상태 검증**

### **A. cogo-orchestrator-agent 검증**

#### **✅ 구현된 기능**
- **의사결정 프레임워크**: RAG + LLM 기반 의사결정
- **역할 기반 실행**: 작업 유형별 역할 선택 및 실행
- **개발 워크플로우**: COGO Knowledge-Based Development Methodology
- **품질 보증 시스템**: 코드 품질, 보안, 성능 분석
- **리팩토링 방법론**: 자동 리팩토링 계획 및 실행
- **성능 최적화**: 병렬 처리, 캐싱, 모니터링
- **실시간 통신**: Supabase Realtime 기반 메시지 처리

#### **❌ 부족한 기능**
- **Sandbox Worker 연동**: 실제 실행 환경과의 연결 없음
- **실시간 실행 모니터링**: 컴파일/빌드/테스트 실시간 모니터링 없음
- **Block 감지 연동**: Block 상태 감지 및 복구 로직 없음

#### **🔧 개선 필요 사항**
```typescript
// 1. Sandbox Worker 연동 인터페이스 추가
interface SandboxWorkerInterface {
  executeCommand(command: string, options: ExecutionOptions): Promise<ExecutionResult>;
  streamOutput(taskId: string): Observable<OutputEvent>;
  detectBlock(taskId: string): Observable<BlockEvent>;
  recoverFromBlock(taskId: string, strategy: RecoveryStrategy): Promise<boolean>;
}

// 2. 실시간 실행 모니터링 추가
interface ExecutionMonitor {
  monitorCompilation(taskId: string): Observable<CompilationEvent>;
  monitorBuild(taskId: string): Observable<BuildEvent>;
  monitorTests(taskId: string): Observable<TestEvent>;
}

// 3. Block 감지 및 복구 로직 추가
interface BlockDetectionSystem {
  detectBlock(taskId: string): Promise<BlockInfo>;
  createRecoveryPlan(blockInfo: BlockInfo): Promise<RecoveryPlan>;
  executeRecovery(plan: RecoveryPlan): Promise<RecoveryResult>;
}
```

### **B. cogo-executor-agent 검증**

#### **✅ 구현된 기능**
- **작업 계획 관리**: TaskPlanManager를 통한 작업 계획 수립
- **작업 분해**: 복잡한 요청을 단계별 작업으로 분해
- **Agent 선택**: 작업 유형별 최적 Agent 선택
- **실시간 구독**: Supabase Realtime 기반 메시지 처리
- **MCP 통합**: Figma, Browser 등 외부 서비스 연동
- **진행률 모니터링**: 작업 진행률 실시간 추적

#### **❌ 부족한 기능**
- **Sandbox Manager 연동**: Sandbox Worker 풀 관리 없음
- **실시간 실행 통신**: WebSocket 기반 실시간 통신 없음
- **Block 복구 조정**: Block 발생 시 복구 전략 조정 없음

#### **🔧 개선 필요 사항**
```typescript
// 1. Sandbox Manager 연동 추가
interface SandboxManagerInterface {
  createWorker(workerType: WorkerType): Promise<string>;
  assignTask(task: TaskRequest): Promise<string>;
  executeTask(workerId: string, command: string): Promise<void>;
  monitorWorker(workerId: string): Observable<WorkerStatus>;
}

// 2. 실시간 실행 통신 추가
interface RealtimeExecutionInterface {
  setupWebSocketConnection(workerId: string): Promise<void>;
  streamExecutionOutput(taskId: string): Observable<ExecutionOutput>;
  sendExecutionInput(taskId: string, input: string): Promise<void>;
}

// 3. Block 복구 조정 로직 추가
interface BlockRecoveryCoordinator {
  handleBlockDetection(blockInfo: BlockInfo): Promise<void>;
  coordinateRecovery(workerId: string, strategy: RecoveryStrategy): Promise<void>;
  switchToAlternativeWorker(taskId: string): Promise<string>;
}
```

---

## 🚀 **구현 계획**

### **Phase 1: 기본 통신 구조 (1-2주)**

#### **1.1 Sandbox Manager 구현**
```typescript
// src/agents/SandboxManager.ts
export class SandboxManager {
  private workerPool: Map<string, SandboxWorker> = new Map();
  private taskQueue: PriorityQueue<TaskRequest> = new PriorityQueue();
  private websocketConnections: Map<string, WebSocket> = new Map();
  
  // Worker 풀 관리
  async createWorker(workerType: 'basic' | 'flutter' | 'analysis'): Promise<string>
  async removeWorker(workerId: string): Promise<void>
  async getAvailableWorker(requirements: WorkerRequirements): Promise<string | null>
  
  // 작업 분배
  async assignTask(task: TaskRequest): Promise<string>
  async executeTask(taskId: string, command: string): Promise<void>
  
  // 실시간 통신
  async setupWebSocketConnection(workerId: string): Promise<void>
  async sendMessage(workerId: string, message: any): Promise<void>
  
  // Block 감지 및 복구
  async detectBlock(workerId: string): Promise<boolean>
  async recoverFromBlock(workerId: string): Promise<void>
}
```

#### **1.2 Sandbox Worker WebSocket 서버 구현**
```python
# cogo-worker/sandbox_websocket_server.py
class SandboxWebSocketServer:
    def __init__(self, workspace: str):
        self.workspace = workspace
        self.active_processes = {}
        self.block_detector = BlockDetector()
        
    async def handle_execute_command(self, message):
        task_id = message['taskId']
        command = message['command']
        
        # 프로세스 실행 및 모니터링
        process = await self.execute_command(command)
        self.active_processes[task_id] = process
        
        # 실시간 출력 스트리밍
        await self.stream_output(task_id, process)
        
        # Block 감지
        await self.monitor_for_blocks(task_id, process)
    
    async def stream_output(self, task_id: str, process):
        while process.is_running():
            output = await process.read_output()
            await self.send_output_event(task_id, output)
            
    async def monitor_for_blocks(self, task_id: str, process):
        while process.is_running():
            if self.block_detector.is_blocked(process):
                await self.send_block_event(task_id, process)
                break
```

#### **1.3 cogo-executor-agent 개선**
```typescript
// 기존 cogo-executor-agent에 Sandbox Manager 연동 추가
export class TaskManager extends BaseAgent {
  private sandboxManager: SandboxManager;
  
  // Sandbox Manager 초기화
  async initializeSandboxManager(): Promise<void> {
    this.sandboxManager = new SandboxManager();
    await this.sandboxManager.initialize();
  }
  
  // Sandbox 작업 실행
  private async executeSandboxTask(task: TaskStep, planId: string): Promise<void> {
    const workerId = await this.sandboxManager.assignTask({
      taskId: task.taskId,
      command: task.command,
      requirements: task.requirements
    });
    
    await this.sandboxManager.executeTask(workerId, task.command);
  }
}
```

### **Phase 2: 고급 기능 (2-3주)**

#### **2.1 Block 감지 및 복구 시스템**
```typescript
// Block 감지 시스템
export class BlockDetectionSystem {
  async detectBlock(processId: string): Promise<BlockInfo> {
    const process = await this.getProcessInfo(processId);
    
    return {
      isBlocked: this.isProcessBlocked(process),
      reason: this.determineBlockReason(process),
      duration: this.getBlockDuration(process),
      resourceUsage: this.getResourceUsage(process)
    };
  }
  
  async createRecoveryPlan(blockInfo: BlockInfo): Promise<RecoveryPlan> {
    switch (blockInfo.reason) {
      case 'timeout':
        return { action: 'terminate', strategy: 'restart' };
      case 'infinite_loop':
        return { action: 'terminate', strategy: 'alternative_approach' };
      case 'memory_exhausted':
        return { action: 'restart', strategy: 'reduce_memory_usage' };
      default:
        return { action: 'terminate', strategy: 'fallback' };
    }
  }
}
```

#### **2.2 실시간 피드백 루프**
```typescript
// 실시간 피드백 시스템
export class RealtimeFeedbackSystem {
  async setupFeedbackLoop(taskId: string): Promise<void> {
    // 컴파일 오류 감지
    this.sandboxManager.onCompilationError(taskId, async (error) => {
      const fix = await this.orchestrator.analyzeCompilationError(error);
      await this.sandboxManager.applyFix(taskId, fix);
    });
    
    // 테스트 실패 감지
    this.sandboxManager.onTestFailure(taskId, async (failure) => {
      const fix = await this.orchestrator.analyzeTestFailure(failure);
      await this.sandboxManager.applyFix(taskId, fix);
    });
    
    // Block 감지
    this.sandboxManager.onBlockDetected(taskId, async (blockInfo) => {
      const recoveryPlan = await this.orchestrator.createRecoveryPlan(blockInfo);
      await this.sandboxManager.executeRecovery(taskId, recoveryPlan);
    });
  }
}
```

#### **2.3 Repository 분석 시스템**
```typescript
// Repository 분석 시스템
export class RepositoryAnalysisSystem {
  async analyzeRepository(repositoryUrl: string): Promise<AnalysisResult> {
    // 1. Repository 클론
    const workspace = await this.sandboxManager.cloneRepository(repositoryUrl);
    
    // 2. 파일 스캔
    const files = await this.sandboxManager.scanFiles(workspace);
    
    // 3. 점진적 분석
    const analysisTasks = this.createAnalysisTasks(files);
    
    for (const task of analysisTasks) {
      const result = await this.sandboxManager.executeAnalysisTask(task);
      await this.storeAnalysisResult(result);
    }
    
    return this.generateAnalysisReport();
  }
}
```

### **Phase 3: 최적화 및 통합 (1-2주)**

#### **3.1 성능 최적화**
```typescript
// 병렬 처리 최적화
export class ParallelProcessingOptimizer {
  async executeParallelTasks(tasks: Task[]): Promise<TaskResult[]> {
    const workerPool = await this.sandboxManager.createWorkerPool(tasks.length);
    const taskAssignments = this.assignTasksToWorkers(tasks, workerPool);
    
    const results = await Promise.all(
      taskAssignments.map(assignment => 
        this.sandboxManager.executeTask(assignment.workerId, assignment.task)
      )
    );
    
    return results;
  }
}
```

#### **3.2 모니터링 및 로깅**
```typescript
// 통합 모니터링 시스템
export class IntegratedMonitoringSystem {
  async monitorSystemHealth(): Promise<SystemHealth> {
    return {
      orchestrator: await this.orchestrator.getHealth(),
      executor: await this.executor.getHealth(),
      sandboxManager: await this.sandboxManager.getHealth(),
      workers: await this.sandboxManager.getWorkerHealth()
    };
  }
  
  async logExecutionEvent(event: ExecutionEvent): Promise<void> {
    await this.logger.log(event);
    await this.analytics.track(event);
  }
}
```

---

## 📊 **API 설계**

### **A. HTTP API 엔드포인트**

#### **Sandbox Manager API**
```typescript
// Worker 관리
POST /api/sandbox/workers/create
GET /api/sandbox/workers
DELETE /api/sandbox/workers/{workerId}

// 작업 실행
POST /api/sandbox/execute
GET /api/sandbox/tasks/{taskId}/status
DELETE /api/sandbox/tasks/{taskId}

// Block 복구
POST /api/sandbox/recover/{workerId}
GET /api/sandbox/health
```

#### **Repository 분석 API**
```typescript
// Repository 분석
POST /api/sandbox/analyze/repository
GET /api/sandbox/analysis/{analysisId}/status
GET /api/sandbox/analysis/{analysisId}/results

// 파일 관리
POST /api/sandbox/files/create
GET /api/sandbox/files/{path}
DELETE /api/sandbox/files/{path}
```

### **B. WebSocket 이벤트**

#### **실시간 출력 스트리밍**
```typescript
interface RealtimeOutputEvent {
  type: 'realtime_output';
  taskId: string;
  workerId: string;
  stream: 'stdout' | 'stderr';
  data: string;
  timestamp: number;
  sequence: number;
}
```

#### **진행률 업데이트**
```typescript
interface ProgressUpdateEvent {
  type: 'progress_update';
  taskId: string;
  workerId: string;
  progress: {
    percentage: number;
    stage: 'compiling' | 'building' | 'testing' | 'analyzing';
    message: string;
    estimatedTimeRemaining: number;
  };
  timestamp: number;
}
```

#### **Block 감지**
```typescript
interface BlockDetectedEvent {
  type: 'block_detected';
  taskId: string;
  workerId: string;
  blockInfo: {
    reason: string;
    duration: number;
    resourceUsage: ResourceUsage;
    recoverable: boolean;
  };
  timestamp: number;
}
```

---

## 🧪 **테스트 계획**

### **A. 단위 테스트**
- Sandbox Manager 기능 테스트
- Block 감지 로직 테스트
- WebSocket 통신 테스트
- Repository 분석 테스트

### **B. 통합 테스트**
- 전체 워크플로우 테스트
- 실시간 피드백 루프 테스트
- 오류 복구 테스트
- 성능 부하 테스트

### **C. 시나리오 테스트**
- 코드 생성 → 컴파일 → 빌드 → 테스트 플로우
- 대용량 Repository 분석
- 실시간 개발 피드백
- Block 감지 및 자동 복구

---

## 📈 **성능 목표**

### **A. 응답 시간**
- 컴파일 오류 감지: < 1초
- Block 감지: < 5초
- 실시간 출력 스트리밍: < 100ms
- 작업 할당: < 500ms

### **B. 처리량**
- 동시 작업 처리: 10개
- Repository 분석: 1000+ 파일
- 실시간 스트리밍: 1000+ 이벤트/초

### **C. 안정성**
- 자동 복구 성공률: > 90%
- 시스템 가용성: > 99.9%
- 오류 복구 시간: < 30초

---

## 🚨 **위험 요소 및 대응 방안**

### **A. 기술적 위험**
- **WebSocket 연결 불안정**: 재연결 로직 및 폴백 메커니즘
- **Block 감지 오탐**: 다중 지표 기반 감지 및 임계값 조정
- **메모리 누수**: 정기적인 리소스 정리 및 모니터링

### **B. 성능 위험**
- **대용량 Repository 처리**: 점진적 분석 및 배치 처리
- **동시 작업 과부하**: 작업 큐 및 우선순위 관리
- **네트워크 지연**: 로컬 캐싱 및 압축 전송

### **C. 보안 위험**
- **코드 실행 보안**: 샌드박스 환경 및 명령어 검증
- **데이터 노출**: 암호화 전송 및 접근 제어
- **리소스 남용**: 리소스 제한 및 모니터링

---

## 📅 **구현 일정**

### **Week 1-2: Phase 1 - 기본 통신 구조**
- [ ] Sandbox Manager 기본 구조 구현
- [ ] Sandbox Worker WebSocket 서버 구현
- [ ] cogo-executor-agent 개선
- [ ] 기본 작업 실행 플로우 구현

### **Week 3-5: Phase 2 - 고급 기능**
- [ ] Block 감지 및 복구 시스템 구현
- [ ] 실시간 피드백 루프 구현
- [ ] Repository 분석 기능 구현
- [ ] 데이터 저장 시스템 구현

### **Week 6-7: Phase 3 - 최적화 및 통합**
- [ ] 성능 최적화 및 병렬 처리
- [ ] 오류 처리 및 복구 로직 강화
- [ ] 모니터링 및 로깅 시스템
- [ ] 전체 시스템 통합 테스트

---

## 🎯 **성공 기준**

### **A. 기능적 성공 기준**
- [ ] 모든 시나리오가 정상 동작
- [ ] 실시간 통신이 안정적으로 작동
- [ ] Block 감지 및 복구가 정확히 동작
- [ ] 대용량 Repository 분석이 성공적으로 완료

### **B. 성능적 성공 기준**
- [ ] 응답 시간 목표 달성
- [ ] 처리량 목표 달성
- [ ] 안정성 목표 달성
- [ ] 리소스 사용량 최적화

### **C. 사용자 경험 성공 기준**
- [ ] 개발자 피드백이 즉시 제공
- [ ] 오류 복구가 자동으로 수행
- [ ] 시스템 사용이 직관적
- [ ] 문서화가 완전히 제공

---

**📅 작성일**: 2025-01-27  
**🔧 버전**: 1.0.0  
**✅ 상태**: 계획 완료  
**🎯 다음 단계**: Phase 1 구현 시작 