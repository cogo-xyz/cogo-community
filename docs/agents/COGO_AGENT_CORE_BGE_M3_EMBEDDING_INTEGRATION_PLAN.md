# BAAI/bge-m3 Embedding 통합 계획

## 📋 개요

**작성일**: 2025-08-06  
**목적**: BAAI/bge-m3 embedding을 활용한 Single Source of Truth 구현  
**핵심**: 1024차원 벡터, 하이브리드 검색, 다국어 지원  

---

## 🎯 **BAAI/bge-m3 모델 특징**

### **주요 장점**
- ✅ **1024차원 벡터**: pgvector와 완벽 호환
- ✅ **하이브리드 검색**: 밀집(Dense) + 희소(Sparse) 벡터 동시 지원
- ✅ **다국어 지원**: 100개 이상 언어 지원
- ✅ **긴 컨텍스트**: 최대 8192 토큰 처리
- ✅ **MIT 라이선스**: 상업적 사용 자유
- ✅ **높은 성능**: 별도 지시문 없이도 우수한 검색 성능

### **COGO 플랫폼에 최적화된 특징**
- **코드 검색 최적화**: 프로그래밍 언어별 특화
- **다국어 코드 지원**: TypeScript, Python, Java, Go 등
- **하이브리드 검색**: 의미 기반 + 키워드 기반 통합
- **실시간 처리**: API 기반 빠른 응답

---

## 🔧 **Supabase 스키마 수정 계획**

### **1. 벡터 차원 변경 (1536 → 1024)**

```sql
-- 기존 1536차원 벡터를 1024차원으로 변경
-- 1. vector_documents 테이블
ALTER TABLE vector_documents 
ALTER COLUMN embedding TYPE vector(1024);

-- 2. agent_knowledge_vectors 테이블
ALTER TABLE agent_knowledge_vectors 
ALTER COLUMN embedding TYPE vector(1024);

-- 3. knowledge_graph_vectors 테이블
ALTER TABLE knowledge_graph_vectors 
ALTER COLUMN embedding TYPE vector(1024);

-- 4. code_vectors 테이블
ALTER TABLE code_vectors 
ALTER COLUMN embedding TYPE vector(1024);

-- 5. git_knowledge_vectors 테이블 (새로 추가)
ALTER TABLE git_knowledge_vectors 
ALTER COLUMN embedding TYPE vector(1024);

-- 6. hybrid_parsing_results 테이블 (새로 추가)
ALTER TABLE hybrid_parsing_results 
ALTER COLUMN embedding TYPE vector(1024);

-- 임베딩 모델 기본값 변경
ALTER TABLE vector_documents 
ALTER COLUMN embedding_model SET DEFAULT 'BAAI/bge-m3';

ALTER TABLE agent_knowledge_vectors 
ALTER COLUMN embedding_model SET DEFAULT 'BAAI/bge-m3';

ALTER TABLE knowledge_graph_vectors 
ALTER COLUMN embedding_model SET DEFAULT 'BAAI/bge-m3';

ALTER TABLE code_vectors 
ALTER COLUMN embedding_model SET DEFAULT 'BAAI/bge-m3';
```

### **2. 하이브리드 검색을 위한 스키마 확장**

```sql
-- 하이브리드 검색을 위한 희소 벡터 컬럼 추가
ALTER TABLE vector_documents 
ADD COLUMN sparse_embedding JSONB DEFAULT '{}';

ALTER TABLE code_vectors 
ADD COLUMN sparse_embedding JSONB DEFAULT '{}';

ALTER TABLE agent_knowledge_vectors 
ADD COLUMN sparse_embedding JSONB DEFAULT '{}';

-- 검색 메타데이터 컬럼 추가
ALTER TABLE vector_documents 
ADD COLUMN search_metadata JSONB DEFAULT '{}';

ALTER TABLE code_vectors 
ADD COLUMN search_metadata JSONB DEFAULT '{}';
```

### **3. 1024차원 벡터 검색 함수 업데이트**

