# Knowledge Graph Scope v1 (TS + PY)

본 문서는 CBO 빌더가 인덱싱할 소스 범위를 고정하기 위한 스코프 정의입니다. 실행 파일과 설정 파일은 다음과 같습니다.

- 설정: `configs/kg_scope.v1.json`
- 실행: `npx ts-node src/scripts/cbo/runScope.ts [configs/kg_scope.v1.json]`

## 범위(초안)
- 언어: TypeScript(우선), Python(준비)
- 경로 (execution-first): `src/servers`, `src/services`, `src/knowledge`, `src/scripts/rag`, `src/workers`, `src/routes`, `src/ai`, `src/types`
- 제외: test/samples/legacy/generated, `**/*.d.ts`
- 파일 확장자: TS(`.ts,.tsx`), Python(`.py`)

## 실행 절차
1) 환경 변수 준비: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
2) TS 인덱싱: 설정 기준으로 파일 리스트 생성 → `buildCboV2.ts` 배치 실행
3) (선택) Neo4j 투영: `cbo:neo4j`

## 출력
- Supabase: `cbo_objects`, `cbo_relations`, (선택) `vector_documents`
- 메타데이터: `metadata.language`, `params_json`, `returns_json`, `fields_json`, `start_line`, `end_line`

---
Back to plan: [docs/DEVELOPMENT_EXECUTION_PLAN_NEXT.md](../DEVELOPMENT_EXECUTION_PLAN_NEXT.md)
