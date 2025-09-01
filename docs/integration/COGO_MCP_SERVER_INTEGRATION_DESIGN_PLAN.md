# COGO MCP Server Integration Design & Development Plan v1.0

## Executive Summary

This document outlines the comprehensive design and development plan for integrating Figma Context MCP Server and Browser-use MCP Server into the COGO Agent Core system. The integration will enable the `cogo-orchestrator-agent` (CIO) to understand and control visual design contexts from Figma and web browser environments, facilitating more sophisticated and autonomous development workflows.

## 1. Architecture Overview

### 1.1 Integration Goals
- **Visual Context Understanding**: Enable AI agents to analyze and understand Figma design contexts
- **Browser Automation**: Provide web browser control capabilities for E2E testing and web scraping
- **Seamless Workflow Integration**: Maintain existing event-driven architecture using Supabase Real-time
- **Scalable Service Architecture**: Implement MCP servers as specialized workers in the execution layer

### 1.2 System Architecture Position
```
┌─────────────────────────────────────────────────────────────┐
│                    Intelligence Layer                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              cogo-orchestrator-agent (CIO)              │ │
│  │              - Strategic Planning                        │ │
│  │              - Workflow Orchestration                    │ │
│  │              - Context Analysis                          │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                    Execution Layer                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐ │
│  │cogo-executor│ │cogo-codegen │ │cogo-sandbox │ │Figma MCP│ │
│  │   -agent    │ │ -service    │ │ -worker     │ │ Server  │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘ │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐ │
│  │Browser MCP  │ │Data Action  │ │Knowledge    │ │Other    │ │
│  │ Server      │ │Executor     │ │Graph        │ │Workers  │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐ │
│  │  Supabase   │ │   Docker    │ │ Kubernetes  │ │External │ │
│  │ Real-time   │ │ Containers  │ │  Cluster    │ │ APIs    │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 2. Development Implementation Plan

### 2.1 Phase 1: Infrastructure Setup (Week 1-2)

#### 2.1.1 Docker Container Architecture
```yaml
# docker-compose.mcp.yml
version: '3.8'
services:
  cogo-figma-mcp:
    build: ./mcp-servers/figma-context
    container_name: cogo-figma-mcp
    ports:
      - "3002:3000"
    environment:
      - FIGMA_API_KEY=${FIGMA_API_KEY}
      - RATE_LIMIT=100
      - CACHE_TTL=3600
    networks:
      - cogo-internal
    restart: unless-stopped

  cogo-browser-mcp:
    build: ./mcp-servers/browser-use
    container_name: cogo-browser-mcp
    ports:
      - "3003:3000"
    environment:
      - HEADLESS=true
      - TIMEOUT=30000
      - VIEWPORT_WIDTH=1920
      - VIEWPORT_HEIGHT=1080
    networks:
      - cogo-internal
    restart: unless-stopped
    volumes:
      - /tmp/screenshots:/app/screenshots

networks:
  cogo-internal:
    driver: bridge
```

### 2.2 Phase 2: MCP Server Development (Week 3-4)

#### 2.2.1 Figma Context MCP Server Implementation
```typescript
// mcp-servers/figma-context/src/server.ts
import express from 'express';
import { FigmaAPI } from './services/figma-api';
import { ContextAnalyzer } from './services/context-analyzer';
import { CacheManager } from './services/cache-manager';

class FigmaContextMCPServer {
  private app: express.Application;
  private figmaAPI: FigmaAPI;
  private contextAnalyzer: ContextAnalyzer;
  private cacheManager: CacheManager;

  constructor() {
    this.app = express();
    this.figmaAPI = new FigmaAPI(process.env.FIGMA_API_KEY);
    this.contextAnalyzer = new ContextAnalyzer();
    this.cacheManager = new CacheManager();
    
    this.setupRoutes();
    this.setupMiddleware();
  }

  private setupRoutes(): void {
    this.app.post('/getContext', this.handleGetContext.bind(this));
    this.app.get('/health', this.handleHealthCheck.bind(this));
    this.app.get('/cache/clear', this.handleClearCache.bind(this));
  }

