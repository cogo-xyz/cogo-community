# Sandbox Worker Integration Test Scenarios

## 📋 테스트 개요

이 문서는 COGO Agent Core의 Sandbox Worker 통합 기능을 검증하기 위한 포괄적인 테스트 시나리오를 정의합니다.

### 🎯 테스트 목표
- TypeScript Sandbox Manager와 Python Sandbox Worker 간의 WebSocket 통신 검증
- 실시간 프로세스 실행 및 모니터링 기능 검증
- Block 감지 및 복구 메커니즘 검증
- 다양한 작업 유형별 실행 성능 검증
- 에러 처리 및 복구 전략 검증

---

## 🧪 테스트 시나리오

### 시나리오 1: 기본 연결 및 통신 테스트

#### 1.1 WebSocket 연결 테스트
**목적**: Sandbox Manager와 Worker 간의 기본 연결 확인

**테스트 단계**:
1. Python Sandbox Worker 서버 시작
2. TypeScript Sandbox Manager에서 Worker 생성
3. WebSocket 연결 상태 확인
4. Heartbeat 메시지 교환 확인

**예상 결과**:
- WebSocket 연결 성공
- Heartbeat 메시지 정상 교환
- 연결 상태 모니터링 정상

**API 테스트**:
```bash
# Worker 생성
curl -X POST http://localhost:3000/api/executor/sandbox/worker \
  -H "Content-Type: application/json" \
  -d '{"type": "basic"}'

# 연결 상태 확인
curl http://localhost:3000/api/executor/sandbox/health
```

#### 1.2 다중 Worker 관리 테스트
**목적**: 여러 Worker의 동시 관리 및 부하 분산 확인

**테스트 단계**:
1. 3개의 기본 Worker 생성
2. Worker 풀 상태 확인
3. Worker 간 작업 분배 확인
4. Worker 제거 및 재생성 테스트

**예상 결과**:
- 다중 Worker 정상 생성
- 작업 부하 분산 정상
- Worker 풀 관리 정상

---

### 시나리오 2: 기본 작업 실행 테스트

#### 2.1 간단한 명령어 실행
**목적**: 기본적인 명령어 실행 기능 검증

**테스트 단계**:
1. `echo "Hello World"` 명령어 실행
2. `ls -la` 명령어 실행
3. `pwd` 명령어 실행
4. 출력 결과 확인

**예상 결과**:
- 명령어 정상 실행
- stdout/stderr 정상 수신
- 실행 시간 측정 정상

**API 테스트**:
```bash
# 간단한 명령어 실행
curl -X POST http://localhost:3000/api/executor/task \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Execute echo command",
    "type": "sandbox-execution",
    "command": "echo \"Hello World\"",
    "requirements": {"type": "basic"}
  }'
```

#### 2.2 긴 실행 시간 작업
**목적**: 장시간 실행되는 작업의 모니터링 검증

**테스트 단계**:
1. `sleep 30` 명령어 실행
2. 실시간 진행 상황 모니터링
3. 작업 완료 확인
4. 리소스 사용량 확인

**예상 결과**:
- 장시간 작업 정상 실행
- 실시간 모니터링 정상
- 리소스 사용량 추적 정상

---

### 시나리오 3: 컴파일 및 빌드 테스트

#### 3.1 Node.js 프로젝트 컴파일
**목적**: TypeScript/JavaScript 프로젝트 컴파일 검증

**테스트 단계**:
1. 간단한 TypeScript 파일 생성
2. `npm install` 실행
3. `npm run build` 실행
4. 컴파일 결과 확인

**테스트 코드**:
```typescript
// test.ts
function greet(name: string): string {
  return `Hello, ${name}!`;
}

console.log(greet("World"));
```

**예상 결과**:
- TypeScript 컴파일 성공
- 빌드 프로세스 정상
- 오류 메시지 정확한 전달

#### 3.2 Python 프로젝트 실행
**목적**: Python 프로젝트 실행 및 패키지 관리 검증

**테스트 단계**:
1. Python 가상환경 생성
2. `pip install` 실행
3. Python 스크립트 실행
4. 의존성 관리 확인

**테스트 코드**:
```python
# test.py
import requests

def fetch_data():
    response = requests.get('https://api.github.com/users/octocat')
    return response.json()

if __name__ == "__main__":
    data = fetch_data()
    print(f"User: {data['login']}")
```

**예상 결과**:
- Python 환경 설정 정상
- 패키지 설치 성공
- 스크립트 실행 정상

---

### 시나리오 4: Block 감지 및 복구 테스트

#### 4.1 무한 루프 감지
**목적**: 무한 루프 상황에서의 Block 감지 검증

