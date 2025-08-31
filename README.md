# COGO Community

Public monorepo for COGO plugins, SDKs, examples, documentation, and testing scenarios.

COGO is a comprehensive AI-powered platform that bridges design systems and code generation, enabling seamless collaboration between designers and developers through Figma plugins, cross-platform SDKs, and real-time agent communication.

## 🏗️ Architecture Overview

COGO consists of multiple interconnected components working together to provide a complete design-to-code pipeline:

- **AI Agent Services**: Handle complex logic, LLM interactions, and orchestration
- **Edge Functions**: Provide lightweight API endpoints for real-time operations
- **Figma Plugins**: Enable direct integration with design tools
- **Cross-Platform SDKs**: Support Flutter and TypeScript/JavaScript environments
- **CLI Tools**: Provide command-line interfaces for automation and development workflows

## 📦 Package Structure

### 🤖 Agent & SDK Packages

#### **packages/cogo-chat-sdk-flutter** - Flutter Chat SDK
Complete Flutter SDK for integrating COGO agent communication into mobile applications.

**Key Features:**
- Full chat protocol implementation with COGO agents
- Real-time SSE (Server-Sent Events) streaming
- Comprehensive endpoint coverage:
  - `actionflow.dart` - ActionFlow execution
  - `attachments.dart` - File attachment handling
  - `bdd.dart` - BDD (Behavior-Driven Development) scenario management
  - `capabilities.dart` - Agent capability discovery
  - `design_generate.dart` - AI-powered design generation
  - `figma_context.dart` - Figma integration
  - `intent.dart` - Intent processing and routing
  - `trace_status.dart` - Request tracing and debugging
- Advanced data models for artifacts, editor context, and IDE hints
- Comprehensive testing suite with 20+ test cases

**Core Components:**
- `lib/cogo_chat_client.dart` - Main client interface
- `lib/models/` - Data models and type definitions
- `lib/utils/` - HTTP, SSE, Supabase integration utilities
- `test/` - Extensive test coverage

#### **packages/cogo-chat-sdk-ts** - TypeScript Chat SDK
Full-featured TypeScript/JavaScript SDK for web applications and Node.js environments.

**Key Features:**
- TypeScript-first design with comprehensive type safety
- Real-time communication via SSE and WebSocket
- Supabase integration for authentication and data persistence
- Advanced error handling and retry mechanisms
- Idempotency support for reliable API calls
- Comprehensive endpoint implementations

**Architecture:**
- `src/client.ts` - Main client with full API coverage
- `src/endpoints.ts` - All COGO API endpoint implementations
- `src/realtime.ts` - Real-time communication handling
- `src/artifacts.ts` - Artifact management and storage
- `src/types.ts` - Complete TypeScript definitions
- `tests/` - 10+ comprehensive test suites

#### **packages/cogo-cli-flutter** - Flutter CLI Tool
Command-line interface for Flutter development workflows with COGO integration.

**Features:**
- JSON manipulation and processing utilities
- HTTP client for COGO API interactions
- Sample data handling and testing
- Command-line automation for development tasks

**Structure:**
- `bin/cogo_cli_flutter.dart` - Main CLI entry point
- `lib/http_client.dart` - HTTP communication layer
- `lib/json_ops.dart` - JSON processing utilities

### 🎨 Figma Integration Packages

#### **packages/figma-plugin** - Main Figma Plugin
Primary Figma plugin for UUI/COGO conversion and real-time collaboration.

**Capabilities:**
- UUI & COGO conversion with advanced error handling
- SSE streaming for real-time communication
- Presence API integration for session management
- Multi-language support and localized UI
- Automatic backup system with timestamped folders
- Context scanning and application features

**Build System:**
- esbuild for fast compilation and bundling
- npm workspaces integration
- TypeScript support with comprehensive type checking

#### **packages/cogo-figma-plugin** - Enhanced Figma Plugin
Alternative Figma plugin implementation with additional features.

**Structure:**
- `cogo-plugin/manifest.json` - Plugin manifest
- `cogo-plugin/src/` - TypeScript source files
- Build artifacts and configuration files

### 📚 Documentation Structure

#### **docs/** - Comprehensive Documentation Suite

**🤖 Agent & API Documentation:**
- `COGO_AGENT_CHAT_MESSAGE_SPEC.md` - Complete chat message protocol specification
- `AGENTS_API_INDEX.md` - Agent API reference index
- `COGO_AGENT_OVERVIEW.md` - Agent system architecture overview
- `docs/api/EDGE_FIGMA_PLUGIN_PROTOCOL.md` - Edge-Figma plugin communication protocol
- `docs/api/EDGE_FUNCTIONS_OVERVIEW.md` - Edge functions architecture overview
- `docs/api/EDGE_TEST_GUIDE.md` - Edge functions testing guide