  private async handleGetContext(req: express.Request, res: express.Response): Promise<void> {
    try {
      const { figma_url, target_nodes, context_type, include_assets } = req.body;
      
      // Check cache first
      const cacheKey = this.generateCacheKey(figma_url, context_type);
      const cachedResult = await this.cacheManager.get(cacheKey);
      if (cachedResult) {
        res.json(cachedResult);
        return;
      }

      // Extract file ID from Figma URL
      const fileId = this.extractFileId(figma_url);
      
      // Fetch design data from Figma API
      const designData = await this.figmaAPI.getFile(fileId);
      
      // Analyze context based on requirements
      const context = await this.contextAnalyzer.analyze(designData, {
        targetNodes: target_nodes,
        contextType: context_type,
        includeAssets: include_assets
      });

      // Cache the result
      await this.cacheManager.set(cacheKey, context);

      res.json(context);
    } catch (error) {
      res.status(500).json({
        error: 'Failed to extract Figma context',
        details: error.message
      });
    }
  }

  public start(port: number = 3000): void {
    this.app.listen(port, () => {
      console.log(`Figma Context MCP Server running on port ${port}`);
    });
  }
}
```

#### 2.2.2 Browser-use MCP Server Implementation
```typescript
// mcp-servers/browser-use/src/server.ts
import express from 'express';
import puppeteer from 'puppeteer';
import { BrowserController } from './services/browser-controller';
import { ActionExecutor } from './services/action-executor';

class BrowserUseMCPServer {
  private app: express.Application;
  private browserController: BrowserController;
  private actionExecutor: ActionExecutor;

  constructor() {
    this.app = express();
    this.browserController = new BrowserController();
    this.actionExecutor = new ActionExecutor();
    
    this.setupRoutes();
    this.setupMiddleware();
  }

  private setupRoutes(): void {
    this.app.post('/execute', this.handleExecute.bind(this));
    this.app.post('/screenshot', this.handleScreenshot.bind(this));
    this.app.get('/health', this.handleHealthCheck.bind(this));
  }

  private async handleExecute(req: express.Request, res: express.Response): Promise<void> {
    try {
      const { url, actions, return_type, wait_for, timeout } = req.body;
      
      // Launch browser instance
      const browser = await this.browserController.launch({
        headless: process.env.HEADLESS === 'true',
        timeout: timeout || 30000
      });

      // Execute actions
      const results = await this.actionExecutor.execute(browser, {
        url,
        actions,
        returnType: return_type,
        waitFor: wait_for
      });

      // Clean up
      await browser.close();

      res.json(results);
    } catch (error) {
      res.status(500).json({
        error: 'Failed to execute browser actions',
        details: error.message
      });
    }
  }

  public start(port: number = 3000): void {
    this.app.listen(port, () => {
      console.log(`Browser-use MCP Server running on port ${port}`);
    });
  }
}
```

### 2.3 Phase 3: COGO Agent Integration (Week 5-6)

#### 2.3.1 cogo-executor-agent Enhancement
```typescript
// src/agents/cogo-executor-agent.ts
export class CogoExecutorAgent extends BaseAgent {
  private figmaMCPClient: FigmaMCPClient;
  private browserMCPClient: BrowserMCPClient;

  constructor() {
    super();
    this.figmaMCPClient = new FigmaMCPClient(process.env.FIGMA_MCP_URL);
    this.browserMCPClient = new BrowserMCPClient(process.env.BROWSER_MCP_URL);
  }

  protected async processSubtask(subtask: Subtask): Promise<SubtaskResult> {
    switch (subtask.type) {
      case 'FETCH_FIGMA_CONTEXT':
        return await this.handleFigmaContextRequest(subtask);
      
      case 'EXECUTE_BROWSER_ACTION':
        return await this.handleBrowserActionRequest(subtask);
      
      default:
        return await super.processSubtask(subtask);
    }
  }

  private async handleFigmaContextRequest(subtask: Subtask): Promise<SubtaskResult> {
    try {
      const { figma_url, target_nodes, context_type, include_assets } = subtask.params;
      
      const context = await this.figmaMCPClient.getContext({
        figma_url,
        target_nodes,
        context_type,
        include_assets
      });

      return {
        subtask_id: subtask.subtask_id,
        task_id: subtask.task_id,
        status: 'completed',
        output: context,
        metadata: {
          source: 'figma-mcp-server',
          timestamp: new Date().toISOString()
        }
      };
    } catch (error) {
      return {
        subtask_id: subtask.subtask_id,
        task_id: subtask.task_id,
        status: 'failed',
        error: error.message,
        metadata: {
          source: 'figma-mcp-server',
          timestamp: new Date().toISOString()
        }
      };
    }
  }

