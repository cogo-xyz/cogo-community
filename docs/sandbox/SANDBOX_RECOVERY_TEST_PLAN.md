# SandboxManager 복구 시스템 테스트 계획서

## 1. 테스트 개요

### 1.1 목적
- SandboxManager의 비정상 상태 감지 로직 검증
- 자동 복구/재시작 기능의 신뢰성 확보
- 실제 운영 환경에서의 안정성 보장

### 1.2 테스트 범위
- WebSocket 연결 상태 모니터링
- Heartbeat 기반 블록 감지
- 프로세스 강제 종료 감지
- 자동 복구 및 재시작 로직
- 작업 재할당 및 큐 관리

### 1.3 테스트 환경
- **개발 환경**: TypeScript SandboxManager + Python cogo-worker
- **테스트 도구**: Jest, Supertest, WebSocket 클라이언트
- **모니터링**: 로그 분석, 상태 추적

## 2. 테스트 시나리오

### 2.1 시나리오 1: Heartbeat 타임아웃 테스트

#### 2.1.1 테스트 목적
- 워커가 5분 이상 heartbeat를 보내지 않을 때 블록 상태로 감지되는지 확인

#### 2.1.2 테스트 절차
1. **준비 단계**
   - SandboxManager 초기화
   - cogo-worker 3개 생성 (basic, nodejs, python)
   - 각 워커에 작업 할당

2. **실행 단계**
   - Python cogo-worker의 heartbeat 전송을 일시적으로 중단
   - 5분 대기
   - SandboxManager의 블록 감지 로직 확인

3. **검증 항목**
   - [ ] 워커 상태가 'blocked'로 변경됨
   - [ ] 로그에 블록 감지 메시지 기록됨
   - [ ] 현재 작업이 'blocked' 상태로 변경됨
   - [ ] 자동 복구 시도가 시작됨

#### 2.1.3 예상 결과
```json
{
  "workerId": "cogo-worker-python-1234567890",
  "status": "blocked",
  "lastActivity": "2024-08-04T10:30:00.000Z",
  "blockDetectedAt": "2024-08-04T10:35:00.000Z",
  "recoveryAttempts": 1
}
```

### 2.2 시나리오 2: WebSocket 연결 끊김 테스트

#### 2.2.1 테스트 목적
- WebSocket 연결이 예기치 않게 끊어질 때 감지 및 복구 확인

#### 2.2.2 테스트 절차
1. **준비 단계**
   - 정상적인 WebSocket 연결 상태 확인
   - 워커에 작업 할당

2. **실행 단계**
   - Python cogo-worker 프로세스 강제 종료 (SIGKILL)
   - WebSocket 연결 끊김 감지 확인
   - 자동 재연결 시도 확인

3. **검증 항목**
   - [ ] WebSocket 연결 끊김 이벤트 발생
   - [ ] 워커 상태가 'disconnected'로 변경됨
   - [ ] 현재 작업이 'failed' 상태로 변경됨
   - [ ] 새로운 워커 생성 시도
   - [ ] 실패한 작업이 큐에 재등록됨

#### 2.2.3 예상 결과
```json
{
  "event": "workerDisconnected",
  "workerId": "cogo-worker-nodejs-1234567890",
  "reason": "WebSocket connection lost",
  "currentTask": "task-123",
  "recoveryAction": "createNewWorker"
}
```

### 2.3 시나리오 3: 프로세스 강제 종료 테스트

#### 2.3.1 테스트 목적
- cogo-worker 프로세스가 강제 종료될 때 감지 및 복구 확인

#### 2.3.2 테스트 절차
1. **준비 단계**
   - 워커 프로세스 ID 확인
   - 작업 실행 중 상태 확인

2. **실행 단계**
   - `kill -9 <process_id>` 명령으로 강제 종료
   - 프로세스 종료 감지 확인
   - 자동 복구 프로세스 확인

3. **검증 항목**
   - [ ] 프로세스 종료 이벤트 감지
   - [ ] 워커 상태가 'error'로 변경됨
   - [ ] 현재 작업이 'failed'로 변경됨
   - [ ] 새로운 워커 생성
   - [ ] 실패한 작업 재할당

### 2.4 시나리오 4: 무한루프 블록 테스트

#### 2.4.1 테스트 목적
- cogo-worker가 무한루프에 빠져 응답하지 않을 때 감지 및 복구

#### 2.4.2 테스트 절차
1. **준비 단계**
   - 무한루프를 포함한 테스트 코드 준비
   - 워커에 무한루프 작업 할당

2. **실행 단계**
   - 무한루프 작업 실행
   - 5분 대기 후 블록 감지 확인
   - 강제 종료 및 복구 확인

3. **검증 항목**
   - [ ] 무한루프 작업 감지
   - [ ] 워커 상태가 'blocked'로 변경됨
   - [ ] 강제 종료 실행
   - [ ] 새로운 워커 생성
   - [ ] 작업 재할당

### 2.5 시나리오 5: 네트워크 장애 테스트

#### 2.5.1 테스트 목적
- 네트워크 연결 문제로 인한 통신 장애 감지 및 복구

#### 2.5.2 테스트 절차
1. **준비 단계**
   - 정상적인 WebSocket 통신 확인
   - 네트워크 모니터링 설정

