# COGO 분산 Agent 시스템 - 완전한 사용 가이드

## 🎯 개요

COGO (Create-Go) 분산 Agent 시스템은 **cogo.xyz 도메인** 기반의 완전한 통합 인증을 제공하는 **엔터프라이즈급 AI Agent 플랫폼**입니다.

### 🏗️ 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│              🎊 COGO 완전 통합 분산 시스템 🎊                │
├─────────────────────────────────────────────────────────────┤
│ 🔐 통합 인증: cogo0@cogo.xyz (단일 JWT 토큰)                │
│ 🏢 도메인: cogo.xyz 기반 완전 통합                          │
├─────────────────────────────────────────────────────────────┤
│ ⚙️ 분산 Agent 클러스터 (포트 6001-6005):                    │
│   • Orchestrator Agent (워크플로우 조정)                    │
│   • Indexing Agent (코드 분석 & 인덱싱)                     │
│   • Research Agent (멀티 AI 리서치)                         │
│   • GraphRAG Agent (지식 그래프 추론)                       │
│   • Executor Agent (Worker 관리 & 실행)                     │
├─────────────────────────────────────────────────────────────┤
│ 🌐 Edge Functions: Chat Gateway (Supabase)                 │
│ 📡 Real-time: Supabase Realtime 채널 통신                   │
│ 🔧 Workers: Python/Figma/Browser (포트 3001-3003)          │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 빠른 시작

### 1. 시스템 시작

```bash
# 1. 프로젝트 디렉토리 이동
cd /Users/hyunsuklee/Desktop/Dev/cogo-project/cogo-agent-core

# 2. 환경 변수 확인
source .cogo-auth.env

# 3. 모든 Agent 시작
./scripts/start-all-agents.sh

# 4. Worker 서버 시작
./scripts/start-all-workers.sh
```

### 2. 시스템 상태 확인

```bash
# 분산 Agent 상태 확인
curl http://localhost:6001/health  # Orchestrator
curl http://localhost:6002/health  # Indexing
curl http://localhost:6003/health  # Research  
curl http://localhost:6004/health  # GraphRAG
curl http://localhost:6005/health  # Executor

# Worker 상태 확인 (WebSocket)
curl http://localhost:3001/health  # Python Sandbox
curl http://localhost:3007/health  # Figma MCP
curl http://localhost:3003/health  # Browser Worker
```

---

## 🔐 인증 시스템

### COGO 통합 인증

모든 시스템 컴포넌트는 **단일 JWT 토큰**으로 인증됩니다:

- **사용자**: `cogo0@cogo.xyz`
- **도메인**: `cogo.xyz`
- **역할**: `cogo_agent`
- **권한**: 모든 Agent 및 Worker 관리 권한

### 인증 토큰 사용

```bash
# 환경 변수에서 토큰 로드
source .cogo-auth.env

# API 호출 시 Authorization 헤더 사용
curl -H "Authorization: Bearer $COGO_AUTH_TOKEN" \
     -H "Content-Type: application/json" \
     http://localhost:6005/api/agent/task
```

### 새 토큰 생성 (필요시)

```bash
# COGO 인증 토큰 재생성
node generate-cogo-token.js
source .cogo-auth.env
```

---

## ⚙️ 분산 Agent 클러스터

### Agent 역할 및 책임

| Agent | 포트 | 역할 | 주요 기능 |
|-------|------|------|-----------|
| **Orchestrator** | 6001 | 워크플로우 조정 | • 복잡한 작업 분해<br>• Agent 간 작업 분배<br>• 전체 프로세스 관리 |
| **Indexing** | 6002 | 코드 분석 & 인덱싱 | • 코드베이스 분석<br>• 문서 인덱싱<br>• 벡터 검색 |
| **Research** | 6003 | 멀티 AI 리서치 | • 웹 검색<br>• 지식 합성<br>• 리서치 보고서 생성 |
| **GraphRAG** | 6004 | 지식 그래프 추론 | • 그래프 기반 추론<br>• 패턴 분석<br>• 복합 쿼리 처리 |
| **Executor** | 6005 | Worker 관리 & 실행 | • Worker 조율<br>• 작업 실행<br>• 결과 통합 |

