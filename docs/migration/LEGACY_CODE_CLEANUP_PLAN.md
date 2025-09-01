# COGO 분산 Agent 시스템 - Legacy 코드 정리 계획서

## 📋 분석 개요

현재 COGO 분산 Agent 시스템의 실제 사용 중인 소스 코드를 분석하여 Legacy 코드를 식별하고 정리 계획을 수립했습니다.

## 🔍 현재 사용 중인 핵심 소스 코드

### 1. **분산 Agent 서버** (1개)
```
real-distributed-server.js                    ← 메인 분산 Agent 실행 서버
```

### 2. **분산 Agent 구현체** (5개)
```
src/agents/
├── DistributedOrchestratorAgent.ts          ← 워크플로우 조정 Agent
├── DistributedIndexingAgent.ts              ← 코드 분석 & 인덱싱 Agent  
├── DistributedResearchAgent.ts              ← 멀티 AI 리서치 Agent
├── DistributedGraphRAGAgent.ts              ← 지식 그래프 추론 Agent
└── IntegratedDistributedExecutorAgent.ts    ← Worker 관리 & 실행 Agent
```

### 3. **핵심 서비스** (3개)
```
src/services/
├── SupabaseRealtimeQueue.ts                 ← Realtime 큐 서비스
├── MultilingualRealtimeChatService.ts       ← 다국어 채팅 서비스
└── RealDistributedCommunication.ts          ← 분산 통신 서비스
```

### 4. **통신 인프라** (5개)
```
src/communication/
├── CommunicationFactory.ts                  ← 통신 팩토리
├── interfaces/DistributedCommunicationInterface.ts
├── real/RealDistributedCommunication.ts
├── mock/MockDistributedCommunication.ts
└── adapters/SupabaseRealtimeAdapter.ts
```

### 5. **Worker 서버들** (3개)
```
cogo-worker/
├── websocket_sandbox_server.py              ← Python Sandbox Worker (포트 3001)
mcp-servers/
├── figma-context/                           ← Figma MCP Worker (포트 3002)
└── browser-use/                             ← Browser Worker (포트 3003)
```

### 6. **핵심 테스트 파일들** (4개)
```
test-cogo-end-to-end.js                      ← End-to-End 시스템 테스트
test-cogo-unified-auth.js                    ← 통합 인증 테스트
generate-cogo-token.js                       ← COGO 인증 토큰 생성
create-cogo-user.js                          ← COGO 사용자 생성
```

### 7. **환경 설정** (2개)
```
env.development                               ← 개발 환경 변수
.cogo-auth.env                               ← COGO 인증 토큰 (Git 제외)
```

## 🗑️ Legacy 코드 정리 대상

### **P1 (높음) - 즉시 정리 필요**

#### 1. **src/agents/ 디렉토리** (총 35개 파일 중 5개만 사용)
```
❌ 정리 대상 (30개):
├── cogo-sandbox-worker.ts                   ← Legacy Worker
├── ErrorRecoveryManager.ts                  ← 미사용
├── DistributedResearchAgent.ts.backup       ← 백업 파일
├── DistributedExecutorAgent.ts              ← 중복 (IntegratedDistributedExecutorAgent 사용)
├── cogo-indexing-worker.ts                  ← Legacy Worker
├── cogo-codegen-service.ts                  ← Legacy Service
├── cogo-graphrag-agent.ts                   ← Legacy Agent
├── cogo-executor-agent.ts                   ← Legacy Agent
├── cogo-manager-agent.ts                    ← Legacy Agent
├── cogo-orchestrator-agent.ts               ← Legacy Agent
├── cogo-orchestrator-agent-clean.ts         ← Legacy Agent
├── cogo-orchestrator-agent.ts.backup        ← 백업 파일
├── cogo-research-worker.ts                  ← Legacy Worker
├── SandboxManager.ts                        ← Legacy Manager
├── SandboxManager.ts.backup                 ← 백업 파일
├── cogo-executor-agent.ts.disabled          ← 비활성화된 파일
├── DatabaseManager.ts                       ← 미사용
├── cogo-openhands-agent.ts                  ← Legacy Agent
├── BlueprintManagerRefactored.ts            ← 미사용
├── cogo-langgraph-orchestrator-agent.ts     ← Legacy Agent
├── A2AProtocolManager.ts                    ← 미사용
└── 하위 디렉토리들 (orchestrator/, workers/, manager/, blueprint/, database/, research/, errorrecovery/, graphrag/, advancedrag/, base/, task/) ← 전체 정리

✅ 보존 대상 (5개):
├── DistributedOrchestratorAgent.ts          ← 활성 사용
├── DistributedIndexingAgent.ts              ← 활성 사용
├── DistributedResearchAgent.ts              ← 활성 사용
├── DistributedGraphRAGAgent.ts              ← 활성 사용
└── IntegratedDistributedExecutorAgent.ts    ← 활성 사용
```

