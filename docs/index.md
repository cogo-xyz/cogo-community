# COGO Community Documentation Index

This index provides comprehensive access to all COGO community documentation, focusing on SDKs, CLI tools, and plugins for seamless integration.

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [SDK Documentation](#-sdk-documentation)
- [CLI Tools](#-cli-tools)
- [Plugins](#-plugins)
- [API Reference](#-api-reference)
- [Integration Examples](#-integration-examples)
- [Troubleshooting](#-troubleshooting)

---

## 🚀 Quick Start

### By Platform

| Platform | Primary Guide | Quick Setup |
|----------|---------------|-------------|
| **Flutter** | [SDK_FLUTTER.md](SDK_FLUTTER.md) | Install → Auth → First Call |
| **TypeScript** | [SDK_TS.md](SDK_TS.md) | Install → Setup → Integrate |
| **Figma** | [FIGMA_PLUGIN_USER_GUIDE.md](FIGMA_PLUGIN_USER_GUIDE.md) | Install → Connect → Design |
| **CLI** | [CLI_COGO_FLUTTER.md](CLI_COGO_FLUTTER.md) | Install → Auth → Commands |

### Essential First Steps
1. **Choose your platform** from the table above
2. **Install the appropriate package/CLI**
3. **Set up authentication** (API keys, tokens)
4. **Make your first API call** or command execution
5. **Explore examples** for your use case

---

## 📱 SDK Documentation

### Flutter SDK
| Document | Description | Key Features |
|----------|-------------|--------------|
| [SDK_FLUTTER.md](SDK_FLUTTER.md) | Complete Flutter SDK guide | Real-time chat, artifact handling, error recovery |

**Highlights:**
- Real-time communication via SSE and Supabase Realtime
- Large file uploads/downloads with signed URLs
- Idempotent operations for safe retries
- Multi-language support and localization

### TypeScript SDK
| Document | Description | Key Features |
|----------|-------------|--------------|
| [SDK_TS.md](SDK_TS.md) | Complete TypeScript SDK guide | Same features as Flutter SDK |

**Highlights:**
- Consistent API with Flutter SDK
- Full TypeScript type definitions
- Node.js and browser compatibility
- Comprehensive error handling

---

## 🛠️ CLI Tools

### Flutter CLI
| Document | Description | Main Commands |
|----------|-------------|---------------|
| [CLI_COGO_FLUTTER.md](CLI_COGO_FLUTTER.md) | Flutter-based CLI tool | variables, symbols, actionflow, figma |

**Available Operations:**
- `variables upsert` - Manage app data and UI state variables
- `symbols identify` - Extract dynamic elements from UI JSON
- `actionflow generate` - Create workflows from BDD specifications
- `figma scan` - Analyze Figma designs for integration

---

## 🔌 Plugins

### Figma Plugin
| Document | Description | Use Cases |
|----------|-------------|-----------|
| [FIGMA_PLUGIN_USER_GUIDE.md](FIGMA_PLUGIN_USER_GUIDE.md) | User guide for Figma plugin | Design → Code conversion |
| [FIGMA_PLUGIN_EXAMPLES.md](FIGMA_PLUGIN_EXAMPLES.md) | Examples and use cases | Real-world scenarios |
| [EDGE_FIGMA_PLUGIN_PROTOCOL.md](EDGE_FIGMA_PLUGIN_PROTOCOL.md) | Technical protocol specification | API integration details |

**Plugin Features:**
- Convert Figma designs to COGO UI JSON
- Real-time collaboration with team members
- Component library synchronization
- Design system consistency checks

---

## 📋 API Reference

### Chat Message Protocol
| Document | Description | Coverage |
|----------|-------------|----------|
| [COGO_AGENT_CHAT_MESSAGE_SPEC.md](COGO_AGENT_CHAT_MESSAGE_SPEC.md) | Complete protocol specification | Request/response schemas, SSE, artifacts, errors |

**Protocol Components:**
- **Request Schema**: Text input, intent keywords, editor context
- **Response Schema**: Task types, progress tracking, artifacts
- **Real-time Updates**: SSE events for live progress
- **Error Handling**: Standardized error formats and recovery
- **Artifact Management**: Large file handling with signed URLs

### Task Types Supported
- `design_generate` - UI component generation
- `variables_derive` - Data binding setup
- `symbols_identify` - Dynamic element extraction
- `figma_context_scan` - Figma design analysis
- `bdd_generate` - Behavior specification creation
- `actionflow_generate` - Workflow creation
- `data_action_generate` - API integration setup

---

## 💡 Integration Examples

### Basic Integration Patterns

#### Flutter App Integration
```dart
import 'package:cogo_chat_sdk_flutter/cogo_chat_client.dart';

final client = CogoChatClient(
  supabaseUrl: 'your-supabase-url',
  supabaseKey: 'your-anon-key',
);

final response = await client.sendMessage(
  text: 'Create a login form',
  intent: Intent(keywords: ['ui.generate']),
);
```

#### TypeScript Integration
```typescript
import { CogoChatClient } from '@cogo/chat-sdk';

const client = new CogoChatClient({
  supabaseUrl: 'your-supabase-url',
  supabaseKey: 'your-anon-key',
});

const response = await client.sendMessage({
  text: 'Create a login form',
  intent: { keywords: ['ui.generate'] },
});
```

#### CLI Usage Examples
```bash
# Variables management
cogo-cli variables upsert --project demo --from-stdin < variables.json

# Symbols identification
cogo-cli symbols identify --ui-json loginPage.json

# Action flow generation
cogo-cli actionflow generate --from-bdd login.bdd

# Figma integration
cogo-cli figma scan --url https://www.figma.com/design/abc123/MyDesign
```

---

## 🆘 Troubleshooting

### Common Issues & Solutions

#### Authentication Problems
**Issue**: API key or token validation errors
**Solution**:
- Verify API keys are correctly set
- Check token expiration
- Ensure proper permissions are granted
- Test with different authentication methods

#### Connection Issues
**Issue**: Network connectivity or firewall problems
**Solution**:
- Check internet connection
- Verify firewall settings allow API calls
- Test with different network environments
- Use proxy settings if required

#### Real-time Connection Drops
**Issue**: SSE or Realtime connections disconnecting
**Solution**:
- Implement automatic reconnection logic
- Handle network interruptions gracefully
- Use exponential backoff for retries
- Monitor connection health

#### File Upload Problems
**Issue**: Large file uploads failing
**Solution**:
- Check file size limits (typically 10MB)
- Verify proper MIME types
- Ensure signed URLs are used for large files
- Implement chunked uploads for very large files

#### CLI Command Failures
**Issue**: CLI commands returning errors
**Solution**:
- Verify CLI installation and version
- Check command syntax and parameters
- Ensure proper authentication
- Review error messages for specific guidance

### Getting Help

1. **Check Documentation**: Review relevant guides first
2. **Search Issues**: Look for existing GitHub issues
3. **Create Issue**: Submit detailed bug reports or feature requests
4. **Community Support**: Join discussions and ask questions

---

## 📚 Documentation Structure

```
docs/community/
├── README.md                           # Main overview and quick start
├── index.md                           # This detailed index
├── SDK_FLUTTER.md                     # Flutter SDK documentation
├── SDK_TS.md                         # TypeScript SDK documentation
├── CLI_COGO_FLUTTER.md               # Flutter CLI documentation
├── FIGMA_PLUGIN_USER_GUIDE.md        # Figma plugin user guide
├── FIGMA_PLUGIN_EXAMPLES.md          # Figma plugin examples
├── EDGE_FIGMA_PLUGIN_PROTOCOL.md     # Figma plugin protocol
└── COGO_AGENT_CHAT_MESSAGE_SPEC.md   # Chat message specification
```

## 🔗 Important Links

- **GitHub Repository**: [https://github.com/cogo-xyz/cogo-community](https://github.com/cogo-xyz/cogo-community)
- **Package Registry**: Available on pub.dev and npm
- **Issue Tracker**: GitHub Issues for bug reports and feature requests
- **Community Discussions**: GitHub Discussions for questions and support

---

## 📋 Document Status

- ✅ **Current** - Actively maintained and accurate
- 🔄 **In Progress** - Currently being updated
- 📅 **Review Needed** - May need updates based on latest changes

---

*Last updated: 2025-09-01*
*Maintained by: COGO Community Team*