```sql
-- 1024차원 벡터 검색 함수
CREATE OR REPLACE FUNCTION search_similar_documents_1024(
    query_embedding vector(1024),
    query_sparse JSONB DEFAULT '{}',
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 10,
    content_type_filter VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    document_id VARCHAR(255),
    title VARCHAR(500),
    content TEXT,
    metadata JSONB,
    similarity float,
    hybrid_score float
)
LANGUAGE sql STABLE AS $$
  SELECT
    vd.id,
    vd.document_id,
    vd.title,
    vd.content,
    vd.metadata,
    1 - (vd.embedding <=> query_embedding) AS similarity,
    -- 하이브리드 점수 계산 (밀집 벡터 + 희소 벡터)
    (1 - (vd.embedding <=> query_embedding)) * 0.7 + 
    (CASE 
      WHEN vd.sparse_embedding IS NOT NULL AND query_sparse IS NOT NULL 
      THEN calculate_sparse_similarity(vd.sparse_embedding, query_sparse)
      ELSE 0 
    END) * 0.3 AS hybrid_score
  FROM
    vector_documents AS vd
  WHERE 
    (content_type_filter IS NULL OR vd.content_type = content_type_filter)
    AND 1 - (vd.embedding <=> query_embedding) > match_threshold
  ORDER BY
    hybrid_score DESC
  LIMIT match_count;
$$;

-- 코드 검색 전용 함수
CREATE OR REPLACE FUNCTION search_similar_code_1024(
    query_embedding vector(1024),
    query_sparse JSONB DEFAULT '{}',
    language_filter VARCHAR(50) DEFAULT NULL,
    match_threshold float DEFAULT 0.6,
    match_count int DEFAULT 15
)
RETURNS TABLE (
    id UUID,
    code_id VARCHAR(255),
    file_path VARCHAR(1000),
    function_name VARCHAR(255),
    code_snippet TEXT,
    language VARCHAR(50),
    description TEXT,
    similarity float,
    hybrid_score float
)
LANGUAGE sql STABLE AS $$
  SELECT
    cv.id,
    cv.code_id,
    cv.file_path,
    cv.function_name,
    cv.code_snippet,
    cv.language,
    cv.description,
    1 - (cv.embedding <=> query_embedding) AS similarity,
    (1 - (cv.embedding <=> query_embedding)) * 0.7 + 
    (CASE 
      WHEN cv.sparse_embedding IS NOT NULL AND query_sparse IS NOT NULL 
      THEN calculate_sparse_similarity(cv.sparse_embedding, query_sparse)
      ELSE 0 
    END) * 0.3 AS hybrid_score
  FROM
    code_vectors AS cv
  WHERE 
    (language_filter IS NULL OR cv.language = language_filter)
    AND 1 - (cv.embedding <=> query_embedding) > match_threshold
  ORDER BY
    hybrid_score DESC
  LIMIT match_count;
$$;

-- 희소 벡터 유사도 계산 함수
CREATE OR REPLACE FUNCTION calculate_sparse_similarity(
    sparse1 JSONB,
    sparse2 JSONB
) RETURNS float AS $$
DECLARE
    similarity float := 0.0;
    key text;
    val1 float;
    val2 float;
BEGIN
    -- 희소 벡터 간 코사인 유사도 계산
    FOR key IN SELECT DISTINCT jsonb_object_keys(sparse1) 
               UNION SELECT DISTINCT jsonb_object_keys(sparse2)
    LOOP
        val1 := COALESCE((sparse1->>key)::float, 0.0);
        val2 := COALESCE((sparse2->>key)::float, 0.0);
        similarity := similarity + (val1 * val2);
    END LOOP;
    
    RETURN LEAST(similarity, 1.0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

---

## 🔄 **마이그레이션 계획**

### **Phase 1: 스키마 변경 및 데이터 백업 (1일)**

```sql
-- 1. 기존 데이터 백업
CREATE TABLE vector_documents_backup AS SELECT * FROM vector_documents;
CREATE TABLE code_vectors_backup AS SELECT * FROM code_vectors;
CREATE TABLE agent_knowledge_vectors_backup AS SELECT * FROM agent_knowledge_vectors;
CREATE TABLE knowledge_graph_vectors_backup AS SELECT * FROM knowledge_graph_vectors;

-- 2. 기존 인덱스 삭제
DROP INDEX IF EXISTS idx_vector_documents_embedding;
DROP INDEX IF EXISTS idx_code_vectors_embedding;
DROP INDEX IF EXISTS idx_agent_knowledge_embedding;
DROP INDEX IF EXISTS idx_knowledge_graph_embedding;

