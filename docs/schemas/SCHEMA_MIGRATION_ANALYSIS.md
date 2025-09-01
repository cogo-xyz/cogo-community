# Tree-sitter 적용을 위한 스키마 마이그레이션 분석

## 현재 스키마 분석

### 1. Supabase 현재 스키마

```sql
-- 현재 cogo_source_info 테이블
CREATE TABLE cogo_source_info (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT,
  description TEXT,
  content TEXT,
  language VARCHAR(50),
  framework VARCHAR(100),
  type VARCHAR(50),
  complexity VARCHAR(20),
  features TEXT[],
  api_endpoints JSONB,
  dependencies JSONB,
  examples TEXT[],
  notes TEXT[],
  embedding vector(1536),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. Neo4j 현재 스키마

```cypher
// 현재 CodeComponent 노드
CREATE (c:CodeComponent {
  id: $id,
  title: $title,
  description: $description,
  content: $content,
  language: $language,
  framework: $framework,
  type: $type,
  complexity: $complexity,
  createdAt: datetime()
});

// 현재 관계
CREATE (c:CodeComponent)-[:HAS_FEATURE]->(f:Feature {name: $name});
CREATE (c:CodeComponent)-[:HAS_API]->(a:API {name: $name, description: $description});
CREATE (c:CodeComponent)-[:DEPENDS_ON]->(d:Dependency {name: $name, type: $type});
```

## Tree-sitter 적용에 따른 스키마 변경 필요성

### 1. **높은 우선순위 변경사항**

#### A. AST 데이터 저장
**필요성**: Tree-sitter는 구문 트리(AST)를 생성하므로, 이를 저장할 수 있는 구조가 필요합니다.

```sql
-- 새로운 테이블: ast_nodes
CREATE TABLE ast_nodes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_info_id UUID REFERENCES cogo_source_info(id),
  node_type VARCHAR(100) NOT NULL,
  node_name TEXT,
  start_line INTEGER,
  end_line INTEGER,
  start_column INTEGER,
  end_column INTEGER,
  parent_node_id UUID REFERENCES ast_nodes(id),
  node_text TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### B. 정밀한 코드 구조 정보
**필요성**: 현재 스키마는 일반적인 메타데이터만 저장하지만, Tree-sitter는 함수 시그니처, 클래스 구조, 메서드 정의 등 정밀한 정보를 제공합니다.

```sql
-- cogo_source_info 테이블 확장
ALTER TABLE cogo_source_info ADD COLUMN signature TEXT;
ALTER TABLE cogo_source_info ADD COLUMN implementation TEXT;
ALTER TABLE cogo_source_info ADD COLUMN imports JSONB;
ALTER TABLE cogo_source_info ADD COLUMN external_calls JSONB;
ALTER TABLE cogo_source_info ADD COLUMN internal_dependencies JSONB;
ALTER TABLE cogo_source_info ADD COLUMN complexity_metrics JSONB;
ALTER TABLE cogo_source_info ADD COLUMN ast_data JSONB;
```

#### C. 코드 관계 모델링
**필요성**: Tree-sitter는 함수 호출, 클래스 상속, 인터페이스 구현 등의 관계를 정확히 파악할 수 있습니다.

```sql
-- 새로운 테이블: code_relationships
CREATE TABLE code_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_component_id UUID REFERENCES cogo_source_info(id),
  target_component_id UUID REFERENCES cogo_source_info(id),
  relationship_type VARCHAR(50) NOT NULL, -- 'calls', 'extends', 'implements', 'imports'
  relationship_metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. **중간 우선순위 변경사항**

#### A. 파일 경로 및 위치 정보
**필요성**: Tree-sitter는 정확한 라인/컬럼 위치를 제공하므로, 이를 저장할 수 있는 구조가 필요합니다.

```sql
-- cogo_source_info 테이블 확장
ALTER TABLE cogo_source_info ADD COLUMN file_path TEXT;
ALTER TABLE cogo_source_info ADD COLUMN start_line INTEGER;
ALTER TABLE cogo_source_info ADD COLUMN end_line INTEGER;
ALTER TABLE cogo_source_info ADD COLUMN start_column INTEGER;
ALTER TABLE cogo_source_info ADD COLUMN end_column INTEGER;
```

#### B. 컴포넌트 타입 세분화
**필요성**: Tree-sitter는 함수, 클래스, 인터페이스, 메서드 등을 정확히 구분할 수 있습니다.

```sql
-- cogo_source_info 테이블 확장
ALTER TABLE cogo_source_info ADD COLUMN component_type VARCHAR(100); -- 'function', 'class', 'interface', 'method'
ALTER TABLE cogo_source_info ADD COLUMN component_name TEXT;
```

### 3. **낮은 우선순위 변경사항**

#### A. 성능 최적화 인덱스
**필요성**: AST 쿼리 성능 향상을 위한 인덱스가 필요합니다.

```sql
-- 성능 최적화 인덱스
CREATE INDEX idx_ast_nodes_source_info_id ON ast_nodes(source_info_id);
CREATE INDEX idx_ast_nodes_node_type ON ast_nodes(node_type);
CREATE INDEX idx_ast_nodes_start_line ON ast_nodes(start_line);
CREATE INDEX idx_code_relationships_source ON code_relationships(source_component_id);
CREATE INDEX idx_code_relationships_target ON code_relationships(target_component_id);
CREATE INDEX idx_code_relationships_type ON code_relationships(relationship_type);
```

## Neo4j 스키마 변경사항

### 1. **AST 노드 추가**

```cypher
// AST Node 노드 추가
CREATE (n:ASTNode {
  id: $id,
  nodeType: $nodeType,
  nodeName: $nodeName,
  startLine: $startLine,
  endLine: $endLine,
  startColumn: $startColumn,
  endColumn: $endColumn,
  nodeText: $nodeText,
  metadata: $metadata
});

