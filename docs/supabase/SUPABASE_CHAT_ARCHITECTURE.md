# 🌐 Supabase 중심 채팅 시스템 아키텍처

## 🎯 설계 목표

System Gateway Agent의 채팅 기능을 완전히 Supabase로 이관하여:
- **순수 Agent 클러스터**: 작업 처리만 담당
- **Supabase 채팅 서버**: Edge Function + Realtime 기반
- **확장성**: 서버리스 자동 스케일링
- **성능**: UNLOGGED 테이블 + CDN 최적화

## 🏗️ 아키텍처 구성 요소

### 1. Supabase Edge Function (채팅 API 서버)

#### `supabase/functions/chat-gateway/index.ts`
```typescript
// 통합 채팅 API Gateway
interface ChatAPI {
  // 인증 관리
  POST /auth/login
  POST /auth/register
  POST /auth/refresh
  
  // 채팅 세션 관리
  POST /chat/session          // 세션 생성
  GET  /chat/sessions         // 사용자 세션 목록
  
  // 메시지 처리
  POST /chat/message          // 메시지 전송
  GET  /chat/history/:id      // 채팅 히스토리
  
  // AI 응답
  POST /chat/ai-greeting      // 다국어 인사말
  POST /chat/ai-response      // AI 응답 생성
  
  // Agent 작업 연계
  POST /chat/agent-task       // Agent 작업 요청
  GET  /chat/agent-status     // Agent 상태 조회
  
  // 관리 기능
  POST /chat/archive          // 메시지 아카이빙
  GET  /chat/analytics        // 채팅 분석
}
```

#### 구현 구조
```typescript
// Edge Function 메인 구조
export default async function handler(req: Request) {
  // 1. CORS 처리
  if (req.method === 'OPTIONS') return corsResponse();
  
  // 2. 경로 라우팅
  const url = new URL(req.url);
  const path = url.pathname;
  
  // 3. 인증 확인 (필요한 경우)
  const authResult = await verifyAuth(req);
  
  // 4. 기능별 처리
  switch (true) {
    case path.startsWith('/chat/message'):
      return handleChatMessage(req, authResult);
    case path.startsWith('/chat/ai-'):
      return handleAIFeatures(req, authResult);
    case path.startsWith('/chat/agent-'):
      return handleAgentIntegration(req, authResult);
    default:
      return new Response('Not Found', { status: 404 });
  }
}
```

### 2. Supabase Realtime (실시간 채널)

#### 채널 구조 설계
```typescript
// 채팅 채널 네이밍 규칙
interface RealtimeChannels {
  // 개별 채팅 세션
  chat_session_{sessionId}     // 1:1 또는 그룹 채팅
  
  // 사용자별 알림
  user_notifications_{userId}  // 개인 알림
  
  // Agent 작업 상태
  agent_tasks_{taskId}         // Agent 작업 진행상황
  
  // 시스템 브로드캐스트
  system_announcements         // 전체 공지
}
```

#### Realtime 이벤트 구조
```typescript
interface ChatRealtimeEvent {
  // 메시지 이벤트
  new_message: {
    type: 'postgres_changes';
    table: 'chat_messages_realtime';
    filter: 'session_id=eq.{sessionId}';
  };
  
  // 브로드캐스트 이벤트
  user_typing: {
    type: 'broadcast';
    event: 'typing';
    payload: { userId, sessionId, isTyping };
  };
  
  // Presence 이벤트
  user_presence: {
    type: 'presence';
    event: 'sync';
    payload: { userId, status, lastSeen };
  };
}
```

### 3. PostgreSQL 스키마 (이미 구현됨)

#### 기존 스키마 활용
```sql
-- ✅ 이미 구현된 테이블들
chat_messages_realtime    -- UNLOGGED (고성능)
chat_messages_history     -- LOGGED + PARTITIONED (안전성)
user_chat_sessions        -- 세션 관리
user_language_preferences -- 다국어 설정
ai_response_logs         -- AI 응답 추적
```

### 4. Gemini 2.5 Flash-Lite 통합

#### Edge Function 내 AI 서비스
```typescript
class GeminiChatService {
  private apiKey: string;
  private baseUrl: string = 'https://generativelanguage.googleapis.com/v1beta';
  
  async generateMultilingualResponse(
    userMessage: string,
    targetLanguage: string,
    context?: ChatContext
  ): Promise<AIResponse> {
    const prompt = this.buildPrompt(userMessage, targetLanguage, context);
    
    const response = await fetch(`${this.baseUrl}/models/gemini-2.0-flash-exp:generateContent`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 500
        }
      })
    });
    
    return this.parseResponse(response);
  }
  
  private buildPrompt(message: string, language: string, context?: ChatContext): string {
    return `You are COGO's multilingual assistant. 
    Respond in ${language} to: "${message}"
    Context: ${context?.agentCapabilities || 'General assistance'}
    Keep it helpful, concise, and professional.`;
  }
}
```

