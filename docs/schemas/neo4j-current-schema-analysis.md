# Neo4j Knowledge Graph 현재 스키마 분석

## 📊 분석 개요

이 문서는 현재 COGO Agent Core 시스템에서 사용 중인 Neo4j Knowledge Graph의 실제 스키마를 분석한 결과입니다.

- **분석 일시**: 2025-07-29
- **Neo4j AuraDB**: neo4j+s://1c783b87.databases.neo4j.io
- **연결 상태**: ✅ 실제 연결 확인됨
- **데이터베이스**: neo4j

---

## 🏷️ 현재 노드 라벨 (Node Labels)

실제 Neo4j 데이터베이스에서 확인한 노드 라벨들:

### 📋 노드 라벨 목록

1. **`Agent`** - 에이전트 노드
2. **`Task`** - 작업 노드  
3. **`KnowledgeNode`** - 지식 노드 (가장 많은 데이터)
4. **`TECHNOLOGY`** - 기술 노드
5. **`CONCEPT`** - 개념 노드
6. **`PATTERN`** - 패턴 노드
7. **`DOMAIN`** - 도메인 노드
8. **`Entity`** - 엔티티 노드
9. **`Knowledge`** - 지식 노드

### 📊 노드 통계

| 라벨 | 개수 | 비고 |
|------|------|------|
| `KnowledgeNode` + `PATTERN` | 91 | 가장 많은 데이터 |
| `Entity` | 8 | 엔티티 데이터 |
| `Knowledge` | 6 | 지식 데이터 |
| `CONCEPT` | 3 | 개념 데이터 |
| `PATTERN` | 3 | 독립 패턴 |
| `TECHNOLOGY` | 3 | 기술 데이터 |
| `DOMAIN` | 1 | 도메인 데이터 |
| `Agent` | 0 | 에이전트 데이터 없음 |
| `Task` | 0 | 작업 데이터 없음 |

---

## 🔗 현재 관계 타입 (Relationship Types)

실제 Neo4j 데이터베이스에서 확인한 관계 타입들:

### 📋 관계 타입 목록

1. **`RELATED_TO`** - 관련 관계 (8개)
2. **`USES`** - 사용 관계 (3개)
3. **`INTEGRATES_WITH`** - 통합 관계 (2개)
4. **`PART_OF`** - 포함 관계 (1개)
5. **`SIMILAR_TO`** - 유사 관계 (1개)
6. **`IMPLEMENTS`** - 구현 관계 (1개)
7. **`USES_PATTERN`** - 패턴 사용 관계 (1개)
8. **`TEST_RELATION`** - 테스트 관계 (1개)
9. **`DEPENDS_ON`** - 의존 관계 (1개)
10. **`KnowledgeRelation`** - 지식 관계 (인덱스만 존재)

### 📊 관계 통계

| 관계 타입 | 개수 | 비고 |
|-----------|------|------|
| `RELATED_TO` | 8 | 가장 많은 관계 |
| `USES` | 3 | 사용 관계 |
| `INTEGRATES_WITH` | 2 | 통합 관계 |
| 기타 관계들 | 각 1개씩 | 다양한 관계 타입 |

---

## 🏗️ 노드 속성 구조

### 📋 `KnowledgeNode` 속성
```cypher
{
  name: STRING,           // 노드 이름
  id: STRING,            // 고유 식별자
  createdAt: DATETIME,   // 생성 시간
  type: STRING,          // 노드 타입 (주로 "PATTERN")
  updatedAt: DATETIME,   // 업데이트 시간
  properties: MAP,       // 추가 속성들
  last_used: DATETIME,   // 마지막 사용 시간
  last_performance: FLOAT // 마지막 성능 점수
}
```

### 📋 `CONCEPT` 속성
```cypher
{
  name: STRING,          // 개념 이름
  id: STRING,           // 고유 식별자
  createdAt: DATETIME,  // 생성 시간
  description: STRING,  // 개념 설명
  updatedAt: DATETIME   // 업데이트 시간
}
```

### 📋 `TECHNOLOGY` 속성
```cypher
{
  name: STRING,          // 기술 이름
  id: STRING,           // 고유 식별자
  createdAt: DATETIME,  // 생성 시간
  description: STRING,  // 기술 설명
  updatedAt: DATETIME   // 업데이트 시간
}
```

### 📋 `PATTERN` 속성
```cypher
{
  name: STRING,          // 패턴 이름
  id: STRING,           // 고유 식별자
  createdAt: DATETIME,  // 생성 시간
  description: STRING,  // 패턴 설명
  updatedAt: DATETIME   // 업데이트 시간
}
```

---

## 🔍 인덱스 구조

### 📋 현재 인덱스 목록