### Agent API 엔드포인트

#### 공통 엔드포인트

```bash
# 상태 확인
GET /health

# 작업 제출
POST /api/agent/task
Content-Type: application/json
Authorization: Bearer $COGO_AUTH_TOKEN
{
  "type": "task-type",
  "priority": "high|medium|low",
  "data": {
    "title": "작업 제목",
    "description": "작업 설명"
  }
}

# Agent 메시지 전송
POST /api/agent/message
Content-Type: application/json
Authorization: Bearer $COGO_AUTH_TOKEN
{
  "targetAgent": "orchestrator",
  "message": "메시지 내용"
}
```

---

## 🌐 Edge Functions

### Chat Gateway

**URL**: `https://cjvgmyotqxfpxpvmwxfv.supabase.co/functions/v1/chat-gateway`

#### 지원 액션

```bash
# 1. 시스템 상태 확인
GET /functions/v1/chat-gateway

# 2. Agent 작업 생성
POST /functions/v1/chat-gateway
Content-Type: application/json
Authorization: Bearer $COGO_AUTH_TOKEN
{
  "action": "agent_task",
  "taskType": "worker-execution",
  "agentType": "executor",
  "sessionId": "session-id",
  "userId": "user-id",
  "title": "작업 제목",
  "description": "작업 설명"
}

# 3. AI 인사말 생성
POST /functions/v1/chat-gateway
Content-Type: application/json
Authorization: Bearer $COGO_AUTH_TOKEN
{
  "action": "ai_greeting",
  "userMessage": "안녕하세요",
  "targetLanguage": "ko"
}

# 4. 채팅 메시지 전송
POST /functions/v1/chat-gateway
Content-Type: application/json
Authorization: Bearer $COGO_AUTH_TOKEN
{
  "action": "send_message",
  "sessionId": "session-id",
  "content": "메시지 내용"
}
```

---

## 🔧 Worker 서버

### Worker 역할 및 기능

| Worker | 포트 | 타입 | 주요 기능 |
|--------|------|------|-----------|
| **Python Sandbox** | 3001 | WebSocket | • Python 코드 실행<br>• 패키지 설치<br>• 파일 작업 |
| **Figma MCP** | 3002 | WebSocket | • Figma 디자인 분석<br>• 컴포넌트 추출<br>• UI 자동화 |
| **Browser Worker** | 3003 | WebSocket | • 웹 자동화<br>• 스크린샷<br>• DOM 조작 |

### Worker 관리

#### Executor Agent를 통한 Worker 관리

```bash
# Worker 상태 확인
curl -H "Authorization: Bearer $COGO_AUTH_TOKEN" \
     http://localhost:6005/api/worker/status

# Worker 작업 실행
curl -X POST \
     -H "Authorization: Bearer $COGO_AUTH_TOKEN" \
     -H "Content-Type: application/json" \
     http://localhost:6005/api/agent/task \
     -d '{
       "type": "worker-execution",
       "data": {
         "worker": "python-sandbox",
         "task": "execute_code",
         "code": "print(\"Hello COGO!\")"
       }
     }'
```

---

## 📡 실시간 통신

### Supabase Realtime 채널

모든 Agent는 Supabase Realtime을 통해 실시간 통신합니다:

#### 채널 구조

```
distributed-orchestrator-6001    # Orchestrator 전용
distributed-indexing-6002        # Indexing 전용
distributed-research-6003        # Research 전용
distributed-graphrag-6004        # GraphRAG 전용
distributed-executor-6005        # Executor 전용

agent_tasks_orchestrator         # Edge Function → Orchestrator
agent_tasks_indexing            # Edge Function → Indexing
agent_tasks_research            # Edge Function → Research
agent_tasks_graphrag            # Edge Function → GraphRAG
agent_tasks_executor            # Edge Function → Executor
```

#### 실시간 모니터링

```bash
# 실시간 Agent 통신 모니터링
node scripts/monitor-realtime-channels.js

# 특정 Agent 로그 확인
tail -f orchestrator.log
tail -f executor.log
```

