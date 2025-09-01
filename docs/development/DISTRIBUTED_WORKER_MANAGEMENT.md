# Distributed Worker Management Architecture

## 🎯 Overview

**분산 구조 Agent 전용** Worker 관리 시스템 설계입니다. 기존 Agent는 고려하지 않고, 오직 새로 개발된 Distributed Agent Ecosystem만을 위한 최적화된 구조입니다.

## 🏗️ Core Architecture

### Distributed Agent Ecosystem
```
DistributedOrchestratorAgent (Main Controller)
├── DistributedExecutorAgent (Worker Manager)
├── DistributedResearchAgent
├── DistributedIndexingAgent
└── DistributedGraphRAGAgent
```

### Worker Services (3가지)
```
1. Python Sandbox Server (Port: 3001) ✅ 실행 중
2. Figma MCP Server (Port: 3002)
3. Browser Worker Server (Port: 3003)
```

## 🔧 Worker Management Components

### 1. WorkerManager (중앙 제어)
```typescript
class WorkerManager {
  private workerRegistry: WorkerRegistry;
  private healthMonitor: HealthMonitor;
  private loadBalancer: LoadBalancer;
  private workerInterface: WebSocketWorkerInterface;
  
  // 핵심 기능
  async registerWorker(config: WorkerConfig): Promise<void>
  async executeTask(task: WorkerTask): Promise<WorkerResult>
  async getWorkerStatus(): Promise<WorkerStatus[]>
  async redistributeTasks(): Promise<void>
}
```

### 2. WorkerRegistry (서비스 디스커버리)
```typescript
interface WorkerInfo {
  workerId: string;
  workerType: 'python-sandbox' | 'figma-mcp' | 'browser-worker';
  endpoint: string;
  port: number;
  status: 'online' | 'offline' | 'busy' | 'error';
  capabilities: string[];
  currentLoad: number;
  lastHeartbeat: Date;
}

class WorkerRegistry {
  async registerWorker(worker: WorkerInfo): Promise<void>
  async unregisterWorker(workerId: string): Promise<void>
  async getAvailableWorkers(type?: string): Promise<WorkerInfo[]>
  async updateWorkerStatus(workerId: string, status: WorkerStatus): Promise<void>
}
```

### 3. HealthMonitor (상태 모니터링)
```typescript
class HealthMonitor {
  private healthCheckInterval: number = 30000; // 30초
  
  async startMonitoring(): Promise<void>
  async performHealthCheck(workerId: string): Promise<HealthResult>
  async handleUnhealthyWorker(workerId: string): Promise<void>
  async restartWorker(workerId: string): Promise<void>
}
```

### 4. LoadBalancer (부하 분산)
```typescript
class LoadBalancer {
  async selectOptimalWorker(task: WorkerTask): Promise<string>
  async distributeTasks(tasks: WorkerTask[]): Promise<TaskDistribution>
  async rebalanceLoad(): Promise<void>
  getLoadMetrics(): LoadMetrics
}
```

## 🔌 Worker Interface Abstraction

### WebSocketWorkerInterface (추상화)
```typescript
interface WebSocketWorkerInterface {
  connect(endpoint: string): Promise<WebSocketConnection>
  disconnect(workerId: string): Promise<void>
  sendMessage(workerId: string, message: WorkerMessage): Promise<void>
  subscribeToMessages?(workerId: string, callback: MessageCallback): Promise<void>
}

// 구현체
class RealWebSocketWorkerInterface implements WebSocketWorkerInterface
class MockWebSocketWorkerInterface implements WebSocketWorkerInterface
```

## 🚀 Worker Services Configuration

### Python Sandbox Server (Port: 3001)
```yaml
python_sandbox:
  name: "python-sandbox"
  type: "websocket"
  port: 3001
  protocol: "ws"
  capabilities:
    - "python-execution"
    - "file-operations"
    - "package-install"
    - "code-analysis"
  workspace: "./workspace"
  max_concurrent_tasks: 5
  timeout: 300s
  health_check:
    endpoint: "/health"
    interval: 30s
    timeout: 5s
```

