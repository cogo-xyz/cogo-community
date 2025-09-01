# COGO Community

Public monorepo for COGO platform SDKs, CLI tools, plugins, and comprehensive documentation. COGO is an AI-powered platform that bridges design systems and code generation, enabling seamless collaboration between designers and developers.

## 🏗️ Architecture Overview

COGO consists of multiple interconnected components:

- **🤖 AI Agent Services**: Handle complex logic, LLM interactions, and orchestration
- **⚡ Edge Functions**: Provide lightweight API endpoints for real-time operations
- **🎨 Figma Plugins**: Enable direct integration with design tools
- **📱 Cross-Platform SDKs**: Support Flutter and TypeScript/JavaScript environments
- **🖥️ CLI Tools**: Provide command-line interfaces for automation and development workflows

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

## 🚀 Getting Started

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

### 🎨 Figma Plugin Quick Start

#### Installation
1. Open Figma Desktop Application
2. Navigate to: **Plugins → Development → Import plugin from manifest**
3. Select one of the following manifest files:
   - Primary Plugin: `packages/figma-plugin/manifest.json`
   - Alternative Plugin: `packages/cogo-figma-plugin/cogo-plugin/manifest.json`

#### Configuration
Launch the plugin and configure the following settings:
- **Edge URL**: Supabase Functions base URL (e.g., `https://<ref>.functions.supabase.co`)
- **Anon Key**: Supabase anonymous key (development environment)
- **Agent ID** (optional): Multi-instance header (e.g., `cogo0`)
- **Project ID**: Target project UUID for operations

## 📚 Documentation

### 🤖 Agent & API Documentation
- `docs/COGO_AGENT_CHAT_MESSAGE_SPEC.md` - Complete chat message protocol specification
- `docs/EDGE_FIGMA_PLUGIN_PROTOCOL.md` - Edge-Figma plugin communication protocol

### 📖 SDK & Integration Guides
- `docs/SDK_FLUTTER.md` - Flutter SDK usage guide
- `docs/SDK_TS.md` - TypeScript SDK usage guide
- `docs/CLI_COGO_FLUTTER.md` - Flutter CLI tool guide
- `docs/FIGMA_PLUGIN_USER_GUIDE.md` - Figma plugin integration guide
- `docs/FIGMA_PLUGIN_EXAMPLES.md` - Figma plugin usage examples

### 🛠️ Development Resources
- `docs/index.md` - Documentation index and overview
- `docs/README.md` - Comprehensive documentation guide

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
- **Quick Start Guide**: `docs/README.md`
- **API Reference**: `docs/COGO_AGENT_CHAT_MESSAGE_SPEC.md`

### 🐛 Issue Reporting
- **Bug Reports**: Create GitHub Issues with detailed descriptions
- **Feature Requests**: Use issue templates with detailed descriptions

### 💬 Community
- **Discussions**: GitHub Discussions for general topics
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

### Notes
- Core runtime (orchestrator/workers/edge) and secrets are not included here
- For development and gated deploys, use `cogo-agent-core`
