# PromptChain.ts 리팩토링 계획

## 📋 파일 분석

### 현재 상태
- **파일 크기**: 22KB, 722줄
- **복잡도**: 높음 (여러 책임을 가짐)
- **우선순위**: 1 (가장 큰 파일)

### 주요 책임들
1. **체인 템플릿 관리** - ChainTemplate, ChainStepTemplate
2. **체인 실행 엔진** - 순차/병렬 실행
3. **에이전트 관리** - 등록 및 조회
4. **변수 관리** - 체인 간 데이터 공유
5. **상태 관리** - 체인 상태 추적
6. **결과 수집** - 실행 결과 및 인사이트

## 🎯 모듈화 계획

### 1. ChainTemplateManager (체인 템플릿 관리)
**파일**: `src/agents/chain/ChainTemplateManager.ts`
**책임**:
- 체인 템플릿 등록/관리
- 템플릿 검증
- 기본 템플릿 초기화

**인터페이스**:
```typescript
export interface ChainTemplateManager {
  registerTemplate(template: ChainTemplate): void;
  getTemplate(name: string): ChainTemplate | undefined;
  getAvailableTemplates(): ChainTemplate[];
  validateTemplate(template: ChainTemplate): boolean;
}
```

### 2. ChainExecutionEngine (체인 실행 엔진)
**파일**: `src/agents/chain/ChainExecutionEngine.ts`
**책임**:
- 순차 실행 로직
- 병렬 실행 로직
- 의존성 체크
- 단계별 실행

**인터페이스**:
```typescript
export interface ChainExecutionEngine {
  executeSequential(chain: PromptChainConfig, inputData: any): Promise<ChainExecutionResult>;
  executeParallel(chain: PromptChainConfig, inputData: any): Promise<ChainExecutionResult>;
  executeStep(step: ChainStep, context: ExecutionContext): Promise<TaskResult>;
}
```

### 3. AgentRegistry (에이전트 관리)
**파일**: `src/agents/chain/AgentRegistry.ts`
**책임**:
- 에이전트 등록/관리
- 에이전트 조회
- 에이전트 상태 관리

**인터페이스**:
```typescript
export interface AgentRegistry {
  registerAgent(agent: BaseAgent): void;
  getAgent(agentId: string): BaseAgent | undefined;
  findAvailableAgent(agentType: string): string | undefined;
  getAgentStatus(agentId: string): any;
}
```

### 4. ChainStateManager (상태 관리)
**파일**: `src/agents/chain/ChainStateManager.ts`
**책임**:
- 활성 체인 추적
- 체인 히스토리 관리
- 상태 업데이트

**인터페이스**:
```typescript
export interface ChainStateManager {
  addActiveChain(chain: PromptChainConfig): void;
  removeActiveChain(chainId: string): void;
  getActiveChains(): PromptChainConfig[];
  addToHistory(result: ChainExecutionResult): void;
  getChainHistory(limit: number): ChainExecutionResult[];
}
```

### 5. VariableManager (변수 관리)
**파일**: `src/agents/chain/VariableManager.ts`
**책임**:
- 체인 간 변수 공유
- 변수 스코프 관리
- 변수 검증

**인터페이스**:
```typescript
export interface VariableManager {
  setVariable(key: string, value: any, scope?: string): void;
  getVariable(key: string, scope?: string): any;
  clearVariables(scope?: string): void;
  getVariables(scope?: string): Map<string, any>;
}
```

### 6. ResultAnalyzer (결과 분석)
**파일**: `src/agents/chain/ResultAnalyzer.ts`
**책임**:
- 실행 결과 요약 생성
- 인사이트 추출
- 성과 분석

**인터페이스**:
```typescript
export interface ResultAnalyzer {
  generateSummary(chain: PromptChainConfig, results: Map<string, TaskResult>, errors: Array<{ stepId: string; error: string }>): string;
  extractInsights(chain: PromptChainConfig, results: Map<string, TaskResult>): Promise<string[]>;
  analyzePerformance(results: Map<string, TaskResult>): PerformanceMetrics;
}
```

## 🔄 리팩토링 순서

### Phase 1: 기반 모듈 생성 (1시간)
1. **ChainTemplateManager** 생성
2. **AgentRegistry** 생성
3. **VariableManager** 생성

### Phase 2: 실행 엔진 분리 (1.5시간)
1. **ChainExecutionEngine** 생성
2. **ChainStateManager** 생성
3. **ResultAnalyzer** 생성

### Phase 3: 메인 클래스 리팩토링 (1시간)
1. **PromptChain** 클래스 간소화
2. **의존성 주입** 적용
3. **인터페이스 통합**

### Phase 4: 테스트 및 검증 (30분)
1. **컴파일 테스트**
2. **기본 기능 동작 확인**
3. **성능 검증**

## 📊 예상 결과

### 코드 품질 향상
- **파일 크기**: 722줄 → 평균 120줄 (83% 감소)
- **순환 복잡도**: 평균 15 → 8 (47% 감소)
- **책임 분리**: 단일 책임 원칙 준수

### 유지보수성 향상
- **모듈화**: 6개 독립적인 모듈
- **테스트 용이성**: 각 모듈별 단위 테스트 가능
- **확장성**: 새로운 기능 추가 용이

### 성능 개선
- **메모리 사용량**: 20% 감소 예상
- **실행 속도**: 15% 향상 예상
- **에러 처리**: 더 정확한 에러 추적

## ⚠️ 주의사항

### 1. 백워드 호환성
- 기존 API 인터페이스 유지
- 점진적 마이그레이션 적용
- 호환성 래퍼 제공

### 2. 의존성 관리
- 순환 의존성 방지
- 명확한 의존성 방향 설정
- 인터페이스 기반 결합

### 3. 에러 처리
- 각 모듈별 에러 처리
- 상위 레벨 에러 집계
- 디버깅 정보 제공

## 🎯 성공 기준

### 즉시 목표
- [ ] 컴파일 오류 0개
- [ ] 기존 기능 동작 확인
- [ ] 모듈 간 의존성 최소화

### 중기 목표
- [ ] 단위 테스트 커버리지 80% 이상
- [ ] 성능 향상 15% 이상
- [ ] 코드 복잡도 50% 감소

### 장기 목표
- [ ] 새로운 체인 타입 추가 용이성
- [ ] 확장 가능한 아키텍처
- [ ] 완전한 문서화

---
**작성일**: 2025-07-31  
**작성자**: COGO Agent Core 개발팀  
**우선순위**: 높음 