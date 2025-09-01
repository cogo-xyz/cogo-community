# COGO Agent Core - Documentation Index

## 📚 완성된 주요 문서 목록

### 🎯 핵심 시스템 문서
1. **[DISTRIBUTED_AGENT_ARCHITECTURE_UPDATE.md](./DISTRIBUTED_AGENT_ARCHITECTURE_UPDATE.md)** - 현재 표준 아키텍처(구성요소/데이터/시퀀스 포함)
2. **[DISTRIBUTED_AGENT_SYSTEM.md](./DISTRIBUTED_AGENT_SYSTEM.md)** - 레거시 개요(참고용)
3. **[WORKER_MANAGEMENT_INTEGRATION.md](./WORKER_MANAGEMENT_INTEGRATION.md)** - Worker 관리 시스템 통합
4. **[COMPREHENSIVE_TEST_SYSTEM.md](./COMPREHENSIVE_TEST_SYSTEM.md)** - Interface-Preserving 테스트 시스템
5. **[FUTURE_DEVELOPMENT_ROADMAP.md](./FUTURE_DEVELOPMENT_ROADMAP.md)** - 향후 개발 계획 로드맵

### 🔧 기술 아키텍처 문서
5. **[COMMUNICATION_SEPARATED_DEVELOPMENT_STRATEGY.md](./COMMUNICATION_SEPARATED_DEVELOPMENT_STRATEGY.md)** - 개발 전략
6. **[SELF_UPGRADING_DISTRIBUTED_AGENT_ECOSYSTEM.md](./SELF_UPGRADING_DISTRIBUTED_AGENT_ECOSYSTEM.md)** - 자가 업그레이드 시스템
7. **[INTERFACE_PRESERVING_TEST_SYSTEM.md](./INTERFACE_PRESERVING_TEST_SYSTEM.md)** - 테스트 시스템 설계
8. **[INTEGRATED_REFACTORING_MASTER_PLAN.md](./INTEGRATED_REFACTORING_MASTER_PLAN.md)** - 통합 리팩토링 계획

### 📖 API 및 설정 문서
9. **[API_REFERENCE.md](./API_REFERENCE.md)** - REST API 개요(세부는 OpenAPI 문서 예정)
10. **[API_KEY_SETUP_GUIDE.md](./API_KEY_SETUP_GUIDE.md)** - 키 설정
11. **[SQL_EDITOR_SCHEMA_SETUP.md](./SQL_EDITOR_SCHEMA_SETUP.md)** - DB 스키마 설정
12. **[DISTRIBUTED_KEY_MANAGEMENT_DESIGN.md](./DISTRIBUTED_KEY_MANAGEMENT_DESIGN.md)** - 분산 키 관리
13. **[REALTIME_CHANNELS_AND_USAGE.md](./REALTIME_CHANNELS_AND_USAGE.md)** - Realtime vs 트랜잭션 스트림 가이드(2025-08-09 갱신)
14. **[DEVELOPMENT_PLAN_RECOMMENDED.md](./DEVELOPMENT_PLAN_RECOMMENDED.md)** - 권장 개발 계획서(2025-08-09)
15. **[openapi/collab.yaml](./openapi/collab.yaml)** - Collab API OpenAPI 스펙(메트릭/워커 포함)
16. **[DEPLOYMENT_AND_OPERATIONS.md](./DEPLOYMENT_AND_OPERATIONS.md)** - 배포/운영 가이드(EF/Collab/JWT)
17. **[VERIFICATION_CHECKLIST_API.md](./VERIFICATION_CHECKLIST_API.md)** - API-only 검증 체크리스트(헬스/잡/워커/EF/DLQ)
18. **[COLLAB_API_FLOW_GUIDE.md](./COLLAB_API_FLOW_GUIDE.md)** - Collab API 플로우 요약(Assign→Claim→Result→DLQ/Retry)
19. **[EDGE_FUNCTIONS_OVERVIEW.md](./EDGE_FUNCTIONS_OVERVIEW.md)** - Supabase Edge Functions 개요 및 사용 가이드
20. **[openapi/edge-functions.yaml](./openapi/edge-functions.yaml)** - Edge Functions OpenAPI 스펙
21. **[CI_SECRETS_AND_BRANCH_PROTECTION.md](./CI_SECRETS_AND_BRANCH_PROTECTION.md)** - CI 시크릿/브랜치 보호 가이드
22. **[integration/MCP-Figma.md](./integration/MCP-Figma.md)** - MCP: Cursor↔Figma(TalkToFigma) 연동 가이드

### 🧭 운영·정책 요약
- **[policies/Agents-Function-Coverage.md](./policies/Agents-Function-Coverage.md)** - 에이전트 기능/계약/이벤트/스모크/수용 기준 요약
- **[policies/Operational-Acceptance-Gates.md](./policies/Operational-Acceptance-Gates.md)** - 운영 게이트(주기/임계치/스케줄링/알림)
- **[policies/Bus-Reclaimer-Retention.md](./policies/Bus-Reclaimer-Retention.md)** - 버스 리클레임/보존/DLQ 정책 및 스크립트

### ⚙️ Worker 관리 문서
13. **[WORKER_MANAGEMENT_ARCHITECTURE.md](./WORKER_MANAGEMENT_ARCHITECTURE.md)** - Worker 아키텍처
14. **[DISTRIBUTED_WORKER_MANAGEMENT.md](./DISTRIBUTED_WORKER_MANAGEMENT.md)** - 분산 Worker 관리

## 🎉 문서화 완성 현황

### ✅ 완료된 영역
- **시스템 아키텍처**: 분산 Agent, Worker 관리, 테스트 시스템
- **개발 전략**: Communication-Separated Development
- **기술 설계**: Interface-Preserving, Self-Upgrading
- **향후 계획**: 3개월 로드맵, 우선순위, 성공 지표

### 📊 문서 통계
- **총 문서 수**: 16+ 개 주요 문서
- **커버리지**: 아키텍처/개발/테스트/운영(현행 Collab+Realtime+Edge 반영)
- **업데이트**: 2025-08-09 기준 최신

---

**다음 우선순위**: Edge Functions(메트릭/잡/아티팩트/워커) 배포/검증 및 대시보드 실시간 반영 문서화