  private async handleBrowserActionRequest(subtask: Subtask): Promise<SubtaskResult> {
    try {
      const { url, actions, return_type, wait_for, timeout } = subtask.params;
      
      const result = await this.browserMCPClient.execute({
        url,
        actions,
        return_type,
        wait_for,
        timeout
      });

      return {
        subtask_id: subtask.subtask_id,
        task_id: subtask.task_id,
        status: 'completed',
        output: result,
        metadata: {
          source: 'browser-mcp-server',
          timestamp: new Date().toISOString()
        }
      };
    } catch (error) {
      return {
        subtask_id: subtask.subtask_id,
        task_id: subtask.task_id,
        status: 'failed',
        error: error.message,
        metadata: {
          source: 'browser-mcp-server',
          timestamp: new Date().toISOString()
        }
      };
    }
  }
}
```

### 2.4 Phase 4: Client Development (Week 7-8)

#### 2.4.1 Enhanced COGO Client Features
```typescript
// cogo-client/src/components/figma/FigmaDesignViewer.tsx
export const FigmaDesignViewer: React.FC<FigmaDesignViewerProps> = ({
  figmaUrl,
  onContextExtracted
}) => {
  const [designContext, setDesignContext] = useState<FigmaContext | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const extractContext = async () => {
    setIsLoading(true);
    try {
      const response = await fetch('/api/figma/extract-context', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ figma_url: figmaUrl })
      });
      
      const context = await response.json();
      setDesignContext(context);
      onContextExtracted?.(context);
    } catch (error) {
      console.error('Failed to extract Figma context:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="figma-design-viewer">
      <div className="figma-preview">
        <iframe
          src={`https://www.figma.com/embed?embed_host=share&url=${encodeURIComponent(figmaUrl)}`}
          width="100%"
          height="600"
          frameBorder="0"
        />
      </div>
      
      <div className="figma-controls">
        <Button onClick={extractContext} disabled={isLoading}>
          {isLoading ? 'Extracting...' : 'Extract Design Context'}
        </Button>
      </div>

      {designContext && (
        <div className="figma-context">
          <h3>Extracted Design Context</h3>
          <div className="context-sections">
            <ColorPaletteSection colors={designContext.extracted_context.color_palette} />
            <TypographySection typography={designContext.extracted_context.typography} />
            <ComponentHierarchySection components={designContext.extracted_context.component_hierarchy} />
          </div>
        </div>
      )}
    </div>
  );
};
```

## 3. Database Schema Extensions

### 3.1 MCP Server Metadata Tables
```sql
-- MCP Server configurations
CREATE TABLE cogo_mcp_servers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'figma-context', 'browser-use'
    server_url VARCHAR(255) NOT NULL,
    health_status VARCHAR(20) DEFAULT 'unknown',
    last_health_check TIMESTAMP WITH TIME ZONE,
    config JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MCP Server execution logs
CREATE TABLE cogo_mcp_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    server_id UUID REFERENCES cogo_mcp_servers(id),
    subtask_id UUID NOT NULL,
    task_id UUID NOT NULL,
    request_data JSONB,
    response_data JSONB,
    execution_time_ms INTEGER,
    status VARCHAR(20), -- 'success', 'failed', 'timeout'
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Figma design contexts cache
CREATE TABLE cogo_figma_contexts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    figma_url TEXT NOT NULL,
    file_id VARCHAR(100) NOT NULL,
    context_data JSONB NOT NULL,
    cache_key VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Browser automation sessions
CREATE TABLE cogo_browser_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id VARCHAR(100) UNIQUE NOT NULL,
    url TEXT NOT NULL,
    actions JSONB NOT NULL,
    results JSONB,
    screenshots JSONB,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);
```

## 4. Supabase Real-time Message Specification

### 4.1 New Subtask Types
```typescript
// Figma Context Extraction Request
{
  "subtask_id": "uuid-subtask-figma-001",
  "task_id": "uuid-task-xyz",
  "type": "FETCH_FIGMA_CONTEXT",
  "params": {
    "figma_url": "https://www.figma.com/file/...",
    "target_nodes": ["Login Button", "Password Input"],
    "context_type": "full_json"
  }
}

