# Worker Management Architecture with Legacy Integration

## 🎯 Overview

COGO Agent Core의 3가지 Worker 서비스 (Python Sandbox, Figma MCP, Browser Worker)를 효과적으로 관리하면서, **기존 Agent 연결 구조와의 호환성을 유지**하는 통합 아키텍처입니다.

## 🔗 Legacy Integration Considerations

### 기존 Agent 구조 분석
- **CogoExecutorAgent (TaskManager)**: MCPClient, SupabaseRealtimeQueue, TaskPlanManager 사용
- **A2AProtocolManager**: Agent 간 통신 프로토콜 (포트 3001, 3002 사용 중)
- **기존 Worker 연결**: MCPClient를 통한 Figma/Browser 연결

### 통합 전략
1. **Backward Compatibility**: 기존 Agent가 계속 작동
2. **Bridge Pattern**: 기존-신규 구조 간 브릿지
3. **Gradual Migration**: 단계적 마이그레이션 지원
4. **Dual Operation**: 기존/신규 동시 운영 가능

## 🏗️ Architecture Components

### 1. WorkerManager (Main Controller)
- **역할**: 전체 Worker 서비스의 중앙 관리
- **기능**:
  - Worker 서비스 시작/중지
  - 태스크 라우팅 및 분배
  - 클라이언트 요청 처리
  - 서비스 간 통신 조율

### 2. WorkerRegistry (Service Discovery)
- **역할**: Worker 서비스 등록 및 발견
- **기능**:
  - 동적 서비스 등록/해제
  - 서비스 메타데이터 관리
  - 엔드포인트 정보 제공
  - 서비스 상태 추적

### 3. HealthMonitor (Auto-Recovery)
- **역할**: Worker 서비스 상태 모니터링
- **기능**:
  - 주기적 헬스체크
  - 장애 감지 및 알림
  - 자동 재시작
  - 상태 리포팅

### 4. LoadBalancer (Task Distribution)
- **역할**: 태스크 분산 및 부하 균형
- **기능**:
  - 최적 Worker 선택
  - 부하 분산 알고리즘
  - 태스크 큐 관리
  - 성능 최적화

## 🔧 Worker Services Configuration

### 포트 할당 전략 (기존 시스템 고려)
```yaml
# 기존 시스템 포트 (유지)
main_server: 3000        # COGO Agent Core Main Server
a2a_agent_01: 3001      # 기존 A2A Code Analysis Agent  
a2a_agent_02: 3002      # 기존 A2A Research Agent

# Worker Services 포트 (신규 할당)
worker_python: 3011     # Python Sandbox Server
worker_figma: 3012      # Figma MCP Server  
worker_browser: 3013    # Browser Worker Server
worker_manager: 3010    # Worker Manager API
```

### Python Sandbox Server
```yaml
service:
  name: "python-sandbox"
  type: "websocket"
  port: 3011              # 3001 → 3011로 변경
  protocol: "ws"
  capabilities: ["python-execution", "file-operations", "package-install"]
  health_check: "/health"
  heartbeat_interval: 30s
  legacy_bridge: true     # 기존 MCPClient 연동 지원
```

### Figma MCP Server
```yaml
service:
  name: "figma-mcp"
  type: "websocket"
  port: 3012              # 3002 → 3012로 변경
  protocol: "ws"
  capabilities: ["figma-design", "ui-generation", "asset-export"]
  health_check: "/health"
  heartbeat_interval: 30s
  legacy_bridge: true     # 기존 MCPClient 연동 지원
```

### Browser Worker
```yaml
service:
  name: "browser-worker"
  type: "websocket-with-client"
  port: 3013              # 3003 → 3013로 변경
  protocol: "ws"
  capabilities: ["web-automation", "scraping", "testing", "screenshot"]
  health_check: "/health"
  heartbeat_interval: 30s
  legacy_bridge: true     # 기존 MCPClient 연동 지원
  client_config:
    type: "headless-chrome"
    auto_start: true
    max_instances: 3
```

## 🔄 Service Lifecycle Management

### 1. 서비스 시작 순서
```
1. WorkerRegistry 초기화
2. HealthMonitor 시작
3. Python Sandbox 서버 시작
4. Figma MCP 서버 시작
5. Browser Worker 서버 시작
6. Browser Client 인스턴스 시작
7. LoadBalancer 활성화
8. WorkerManager 준비 완료
```

### 2. 서비스 등록 프로세스
```
1. Worker 서비스 시작
2. WorkerRegistry에 자동 등록
3. 초기 헬스체크 수행
4. LoadBalancer에 추가
5. 서비스 Ready 상태
```

### 3. 장애 복구 프로세스
```
1. HealthMonitor가 장애 감지
2. 서비스 상태를 "Unhealthy"로 변경
3. LoadBalancer에서 임시 제외
4. 자동 재시작 시도
5. 복구 성공 시 다시 등록
6. 복구 실패 시 알림 및 로깅
```

## 🌐 Browser Worker 특수 관리

### Client-Server 분리 구조
```
Browser WebSocket Server (Port 3003)
├── Connection Pool Manager
├── Task Queue
├── Response Handler
└── Browser Client Manager
    ├── Headless Chrome Instance 1
    ├── Headless Chrome Instance 2
    └── Headless Chrome Instance 3
```

### Browser Client 관리 전략
- **인스턴스 풀링**: 미리 생성된 브라우저 인스턴스 관리
- **세션 격리**: 각 태스크별 독립적인 브라우저 컨텍스트
- **메모리 관리**: 주기적인 브라우저 재시작으로 메모리 누수 방지
- **동시성 제어**: 최대 브라우저 인스턴스 수 제한

