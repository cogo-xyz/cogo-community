# 현재 컴파일 오류 해결 액션 플랜

## 🚨 현재 상황
- **총 오류 수**: 43개
- **영향받는 파일**: 9개
- **우선순위**: 높음 (서버 안정성에 직접 영향)

## 📋 오류 분류 및 해결 계획

### 1. RecommendationEngine 오류 (5개) - 우선순위 1

#### 문제
```typescript
// KnowledgeResult.results 속성이 존재하지 않음
bestPracticesQuery.results // 오류
```

#### 해결 방법
1. **HybridKnowledgeManager의 queryKnowledge 메서드 반환 타입 확인**
2. **KnowledgeResult 인터페이스에 results 속성 추가 또는 다른 속성명 사용**
3. **RecommendationEngine에서 올바른 속성명으로 접근하도록 수정**

#### 예상 작업 시간: 15분

### 2. AutoCodeFixAgent 오류 (12개) - 우선순위 1

#### 문제 A: Private 메서드 접근 오류
```typescript
this.codeFixProcessor.buildErrorFixPrompt() // 오류
this.codeFixProcessor.generateFix() // 오류
```

#### 해결 방법
1. **CodeFixProcessor의 private 메서드들을 public으로 변경**
2. **또는 별도의 public 래퍼 메서드 생성**

#### 문제 B: 메서드 시그니처 불일치
```typescript
this.codeFixProcessor.buildErrorFixPrompt(code, language, errors)
// errors는 CodeError[]이지만 메서드는 CodeError를 기대
```

#### 해결 방법
1. **buildErrorFixPrompt 메서드 시그니처 수정**
2. **또는 호출하는 쪽에서 개별 error를 전달하도록 수정**

#### 예상 작업 시간: 30분

### 3. CodeFixProcessor 오류 (5개) - 우선순위 1

#### 문제 A: CodeChange 인터페이스 불일치
```typescript
// OpenHandsIntegrationService의 CodeChange
interface CodeChange {
  type: 'insert' | 'delete' | 'replace';
  line: number;
  column: number;
  oldCode: string;
  newCode: string;
}

// CodeFixProcessor의 CodeChange
interface CodeChange {
  type: 'insert' | 'delete' | 'replace';
  line: number;
  column: number;
  oldCode?: string;
  newCode: string;
  description: string; // 추가 속성
}
```

#### 해결 방법
1. **OpenHandsIntegrationService의 CodeChange에 description 속성 추가**
2. **또는 CodeFixProcessor에서 description을 optional로 변경**

#### 문제 B: CodeError 타입 누락
```typescript
errors: [{
  message: string;
  line: number;
  column: number;
  severity: "error";
  code: string;
  // type 속성 누락
}]
```

#### 해결 방법
1. **모든 CodeError 객체에 type 속성 추가**

#### 예상 작업 시간: 20분

### 4. PerformanceOptimizer & TestGenerator 오류 (8개) - 우선순위 2

#### 문제 A: executeCode 메서드 시그니처 불일치
```typescript
await this.openhandsService.executeCode({}) // 오류
// executeCode는 (code: string, language: string)을 기대
```

#### 해결 방법
1. **호출하는 쪽에서 올바른 매개변수 전달**
2. **또는 executeCode 메서드 오버로드 추가**

#### 문제 B: metrics 속성 누락
```typescript
executionResult.metrics.cpuUsage // 오류
executionResult.metrics.throughput // 오류
```

#### 해결 방법
1. **ExecutionResult의 metrics 인터페이스 확장**
2. **또는 기본값으로 fallback 처리**

#### 예상 작업 시간: 25분

### 5. ArchitectureAnalysisAgent 오류 (3개) - 우선순위 1

#### 문제: 누락된 메서드 참조
```typescript
this.detectCircularDependencies(dependencyGraph) // 오류
this.calculateOverallPerformanceScore(performanceMetrics) // 오류
this.calculateRiskLevel(securityAssessment) // 오류
```

#### 해결 방법
1. **이미 제거된 메서드들의 참조를 인라인 값으로 대체**
2. **또는 해당 로직을 적절한 모듈로 이동**

#### 예상 작업 시간: 15분

## 🎯 해결 순서

### Phase 1: 즉시 해결 (1시간 내)
1. **RecommendationEngine 오류 수정** (15분)
2. **ArchitectureAnalysisAgent 오류 수정** (15분)
3. **CodeFixProcessor 타입 오류 수정** (20분)
4. **AutoCodeFixAgent 메서드 접근 오류 수정** (10분)

### Phase 2: 중간 우선순위 (2시간 내)
1. **PerformanceOptimizer & TestGenerator 오류 수정** (25분)
2. **AutoCodeFixAgent 시그니처 오류 수정** (20분)
3. **컴파일 테스트 및 검증** (15분)

### Phase 3: 최종 검증 (30분)
1. **전체 컴파일 테스트**
2. **서버 시작 테스트**
3. **기본 기능 동작 확인**

## 🛠️ 구체적인 수정 방법

### 1. RecommendationEngine 수정
```typescript
// 수정 전
if (bestPracticesQuery.results && bestPracticesQuery.results.length > 0) {

// 수정 후
if (bestPracticesQuery && bestPracticesQuery.length > 0) {
```

### 2. CodeFixProcessor 메서드 public으로 변경
```typescript
// 수정 전
private async generateFix(error: CodeError, code: string, language: string)

// 수정 후
public async generateFix(error: CodeError, code: string, language: string)
```

### 3. OpenHandsIntegrationService 인터페이스 통합
```typescript
// CodeChange 인터페이스 통합
export interface CodeChange {
  type: 'insert' | 'delete' | 'replace';
  line: number;
  column: number;
  oldCode: string;
  newCode: string;
  description?: string; // optional로 추가
}
```

### 4. executeCode 메서드 호출 수정
```typescript
// 수정 전
await this.openhandsService.executeCode({})

// 수정 후
await this.openhandsService.executeCode(code, language)
```

## 📊 예상 결과

### 컴파일 오류 감소
- **현재**: 43개 오류
- **Phase 1 후**: 15개 오류 (65% 감소)
- **Phase 2 후**: 0개 오류 (100% 해결)

### 서버 안정성 향상
- **컴파일 성공률**: 95% → 100%
- **서버 시작 성공률**: 90% → 100%
- **런타임 오류**: 50% 감소 예상

## ⚠️ 주의사항

### 1. 백워드 호환성 유지
- 기존 API 호출 방식 유지
- 점진적 마이그레이션 적용
- 호환성 래퍼 제공

### 2. 타입 안정성 확보
- 모든 타입 오류 해결
- 인터페이스 일관성 유지
- 엄격한 타입 체크 적용

### 3. 테스트 커버리지
- 수정 후 기본 기능 테스트
- 에이전트 동작 확인
- 서버 안정성 검증

## 🎯 성공 기준

### 즉시 목표
- [ ] 컴파일 오류 0개 달성
- [ ] 서버 정상 시작
- [ ] 기본 에이전트 동작 확인

### 중기 목표
- [ ] ArchitectureAnalysisAgent 리팩토링 완료
- [ ] 다음 대용량 에이전트 리팩토링 시작
- [ ] 전체 시스템 안정성 향상

### 장기 목표
- [ ] 모든 대용량 에이전트 모듈화 완료
- [ ] 성능 최적화 완료
- [ ] 문서화 완료

---
**작성일**: 2025-01-XX  
**작성자**: COGO Agent Core 개발팀  
**우선순위**: 높음 