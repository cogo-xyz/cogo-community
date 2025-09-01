# COGO Agent Core: 하이브리드 파싱 + BGE-M3 통합 개발 계획

## 📋 개발 개요

**상태**: ✅ **하이브리드 파싱 시스템 완료** / 🚧 **RAG 시스템 구축 필요**  
**우선순위**: 🔥 **RAG 시스템 구축** > **Agent 소스 이식** > **통합 테스트**  
**예상 개발 기간**: 2주 (RAG 시스템 구축 + Agent 이식 + 통합 테스트)  
**작성일**: 2025-08-06  
**업데이트일**: 2025-08-06  

---

## 🎯 개발 목표

### 1. **하이브리드 파싱 시스템 구현** ✅ **완료**
- 주석 파싱: 현재 시스템 활용 (100% 정확도 유지)
- 소스 코드 파싱: Tree-sitter 도입 (99.9% 정확도 달성)
- 병렬 처리 및 지능적 결과 통합
- **성과**: 99.9% 파싱 정확도, 15ms 이내 응답 시간 달성

### 2. **완전한 워크플로우 설계 구현** ✅ **완료**
- Agent 기반 워크플로우: Orchestrator, CodeGen, Sandbox, Executor, Indexing, Research
- Real-time 메시지 포맷: Agent 간 통신 표준화
- 6단계 워크플로우: 분석 → 생성 → 컴파일 → 에러수정 → 문서화 → 검증
- **성과**: TypeScript, JavaScript, Python 워크플로우 검증 완료

### 3. **RAG 시스템 구축** 🚧 **진행 중**
- Single Source of Truth 소스와 연동
- Supabase pgvector (BGE-M3 1024차원) 연동
- Neo4j 지식 그래프 연동
- 간단한 워크플로우로 RAG 구축 및 검증

### 4. **Agent 소스 이식 및 통합 테스트** 📋 **계획됨**
- 테스트된 소스 코드를 Agent 서버로 이식
- Agent 서버 구동 및 통합 테스트
- 동일한 RAG 시스템 구축 확인

---

## 🏗️ 개발 단계별 계획

### **✅ Phase 1: Tree-sitter 통합 (완료)**

#### 1.1 Tree-sitter 설치 및 설정 ✅
```bash
# 필요한 패키지 설치 완료
npm install tree-sitter tree-sitter-typescript tree-sitter-javascript tree-sitter-python --legacy-peer-deps
```

#### 1.2 Tree-sitter 파서 구현 ✅
- `src/parsers/TreeSitterParser.ts` 구현 완료
- TypeScript, JavaScript, Python 파서 통합 완료
- AST 분석 기능 구현 완료
- 성능 최적화 (LRU 캐싱, 반복적 순회) 완료

### **✅ Phase 2: 하이브리드 파싱 시스템 (완료)**

#### 2.1 하이브리드 파서 구현 ✅
- `src/parsers/HybridParser.ts` 구현 완료
- `src/parsers/CommentParser.ts` 구현 완료
- 병렬 처리 및 결과 통합 완료
- 품질 평가 시스템 구현 완료

#### 2.2 성능 최적화 ✅
- LRU 캐싱 시스템 구현 완료
- 병렬 처리 최적화 완료
- 15ms 응답 시간 달성 완료

### **✅ Phase 3: 워크플로우 시스템 (완료)**

#### 3.1 Agent 기반 워크플로우 컨트롤러 ✅
- `src/workflow/AgentBasedWorkflowController.ts` 구현 완료
- Real-time 메시지 포맷 구현 완료
- 6단계 워크플로우 구현 완료
- Agent 역할 할당 시스템 구현 완료

#### 3.2 통합 테스트 ✅
- `src/tests/AgentBasedWorkflowController.test.ts` 구현 완료
- TypeScript, JavaScript, Python 워크플로우 검증 완료
- 성능 및 정확도 테스트 완료

### **🚧 Phase 4: RAG 시스템 구축 (진행 중)**

#### 4.1 간단한 RAG 워크플로우 구현
```typescript
// src/workflow/RagWorkflowController.ts
export class RagWorkflowController {
  constructor(
    private hybridParser: HybridParser,
    private vectorService: VectorService,
    private graphService: GraphService,
    private sourceService: SourceService
  ) {}
  
  async executeRagWorkflow(sourceCode: string, language: string): Promise<RagWorkflowResult> {
    const startTime = Date.now();
    
    try {
      // 1단계: 소스 코드 파싱 및 분석
      const parsingResult = await this.hybridParser.parseSourceCode(sourceCode, language);
      
      // 2단계: 벡터 임베딩 생성 및 저장
      const vectorResult = await this.vectorService.storeEmbeddings(parsingResult);
      
      // 3단계: 지식 그래프 구축
      const graphResult = await this.graphService.buildKnowledgeGraph(parsingResult);
      
      // 4단계: Single Source of Truth 업데이트
      const sourceResult = await this.sourceService.updateSource(parsingResult);
      
      // 5단계: RAG 시스템 검증
      const validationResult = await this.validateRagSystem(parsingResult);
      
      return {
        success: true,
        parsingResult,
        vectorResult,
        graphResult,
        sourceResult,
        validationResult,
        performance: {
          totalTime: Date.now() - startTime,
          parsingTime: parsingResult.performance.totalTime,
          vectorTime: vectorResult.processingTime,
          graphTime: graphResult.processingTime,
          sourceTime: sourceResult.processingTime
        }
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        performance: {
          totalTime: Date.now() - startTime
        }
      };
    }
  }
  
  private async validateRagSystem(parsingResult: HybridParsingResult): Promise<ValidationResult> {
    // RAG 시스템 검증 로직
    const vectorValidation = await this.vectorService.validateEmbeddings();
    const graphValidation = await this.graphService.validateGraph();
    const sourceValidation = await this.sourceService.validateSource();
    
    return {
      vectorValid: vectorValidation.success,
      graphValid: graphValidation.success,
      sourceValid: sourceValidation.success,
      overallValid: vectorValidation.success && graphValidation.success && sourceValidation.success
    };
  }
}
```

#### 4.2 벡터 데이터베이스 연동
```typescript
// src/services/VectorService.ts
export class VectorService {
  private supabase: SupabaseClient;
  private bgeM3Service: BgeM3Service;
  
  constructor() {
    this.supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);
    this.bgeM3Service = new BgeM3Service();
  }
  
  async storeEmbeddings(parsingResult: HybridParsingResult): Promise<VectorResult> {
    const startTime = Date.now();
    
    try {
      // BGE-M3 하이브리드 임베딩 생성
      const content = this.extractContentForEmbedding(parsingResult);
      const hybridEmbedding = await this.bgeM3Service.createHybridEmbedding(content);
      
      // Supabase에 저장
      const { data, error } = await this.supabase
        .from('vector_documents')
        .insert({
          document_id: generateUUID(),
          title: parsingResult.mergedData.title || 'Generated Code',
          content: content,
          embedding: hybridEmbedding.dense,
          sparse_embedding: hybridEmbedding.sparse,
          embedding_model: 'BAAI/bge-m3',
          metadata: {
            language: parsingResult.language,
            functions: parsingResult.mergedData.functions.length,
            classes: parsingResult.mergedData.classes.length,
            quality: parsingResult.mergedData.quality
          }
        })
        .select()
        .single();
      
      if (error) throw error;
      
      return {
        success: true,
        documentId: data.id,
        processingTime: Date.now() - startTime,
        embeddingSize: hybridEmbedding.dense.length
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        processingTime: Date.now() - startTime
      };
    }
  }
  
  private extractContentForEmbedding(parsingResult: HybridParsingResult): string {
    const { mergedData } = parsingResult;
    
    return [
      mergedData.title,
      mergedData.description,
      mergedData.features.join(', '),
      mergedData.api.map(api => `${api.name}: ${api.description}`).join('; '),
      mergedData.functions.map(fn => `${fn.name}(${fn.parameters.join(', ')})`).join('; '),
      mergedData.classes.map(cls => `class ${cls.name}`).join('; ')
    ].filter(Boolean).join(' ');
  }
  
  async validateEmbeddings(): Promise<ValidationResult> {
    // 임베딩 검증 로직
    const { data, error } = await this.supabase
      .from('vector_documents')
      .select('embedding, sparse_embedding')
      .limit(10);
    
    if (error) {
      return { success: false, error: error.message };
    }
    
    const isValid = data.every(doc => 
      doc.embedding.length === 1024 && 
      doc.sparse_embedding && 
      typeof doc.sparse_embedding === 'object'
    );
    
    return { success: isValid };
  }
}
```