## 📊 Monitoring & Metrics

### 수집 메트릭
```yaml
worker_metrics:
  - service_status: ["running", "stopped", "error"]
  - response_time: "milliseconds"
  - active_connections: "count"
  - task_queue_size: "count"
  - success_rate: "percentage"
  - error_count: "count"
  - memory_usage: "MB"
  - cpu_usage: "percentage"

browser_specific_metrics:
  - active_browser_instances: "count"
  - page_load_time: "milliseconds"
  - memory_per_instance: "MB"
  - crash_count: "count"
```

## 🔌 API Interface

### WorkerManager REST API
```typescript
// Worker 상태 조회
GET /api/workers/status
Response: {
  workers: [
    {
      name: "python-sandbox",
      status: "running",
      port: 3001,
      connections: 5,
      load: 0.3
    }
  ]
}

// 태스크 실행
POST /api/workers/execute
Body: {
  workerType: "python-sandbox",
  task: { ... },
  priority: "normal"
}

// Worker 제어
POST /api/workers/{workerId}/restart
POST /api/workers/{workerId}/stop
GET /api/workers/{workerId}/health
```

## 🚀 Implementation Phases

### Phase 1: Core Infrastructure
- [x] Python Sandbox Server (완료)
- [ ] WorkerRegistry 구현
- [ ] HealthMonitor 기본 기능
- [ ] WorkerManager 기본 구조

### Phase 2: Service Integration
- [ ] Figma MCP Server 구현
- [ ] Browser Worker Server 구현
- [ ] Browser Client Manager
- [ ] LoadBalancer 구현

### Phase 3: Advanced Features
- [ ] Auto-scaling
- [ ] Advanced monitoring
- [ ] Performance optimization
- [ ] Fault tolerance

## 🛡️ Security & Best Practices

### Security Measures
- Worker 간 네트워크 격리
- API 인증 및 권한 관리
- 태스크 실행 제한 (timeout, resource limit)
- 로그 보안 (민감 정보 마스킹)

### Performance Optimization
- Connection pooling
- Task batching
- Lazy loading
- Cache 전략

## 📋 Configuration Management

### 환경별 설정
```bash
# Development
WORKER_PYTHON_PORT=3001
WORKER_FIGMA_PORT=3002
WORKER_BROWSER_PORT=3003
WORKER_HEALTH_CHECK_INTERVAL=30
BROWSER_MAX_INSTANCES=2

# Production
WORKER_PYTHON_PORT=3001
WORKER_FIGMA_PORT=3002
WORKER_BROWSER_PORT=3003
WORKER_HEALTH_CHECK_INTERVAL=15
BROWSER_MAX_INSTANCES=5
```

## 🌉 Legacy Integration Bridge Pattern

### WorkerRegistryAdapter (브릿지 컴포넌트)
```typescript
interface LegacyWorkerBridge {
  // 기존 MCPClient와 신규 WorkerManager 연결
  bridgeMCPClient(mcpClient: MCPClient): Promise<void>;
  
  // 기존 TaskManager와 신규 DistributedExecutor 연결  
  bridgeTaskManager(taskManager: TaskManager): Promise<void>;
  
  // 포트 리다이렉션 (3001 → 3011, 3002 → 3012)
  setupPortRedirection(): Promise<void>;
  
  // 기존 Agent 메시지를 신규 Worker 형식으로 변환
  translateLegacyMessage(message: any): WorkerMessage;
}
```

### 단계적 마이그레이션 전략
```
Phase 1: Coexistence (병존)
├── 기존 Agent: 계속 운영 (포트 3001, 3002)
├── 신규 Worker: 새 포트에서 시작 (3011, 3012, 3013)
└── Bridge: 양방향 메시지 변환 및 전달

Phase 2: Hybrid Operation (하이브리드)
├── 일부 태스크: 기존 Agent 처리
├── 일부 태스크: 신규 Worker 처리  
└── WorkerManager: 로드밸런싱으로 분배

Phase 3: Full Migration (완전 마이그레이션)
├── 모든 태스크: 신규 Worker 처리
├── 기존 Agent: Deprecated 상태
└── Bridge: 호환성 유지 목적으로만 사용
```

### Legacy Support Configuration
```yaml
# 기존 Agent 지원 설정
legacy_support:
  enabled: true
  mcp_client_bridge: true
  task_manager_bridge: true
  port_redirection:
    3001: 3011  # A2A Agent → Python Sandbox
    3002: 3012  # A2A Agent → Figma MCP
  message_translation: true
  backward_compatibility: true
```

## 🚀 Implementation Roadmap

### Phase 1: Bridge Infrastructure (2주)
- [x] Python Sandbox Server (3011 포트) ✅ 완료
- [ ] WorkerRegistryAdapter 구현
- [ ] Legacy Message Translator
- [ ] Port Redirection Service
- [ ] Figma MCP Server (3012 포트)
- [ ] Browser Worker Server (3013 포트)

### Phase 2: Worker Manager Integration (2주)
- [ ] WorkerManager Core 구현
- [ ] HealthMonitor 구현
- [ ] LoadBalancer 구현
- [ ] Legacy Bridge 통합 테스트
- [ ] Hybrid Operation 검증

### Phase 3: Advanced Features (2주)
- [ ] Auto-scaling
- [ ] Advanced monitoring
- [ ] Performance optimization
- [ ] Full migration support

이 아키텍처는 확장 가능하고 유지보수가 용이한 Worker 관리 시스템을 제공하며, **기존 Agent 구조와의 완벽한 호환성을 보장**합니다. 특히 Browser Worker의 클라이언트 특성과 기존 MCPClient 연동을 모두 고려한 통합 관리 기능을 포함합니다.