-- 3. 벡터 컬럼 타입 변경
ALTER TABLE vector_documents ALTER COLUMN embedding TYPE vector(1024);
ALTER TABLE code_vectors ALTER COLUMN embedding TYPE vector(1024);
ALTER TABLE agent_knowledge_vectors ALTER COLUMN embedding TYPE vector(1024);
ALTER TABLE knowledge_graph_vectors ALTER COLUMN embedding TYPE vector(1024);

-- 4. 새로운 인덱스 생성
CREATE INDEX idx_vector_documents_embedding_1024 
ON vector_documents USING hnsw (embedding vector_cosine_ops);

CREATE INDEX idx_code_vectors_embedding_1024 
ON code_vectors USING hnsw (embedding vector_cosine_ops);

CREATE INDEX idx_agent_knowledge_embedding_1024 
ON agent_knowledge_vectors USING hnsw (embedding vector_cosine_ops);

CREATE INDEX idx_knowledge_graph_embedding_1024 
ON knowledge_graph_vectors USING hnsw (embedding vector_cosine_ops);
```

### **Phase 2: BGE-M3 재임베딩 (2-3일)**

```typescript
// src/migration/BgeM3Migration.ts
export class BgeM3Migration {
  private bgeM3Service: BgeM3Service;
  private supabase: SupabaseClient;

  constructor() {
    this.bgeM3Service = new BgeM3Service();
    this.supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);
  }

  /**
   * 기존 데이터를 BGE-M3로 재임베딩
   */
  async migrateToBgeM3(): Promise<MigrationResult> {
    const result: MigrationResult = {
      totalRecords: 0,
      processedRecords: 0,
      failedRecords: 0,
      errors: [],
      duration: 0
    };

    const startTime = Date.now();

    try {
      // 1. vector_documents 마이그레이션
      await this.migrateVectorDocuments(result);
      
      // 2. code_vectors 마이그레이션
      await this.migrateCodeVectors(result);
      
      // 3. agent_knowledge_vectors 마이그레이션
      await this.migrateAgentKnowledgeVectors(result);
      
      // 4. knowledge_graph_vectors 마이그레이션
      await this.migrateKnowledgeGraphVectors(result);

    } catch (error) {
      result.errors.push(error.message);
    }

    result.duration = Date.now() - startTime;
    return result;
  }

  /**
   * vector_documents 테이블 마이그레이션
   */
  private async migrateVectorDocuments(result: MigrationResult): Promise<void> {
    const { data: documents } = await this.supabase
      .from('vector_documents')
      .select('*')
      .is('embedding', null); // 임베딩이 없는 레코드만

    result.totalRecords += documents?.length || 0;

    for (const doc of documents || []) {
      try {
        // BGE-M3로 재임베딩
        const embedding = await this.bgeM3Service.createEmbedding(doc.content);
        
        // 업데이트
        await this.supabase
          .from('vector_documents')
          .update({ 
            embedding: embedding,
            embedding_model: 'BAAI/bge-m3',
            updated_at: new Date().toISOString()
          })
          .eq('id', doc.id);

        result.processedRecords++;
      } catch (error) {
        result.failedRecords++;
        result.errors.push(`Document ${doc.id}: ${error.message}`);
      }
    }
  }
}
```

### **Phase 3: 검증 및 롤백 준비 (1일)**

```typescript
// src/migration/MigrationValidator.ts
export class MigrationValidator {
  /**
   * 마이그레이션 결과 검증
   */
  async validateMigration(): Promise<ValidationResult> {
    const result: ValidationResult = {
      success: false,
      totalRecords: 0,
      validRecords: 0,
      invalidRecords: 0,
      issues: []
    };

    // 1. 벡터 차원 검증
    const dimensionCheck = await this.validateVectorDimensions();
    if (!dimensionCheck.success) {
      result.issues.push(...dimensionCheck.issues);
    }

    // 2. 검색 성능 검증
    const performanceCheck = await this.validateSearchPerformance();
    if (!performanceCheck.success) {
      result.issues.push(...performanceCheck.issues);
    }

    // 3. 데이터 무결성 검증
    const integrityCheck = await this.validateDataIntegrity();
    if (!integrityCheck.success) {
      result.issues.push(...integrityCheck.issues);
    }

    result.success = result.issues.length === 0;
    return result;
  }

