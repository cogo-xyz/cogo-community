# COGO Agent Core - SandboxManager 구현

## 📋 개요

SandboxManager가 채널 구조에 맞춰 완전히 새로 구현되었습니다. 워커 관리, 작업 실행, 코드 컴파일, AI 수정 등의 기능을 제공하며 Supabase Realtime을 통한 실시간 통신을 지원합니다.

## 🏗️ 아키텍처

### 채널 구조
```
Client → agents.sandbox → SandboxManager → Response Channels
Client → tasks.requests → SandboxManager → task.* Channels
Client → code.compilation → SandboxManager → code.compilation.result
Client → ai.fixes → SandboxManager → ai.fixes.result
```

### 워커 관리 플로우
```
Create Worker → Assign Task → Execute Task → Monitor → Complete/Cleanup
```

## 🔧 구현된 기능

### 1. 워커 관리
- **워커 생성**: `createWorker(type)`
- **워커 제거**: `removeWorker(workerId)`
- **워커 상태 조회**: `getWorkerStatus(workerId)`
- **모든 워커 조회**: `getAllWorkers()`
- **워커 복구**: `recoverWorker(workerId)`

### 2. 작업 관리
- **작업 할당**: `assignTask(taskRequest)`
- **작업 실행**: `executeSandboxTask(taskId, command)`
- **작업 상태 조회**: `getTaskStatus(taskId)`
- **작업 종료**: `terminateTask(taskId)`
- **큐 상태 조회**: `getQueueStatus()`

### 3. 코드 처리
- **코드 컴파일**: `compileCode(taskId, code, language)`
- **AI 오류 수정**: `fixCompilationError(fixRequest)`

### 4. 모니터링
- **헬스 체크**: `getHealth()`
- **블록 감지**: `detectBlock(workerId)`
- **블록 복구**: `recoverFromBlock(workerId)`
- **하트비트**: 10초마다 브로드캐스트
- **헬스 체크**: 30초마다 수행

## 📡 채널 구조

### 입력 채널
- **agents.sandbox**: 워커 관리 요청
- **tasks.requests**: 작업 관리 요청
- **code.compilation**: 코드 컴파일 요청
- **ai.fixes**: AI 수정 요청

### 출력 채널
- **worker.created**: 워커 생성 완료
- **worker.removed**: 워커 제거 완료
- **workers.list**: 워커 목록 응답
- **task.assigned**: 작업 할당 완료
- **task.executed**: 작업 실행 완료
- **task.status**: 작업 상태 응답
- **task.terminated**: 작업 종료 완료
- **code.compilation.result**: 컴파일 결과
- **ai.fixes.result**: AI 수정 결과
- **sandbox.health**: 헬스 체크 응답
- **sandbox.heartbeat**: 하트비트

## 🧪 테스트 시나리오

### 1. 워커 생성
```json
{
  "type": "agents.sandbox",
  "payload": {
    "type": "create_worker",
    "workerType": "basic"
  }
}
```

### 2. 작업 할당
```json
{
  "type": "tasks.requests",
  "payload": {
    "type": "assign_task",
    "taskId": "test_task_1",
    "command": "echo Hello World",
    "type": "basic"
  }
}
```

### 3. 코드 컴파일
```json
{
  "type": "code.compilation",
  "payload": {
    "taskId": "test_task_1",
    "code": "console.log('Hello World');",
    "language": "javascript"
  }
}
```

### 4. AI 수정 요청
```json
{
  "type": "ai.fixes",
  "payload": {
    "taskId": "test_task_1",
    "error": "SyntaxError: Unexpected token",
    "code": "console.log('Hello World'",
    "language": "javascript"
  }
}
```

## 🚀 API 엔드포인트

### 워커 관리
- `GET /api/sandbox/health` - 헬스 체크
- `GET /api/sandbox/workers` - 모든 워커 조회
- `GET /api/sandbox/workers/:workerId` - 특정 워커 조회
- `POST /api/sandbox/workers` - 워커 생성
- `DELETE /api/sandbox/workers/:workerId` - 워커 제거
- `POST /api/sandbox/workers/:workerId/execute` - 작업 실행

### 작업 관리
- `GET /api/sandbox/tasks/:taskId` - 작업 상태 조회
- `DELETE /api/sandbox/tasks/:taskId` - 작업 종료
- `GET /api/sandbox/queue` - 큐 상태 조회

### 고급 기능
- `POST /api/sandbox/fix-compilation` - 컴파일 오류 수정
- `POST /api/sandbox/workers/:workerId/detect-block` - 블록 감지
- `POST /api/sandbox/workers/:workerId/recover` - 블록 복구

## 📊 현재 상태

### ✅ 완료된 작업
- [x] SandboxManager 클래스 구현
- [x] 워커 관리 시스템
- [x] 작업 관리 시스템
- [x] 코드 컴파일 기능
- [x] AI 수정 기능
- [x] 모니터링 시스템
- [x] 채널 기반 통신
- [x] API 라우트 구현
- [x] 컴파일 오류 해결
- [x] 서버 통합 완료

### 🔄 다음 단계
- [ ] 실제 OpenHands CLI 연동
- [ ] 워커 프로세스 관리
- [ ] 파일 시스템 관리
- [ ] 보안 강화
- [ ] 성능 최적화

## 🚀 사용법

### 서버 시작
```bash
npm start
```

### 워커 생성
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"type":"basic"}' \
  http://localhost:3000/api/sandbox/workers
```

### 작업 실행
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"command":"echo Hello World","priority":1}' \
  http://localhost:3000/api/sandbox/workers/{workerId}/execute
```

### 헬스 체크
```bash
curl http://localhost:3000/api/sandbox/health
```

### 테스트 실행
```bash
node test-sandbox-channels.js
```

## 🔒 보안 고려사항

1. **워커 격리**: 각 워커는 독립적인 워크스페이스에서 실행
2. **작업 제한**: 최대 워커 수 및 작업 시간 제한
3. **리소스 관리**: 메모리 및 CPU 사용량 모니터링
4. **오류 처리**: 워커 실패 시 자동 복구

## 📝 참고사항

- 현재 Mock 모드로 작동하여 실제 프로세스 생성 없이 테스트 가능
- 워커 타입: basic, flutter, nodejs, python 지원
- 최대 워커 수: 5개 (설정 가능)
- 하트비트: 10초마다
- 헬스 체크: 30초마다
- 블록 감지: 30초 이상 활동 없음

## 🔄 실제 OpenHands 연동 준비

### 1. 워커 프로세스 관리
```typescript
// 실제 프로세스 생성
const child = spawn('openhands', ['--workspace', workspace, command]);
```

### 2. 파일 시스템 관리
```typescript
// 워크스페이스 생성 및 정리
await fs.mkdir(workspace, { recursive: true });
```

### 3. 리소스 모니터링
```typescript
// 프로세스 리소스 사용량 추적
const usage = process.cpuUsage();
const memory = process.memoryUsage();
``` 