## CreateGo → cogo 마이그레이션 실행 계획(상세)

### 전략 요약
- Python CreateGo는 사이드카/브릿지로 우선 통합하고, 기능 단위로 TS 리라이팅(A/B 검증) 후 전환
- 데이터·프로토콜 호환을 선행 확보(Supabase/Neo4j/Realtime)

### 작업 항목(체크리스트)
1. 인벤토리 문서화
   - [ ] Supabase 스키마 인벤토리 업데이트
   - [ ] Neo4j 모델 매핑 업데이트
   - [ ] Realtime 이벤트 카탈로그 업데이트
2. 브릿지/호환 레이어
   - [ ] `src/services/legacy/creatego/ProtocolAdapter.ts`
   - [ ] `src/workers/CreateGoBridgeWorker.ts`
3. DB 마이그레이션(SQL)
   - [ ] `supabase/migrations/creatego_compat/*.sql`
   - [ ] 검증 스크립트 `src/scripts/migration/validateSupabaseCompat.ts`
4. Graph 마이그레이션(Cypher)
   - [ ] `neo4j/migrations/creatego_compat/*.cypher`
   - [ ] 검증 스크립트 `src/scripts/migration/validateNeo4jCompat.ts`
5. 기능 리라이팅(단계)
   - [ ] Figma→UI 변환 서비스/워커
   - [ ] BDD 생성 서비스/워커
   - [ ] Action/ActionFlow 합성 서비스/워커
6. 통합 테스트/게이트
   - [ ] E2E(샘플 데이터) 파이프라인
   - [ ] MCP 핑 + 회로/리트라이 시나리오
   - [ ] 실패 시 알림

### 스위치오버/롤백
- Feature Flag로 라우팅 제어, Shadow Write로 결과 비교
- 실패 시 즉시 Python 경로로 되돌림, 브릿지 로그/아티팩트 참조


