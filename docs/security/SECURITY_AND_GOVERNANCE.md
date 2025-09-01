### Security and Governance for Chat Artifacts

Scope: artifacts 저장/전달/열람 정책

Storage
- Supabase Storage bucket `artifacts` 사용, 서브폴더 도메인별 분리(ui/, figma/, bdd/, actionflow/, logs/)
- 대용량은 파일로 저장, 응답에는 링크/ID만 노출

Access
- 서명 URL(기본 만료 10분), 필요 시 재발급 API
- MIME allowlist, 크기 제한, 바이러스 스캔(옵션)

PII/Secret
- 민감 데이터 스크럽/마스킹 후 저장 권고
- 프롬프트/로그의 키/토큰 제거 규칙 명시

Audit
- `cogo.artifacts` 메타 기록(trace_id, task_type, actor, project_id)
- 다운로드/재발급 로깅(옵션)

Retention
- 기본 30일 보관(예시), 프로젝트 정책으로 연장/단축


