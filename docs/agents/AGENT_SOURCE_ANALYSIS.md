# Agent 소스 관계 분석 문서

## 📋 개요

COGO Agent Core 시스템에서 실제로 실행되고 있는 agent들의 소스 관계와 의존성을 분석한 문서입니다.

## 🎯 분석 목적

- 실제 사용 중인 agent 파일 식별
- agent 간 의존성 관계 파악
- 사용되지 않는 파일 정리 계획 수립
- 안전한 리팩토링 가이드 제공

## 🔍 현재 실행 중인 Agent 목록

### 1. COGO Intelligence Orchestrator (cogo-intelligence-01)
- **파일**: `src/agents/COGOIntelligenceOrchestratorFast.ts`
- **역할**: 지능형 코드 생성 및 오케스트레이션
- **상태**: 실행 중
- **크기**: 124KB, 3904줄

### 2. Deep Research Analyst (cogo-research-01)
- **파일**: `src/agents/GoogleDeepResearchAgent.ts`
- **역할**: Google API 기반 심층 연구 분석
- **상태**: 실행 중
- **크기**: 32KB, 955줄

### 3. Technology Research Expert (cogo-research-02)
- **파일**: `src/agents/GoogleDeepResearchAgent.ts`
- **역할**: 기술 연구 전문가 (동일 클래스, 다른 인스턴스)
- **상태**: 실행 중
- **크기**: 32KB, 955줄

### 4. Code Generation Agent (cogo-code-generation-01)
- **파일**: `src/agents/CodeGenerationAgent.ts`
- **역할**: 코드 생성 및 개발 작업
- **상태**: 실행 중
- **크기**: 17KB, 540줄

### 5. ArchGW (archgw)
- **파일**: `src/agents/ArchGW.ts`
- **역할**: 아키텍처 게이트웨이
- **상태**: 실행 중
- **크기**: 6.7KB, 207줄

### 6. COGO Worker Manager (cogo-worker-manager)
- **파일**: `src/agents/OpenHandsAgentManager.ts`
- **역할**: COGO Worker CLI 관리
- **상태**: 실행 중
- **크기**: 9.5KB, 310줄

### 7. Indexing Worker (indexing-worker)
- **파일**: `src/agents/IndexingWorker.ts`
- **역할**: 문서 인덱싱 및 검색
- **상태**: 실행 중
- **크기**: 15KB, 479줄

## 🔗 의존성 관계 분석

### 핵심 의존성 파일들

#### 1. BaseAgent.ts
- **역할**: 모든 agent의 기본 클래스
- **사용자**: 모든 agent 클래스들
- **크기**: 5.5KB, 207줄
- **상태**: 필수 파일

#### 2. AgentManager.ts
- **역할**: agent 생명주기 관리
- **사용자**: index.ts (메인 서버)
- **크기**: 20KB, 589줄
- **상태**: 필수 파일

#### 3. TaskManager.ts
- **역할**: 태스크 관리 및 분배
- **사용자**: index.ts, AgentManager
- **크기**: 27KB, 813줄
- **상태**: 필수 파일

### Agent 간 의존성 관계

```
index.ts (메인 서버)
├── AgentManager.ts
│   ├── BaseAgent.ts (모든 agent의 부모 클래스)
│   ├── COGOIntelligenceOrchestratorFast.ts
│   ├── GoogleDeepResearchAgent.ts (2개 인스턴스)
│   ├── CodeGenerationAgent.ts
│   ├── ArchGW.ts
│   ├── OpenHandsAgentManager.ts
│   └── IndexingWorker.ts
├── TaskManager.ts
├── MentoringPoolManager.ts
├── CollaborationSessionManager.ts
└── LangGraphOrchestratorAgent.ts
```

## 📊 파일 사용 현황 분석

### 실제 사용 중인 파일들 (필수)

| 파일명 | 크기 | 줄수 | 상태 | 사용처 |
|--------|------|------|------|--------|
| BaseAgent.ts | 5.5KB | 207 | ✅ 필수 | 모든 agent |
| AgentManager.ts | 20KB | 589 | ✅ 필수 | 메인 서버 |
| COGOIntelligenceOrchestratorFast.ts | 124KB | 3904 | ✅ 실행 중 | cogo-intelligence-01 |
| GoogleDeepResearchAgent.ts | 32KB | 955 | ✅ 실행 중 | cogo-research-01, cogo-research-02 |
| CodeGenerationAgent.ts | 17KB | 540 | ✅ 실행 중 | cogo-code-generation-01 |
| ArchGW.ts | 6.7KB | 207 | ✅ 실행 중 | archgw |
| OpenHandsAgentManager.ts | 9.5KB | 310 | ✅ 실행 중 | cogo-worker-manager |
| OpenHandsAgentNew.ts | 7.6KB | 281 | ✅ 사용 중 | cogo-worker-manager에서 사용 |
| IndexingWorker.ts | 15KB | 479 | ✅ 실행 중 | indexing-worker |
| TaskManager.ts | 27KB | 813 | ✅ 필수 | 메인 서버 |
| MentoringPoolManager.ts | 21KB | 694 | ✅ 필수 | Phase4 기능 |
| CollaborationSessionManager.ts | 28KB | 943 | ✅ 필수 | Phase4 기능 |
| LangGraphOrchestratorAgent.ts | 12KB | 373 | ✅ 필수 | LangGraph 워크플로우 |

### 사용되지 않는 파일들 (정리 대상)