### Figma MCP Server (Port: 3002)
```yaml
figma_mcp:
  name: "figma-mcp"
  type: "websocket"
  port: 3002
  protocol: "mcp"
  capabilities:
    - "figma-design"
    - "ui-generation"
    - "asset-export"
    - "design-analysis"
  max_concurrent_tasks: 3
  timeout: 180s
  health_check:
    endpoint: "/health"
    interval: 30s
    timeout: 5s
  figma_config:
    api_token: "${FIGMA_API_TOKEN}"
    team_id: "${FIGMA_TEAM_ID}"
```

### Browser Worker Server (Port: 3003)
```yaml
browser_worker:
  name: "browser-worker"
  type: "websocket"
  port: 3003
  protocol: "ws"
  capabilities:
    - "web-automation"
    - "scraping"
    - "screenshot"
    - "testing"
    - "form-filling"
  max_concurrent_tasks: 4
  timeout: 120s
  health_check:
    endpoint: "/health"
    interval: 30s
    timeout: 5s
  browser_config:
    type: "headless-chrome"
    pool_size: 3
    auto_restart: true
    memory_limit: "512MB"
    # GPU 없는 환경 최적화 설정
    software_rendering: true
    chrome_flags:
      - "--disable-gpu"
      - "--disable-software-rasterizer" 
      - "--disable-dev-shm-usage"
      - "--no-sandbox"
      - "--disable-setuid-sandbox"
      - "--disable-accelerated-2d-canvas"
      - "--disable-accelerated-jpeg-decoding"
      - "--disable-accelerated-mjpeg-decode"
      - "--disable-accelerated-video-decode"
      - "--memory-pressure-off"
      - "--disable-background-timer-throttling"
      - "--disable-renderer-backgrounding"
      - "--disable-backgrounding-occluded-windows"
    performance_mode: "cpu_optimized"  # CPU 최적화 모드
```

## 🔄 Task Execution Flow

### 1. Task 수신 및 분배
```
DistributedOrchestratorAgent
└── Task 생성
    └── DistributedExecutorAgent
        └── WorkerManager
            └── LoadBalancer (최적 Worker 선택)
                └── Worker 실행
```

### 2. Worker 선택 알고리즘
```typescript
class LoadBalancer {
  selectOptimalWorker(task: WorkerTask): string {
    const suitableWorkers = this.filterByCapability(task.type);
    const availableWorkers = this.filterByStatus(suitableWorkers, 'online');
    const optimalWorker = this.sortByLoad(availableWorkers)[0];
    return optimalWorker.workerId;
  }
}
```

### 3. Task 실행 및 모니터링
```
1. Task Queue에 추가
2. Worker 선택 및 할당
3. WebSocket으로 Task 전송
4. 실행 상태 실시간 모니터링
5. 결과 수신 및 반환
6. Worker Load 업데이트
```

## 🌐 Browser Worker 특수 관리

### Browser Client Pool Management
```typescript
class BrowserManager {
  private chromePool: ChromeInstance[] = [];
  private maxInstances: number = 3;
  
  async getAvailableInstance(): Promise<ChromeInstance>
  async releaseInstance(instance: ChromeInstance): Promise<void>
  async restartInstance(instanceId: string): Promise<void>
  async cleanupMemory(): Promise<void>
}

interface ChromeInstance {
  id: string;
  process: ChildProcess;
  status: 'idle' | 'busy' | 'error';
  memoryUsage: number;
  taskCount: number;
  createdAt: Date;
}
```

### Browser Task Types
```typescript
type BrowserTaskType = 
  | 'screenshot'
  | 'scraping'
  | 'automation'
  | 'testing'
  | 'form-filling'
  | 'pdf-generation';

interface BrowserTask extends WorkerTask {
  taskType: BrowserTaskType;
  url?: string;
  selector?: string;
  script?: string;
  options?: BrowserOptions;
}
```

## 📊 Monitoring & Metrics

