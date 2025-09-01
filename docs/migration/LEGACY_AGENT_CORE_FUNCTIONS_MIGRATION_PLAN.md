# 🔄 Legacy Agent 핵심 기능 분산 Agent 이관 계획서

## 📋 개요

현재 분산 Agent 구조가 완성되었으나, Legacy Agent들의 핵심 기능들이 누락된 상태입니다. 
본 문서는 Legacy Agent들의 핵심 기능을 분석하고 현재 분산 Agent 구조로 이관하는 상세 계획을 제시합니다.

## 🚦 진행 현황

- Phase 1: 핵심 모듈 구조 이관 — 완료
  - Advanced 기능 플래그 기본값 활성화 완료
    - USE_ORCHESTRATOR_CORE = true
    - USE_GRAPHRAG_CORE = true
    - USE_INDEXING_ADVANCED = true
    - USE_RESEARCH_ADVANCED = true
    - USE_EXECUTOR_ADVANCED = true
  - RealDistributedAgentServer에 경량 Advanced details 응답 노출
    - Orchestrator: decision, prompts, rag
    - Indexing: parsed, workflow
    - Research: summary, confidence, durationMs
    - GraphRAG: parsed, paths, communities, adaptive, correction
    - Executor: plan
- Phase 2(경량): 서비스 통합 및 워크플로우 — 완료
  - Indexing/Research/Executor 경량 구현(스켈레톤) 연동 및 기능 플래그 적용
  - RealDistributedAgentServer details 경로에서 실제 스켈레톤 호출로 검증 완료
- Phase 3(경량): 통신/상태 관리 고도화 — 완료
  - 공통 협업 스켈레톤 추가: `src/agents/common/communication/RealtimeCollaboration.ts`
  - 모든 에이전트 서버(`/`·`/health`)에 `comm` 통계 노출 (subscribers, totalEvents, lastEventAt)
  - Collab API 추가(인증/권한 포함):
    - POST `/api/agent/collab/subscribe`
    - POST `/api/agent/collab/unsubscribe`
    - POST `/api/agent/collab/broadcast`
- 검증 현황
  - 5개 에이전트 API 회귀 테스트 통과 (details 필드 포함 응답 확인)
  - 5개 에이전트 Collab API 구독/브로드캐스트/해제 및 헬스 응답 통계 확인

## 🔍 Legacy Agent 핵심 기능 분석

### 1. 🧠 Orchestrator Agent 핵심 기능

#### Legacy 위치: `backup/legacy-cleanup-20250808-133517/agents/`
- `cogo-orchestrator-agent.ts` (메인 Agent)
- `orchestrator/` 폴더 (핵심 모듈들)

#### 핵심 기능 모듈:
1. **OrchestratorModule** (`orchestrator/OrchestratorModule.ts`)
   - 통합 오케스트레이션 관리
   - 워크플로우 실행 및 모니터링
   - 메트릭스 추적 및 분석

2. **DecisionFramework** (`orchestrator/DecisionFramework.ts`)
   - AI 기반 의사결정 엔진
   - 역할 선택 및 작업 분배 로직
   - 컨텍스트 기반 추론

3. **LLMPromptEngine** (`orchestrator/LLMPromptEngine.ts`)
   - 동적 프롬프트 생성
   - 컨텍스트 인식 프롬프트 최적화
   - 다국어 프롬프트 지원

4. **BlueprintManager** (`orchestrator/BlueprintManager.ts`)
   - 코드 블루프린트 관리
   - 템플릿 기반 코드 생성
   - 학습 기반 최적화

5. **RAGSearchEngine** (`orchestrator/RAGSearchEngine.ts`)
   - 지식 검색 및 컨텍스트 수집
   - 하이브리드 검색 전략
   - 결과 품질 평가

#### 누락된 기능:
- ❌ 세션 관리 및 사용자 상호작용
- ❌ RAG 컨텍스트 수집 및 활용
- ❌ 고급 의사결정 프레임워크
- ❌ 멀티모달 프롬프트 엔진
- ❌ 실시간 메트릭스 추적