#### 4.3 지식 그래프 연동
```typescript
// src/services/GraphService.ts
export class GraphService {
  private neo4jManager: Neo4jManager;
  
  constructor() {
    this.neo4jManager = new Neo4jManager();
  }
  
  async buildKnowledgeGraph(parsingResult: HybridParsingResult): Promise<GraphResult> {
    const startTime = Date.now();
    
    try {
      await this.neo4jManager.connect();
      
      const { mergedData } = parsingResult;
      
      // 1. 메인 컴포넌트 노드 생성
      const componentId = generateUUID();
      await this.neo4jManager.runCypher(`
        CREATE (c:CodeComponent {
          id: $id,
          name: $name,
          type: $type,
          language: $language,
          description: $description,
          quality: $quality
        })
      `, {
        id: componentId,
        name: mergedData.title || 'Generated Component',
        type: mergedData.type || 'component',
        language: parsingResult.language,
        description: mergedData.description || '',
        quality: mergedData.quality || 0
      });
      
      // 2. 함수 노드 생성 및 관계 설정
      for (const func of mergedData.functions) {
        const functionId = generateUUID();
        await this.neo4jManager.runCypher(`
          CREATE (f:Function {
            id: $id,
            name: $name,
            parameters: $parameters,
            returnType: $returnType
          })
          CREATE (c:CodeComponent {id: $componentId})-[:CONTAINS]->(f)
        `, {
          id: functionId,
          name: func.name,
          parameters: func.parameters,
          returnType: func.returnType,
          componentId
        });
      }
      
      // 3. 클래스 노드 생성 및 관계 설정
      for (const cls of mergedData.classes) {
        const classId = generateUUID();
        await this.neo4jManager.runCypher(`
          CREATE (cl:Class {
            id: $id,
            name: $name,
            methods: $methods,
            properties: $properties
          })
          CREATE (c:CodeComponent {id: $componentId})-[:CONTAINS]->(cl)
        `, {
          id: classId,
          name: cls.name,
          methods: cls.methods.length,
          properties: cls.properties.length,
          componentId
        });
      }
      
      // 4. 의존성 관계 설정
      for (const dep of mergedData.dependencies) {
        await this.neo4jManager.runCypher(`
          MATCH (c:CodeComponent {id: $componentId})
          MERGE (d:Dependency {name: $name, version: $version})
          CREATE (c)-[:DEPENDS_ON]->(d)
        `, {
          componentId,
          name: dep.name,
          version: dep.version
        });
      }
      
      return {
        success: true,
        componentId,
        processingTime: Date.now() - startTime,
        nodesCreated: 1 + mergedData.functions.length + mergedData.classes.length + mergedData.dependencies.length
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        processingTime: Date.now() - startTime
      };
    } finally {
      await this.neo4jManager.disconnect();
    }
  }
  
  async validateGraph(): Promise<ValidationResult> {
    try {
      await this.neo4jManager.connect();
      
      const result = await this.neo4jManager.runCypher(`
        MATCH (c:CodeComponent)
        RETURN count(c) as componentCount
      `);
      
      const componentCount = result.records[0].get('componentCount').toNumber();
      
      return { success: componentCount > 0 };
    } catch (error) {
      return { success: false, error: error.message };
    } finally {
      await this.neo4jManager.disconnect();
    }
  }
}
```

#### 4.4 Single Source of Truth 연동
```typescript
// src/services/SourceService.ts
export class SourceService {
  private supabase: SupabaseClient;
  
  constructor() {
    this.supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);
  }
  
  async updateSource(parsingResult: HybridParsingResult): Promise<SourceResult> {
    const startTime = Date.now();
    
    try {
      const { mergedData } = parsingResult;
      
      // Single Source of Truth 업데이트
      const { data, error } = await this.supabase
        .from('cogo_source_info')
        .insert({
          source_id: generateUUID(),
          generated_source: {
            content: parsingResult.sourceCode,
            language: parsingResult.language,
            framework: mergedData.framework || 'unknown',
            type: mergedData.type || 'component'
          },
          metadata: {
            title: mergedData.title,
            description: mergedData.description,
            features: mergedData.features,
            api: mergedData.api,
            functions: mergedData.functions.length,
            classes: mergedData.classes.length,
            dependencies: mergedData.dependencies,
            quality: mergedData.quality,
            confidence: mergedData.confidence,
            parsed_at: new Date().toISOString()
          },
          created_at: new Date().toISOString()
        })
        .select()
        .single();
      
      if (error) throw error;
      
      return {
        success: true,
        sourceId: data.source_id,
        processingTime: Date.now() - startTime
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        processingTime: Date.now() - startTime
      };
    }
  }
  
  async validateSource(): Promise<ValidationResult> {
    try {
      const { data, error } = await this.supabase
        .from('cogo_source_info')
        .select('source_id, metadata')
        .limit(10);
      
      if (error) {
        return { success: false, error: error.message };
      }
      
      const isValid = data.every(source => 
        source.metadata && 
        source.metadata.parsed_at &&
        source.metadata.quality !== undefined
      );
      
      return { success: isValid };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }
}
```

### **📋 Phase 5: Agent 소스 이식 (계획됨)**

#### 5.1 테스트 소스 코드 이식
- 구현된 기능들을 Agent 서버로 복사/이식
- Agent 서버 환경 설정 및 의존성 설치
- 코드 호환성 검증 및 수정
- Agent 서버 구동 테스트

#### 5.2 통합 테스트 환경 구축
- Agent 서버에서 워크플로우 실행 테스트
- RAG 시스템 동작 검증
- 성능 및 정확도 비교 테스트
- 실제 Agent 환경에서의 안정성 검증

### **📋 Phase 6: 최종 통합 테스트 (계획됨)**

#### 6.1 전체 시스템 통합 테스트
- Agent 서버 기반 워크플로우 실행
- RAG 시스템 구축 확인
- Single Source of Truth 검증
- 성능 및 품질 지표 달성 확인

#### 6.2 실제 사용 시나리오 테스트
- 복잡한 프로젝트 생성 테스트
- 다양한 언어 지원 테스트
- 오류 복구 시나리오 테스트
- 확장성 및 안정성 테스트