**📖 User Guides & Manuals:**
- `docs/manuals/COGO_User_Manual.md` - Complete user manual
- `docs/manuals/Developer_Manual.md` - Developer guide and API references
- `docs/manuals/Designer_Chatting_Guide.md` - Designer collaboration guide
- `docs/manuals/COGO_User_Scenarios.md` - User scenario documentation

**🔧 Integration & Development:**
- `docs/SDK_TS.md` - TypeScript SDK usage guide
- `docs/SDK_FLUTTER.md` - Flutter SDK usage guide
- `docs/CLI_COGO_FLUTTER.md` - Flutter CLI tool guide
- `docs/integration/FIGMA_PLUGIN_USER_GUIDE.md` - Figma plugin integration guide
- `docs/examples/FIGMA_PLUGIN_EXAMPLES.md` - Figma plugin usage examples

**🧪 Testing & Scenarios:**
- `docs/QUICKSTART_TESTING.md` - Quick start testing guide
- `docs/BDD_TO_ACTIONFLOW.md` - BDD to ActionFlow conversion guide
- `docs/scenarios/` - Comprehensive scenario documentation:
  - `figma/` - Figma integration scenarios (user intent, symbols, BDD, ActionFlow)
  - `login/` - Login flow scenarios with technical documentation
  - `chat/` - Chat interaction scenarios

**🏭 Operations & Management:**
- `docs/observability/INTENT_RESOLVE_METRICS.md` - Intent resolution metrics
- `docs/security/SECURITY_HARDENING.md` - Security hardening guide
- `docs/management/ARTIFACTS_RETENTION.md` - Artifacts retention policy
- `docs/runbook/NIGHTLY_FLOW.md` - Nightly operations runbook
- `docs/runbook/SECURITY_METRICS.md` - Security metrics monitoring

**📋 Planning & Design:**
- `docs/plans/COGO_CLI_DESIGN.md` - CLI tool design and architecture plan
- `docs/plans/INTENT_KEYWORD_REGISTRY.md` - Intent keyword registry plan

**🛠️ Development Resources:**
- `docs/postman/COGO.postman_collection.json` - Complete API testing collection
- All documentation maintained in English with consistent structure

## 🚀 Getting Started

### 🎨 Figma Plugin Quick Start

#### 1. Development Environment Setup
```bash
# Clone the repository
git clone https://github.com/cogo-xyz/cogo-community.git
cd cogo-community

# Install dependencies for all packages
npm ci

# Build all packages
npm run build
```

#### 2. Figma Plugin Installation
1. Open Figma Desktop Application
2. Navigate to: **Plugins → Development → Import plugin from manifest**
3. Select one of the following manifest files:
   - Primary Plugin: `packages/figma-plugin/manifest.json`
   - Alternative Plugin: `packages/cogo-figma-plugin/cogo-plugin/manifest.json`

#### 3. Plugin Configuration
Launch the plugin and configure the following settings:
- **Edge URL**: Supabase Functions base URL (e.g., `https://<ref>.functions.supabase.co`)
- **Anon Key**: Supabase anonymous key (development environment)
- **Agent ID** (optional): Multi-instance header (e.g., `cogo0`)
- **Project ID**: Target project UUID for operations

#### 4. Feature Testing
Test the following capabilities:
- **Convert Selection** → UUI & COGO conversion with error handling
- **Generate / Generate via LLM** → AI-powered generation with RAG
- **Upload & Ingest** → Large JSON processing with artifact storage
- **Chat SSE, Figma Context SSE** → Real-time streaming with Presence API
- **Presence Register/Unregister** → Session management and user tracking
- **Context Start/Apply** → Figma page scanning and result application
- **Multi-language Support** → Localized UI messages and error handling

### 📱 Flutter SDK Quick Start

#### Installation
```bash
# Add dependency to pubspec.yaml
dependencies:
  cogo_chat_sdk:
    path: packages/cogo-chat-sdk-flutter

# Install dependencies
flutter pub get
```

#### Basic Usage
```dart
import 'package:cogo_chat_sdk/cogo_chat_client.dart';

final client = CogoChatClient(
  edgeUrl: 'https://your-project.functions.supabase.co',
  anonKey: 'your-anon-key',
  projectId: 'your-project-uuid',
);

// Send a message
final response = await client.sendMessage(
  text: 'Generate a login screen design',
  sessionId: 'session-123',
);

// Listen to SSE events
client.sseStream.listen((event) {
  print('Received: ${event.type} - ${event.data}');
});
```

### 🌐 TypeScript SDK Quick Start

#### Installation
```bash
npm install packages/cogo-chat-sdk-ts
# or
yarn add packages/cogo-chat-sdk-ts
```