**테스트 단계**:
1. 무한 루프 스크립트 실행
2. Block 감지 메커니즘 작동 확인
3. 자동 복구 프로세스 확인
4. Worker 상태 복구 확인

**테스트 코드**:
```python
# infinite_loop.py
while True:
    pass
```

**예상 결과**:
- 무한 루프 감지 성공
- 자동 프로세스 종료
- Worker 상태 정상 복구

#### 4.2 메모리 부족 상황 감지
**목적**: 메모리 부족 상황에서의 Block 감지 검증

**테스트 단계**:
1. 메모리를 과도하게 사용하는 스크립트 실행
2. 메모리 사용량 모니터링
3. 임계값 초과 시 Block 감지
4. 메모리 해제 및 복구

**테스트 코드**:
```python
# memory_test.py
import array

# 1GB 메모리 할당 시도
data = array.array('B', [0] * (1024 * 1024 * 1024))
```

**예상 결과**:
- 메모리 사용량 모니터링 정상
- 임계값 초과 감지
- 자동 복구 프로세스 작동

#### 4.3 CPU 과부하 감지
**목적**: CPU 과부하 상황에서의 Block 감지 검증

**테스트 단계**:
1. CPU 집약적 작업 실행
2. CPU 사용량 모니터링
3. 임계값 초과 시 Block 감지
4. CPU 사용량 정상화 확인

**테스트 코드**:
```python
# cpu_test.py
import multiprocessing

def cpu_intensive():
    for i in range(10000000):
        _ = i * i

if __name__ == "__main__":
    processes = []
    for _ in range(multiprocessing.cpu_count()):
        p = multiprocessing.Process(target=cpu_intensive)
        p.start()
        processes.append(p)
    
    for p in processes:
        p.join()
```

**예상 결과**:
- CPU 사용량 모니터링 정상
- 임계값 초과 감지
- 자동 복구 프로세스 작동

---

### 시나리오 5: 실시간 통신 테스트

#### 5.1 실시간 출력 스트리밍
**목적**: 실시간 stdout/stderr 스트리밍 검증

**테스트 단계**:
1. 지속적으로 출력하는 스크립트 실행
2. WebSocket을 통한 실시간 출력 수신
3. 출력 지연 시간 측정
4. 출력 정확성 확인

**테스트 코드**:
```python
# streaming_test.py
import time

for i in range(10):
    print(f"Output {i}: {time.time()}")
    time.sleep(1)
```

**예상 결과**:
- 실시간 출력 스트리밍 정상
- 지연 시간 < 100ms
- 출력 정확성 100%

#### 5.2 실시간 입력 전송
**목적**: 실시간 stdin 입력 전송 검증

**테스트 단계**:
1. 사용자 입력을 기다리는 스크립트 실행
2. WebSocket을 통한 입력 전송
3. 입력 처리 확인
4. 응답 정확성 확인

**테스트 코드**:
```python
# input_test.py
name = input("Enter your name: ")
print(f"Hello, {name}!")
```

**예상 결과**:
- 실시간 입력 전송 정상
- 입력 처리 정확성 100%
- 응답 정확성 100%

---

### 시나리오 6: 에러 처리 및 복구 테스트

#### 6.1 명령어 실행 실패
**목적**: 잘못된 명령어 실행 시 에러 처리 검증

**테스트 단계**:
1. 존재하지 않는 명령어 실행
2. 에러 메시지 수신 확인
3. Worker 상태 확인
4. 다음 작업 실행 가능성 확인

**API 테스트**:
```bash
# 잘못된 명령어 실행
curl -X POST http://localhost:3000/api/executor/task \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Execute invalid command",
    "type": "sandbox-execution",
    "command": "nonexistent_command",
    "requirements": {"type": "basic"}
  }'
```

**예상 결과**:
- 에러 메시지 정확한 전달
- Worker 상태 정상 유지
- 다음 작업 실행 가능

#### 6.2 Worker 연결 끊김 복구
**목적**: Worker 연결 끊김 시 자동 복구 검증

**테스트 단계**:
1. Worker 프로세스 강제 종료
2. 연결 끊김 감지 확인
3. 자동 재연결 시도 확인
4. 새로운 Worker 생성 확인

**예상 결과**:
- 연결 끊김 감지 성공
- 자동 재연결 시도
- 새로운 Worker 생성 성공

---

### 시나리오 7: 성능 및 부하 테스트

#### 7.1 동시 작업 실행
**목적**: 다중 작업 동시 실행 성능 검증

**테스트 단계**:
1. 5개의 동시 작업 생성
2. 작업 큐 관리 확인
3. Worker 부하 분산 확인
4. 전체 실행 시간 측정

