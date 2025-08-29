# COGO Community

Public monorepo for COGO plugins, SDKs, examples, documentation, and testing scenarios.

COGO는 디자인 시스템과 코드 생성을 연결하는 AI 기반 플랫폼으로, Figma 플러그인을 통해 디자이너와 개발자의 협업을 지원합니다.

## 🏗️ 프로젝트 구조

### Packages
- **packages/figma-plugin**: Figma 플러그인으로 UUI/COGO 변환, 데이터 수집 및 SSE 테스트 기능 제공

### Tools
- **tools/figma-plugin**: 개발 및 배포용 Figma 플러그인 빌드 환경
  - 백업 폴더: `_backup_YYYYMMDD-HHMMSS/` - 이전 버전 보관

## 🚀 빠른 시작 (Figma 플러그인)

### 1. 개발 환경 설정
```bash
# 프로젝트 클론 및 의존성 설치
npm ci

# 모든 패키지 빌드
npm run build
```

### 2. Figma 플러그인 설치
1. Figma → Plugins → Development → Import plugin from manifest
2. 다음 경로에서 manifest.json 선택:
   - 개발용: `tools/figma-plugin/manifest.json`
   - 패키지용: `packages/figma-plugin/manifest.json`

### 3. 플러그인 설정
플러그인을 열고 다음 설정 입력:
- **Edge URL**: Supabase Functions base URL (예: `https://<ref>.functions.supabase.co`)
- **Anon Key**: Supabase 익명 키 (개발 환경에서 사용 가능)
- **Agent ID** (선택): 다중 인스턴스용 헤더 (예: `cogo0`)
- **Project ID**: 대상 프로젝트 UUID

### 4. 기능 테스트
- **Convert Selection** → UUI & COGO 변환
- **Generate / Generate via LLM** → AI 기반 생성
- **Upload & Ingest** → 대용량 JSON 데이터 처리
- **Chat SSE, Figma Context SSE** → 실시간 스트리밍

## 📚 문서

### 🔧 사용자 가이드 및 매뉴얼
- **Figma 플러그인 통합**: `docs/integration/FIGMA_PLUGIN_USER_GUIDE.md`
- **사용자 매뉴얼**: `docs/manuals/COGO_User_Manual.md`
- **개발자 매뉴얼**: `docs/manuals/Developer_Manual.md`
- **디자이너 채팅 가이드**: `docs/manuals/Designer_Chatting_Guide.md`
- **사용자 시나리오**: `docs/manuals/COGO_User_Scenarios.md`

### 💡 예제 및 튜토리얼
- **Figma 플러그인 예제**: `docs/examples/FIGMA_PLUGIN_EXAMPLES.md`
- **플러그인 예제 (루트)**: `docs/FIGMA_PLUGIN_EXAMPLES.md`

### 🧪 테스트 및 시나리오
- **빠른 시작 테스트**: `docs/QUICKSTART_TESTING.md`
- **BDD to ActionFlow 가이드**: `docs/BDD_TO_ACTIONFLOW.md`
- **Figma 시나리오**: `docs/scenarios/figma/README.md`
  - 사용자 의도: `docs/scenarios/figma/1_user_intent.md`
  - 심볼 정의: `docs/scenarios/figma/2_symbols.json`
  - BDD 시나리오: `docs/scenarios/figma/3_bdd.feature`
  - 액션플로우: `docs/scenarios/figma/4_actionflow.json`
- **로그인 시나리오**: `docs/scenarios/login/README.md`
  - 사용자 의도: `docs/scenarios/login/1_user_intent.md`
  - 기술 문서: `docs/scenarios/login/TECHNICAL_DOC.md`
  - 사용자 매뉴얼: `docs/scenarios/login/USER_MANUAL.md`
- **채팅 시나리오**: `docs/scenarios/chat/README.md`

### 🔌 API 및 프로토콜
- **에이전트 채팅 메시지 스펙**: `docs/COGO_AGENT_CHAT_MESSAGE_SPEC.md`
- **Edge-Figma 플러그인 프로토콜**: `docs/EDGE_FIGMA_PLUGIN_PROTOCOL.md`
- **Postman 컬렉션**: `docs/postman/COGO.postman_collection.json`

### 🏭 개발 및 운영
- **에이전트 관측성 계획**: `docs/AGENT_OBSERVABILITY_PLAN.md`
- **야간 플로우 런북**: `docs/runbook/NIGHTLY_FLOW.md`
- **보안 메트릭스**: `docs/runbook/SECURITY_METRICS.md`

## ⚠️ 중요 노트
- **개발 환경**: Edge/Anon 키 직접 입력 허용
- **운영 환경**: 단기 JWT/HMAC 토큰 권장
- **이벤트 로깅**: `cogo` 도메인으로 이벤트 및 감사 로그 전송 (예: `bus_events`)
- **모노레포 구조**: workspaces를 통한 다중 패키지 관리

## 🤝 기여 방법

### 개발 워크플로우
1. 이슈 생성 또는 기존 이슈 확인
2. 기능 브랜치 생성: `git checkout -b feature/your-feature-name`
3. 변경사항 구현 및 테스트
4. 커밋: `git commit -m "feat: add your feature description"`
5. PR 생성 및 코드 리뷰 요청

### 코딩 컨벤션
- TypeScript/JavaScript: ESLint + Prettier 사용
- 커밋 메시지: [Conventional Commits](https://conventionalcommits.org/) 형식
- 브랜치 네이밍: `feature/`, `fix/`, `docs/`, `refactor/` 접두사 사용

## 📄 라이선스

이 프로젝트는 [LICENSE](LICENSE) 파일에 명시된 라이선스에 따라 배포됩니다.

## 📞 지원 및 문의

- **문서**: 상단의 문서 섹션 참조
- **이슈**: [GitHub Issues](../../issues)에서 버그 리포트 및 기능 요청
- **토론**: [GitHub Discussions](../../discussions)에서 일반적인 논의

---

<div align="center">

**COGO Community**에 관심을 가져주셔서 감사합니다! 🚀

*디자인과 코드의 완벽한 통합을 위해 함께 만들어가요*

</div>