// CodeComponent와 ASTNode 관계
CREATE (c:CodeComponent)-[:HAS_AST_NODE]->(n:ASTNode);
CREATE (n:ASTNode)-[:PARENT_OF]->(child:ASTNode);
```

### 2. **정밀한 코드 관계**

```cypher
// 정밀한 코드 관계 추가
CREATE (source:CodeComponent)-[:CALLS]->(target:CodeComponent);
CREATE (source:CodeComponent)-[:EXTENDS]->(target:CodeComponent);
CREATE (source:CodeComponent)-[:IMPLEMENTS]->(target:CodeComponent);
CREATE (source:CodeComponent)-[:IMPORTS]->(target:CodeComponent);
CREATE (source:CodeComponent)-[:OVERRIDES]->(target:CodeComponent);
```

### 3. **파일 구조 모델링**

```cypher
// 파일 구조 노드
CREATE (f:File {
  path: $path,
  name: $name,
  extension: $extension,
  language: $language
});

// 파일과 컴포넌트 관계
CREATE (f:File)-[:CONTAINS]->(c:CodeComponent);
```

## 마이그레이션 계획

### Phase 1: 기본 구조 확장 (1-2주)

1. **Supabase 마이그레이션**
   ```sql
   -- 1단계: 새 컬럼 추가
   ALTER TABLE cogo_source_info ADD COLUMN signature TEXT;
   ALTER TABLE cogo_source_info ADD COLUMN file_path TEXT;
   ALTER TABLE cogo_source_info ADD COLUMN component_type VARCHAR(100);
   ALTER TABLE cogo_source_info ADD COLUMN component_name TEXT;
   
   -- 2단계: 새 테이블 생성
   CREATE TABLE ast_nodes (...);
   CREATE TABLE code_relationships (...);
   ```

2. **Neo4j 마이그레이션**
   ```cypher
   // 1단계: 새 노드 타입 추가
   CREATE (n:ASTNode {...});
   
   // 2단계: 새 관계 타입 추가
   CREATE (source:CodeComponent)-[:CALLS]->(target:CodeComponent);
   ```

### Phase 2: 데이터 마이그레이션 (2-3주)

1. **기존 데이터 변환**
   - 현재 `content` 필드의 코드를 Tree-sitter로 재파싱
   - AST 데이터 추출 및 저장
   - 관계 정보 재구성

2. **데이터 검증**
   - 마이그레이션된 데이터의 정확성 검증
   - 성능 테스트 및 최적화

### Phase 3: 인덱스 및 최적화 (1주)

1. **성능 최적화**
   - 필요한 인덱스 추가
   - 쿼리 최적화
   - 캐싱 전략 구현

## 마이그레이션 위험도 분석

### 1. **높은 위험도**

#### A. 데이터 손실 위험
- **위험**: 기존 데이터 변환 과정에서 정보 손실 가능
- **완화책**: 
  - 단계별 마이그레이션
  - 백업 및 롤백 계획
  - 데이터 검증 자동화

#### B. 성능 저하 위험
- **위험**: AST 데이터 저장으로 인한 성능 저하
- **완화책**:
  - 인덱스 최적화
  - 캐싱 전략
  - 점진적 마이그레이션

### 2. **중간 위험도**

#### A. 호환성 문제
- **위험**: 기존 API와의 호환성 문제
- **완화책**:
  - 하위 호환성 유지
  - API 버전 관리
  - 점진적 API 업데이트

### 3. **낮은 위험도**

#### A. 개발 복잡성 증가
- **위험**: Tree-sitter 도입으로 인한 개발 복잡성 증가
- **완화책**:
  - 명확한 아키텍처 설계
  - 문서화 및 테스트
  - 개발자 교육

## 권장사항

### 1. **단계적 접근**
- 한 번에 모든 변경을 적용하지 말고 단계별로 진행
- 각 단계마다 검증 및 테스트 수행

### 2. **백업 및 롤백 계획**
- 마이그레이션 전 완전한 백업
- 각 단계별 롤백 계획 수립

### 3. **성능 모니터링**
- 마이그레이션 전후 성능 비교
- 지속적인 성능 모니터링

### 4. **문서화**
- 마이그레이션 과정 문서화
- 새로운 스키마 사용법 가이드 작성

## 결론

Tree-sitter 적용을 위한 스키마 변경은 **필수적**이며, 특히 AST 데이터 저장과 정밀한 코드 구조 정보 저장을 위한 변경이 우선적으로 필요합니다. 단계적 마이그레이션을 통해 위험을 최소화하면서 고성능 파싱 시스템을 구축할 수 있습니다. 