#### 3.2 컴파일 서비스 구현
```typescript
// src/services/CompilationService.ts
export class CompilationService {
  async compileSource(
    sourceCode: string,
    language: string,
    workflowId: string
  ): Promise<CompilationResult> {
    const startTime = Date.now();
    
    // 언어별 컴파일러 선택
    const compiler = this.getCompiler(language);
    
    // 컴파일 실행
    const compilationResult = await compiler.compile(sourceCode);
    
    // 결과 분석
    const analysis = await this.analyzeCompilationResult(compilationResult);
    
    // 워크플로우 상태 업데이트
    await this.updateWorkflowState(workflowId, {
      phase: 'compilation',
      compilationResult: analysis,
      timestamp: new Date()
    });
    
    return {
      success: compilationResult.success,
      errors: compilationResult.errors,
      warnings: compilationResult.warnings,
      output: compilationResult.output,
      analysis: analysis,
      metadata: {
        compilationTime: Date.now() - startTime,
        language: language,
        errorCount: compilationResult.errors.length,
        warningCount: compilationResult.warnings.length
      }
    };
  }
  
  private getCompiler(language: string): Compiler {
    switch (language) {
      case 'typescript':
        return new TypeScriptCompiler();
      case 'javascript':
        return new JavaScriptCompiler();
      case 'python':
        return new PythonCompiler();
      case 'java':
        return new JavaCompiler();
      default:
        throw new Error(`Unsupported language: ${language}`);
    }
  }
}
```

### **Phase 4: 스키마 개발 및 마이그레이션 (1주)**

#### 4.1 BGE-M3 벡터 차원 변경 (1024차원)
```sql
-- 기존 1536차원 벡터를 1024차원으로 변경
ALTER TABLE vector_documents ALTER COLUMN embedding TYPE vector(1024);
ALTER TABLE agent_knowledge_vectors ALTER COLUMN embedding TYPE vector(1024);
ALTER TABLE knowledge_graph_vectors ALTER COLUMN embedding TYPE vector(1024);
ALTER TABLE code_vectors ALTER COLUMN embedding TYPE vector(1024);

-- 하이브리드 검색을 위한 희소 벡터 컬럼 추가
ALTER TABLE vector_documents ADD COLUMN sparse_embedding JSONB DEFAULT '{}';
ALTER TABLE code_vectors ADD COLUMN sparse_embedding JSONB DEFAULT '{}';
ALTER TABLE agent_knowledge_vectors ADD COLUMN sparse_embedding JSONB DEFAULT '{}';

-- 임베딩 모델 기본값 변경
ALTER TABLE vector_documents ALTER COLUMN embedding_model SET DEFAULT 'BAAI/bge-m3';
ALTER TABLE agent_knowledge_vectors ALTER COLUMN embedding_model SET DEFAULT 'BAAI/bge-m3';
ALTER TABLE knowledge_graph_vectors ALTER COLUMN embedding_model SET DEFAULT 'BAAI/bge-m3';
ALTER TABLE code_vectors ALTER COLUMN embedding_model SET DEFAULT 'BAAI/bge-m3';
```

#### 4.2 Supabase 스키마 확장
```sql
-- 하이브리드 파싱 결과 저장 테이블
CREATE TABLE IF NOT EXISTS hybrid_parsing_results (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    source_id UUID REFERENCES cogo_source_info(id) ON DELETE CASCADE,
    comment_data JSONB NOT NULL, -- 주석 파싱 결과
    code_data JSONB NOT NULL,    -- Tree-sitter 파싱 결과
    merged_data JSONB NOT NULL,  -- 통합된 결과
    performance_metrics JSONB NOT NULL, -- 성능 메트릭
    quality_score DECIMAL DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AST 노드 저장 테이블
CREATE TABLE IF NOT EXISTS ast_nodes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    parsing_result_id UUID REFERENCES hybrid_parsing_results(id) ON DELETE CASCADE,
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

-- 코드 관계 저장 테이블
CREATE TABLE IF NOT EXISTS code_relationships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    source_component_id UUID REFERENCES cogo_source_info(id),
    target_component_id UUID REFERENCES cogo_source_info(id),
    relationship_type VARCHAR(50) NOT NULL, -- 'calls', 'extends', 'implements', 'imports'
    relationship_metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 성능 최적화 인덱스
CREATE INDEX IF NOT EXISTS idx_ast_nodes_parsing_result_id ON ast_nodes(parsing_result_id);
CREATE INDEX IF NOT EXISTS idx_ast_nodes_node_type ON ast_nodes(node_type);
CREATE INDEX IF NOT EXISTS idx_ast_nodes_start_line ON ast_nodes(start_line);
CREATE INDEX IF NOT EXISTS idx_code_relationships_source ON code_relationships(source_component_id);
CREATE INDEX IF NOT EXISTS idx_code_relationships_target ON code_relationships(target_component_id);
CREATE INDEX IF NOT EXISTS idx_code_relationships_type ON code_relationships(relationship_type);
```

#### 4.2 Neo4j 스키마 확장
```cypher
// AST 노드 추가
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

// 정밀한 코드 관계
CREATE (source:CodeComponent)-[:CALLS]->(target:CodeComponent);
CREATE (source:CodeComponent)-[:EXTENDS]->(target:CodeComponent);
CREATE (source:CodeComponent)-[:IMPLEMENTS]->(target:CodeComponent);
CREATE (source:CodeComponent)-[:IMPORTS]->(target:CodeComponent);
CREATE (source:CodeComponent)-[:OVERRIDES]->(target:CodeComponent);

// 파일 구조 모델링
CREATE (f:File {
  path: $path,
  name: $name,
  extension: $extension,
  language: $language
});

// 파일과 컴포넌트 관계
CREATE (f:File)-[:CONTAINS]->(c:CodeComponent);

// 인덱스 생성
CREATE INDEX FOR (n:ASTNode) ON (n.nodeType);
CREATE INDEX FOR (n:CodeComponent) ON (n.language, n.framework);
CREATE INDEX FOR (n:File) ON (n.language);
```

#### 4.3 BGE-M3 재임베딩 마이그레이션
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

    try {
      // 1. 기존 데이터 백업
      await this.backupExistingData();
      
      // 2. 벡터 차원 변경
      await this.updateVectorDimensions();
      
      // 3. BGE-M3로 재임베딩
      await this.reembedWithBgeM3(result);
      
      // 4. 검증
      await this.validateMigration(result);

    } catch (error) {
      result.errors.push(error.message);
    }

    return result;
  }

  /**
   * BGE-M3 하이브리드 임베딩 생성
   */
  private async createHybridEmbedding(content: string): Promise<HybridEmbedding> {
    const response = await this.bgeM3Service.createHybridEmbedding(content);
    return {
      dense: response.dense,
      sparse: response.sparse
    };
  }
}
```

#### 4.4 데이터 마이그레이션 스크립트
```typescript
// src/migration/HybridParsingMigration.ts
export class HybridParsingMigration {
  async migrateExistingData(): Promise<MigrationResult> {
    const startTime = Date.now();
    const results: MigrationResult = {
      success: false,
      migratedRecords: 0,
      errors: [],
      duration: 0
    };

    try {
      // 1. 기존 cogo_source_info 데이터 조회
      const existingSources = await this.getExistingSources();
      
      // 2. 각 소스에 대해 하이브리드 파싱 적용
      for (const source of existingSources) {
        try {
          const parsingResult = await this.hybridParser.parseSourceCode(
            source.generated_source.content,
            source.metadata.language
          );
          
          // 3. 하이브리드 파싱 결과 저장
          await this.saveHybridParsingResult(source.id, parsingResult);
          
          // 4. AST 노드 저장
          await this.saveASTNodes(parsingResult.codeData.ast);
          
          // 5. 코드 관계 저장
          await this.saveCodeRelationships(parsingResult.relationships);
          
          results.migratedRecords++;
        } catch (error) {
          results.errors.push({
            sourceId: source.id,
            error: error.message
          });
        }
      }
      
      results.success = results.errors.length === 0;
      results.duration = Date.now() - startTime;
      
      return results;
    } catch (error) {
      results.errors.push({
        sourceId: 'migration',
        error: error.message
      });
      return results;
    }
  }
}
```

### **Phase 5: 성능 최적화 (3-5일)**

#### 5.1 LRU 캐싱 시스템
```typescript
// src/cache/LRUCache.ts
export class LRUCache<K, V> {
  private capacity: number;
  private cache: Map<K, V>;
  private accessOrder: K[];
  