**API 테스트**:
```bash
# 동시 작업 실행
for i in {1..5}; do
  curl -X POST http://localhost:3000/api/executor/task \
    -H "Content-Type: application/json" \
    -d "{
      \"description\": \"Concurrent task $i\",
      \"type\": \"sandbox-execution\",
      \"command\": \"sleep 5 && echo 'Task $i completed'\",
      \"requirements\": {\"type\": \"basic\"}
    }" &
done
wait
```

**예상 결과**:
- 동시 작업 정상 실행
- 작업 큐 관리 정상
- 부하 분산 정상

#### 7.2 대용량 출력 처리
**목적**: 대용량 출력 데이터 처리 성능 검증

**테스트 단계**:
1. 대용량 출력 생성 스크립트 실행
2. 메모리 사용량 모니터링
3. 출력 처리 속도 측정
4. 시스템 안정성 확인

**테스트 코드**:
```python
# large_output.py
for i in range(100000):
    print(f"Line {i}: " + "x" * 100)
```

**예상 결과**:
- 대용량 출력 정상 처리
- 메모리 사용량 안정적
- 처리 속도 만족스러움

---

### 시나리오 8: 특화된 Worker 테스트

#### 8.1 Flutter Worker 테스트
**목적**: Flutter 전용 Worker 기능 검증

**테스트 단계**:
1. Flutter Worker 생성
2. Flutter 프로젝트 빌드
3. Flutter 테스트 실행
4. Flutter 특화 기능 확인

**API 테스트**:
```bash
# Flutter Worker 생성
curl -X POST http://localhost:3000/api/executor/sandbox/worker \
  -H "Content-Type: application/json" \
  -d '{"type": "flutter"}'

# Flutter 빌드 실행
curl -X POST http://localhost:3000/api/executor/task \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Flutter build",
    "type": "sandbox-execution",
    "command": "flutter build apk",
    "requirements": {"type": "flutter"}
  }'
```

**예상 결과**:
- Flutter 환경 정상 설정
- Flutter 빌드 성공
- Flutter 테스트 정상 실행

#### 8.2 Analysis Worker 테스트
**목적**: 소스 코드 분석 전용 Worker 기능 검증

**테스트 단계**:
1. Analysis Worker 생성
2. 소스 코드 복잡도 분석
3. 보안 취약점 스캔
4. 코드 품질 메트릭 계산

**API 테스트**:
```bash
# Analysis Worker 생성
curl -X POST http://localhost:3000/api/executor/sandbox/worker \
  -H "Content-Type: application/json" \
  -d '{"type": "analysis"}'

# 소스 코드 분석 실행
curl -X POST http://localhost:3000/api/executor/task \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Code analysis",
    "type": "sandbox-execution",
    "command": "python -m pylint src/",
    "requirements": {"type": "analysis"}
  }'
```

**예상 결과**:
- 소스 코드 분석 정상 실행
- 분석 결과 정확한 전달
- 품질 메트릭 정상 계산

---

## 📊 테스트 결과 검증 기준

### 성능 기준
- **응답 시간**: API 호출 응답 < 1초
- **실시간 지연**: WebSocket 메시지 < 100ms
- **Block 감지**: 5초 이내 감지
- **복구 시간**: 10초 이내 복구

### 안정성 기준
- **연결 안정성**: 99% 이상
- **작업 성공률**: 95% 이상
- **에러 복구율**: 90% 이상
- **메모리 누수**: 없음

### 기능성 기준
- **명령어 실행**: 100% 정확성
- **출력 전달**: 100% 정확성
- **Block 감지**: 100% 정확성
- **복구 메커니즘**: 100% 작동

---

## 🚀 테스트 실행 방법

### 1. 사전 준비
```bash
# Python 의존성 설치
cd cogo-worker
python3 -m pip install websockets psutil

# TypeScript 컴파일
npm run build
```

### 2. Sandbox Worker 서버 시작
```bash
# Python WebSocket 서버 시작
cd cogo-worker
python3 sandbox_websocket_server.py
```

### 3. 테스트 실행
```bash
# 각 시나리오별 테스트 실행
./run_sandbox_tests.sh
```

### 4. 결과 확인
```bash
# 테스트 결과 확인
cat test_results.json
```

---

## 📝 테스트 결과 문서화

각 테스트 시나리오 실행 후 다음 정보를 문서화합니다:

1. **테스트 실행 시간**
2. **성공/실패 여부**
3. **성능 메트릭**
4. **발견된 이슈**
5. **개선 제안사항**

이 문서는 지속적으로 업데이트되어 Sandbox Worker의 품질을 보장합니다. 