# COGO System MCP Server Integration Guide

## Overview

This document describes the integration of Model Context Protocol (MCP) servers with the COGO Agent Core system, enabling real-time communication and task execution through specialized MCP servers for Figma context retrieval and browser automation.

## Architecture

### System Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   COGO Agent    │    │  Figma Context  │    │  Browser-use    │
│     Core        │◄──►│   MCP Server    │    │   MCP Server    │
│   (Port 3000)   │    │   (Port 3002)   │    │   (Port 3003)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Supabase Real-time Queue                     │
│                    (Central Event Bus)                          │
│  • cogo-subtasks: MCP task requests                            │
│  • cogo-results: MCP task results                              │
│  • mcp-health: Health monitoring                               │
└─────────────────────────────────────────────────────────────────┘
```

### Communication Flow

1. **Task Request**: COGO Agent receives task via API
2. **Task Decomposition**: Task is broken down into MCP subtasks
3. **Real-time Broadcasting**: Subtasks are sent via Supabase Real-time
4. **MCP Processing**: Specialized MCP servers execute tasks
5. **Result Collection**: Results are returned via Real-time
6. **Response**: Final response is sent back to client

## MCP Servers

### 1. Figma Context MCP Server

**Purpose**: Retrieve and validate Figma design context

**Features**:
- Figma file validation
- Design context extraction
- Mock mode for development
- Redis caching for performance

**Endpoints**:
- `GET /health` - Health check
- `POST /figma/context` - Get Figma context
- `POST /figma/validate` - Validate Figma URL

**Configuration**:
```typescript
{
  port: 3002,
  figmaApiKey: process.env.FIGMA_API_KEY,
  redisUrl: process.env.REDIS_URL,
  mockMode: process.env.MOCK_MODE === 'true'
}
```

### 2. Browser-use MCP Server

**Purpose**: Browser automation and web interaction

**Features**:
- Playwright-based browser automation
- Screenshot capture
- DOM snapshot extraction
- Memory optimization
- Real browser execution

**Endpoints**:
- `GET /health` - Health check
- `GET /browser/info` - Browser information
- `POST /execute` - Execute browser actions
- `POST /screenshot` - Take screenshot
- `POST /dom-snapshot` - Get DOM snapshot

**Configuration**:
```typescript
{
  port: 3003,
  headless: process.env.HEADLESS === 'true',
  timeout: parseInt(process.env.TIMEOUT || '30000'),
  mockMode: process.env.MOCK_MODE === 'false'
}
```

## Real-time Integration

### Channels

#### `cogo-subtasks`
- **Purpose**: MCP task requests
- **Message Format**:
```typescript
{
  type: 'MCP_SUBTASK',
  payload: {
    subtask_id: string,
    task_id: string,
    type: 'EXECUTE_BROWSER_ACTION' | 'FETCH_FIGMA_CONTEXT' | 'TAKE_SCREENSHOT',
    params: object
  },
  source: string,
  target: 'cogo-subtasks'
}
```

#### `cogo-results`
- **Purpose**: MCP task results
- **Message Format**:
```typescript
{
  type: 'SUBTASK_RESULT',
  payload: {
    subtask_id: string,
    task_id: string,
    status: 'completed' | 'failed',
    output?: any,
    error?: string,
    execution_time: number,
    metadata: {
      source: string,
      timestamp: string
    }
  },
  source: string,
  target: 'cogo-results'
}
```

### MCP Client Integration

The `MCPClient` class provides HTTP-based communication with MCP servers:

```typescript
class MCPClient {
  private figmaClient: AxiosInstance;
  private browserClient: AxiosInstance;