### 2. 🕸️ GraphRAG Agent 핵심 기능

#### Legacy 위치: `backup/legacy-cleanup-20250808-133517/agents/`
- `cogo-graphrag-agent.ts` (메인 Agent)
- `graphrag/` 폴더 (핵심 모듈들)
- `advancedrag/` 폴더 (고급 RAG 기능)

#### 핵심 기능 모듈:
1. **GraphQueryProcessor** (`graphrag/GraphQueryProcessor.ts`)
   - 자연어 쿼리를 구조화된 그래프 쿼리로 변환
   - 복잡한 그래프 검색 전략 결정
   - AI 기반 쿼리 분석

2. **MultiHopReasoner** (`graphrag/MultiHopReasoner.ts`)
   - 다단계 추론 엔진
   - 논리적 경로 탐색
   - 증거 기반 결론 도출

3. **CommunityAnalyzer** (`graphrag/CommunityAnalyzer.ts`)
   - 지식 그래프 커뮤니티 분석
   - 클러스터링 및 관계 분석
   - 중심성 및 영향도 계산

4. **AdaptiveRAGProcessor** (`advancedrag/AdaptiveRAGProcessor.ts`)
   - 적응형 RAG 처리
   - 쿼리 복잡도 기반 전략 선택
   - 자가 수정 및 개선

5. **CorrectiveRAGProcessor** (`advancedrag/CorrectiveRAGProcessor.ts`)
   - 검색 결과 품질 검증
   - 오류 감지 및 수정
   - 대안 검색 전략 실행

#### 누락된 기능:
- ❌ 고급 그래프 쿼리 처리
- ❌ 다단계 추론 엔진
- ❌ 적응형 RAG 처리
- ❌ 커뮤니티 기반 분석
- ❌ 자가 수정 메커니즘

### 3. 🔍 Indexing Agent 핵심 기능

#### Legacy 위치: `backup/legacy-cleanup-20250808-133517/agents/`
- `cogo-indexing-worker.ts` (메인 Agent)
- `workflow/` 폴더 (워크플로우 관리)

#### 핵심 기능 모듈:
1. **HybridParser Integration**
   - 다중 언어 파싱 시스템
   - Tree-sitter 기반 구문 분석
   - 코멘트 및 메타데이터 추출

2. **BGE-M3 Embedding Service**
   - 고성능 임베딩 생성
   - 다국어 임베딩 지원
   - 벡터 품질 최적화

3. **RagWorkflowController** (`workflow/RagWorkflowController.ts`)
   - RAG 워크플로우 관리
   - 인덱싱 파이프라인 제어
   - 품질 검증 및 최적화

4. **Advanced File Processing**
   - 대용량 파일 처리
   - 병렬 인덱싱
   - 증분 업데이트

#### 누락된 기능:
- ❌ 하이브리드 파서 통합
- ❌ BGE-M3 임베딩 서비스
- ❌ 워크플로우 기반 인덱싱
- ❌ 고급 파일 처리
- ❌ 품질 검증 시스템

### 4. 🔬 Research Agent 핵심 기능

#### Legacy 위치: `backup/legacy-cleanup-20250808-133517/agents/`
- `cogo-research-worker.ts` (메인 Agent)
- `research/` 폴더 (연구 모듈들)

#### 핵심 기능 모듈:
1. **ResearchTaskProcessor** (`research/ResearchTaskProcessor.ts`)
   - 복잡한 연구 작업 분해
   - 병렬 연구 실행
   - 결과 통합 및 분석

2. **Context7 Integration**
   - 외부 지식 소스 연동
   - 실시간 정보 수집
   - 컨텍스트 기반 검색

3. **Security Analysis**
   - 보안 분석 전문 기능
   - 취약점 탐지 및 평가
   - 위험도 계산

4. **Multi-AI Integration**
   - 다중 AI 모델 활용
   - 결과 비교 및 검증
   - 최적 모델 선택

#### 누락된 기능:
- ❌ 고급 연구 작업 처리
- ❌ Context7 통합
- ❌ 보안 분석 기능
- ❌ 다중 AI 모델 통합
- ❌ 연구 결과 품질 검증

