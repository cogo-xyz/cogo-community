# 🌍 다국어 실시간 채팅 시스템

## 📋 프로젝트 개요

COGO Agent Core의 다국어 실시간 채팅 시스템은 UNLOGGED 테이블을 활용한 고성능 메시징과 Gemini 2.5 Flash-Lite 기반 AI 응답을 제공합니다.

## 🏗️ 아키텍처 설계

### 역할 분리 구조

```
🌐 System-Gateway Agent (포트 6005)
├── 💬 사용자 채팅 인터페이스
├── 🌍 다국어 인사말 (Gemini 2.5 Flash-Lite)
├── 🔐 인증 관리
└── 📞 Orchestrator로 작업 전달

🎯 Orchestrator Agent (포트 6001)
├── 📋 작업 스케줄링 및 조율
├── 🔀 다른 Agent들로 작업 분배
├── 📊 전체 시스템 관리
└── ⚖️ 로드 밸런싱

📚 작업 전용 Agent들
├── Indexing Agent (6002) - 인덱싱 작업
├── Research Agent (6003) - 연구 작업
└── GraphRAG Agent (6004) - 그래프 작업
```

### Edge Function vs Real-time 역할 분리

- **Edge Function**: 인증 전용 (JWT + RBAC)
- **Supabase Real-time**: 채팅 전용 (메시지 동기화)

## 📊 데이터베이스 설계

### 하이브리드 테이블 구조 (성능 + 안전성)

#### 1. 실시간 채팅 테이블 (UNLOGGED - 고성능)
```sql
CREATE UNLOGGED TABLE chat_messages_realtime (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    message_type VARCHAR(50) DEFAULT 'user_message',
    content TEXT NOT NULL,
    original_language VARCHAR(10) DEFAULT 'en',
    detected_language VARCHAR(10),
    translated_content JSONB DEFAULT '{}',
    ai_metadata JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE
) WITH (
    autovacuum_enabled = false,  -- 성능 최적화
    fillfactor = 90              -- INSERT 성능 최적화
);
```

#### 2. 영구 보관 테이블 (LOGGED + PARTITIONED - 안전성)
```sql
CREATE TABLE chat_messages_history (
    -- 동일 구조 + archived_at 필드
) PARTITION BY RANGE (timestamp);

-- 월별 파티션
CREATE TABLE chat_messages_history_2025_01 PARTITION OF chat_messages_history
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

### 성능 최적화 전략

1. **UNLOGGED 테이블 장점**:
   - 🚀 35-75% 빠른 INSERT 성능 (WAL 없음)
   - 💾 적은 디스크 사용량
   - ⚡ 100K+ 메시지/초 처리 가능

2. **자동 아카이빙**:
   - 24시간 후 실시간 → 히스토리 이동
   - `TRUNCATE` 기반 고속 정리
   - 월별 파티션으로 관리

## 🤖 AI 통합

### Gemini 2.5 Flash-Lite 통합

```typescript
// AI 응답 생성 함수
async function generateAIGreeting(
    sessionId: string,
    userMessage: string,
    targetLanguage: string = 'en'
): Promise<AIGreetingResponse>
```

### 지원 언어 (13개)
- 한국어 (ko), English (en), 日本語 (ja)
- 中文 (zh), Español (es), Français (fr)
- Deutsch (de), Português (pt), Русский (ru)
- العربية (ar), Italiano (it), ไทย (th), Tiếng Việt (vi)

## 🔧 주요 컴포넌트

### 1. MultilingualRealtimeChatService
- Supabase Real-time 통합
- 다국어 AI 응답
- 고성능 메시징
- 자동 아카이빙

### 2. 채팅 API 라우트 (`/api/chat/`)
- `/session` - 채팅 세션 생성
- `/message` - 메시지 전송
- `/ai-greeting` - AI 인사말 생성
- `/history/:sessionId` - 채팅 히스토리
- `/languages` - 지원 언어 목록
- `/status` - 서비스 상태

### 3. 데이터베이스 함수들
- `get_or_create_chat_session()` - 세션 관리
- `generate_ai_greeting_response()` - AI 응답 생성
- `archive_old_chat_messages()` - 메시지 아카이빙
- `fast_cleanup_realtime_chat()` - 고속 정리

## 📈 성능 메트릭

- **목표**: 100K+ 메시지/초
- **응답 시간**: 평균 < 50ms
- **다국어 처리**: < 100ms
- **아카이빙**: 자동 (24시간 주기)

## 🔒 보안

- JWT 기반 인증
- RBAC 권한 관리
- Row Level Security (RLS)
- 사용자별 데이터 격리

## 📝 구현 상태

### ✅ 완료
- [x] 하이브리드 테이블 설계
- [x] 다국어 스키마 구현
- [x] MultilingualRealtimeChatService
- [x] 채팅 API 라우트
- [x] AI 응답 시뮬레이션
- [x] 자동 아카이빙 함수

### 🔄 진행 중
- [ ] System-Gateway Agent 분산 구조 업데이트
- [ ] `real-distributed-server.js` 채팅 라우트 통합
- [ ] 실제 Gemini 2.5 Flash-Lite API 연동

### ⏳ 예정
- [ ] 성능 최적화 테스트
- [ ] 프로덕션 배포
- [ ] 모니터링 대시보드

## 🧪 테스트

```bash
# 채팅 시스템 테스트
node test-multilingual-chat-system.js

# 분산 Agent 채팅 통합 테스트
node test-distributed-agent-chat.js
```

## 📚 참고 자료

- [PostgreSQL UNLOGGED Tables](https://www.postgresql.org/docs/current/sql-createtable.html)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)
- [Gemini API Documentation](https://ai.google.dev/docs)
