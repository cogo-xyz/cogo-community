# Phase 5: Agent 소스 이식 계획서

## 📋 개요

**목표**: Phase 4에서 구현된 RAG 시스템 함수들을 실제 Agent 서버로 이식하여 통합 테스트 환경 구축

**기간**: 1주일  
**상태**: 🚧 진행 중  
**우선순위**: 높음  

## 🎯 이식 대상 함수들

### 1. RAG 워크플로우 컨트롤러
- **파일**: `src/workflow/RagWorkflowController.ts`
- **핵심 함수**: `executeRagWorkflow()`
- **이식 대상**: `cogo-orchestrator-agent.ts`

### 2. 하이브리드 파서
- **파일**: `src/parsers/HybridParser.ts`
- **핵심 함수**: `parse()`, `initialize()`
- **이식 대상**: `cogo-indexing-worker.ts`

### 3. 벡터 서비스
- **파일**: `src/workflow/RagWorkflowController.ts` (VectorService 클래스)
- **핵심 함수**: `storeEmbeddings()`, `validateEmbeddings()`
- **이식 대상**: `cogo-graphrag-agent.ts`

### 4. 그래프 서비스
- **파일**: `src/workflow/RagWorkflowController.ts` (GraphService 클래스)
- **핵심 함수**: `buildKnowledgeGraph()`, `validateGraph()`
- **이식 대상**: `cogo-graphrag-agent.ts`

### 5. 소스 서비스
- **파일**: `src/workflow/RagWorkflowController.ts` (SourceService 클래스)
- **핵심 함수**: `updateSource()`, `validateSource()`
- **이식 대상**: `cogo-system-gateway.ts`

## 🔄 이식 단계별 계획

### Step 1: Agent 서버 환경 분석 (1일)
- [ ] 기존 Agent 서버 구조 분석
- [ ] 의존성 및 인터페이스 매핑
- [ ] 이식 호환성 검토
- [ ] 환경 설정 파일 업데이트

### Step 2: Orchestrator Agent 이식 (1일)
- [ ] `RagWorkflowController` 이식
- [ ] 워크플로우 실행 로직 통합
- [ ] 에러 처리 및 로깅 추가
- [ ] API 엔드포인트 추가

### Step 3: Indexing Worker 이식 (1일)
- [ ] `HybridParser` 이식
- [ ] 파싱 파이프라인 통합
- [ ] 실시간 파싱 기능 추가
- [ ] 성능 최적화

### Step 4: GraphRAG Agent 이식 (1일)
- [ ] `VectorService` 이식
- [ ] `GraphService` 이식
- [ ] 하이브리드 검색 기능 통합
- [ ] Neo4j 연결 최적화

### Step 5: System Gateway 이식 (1일)
- [ ] `SourceService` 이식
- [ ] Single Source of Truth 업데이트
- [ ] 실시간 동기화 기능
- [ ] API 게이트웨이 통합

### Step 6: 통합 테스트 (1일)
- [ ] 전체 RAG 워크플로우 테스트
- [ ] Agent 간 통신 테스트
- [ ] 성능 및 안정성 테스트
- [ ] 에러 복구 테스트

### Step 7: 문서화 및 최적화 (1일)
- [ ] API 문서 업데이트
- [ ] 배포 가이드 작성
- [ ] 성능 튜닝
- [ ] 모니터링 설정

## 🔧 기술적 고려사항

### 의존성 관리
- **Tree-sitter**: Agent 서버에 설치 필요
- **Neo4j Driver**: 기존 설치 확인
- **Supabase Client**: 기존 설치 확인
- **BGE-M3**: 임베딩 모델 설정

### 인터페이스 호환성
- **Task 인터페이스**: 기존 Task 타입과 통합
- **BaseAgent**: 상속 구조 유지
- **EventEmitter**: 이벤트 기반 통신
- **Logger**: 통합 로깅 시스템

### 성능 최적화
- **비동기 처리**: Promise 기반 비동기 실행
- **캐싱**: LRU 캐시 적용
- **병렬 처리**: Worker Threads 활용
- **메모리 관리**: 가비지 컬렉션 최적화

## 📊 성공 지표

### 기능적 지표
- [ ] RAG 워크플로우 100% 실행 성공
- [ ] 모든 Agent 간 통신 정상
- [ ] 에러 복구 95% 이상 성공률
- [ ] API 응답 시간 < 5초

### 성능 지표
- [ ] 파싱 성능: 1000줄/초
- [ ] 벡터 임베딩: 100개/분
- [ ] 그래프 구축: 1000노드/분
- [ ] 메모리 사용량 < 2GB

### 안정성 지표
- [ ] 24시간 연속 실행 안정성
- [ ] 에러 발생률 < 1%
- [ ] 자동 복구 시간 < 30초
- [ ] 데이터 무결성 100%

## 🚨 위험 요소 및 대응 방안

### 기술적 위험
1. **의존성 충돌**
   - **위험**: Tree-sitter와 기존 라이브러리 충돌
   - **대응**: 격리된 환경에서 단계적 이식

2. **성능 저하**
   - **위험**: RAG 시스템으로 인한 성능 저하
   - **대응**: 점진적 최적화 및 모니터링

3. **데이터 손실**
   - **위험**: 이식 과정에서 데이터 손실
   - **대응**: 완전한 백업 및 롤백 계획

### 운영적 위험
1. **서비스 중단**
   - **위험**: 이식 중 서비스 중단
   - **대응**: Blue-Green 배포 전략

2. **팀 협업**
   - **위험**: 여러 Agent 동시 이식으로 인한 충돌
   - **대응**: 순차적 이식 및 코드 리뷰

## 📁 파일 구조 계획

```
src/agents/
├── cogo-orchestrator-agent.ts          # RAG 워크플로우 컨트롤러 이식
├── cogo-indexing-worker.ts             # 하이브리드 파서 이식
├── cogo-graphrag-agent.ts              # 벡터/그래프 서비스 이식
├── cogo-system-gateway.ts              # 소스 서비스 이식
└── workflow/
    ├── RagWorkflowController.ts        # 이식된 RAG 컨트롤러
    ├── VectorService.ts                # 분리된 벡터 서비스
    ├── GraphService.ts                 # 분리된 그래프 서비스
    └── SourceService.ts                # 분리된 소스 서비스
```

## 🎯 다음 단계

**Phase 6: 최종 통합 테스트**
- Agent 서버 기반 RAG 시스템 테스트
- 실제 사용 시나리오 검증
- 성능 및 안정성 최종 확인

## ✅ 완료 체크리스트

- [ ] Agent 서버 환경 분석 완료
- [ ] Orchestrator Agent 이식 완료
- [ ] Indexing Worker 이식 완료
- [ ] GraphRAG Agent 이식 완료
- [ ] System Gateway 이식 완료
- [ ] 통합 테스트 완료
- [ ] 문서화 및 최적화 완료
- [ ] Phase 6 준비 완료 