### 5. ⚡ Executor Agent 핵심 기능

#### Legacy 위치: `backup/legacy-cleanup-20250808-133517/agents/`
- `cogo-executor-agent.ts` (메인 Agent)
- `task/` 폴더 (작업 관리 모듈)
- `blueprint/` 폴더 (코드 생성 모듈)

#### 핵심 기능 모듈:
1. **TaskPlanManager** (`task/TaskPlan.ts`)
   - 복잡한 작업 계획 수립
   - 의존성 관리
   - 단계별 실행 계획

2. **ParallelGenerationManager** (`task/ParallelGenerationManager.ts`)
   - 병렬 코드 생성
   - 리소스 최적화
   - 충돌 방지 및 동기화

3. **BlueprintCreator** (`blueprint/BlueprintCreator.ts`)
   - 코드 블루프린트 생성
   - 패턴 기반 설계
   - 재사용 가능한 템플릿

4. **CodeValidator** (`blueprint/CodeValidator.ts`)
   - 코드 품질 검증
   - 정적 분석
   - 모범 사례 검사

5. **MCP Integration**
   - Figma, Browser 워커 연동
   - 외부 도구 통합
   - 멀티미디어 처리

#### 누락된 기능:
- ❌ 고급 작업 계획 수립
- ❌ 병렬 생성 관리
- ❌ 블루프린트 기반 생성
- ❌ 코드 품질 검증
- ❌ MCP 워커 통합

## 🎯 이관 계획 수립

### Phase 1: 핵심 모듈 구조 이관 (1주)

#### 1.1 Orchestrator Agent 핵심 모듈 이관
```
src/agents/DistributedOrchestratorAgent.ts 확장
├── modules/
│   ├── DecisionFramework.ts          # Legacy orchestrator/DecisionFramework.ts
│   ├── LLMPromptEngine.ts           # Legacy orchestrator/LLMPromptEngine.ts
│   ├── RAGSearchEngine.ts           # Legacy orchestrator/RAGSearchEngine.ts
│   ├── BlueprintManager.ts          # Legacy orchestrator/BlueprintManager.ts
│   └── OrchestratorMetrics.ts       # Legacy orchestrator/OrchestratorMetrics.ts
```

#### 1.2 GraphRAG Agent 고급 기능 이관
```
src/agents/DistributedGraphRAGAgent.ts 확장
├── processors/
│   ├── GraphQueryProcessor.ts       # Legacy graphrag/GraphQueryProcessor.ts
│   ├── MultiHopReasoner.ts         # Legacy graphrag/MultiHopReasoner.ts
│   ├── CommunityAnalyzer.ts        # Legacy graphrag/CommunityAnalyzer.ts
│   ├── AdaptiveRAGProcessor.ts     # Legacy advancedrag/AdaptiveRAGProcessor.ts
│   └── CorrectiveRAGProcessor.ts   # Legacy advancedrag/CorrectiveRAGProcessor.ts
```

#### 1.3 공통 모듈 Base 클래스 확장
```
src/agents/common/base/BaseDistributedAgent.ts 확장
├── capabilities/
│   ├── SessionManagement.ts        # 사용자 세션 관리
│   ├── QualityAssessment.ts        # 품질 평가 시스템
│   ├── MetricsCollection.ts        # 메트릭스 수집
│   └── ErrorRecovery.ts            # 오류 복구
```

### Phase 2: 서비스 통합 및 워크플로우 (1주)

#### 2.1 Indexing Agent 고급 처리 통합
```
src/agents/DistributedIndexingAgent.ts 확장
├── parsers/
│   ├── HybridParser.ts             # Legacy parsers/HybridParser.ts
│   ├── TreeSitterParser.ts         # Legacy parsers/TreeSitterParser.ts
│   └── CommentParser.ts            # Legacy parsers/CommentParser.ts
├── embeddings/
│   └── BGEM3EmbeddingService.ts    # Legacy services/BGEM3EmbeddingService.ts
└── workflows/
    └── RagWorkflowController.ts    # Legacy workflow/RagWorkflowController.ts
```

