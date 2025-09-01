# MentoringPoolManager.ts 리팩토링 계획

## 📋 파일 분석

### 현재 상태
- **파일 크기**: 21KB, 694줄
- **복잡도**: 높음 (여러 책임을 가짐)
- **우선순위**: 2 (두 번째 큰 파일)

### 주요 책임들
1. **멘토/멘티 프로필 관리** - MentorProfile, MenteeProfile
2. **매칭 시스템** - MentoringMatch, 매칭 알고리즘
3. **세션 관리** - MentoringSession, 세션 라이프사이클
4. **상호작용 관리** - MentoringInteraction, 피드백
5. **지식 그래프 업데이트** - 학습 결과 저장
6. **백그라운드 프로세스** - 모니터링, 큐 처리

## 🎯 모듈화 계획

### 1. ProfileManager (프로필 관리)
**파일**: `src/agents/mentoring/ProfileManager.ts`
**책임**:
- 멘토/멘티 프로필 등록/관리
- 프로필 업데이트
- 가용성 관리

**인터페이스**:
```typescript
export interface ProfileManager {
  registerMentor(profile: MentorProfile): void;
  registerMentee(profile: MenteeProfile): void;
  getMentorProfile(mentorId: string): MentorProfile | null;
  getMenteeProfile(menteeId: string): MenteeProfile | null;
  updateMentorAvailability(mentorId: string, available: boolean): void;
  getAvailableMentors(): MentorProfile[];
}
```

### 2. MatchmakingEngine (매칭 엔진)
**파일**: `src/agents/mentoring/MatchmakingEngine.ts`
**책임**:
- 최적 멘토 찾기
- 매칭 점수 계산
- 호환성 분석

**인터페이스**:
```typescript
export interface MatchmakingEngine {
  findOptimalMentor(menteeId: string, task: Task): Promise<MentoringMatch | null>;
  calculateMatchScore(mentor: MentorProfile, mentee: MenteeProfile, task: Task): Promise<number>;
  generateMatchReasoning(mentor: MentorProfile, mentee: MenteeProfile, task: Task): Promise<string[]>;
}
```

### 3. SessionManager (세션 관리)
**파일**: `src/agents/mentoring/SessionManager.ts`
**책임**:
- 세션 생성/관리
- 세션 진행률 추적
- 세션 완료 처리

**인터페이스**:
```typescript
export interface SessionManager {
  createSession(mentorId: string, menteeId: string, taskId: string, sessionType: string, objectives: string[]): Promise<MentoringSession>;
  addInteraction(sessionId: string, interaction: MentoringInteraction): Promise<void>;
  completeSession(sessionId: string): Promise<void>;
  getActiveSessions(): MentoringSession[];
  getSessionProgress(sessionId: string): any;
}
```

### 4. InteractionManager (상호작용 관리)
**파일**: `src/agents/mentoring/InteractionManager.ts`
**책임**:
- 상호작용 기록
- 피드백 관리
- 효과성 분석

**인터페이스**:
```typescript
export interface InteractionManager {
  addInteraction(sessionId: string, interaction: MentoringInteraction): Promise<void>;
  addFeedback(feedback: MentoringFeedback): Promise<void>;
  calculateInteractionEffectiveness(interactions: MentoringInteraction[]): number;
  getFeedbackHistory(agentId: string): MentoringFeedback[];
}
```

### 5. KnowledgeIntegrator (지식 통합)
**파일**: `src/agents/mentoring/KnowledgeIntegrator.ts`
**책임**:
- 세션 결과를 지식 그래프에 통합
- 학습 패턴 분석
- 지식 업데이트

**인터페이스**:
```typescript
export interface KnowledgeIntegrator {
  updateKnowledgeGraph(session: MentoringSession): Promise<void>;
  analyzeLearningPatterns(menteeId: string): Promise<any>;
  extractKeyInsights(session: MentoringSession): Promise<string[]>;
}
```

### 6. BackgroundProcessor (백그라운드 처리)
**파일**: `src/agents/mentoring/BackgroundProcessor.ts`
**책임**:
- 매칭 큐 처리
- 세션 모니터링
- 정기 업데이트

**인터페이스**:
```typescript
export interface BackgroundProcessor {
  startMonitoring(): void;
  stopMonitoring(): void;
  processMatchmakingQueue(): Promise<void>;
  monitorActiveSessions(): Promise<void>;
  updateSystemMetrics(): Promise<void>;
}
```

## 🔄 리팩토링 순서

### Phase 1: 기반 모듈 생성 (1.5시간)
1. **ProfileManager** 생성
2. **InteractionManager** 생성
3. **KnowledgeIntegrator** 생성

### Phase 2: 핵심 로직 분리 (2시간)
1. **MatchmakingEngine** 생성
2. **SessionManager** 생성
3. **BackgroundProcessor** 생성

### Phase 3: 메인 클래스 리팩토링 (1시간)
1. **MentoringPoolManager** 클래스 간소화
2. **의존성 주입** 적용
3. **인터페이스 통합**

### Phase 4: 테스트 및 검증 (30분)
1. **컴파일 테스트**
2. **기본 기능 동작 확인**
3. **성능 검증**

## 📊 예상 결과

### 코드 품질 향상
- **파일 크기**: 694줄 → 평균 115줄 (83% 감소)
- **순환 복잡도**: 평균 18 → 9 (50% 감소)
- **책임 분리**: 단일 책임 원칙 준수

### 유지보수성 향상
- **모듈화**: 6개 독립적인 모듈
- **테스트 용이성**: 각 모듈별 단위 테스트 가능
- **확장성**: 새로운 기능 추가 용이

### 성능 개선
- **메모리 사용량**: 25% 감소 예상
- **실행 속도**: 20% 향상 예상
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

### 3. 이벤트 처리
- EventEmitter 패턴 유지
- 이벤트 기반 통신 보장
- 비동기 처리 최적화

## 🎯 성공 기준

### 즉시 목표
- [ ] 컴파일 오류 0개
- [ ] 기존 기능 동작 확인
- [ ] 모듈 간 의존성 최소화

### 중기 목표
- [ ] 단위 테스트 커버리지 80% 이상
- [ ] 성능 향상 20% 이상
- [ ] 코드 복잡도 50% 감소

### 장기 목표
- [ ] 새로운 매칭 알고리즘 추가 용이성
- [ ] 확장 가능한 아키텍처
- [ ] 완전한 문서화

---
**작성일**: 2025-07-31  
**작성자**: COGO Agent Core 개발팀  
**우선순위**: 높음 