# Agent 소스 파일 관계도

## 📋 개요

COGO Agent Core 시스템의 agent 관련 소스 파일들의 의존성 관계를 계층별로 분석한 문서입니다.

## 🏗️ 계층 구조 분석

### Level 1: 최하위 기반 클래스 (Foundation Layer)

```
BaseAgent.ts (5.5KB, 207줄)
├── 모든 agent의 부모 클래스
├── 기본 기능 제공
└── 추상 메서드 정의
```

**의존성**: 없음 (최하위)
**사용자**: 모든 agent 클래스들

### Level 2: 핵심 관리자 클래스 (Core Management Layer)

```
AgentManager.ts (20KB, 589줄)
├── agent 생명주기 관리
├── agent 초기화 및 종료
├── 태스크 분배
└── 성능 모니터링

TaskManager.ts (27KB, 813줄)
├── 태스크 관리 및 분배
├── 태스크 상태 추적
├── 우선순위 관리
└── 결과 처리
```

**의존성**: BaseAgent.ts
**사용자**: index.ts, routes, services

### Level 3: 특화 Agent 클래스 (Specialized Agent Layer)

#### 3.1 지능형 오케스트레이션
```
COGOIntelligenceOrchestratorFast.ts (124KB, 3904줄)
├── 지능형 코드 생성
├── 4단계 라이프사이클
├── AI 모델 통합
└── JSON 파싱 및 폴백 시스템
```

#### 3.2 연구 및 분석
```
GoogleDeepResearchAgent.ts (32KB, 955줄)
├── Google API 통합
├── 심층 연구 분석
├── Context7 MCP 통합
└── Gemini 모델 활용
```

#### 3.3 코드 생성
```
CodeGenerationAgent.ts (17KB, 540줄)
├── 코드 생성 및 개발
├── 파일 구조 설계
├── 인터페이스 생성
└── 검증 및 테스트
```

#### 3.4 워커 관리
```
OpenHandsAgentManager.ts (9.5KB, 310줄)
├── COGO Worker CLI 관리
├── 작업 분배
├── 성능 모니터링
└── 자동 확장/축소

OpenHandsAgentNew.ts (7.6KB, 281줄)
├── OpenHands CLI 실행
├── 작업 처리
├── 결과 반환
└── 오류 처리
```

#### 3.5 인덱싱 및 검색
```
IndexingWorker.ts (15KB, 479줄)
├── 문서 인덱싱
├── 벡터 검색
├── 실시간 업데이트
└── 성능 최적화
```

#### 3.6 아키텍처 게이트웨이
```
ArchGW.ts (6.7KB, 207줄)
├── 아키텍처 분석
├── 패턴 인식
├── 의존성 관리
└── 구조 최적화
```

### Level 4: 고급 기능 클래스 (Advanced Feature Layer)

#### 4.1 협업 및 멘토링
```
MentoringPoolManager.ts (21KB, 694줄)
├── 멘토링 세션 관리
├── 멘토-멘티 매칭
├── 성과 추적
└── 피드백 시스템

CollaborationSessionManager.ts (28KB, 943줄)
├── 협업 세션 관리
├── 실시간 통신
├── 문서 공유
└── 버전 관리
```

#### 4.2 워크플로우 관리
```
LangGraphOrchestratorAgent.ts (12KB, 373줄)
├── LangGraph 워크플로우
├── 노드 관리
├── 엣지 처리
└── 실행 최적화

WorkflowTemplateManager.ts (74KB, 2497줄)
├── 워크플로우 템플릿
├── 패턴 관리
├── 재사용성
└── 확장성
```

#### 4.3 프로토콜 및 통신
```
A2AProtocolManager.ts (7.6KB, 263줄)
├── Agent 간 통신
├── 프로토콜 관리
├── 메시지 라우팅
└── 보안 처리

ManagerCommunicationService.ts (10KB, 348줄)
├── 매니저 간 통신
├── 이벤트 처리
├── 상태 동기화
└── 오류 복구
```

#### 4.4 스케줄링 및 데이터
```
SchedulingManager.ts (10.0KB, 313줄)
├── 작업 스케줄링
├── 우선순위 관리
├── 리소스 할당
└── 성능 최적화

DatabaseManager.ts (19KB, 667줄)
├── 데이터베이스 관리
├── 연결 풀링
├── 트랜잭션 처리
└── 백업 및 복구

DataSyncManager.ts (11KB, 366줄)
├── 데이터 동기화
├── 충돌 해결
├── 실시간 업데이트
└── 일관성 보장
```

