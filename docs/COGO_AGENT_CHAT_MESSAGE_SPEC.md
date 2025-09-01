# COGO Agent Chat Message Specification

This document defines the standardized response format for COGO Agent chat interactions. It provides a clear contract for IDEs and applications to safely implement COGO platform features.

## Overview

The COGO Agent provides a unified chat interface for various AI-powered operations including UI generation, Figma integration, and workflow automation. This specification ensures consistent interaction patterns across different client implementations.

### Key Features
- **Standardized Response Format**: Consistent JSON structure across all operations
- **Real-time Progress**: SSE (Server-Sent Events) for live progress updates
- **Artifact Management**: Large outputs handled via secure links
- **Idempotency Support**: Safe retry mechanisms for all operations
- **Multi-language Support**: Localized responses and hints

## Message Flow

```
User Request → Intent Analysis → Progress Streaming → Final Response
     ↓              ↓              ↓              ↓
  Natural        Keywords       SSE Events     JSON + Artifacts
  Language       Extraction     (Optional)     (Required)
```

### Basic Flow
1. **User Input**: Natural language request
2. **Intent Processing**: Extract keywords and context
3. **Progress Updates**: Optional real-time progress via SSE
4. **Final Response**: Structured JSON with results and artifacts

## Response Schema

### Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `task_type` | string | Operation type | `"design_generate"` |
| `title` | string | Human-readable title | `"Login Page Design"` |
| `response` | string | Main result text | `"UI generated successfully"` |
| `trace_id` | string | Unique operation ID | `"uuid-string"` |
| `intent` | object | User intent structure | See below |

### Intent Structure
```json
{
  "intent": {
    "text": "Create a login page",
    "language": "en",
    "keywords": ["ui.generate"],
    "confidence": 0.85,
    "target": {
      "project_uuid": "project-123"
    }
  }
}
```

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `artifacts` | object | Generated files and data |
| `cli_actions` | array | IDE automation commands |
| `ide_hints` | object | UI guidance and suggestions |
| `execution` | object | Processing mode and policies |
| `meta` | object | Additional metadata |

## Task Types

### UI Generation
- **`design_generate`**: Create UI components from natural language
- **`variables_derive`**: Generate data bindings and state management
- **`symbols_identify`**: Identify dynamic elements in UI

### Figma Integration
- **`figma_context_scan`**: Analyze Figma designs
- **`figma_apply`**: Apply Figma designs to projects

### Workflow Automation
- **`bdd_generate`**: Generate behavior specifications
- **`bdd_refine`**: Enhance BDD scenarios
- **`actionflow_generate`**: Create workflow definitions
- **`actionflow_refine`**: Optimize action flows
- **`data_action_generate`**: Define API integrations

## Real-time Progress (SSE)

For long-running operations, the agent provides real-time progress updates via Server-Sent Events.

### Event Types
- `ready`: Operation initialized
- `progress`: Status updates with percentage
- `queued`: Operation queued for processing
- `handoff`: Moved to background processing
- `done`: Operation completed
- `error`: Error occurred

### Example SSE Stream
```
event: ready
data: {"trace_id":"abc-123"}

event: progress
data: {"stage":"Analyzing requirements","progress_pct":25}

event: progress
data: {"stage":"Generating UI","progress_pct":75}

event: done
data: {"task_type":"design_generate","title":"Login Page","response":"Complete"}
```

## Artifact Management

Large outputs are handled via the artifacts system for security and performance.

### Artifact Types
```json
{
  "artifacts": {
    "ui_json": {
      "preview": "/* UI structure preview */",
      "download_url": "https://api.cogo.ai/artifacts/ui/login.json"
    },
    "variables": {
      "mapping": {"#username": "#appData.login.username"},
      "download_url": "https://api.cogo.ai/artifacts/variables.json"
    }
  }
}
```

## CLI Actions (IDE Automation)

Responses can include automated commands for IDE execution.