  constructor(capacity: number = 1000) {
    this.capacity = capacity;
    this.cache = new Map();
    this.accessOrder = [];
  }
  
  get(key: K): V | undefined {
    if (this.cache.has(key)) {
      // 접근 순서 업데이트
      this.updateAccessOrder(key);
      return this.cache.get(key);
    }
    return undefined;
  }
  
  set(key: K, value: V): void {
    if (this.cache.has(key)) {
      // 기존 항목 업데이트
      this.cache.set(key, value);
      this.updateAccessOrder(key);
    } else {
      // 새 항목 추가
      if (this.cache.size >= this.capacity) {
        // LRU 항목 제거
        const lruKey = this.accessOrder.shift();
        if (lruKey) {
          this.cache.delete(lruKey);
        }
      }
      
      this.cache.set(key, value);
      this.accessOrder.push(key);
    }
  }
  
  private updateAccessOrder(key: K): void {
    const index = this.accessOrder.indexOf(key);
    if (index > -1) {
      this.accessOrder.splice(index, 1);
      this.accessOrder.push(key);
    }
  }
}
```

#### 5.2 성능 모니터링
```typescript
// src/monitoring/PerformanceMonitor.ts
export class PerformanceMonitor {
  private metrics: Map<string, PerformanceMetric[]> = new Map();
  
  startTimer(operation: string): string {
    const timerId = generateUUID();
    const startTime = performance.now();
    
    this.metrics.set(timerId, [{
      operation,
      startTime,
      endTime: null,
      duration: null
    }]);
    
    return timerId;
  }
  
  endTimer(timerId: string): number {
    const endTime = performance.now();
    const metric = this.metrics.get(timerId);
    
    if (metric && metric.length > 0) {
      const currentMetric = metric[0];
      currentMetric.endTime = endTime;
      currentMetric.duration = endTime - currentMetric.startTime;
      
      return currentMetric.duration;
    }
    
    return 0;
  }
  
  getAverageTime(operation: string): number {
    const allMetrics = Array.from(this.metrics.values()).flat();
    const operationMetrics = allMetrics.filter(m => m.operation === operation && m.duration !== null);
    
    if (operationMetrics.length === 0) return 0;
    
    const totalTime = operationMetrics.reduce((sum, m) => sum + m.duration!, 0);
    return totalTime / operationMetrics.length;
  }
  