### Level 5: 특수 목적 클래스 (Special Purpose Layer)

#### 5.1 오류 복구 및 품질
```
ErrorRecoveryManager.ts (27KB, 956줄)
├── 오류 감지 및 복구
├── 자동 복구 메커니즘
├── 로깅 및 모니터링
└── 예방적 조치

ProductionRAGAgent.ts (18KB, 581줄)
├── RAG 시스템 운영
├── 검색 최적화
├── 응답 품질 관리
└── 성능 모니터링
```

#### 5.2 지능형 OpenHands
```
IntelligentOpenHandsAgent.ts (13KB, 397줄)
├── 지능형 CLI 실행
├── 컨텍스트 이해
├── 자동화된 작업
└── 학습 및 개선
```

#### 5.3 Phase 관리
```
Phase5Manager.ts (13KB, 429줄)
├── Phase 5 기능 관리
├── 고급 기능 통합
├── 성능 최적화
└── 확장성 관리
```

### Level 6: Expert 클래스 (Expert Layer)

```
expert/AutoCodeFixAgent.ts (27KB, 837줄)
├── 자동 코드 수정
├── 오류 분석
├── 패턴 인식
└── 개선 제안

expert/ArchitectureAnalysisAgent.ts (26KB, 796줄)
├── 아키텍처 분석
├── 패턴 평가
├── 최적화 제안
└── 문서화
```

## 🔗 의존성 관계도

```
Level 1: BaseAgent.ts
    ↑
Level 2: AgentManager.ts, TaskManager.ts
    ↑
Level 3: COGOIntelligenceOrchestratorFast.ts, GoogleDeepResearchAgent.ts, 
         CodeGenerationAgent.ts, OpenHandsAgentManager.ts, OpenHandsAgentNew.ts,
         IndexingWorker.ts, ArchGW.ts
    ↑
Level 4: MentoringPoolManager.ts, CollaborationSessionManager.ts,
         LangGraphOrchestratorAgent.ts, WorkflowTemplateManager.ts,
         A2AProtocolManager.ts, ManagerCommunicationService.ts,
         SchedulingManager.ts, DatabaseManager.ts, DataSyncManager.ts
    ↑
Level 5: ErrorRecoveryManager.ts, ProductionRAGAgent.ts,
         IntelligentOpenHandsAgent.ts, Phase5Manager.ts
    ↑
Level 6: expert/AutoCodeFixAgent.ts, expert/ArchitectureAnalysisAgent.ts
```

## 📊 리팩토링 우선순위

### 1단계: Level 1 (최하위)
- **BaseAgent.ts**: 안정적, 리팩토링 불필요

### 2단계: Level 2 (핵심 관리자)
- **TaskManager.ts**: 27KB → 모듈화 필요
- **AgentManager.ts**: 20KB → 최적화 필요

### 3단계: Level 3 (특화 Agent)
- **COGOIntelligenceOrchestratorFast.ts**: 124KB → 분할 필요
- **WorkflowTemplateManager.ts**: 74KB → 모듈화 필요
- **GoogleDeepResearchAgent.ts**: 32KB → 최적화 필요
- **ErrorRecoveryManager.ts**: 27KB → 최적화 필요
- **CollaborationSessionManager.ts**: 28KB → 최적화 필요

### 4단계: Level 4-6 (고급 기능)
- 나머지 파일들 순차적 리팩토링

## 🎯 리팩토링 전략

### 1. 파일 크기 기준
- **100KB 이상**: 필수 분할
- **50KB 이상**: 모듈화 권장
- **30KB 이상**: 최적화 권장

### 2. 복잡도 기준
- **2000줄 이상**: 필수 분할
- **1000줄 이상**: 모듈화 권장
- **500줄 이상**: 최적화 권장

### 3. 의존성 기준
- **높은 의존성**: 안정성 우선
- **중간 의존성**: 점진적 개선
- **낮은 의존성**: 적극적 리팩토링

---

**문서 버전**: 1.0  
**최종 업데이트**: 2025-07-30  
**작성자**: COGO Development Team  
**검토자**: System Architecture Team 