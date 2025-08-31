# COGO Community

Public monorepo for COGO plugins, SDKs, examples, documentation, and testing scenarios.

COGO is an AI-powered platform that bridges design systems and code generation, supporting collaboration between designers and developers through Figma plugins and real-time agent communication.

## 🏗️ Project Structure

### Core Packages
- **packages/figma-plugin**: Main Figma plugin for UUI/COGO conversion and real-time features
  - UUI & COGO conversion capabilities
  - SSE streaming support for real-time communication
  - Presence API integration for session management
  - Multi-language support and advanced error handling
  - Backup folders: `_backup_YYYYMMDD-HHMMSS/` - Automatic version backup storage

### Documentation
- **docs/**: Comprehensive documentation covering all aspects of COGO
  - Agent specifications and API references
  - Integration guides and user manuals
  - Testing scenarios and examples
  - Security policies and operational procedures

## 🚀 Quick Start (Figma Plugin)

### 1. Development Environment Setup
```bash
# Clone project and install dependencies
npm ci

# Build all packages
npm run build
```

### 2. Figma Plugin Installation
1. Figma → Plugins → Development → Import plugin from manifest
2. Select manifest.json from the following path:
   - `packages/figma-plugin/manifest.json`

### 3. Plugin Build (if needed)
```bash
cd packages/figma-plugin
npm install
npm run build
```

### 4. Plugin Configuration
Open the plugin and enter the following settings:
- **Edge URL**: Supabase Functions base URL (e.g., `https://<ref>.functions.supabase.co`)
- **Anon Key**: Supabase anonymous key (available in development environment)
- **Agent ID** (optional): Header for multi-instance (e.g., `cogo0`)
- **Project ID**: Target project UUID

### 5. Feature Testing
- **Convert Selection** → UUI & COGO conversion with advanced error handling
- **Generate / Generate via LLM** → AI-powered generation with RAG integration
- **Upload & Ingest** → Large JSON data processing with artifact storage
- **Chat SSE, Figma Context SSE** → Real-time streaming with Presence API
- **Presence Register/Unregister** → Session management and user tracking
- **Context Start/Apply** → Figma page scanning and result application
- **Multi-language Support** → Localized UI messages and error handling

## 📚 Documentation

### 🤖 Agent & API Documentation
- **Agent Specifications**:
  - `docs/COGO_AGENT_CHAT_MESSAGE_SPEC.md` - Complete chat message protocol specification
  - `docs/AGENTS_API_INDEX.md` - Agent API reference index
  - `docs/COGO_AGENT_OVERVIEW.md` - Agent system overview
- **API References** (`docs/api/`):
  - `EDGE_FIGMA_PLUGIN_PROTOCOL.md` - Edge-Figma plugin communication protocol
  - `EDGE_FUNCTIONS_OVERVIEW.md` - Edge functions architecture overview
  - `EDGE_TEST_GUIDE.md` - Edge functions testing guide

### 📖 User Guides & Manuals
- **Manuals**: `docs/manuals/`
  - `COGO_User_Manual.md` - Complete user manual
  - `Developer_Manual.md` - Developer guide
  - `Designer_Chatting_Guide.md` - Designer collaboration guide
  - `COGO_User_Scenarios.md` - User scenario documentation

### 🔧 Integration & Examples
- **Integration Guides**: `docs/integration/`
  - `FIGMA_PLUGIN_USER_GUIDE.md` - Figma plugin integration guide
- **Examples**: `docs/examples/`
  - `FIGMA_PLUGIN_EXAMPLES.md` - Figma plugin usage examples
- **Quick Start**: `docs/QUICKSTART_TESTING.md` - Quick start testing guide

### 🧪 Testing & Scenarios
- **BDD to ActionFlow**: `docs/BDD_TO_ACTIONFLOW.md` - BDD to ActionFlow conversion guide
- **Scenarios**: `docs/scenarios/`
  - **Figma Scenarios**: `docs/scenarios/figma/`
    - User Intent: `1_user_intent.md`
    - Symbol Definition: `2_symbols.json`
    - BDD Scenario: `3_bdd.feature`
    - ActionFlow: `4_actionflow.json`
  - **Login Scenarios**: `docs/scenarios/login/`
    - User Intent: `1_user_intent.md`
    - Technical Documentation: `TECHNICAL_DOC.md`
    - User Manual: `USER_MANUAL.md`
  - **Chat Scenarios**: `docs/scenarios/chat/`

### 🏭 Operations & Management
- **Observability**: `docs/observability/`
  - `INTENT_RESOLVE_METRICS.md` - Intent resolution metrics
- **Security**: `docs/security/`
  - `SECURITY_HARDENING.md` - Security hardening guide
- **Management**: `docs/management/`
  - `ARTIFACTS_RETENTION.md` - Artifacts retention policy
- **Planning**: `docs/plans/`
  - `INTENT_KEYWORD_REGISTRY.md` - Intent keyword registry plan

### 🔌 Development Resources
- **Postman Collection**: `docs/postman/COGO.postman_collection.json` - API testing collection
- **Runbooks**: `docs/runbook/`
  - `NIGHTLY_FLOW.md` - Nightly flow operations
  - `SECURITY_METRICS.md` - Security metrics monitoring

## ⚠️ Important Notes
- **Development Environment**: Direct Edge/Anon key input allowed
- **Production Environment**: Short-lived JWT/HMAC tokens recommended
- **Event Logging**: Events and audit logs sent to `cogo` domain (e.g., `bus_events`)
- **Package Structure**: Figma plugin managed through npm workspaces
- **Backup System**: Automatic backup creation with timestamped folders
- **Documentation**: Comprehensive docs covering all COGO aspects
- **Multi-language Support**: Figma plugin supports multiple languages

## 🤝 Contributing Guidelines

### Development Workflow
1. Create issue or check existing issues
2. Create feature branch: `git checkout -b feature/your-feature-name`
3. Implement and test changes
4. Commit: `git commit -m "feat: add your feature description"`
5. Create PR and request code review

### Coding Conventions
- **TypeScript**: ESLint + Prettier for consistent code formatting
- **Build System**: esbuild for fast compilation and bundling
- **Package Management**: npm workspaces for monorepo management
- **Commit Messages**: [Conventional Commits](https://conventionalcommits.org/) format
- **Branch Naming**: `feature/`, `fix/`, `docs/`, `refactor/` prefixes
- **Documentation**: All docs in English with clear structure

## 📄 License

This project is distributed under the license specified in the [LICENSE](LICENSE) file.

## 📞 Support & Contact

- **Documentation**: Refer to the documentation section above
- **Quick Start**: `docs/QUICKSTART_TESTING.md` for immediate setup help
- **API Testing**: `docs/postman/COGO.postman_collection.json` for API testing
- **Issues**: Bug reports and feature requests at [GitHub Issues](https://github.com/creatego-io/cogo-community/issues)
- **Discussions**: General discussions at [GitHub Discussions](https://github.com/creatego-io/cogo-community/discussions)
- **Security**: Security issues at [GitHub Security](https://github.com/creatego-io/cogo-community/security)

---

<div align="center">

**Thank you for your interest in COGO Community!** 🚀

*Let's work together for the perfect integration of design and code*

</div>


## SDK & CLI Guides
- SDK (TypeScript): docs/SDK_TS.md
- SDK (Flutter): docs/SDK_FLUTTER.md
- CLI (Flutter): docs/CLI_COGO_FLUTTER.md
- Plan: docs/plans/COGO_CLI_DESIGN.md

## New Packages
- packages/cogo-chat-sdk-ts
- packages/cogo-chat-sdk-flutter
- packages/cogo-cli-flutter
- packages/cogo-figma-plugin

## Figma Plugin Guides
- Protocol: docs/EDGE_FIGMA_PLUGIN_PROTOCOL.md
- User Guide: docs/FIGMA_PLUGIN_USER_GUIDE.md
- Examples: docs/FIGMA_PLUGIN_EXAMPLES.md


Note:
- Ingest result returns { bucket, key, signedUrl }. key is bucket-relative; prefer using signedUrl to download.