### Action Structure
```json
{
  "cli_actions": [
    {
      "id": "apply_variables",
      "tool": "cogo-cli",
      "command": "variables upsert",
      "args": ["--project", "project-123", "--from-stdin"],
      "input_artifact_ref": "artifacts.variables",
      "dry_run": true
    }
  ]
}
```

## IDE Hints

Provide contextual guidance for better user experience.

### Hint Types
```json
{
  "ide_hints": {
    "toast": "Variables applied successfully",
    "open_file": "src/pages/login.json",
    "highlight": {
      "path": "src/pages/login.json",
      "range": [10, 15]
    },
    "next_action": "preview_design"
  }
}
```

## Examples

### UI Generation
```json
{
  "task_type": "design_generate",
  "title": "Login Page Design",
  "response": "Created a modern login page with email/password fields and validation",
  "trace_id": "abc-123-def-456",
  "intent": {
    "text": "Create a login page with email and password",
    "keywords": ["ui.generate"],
    "language": "en",
    "confidence": 0.88
  },
  "artifacts": {
    "ui_preview": {
      "version": "1.0",
      "components": ["email_input", "password_input", "login_button"]
    }
  },
  "ide_hints": {
    "toast": "Login page design ready for review",
    "next_action": "add_variables"
  }
}
```

### Variables Derivation
```json
{
  "task_type": "variables_derive",
  "title": "Data Binding Setup",
  "response": "Generated data bindings for login form elements",
  "trace_id": "def-456-ghi-789",
  "artifacts": {
    "variables": {
      "mapping": {
        "#email": "#appData.login.email",
        "#password": "#appData.login.password",
        "#isLoading": "#uiState.login.loading"
      }
    }
  },
  "cli_actions": [
    {
      "id": "apply_variables",
      "tool": "cogo-cli",
      "command": "variables upsert",
      "args": ["--project", "project-123"],
      "dry_run": true
    }
  ]
}
```

### Figma Integration
```json
{
  "task_type": "figma_context_scan",
  "title": "Figma Design Analysis",
  "response": "Analyzed Figma design: 12 components, 5 screens identified",
  "trace_id": "ghi-789-jkl-012",
  "artifacts": {
    "figma_components": {
      "count": 12,
      "screens": ["login", "dashboard", "profile"],
      "download_url": "https://api.cogo.ai/artifacts/figma-analysis.json"
    }
  }
}
```

## Error Handling

Standardized error format for all operations:

```json
{
  "code": "VALIDATION_ERROR",
  "message": "Invalid project UUID provided",
  "retryable": false,
  "details": {
    "field": "project_uuid",
    "expected": "UUID format"
  },
  "trace_id": "error-trace-123"
}
```

## Integration Guide

### For IDE Developers

1. **Parse Responses**: Always validate required fields
2. **Handle SSE**: Implement progress UI for better UX
3. **Artifact Downloads**: Use provided URLs for large files
4. **CLI Actions**: Support dry-run mode with user confirmation
5. **Error Recovery**: Implement retry logic for retryable errors

### For CLI Tools

1. **Idempotency**: Use provided keys for safe retries
2. **Dry Run**: Always preview changes before applying
3. **Conflict Resolution**: Handle merge conflicts appropriately
4. **Progress Feedback**: Show progress for long operations

### Best Practices

- **Validate Inputs**: Check intent keywords against capabilities
- **Handle Large Responses**: Use artifact system for >1MB content
- **Implement Timeouts**: Set reasonable timeouts for operations
- **Support Localization**: Use language field for UI hints
- **Secure Downloads**: Validate artifact URLs and signatures

## Version Compatibility

- **Current Version**: v1
- **Breaking Changes**: Will be communicated via version field
- **Backward Compatibility**: Maintained for 2 major versions

## Support

For integration questions or issues:
- Visit the [GitHub Repository](https://github.com/cogo-xyz/cogo-community)

---

**Version**: 1.0
**Last Updated**: 2025-09-01
**Audience**: IDE Developers, Integration Partners