2. **실행 단계**
   - 네트워크 연결 일시적 차단
   - 연결 재시도 로직 확인
   - 복구 성공 여부 확인

3. **검증 항목**
   - [ ] 네트워크 오류 감지
   - [ ] 재연결 시도 로그 확인
   - [ ] 연결 복구 성공
   - [ ] 작업 재개 확인

## 3. 테스트 자동화

### 3.1 테스트 스크립트 구조

```typescript
// test-sandbox-recovery.ts
describe('SandboxManager Recovery Tests', () => {
  let sandboxManager: SandboxManager;
  let webSocketServer: SandboxWebSocketServer;

  beforeEach(async () => {
    // 테스트 환경 초기화
  });

  afterEach(async () => {
    // 테스트 환경 정리
  });

  describe('Heartbeat Timeout Tests', () => {
    test('should detect worker block after 5 minutes of no heartbeat', async () => {
      // 시나리오 1 구현
    });
  });

  describe('WebSocket Disconnection Tests', () => {
    test('should handle WebSocket connection loss', async () => {
      // 시나리오 2 구현
    });
  });

  describe('Process Termination Tests', () => {
    test('should detect and recover from forced process termination', async () => {
      // 시나리오 3 구현
    });
  });

  describe('Infinite Loop Tests', () => {
    test('should detect and recover from infinite loop', async () => {
      // 시나리오 4 구현
    });
  });

  describe('Network Failure Tests', () => {
    test('should handle network connectivity issues', async () => {
      // 시나리오 5 구현
    });
  });
});
```

### 3.2 모니터링 및 로깅

```typescript
// 테스트용 로깅 설정
const testLogger = {
  info: (message: string, data?: any) => {
    console.log(`[TEST-INFO] ${message}`, data);
  },
  error: (message: string, error?: any) => {
    console.error(`[TEST-ERROR] ${message}`, error);
  },
  warn: (message: string, data?: any) => {
    console.warn(`[TEST-WARN] ${message}`, data);
  }
};
```

## 4. 성공 기준

### 4.1 기능적 기준
- [ ] 모든 비정상 상태가 5분 이내에 감지됨
- [ ] 자동 복구가 10분 이내에 완료됨
- [ ] 실패한 작업이 100% 재할당됨
- [ ] 시스템 전체가 정상 상태로 복구됨

### 4.2 성능 기준
- [ ] 블록 감지 지연시간: < 30초
- [ ] 복구 완료 시간: < 2분
- [ ] 작업 재할당 시간: < 1분
- [ ] 시스템 안정성: 99% 이상

### 4.3 로깅 기준
- [ ] 모든 이벤트가 적절한 로그 레벨로 기록됨
- [ ] 복구 과정이 상세히 추적 가능함
- [ ] 오류 상황이 명확히 식별됨

## 5. 테스트 실행 계획

### 5.1 1단계: 단위 테스트
- 개별 복구 함수 테스트
- WebSocket 이벤트 핸들러 테스트
- 상태 관리 로직 테스트

### 5.2 2단계: 통합 테스트
- SandboxManager + WebSocket 서버 통합 테스트
- 실제 cogo-worker와의 연동 테스트

### 5.3 3단계: 부하 테스트
- 다중 워커 동시 장애 시나리오
- 연속적인 복구 시도 테스트

### 5.4 4단계: 장기 안정성 테스트
- 24시간 연속 운영 테스트
- 메모리 누수 및 성능 저하 확인

## 6. 테스트 결과 문서화

### 6.1 테스트 리포트 템플릿
```markdown
# SandboxManager 복구 테스트 리포트

## 테스트 개요
- 테스트 일시: 2024-08-04
- 테스트 환경: Development
- 테스트 버전: v1.0.0

## 테스트 결과 요약
- 총 테스트 케이스: 15개
- 성공: 14개
- 실패: 1개
- 성공률: 93.3%

## 상세 결과
### 시나리오 1: Heartbeat 타임아웃
- 상태: ✅ 성공
- 소요 시간: 5분 30초
- 블록 감지 시간: 5분 2초

### 시나리오 2: WebSocket 연결 끊김
- 상태: ✅ 성공
- 소요 시간: 2분 15초
- 복구 시간: 1분 45초

## 발견된 이슈
1. 시나리오 3에서 프로세스 강제 종료 시 10% 확률로 복구 실패
2. 네트워크 장애 시 재연결 시도 횟수 제한 필요

## 개선 사항
1. 프로세스 종료 감지 로직 강화
2. 재연결 시도 횟수 제한 설정
3. 로깅 레벨 조정

## 결론
전반적으로 복구 시스템이 안정적으로 동작하며, 실제 운영 환경 적용 가능
```

## 7. 다음 단계

### 7.1 테스트 실행
- 위 계획에 따라 단계별 테스트 실행
- 결과 문서화 및 이슈 트래킹

### 7.2 개선 사항 적용
- 발견된 이슈 수정
- 성능 최적화

### 7.3 운영 환경 적용
- 프로덕션 환경 배포
- 모니터링 시스템 구축

---

**테스트 계획서 버전**: 1.0  
**작성일**: 2024-08-04  
**작성자**: AI Assistant  
**검토자**: Development Team 