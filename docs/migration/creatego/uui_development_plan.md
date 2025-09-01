### UUI 개발 계획 배치(실행 순서)

- 목표/범위
  - UUI 스키마 확장(페이지/프래그먼트/바인딩/오버라이드), Figma→UUI 변환 품질 고도화
  - CreateGo UI JSON 호환 어댑터 제공(테스트는 기존 샘플 축약판으로)
  - 성능(증분 파싱/렌더), 스트리밍(부분 페이지) 대비 구조 확립
  - CI/골든/메트릭으로 회귀 방지

---

### 배치 1: 스키마/문서 정리
- 작업
  - UUI 설계 문서 확정: `docs/migration/creatego/uui_design.md` 유지/보강
  - 스키마 확장 점검: `configs/uuis.schema.json`(features/index/pages/page.kind/fragment/contentHash/deps/bindings/platform/$legacy)
  - OpenAPI/Types 재생성 점검
- 산출물: 업데이트된 UUI 설계 문서, 스키마 파일
- 검증: `npm run types:ui` 성공, `npm run ci:ui:full` 그린

### 배치 2: AST 파이프라인 확장(틀 추가)
- 작업
  - BindingsPass(정적 바인딩 필드 정규화)
  - PlatformOverridePass(플랫폼별 최소 오버라이드 주입/검증)
  - FragmentAssemblePass(페이지/프래그먼트 조립의 바운더리 틀)
  - SchemaGuardPass(Ajv로 최종/증분 검증)
- 산출물: `src/ast/uuis/passes/*` 스켈레톤 + 오케스트레이터 연결
- 검증: `ci:ui:full` 그린, 골든 변화 최소

### 배치 3: CreateGo 호환 어댑터(입력→UUI)
- 작업
  - `CreateGoToUuiAdapter` 도입: CreateGo JSON → UUI(룰 기반), `$legacy` 보존
  - 옵션 경로: `/api/ui/convert`에서 `{ compat: 'creatego' }` 처리 경로만 추가(플래그)
- 산출물: 어댑터 모듈, 라우트 옵션 처리
- 검증: 축약 샘플 입력→UUI 변환 성공, 실패 시 아티팩트/로그 남김

### 배치 4: 룰 확장(컴포넌트/입력/컨테이너)
- 작업
  - `configs/figma_rules/*` 확장: Card/List/Inputs/Button 등 매핑 보강
  - 룰 버전 해시(__rules_v) 유지, 충돌 시 스킵/로그
- 산출물: 룰 파일 업데이트, 맵핑표 갱신
- 검증: 골든 테스트 자동 갱신, 의도치 않은 변화 없음

### 배치 5: 스트리밍 사양 초안(문서+타입)
- 작업: 조각 메시지 스펙(pageChunk/pagePatch) 문서화, OpenAPI 타입 정의 생성(서버 구현은 다음 단계)
- 산출물: 문서/타입
- 검증: 타입 빌드 성공

### 배치 6: 성능·증분 처리 고도화
- 작업: 해시 재사용률/변환 레이턴시 메트릭, TokenAliasPass/NormalizePass 비용 큰 변환 사전 적용
- 산출물: 메트릭/최적화 코드
- 검증: Metrics 요약에서 UI 섹션 확인

### 배치 7: 테스트/CI 강화
- 작업: 다양한 페이지/컴포넌트 축약 케이스 추가, `ci:ui:health`(옵션)
- 산출물: 신규 픽스처/골든, CI 유지
- 검증: `npm run ci:ui:full` 그린

### 배치 8: 인덱싱/그래프 연계(선택)
- 작업: `UI_AST_TO_NEO4J=true` 시 UUI 노드 업서트 + 부모-자식 `:CONTAINS`
- 산출물: 인덱서 통계
- 검증: 로컬 Neo4j로 업서트 확인

### 배치 9: 운영/문서/가드
- 작업: `/api/ui/*` ADMIN 토큰 가드/정책 확인, 문서 링크/명칭 UUI로 일관 정리
- 산출물: 정책/문서 업데이트
- 검증: 정책 적용 후 라우트 접근 정상

### 수용 기준(Definition of Done)
- UUI 스키마/문서/타입 정합
- Figma→UUI 변환 파이프라인 정상(룰/레이아웃/이벤트/토큰/해시)
- CreateGo 호환 입력→UUI 변환 플래그 경로 동작(축약 샘플)
- CI 그린: `npm run ci:ui:full`