## 🚀 구축 단계별 계획

### Phase 1: Edge Function 채팅 API 구축 (1-2일)

#### 1.1 기본 Edge Function 생성
```bash
# Supabase CLI로 새 함수 생성
supabase functions new chat-gateway

# 기본 구조 설정
mkdir supabase/functions/chat-gateway/types
mkdir supabase/functions/chat-gateway/services
mkdir supabase/functions/chat-gateway/handlers
```

#### 1.2 핵심 기능 구현
- [ ] CORS 및 라우팅 시스템
- [ ] JWT 인증 통합
- [ ] 기본 채팅 API 엔드포인트
- [ ] 데이터베이스 연동

#### 1.3 AI 서비스 통합
- [ ] Gemini API 클라이언트 구현
- [ ] 다국어 프롬프트 엔진
- [ ] 응답 캐싱 메커니즘

### Phase 2: Realtime 채널 설정 (1일)

#### 2.1 채널 구조 구현
```typescript
// 클라이언트 측 Realtime 연결
const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  realtime: {
    params: { eventsPerSecond: 100 }
  }
});

// 채팅 세션 구독
const channel = supabase
  .channel(`chat_session_${sessionId}`)
  .on('postgres_changes', 
    { event: 'INSERT', schema: 'public', table: 'chat_messages_realtime' },
    handleNewMessage
  )
  .on('broadcast', { event: 'typing' }, handleTyping)
  .on('presence', { event: 'sync' }, handlePresence)
  .subscribe();
```

#### 2.2 이벤트 핸들러 구현
- [ ] 새 메시지 실시간 동기화
- [ ] 타이핑 인디케이터
- [ ] 사용자 온라인 상태
- [ ] Agent 작업 상태 업데이트

### Phase 3: Agent 통합 (1일)

#### 3.1 Agent 작업 요청 API
```typescript
// Edge Function에서 Agent로 작업 전달
async function delegateToAgent(taskRequest: AgentTaskRequest): Promise<AgentResponse> {
  const response = await fetch(`http://localhost:6001/api/agent/task`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${serviceToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(taskRequest)
  });
  
  return response.json();
}
```

#### 3.2 결과 스트리밍
- [ ] Agent 작업 진행상황 실시간 스트림
- [ ] 결과를 채팅으로 자동 전달
- [ ] 에러 처리 및 복구

### Phase 4: 클라이언트 SDK (1일)

#### 4.1 JavaScript/TypeScript SDK
```typescript
class COGOChatClient {
  private supabase: SupabaseClient;
  private chatChannel?: RealtimeChannel;
  
  constructor(config: ChatConfig) {
    this.supabase = createClient(config.supabaseUrl, config.supabaseKey);
  }
  
  async joinChatSession(sessionId: string): Promise<ChatSession> {
    // Edge Function 호출로 세션 생성/참여
    const response = await this.supabase.functions.invoke('chat-gateway', {
      body: { action: 'join_session', sessionId }
    });
    
    // Realtime 채널 구독
    this.chatChannel = this.supabase
      .channel(`chat_session_${sessionId}`)
      .subscribe();
    
    return response.data;
  }
  
  async sendMessage(content: string, options?: MessageOptions): Promise<void> {
    await this.supabase.functions.invoke('chat-gateway', {
      body: { 
        action: 'send_message', 
        sessionId: this.sessionId,
        content,
        ...options 
      }
    });
  }
  
  async requestAgentHelp(taskType: string, params: any): Promise<void> {
    await this.supabase.functions.invoke('chat-gateway', {
      body: { 
        action: 'agent_task', 
        taskType,
        params 
      }
    });
  }
}
```

#### 4.2 React/Vue 컴포넌트
- [ ] 채팅 인터페이스 컴포넌트
- [ ] AI 응답 표시 컴포넌트
- [ ] Agent 작업 상태 컴포넌트

## 🔧 기술적 구현 상세

### Edge Function 환경 변수 설정
```toml
# supabase/config.toml
[functions.chat-gateway]
verify_jwt = false  # 자체 JWT 검증 구현
import_map = "./functions/chat-gateway/import_map.json"