#### 2.2 Research Agent 연구 모듈 통합
```
src/agents/DistributedResearchAgent.ts 확장
├── processors/
│   └── ResearchTaskProcessor.ts    # Legacy research/ResearchTaskProcessor.ts
├── integrations/
│   ├── Context7Client.ts           # Legacy knowledge/Context7Client.ts
│   └── SecurityAnalyzer.ts         # 보안 분석 모듈
└── validators/
    └── ResearchQualityValidator.ts # 연구 품질 검증
```

#### 2.3 Executor Agent 실행 엔진 통합
```
src/agents/DistributedExecutorAgent.ts 확장
├── planners/
│   ├── TaskPlanManager.ts          # Legacy task/TaskPlan.ts
│   └── ParallelGenerationManager.ts # Legacy task/ParallelGenerationManager.ts
├── blueprints/
│   ├── BlueprintCreator.ts         # Legacy blueprint/BlueprintCreator.ts
│   ├── CodeGenerator.ts            # Legacy blueprint/CodeGenerator.ts
│   └── CodeValidator.ts            # Legacy blueprint/CodeValidator.ts
└── workers/
    └── MCPIntegration.ts           # MCP 워커 통합
```

### Phase 3: 통신 및 상태 관리 고도화 (1주)

#### 3.1 분산 통신 패키지 확장
```
src/agents/common/communication/ 확장
├── RealtimeCollaboration.ts        # 실시간 협업 기능
├── AgentInteraction.ts             # Agent 간 상호작용
├── QueueManagement.ts              # 작업 큐 관리
└── EventDrivenCommunication.ts     # 이벤트 기반 통신
```

#### 3.2 유틸리티 패키지 확장
```
src/agents/common/utilities/ 확장
├── AdvancedMetrics.ts              # 고급 메트릭스 수집
├── QualityAssurance.ts             # 품질 보증 시스템
├── ResourceMonitoring.ts           # 리소스 모니터링
└── PerformanceOptimizer.ts         # 성능 최적화
```

### Phase 4: 테스트 및 검증 (1주)

#### 4.1 통합 테스트 구현
```
src/tests/ 확장
├── LegacyFunctionMigrationTest.ts  # 이관 기능 검증
├── AdvancedAgentCapabilityTest.ts  # 고급 기능 테스트
├── PerformanceComparisonTest.ts    # 성능 비교 테스트
└── QualityAssuranceTest.ts         # 품질 보증 테스트
```

#### 4.2 성능 벤치마크
- Legacy vs 분산 Agent 성능 비교
- 메모리 사용량 최적화
- 응답 시간 개선 검증
- 확장성 테스트

## 📊 이관 우선순위 매트릭스

| Agent | 모듈 | 중요도 | 복잡도 | 우선순위 | 예상 기간 |
|-------|------|--------|--------|----------|-----------|
| Orchestrator | DecisionFramework | ⭐⭐⭐ | ⭐⭐⭐ | 1 | 2일 |
| Orchestrator | LLMPromptEngine | ⭐⭐⭐ | ⭐⭐ | 2 | 1일 |
| GraphRAG | AdaptiveRAGProcessor | ⭐⭐⭐ | ⭐⭐⭐ | 3 | 2일 |
| Indexing | HybridParser | ⭐⭐ | ⭐⭐ | 4 | 1일 |
| Executor | TaskPlanManager | ⭐⭐⭐ | ⭐⭐ | 5 | 1일 |
| Research | ResearchTaskProcessor | ⭐⭐ | ⭐⭐ | 6 | 1일 |
| GraphRAG | MultiHopReasoner | ⭐⭐ | ⭐⭐⭐ | 7 | 2일 |
| Orchestrator | RAGSearchEngine | ⭐⭐ | ⭐⭐ | 8 | 1일 |
| Executor | ParallelGenerationManager | ⭐⭐ | ⭐⭐ | 9 | 1일 |
| Indexing | BGEM3EmbeddingService | ⭐⭐ | ⭐ | 10 | 1일 |

## 🔧 기술적 고려사항