#### 2. **src/services/ 디렉토리** (총 111개 파일 중 3개만 사용)
```
❌ 정리 대상 (108개):
├── MonitoringDashboard.ts                   ← 미사용
├── CloudAgentManager.ts                     ← 미사용
├── RealWebSocketWorkerInterface.ts          ← 미사용
├── WorkerInterfaceFactory.ts                ← 미사용
├── LoadBalancer.ts                          ← 미사용
├── WebSocketWorkerInterface.ts              ← 미사용
├── HealthMonitor.ts                         ← 미사용
├── WorkerManager.ts                         ← 미사용
├── WorkerRegistry.ts                        ← 미사용
├── RealDatabaseServices.ts                  ← 미사용
├── APIKeyManager.ts                         ← 미사용
├── RealAIServices.ts                        ← 미사용
├── DistributedKeyManager.ts                 ← 미사용
├── RealWebSocketWorkers.ts                  ← 미사용
├── AIModelSelector.ts                       ← 미사용
├── CentralAPIKeyManager.ts                  ← 미사용
├── RAGServiceFactory.ts                     ← 미사용
├── BGEM3EmbeddingService.ts                 ← 미사용
├── SupabaseRAGService.ts                    ← 미사용
├── OpenAIClient.ts                          ← 미사용
├── ConfigurationManagementService.ts        ← 미사용
├── LanguageSpecificPrompts.ts               ← 미사용
├── StructuredCodeGenerationEngine.ts        ← 미사용
├── DomainSpecificPromptMethodology.ts       ← 미사용
├── ContextAwarePromptEngine.ts              ← 미사용
├── IntelligentErrorRecovery.ts              ← 미사용
├── EventDrivenCommunication.ts              ← 미사용
├── FireworksClient.ts                       ← 미사용
├── MetricsService.ts                        ← 미사용
├── RealTimeCollaborationService.ts          ← 미사용
├── RealtimeMonitor.ts                       ← 미사용
├── SupabaseRealtimeService.ts               ← 미사용
├── LLMInteractionFramework.ts               ← 미사용
├── PerformanceOptimizationSystem.ts         ← 미사용
├── RolePackageManager.ts                    ← 미사용
├── QualityAssuranceSystem.ts                ← 미사용
├── RefactoringMethodology.ts                ← 미사용
├── TelegramKnowledgeBot.ts                  ← 미사용
├── EmbeddingService.ts                      ← 미사용
├── GeminiClient.ts                          ← 미사용
├── ClaudeClient.ts                          ← 미사용
├── PreGenerationFramework.ts                ← 미사용
├── PromptGenerationEngine.ts                ← 미사용
├── KnowledgeBaseSearch.ts                   ← 미사용
├── RequirementComplexityAnalyzer.ts         ← 미사용
├── SmartNotificationSystem.ts               ← 미사용
├── CodeGenerationService.ts                 ← 미사용
├── PerformanceTracker.ts                    ← 미사용
├── MCPClient.ts                             ← 미사용
├── ProductionReadinessReport.ts             ← 미사용
├── TaskProcessor.ts                         ← 미사용
├── RoleExecutor.ts                          ← 미사용
├── RoleSelector.ts                          ← 미사용
├── role-selection-engine.ts                 ← 미사용
├── CodeTemplateService.ts                   ← 미사용
├── HybridQueryService.ts                    ← 미사용
├── VectorStoreService.ts                    ← 미사용
├── DatabaseMigrationService.ts              ← 미사용
├── CogoWorkerManager.ts                     ← 미사용
├── CollaborationManager.ts                  ← 미사용
├── AgentCommunicationManager.ts             ← 미사용
├── ClaudeCodeGenerationService.ts           ← 미사용
├── DirectClaudeService.ts                   ← 미사용
├── OpenHandsSessionManager.ts               ← 미사용
├── OpenHandsKeyManager.ts                   ← 미사용
├── LanguageTranslationService.ts            ← 미사용
├── PromptManagementService.ts               ← 미사용
├── GraphManager.ts                          ← 미사용
├── PatternRecognitionEngine.ts              ← 미사용
├── MultiUserCollaboration.ts                ← 미사용
├── PerformanceOptimizer.ts                  ← 미사용
├── ParallelProcessingEngine.ts              ← 미사용
├── RealtimeLogStreaming.ts                  ← 미사용
├── SettingsManager.ts                       ← 미사용
├── AdvancedSearchEngine.ts                  ← 미사용
├── OptimizedCacheManager.ts                 ← 미사용
├── GarbageCollectionOptimizer.ts            ← 미사용
├── MonitoringEnhancer.ts                    ← 미사용
├── MCPServer.ts                             ← 미사용
├── UIEnhancer.ts                            ← 미사용
├── ArchGW.ts                                ← 미사용
├── SupabaseConnectionPool.ts                ← 미사용
├── ErrorHandlingEnhancer.ts                 ← 미사용
├── MemoryProfiler.ts                        ← 미사용
├── QualityAssessmentService.ts              ← 미사용
├── LoggingService.ts                        ← 미사용
├── IntelligentPromptGenerator.ts            ← 미사용
├── ContinuousLearningSystem.ts              ← 미사용
├── PerformanceMonitor.ts                    ← 미사용
├── AutoPromptOptimizer.ts                   ← 미사용
├── AdvancedMetricsCollector.ts              ← 미사용
├── AutonomousGitManager.ts                  ← 미사용
├── RealAICodeGenerator.ts                   ← 미사용
├── GitHubRepositoryAnalyzer.ts              ← 미사용
└── 하위 디렉토리들 (architecture/, quality/) ← 전체 정리

✅ 보존 대상 (3개):
├── SupabaseRealtimeQueue.ts                 ← 활성 사용
├── MultilingualRealtimeChatService.ts       ← 활성 사용
└── RealDistributedCommunication.ts          ← 활성 사용
```