[functions.chat-gateway.env]
GEMINI_API_KEY = "env.GEMINI_API_KEY"
AGENT_SERVICE_TOKEN = "env.AGENT_SERVICE_TOKEN"
CHAT_ENCRYPTION_KEY = "env.CHAT_ENCRYPTION_KEY"
```

### 성능 최적화 전략

#### 1. 메시지 배치 처리
```typescript
// 대량 메시지 배치 삽입
const batchInsertMessages = async (messages: ChatMessage[]) => {
  await supabase
    .from('chat_messages_realtime')
    .insert(messages);
    
  // Realtime으로 배치 브로드캐스트
  await channel.send({
    type: 'broadcast',
    event: 'batch_messages',
    payload: { messages, batchId: generateId() }
  });
};
```

#### 2. AI 응답 캐싱
```typescript
// Redis 대안으로 Supabase 테이블 활용
CREATE UNLOGGED TABLE ai_response_cache (
  prompt_hash VARCHAR(64) PRIMARY KEY,
  language VARCHAR(10),
  response_content TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '1 hour'
);
```

#### 3. 연결 풀링
```typescript
// Edge Function 전역 연결 재사용
let globalSupabaseClient: SupabaseClient;

export default async function handler(req: Request) {
  if (!globalSupabaseClient) {
    globalSupabaseClient = createClient(url, key, {
      db: { schema: 'public' },
      auth: { persistSession: false }
    });
  }
  // ... 로직 실행
}
```

## 📊 모니터링 및 분석

### 실시간 대시보드 메트릭
```sql
-- 채팅 활동 분석 뷰
CREATE VIEW chat_analytics AS
SELECT 
  DATE_TRUNC('hour', timestamp) as hour,
  COUNT(*) as message_count,
  COUNT(DISTINCT session_id) as active_sessions,
  COUNT(DISTINCT user_id) as active_users,
  AVG(LENGTH(content)) as avg_message_length,
  COUNT(*) FILTER (WHERE message_type = 'ai_greeting') as ai_responses
FROM chat_messages_realtime 
WHERE timestamp > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour DESC;
```

### Edge Function 성능 추적
```typescript
// 함수 실행 시간 및 비용 추적
const metrics = {
  startTime: Date.now(),
  dbQueries: 0,
  aiRequests: 0,
  errors: 0
};

// 함수 종료 시 로깅
await supabase.from('function_metrics').insert({
  function_name: 'chat-gateway',
  execution_time: Date.now() - metrics.startTime,
  db_queries: metrics.dbQueries,
  ai_requests: metrics.aiRequests,
  errors: metrics.errors,
  timestamp: new Date()
});
```

## 🚨 보안 고려사항

### 1. 메시지 암호화 (선택적)
```typescript
// 민감한 메시지 암호화
const encryptMessage = async (content: string): Promise<string> => {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(CHAT_ENCRYPTION_KEY),
    { name: 'AES-GCM' },
    false,
    ['encrypt']
  );
  
  const encrypted = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: crypto.getRandomValues(new Uint8Array(12)) },
    key,
    new TextEncoder().encode(content)
  );
  
  return btoa(String.fromCharCode(...new Uint8Array(encrypted)));
};
```

### 2. Rate Limiting
```typescript
// Edge Function 내 레이트 리미팅
const rateLimiter = new Map<string, { count: number; resetTime: number }>();

const checkRateLimit = (userId: string, limit: number = 100): boolean => {
  const now = Date.now();
  const userLimit = rateLimiter.get(userId);
  
  if (!userLimit || now > userLimit.resetTime) {
    rateLimiter.set(userId, { count: 1, resetTime: now + 60000 }); // 1분
    return true;
  }
  
  if (userLimit.count >= limit) {
    return false;
  }
  
  userLimit.count++;
  return true;
};
```

## 🎯 마이그레이션 계획

### System Gateway Agent 제거 단계
1. **Phase 1**: Edge Function으로 기능 복제
2. **Phase 2**: 클라이언트를 새 API로 전환
3. **Phase 3**: System Gateway Agent 비활성화
4. **Phase 4**: 코드 및 문서 정리

### 데이터 마이그레이션
- 기존 채팅 데이터는 그대로 유지
- 새로운 클라이언트는 Edge Function 사용
- 점진적 전환으로 무중단 서비스

## 📈 기대 효과

### 성능 향상
- **서버리스 스케일링**: 사용량에 따른 자동 확장
- **CDN 최적화**: Edge Function의 글로벌 배포
- **연결 효율성**: Realtime의 WebSocket 최적화

### 운영 단순화
- **인프라 관리 불필요**: Supabase 관리형 서비스
- **자동 백업**: PostgreSQL 자동 백업
- **모니터링**: Supabase 대시보드 활용

### 개발 효율성
- **API 표준화**: RESTful + Realtime 일관된 API
- **타입 안전성**: TypeScript 완전 지원
- **빠른 개발**: Supabase 코드 생성 도구