---

## 🧪 시스템 테스트

### 1. End-to-End 테스트

```bash
# 전체 시스템 End-to-End 테스트
node test-cogo-end-to-end.js

# 결과: cogo-e2e-test-report-{timestamp}.json
```

### 2. 통합 인증 테스트

```bash
# 모든 Agent COGO 인증 테스트
node test-cogo-unified-auth.js

# 결과: cogo-unified-auth-report-{timestamp}.json
```

### 3. 개별 Agent 테스트

```bash
# 특정 Agent 테스트
curl -X POST \
     -H "Authorization: Bearer $COGO_AUTH_TOKEN" \
     -H "Content-Type: application/json" \
     http://localhost:6001/api/agent/task \
     -d '{
       "type": "test",
       "data": {
         "title": "Orchestrator 테스트"
       }
     }'
```

---

## 🛠️ 운영 및 관리

### 시스템 시작/중지

#### 전체 시스템 시작

```bash
# 모든 Agent 시작
nohup node real-distributed-server.js orchestrator 6001 > orchestrator.log 2>&1 &
nohup node real-distributed-server.js indexing 6002 > indexing.log 2>&1 &
nohup node real-distributed-server.js research 6003 > research.log 2>&1 &
nohup node real-distributed-server.js graphrag 6004 > graphrag.log 2>&1 &
nohup node real-distributed-server.js executor 6005 > executor.log 2>&1 &

# 모든 Worker 시작
cd cogo-worker && nohup python3 websocket_sandbox_server.py > ../python-sandbox.log 2>&1 &
cd mcp-servers/figma-context && nohup npm run start:websocket > ../../figma-mcp.log 2>&1 &
cd mcp-servers/browser-use && nohup npm run start:websocket > ../../browser-worker.log 2>&1 &
```

#### 전체 시스템 중지

```bash
# 모든 프로세스 종료
kill $(ps aux | grep "real-distributed-server.js" | grep -v grep | awk '{print $2}')
kill $(ps aux | grep "websocket_sandbox_server" | grep -v grep | awk '{print $2}')
kill $(ps aux | grep "npm run start:websocket" | grep -v grep | awk '{print $2}')
```

### 로그 모니터링

```bash
# 실시간 로그 모니터링
tail -f orchestrator.log indexing.log research.log graphrag.log executor.log

# Worker 로그 모니터링  
tail -f python-sandbox.log figma-mcp.log browser-worker.log

# 특정 Agent 상세 로그
tail -f -n 100 executor.log | grep "Task"
```

### 상태 모니터링

```bash
# 시스템 전체 상태 대시보드
watch -n 5 'echo "=== COGO Agent 상태 ===" && \
curl -s http://localhost:6001/health | jq "{agent: \"orchestrator\", status, supabaseConnected}" && \
curl -s http://localhost:6002/health | jq "{agent: \"indexing\", status, supabaseConnected}" && \
curl -s http://localhost:6003/health | jq "{agent: \"research\", status, supabaseConnected}" && \
curl -s http://localhost:6004/health | jq "{agent: \"graphrag\", status, supabaseConnected}" && \
curl -s http://localhost:6005/health | jq "{agent: \"executor\", status, supabaseConnected}"'
```

---

## 🔧 문제 해결

### 일반적인 문제 및 해결

#### 1. Agent 연결 실패

```bash
# 문제: Agent가 Supabase에 연결되지 않음
# 해결: 환경 변수 및 토큰 확인
source .cogo-auth.env
echo $COGO_AUTH_TOKEN
echo $SUPABASE_URL

# 토큰 재생성
node generate-cogo-token.js
```

#### 2. Worker 연결 실패

```bash
# 문제: Worker 서버 응답 없음
# 해결: Worker 프로세스 확인 및 재시작
ps aux | grep "websocket_sandbox_server\|npm run start:websocket"

# 개별 Worker 재시작
cd cogo-worker && python3 websocket_sandbox_server.py
```

#### 3. 실시간 통신 실패

