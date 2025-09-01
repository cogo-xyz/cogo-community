# COGO Community Documentation

Welcome to the COGO Community Documentation! This collection provides comprehensive guides and references for integrating with COGO platform packages and APIs.

## 📦 Available Packages

### SDKs
- **[SDK_FLUTTER.md](SDK_FLUTTER.md)** - Flutter SDK for COGO chat and agent interactions
- **[SDK_TS.md](SDK_TS.md)** - TypeScript SDK for COGO chat and agent interactions

### CLI Tools
- **[CLI_COGO_FLUTTER.md](CLI_COGO_FLUTTER.md)** - Flutter-based CLI for COGO platform operations

### Plugins
- **[FIGMA_PLUGIN_USER_GUIDE.md](FIGMA_PLUGIN_USER_GUIDE.md)** - Figma plugin user guide
- **[FIGMA_PLUGIN_EXAMPLES.md](FIGMA_PLUGIN_EXAMPLES.md)** - Figma plugin examples and use cases
- **[EDGE_FIGMA_PLUGIN_PROTOCOL.md](EDGE_FIGMA_PLUGIN_PROTOCOL.md)** - Figma plugin protocol specification

## 🚀 Quick Start

### For Flutter Developers
1. **[Install Flutter SDK](SDK_FLUTTER.md#getting-started)**
2. **[Set up authentication](SDK_FLUTTER.md#authentication)**
3. **[Make your first API call](SDK_FLUTTER.md#basic-usage)**

### For TypeScript Developers
1. **[Install TypeScript SDK](SDK_TS.md#installation)**
2. **[Configure your environment](SDK_TS.md#setup)**
3. **[Integrate with your application](SDK_TS.md#integration)**

### For Figma Plugin Users
1. **[Install the plugin](FIGMA_PLUGIN_USER_GUIDE.md#installation)**
2. **[Connect your account](FIGMA_PLUGIN_USER_GUIDE.md#setup)**
3. **[Start designing with COGO](FIGMA_PLUGIN_USER_GUIDE.md#getting-started)**

## 📋 API Reference

- **[COGO_AGENT_CHAT_MESSAGE_SPEC.md](COGO_AGENT_CHAT_MESSAGE_SPEC.md)** - Complete chat message protocol specification
  - Response schemas and formats
  - Real-time progress updates (SSE)
  - Artifact management
  - Error handling patterns

## 🛠️ Development Tools

### CLI Operations
- **Variables Management**: `cogo-cli variables upsert --project <id>`
- **Symbols Processing**: `cogo-cli symbols identify --ui-json <file>`
- **Action Flow Generation**: `cogo-cli actionflow generate --from-bdd <file>`
- **Figma Integration**: `cogo-cli figma scan --url <figma-url>`

### SDK Features
- **Real-time Communication**: SSE and Supabase Realtime integration
- **Artifact Handling**: Large file uploads and downloads
- **Idempotent Operations**: Safe retry mechanisms
- **Multi-language Support**: Localized responses and hints

## 📚 Documentation Structure

```
docs/community/
├── README.md                           # This overview (you are here)
├── index.md                           # Detailed documentation index
├── SDK_FLUTTER.md                     # Flutter SDK documentation
├── SDK_TS.md                         # TypeScript SDK documentation
├── CLI_COGO_FLUTTER.md               # Flutter CLI documentation
├── FIGMA_PLUGIN_USER_GUIDE.md        # Figma plugin user guide
├── FIGMA_PLUGIN_EXAMPLES.md          # Figma plugin examples
├── EDGE_FIGMA_PLUGIN_PROTOCOL.md     # Figma plugin protocol
└── COGO_AGENT_CHAT_MESSAGE_SPEC.md   # Chat message specification
```

## 🔗 Key Links

- **GitHub Repository**: [https://github.com/cogo-xyz/cogo-community](https://github.com/cogo-xyz/cogo-community)
- **Package Registry**: Available on pub.dev and npm
- **Support**: GitHub Issues and Discussions

## 📖 Integration Guides

### Basic Integration
1. **Choose your platform**: Flutter, TypeScript, or Figma
2. **Install the appropriate package**
3. **Configure authentication**
4. **Implement your use case**

### Advanced Features
- **Real-time Updates**: Use SSE for live progress tracking
- **File Management**: Handle large artifacts with signed URLs
- **Error Recovery**: Implement proper retry and fallback logic
- **Localization**: Support multiple languages in your UI

## 🆘 Troubleshooting

### Common Issues
- **Authentication Errors**: Verify your API keys and tokens
- **Connection Issues**: Check network connectivity and firewall settings
- **File Upload Problems**: Ensure proper MIME types and file size limits
- **Real-time Disconnects**: Implement reconnection logic for SSE streams

### Getting Help
1. Check the relevant documentation section
2. Search existing GitHub issues
3. Create a new issue with detailed information
4. Join community discussions

---

**Version**: 1.0
**Last Updated**: 2025-09-01
**Maintained by**: COGO Community Team