### 1. 호환성 유지
- BaseDistributedAgent 인터페이스 준수
- 기존 분산 통신 구조 활용
- 공통 패키지 아키텍처 확장

### 2. 성능 최적화
- 메모리 효율적인 모듈 로딩
- 지연 초기화 (Lazy Loading)
- 캐싱 전략 적용

### 3. 확장성 고려
- 플러그인 아키텍처
- 설정 기반 기능 활성화/비활성화
- 버전 호환성 관리

### 4. 테스트 전략
- 단위 테스트: 각 모듈별 개별 검증
- 통합 테스트: Agent 간 상호작용 검증
- 성능 테스트: Legacy 대비 성능 비교
- 부하 테스트: 확장성 검증

## 📈 예상 효과

### 정량적 개선
- **기능 완성도**: 60% → 95% (35% 향상)
- **성능**: Legacy 대비 20-30% 향상 예상
- **메모리 효율성**: 분산 구조로 인한 30% 절약
- **확장성**: 수평 확장 가능

### 정성적 개선
- **유지보수성**: 모듈화된 구조로 개선
- **재사용성**: 공통 패키지 활용도 증가
- **안정성**: 테스트 커버리지 확대
- **개발 효율성**: 표준화된 개발 패턴

## 🚧 위험 요소 및 대응 방안

### 1. 복잡성 증가
- **위험**: 모듈 간 의존성 복잡화
- **대응**: 인터페이스 기반 설계, 의존성 주입

### 2. 성능 저하
- **위험**: 모듈 추가로 인한 오버헤드
- **대응**: 성능 프로파일링, 최적화 포인트 식별

### 3. 호환성 문제
- **위험**: Legacy 코드와의 호환성 이슈
- **대응**: 단계적 이관, 병렬 실행 검증

### 4. 테스트 커버리지
- **위험**: 복잡한 모듈의 테스트 누락
- **대응**: TDD 방식 적용, 자동화된 테스트 파이프라인

## 📅 실행 일정

```
Week 1: Phase 1 - 핵심 모듈 구조 이관
├── Day 1-2: Orchestrator Agent 모듈 이관
├── Day 3-4: GraphRAG Agent 모듈 이관
└── Day 5-7: 공통 Base 클래스 확장

Week 2: Phase 2 - 서비스 통합 및 워크플로우
├── Day 1-2: Indexing Agent 고급 처리 통합
├── Day 3-4: Research Agent 연구 모듈 통합
└── Day 5-7: Executor Agent 실행 엔진 통합

Week 3: Phase 3 - 통신 및 상태 관리 고도화
├── Day 1-3: 분산 통신 패키지 확장
├── Day 4-5: 유틸리티 패키지 확장
└── Day 6-7: 성능 최적화

Week 4: Phase 4 - 테스트 및 검증
├── Day 1-3: 통합 테스트 구현
├── Day 4-5: 성능 벤치마크
└── Day 6-7: 최종 검증 및 문서화
```

## ✅ 승인 요청

본 이관 계획서는 다음 내용을 포함합니다:

1. **📋 현황 분석**: Legacy Agent 5개의 핵심 기능 상세 분석
2. **🎯 이관 계획**: 4단계 체계적 이관 방안
3. **📊 우선순위**: 중요도와 복잡도 기반 작업 순서
4. **🔧 기술 방안**: 호환성, 성능, 확장성 고려사항
5. **📈 예상 효과**: 정량적/정성적 개선 지표
6. **📅 실행 일정**: 4주간 상세 일정

**검토 요청 사항:**
- [ ] 이관 대상 모듈 선정의 적절성
- [ ] 우선순위 매트릭스의 타당성
- [ ] 기술 아키텍처 방향성
- [ ] 실행 일정의 현실성

승인 후 Phase 1부터 단계적으로 진행하겠습니다.

---

**📝 작성일**: 2025-08-08  
**🔧 작성자**: COGO Agent Core Development Team  
**📋 상태**: Phase 1 완료, Phase 2(경량) 완료, Phase 3(경량) 완료
**🕒 최종 업데이트**: 2025-08-08