// Browser Action Execution Request
{
  "subtask_id": "uuid-subtask-browser-002",
  "task_id": "uuid-task-xyz",
  "type": "EXECUTE_BROWSER_ACTION",
  "params": {
    "url": "https://example.com/login",
    "actions": [
      {"action": "type", "selector": "#username", "text": "testuser"},
      {"action": "type", "selector": "#password", "text": "password123"},
      {"action": "click", "selector": "#login-button"},
      {"action": "screenshot", "output_variable": "login_result_screenshot"}
    ],
    "return_type": "dom_snapshot"
  }
}
```

## 5. Testing Strategy

### 5.1 Unit Testing
```typescript
// tests/mcp-servers/figma-context.test.ts
describe('Figma Context MCP Server', () => {
  let server: FigmaContextMCPServer;
  let figmaAPI: jest.Mocked<FigmaAPI>;

  beforeEach(() => {
    figmaAPI = createMockFigmaAPI();
    server = new FigmaContextMCPServer(figmaAPI);
  });

  describe('GET /getContext', () => {
    it('should extract context from valid Figma URL', async () => {
      const mockFigmaData = createMockFigmaData();
      figmaAPI.getFile.mockResolvedValue(mockFigmaData);

      const response = await request(server.app)
        .post('/getContext')
        .send({
          figma_url: 'https://www.figma.com/file/test123/Design',
          context_type: 'full_json'
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('design_data');
      expect(response.body).toHaveProperty('extracted_context');
    });
  });
});
```

## 6. Deployment Configuration

### 6.1 Kubernetes Deployment
```yaml
# k8s/mcp-servers.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cogo-figma-mcp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cogo-figma-mcp
  template:
    metadata:
      labels:
        app: cogo-figma-mcp
    spec:
      containers:
      - name: figma-mcp
        image: cogo/figma-mcp:latest
        ports:
        - containerPort: 3000
        env:
        - name: FIGMA_API_KEY
          valueFrom:
            secretKeyRef:
              name: figma-api-secret
              key: api-key
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
```

## 7. Security Considerations

### 7.1 Network Security
- **Internal Communication**: All MCP servers communicate within the internal Docker network
- **External Access**: Only HTTPS outbound traffic for Figma API and web scraping
- **Authentication**: API key-based authentication for Figma API
- **Rate Limiting**: Implemented at both MCP server and COGO agent levels

### 7.2 Data Security
- **Sensitive Data**: Figma API keys stored as Kubernetes secrets
- **Data Encryption**: All data in transit encrypted with TLS
- **Access Control**: Row-level security in Supabase for user data
- **Audit Logging**: All MCP server interactions logged for audit purposes

## 8. Performance Optimization

### 8.1 Caching Strategy
- **Figma Context Caching**: Redis-based caching with TTL for design contexts
- **Browser Session Caching**: In-memory caching for active browser sessions
- **API Response Caching**: HTTP-level caching for repeated requests

### 8.2 Resource Management
- **Connection Pooling**: Reuse browser instances and API connections
- **Memory Management**: Proper cleanup of browser resources
- **Concurrent Execution**: Parallel processing of independent actions

## 9. Future Enhancements

### 9.1 Advanced Features
1. **Real-time Collaboration**: Live Figma design updates triggering automatic code generation
2. **AI-Powered Analysis**: Machine learning models for design pattern recognition
3. **Multi-browser Support**: Chrome, Firefox, Safari automation capabilities
4. **Visual Regression Testing**: Automated UI testing with screenshot comparison

### 9.2 Scalability Improvements
1. **Horizontal Scaling**: Multiple MCP server instances with load balancing
2. **Microservices Architecture**: Further decomposition of MCP server functionality
3. **Edge Computing**: Distributed MCP servers for global performance
4. **Serverless Functions**: Event-driven MCP server execution

## 10. Conclusion

This comprehensive design and development plan provides a roadmap for successfully integrating Figma Context MCP Server and Browser-use MCP Server into the COGO Agent Core system. The implementation will enable sophisticated AI-driven development workflows that can understand visual design contexts and automate browser interactions.

The modular architecture ensures scalability, maintainability, and extensibility while maintaining the existing event-driven communication patterns. The phased development approach allows for incremental testing and validation of each component.

Key success factors include:
- Robust error handling and retry mechanisms
- Comprehensive monitoring and observability
- Security-first design principles
- Performance optimization strategies
- Thorough testing at all levels

The integration will significantly enhance the COGO system's capabilities, enabling more sophisticated and autonomous development workflows that bridge the gap between design and implementation.

---

**Document Version**: 1.0  
**Last Updated**: January 30, 2025  
**Next Review**: February 15, 2025  
**Status**: Design Complete - Ready for Implementation 