  async getFigmaContext(request: FigmaContextRequest): Promise<FigmaContextResponse>
  async executeBrowserActions(request: BrowserActionRequest): Promise<BrowserActionResult>
  async takeScreenshot(request: ScreenshotRequest): Promise<ScreenshotResponse>
  async getDOMSnapshot(request: DOMSnapshotRequest): Promise<DOMSnapshotResponse>
  async checkHealth(): Promise<{ figma: boolean; browser: boolean; details: any }>
}
```

## Task Processing

### Task Manager Integration

The `cogo-executor-agent` handles MCP subtasks through real-time channels:

```typescript
private async handleMCPSubtask(message: any): Promise<void> {
  const subtask: MCPSubtask = message.payload;
  const result = await this.processMCPSubtask(subtask);
  
  await this.realtimeQueue.broadcastMessage({
    type: 'SUBTASK_RESULT',
    payload: result,
    source: this.getId(),
    target: 'cogo-results'
  });
}
```

### Supported MCP Subtask Types

1. **FETCH_FIGMA_CONTEXT**
   - Retrieves Figma file context
   - Parameters: `FigmaContextRequest`

2. **EXECUTE_BROWSER_ACTION**
   - Executes browser automation
   - Parameters: `BrowserActionRequest`

3. **TAKE_SCREENSHOT**
   - Captures browser screenshot
   - Parameters: `ScreenshotRequest`

4. **GET_DOM_SNAPSHOT**
   - Extracts DOM structure
   - Parameters: `DOMSnapshotRequest`

## API Usage Examples

### Browser Automation

```bash
# Execute browser action
curl -X POST -H "Content-Type: application/json" \
  -d '{
    "type": "MCP_SUBTASK",
    "payload": {
      "subtask_id": "browser-001",
      "task_id": "task-001",
      "type": "EXECUTE_BROWSER_ACTION",
      "params": {
        "url": "https://www.google.com",
        "actions": [{"type": "navigate", "url": "https://www.google.com"}]
      }
    }
  }' \
  http://localhost:3000/api/tasks
```

### Screenshot Capture

```bash
# Take screenshot
curl -X POST -H "Content-Type: application/json" \
  -d '{
    "type": "MCP_SUBTASK",
    "payload": {
      "subtask_id": "screenshot-001",
      "task_id": "task-002",
      "type": "TAKE_SCREENSHOT",
      "params": {
        "url": "https://www.google.com",
        "format": "png",
        "fullPage": false
      }
    }
  }' \
  http://localhost:3000/api/tasks
```

### Figma Context Retrieval

```bash
# Get Figma context
curl -X POST -H "Content-Type: application/json" \
  -d '{
    "type": "MCP_SUBTASK",
    "payload": {
      "subtask_id": "figma-001",
      "task_id": "task-003",
      "type": "FETCH_FIGMA_CONTEXT",
      "params": {
        "figmaUrl": "https://www.figma.com/file/example",
        "includeStyles": true,
        "includeComponents": true
      }
    }
  }' \
  http://localhost:3000/api/tasks
```

## Health Monitoring

### MCP Health Check

```bash
# Check MCP servers health
curl -s http://localhost:3000/api/mcp/health | jq .
```

**Response Format**:
```json
{
  "success": true,
  "data": {
    "figma": true,
    "browser": true,
    "details": {
      "figma": {
        "status": "healthy",
        "services": {
          "figma_api": {"status": "healthy"},
          "cache": {"status": "healthy"}
        }
      },
      "browser": {
        "status": "healthy",
        "services": {
          "browser": {"status": "healthy"},
          "memory": {"status": "healthy"}
        }
      }
    }
  }
}
```

## Development Setup

### Prerequisites

- Node.js 18+
- Redis server
- Playwright browsers
- Figma API key (optional for mock mode)

### Installation

1. **Install dependencies**:
```bash
# COGO Agent Core
npm install

# Figma MCP Server
cd mcp-servers/figma-context
npm install

# Browser MCP Server
cd ../browser-use
npm install
```

2. **Environment Configuration**:
```bash
# Figma MCP Server
cp mcp-servers/figma-context/env.development mcp-servers/figma-context/.env