### **P2 (중간) - 단계적 정리**

#### 3. **src/routes/ 디렉토리** (총 44개 파일 중 6개만 사용)
```
❌ 정리 대상 (38개):
├── langgraph-workflow.ts                    ← 미사용
├── monitoringRoutes.ts                      ← 미사용
├── cogoRoutes.ts                            ← 미사용
├── code-generation.ts                       ← 미사용
├── chatRoutes.ts                            ← 미사용
├── aiRoutes.ts                              ← 미사용
├── taskRoutes.ts                            ← 미사용
├── webInterfaceRoutes.ts                    ← 미사용
├── simpleTaskRoutes.ts                      ← 미사용
├── researchRoutes.ts                        ← 미사용
├── indexingRoutes.ts                        ← 미사용
├── codegenRAGRoutes.ts                      ← 미사용
├── multilingualRoutes.ts                    ← 미사용
├── languageSpecificRoutes.ts                ← 미사용
├── structuredCodeGenerationRoutes.ts        ← 미사용
├── phase4Week3Routes.ts                     ← 미사용
├── eventTestRoutes.ts                       ← 미사용
├── systemGatewayRoutes.ts                   ← 미사용
├── workflowRoutes.ts                        ← 미사용
├── sandboxRoutes.ts                         ← 미사용
├── cogoWorkflowRoutes.ts                    ← 미사용
├── mechanicRoutes.ts                        ← 미사용
├── knowledgeGraphRoutes.ts                  ← 미사용
├── developmentRoutes.ts                     ← 미사용
├── ai-model-routes.ts                       ← 미사용
├── mcp-routes.ts                            ← 미사용
├── agents.ts                                ← 미사용
├── centralGatewayRoutes.ts                  ← 미사용
├── realtimeRoutes.ts                        ← 미사용
├── hybrid-analytics.ts                      ← 미사용
├── migrationRoutes.ts                       ← 미사용
├── cogoWorkerRoutes.ts                      ← 미사용
├── ragRoutes.ts                             ← 미사용
├── translationRoutes.ts                     ← 미사용
├── realtimeQueueRoutes.ts                   ← 미사용
├── quality-assessment.ts                    ← 미사용
├── feedbackRoutes.ts                        ← 미사용
├── testRoutes.ts                            ← 미사용
├── aiCodeRoutes.ts                          ← 미사용
├── githubAnalysisRoutes.ts                  ← 미사용
├── codeExecutorRoutes.ts                    ← 미사용
├── selfLearningRoutes.ts                    ← 미사용
├── helloRoutes.ts                           ← 미사용
└── fileUploadRoutes.ts                      ← 미사용

✅ 보존 대상 (6개):
├── [분산 시스템에서 사용되는 핵심 라우트들만 선별 보존]
```

#### 4. **src/tests/ 디렉토리** (총 118개 파일 중 10개만 사용)
```
❌ 정리 대상 (108개):
├── 대부분의 테스트 파일들이 Legacy 시스템용
├── 분산 Agent 시스템과 무관한 테스트들
└── 중복되거나 미사용 테스트들

✅ 보존 대상 (10개):
├── [분산 Agent 시스템 관련 핵심 테스트만 선별 보존]
```

### **P3 (낮음) - 선택적 정리**

