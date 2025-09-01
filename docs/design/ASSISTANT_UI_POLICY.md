### Assistant-UI Policy (Separation)

Decision
- 본 레포의 Assistant-UI는 데모/개발 편의 목적이며, 프로덕션용 UI는 별도 프로젝트로 분리한다.

Rationale
- 독립 릴리즈 주기/품질 기준 유지
- Edge/Backend와 결합도 축소, 환경 의존성/설정 충돌 최소화

Implications
- 본 레포 테스트는 `curl`/스크립트 중심 유지
- 별도 UI 프로젝트에서 `artifacts`/`trace_id`/SSE를 1급 기능으로 지원

Migration
- README에 분리 정책 및 레퍼런스 링크 추가
- 기존 Assistant-UI는 유지하되 “not recommended for prod” 명시