# Browser MCP Server
cp mcp-servers/browser-use/env.development mcp-servers/browser-use/.env
```

3. **Start servers**:
```bash
# Start all servers
./start-all-servers.sh

# Or start individually
./start-agent-core.sh
./start-figma-mcp.sh
./start-browser-mcp.sh
```

### Development Scripts

- `start-agent-core.sh` - Start COGO Agent Core
- `start-figma-mcp.sh` - Start Figma Context MCP
- `start-browser-mcp.sh` - Start Browser-use MCP
- `start-all-servers.sh` - Start all servers
- `stop-all-servers.sh` - Stop all servers

## Performance Optimization

### Memory Management

Browser MCP server includes memory optimization features:

- Memory usage monitoring
- Configurable memory thresholds (98% default)
- Browser launch arguments for memory efficiency
- Automatic browser cleanup

### Caching

Figma MCP server implements Redis caching:

- Figma API response caching
- URL validation caching
- Configurable cache TTL
- Cache health monitoring

## Error Handling

### MCP Client Error Handling

```typescript
try {
  const result = await this.mcpClient.executeBrowserActions(request);
  return result;
} catch (error) {
  console.error('[MCPClient] Browser action failed:', error);
  throw new Error(`MCP execution failed: ${error.message}`);
}
```

### Real-time Error Handling

```typescript
private async handleMCPSubtask(message: any): Promise<void> {
  try {
    const result = await this.processMCPSubtask(message.payload);
    // Broadcast success
  } catch (error) {
    // Broadcast error result
    const errorResult: MCPSubtaskResult = {
      status: 'failed',
      error: error.message,
      // ... other fields
    };
  }
}
```

## Security Considerations

### Network Security

- Internal communication only (localhost)
- No external MCP server connections
- Environment-based configuration

### Data Security

- No sensitive data in logs
- Mock mode for development
- Configurable API keys

## Monitoring and Logging

### Health Monitoring

- Real-time health checks
- Service status monitoring
- Memory usage tracking
- Response time monitoring

### Logging

- Structured logging with timestamps
- Request/response logging
- Error logging with stack traces
- Performance metrics logging

## Future Enhancements

### Planned Features

1. **Additional MCP Servers**:
   - Database MCP for data operations
   - File System MCP for file operations
   - API MCP for external API integration

2. **Enhanced Real-time Features**:
   - WebSocket support for real-time updates
   - Event streaming for large datasets
   - Real-time collaboration features

3. **Advanced Task Management**:
   - Task prioritization
   - Resource allocation
   - Load balancing across MCP servers

### Scalability Considerations

- Horizontal scaling of MCP servers
- Load balancing for high-traffic scenarios
- Database optimization for real-time operations
- Caching strategies for improved performance

## Troubleshooting

### Common Issues

1. **Port Conflicts**:
   - Ensure ports 3000, 3002, 3003 are available
   - Use `lsof -i :PORT` to check port usage

2. **Browser Launch Issues**:
   - Install Playwright browsers: `npx playwright install`
   - Check GPU compatibility for headless mode
   - Verify system dependencies

3. **Redis Connection Issues**:
   - Ensure Redis server is running
   - Check Redis connection configuration
   - Verify network connectivity

4. **Memory Issues**:
   - Monitor memory usage with health checks
   - Adjust memory thresholds if needed
   - Restart servers if memory usage is high

### Debug Mode

Enable debug logging by setting environment variables:

```bash
DEBUG=true
LOG_LEVEL=debug
```

## Conclusion

The MCP server integration provides a robust foundation for extending COGO Agent capabilities through specialized external services. The real-time communication architecture ensures efficient task processing and result delivery, while the modular design allows for easy extension with additional MCP servers.

The system successfully demonstrates:
- Real-time task processing
- Reliable error handling
- Comprehensive health monitoring
- Scalable architecture design
- Developer-friendly setup and configuration

This integration serves as a template for future MCP server implementations and provides a solid foundation for building more complex multi-agent systems. 