### Worker Metrics Collection
```typescript
interface WorkerMetrics {
  workerId: string;
  workerType: string;
  
  // Performance Metrics
  taskCount: number;
  averageResponseTime: number;
  successRate: number;
  errorCount: number;
  
  // Resource Metrics
  cpuUsage: number;
  memoryUsage: number;
  diskUsage: number;
  
  // Connection Metrics
  connectionCount: number;
  uptime: number;
  lastHealthCheck: Date;
}
```

### Real-time Monitoring Dashboard
```
Worker Status Board:
┌─────────────────┬──────────┬──────────┬─────────────┐
│ Worker          │ Status   │ Load     │ Tasks       │
├─────────────────┼──────────┼──────────┼─────────────┤
│ python-sandbox  │ ✅ Online│ 60%      │ 3/5         │
│ figma-mcp       │ ✅ Online│ 30%      │ 1/3         │  
│ browser-worker  │ ⚠️  Busy │ 85%      │ 4/4         │
└─────────────────┴──────────┴──────────┴─────────────┘
```

## 🔧 Configuration Management

### Environment Variables
```bash
# Worker Ports
WORKER_PYTHON_PORT=3001
WORKER_FIGMA_PORT=3002
WORKER_BROWSER_PORT=3003

# Worker Management
WORKER_HEALTH_CHECK_INTERVAL=30
WORKER_MAX_RETRIES=3
WORKER_TIMEOUT=300

# Browser Specific (GPU 없는 환경 최적화)
BROWSER_POOL_SIZE=3
BROWSER_MEMORY_LIMIT=512
BROWSER_AUTO_RESTART=true
BROWSER_SOFTWARE_RENDERING=true
BROWSER_CPU_OPTIMIZED=true

# Figma Specific  
FIGMA_API_TOKEN=your_token_here
FIGMA_TEAM_ID=your_team_id
```

### Docker 환경별 설정

#### GPU 없는 Docker Linux 서버 (일반적인 경우)
```dockerfile
# Dockerfile for Browser Worker
FROM node:18-slim

# Chrome 의존성 설치
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libgcc1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    lsb-release \
    wget \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Chrome 설치
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Browser Worker 앱 설정
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Chrome 최적화 플래그 (GPU 없는 환경)
ENV CHROME_FLAGS="--disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --no-sandbox --disable-setuid-sandbox --disable-accelerated-2d-canvas --memory-pressure-off"

EXPOSE 3003
CMD ["node", "browser-worker-server.js"]
```

#### GPU 있는 환경 (선택적)
```dockerfile
# GPU 지원 환경에서는 다른 플래그 사용
ENV CHROME_FLAGS="--use-gl=angle --use-angle=gl-egl --enable-gpu-rasterization --ignore-gpu-blocklist"
```

## 🚀 Implementation Plan

### Phase 1: Core Infrastructure (1주)
- [x] Python Sandbox Server ✅ 완료 (Port: 3001)
- [ ] WorkerManager 기본 구조
- [ ] WorkerRegistry 구현
- [ ] WebSocketWorkerInterface 추상화

### Phase 2: Worker Services (1주)
- [ ] Figma MCP Server 구현 (Port: 3002)
- [ ] Browser Worker Server 구현 (Port: 3003)
- [ ] Browser Manager & Chrome Pool
- [ ] HealthMonitor 구현

### Phase 3: Advanced Features (1주)
- [ ] LoadBalancer 최적화
- [ ] Real-time Monitoring
- [ ] Auto-scaling
- [ ] Performance Optimization

## 🎯 Success Criteria

### 기능 요구사항
- ✅ 3가지 Worker Service 동시 운영
- ✅ 자동 Worker 발견 및 등록
- ✅ 실시간 상태 모니터링
- ✅ 부하 분산 및 최적화
- ✅ 장애 감지 및 자동 복구

### 성능 요구사항
- Task 처리 시간: < 5초 (Python), < 10초 (Figma), < 15초 (Browser)
- Worker 가용성: > 99%
- 동시 Task 처리: Python(5), Figma(3), Browser(4)
- 메모리 사용량: < 1GB per Worker

이 설계는 **순수 분산 구조 Agent**만을 위한 최적화된 Worker 관리 시스템으로, 확장성과 성능을 극대화하도록 구성되었습니다.