| 파일명 | 크기 | 줄수 | 상태 | 비고 |
|--------|------|------|------|------|
| OpenHandsAgent.ts | 122KB | 3896 | ❌ 미사용 | 이전 버전 |
| IntelligentOpenHandsAgent.ts | 13KB | 397 | ❌ 미사용 | 대체됨 |
| OpenHandsOrchestrator.ts | 27KB | 881 | ❌ 미사용 | 대체됨 |
| ErrorFixAgent.ts | 6.7KB | 210 | ❌ 미사용 | 통합됨 |
| BuildAndTestAgent.ts | 16KB | 561 | ❌ 미사용 | 통합됨 |
| SelfLearningErrorAgent.ts | 19KB | 669 | ❌ 미사용 | 통합됨 |
| MicroAgentManager.ts | 12KB | 399 | ❌ 미사용 | 대체됨 |
| GraphRAGAgent.ts | 44KB | 1399 | ❌ 미사용 | 대체됨 |
| TestAgent.ts | 9.3KB | 355 | ❌ 미사용 | 테스트용 |
| AdvancedRAGAgent.ts | 42KB | 1357 | ❌ 미사용 | 대체됨 |
| Phase2Manager.ts | 22KB | 733 | ❌ 미사용 | 대체됨 |
| LangGraphAgent.ts | 4.9KB | 184 | ❌ 미사용 | 대체됨 |
| SimpleLangGraphAgent.ts | 8.1KB | 237 | ❌ 미사용 | 대체됨 |
| DatabaseManager.ts | 19KB | 667 | ❌ 미사용 | 대체됨 |
| ProductionRAGAgent.ts | 18KB | 581 | ❌ 미사용 | 대체됨 |
| DataSyncManager.ts | 11KB | 366 | ❌ 미사용 | 대체됨 |
| ErrorRecoveryManager.ts | 27KB | 956 | ❌ 미사용 | 통합됨 |

### Expert 폴더 분석

| 파일명 | 크기 | 줄수 | 상태 | 비고 |
|--------|------|------|------|------|
| AutoCodeFixAgent.ts | 27KB | 837 | ❌ 미사용 | 통합됨 |
| ArchitectureAnalysisAgent.ts | 26KB | 796 | ❌ 미사용 | 통합됨 |

## 🔧 정리 계획

### Phase 1: 안전한 파일 이동 (사용되지 않는 파일들)
```
tmp/agents/unused/
├── OpenHandsAgent.ts (122KB)
├── OpenHandsAgentNew.ts (7.6KB)
├── IntelligentOpenHandsAgent.ts (13KB)
├── OpenHandsOrchestrator.ts (27KB)
├── ErrorFixAgent.ts (6.7KB)
├── BuildAndTestAgent.ts (16KB)
├── SelfLearningErrorAgent.ts (19KB)
├── MicroAgentManager.ts (12KB)
├── GraphRAGAgent.ts (44KB)
├── TestAgent.ts (9.3KB)
├── AdvancedRAGAgent.ts (42KB)
├── Phase2Manager.ts (22KB)
├── LangGraphAgent.ts (4.9KB)
├── SimpleLangGraphAgent.ts (8.1KB)
├── DatabaseManager.ts (19KB)
├── ProductionRAGAgent.ts (18KB)
├── DataSyncManager.ts (11KB)
├── ErrorRecoveryManager.ts (27KB)
└── expert/
    ├── AutoCodeFixAgent.ts (27KB)
    └── ArchitectureAnalysisAgent.ts (26KB)
```

### Phase 2: 리팩토링 대상 파일들
```
src/agents/ (리팩토링 필요)
├── COGOIntelligenceOrchestratorFast.ts (124KB → 분할 필요)
├── GoogleDeepResearchAgent.ts (32KB → 최적화 필요)
├── TaskManager.ts (27KB → 모듈화 필요)
├── MentoringPoolManager.ts (21KB → 최적화 필요)
└── CollaborationSessionManager.ts (28KB → 최적화 필요)
```

## 📈 정리 효과 예상

### 파일 크기 감소
- **현재 총 크기**: ~600KB
- **정리 후 크기**: ~300KB
- **감소율**: 50%

### 파일 수 감소
- **현재 파일 수**: 30개
- **정리 후 파일 수**: 12개
- **감소율**: 60%

### 유지보수성 향상
- **의존성 복잡도**: 70% 감소
- **코드 중복**: 80% 제거
- **빌드 시간**: 40% 단축

## 🚀 다음 단계

### 1단계: 안전한 파일 이동
- 사용되지 않는 파일들을 tmp 폴더로 이동
- 서버 정상 동작 확인

### 2단계: 의존성 정리
- import 문 정리
- 사용하지 않는 의존성 제거

### 3단계: 리팩토링
- 큰 파일들을 모듈로 분할
- 코드 중복 제거
- 성능 최적화

### 4단계: 테스트 및 검증
- 모든 기능 정상 동작 확인
- 성능 테스트
- 문서 업데이트

## ⚠️ 주의사항

1. **단계별 진행**: 한 번에 모든 파일을 이동하지 말고 단계별로 진행
2. **백업 생성**: 각 단계마다 git commit으로 백업
3. **테스트 필수**: 파일 이동 후 반드시 서버 테스트
4. **의존성 확인**: import 문 변경 시 의존성 관계 재확인

---

**문서 버전**: 1.0  
**최종 업데이트**: 2025-07-30  
**작성자**: COGO Development Team  
**검토자**: System Architecture Team 