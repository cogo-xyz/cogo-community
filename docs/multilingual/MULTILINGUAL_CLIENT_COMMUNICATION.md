# Multilingual Client Communication Architecture

## Table of Contents
1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Communication Flow](#communication-flow)
4. [Message Structure](#message-structure)
5. [Language Handling](#language-handling)
6. [Implementation Guide](#implementation-guide)
7. [API Reference](#api-reference)
8. [Testing Strategy](#testing-strategy)

## Overview

The COGO Agent Core implements a sophisticated multilingual communication system that supports client interactions in multiple languages while maintaining English as the internal processing language for all agents and knowledge systems.

### Key Features
- **Multilingual Client Support**: Clients can communicate in their preferred language
- **Automatic Language Detection**: System detects client message language automatically
- **English Internal Processing**: All internal operations use English for consistency
- **Smart Translation**: Translation handled by cogo-system-gateway using Gemini 1.5 Flash
- **Session Management**: Language preferences stored per client session

## Design Principles

### 1. Client Language Priority
- Client's preferred language is respected for all interactions
- Welcome messages sent in client's language
- Error messages and notifications in client's language

### 2. English Internal Standard
- All internal agent communication in English
- Knowledge Graph (Neo4j) documents in English
- Code comments and documentation in English
- System logs and metadata in English

### 3. Translation Separation
- Translation only occurs in cogo-system-gateway
- cogo-orchestrator-agent never handles translation
- Gemini 1.5 Flash handles all translation tasks

### 4. Language Persistence
- Client language preference stored in session
- Language maintained across conversation turns
- Fallback to English if language detection fails

## Communication Flow

```
┌─────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Client    │    │ cogo-system-gateway │    │ cogo-orchestrator-  │
│ (Multilingual)│    │  (Gemini 1.5 Flash) │    │     agent          │
│             │    │                     │    │    (English)        │
└─────────────┘    └─────────────────────┘    └─────────────────────┘
       │                       │                       │
       │ 1. Connect            │                       │
       ├──────────────────────►│                       │
       │                       │                       │
       │ 2. Welcome Message    │                       │
       │◄──────────────────────┤                       │
       │ (Client Language)     │                       │
       │                       │                       │
       │ 3. User Message       │                       │
       ├──────────────────────►│                       │
       │ (Any Language)        │                       │
       │                       │ 4. Intent Analysis    │
       │                       ├──────────────────────►│
       │                       │ (English)             │
       │                       │                       │
       │                       │ 5. Task Request       │
       │                       ├──────────────────────►│
       │                       │ (English)             │
       │                       │                       │
       │                       │ 6. Task Response      │
       │                       │◄──────────────────────┤
       │                       │ (English)             │
       │                       │                       │
       │ 7. Response/Translation│                       │
       │◄──────────────────────┤                       │
       │ (Client Language)     │                       │
       │                       │                       │
```

## Message Structure

### Client Message Format
```typescript
interface ClientMessage {
  sessionId: string;
  userId?: string;
  message: string;
  language?: string;           // ISO 639-1 code (e.g., 'ko', 'en', 'ja')
  timestamp: string;
  metadata?: {
    clientType?: string;       // 'web', 'mobile', 'api'
    userAgent?: string;
    preferences?: {
      autoTranslate?: boolean; // Whether to auto-translate responses
      targetLanguage?: string; // Preferred response language
    };
  };
}
```

### System Gateway Response Format
```typescript
interface SystemGatewayResponse {
  sessionId: string;
  messageId: string;
  type: 'welcome' | 'conversation' | 'task_request' | 'error' | 'translation';
  content: {
    original?: string;         // Original English response
    translated?: string;       // Translated content
    language: string;          // Response language
  };
  intent?: {
    type: 'conversation' | 'task_request' | 'clarification_needed';
    confidence: number;
    detectedLanguage: string;
  };
  timestamp: string;
  metadata?: {
    translationRequired?: boolean;
    sourceLanguage?: string;
    targetLanguage?: string;
  };
}
```

### Orchestrator Communication Format
```typescript
interface OrchestratorMessage {
  sessionId: string;
  taskId: string;
  type: 'task_request' | 'task_update' | 'task_completion';
  content: {
    request: string;           // Always in English
    context?: any;
    requirements?: any;
  };
  language: 'en';              // Always English
  timestamp: string;
}
```

## Language Handling

### Supported Languages
```typescript
const SUPPORTED_LANGUAGES = {
  'ko': 'Korean',
  'en': 'English',
  'ja': 'Japanese',
  'zh': 'Chinese',
  'es': 'Spanish',
  'fr': 'French',
  'de': 'German',
  'pt': 'Portuguese',
  'ru': 'Russian',
  'ar': 'Arabic'
} as const;

type SupportedLanguage = keyof typeof SUPPORTED_LANGUAGES;
```

### Language Detection Strategy
1. **Explicit Language**: Client specifies language in message
2. **Session Language**: Use language from previous session
3. **Auto Detection**: Gemini 1.5 Flash detects message language
4. **Fallback**: Default to English if detection fails

### Translation Strategy
```typescript
interface TranslationConfig {
  sourceLanguage: string;
  targetLanguage: string;
  preserveFormatting: boolean;
  context?: string;
  style?: 'formal' | 'casual' | 'technical';
}
```

## Implementation Guide

### 1. Client Connection Flow
```typescript
// 1. Client connects with language preference
const clientMessage: ClientMessage = {
  sessionId: 'session-123',
  language: 'ko',
  message: '안녕하세요',
  timestamp: new Date().toISOString()
};

// 2. System gateway detects language and sends welcome
const welcomeResponse: SystemGatewayResponse = {
  sessionId: 'session-123',
  type: 'welcome',
  content: {
    translated: '안녕하세요! COGO Agent Core에 오신 것을 환영합니다.',
    language: 'ko'
  },
  intent: {
    type: 'conversation',
    confidence: 0.95,
    detectedLanguage: 'ko'
  }
};
```

### 2. Task Request Flow
```typescript
// 1. Client sends task request in Korean
const taskRequest: ClientMessage = {
  sessionId: 'session-123',
  language: 'ko',
  message: 'React 앱을 만들어주세요',
  timestamp: new Date().toISOString()
};

// 2. System gateway translates to English for orchestrator
const orchestratorRequest: OrchestratorMessage = {
  sessionId: 'session-123',
  taskId: 'task-456',
  type: 'task_request',
  content: {
    request: 'Create a React application',
    context: { framework: 'react', language: 'typescript' }
  },
  language: 'en',
  timestamp: new Date().toISOString()
};

// 3. Orchestrator responds in English
const orchestratorResponse = {
  taskId: 'task-456',
  content: 'I will create a React application for you. Let me start by analyzing your requirements...',
  language: 'en'
};

// 4. System gateway translates response to Korean
const clientResponse: SystemGatewayResponse = {
  sessionId: 'session-123',
  type: 'task_request',
  content: {
    original: 'I will create a React application for you...',
    translated: 'React 애플리케이션을 만들어드리겠습니다. 요구사항을 분석하여 시작하겠습니다...',
    language: 'ko'
  }
};
```

### 3. Session Management
```typescript
interface ClientSession {
  sessionId: string;
  userId?: string;
  language: string;
  createdAt: string;
  lastActivity: string;
  preferences: {
    autoTranslate: boolean;
    targetLanguage: string;
    notificationLanguage: string;
  };
  metadata: {
    clientType: string;
    userAgent: string;
    ipAddress?: string;
  };
}
```

## API Reference

### Client Connection Endpoint
```http
POST /api/central/connect
Content-Type: application/json

{
  "sessionId": "session-123",
  "language": "ko",
  "preferences": {
    "autoTranslate": true,
    "targetLanguage": "ko"
  }
}
```

### Message Endpoint
```http
POST /api/central/message
Content-Type: application/json

{
  "sessionId": "session-123",
  "message": "React 앱을 만들어주세요",
  "language": "ko"
}
```

### Session Management Endpoint
```http
GET /api/central/session/{sessionId}
```

## Testing Strategy

### 1. Language Detection Tests
- Test automatic language detection for various languages
- Verify fallback to English for unsupported languages
- Test mixed language messages

### 2. Translation Tests
- Test translation accuracy for technical terms
- Verify context preservation during translation
- Test translation performance and latency

### 3. Session Persistence Tests
- Test language preference persistence across sessions
- Verify session cleanup and timeout handling
- Test concurrent sessions with different languages

### 4. Integration Tests
- Test end-to-end multilingual communication flow
- Verify orchestrator receives English messages only
- Test error handling in multilingual context

### 5. Performance Tests
- Test translation latency under load
- Verify memory usage with multiple language sessions
- Test concurrent translation requests

## Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] Update ClientMessage interface with language support
- [ ] Implement language detection in cogo-system-gateway
- [ ] Add translation service using Gemini 1.5 Flash
- [ ] Update session management with language preferences

### Phase 2: Communication Flow
- [ ] Implement multilingual welcome message system
- [ ] Add translation layer in cogo-system-gateway
- [ ] Update orchestrator communication to English-only
- [ ] Implement response translation system

### Phase 3: Testing & Validation
- [ ] Create comprehensive test suite for multilingual features
- [ ] Test with multiple languages and scenarios
- [ ] Performance testing and optimization
- [ ] Documentation and API reference updates

### Phase 4: Production Deployment
- [ ] Monitor translation accuracy and performance
- [ ] Implement language-specific error handling
- [ ] Add language analytics and reporting
- [ ] User feedback collection and improvement

## Conclusion

This multilingual architecture ensures that COGO Agent Core can serve clients worldwide while maintaining the integrity and consistency of internal processing. The separation of concerns between client communication and internal processing allows for scalable, maintainable, and user-friendly multilingual support. 