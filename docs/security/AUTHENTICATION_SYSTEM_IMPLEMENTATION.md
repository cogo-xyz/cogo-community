# COGO Agent Core - 인증 시스템 구현

## 📋 개요

cogo-auth-gateway가 Supabase를 이용한 사용자 인증 및 JWT 토큰 발급을 처리하는 인증 게이트웨이로 확장되었습니다. 현재는 Mock 모드로 구현되어 실제 Supabase 연결 없이도 작동합니다.

## 🏗️ 아키텍처

### 인증 플로우
```
UI Client → auth.requests → cogo-auth-gateway → auth.response → UI Client
                ↓
        cogo-system-gateway (인증된 메시지만)
```

### 채널 구조
- **auth.requests**: 인증 요청 수신
- **auth.response**: 인증 응답 전송
- **ui.conversation**: 인증된 사용자 메시지 처리

## 🔧 구현된 기능

### 1. 사용자 인증
- **로그인**: `signInWithPassword`
- **회원가입**: `signUp`
- **로그아웃**: `signOut`
- **토큰 갱신**: `refreshSession`
- **토큰 검증**: `getUser`

### 2. 세션 관리
- 활성 세션 추적
- 토큰 블랙리스트 관리
- 만료된 세션 정리 (24시간)

### 3. Mock 데이터
```javascript
// 테스트용 사용자
email: 'test@example.com'
password: 'password123'
```

## 📡 메시지 형식

### 인증 요청 (AuthRequest)
```typescript
interface AuthRequest {
  type: 'login' | 'register' | 'logout' | 'refresh' | 'verify';
  email?: string;
  password?: string;
  token?: string;
  refreshToken?: string;
  sessionId?: string;
  metadata?: any;
}
```

### 인증 응답 (AuthResponse)
```typescript
interface AuthResponse {
  success: boolean;
  message: string;
  data?: {
    user?: any;
    session?: any;
    token?: string;
    refreshToken?: string;
  };
  error?: string;
  timestamp: string;
}
```

## 🧪 테스트 시나리오

### 1. 성공적인 로그인
```json
{
  "type": "auth.requests",
  "payload": {
    "type": "login",
    "email": "test@example.com",
    "password": "password123"
  }
}
```

### 2. 회원가입
```json
{
  "type": "auth.requests",
  "payload": {
    "type": "register",
    "email": "newuser@example.com",
    "password": "newpassword123"
  }
}
```

### 3. 토큰 검증
```json
{
  "type": "auth.requests",
  "payload": {
    "type": "verify",
    "token": "mock-access-token-123"
  }
}
```

## 🔄 실제 Supabase 연동 준비

### 1. 환경 변수 설정
```bash
ENABLE_SUPABASE=true
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 2. 코드 변경
Mock 클라이언트를 실제 Supabase 클라이언트로 교체:
```typescript
// 현재: Mock 클라이언트
const mockSupabase = { auth: new MockSupabaseAuth() };

// 변경: 실제 Supabase 클라이언트
import { createClient } from '@supabase/supabase-js';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```

## 📊 현재 상태

### ✅ 완료된 작업
- [x] Mock 인증 시스템 구현
- [x] 인증 요청/응답 처리
- [x] 세션 관리
- [x] 토큰 검증
- [x] 컴파일 오류 해결
- [x] 서버 정상 구동 확인

### 🔄 다음 단계
- [ ] 실제 Supabase 연동
- [ ] 인증 미들웨어 구현
- [ ] 권한 기반 접근 제어
- [ ] 보안 강화 (rate limiting, etc.)

## 🚀 사용법

### 서버 시작
```bash
npm start
```

### 인증 게이트웨이 상태 확인
```bash
curl http://localhost:3000/api/agents | jq '.[] | select(.id == "cogo-auth-gateway")'
```

### 테스트 실행
```bash
node test-auth-mock.js
```

## 🔒 보안 고려사항

1. **토큰 관리**: JWT 토큰의 안전한 저장 및 전송
2. **세션 관리**: 활성 세션 추적 및 만료 처리
3. **블랙리스트**: 로그아웃된 토큰의 즉시 무효화
4. **입력 검증**: 이메일 및 비밀번호 형식 검증

## 📝 참고사항

- 현재 Mock 모드로 작동하여 실제 데이터베이스 연결이 필요하지 않음
- 테스트용 사용자: `test@example.com` / `password123`
- 모든 인증 관련 로그는 콘솔에 출력됨
- 실제 운영 환경에서는 Supabase 연동이 필요함 