#### Basic Usage
```typescript
import { CogoClient } from 'cogo-chat-sdk-ts';

const client = new CogoClient({
  edgeUrl: 'https://your-project.functions.supabase.co',
  anonKey: 'your-anon-key',
  projectId: 'your-project-uuid',
});

// Send a message
const response = await client.sendMessage({
  text: 'Create a user registration form',
  sessionId: 'session-456',
});

// Handle real-time events
client.on('sse', (event) => {
  console.log('SSE Event:', event.type, event.data);
});
```

### 🖥️ CLI Tool Quick Start

#### Installation
```bash
# Navigate to CLI package
cd packages/cogo-cli-flutter

# Get dependencies
flutter pub get

# Run the CLI
dart run bin/cogo_cli_flutter.dart --help
```

#### Basic Usage
```bash
# Process JSON data
dart run bin/cogo_cli_flutter.dart process-json --input sample.json

# Test API endpoints
dart run bin/cogo_cli_flutter.dart test-api --endpoint /design-generate
```

## ⚙️ Development & Configuration

### Environment Setup
```bash
# For all packages
npm ci
npm run build

# For Flutter packages
cd packages/cogo-chat-sdk-flutter && flutter pub get
cd packages/cogo-cli-flutter && flutter pub get

# For TypeScript packages
cd packages/cogo-chat-sdk-ts && npm install
```

### Configuration
**Environment Variables:**
```bash
# Required for all COGO operations
COGO_EDGE_URL=https://your-project.functions.supabase.co
COGO_ANON_KEY=your-supabase-anon-key
COGO_PROJECT_ID=your-project-uuid

# Optional for multi-instance deployments
COGO_AGENT_ID=cogo0
```

## 🧪 Testing & Quality Assurance

### Test Suites
- **Flutter SDK**: `packages/cogo-chat-sdk-flutter/test/` - 20+ integration tests
- **TypeScript SDK**: `packages/cogo-chat-sdk-ts/tests/` - 10+ comprehensive test suites
- **E2E Scenarios**: `docs/scenarios/` - Complete workflow testing

### Quick Testing
```bash
# Run all tests
npm test

# Test specific scenarios
npm run test:e2e

# Validate API endpoints
npm run test:api
```

## 🔐 Security & Compliance

### Authentication
- **Development**: Direct key authentication for rapid development
- **Production**: JWT/HMAC tokens with short expiration
- **Multi-tenant**: Agent-specific authentication headers

### Data Handling
- **Artifacts**: Secure storage with signed URLs
- **Audit Logs**: Comprehensive event logging to `cogo` domain
- **Encryption**: End-to-end encryption for sensitive operations

## 🤝 Contributing Guidelines

### Development Workflow
1. **Fork & Clone**: Create your feature branch from `main`
2. **Development**: Follow coding conventions and add tests
3. **Documentation**: Update relevant docs for any API changes
4. **Testing**: Ensure all tests pass locally
5. **Pull Request**: Create PR with detailed description

### Coding Standards
- **TypeScript/JavaScript**: ESLint + Prettier configuration
- **Flutter/Dart**: Standard Dart formatting
- **Documentation**: English-only, comprehensive coverage
- **Commit Messages**: [Conventional Commits](https://conventionalcommits.org/) format

### Branch Naming
- `feature/*` - New features and enhancements
- `fix/*` - Bug fixes and patches
- `docs/*` - Documentation improvements
- `refactor/*` - Code refactoring and cleanup

## 📄 License & Legal

This project is distributed under the license specified in the [LICENSE](LICENSE) file.

## 📞 Support & Community

### 📚 Documentation
- **Complete Documentation**: See detailed docs above
- **Quick Start Guide**: `docs/QUICKSTART_TESTING.md`
- **API Reference**: `docs/postman/COGO.postman_collection.json`

### 🐛 Issue Reporting
- **Bug Reports**: [GitHub Issues](https://github.com/cogo-xyz/cogo-community/issues)
- **Feature Requests**: Use issue templates with detailed descriptions
- **Security Issues**: [GitHub Security](https://github.com/cogo-xyz/cogo-community/security)

### 💬 Community
- **Discussions**: [GitHub Discussions](https://github.com/cogo-xyz/cogo-community/discussions)
- **Contributing**: See contribution guidelines above

---

<div align="center">

# 🎉 **Welcome to COGO Community!**

*Transforming design-to-code workflows through AI-powered collaboration*

**Ready to build the future of design systems?** 🚀

</div>

---

## 📋 Additional Notes

### API Response Format
- **Ingest Results**: Returns `{ bucket, key, signedUrl }`
- **Key Usage**: `key` is bucket-relative path
- **Download Method**: Prefer `signedUrl` for secure file access

### Build System
- **Primary**: npm workspaces with esbuild
- **Flutter**: Standard pub/dart toolchain
- **Backup**: Automatic timestamped backups for safety

### Supported Platforms
- **Web**: TypeScript SDK for modern web applications
- **Mobile**: Flutter SDK for iOS/Android development
- **Desktop**: CLI tools for automation and development
- **Design**: Figma plugins for direct design integration