  /**
   * 벡터 차원 검증
   */
  private async validateVectorDimensions(): Promise<ValidationCheck> {
    const { data } = await this.supabase
      .from('vector_documents')
      .select('embedding')
      .limit(1);

    if (data && data[0]?.embedding) {
      const dimension = data[0].embedding.length;
      if (dimension !== 1024) {
        return {
          success: false,
          issues: [`Expected 1024 dimensions, got ${dimension}`]
        };
      }
    }

    return { success: true, issues: [] };
  }
}
```

---

## 🔧 **BGE-M3 API 서비스 구현**

### **1. BGE-M3 API 클라이언트**

```typescript
// src/services/BgeM3Service.ts
export class BgeM3Service {
  private apiEndpoint: string;
  private apiKey: string;
  private httpClient: AxiosInstance;

  constructor() {
    this.apiEndpoint = process.env.BGE_API_ENDPOINT!;
    this.apiKey = process.env.BGE_API_KEY!;
    
    this.httpClient = axios.create({
      baseURL: this.apiEndpoint,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`
      }
    });
  }

  /**
   * 단일 텍스트 임베딩 생성
   */
  async createEmbedding(text: string): Promise<number[]> {
    try {
      const response = await this.httpClient.post('/embeddings', {
        input: text,
        model: 'BAAI/bge-m3',
        encoding_format: 'float'
      });

      return response.data.data[0].embedding;
    } catch (error) {
      throw new Error(`BGE-M3 API 호출 실패: ${error.message}`);
    }
  }

  /**
   * 하이브리드 임베딩 생성 (밀집 + 희소)
   */
  async createHybridEmbedding(text: string): Promise<HybridEmbedding> {
    try {
      const response = await this.httpClient.post('/embeddings', {
        input: text,
        model: 'BAAI/bge-m3',
        encoding_format: 'float',
        return_sparse: true
      });

      return {
        dense: response.data.data[0].embedding,
        sparse: response.data.data[0].sparse_embedding
      };
    } catch (error) {
      throw new Error(`BGE-M3 하이브리드 임베딩 실패: ${error.message}`);
    }
  }

  /**
   * 배치 임베딩 생성
   */
  async createBatchEmbeddings(texts: string[]): Promise<number[][]> {
    try {
      const response = await this.httpClient.post('/embeddings', {
        input: texts,
        model: 'BAAI/bge-m3',
        encoding_format: 'float'
      });

      return response.data.data.map((item: any) => item.embedding);
    } catch (error) {
      throw new Error(`BGE-M3 배치 임베딩 실패: ${error.message}`);
    }
  }
}
```

### **2. COGO 소스 최적화 임베딩**

```typescript
// src/services/CogoEmbeddingService.ts
export class CogoEmbeddingService {
  private bgeM3Service: BgeM3Service;

  constructor() {
    this.bgeM3Service = new BgeM3Service();
  }

  /**
   * COGO 소스를 검색에 최적화된 형태로 변환
   */
  prepareCogoSourceForEmbedding(source: CogoSource): string {
    const components = source.structure?.components || [];
    const codeSnippet = source.code?.content?.split('\n').slice(0, 30).join('\n') || '';
    
    const searchableContent = `
      Component: ${components.map(c => c.name).join(', ')}
      Language: ${source.code?.language || 'unknown'}
      Framework: ${source.code?.framework || 'unknown'}
      Overview: ${source.documentation?.overview || ''}
      Responsibilities: ${components.map(c => c.responsibilities).join(', ')}
      Strengths: ${source.quality?.analysis?.strengths?.join(', ') || ''}
      Code: ${codeSnippet}
      Features: ${source.features?.join(', ') || ''}
      API: ${source.api?.endpoints?.map(e => `${e.method} ${e.path}`).join(', ') || ''}
    `.trim().replace(/\s+/g, ' ');

    return searchableContent;
  }

  /**
   * COGO 소스 임베딩 생성
   */
  async createCogoSourceEmbedding(source: CogoSource): Promise<CogoEmbedding> {
    const searchableContent = this.prepareCogoSourceForEmbedding(source);
    
    // 하이브리드 임베딩 생성
    const hybridEmbedding = await this.bgeM3Service.createHybridEmbedding(searchableContent);
    
    return {
      sourceId: source.generation_id,
      content: searchableContent,
      denseEmbedding: hybridEmbedding.dense,
      sparseEmbedding: hybridEmbedding.sparse,
      metadata: {
        language: source.code?.language,
        framework: source.code?.framework,
        componentCount: source.structure?.components?.length || 0,
        codeLength: source.code?.content?.length || 0,
        features: source.features || [],
        apiEndpoints: source.api?.endpoints?.length || 0
      }
    };
  }
}
```

### **3. 검색 서비스 업데이트**

```typescript
// src/services/EnhancedSearchService.ts
export class EnhancedSearchService {
  private bgeM3Service: BgeM3Service;
  private supabase: SupabaseClient;

  constructor() {
    this.bgeM3Service = new BgeM3Service();
    this.supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);
  }

  /**
   * 하이브리드 검색 (밀집 + 희소 벡터)
   */
  async hybridSearch(query: string, options: SearchOptions = {}): Promise<SearchResult> {
    // 하이브리드 임베딩 생성
    const hybridEmbedding = await this.bgeM3Service.createHybridEmbedding(query);
    
    // 검색 실행
    const { data, error } = await this.supabase.rpc('search_similar_documents_1024', {
      query_embedding: hybridEmbedding.dense,
      query_sparse: hybridEmbedding.sparse,
      match_threshold: options.threshold || 0.6,
      match_count: options.limit || 10,
      content_type_filter: options.contentType
    });

    if (error) throw error;

    return {
      query,
      results: data,
      totalCount: data.length,
      searchTime: Date.now(),
      model: 'BAAI/bge-m3'
    };
  }

  /**
   * 코드 전용 검색
   */
  async searchCode(query: string, language?: string): Promise<CodeSearchResult> {
    const hybridEmbedding = await this.bgeM3Service.createHybridEmbedding(query);
    
    const { data, error } = await this.supabase.rpc('search_similar_code_1024', {
      query_embedding: hybridEmbedding.dense,
      query_sparse: hybridEmbedding.sparse,
      language_filter: language,
      match_threshold: 0.5,
      match_count: 15
    });

    if (error) throw error;

    return {
      query,
      language,
      results: data,
      totalCount: data.length,
      searchTime: Date.now(),
      model: 'BAAI/bge-m3'
    };
  }
}
```

---

## 🚀 **구현 로드맵**

### **Phase 1: 스키마 변경 및 마이그레이션 (1주)**
- [ ] Supabase 스키마 1024차원으로 변경
- [ ] 기존 데이터 백업
- [ ] BGE-M3 재임베딩 마이그레이션
- [ ] 검증 및 롤백 준비

### **Phase 2: BGE-M3 API 통합 (1주)**
- [ ] BGE-M3 API 클라이언트 구현
- [ ] 하이브리드 임베딩 서비스 구현
- [ ] COGO 소스 최적화 임베딩 구현
- [ ] 배치 처리 최적화

### **Phase 3: 검색 시스템 업데이트 (1주)**
- [ ] 하이브리드 검색 함수 구현
- [ ] 검색 서비스 업데이트
- [ ] 성능 최적화
- [ ] 테스트 및 검증

### **Phase 4: 통합 및 최적화 (1주)**
- [ ] 전체 시스템 통합
- [ ] 성능 모니터링
- [ ] 에러 처리 및 복구
- [ ] 문서화 완료

---

## 📈 **성공 지표**

### **기술적 지표**
- [ ] 임베딩 정확도: 95% 이상 (기존 대비)
- [ ] 검색 응답 시간: 1초 이내
- [ ] 하이브리드 검색 정확도: 90% 이상
- [ ] 다국어 지원: 100개 언어 이상

### **성능 지표**
- [ ] 벡터 저장 공간: 33% 절약 (1536 → 1024)
- [ ] 검색 속도: 20% 향상
- [ ] 메모리 사용량: 25% 절약
- [ ] API 응답 시간: 50% 단축

---

## 🎯 **결론**

BAAI/bge-m3 embedding을 통합함으로써 COGO 플랫폼은:

- ✅ **최적화된 벡터 차원**: 1024차원으로 효율성 극대화
- ✅ **하이브리드 검색**: 의미 + 키워드 기반 정확도 향상
- ✅ **다국어 지원**: 글로벌 개발자 지원
- ✅ **상업적 자유**: MIT 라이선스로 제약 없음
- ✅ **성능 향상**: 검색 속도 및 정확도 개선

이를 통해 **진정한 Single Source of Truth**를 구현하여 COGO Agent Core의 지능형 코드 분석 및 생성 능력을 크게 향상시킬 것입니다.

---

**작성자**: COGO Agent (AI Assistant)  
**작성일**: 2025-08-06  
**상태**: 📋 설계 완료 - 구현 준비 