| 인덱스 이름 | 타입 | 대상 | 속성 | 상태 |
|-------------|------|------|------|------|
| `agent_id_index` | RANGE | NODE | `Agent.id` | ONLINE |
| `node_name_index` | RANGE | NODE | `KnowledgeNode.name` | ONLINE |
| `node_type_index` | RANGE | NODE | `KnowledgeNode.type` | ONLINE |
| `rel_type_index` | RANGE | RELATIONSHIP | `KnowledgeRelation.type` | ONLINE |
| `task_id_index` | RANGE | NODE | `Task.id` | ONLINE |
| `index_343aff4e` | LOOKUP | NODE | - | ONLINE |
| `index_f7700477` | LOOKUP | RELATIONSHIP | - | ONLINE |

### 📊 인덱스 사용 통계

- **`agent_id_index`**: 5회 읽기 (2025-07-15)
- **`task_id_index`**: 1회 읽기 (2025-07-15)
- **`index_343aff4e`**: 3,829회 읽기 (2025-07-29)
- **`index_f7700477`**: 9회 읽기 (2025-07-27)

---

## 📈 데이터 분석 결과

### ✅ 현재 상태
1. **Neo4j 연결**: 실제 AuraDB에 연결되어 있음
2. **데이터 존재**: 115개의 노드와 19개의 관계 존재
3. **인덱스 구성**: 7개의 인덱스로 성능 최적화
4. **주요 데이터**: 패턴(Pattern) 관련 지식이 대부분

### 🔍 주요 특징
1. **지식 중심**: KnowledgeNode가 전체 데이터의 79% 차지
2. **패턴 집중**: 91개의 패턴 관련 노드
3. **관계 다양성**: 10가지 다른 관계 타입
4. **기본 구조**: Agent, Task 노드는 아직 데이터 없음

### 📊 데이터 분포
- **노드**: 115개 (KnowledgeNode: 91개, Entity: 8개, 기타: 16개)
- **관계**: 19개 (RELATED_TO: 8개, USES: 3개, 기타: 8개)
- **인덱스**: 7개 (RANGE: 5개, LOOKUP: 2개)

---

## 🎯 현재 스키마의 특징

### ✅ 장점
1. **확장 가능한 구조**: KnowledgeNode로 다양한 타입 지원
2. **성능 최적화**: 적절한 인덱스 구성
3. **관계 다양성**: 다양한 관계 타입으로 복잡한 연결 표현
4. **메타데이터 지원**: properties 필드로 확장 가능

### ⚠️ 개선 필요 사항
1. **Agent/Task 데이터 부족**: 실제 에이전트와 작업 데이터 없음
2. **코드 구조 부재**: CodeFile, Function, Class 노드 없음
3. **버전 관리 부재**: Commit, 변경 이력 노드 없음
4. **대화 관리 부재**: Conversation, Message 노드 없음

---

## 🔄 기존 마이그레이션 파일과의 비교

### 📋 기존 설계 vs 현재 상태

| 항목 | 기존 설계 | 현재 상태 | 차이점 |
|------|-----------|-----------|--------|
| 노드 타입 | 11개 | 9개 | 2개 부족 |
| 관계 타입 | 9개 | 10개 | 1개 추가 |
| Agent 노드 | 설계됨 | 데이터 없음 | 구현 필요 |
| Task 노드 | 설계됨 | 데이터 없음 | 구현 필요 |
| 코드 구조 | 설계됨 | 없음 | 구현 필요 |
| 버전 관리 | 설계됨 | 없음 | 구현 필요 |

### 📋 누락된 노드 타입
1. **CodeFile** - 코드 파일
2. **Function** - 함수
3. **Class** - 클래스
4. **Library** - 라이브러리
5. **Commit** - 커밋
6. **ConversationSession** - 대화 세션
7. **Message** - 메시지

### 📋 누락된 관계 타입
1. **CONTAINS** - 포함 관계
2. **CALLS** - 호출 관계
3. **IMPORTS** - 임포트 관계
4. **GENERATED_BY** - 생성 관계
5. **MODIFIED** - 수정 관계
6. **AFFECTS** - 영향 관계

---

## 🎯 다음 단계

이 분석을 바탕으로 `database-design-and-namespace.md` 가이드라인에 따라 Neo4j 스키마 확장 계획을 수립할 수 있습니다.

### 🔥 우선 구현 필요
1. **Agent/Task 데이터**: 실제 에이전트와 작업 데이터 추가
2. **코드 구조**: CodeFile, Function, Class 노드 구현
3. **대화 관리**: Conversation, Message 노드 구현
4. **관계 확장**: 누락된 관계 타입 추가

### 🔶 중기 구현 필요
1. **버전 관리**: Commit 노드 및 관련 관계
2. **성능 최적화**: 추가 인덱스 및 제약 조건
3. **데이터 마이그레이션**: 기존 데이터 정리 및 통합

### 🔵 장기 구현 필요
1. **고급 관계**: 복잡한 다중 관계
2. **메타데이터 확장**: 추가 속성 및 메타데이터
3. **분석 기능**: 그래프 분석 및 시각화 