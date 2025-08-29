# COGO Community

Public monorepo for COGO plugins, SDKs, examples, documentation, and testing scenarios.

COGO is an AI-powered platform that bridges design systems and code generation, supporting collaboration between designers and developers through Figma plugins.

## 🏗️ Project Structure

### Packages
- **packages/figma-plugin**: Figma plugin providing UUI/COGO conversion, data collection, and SSE testing features

### Tools
- **tools/figma-plugin**: Development and deployment environment for Figma plugin builds
  - Backup folders: `_backup_YYYYMMDD-HHMMSS/` - Previous version storage

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

### 3. Plugin Configuration
Open the plugin and enter the following settings:
- **Edge URL**: Supabase Functions base URL (e.g., `https://<ref>.functions.supabase.co`)
- **Anon Key**: Supabase anonymous key (available in development environment)
- **Agent ID** (optional): Header for multi-instance (e.g., `cogo0`)
- **Project ID**: Target project UUID

### 4. Feature Testing
- **Convert Selection** → UUI & COGO conversion
- **Generate / Generate via LLM** → AI-powered generation
- **Upload & Ingest** → Large JSON data processing
- **Chat SSE, Figma Context SSE** → Real-time streaming

## 📚 Documentation

### 🔧 User Guides & Manuals
- **Figma Plugin Integration**: `docs/integration/FIGMA_PLUGIN_USER_GUIDE.md`
- **User Manual**: `docs/manuals/COGO_User_Manual.md`
- **Developer Manual**: `docs/manuals/Developer_Manual.md`
- **Designer Chatting Guide**: `docs/manuals/Designer_Chatting_Guide.md`
- **User Scenarios**: `docs/manuals/COGO_User_Scenarios.md`

### 💡 Examples & Tutorials
- **Figma Plugin Examples**: `docs/examples/FIGMA_PLUGIN_EXAMPLES.md`
- **Plugin Examples (Root)**: `docs/FIGMA_PLUGIN_EXAMPLES.md`

### 🧪 Testing & Scenarios
- **Quick Start Testing**: `docs/QUICKSTART_TESTING.md`
- **BDD to ActionFlow Guide**: `docs/BDD_TO_ACTIONFLOW.md`
- **Figma Scenarios**: `docs/scenarios/figma/README.md`
  - User Intent: `docs/scenarios/figma/1_user_intent.md`
  - Symbol Definition: `docs/scenarios/figma/2_symbols.json`
  - BDD Scenario: `docs/scenarios/figma/3_bdd.feature`
  - ActionFlow: `docs/scenarios/figma/4_actionflow.json`
- **Login Scenarios**: `docs/scenarios/login/README.md`
  - User Intent: `docs/scenarios/login/1_user_intent.md`
  - Technical Documentation: `docs/scenarios/login/TECHNICAL_DOC.md`
  - User Manual: `docs/scenarios/login/USER_MANUAL.md`
- **Chat Scenarios**: `docs/scenarios/chat/README.md`

### 🔌 API & Protocols
- **Agent Chat Message Spec**: `docs/COGO_AGENT_CHAT_MESSAGE_SPEC.md`
- **Edge-Figma Plugin Protocol**: `docs/EDGE_FIGMA_PLUGIN_PROTOCOL.md`
- **Postman Collection**: `docs/postman/COGO.postman_collection.json`

### 🏭 Development & Operations
- **Agent Observability Plan**: `docs/AGENT_OBSERVABILITY_PLAN.md`
- **Nightly Flow Runbook**: `docs/runbook/NIGHTLY_FLOW.md`
- **Security Metrics**: `docs/runbook/SECURITY_METRICS.md`

## ⚠️ Important Notes
- **Development Environment**: Direct Edge/Anon key input allowed
- **Production Environment**: Short-lived JWT/HMAC tokens recommended
- **Event Logging**: Events and audit logs sent to `cogo` domain (e.g., `bus_events`)
- **Monorepo Structure**: Multi-package management through workspaces

## 🤝 Contributing Guidelines

### Development Workflow
1. Create issue or check existing issues
2. Create feature branch: `git checkout -b feature/your-feature-name`
3. Implement and test changes
4. Commit: `git commit -m "feat: add your feature description"`
5. Create PR and request code review

### Coding Conventions
- TypeScript/JavaScript: ESLint + Prettier usage
- Commit Messages: [Conventional Commits](https://conventionalcommits.org/) format
- Branch Naming: `feature/`, `fix/`, `docs/`, `refactor/` prefixes

## 📄 License

This project is distributed under the license specified in the [LICENSE](LICENSE) file.

## 📞 Support & Contact

- **Documentation**: Refer to the documentation section above
- **Issues**: Bug reports and feature requests at [GitHub Issues](../../issues)
- **Discussions**: General discussions at [GitHub Discussions](../../discussions)

---

<div align="center">

**Thank you for your interest in COGO Community!** 🚀

*Let's work together for the perfect integration of design and code*

</div>