```bash
# 문제: Realtime 채널 연결 안됨
# 해결: Supabase 연결 상태 확인
curl -H "Authorization: Bearer $COGO_AUTH_TOKEN" \
     "https://cjvgmyotqxfpxpvmwxfv.supabase.co/rest/v1/"
```

#### 4. 인증 오류

```bash
# 문제: 401 Unauthorized 오류
# 해결: COGO 토큰 갱신
node generate-cogo-token.js
source .cogo-auth.env

# 모든 Agent 재시작
./scripts/restart-all-agents.sh
```

---

## 📊 성능 최적화

### 시스템 성능 모니터링

```bash
# Agent 성능 메트릭 확인
curl -H "Authorization: Bearer $COGO_AUTH_TOKEN" \
     http://localhost:6005/api/agent/metrics

# Worker 활용률 확인
curl -H "Authorization: Bearer $COGO_AUTH_TOKEN" \
     http://localhost:6005/api/worker/metrics
```

### 최적화 권장사항

1. **메모리 사용량 모니터링**
   ```bash
   ps aux | grep "node real-distributed-server" | awk '{print $4, $11}'
   ```

2. **동시 작업 수 조정**
   - Executor Agent: `maxConcurrentTasks` 설정
   - Worker 서버: 연결 풀 크기 조정

3. **로그 로테이션 설정**
   ```bash
   # logrotate 설정으로 로그 파일 크기 관리
   sudo logrotate -d /etc/logrotate.d/cogo-agents
   ```

---

## 🔐 보안 가이드

### 인증 토큰 관리

1. **토큰 보안**
   - `.cogo-auth.env` 파일은 `.gitignore`에 포함
   - 프로덕션 환경에서는 환경 변수로 주입
   - 정기적인 토큰 갱신 (30일마다 권장)

2. **네트워크 보안**
   - 내부 Agent 포트(6001-6005)는 방화벽으로 보호
   - Supabase 연결은 HTTPS/WSS 사용
   - Worker 포트(3001-3003)는 로컬 네트워크만 접근

3. **접근 제어**
   - RBAC 기반 권한 관리
   - API 엔드포인트별 권한 검증
   - 감사 로그 기록

---

## 📈 확장 가이드

### 새로운 Agent 추가

1. **Agent 클래스 생성**
   ```typescript
   // src/agents/NewAgent.ts
   export class NewAgent extends BaseAgent {
     constructor() {
       super('new-agent', 'New Agent', 'new');
     }
   }
   ```

2. **real-distributed-server.js에 추가**
   ```javascript
   case 'new':
     console.log(`🆕 ${this.agentType}: Setting up new functionality`);
     break;
   ```

3. **Edge Function에 Agent 타입 추가**
   ```typescript
   const supportedAgents = ['orchestrator', 'indexing', 'research', 'graphrag', 'executor', 'new']
   ```

### 새로운 Worker 추가

1. **Worker 서버 구현**
   - WebSocket 기반 통신
   - Health check 엔드포인트
   - 표준 메시지 프로토콜

2. **Executor Agent에 Worker 등록**
   ```javascript
   const workerConfigs = [
     // 기존 Worker들...
     {
       workerId: 'new-worker-1',
       workerType: 'new-worker',
       endpoint: 'ws://localhost:3004'
     }
   ];
   ```

---

## 📞 지원 및 문의

### 개발 팀 연락처

- **프로젝트 관리자**: cogo0@cogo.xyz
- **기술 지원**: COGO Platform Team
- **문서 업데이트**: 2025년 8월 8일

### 추가 리소스

- **GitHub Repository**: [COGO Agent Core](https://github.com/cogo-platform/cogo-agent-core)
- **기술 문서**: `docs/` 디렉토리
- **API 참조**: `docs/API_REFERENCE.md`
- **개발 가이드**: `docs/DEVELOPMENT_GUIDE.md`

---

## 📄 라이선스

이 시스템은 **COGO Platform의 엔터프라이즈 라이선스** 하에 배포됩니다.

**© 2025 COGO Platform. All rights reserved.**

---

*이 문서는 COGO 분산 Agent 시스템 v2.0.0 기준으로 작성되었습니다.*