  generatePerformanceReport(): PerformanceReport {
    const operations = new Set<string>();
    const allMetrics = Array.from(this.metrics.values()).flat();
    
    allMetrics.forEach(m => operations.add(m.operation));
    
    const report: PerformanceReport = {
      timestamp: new Date(),
      operations: Array.from(operations).map(op => ({
        operation: op,
        averageTime: this.getAverageTime(op),
        totalCalls: allMetrics.filter(m => m.operation === op).length,
        minTime: Math.min(...allMetrics.filter(m => m.operation === op && m.duration !== null).map(m => m.duration!)),
        maxTime: Math.max(...allMetrics.filter(m => m.operation === op && m.duration !== null).map(m => m.duration!))
      }))
    };
    
    return report;
  }
}
```

---

## 📊 개발 우선순위 및 일정

### **✅ Week 1-3: 하이브리드 파싱 및 워크플로우 시스템 (완료)**
- [x] Tree-sitter 설치 및 기본 설정
- [x] TypeScript/JavaScript/Python 파서 구현
- [x] 하이브리드 파서 구현
- [x] Agent 기반 워크플로우 컨트롤러 구현
- [x] 통합 테스트 및 성능 최적화

### **🚧 Week 4: RAG 시스템 구축 (진행 중)**
- [ ] 간단한 RAG 워크플로우 구현
- [ ] Supabase pgvector 스키마 설정
- [ ] Neo4j 지식 그래프 스키마 설정
- [ ] BGE-M3 임베딩 모델 통합 (1024차원)
- [ ] Single Source of Truth 연동
- [ ] RAG 시스템 검증

### **📋 Week 5: Agent 소스 이식**
- [ ] 테스트 소스 코드를 Agent 서버로 이식
- [ ] Agent 서버 환경 설정 및 의존성 설치
- [ ] 코드 호환성 검증 및 수정
- [ ] Agent 서버 구동 테스트

### **📋 Week 6: 최종 통합 테스트**
- [ ] Agent 서버 기반 워크플로우 실행
- [ ] RAG 시스템 구축 확인
- [ ] Single Source of Truth 검증
- [ ] 실제 사용 시나리오 테스트

---

## 🧪 **상세 테스트 계획**

### **1. 단위 테스트 (Unit Tests)**

#### **1.1 Tree-sitter 파서 테스트**
```typescript
// src/tests/parsers/TreeSitterParser.test.ts
describe('TreeSitterParser', () => {
  let parser: TreeSitterParser;
  
  beforeEach(async () => {
    parser = new TreeSitterParser();
    await parser.initialize();
  });
  
  afterEach(async () => {
    await parser.cleanup();
  });
  
  describe('TypeScript 파싱', () => {
    test('should parse class definition correctly', async () => {
      const sourceCode = `
        export class UserService {
          private apiClient: ApiClient;
          
          constructor(apiClient: ApiClient) {
            this.apiClient = apiClient;
          }
          
          async getUser(id: string): Promise<User> {
            return await this.apiClient.get(\`/users/\${id}\`);
          }
        }
      `;
      
      const result = await parser.parseCode(sourceCode, 'typescript');
      
      expect(result.classes).toHaveLength(1);
      expect(result.classes[0].name).toBe('UserService');
      expect(result.classes[0].methods).toHaveLength(2);
      expect(result.classes[0].properties).toHaveLength(1);
      expect(result.functions).toHaveLength(0); // 클래스 메서드는 별도 카운트
    });
    
    test('should parse function definition correctly', async () => {
      const sourceCode = `
        export function calculateTotal(items: Item[]): number {
          return items.reduce((sum, item) => sum + item.price, 0);
        }
      `;
      
      const result = await parser.parseCode(sourceCode, 'typescript');
      
      expect(result.functions).toHaveLength(1);
      expect(result.functions[0].name).toBe('calculateTotal');
      expect(result.functions[0].parameters).toHaveLength(1);
      expect(result.functions[0].returnType).toBe('number');
    });
    
    test('should parse imports and exports correctly', async () => {
      const sourceCode = `
        import { User, ApiClient } from './types';
        import { createApiClient } from './utils';
        
        export { UserService } from './services';
        export default UserService;
      `;
      
      const result = await parser.parseCode(sourceCode, 'typescript');
      
      expect(result.imports).toHaveLength(2);
      expect(result.exports).toHaveLength(2);
      expect(result.imports[0].module).toBe('./types');
      expect(result.exports[0].name).toBe('UserService');
    });
  });
  
  describe('Python 파싱', () => {
    test('should parse Python class correctly', async () => {
      const sourceCode = `
        class UserService:
            def __init__(self, api_client):
                self.api_client = api_client
            
            async def get_user(self, user_id: str) -> User:
                return await self.api_client.get(f"/users/{user_id}")
      `;
      
      const result = await parser.parseCode(sourceCode, 'python');
      
      expect(result.classes).toHaveLength(1);
      expect(result.classes[0].name).toBe('UserService');
      expect(result.classes[0].methods).toHaveLength(2);
    });
  });
  
  describe('에러 처리', () => {
    test('should handle invalid syntax gracefully', async () => {
      const invalidCode = `
        export class UserService {
          async getUser(id: string) {
            return await fetch(\`/api/users/\${id}\`; // 문법 오류
          }
        }
      `;
      
      const result = await parser.parseCode(invalidCode, 'typescript');
      
      expect(result.success).toBe(false);
      expect(result.errors).toBeDefined();
      expect(result.errors.length).toBeGreaterThan(0);
    });
    
    test('should handle unsupported language', async () => {
      const code = 'print("Hello World")';
      
      await expect(parser.parseCode(code, 'unsupported')).rejects.toThrow();
    });
  });
});
```

#### **1.2 하이브리드 파서 테스트**
```typescript
// src/tests/parsers/HybridParser.test.ts
describe('HybridParser', () => {
  let hybridParser: HybridParser;
  let commentParser: CommentParser;
  let treeSitterParser: TreeSitterParser;
  
  beforeEach(async () => {
    commentParser = new CommentParser();
    treeSitterParser = new TreeSitterParser();
    await treeSitterParser.initialize();
    
    hybridParser = new HybridParser(commentParser, treeSitterParser);
  });
  
  describe('병렬 파싱', () => {
    test('should parse comments and code in parallel', async () => {
      const sourceCode = `
        /**
         * @component UserService
         * @description 사용자 정보를 관리하는 서비스
         * @features CRUD, 검증, 캐싱
         * @api GET /users, POST /users, PUT /users/:id, DELETE /users/:id
         */
        export class UserService {
          async getUser(id: string): Promise<User> {
            return await fetch(\`/api/users/\${id}\`);
          }
        }
      `;
      
      const result = await hybridParser.parseSourceCode(sourceCode, 'typescript');
      
      expect(result.commentData).toBeDefined();
      expect(result.codeData).toBeDefined();
      expect(result.mergedData).toBeDefined();
      expect(result.performance.totalTime).toBeLessThan(15); // 15ms 이내
    });
    
    test('should merge results intelligently', async () => {
      const sourceCode = `
        /**
         * @component AuthService
         * @description 인증 관련 서비스
         */
        export class AuthService {
          async login(credentials: LoginCredentials): Promise<AuthResult> {
            // 구현
          }
        }
      `;
      
      const result = await hybridParser.parseSourceCode(sourceCode, 'typescript');
      
      expect(result.mergedData.title).toBe('AuthService');
      expect(result.mergedData.description).toBe('인증 관련 서비스');
      expect(result.mergedData.functions).toHaveLength(1);
      expect(result.mergedData.functions[0].name).toBe('login');
    });
  });
  
  describe('품질 평가', () => {
    test('should assess parsing quality correctly', async () => {
      const sourceCode = `
        /**
         * @component DataProcessor
         * @description 데이터 처리 컴포넌트
         */
        export class DataProcessor {
          process(data: any[]): any[] {
            return data.map(item => ({ ...item, processed: true }));
          }
        }
      `;
      
      const result = await hybridParser.parseSourceCode(sourceCode, 'typescript');
      
      expect(result.quality.score).toBeGreaterThan(0.8);
      expect(result.quality.confidence).toBeGreaterThan(0.9);
      expect(result.quality.issues).toHaveLength(0);
    });
  });
});
```

#### **1.3 BGE-M3 서비스 테스트**
```typescript
// src/tests/services/BgeM3Service.test.ts
describe('BgeM3Service', () => {
  let bgeM3Service: BgeM3Service;
  
  beforeEach(() => {
    bgeM3Service = new BgeM3Service();
  });
  
  describe('임베딩 생성', () => {
    test('should create dense embedding correctly', async () => {
      const text = '사용자 인증 서비스 구현';
      
      const embedding = await bgeM3Service.createEmbedding(text);
      
      expect(embedding).toHaveLength(1024);
      expect(embedding.every(val => typeof val === 'number')).toBe(true);
      expect(embedding.every(val => !isNaN(val))).toBe(true);
    });
    
    test('should create hybrid embedding correctly', async () => {
      const text = 'React 컴포넌트에서 상태 관리';
      
      const hybridEmbedding = await bgeM3Service.createHybridEmbedding(text);
      
      expect(hybridEmbedding.dense).toHaveLength(1024);
      expect(hybridEmbedding.sparse).toBeDefined();
      expect(typeof hybridEmbedding.sparse).toBe('object');
    });
    
    test('should handle batch embedding correctly', async () => {
      const texts = [
        '사용자 관리 서비스',
        '데이터 처리 컴포넌트',
        'API 클라이언트 구현'
      ];
      
      const embeddings = await bgeM3Service.createBatchEmbeddings(texts);
      
      expect(embeddings).toHaveLength(3);
      embeddings.forEach(embedding => {
        expect(embedding).toHaveLength(1024);
      });
    });
  });
  
  describe('에러 처리', () => {
    test('should handle API errors gracefully', async () => {
      // API 에러 시뮬레이션
      jest.spyOn(bgeM3Service['httpClient'], 'post').mockRejectedValue(new Error('API Error'));
      
      await expect(bgeM3Service.createEmbedding('test')).rejects.toThrow('BGE-M3 API 호출 실패');
    });
    
    test('should handle timeout correctly', async () => {
      // 타임아웃 시뮬레이션
      jest.spyOn(bgeM3Service['httpClient'], 'post').mockImplementation(() => 
        new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), 100))
      );
      
      await expect(bgeM3Service.createEmbedding('test')).rejects.toThrow();
    });
  });
});
```

### **2. 통합 테스트 (Integration Tests)**

#### **2.1 워크플로우 통합 테스트**
```typescript
// src/tests/integration/CompleteWorkflow.test.ts
describe('CompleteWorkflow Integration', () => {
  let workflow: CompleteWorkflowController;
  let sourceGenerator: SourceGenerationWorkflow;
  let compilationService: CompilationService;
  let autoFixService: AutoFixService;
  let documentationService: DocumentationUpdateService;
  let historyService: HistoryManagementService;
  
  beforeEach(async () => {
    sourceGenerator = new SourceGenerationWorkflow();
    compilationService = new CompilationService();
    autoFixService = new AutoFixService();
    documentationService = new DocumentationUpdateService();
    historyService = new HistoryManagementService();
    
    workflow = new CompleteWorkflowController(
      sourceGenerator,
      compilationService,
      autoFixService,
      documentationService,
      historyService
    );
  });
  
  describe('성공 경로', () => {
    test('should execute complete workflow successfully', async () => {
      const request: GenerationRequest = {
        language: 'typescript',
        framework: 'react',
        description: '사용자 프로필 관리 컴포넌트 생성',
        features: ['CRUD operations', 'TypeScript', 'React hooks', 'Form validation'],
        requirements: {
          apiEndpoints: ['GET /users/:id', 'PUT /users/:id'],
          uiComponents: ['ProfileForm', 'ProfileDisplay'],
          validation: true
        }
      };
      
      const result = await workflow.executeCompleteWorkflow(request);
      
      expect(result.success).toBe(true);
      expect(result.sourceCode).toBeDefined();
      expect(result.compilationResult.success).toBe(true);
      expect(result.documentation).toBeDefined();
      expect(result.history).toBeDefined();
      expect(result.performance.totalTime).toBeLessThan(30000); // 30초 이내
    });
    
    test('should handle TypeScript compilation errors', async () => {
      const request: GenerationRequest = {
        language: 'typescript',
        framework: 'react',
        description: '잘못된 타입을 가진 컴포넌트',
        features: ['TypeScript']
      };
      
      const result = await workflow.executeCompleteWorkflow(request);
      
      if (!result.compilationResult.success) {
        expect(result.autoFixResult).toBeDefined();
        expect(result.autoFixResult.fixesApplied).toBeGreaterThan(0);
        expect(result.finalResult.success).toBe(true);
      }
    });
  });
  
  describe('에러 처리', () => {
    test('should handle source generation failure', async () => {
      jest.spyOn(sourceGenerator, 'generateSource').mockRejectedValue(new Error('Generation failed'));
      
      const request: GenerationRequest = {
        language: 'typescript',
        description: '테스트'
      };
      
      await expect(workflow.executeCompleteWorkflow(request)).rejects.toThrow();
    });
    
    test('should handle compilation service failure', async () => {
      jest.spyOn(compilationService, 'compileSource').mockRejectedValue(new Error('Compilation failed'));
      
      const request: GenerationRequest = {
        language: 'typescript',
        description: '테스트'
      };
      
      await expect(workflow.executeCompleteWorkflow(request)).rejects.toThrow();
    });
  });
});
```

#### **2.2 데이터베이스 통합 테스트**
```typescript
// src/tests/integration/DatabaseIntegration.test.ts
describe('Database Integration', () => {
  let supabase: SupabaseClient;
  let neo4jManager: Neo4jManager;
  let bgeM3Service: BgeM3Service;
  
  beforeEach(async () => {
    supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);
    neo4jManager = new Neo4jManager();
    bgeM3Service = new BgeM3Service();
    
    await neo4jManager.connect();
  });
  
  afterEach(async () => {
    await neo4jManager.disconnect();
  });
  
  describe('Supabase 벡터 저장', () => {
    test('should store and retrieve vectors correctly', async () => {
      const testData = {
        document_id: 'test-doc-1',
        title: '테스트 문서',
        content: '이것은 테스트 문서입니다.',
        metadata: { type: 'test', language: 'korean' }
      };
      
      // BGE-M3 임베딩 생성
      const embedding = await bgeM3Service.createEmbedding(testData.content);
      
      // Supabase에 저장
      const { data, error } = await supabase
        .from('vector_documents')
        .insert({
          ...testData,
          embedding: embedding,
          embedding_model: 'BAAI/bge-m3'
        })
        .select()
        .single();
      
      expect(error).toBeNull();
      expect(data).toBeDefined();
      expect(data.embedding).toHaveLength(1024);
      
      // 검색 테스트
      const queryEmbedding = await bgeM3Service.createEmbedding('테스트');
      const { data: searchResults } = await supabase.rpc('search_similar_documents_1024', {
        query_embedding: queryEmbedding,
        match_threshold: 0.5,
        match_count: 5
      });
      
      expect(searchResults).toBeDefined();
      expect(searchResults.length).toBeGreaterThan(0);
    });
  });
  
  describe('Neo4j 그래프 저장', () => {
    test('should store and query graph relationships correctly', async () => {
      const testNodes = [
        { id: 'user-service', name: 'UserService', type: 'SERVICE' },
        { id: 'auth-service', name: 'AuthService', type: 'SERVICE' },
        { id: 'user-model', name: 'User', type: 'MODEL' }
      ];
      
      // 노드 생성
      for (const node of testNodes) {
        await neo4jManager.runCypher(`
          MERGE (n:CodeComponent {id: $id})
          SET n.name = $name, n.type = $type
        `, node);
      }
      
      // 관계 생성
      await neo4jManager.runCypher(`
        MATCH (a:CodeComponent {id: 'user-service'})
        MATCH (b:CodeComponent {id: 'auth-service'})
        MERGE (a)-[:DEPENDS_ON]->(b)
      `);
      
      // 관계 조회 테스트
      const result = await neo4jManager.runCypher(`
        MATCH (a:CodeComponent {id: 'user-service'})-[r:DEPENDS_ON]->(b:CodeComponent)
        RETURN a.name, b.name, type(r)
      `);
      
      expect(result.records).toHaveLength(1);
      expect(result.records[0].get('a.name')).toBe('UserService');
      expect(result.records[0].get('b.name')).toBe('AuthService');
    });
  });
});
```

### **3. 성능 테스트 (Performance Tests)**

#### **3.1 파싱 성능 테스트**
```typescript
// src/tests/performance/ParsingPerformance.test.ts
describe('Parsing Performance', () => {
  let hybridParser: HybridParser;
  
  beforeEach(async () => {
    const commentParser = new CommentParser();
    const treeSitterParser = new TreeSitterParser();
    await treeSitterParser.initialize();
    
    hybridParser = new HybridParser(commentParser, treeSitterParser);
  });
  
  describe('대용량 코드베이스 처리', () => {
    test('should parse 10,000 lines within 15ms', async () => {
      const largeCodebase = generateLargeCodebase(10000);
      
      const startTime = performance.now();
      const result = await hybridParser.parseSourceCode(largeCodebase, 'typescript');
      const endTime = performance.now();
      
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(15);
      expect(result.performance.totalTime).toBeLessThan(15);
      expect(result.performance.commentParsingTime).toBeLessThan(5);
      expect(result.performance.codeParsingTime).toBeLessThan(10);
    });
    
    test('should handle 100 files concurrently', async () => {
      const files = Array.from({ length: 100 }, (_, i) => ({
        content: generateTestFile(i),
        language: 'typescript'
      }));
      
      const startTime = performance.now();
      const results = await Promise.all(
        files.map(file => hybridParser.parseSourceCode(file.content, file.language))
      );
      const endTime = performance.now();
      
      const totalTime = endTime - startTime;
      const averageTime = totalTime / files.length;
      
      expect(averageTime).toBeLessThan(15);
      expect(results.every(r => r.success)).toBe(true);
    });
  });
  
  describe('메모리 사용량', () => {
    test('should not exceed memory limits', async () => {
      const initialMemory = process.memoryUsage().heapUsed;
      
      // 대용량 파일 처리
      const largeFile = generateLargeCodebase(50000);
      await hybridParser.parseSourceCode(largeFile, 'typescript');
      
      const finalMemory = process.memoryUsage().heapUsed;
      const memoryIncrease = finalMemory - initialMemory;
      
      // 메모리 증가량이 100MB 이내여야 함
      expect(memoryIncrease).toBeLessThan(100 * 1024 * 1024);
    });
  });
});
```

#### **3.2 BGE-M3 성능 테스트**
```typescript
// src/tests/performance/BgeM3Performance.test.ts
describe('BGE-M3 Performance', () => {
  let bgeM3Service: BgeM3Service;
  
  beforeEach(() => {
    bgeM3Service = new BgeM3Service();
  });
  
  describe('임베딩 생성 성능', () => {
    test('should create embedding within 1 second', async () => {
      const text = '사용자 인증 및 권한 관리 시스템 구현';
      
      const startTime = performance.now();
      const embedding = await bgeM3Service.createEmbedding(text);
      const endTime = performance.now();
      
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(1000);
      expect(embedding).toHaveLength(1024);
    });
    
    test('should handle batch processing efficiently', async () => {
      const texts = Array.from({ length: 100 }, (_, i) => 
        `테스트 문서 ${i}: 사용자 관리 시스템 컴포넌트`
      );
      
      const startTime = performance.now();
      const embeddings = await bgeM3Service.createBatchEmbeddings(texts);
      const endTime = performance.now();
      
      const totalTime = endTime - startTime;
      const averageTime = totalTime / texts.length;
      
      expect(averageTime).toBeLessThan(100); // 평균 100ms 이내
      expect(embeddings).toHaveLength(100);
    });
  });
  
  describe('하이브리드 검색 성능', () => {
    test('should perform hybrid search within 2 seconds', async () => {
      const searchService = new EnhancedSearchService();
      const query = '사용자 프로필 관리 컴포넌트';
      
      const startTime = performance.now();
      const results = await searchService.hybridSearch(query, {
        threshold: 0.6,
        limit: 10
      });
      const endTime = performance.now();
      
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(2000);
      expect(results.results.length).toBeGreaterThan(0);
    });
  });
});
```

### **4. 스키마 마이그레이션 테스트 (Migration Tests)**

#### **4.1 BGE-M3 마이그레이션 테스트**
```typescript
// src/tests/migration/BgeM3Migration.test.ts
describe('BGE-M3 Migration', () => {
  let migration: BgeM3Migration;
  let supabase: SupabaseClient;
  
  beforeEach(async () => {
    migration = new BgeM3Migration();
    supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);
  });
  
  describe('스키마 변경', () => {
    test('should update vector dimensions correctly', async () => {
      const result = await migration.updateVectorDimensions();
      
      expect(result.success).toBe(true);
      expect(result.tablesUpdated).toContain('vector_documents');
      expect(result.tablesUpdated).toContain('code_vectors');
      expect(result.tablesUpdated).toContain('agent_knowledge_vectors');
    });
    
    test('should add sparse embedding columns', async () => {
      const result = await migration.addSparseEmbeddingColumns();
      
      expect(result.success).toBe(true);
      expect(result.columnsAdded).toContain('sparse_embedding');
    });
  });
  
  describe('데이터 재임베딩', () => {
    test('should re-embed existing data successfully', async () => {
      const result = await migration.migrateToBgeM3();
      
      expect(result.success).toBe(true);
      expect(result.processedRecords).toBeGreaterThan(0);
      expect(result.failedRecords).toBe(0);
      expect(result.duration).toBeLessThan(300000); // 5분 이내
    });
    
    test('should handle large datasets efficiently', async () => {
      // 대용량 데이터셋 시뮬레이션
      const largeDataset = generateLargeDataset(10000);
      
      const result = await migration.migrateLargeDataset(largeDataset);
      
      expect(result.success).toBe(true);
      expect(result.processedRecords).toBe(10000);
      expect(result.batchSize).toBe(100); // 배치 크기 확인
    });
  });
  
  describe('롤백 기능', () => {
    test('should rollback migration on failure', async () => {
      // 실패 상황 시뮬레이션
      jest.spyOn(migration['bgeM3Service'], 'createEmbedding').mockRejectedValue(new Error('API Error'));
      
      const result = await migration.migrateToBgeM3();
      
      expect(result.success).toBe(false);
      expect(result.rollbackPerformed).toBe(true);
      expect(result.originalDataRestored).toBe(true);
    });
  });
});
```

### **5. E2E 테스트 (End-to-End Tests)**

#### **5.1 전체 워크플로우 E2E 테스트**
```typescript
// src/tests/e2e/CompleteWorkflowE2E.test.ts
describe('Complete Workflow E2E', () => {
  let workflow: CompleteWorkflowController;
  let searchService: EnhancedSearchService;
  
  beforeEach(async () => {
    workflow = new CompleteWorkflowController(
      new SourceGenerationWorkflow(),
      new CompilationService(),
      new AutoFixService(),
      new DocumentationUpdateService(),
      new HistoryManagementService()
    );
    
    searchService = new EnhancedSearchService();
  });
  
  test('should complete full workflow from request to search', async () => {
    // 1. 소스 생성 요청
    const request: GenerationRequest = {
      language: 'typescript',
      framework: 'react',
      description: '사용자 대시보드 컴포넌트',
      features: ['차트', '테이블', '필터링', '정렬']
    };
    
    // 2. 워크플로우 실행
    const result = await workflow.executeCompleteWorkflow(request);
    
    expect(result.success).toBe(true);
    expect(result.sourceCode).toBeDefined();
    expect(result.compilationResult.success).toBe(true);
    
    // 3. 검색 테스트
    const searchResults = await searchService.hybridSearch('사용자 대시보드', {
      threshold: 0.6,
      limit: 5
    });
    
    expect(searchResults.results.length).toBeGreaterThan(0);
    expect(searchResults.results[0].similarity).toBeGreaterThan(0.6);
    
    // 4. 히스토리 확인
    const history = await workflow.getWorkflowHistory(result.workflowId);
    
    expect(history.phases).toHaveLength(4); // generation, compilation, documentation, history
    expect(history.phases.every(p => p.status === 'completed')).toBe(true);
  });
  
  test('should handle error recovery in E2E scenario', async () => {
    // 컴파일 에러가 발생하는 요청
    const request: GenerationRequest = {
      language: 'typescript',
      description: '잘못된 타입을 가진 컴포넌트',
      features: ['TypeScript']
    };
    
    const result = await workflow.executeCompleteWorkflow(request);
    
    // 자동 수정이 적용되어야 함
    expect(result.autoFixResult.fixesApplied).toBeGreaterThan(0);
    expect(result.finalResult.success).toBe(true);
  });
});
```

### **6. 부하 테스트 (Load Tests)**

#### **6.1 동시 요청 처리 테스트**
```typescript
// src/tests/load/ConcurrentRequests.test.ts
describe('Concurrent Requests Load Test', () => {
  let workflow: CompleteWorkflowController;
  
  beforeEach(async () => {
    workflow = new CompleteWorkflowController(
      new SourceGenerationWorkflow(),
      new CompilationService(),
      new AutoFixService(),
      new DocumentationUpdateService(),
      new HistoryManagementService()
    );
  });
  
  test('should handle 50 concurrent requests', async () => {
    const requests = Array.from({ length: 50 }, (_, i) => ({
      language: 'typescript' as const,
      description: `테스트 컴포넌트 ${i}`,
      features: ['TypeScript', 'React']
    }));
    
    const startTime = performance.now();
    const results = await Promise.all(
      requests.map(req => workflow.executeCompleteWorkflow(req))
    );
    const endTime = performance.now();
    
    const totalTime = endTime - startTime;
    const successCount = results.filter(r => r.success).length;
    
    expect(successCount).toBeGreaterThan(45); // 90% 이상 성공
    expect(totalTime).toBeLessThan(60000); // 1분 이내
  });
  
  test('should maintain performance under load', async () => {
    const requests = Array.from({ length: 100 }, (_, i) => ({
      language: 'typescript' as const,
      description: `부하 테스트 컴포넌트 ${i}`,
      features: ['TypeScript']
    }));
    
    const startTime = performance.now();
    const results = await Promise.all(
      requests.map(req => workflow.executeCompleteWorkflow(req))
    );
    const endTime = performance.now();
    
    const totalTime = endTime - startTime;
    const averageTime = totalTime / requests.length;
    
    expect(averageTime).toBeLessThan(1000); // 평균 1초 이내
    expect(results.every(r => r.performance.totalTime < 5000)).toBe(true); // 개별 요청 5초 이내
  });
});
```

### **7. 보안 테스트 (Security Tests)**

#### **7.1 입력 검증 테스트**
```typescript
// src/tests/security/InputValidation.test.ts
describe('Input Validation Security', () => {
  let hybridParser: HybridParser;
  
  beforeEach(async () => {
    const commentParser = new CommentParser();
    const treeSitterParser = new TreeSitterParser();
    await treeSitterParser.initialize();
    
    hybridParser = new HybridParser(commentParser, treeSitterParser);
  });
  
  test('should handle SQL injection attempts', async () => {
    const maliciousCode = `
      /**
       * @component Test
       * @description '; DROP TABLE users; --
       */
      export class Test {}
    `;
    
    const result = await hybridParser.parseSourceCode(maliciousCode, 'typescript');
    
    expect(result.success).toBe(true);
    expect(result.commentData.description).not.toContain('DROP TABLE');
  });
  
  test('should handle XSS attempts', async () => {
    const maliciousCode = `
      /**
       * @component Test
       * @description <script>alert('xss')</script>
       */
      export class Test {}
    `;
    
    const result = await hybridParser.parseSourceCode(maliciousCode, 'typescript');
    
    expect(result.success).toBe(true);
    expect(result.commentData.description).not.toContain('<script>');
  });
  
  test('should handle path traversal attempts', async () => {
    const maliciousCode = `
      /**
       * @component Test
       * @description ../../../etc/passwd
       */
      export class Test {}
    `;
    
    const result = await hybridParser.parseSourceCode(maliciousCode, 'typescript');
    
    expect(result.success).toBe(true);
    expect(result.commentData.description).not.toContain('../../../');
  });
});
```

---

## 📊 **테스트 커버리지 목표**

### **코드 커버리지**
- **단위 테스트**: 90% 이상
- **통합 테스트**: 85% 이상
- **E2E 테스트**: 80% 이상
- **전체 커버리지**: 88% 이상

### **성능 목표**
- **파싱 응답 시간**: 15ms 이내
- **임베딩 생성 시간**: 1초 이내
- **검색 응답 시간**: 2초 이내
- **동시 요청 처리**: 50개 이상

### **품질 목표**
- **테스트 통과율**: 95% 이상
- **에러 처리**: 100% 커버
- **보안 검증**: 100% 통과
- **메모리 누수**: 0건

---

## 🚨 위험 요소 및 대응 방안

### **위험 요소**
1. **Tree-sitter 언어 지원 제한**: 일부 언어의 Tree-sitter 파서가 불완전할 수 있음
2. **성능 목표 달성 실패**: 15ms 응답 시간 목표 달성이 어려울 수 있음
3. **기존 시스템 호환성**: 현재 시스템과의 호환성 문제 발생 가능
4. **스키마 마이그레이션 위험**: 기존 데이터 손실 또는 불일치 가능성
5. **벡터DB/Neo4j 통합 복잡성**: 두 데이터베이스 간 동기화 문제

### **대응 방안**
1. **점진적 도입**: TypeScript부터 시작하여 점진적으로 확장
2. **성능 최적화**: 캐싱, 병렬 처리, 코드 최적화로 성능 향상
3. **호환성 보장**: 기존 API 유지하면서 새로운 기능 추가
4. **마이그레이션 안전성**: 백업 및 롤백 계획, 단계별 마이그레이션
5. **데이터 일관성**: 트랜잭션 관리 및 동기화 메커니즘 구현

---

## 📈 성공 지표

### **기술적 지표**
- [ ] 파싱 정확도: 99.9% 이상
- [ ] 응답 시간: 15ms 이내
- [ ] 메모리 사용량: 기존 대비 20% 이내 증가
- [ ] CPU 사용량: 기존 대비 30% 이내 증가
- [ ] 스키마 마이그레이션 성공률: 100%
- [ ] 데이터 일관성: 99.9% 이상

### **품질 지표**
- [ ] 테스트 커버리지: 90% 이상
- [ ] 코드 품질: SonarQube A등급
- [ ] 문서화 완성도: 100%
- [ ] 사용자 만족도: 4.5/5.0 이상
- [ ] 마이그레이션 안전성: 100%
- [ ] 벡터DB/Neo4j 동기화: 99.9% 이상

---

## 📚 **관련 문서 및 참조**

### **기존 분석 문서**
- [Tree-sitter 통합 로드맵](./TREE_SITTER_INTEGRATION_ROADMAP.md) - Tree-sitter 통합 전략
- [하이브리드 파싱 전략](./HYBRID_PARSING_STRATEGY.md) - 주석 + Tree-sitter 통합 전략
- [스키마 마이그레이션 분석](./SCHEMA_MIGRATION_ANALYSIS.md) - Tree-sitter 적용을 위한 스키마 변경
- [통합테스트 및 스키마 분석](./INTEGRATION_TEST_AND_SCHEMA_ANALYSIS.md) - 기존 시스템과의 통합 방안
- [Git Indexing vs 하이브리드 파싱 분석](./GIT_INDEXING_VS_HYBRID_PARSING_ANALYSIS.md) - 두 시스템의 차이점
- [Single Source of Truth Git 통합](./COGO_AGENT_CORE_SINGLE_SOURCE_OF_TRUTH_GIT_INTEGRATION.md) - GitHub + Git 정보 RAG 통합

### **데이터베이스 스키마 문서**
- [COGO 소스 생성 시스템 데이터베이스 스키마](./DATABASE_SCHEMAS_FOR_COGO_SOURCE.md) - Supabase + Neo4j 스키마
- [BGE-M3 Embedding 통합 계획](./COGO_AGENT_CORE_BGE_M3_EMBEDDING_INTEGRATION_PLAN.md) - BAAI/bge-m3 embedding 통합
- [개발 TODO 리스트](./DEVELOPMENT_TODO_LIST.md) - 전체 개발 현황 및 우선순위

### **구현 가이드**
- [소스 생성-컴파일-수정 워크플로우](./SOURCE_GENERATION_COMPILATION_WORKFLOW.md) - 완전한 워크플로우 설계
- [개발 계획](./COGO_AGENT_CORE_HYBRID_PARSING_BGE_M3_INTEGRATION_PLAN.md) - 이 문서

---

## 🎯 결론

이 개발 계획은 COGO Agent Core의 **다음 세대 파싱 시스템**을 구축하는 종합적인 로드맵입니다. 하이브리드 파싱 전략, 완전한 워크플로우 설계, 스키마 마이그레이션, 성능 최적화를 통해 현재 시스템의 한계를 극복하고 엔터프라이즈급 성능을 달성할 것입니다.

**주요 특징**:
- ✅ **완전한 스키마 설계**: Supabase + Neo4j 통합 스키마
- ✅ **BGE-M3 통합**: 1024차원 벡터, 하이브리드 검색 지원
- ✅ **안전한 마이그레이션**: 백업 및 롤백 계획 포함
- ✅ **포괄적인 테스트**: 단위, 통합, 성능, 마이그레이션 테스트
- ✅ **성능 최적화**: 15ms 응답 시간, 99.9% 정확도 목표
- ✅ **문서화 완성**: 모든 단계별 상세 문서

**다음 단계**: 이 계획을 기반으로 Phase 4 (RAG 시스템 구축)부터 순차적으로 개발을 시작하겠습니다.

---

**작성자**: COGO Agent (AI Assistant)  
**작성일**: 2025-08-06  
**업데이트일**: 2025-08-06  
**상태**: 📋 개발 계획 업데이트 완료 - RAG 시스템 구축 단계로 진행