#### 5. **기타 Legacy 디렉토리들**
```
src/
├── knowledge/ (16개)                        ← 대부분 정리
├── parsers/ (3개)                           ← 대부분 정리
├── workflow/ (7개)                          ← 대부분 정리
├── research/ (3개)                          ← 대부분 정리
├── debug/ (5개)                             ← 대부분 정리
├── migration/ (1개)                         ← 정리
├── core/ (2개)                              ← 선택적 보존
├── middleware/ (1개)                        ← 선택적 보존
├── types/ (9개)                             ← 선택적 보존
├── utils/ (3개)                             ← 선택적 보존
└── ai/ (2개)                                ← 선택적 보존
```

## 📊 정리 후 예상 결과

### **파일 수 변화**
- **현재**: ~400개 파일
- **정리 후**: ~40개 파일
- **감소율**: 90%

### **정리 후 구조**
```
📁 COGO 분산 Agent 시스템 (정리 후)
├── 🏗️ 핵심 실행 (1개)
│   └── real-distributed-server.js
├── ⚙️ 분산 Agent (5개)  
│   └── src/agents/Distributed*.ts
├── 🔧 Worker 서버 (3개)
│   └── cogo-worker/, mcp-servers/
├── 🌐 Edge Functions (3개)
│   └── supabase/functions/
├── 📡 통신 인프라 (8개)
│   └── src/communication/, src/services/ (핵심만)
├── 🧪 핵심 테스트 (4개)
│   └── test-cogo-*.js, generate-*.js
├── 📚 문서화 (현재 유지)
│   └── docs/
└── 🔧 설정 파일 (2개)
    └── env.development, .cogo-auth.env
```

## 🚀 정리 실행 계획

### **Phase 1: 즉시 정리 (P1 우선순위)**
1. **src/agents/ 디렉토리 정리**
   - 5개 분산 Agent 제외 모든 파일 삭제
   - 하위 디렉토리 전체 삭제
   - 백업 파일들 삭제

2. **src/services/ 디렉토리 정리**
   - 3개 핵심 서비스 제외 모든 파일 삭제
   - 하위 디렉토리 전체 삭제

### **Phase 2: 단계적 정리 (P2 우선순위)**
1. **src/routes/ 디렉토리 정리**
   - 분산 시스템에서 사용되지 않는 라우트들 삭제
   - 핵심 라우트만 선별 보존

2. **src/tests/ 디렉토리 정리**
   - 분산 Agent 시스템 관련 테스트만 보존
   - Legacy 테스트들 삭제

### **Phase 3: 선택적 정리 (P3 우선순위)**
1. **기타 Legacy 디렉토리들 정리**
   - 필요성 검토 후 선별적 삭제
   - 핵심 기능에 영향 없는 파일들 정리

## ⚠️ 주의사항

### **정리 전 확인 사항**
1. **백업 생성**: 전체 프로젝트 백업
2. **의존성 확인**: 삭제할 파일들의 의존성 관계 확인
3. **테스트 실행**: 정리 후 시스템 정상 동작 확인

### **정리 중 주의사항**
1. **단계별 실행**: 한 번에 모든 파일을 삭제하지 말고 단계별로 진행
2. **검증**: 각 단계마다 시스템 동작 확인
3. **롤백 준비**: 문제 발생 시 즉시 롤백 가능하도록 준비

### **정리 후 확인 사항**
1. **시스템 동작 테스트**: 모든 핵심 기능 정상 동작 확인
2. **성능 테스트**: 정리 후 성능 변화 확인
3. **문서 업데이트**: 정리된 구조에 맞게 문서 업데이트

## 📋 정리 체크리스트

### **Phase 1 체크리스트**
- [ ] src/agents/ 디렉토리 백업
- [ ] 5개 분산 Agent 제외 모든 파일 삭제
- [ ] src/agents/ 하위 디렉토리 전체 삭제
- [ ] src/services/ 디렉토리 백업
- [ ] 3개 핵심 서비스 제외 모든 파일 삭제
- [ ] src/services/ 하위 디렉토리 전체 삭제
- [ ] Phase 1 정리 후 시스템 테스트

### **Phase 2 체크리스트**
- [ ] src/routes/ 디렉토리 분석 및 정리
- [ ] src/tests/ 디렉토리 분석 및 정리
- [ ] Phase 2 정리 후 시스템 테스트

### **Phase 3 체크리스트**
- [ ] 기타 Legacy 디렉토리들 분석 및 정리
- [ ] 전체 시스템 통합 테스트
- [ ] 문서 업데이트

## 🎯 정리 목표

1. **코드베이스 간소화**: 90% 파일 수 감소
2. **유지보수성 향상**: 명확한 구조와 의존성
3. **성능 최적화**: 불필요한 코드 제거로 성능 향상
4. **개발 효율성 증대**: 명확한 아키텍처로 개발 속도 향상
5. **시스템 안정성**: Legacy 코드로 인한 버그 위험 제거

---

**© 2025 COGO Platform. Legacy 코드 정리 계획서 v1.0**
