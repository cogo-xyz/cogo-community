# COGO Agent Core - Agent Architecture Overview

> See also: [COGO Autonomous Knowledge+Intelligent Distributed Agentic Platform](./design/COGO_AUTONOMOUS_DISTRIBUTED_AGENTIC_PLAN.md)

## Table of Contents
1. [Introduction](#introduction)
2. [System Architecture](#system-architecture)
3. [Agent Structure](#agent-structure)
4. [Agent Types and Roles](#agent-types-and-roles)
5. [Communication System](#communication-system)
6. [Workflow Management](#workflow-management)
7. [Knowledge Management](#knowledge-management)
8. [Development Guidelines](#development-guidelines)
9. [API Reference](#api-reference)
10. [Troubleshooting](#troubleshooting)

## Introduction

The COGO Agent Core is a sophisticated multi-agent system designed for autonomous software development and AI-powered code generation. The system implements a role-based architecture where specialized agents collaborate to accomplish complex development tasks.

### Key Features
- **Multi-Agent Collaboration**: Orchestrator and 5 specialized worker agents working together
- **Role-Based Architecture**: Dynamic role assignment and execution based on Supabase/Neo4j schemas
- **Real-time Communication**: Supabase Real-time for inter-agent messaging
- **Knowledge Integration**: Hybrid knowledge management with vector and graph databases
- **Workflow Orchestration**: LangGraph-based workflow execution
- **AI Model Integration**: Support for Claude, Gemini, and OpenAI models
- **User Session Management**: Centralized user session tracking and message processing
- **Centralized Configuration**: Unified configuration management for all services

## System Architecture

### Orchestrator-Worker Architecture

The COGO Agent Core implements an Orchestrator-Worker pattern where:

- **Orchestrator Agent**: Central intelligent search and session management system
- **Worker Agents**: Specialized agents that receive instructions from the Orchestrator
- **Role-based Execution**: Agents operate based on roles defined in Supabase and Neo4j schemas

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    COGO Agent Core                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Frontend  │  │   API Layer │  │  WebSocket  │         │
│  │   (React)   │  │   (Express) │  │   (Socket.io)│         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                    Agent Layer                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Orchestrator│  │   Executor  │  │   Gateway   │         │
│  │   Agent     │  │   Agent     │  │   Agent     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ CodeGen     │  │   Worker    │  │  Research   │         │
│  │  Service    │  │   Manager   │  │   Worker    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│  ┌─────────────┐                                            │
│  │ Indexing    │                                            │
│  │  Worker     │                                            │
│  └─────────────┘                                            │
├─────────────────────────────────────────────────────────────┤
│                  Service Layer                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   AI        │  │ Knowledge   │  │ Workflow    │         │
│  │  Clients    │  │  Manager    │  │  Engine     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                  Data Layer                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Supabase   │  │    Neo4j    │  │   SQLite    │         │
│  │ (PostgreSQL)│  │  (Graph DB) │  │  (Local)    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### Refactoring Summary (Distributed, Edge-first)

- Execution split: Core LLM/RAG/Embedding flows run on Supabase Edge Functions via SSE; distributed agents handle capabilities not suitable for Edge (e.g., long-running tasks, local compute, code build/test, advanced indexing/graph processing).
- Realtime messaging: Single Supabase Realtime subscription per container; routes are enforced via `(service, role, shard)` keys.
- Health & Observability: Each agent exposes `GET /health` (port-mapped locally) and a separate metrics service exposes `GET /health` and `/api/metrics/*` on port 3100 (local only).
- Required env: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (Realtime, Edge ingress). For authenticated server-to-DB access (AuthMiddleware and protected actions), `SUPABASE_SERVICE_ROLE_KEY` is required.

#### Local Ports (default)

- Orchestrator: host 6001 → container 3000 → `GET /health`
- Indexing: host 6002 → container 3000 → `GET /health`
- Research: host 6003 → container 3000 → `GET /health`
- Executor: host 6005 → container 3000 → `GET /health`
- Metrics (separate service): host 3100 → container 3100 → `GET /health`, `GET /api/metrics/health`

Notes
- Production should not publicly expose metrics; prefer internal-only access behind reverse proxy.
- Avoid port collisions with other local stacks; see `docs/runbook/ports-and-endpoints.md`.

### Distributed Bus and Orchestrator Standard (Update)

- Central message bus: `public.agent_messages` with routing keys `(service, role, shard, tenant)`
- One Realtime subscription per container (table=agent_messages, row-level filters by routing keys)
- Orchestrator = brain: Sense/Diagnose/Plan/Allocate/Observe/Evaluate/Update
- Executor = dispatcher: publishes standardized assignments (budget/TTL/model) via `payload.__assignment`
- Workers honor `__assignment` and focus on execution; governance (retry/backoff/audit) captured in DB
- Edge Ingress: Supabase Edge Function `orchestrator-chat` accepts external chat intents and enqueues to `(service=orchestrator, role=decide, shard=0)`

See `docs/plans/Distributed-Agents-Naming-and-Deployment.md` for naming, roles, deployment, and test plans.

#### Edge & Realtime Integration (Details)

- Edge Functions (SSE):
  - LLM chat/stream, embeddings, and RAG queries are executed at the edge for low-latency ingress and streaming.
  - Agents consume the results asynchronously via Realtime bus events and persist result traces for observability.
- Realtime Bus:
  - One channel subscription per container for `agent_messages` and a dedicated `tasks-<agentType>` channel per agent type.
  - Governance (retry/backoff/audit) is captured in DB and surfaced via metrics.
- Agent HTTP API (minimal):
  - `GET /health` reports status, agent type, uptime, and basic comm stats.
  - `GET /metrics` (Prometheus text) and `GET /api/metrics/summary` (JSON) are exposed only in dev where applicable.

#### New/Updated Processes

- `cogo-executor-dispatcher`: Dedicated executor/dispatcher enforcing `__assignment` (budget/TTL/model) and publishing to target routes
- `cogo-codegen-service`: Code generation service listening on `(service=codegen, role=generate, shard=N)`
- `cogo-build-test-worker`: Build and test worker listening on `(service=code, role=build-test, shard=N)`

#### Orchestrator-managed Workflows

- Indexing Workflow: `src/workflows/indexing.ts` (publish → wait → retry → gate → notify)
- Code-Build-Test Workflow: `src/workflows/codeBuildTest.ts` chaining codegen and build/test buses

Each workflow uses node types: Publish(bus), Wait(event/condition), Retry(backoff), Gate(assert), Notify(webhook).

### Component Relationships

- **Frontend**: React-based user interface for task management and monitoring
- **API Layer**: Express.js REST API for external communication
- **WebSocket**: Real-time communication for live updates
- **Agent Layer**: Core multi-agent system with specialized roles
- **Service Layer**: Shared services for AI, knowledge, and workflow management
- **Data Layer**: Multi-database architecture for different data types

## Agent Structure

### Base Agent Architecture

All agents inherit from the `BaseAgent` class, which provides common functionality:

```typescript
abstract class BaseAgent {
  protected id: string;
  protected name: string;
  protected type: string;
  protected status: AgentStatus;
  protected lastActivity: Date;
  protected tasksCompleted: number;
  protected averageTime: number;
  protected successRate: number;
  protected metadata: any;
  
  abstract initialize(): Promise<void>;
  abstract executeTask(task: Task): Promise<boolean>;
  abstract getStatus(): Promise<AgentStatus>;
  abstract shutdown(): Promise<void>;
}
```

### Agent Lifecycle

1. **Initialization**: Agent setup and resource allocation
2. **Task Processing**: Execution of assigned tasks
3. **Status Monitoring**: Health and performance tracking
4. **Graceful Shutdown**: Resource cleanup and state preservation

## Agent Types and Roles

### 1. 🧠 Orchestrator Agent (`cogo-orchestrator-agent`)

**Purpose**: Central coordination, task distribution, and user session management
**Responsibilities**:
- Task planning and decomposition
- Agent coordination and load balancing
- Workflow orchestration
- Decision making and strategy
- User session management and tracking
- User message processing and routing
- Progress updates and status notifications

**Key Features**:
- Role-based execution with dynamic role assignment
- LangGraph workflow integration
- Intelligent task routing
- Performance optimization
- Real-time user session tracking
- Message queuing and processing
- Progress monitoring and updates
- User response management

### 2. 👔 Executor Agent (`cogo-executor-agent`)

**Purpose**: Task execution and management
**Responsibilities**:
- Task execution and monitoring
- Subtask creation and management
- Progress tracking
- Result aggregation

**Key Features**:
- Task plan management
- Parallel execution support
- Error handling and retry logic
- Real-time status updates

### 3. ✍️ Code Generation Service (`cogo-codegen-service`)

**Purpose**: AI-powered code generation
**Responsibilities**:
- Source code generation
- Code analysis and optimization
- Language-specific code generation
- Code review and quality assessment

**Key Features**:
- Multi-language support
- AI model integration (Claude, Gemini, OpenAI)
- Code quality metrics
- Automated testing integration

### 4. 🦾 Sandbox Worker (`cogo-sandbox-worker`)

**Purpose**: Secure code execution environment
**Responsibilities**:
- Docker container management
- Code execution and testing
- Security isolation
- Resource monitoring

**Key Features**:
- Docker-based sandboxing
- Multi-language runtime support
- Resource limits and monitoring
- Security policy enforcement

### 5. 👤 Architecture Gateway (`cogo-arch-gateway`)

**Purpose**: User session management and message handling
**Responsibilities**:
- User session creation and management
- User message processing and routing
- Progress updates and status notifications
- User interface communication

**Key Features**:
- Real-time user session tracking
- Message queuing and processing
- Progress monitoring and updates
- User response management

### 6. ⚙️ System Gateway (`cogo-system-gateway`)

**Purpose**: System-wide coordination, multilingual communication, and user session management
**Responsibilities**:
- Multilingual client communication and language detection
- User session management and intent analysis
- Agent lifecycle management
- System health monitoring
- Resource allocation
- Global state management

**Key Features**:
- **Multilingual Support**: Korean, English, Japanese, Chinese, Russian, Thai
- **Language Detection**: Automatic detection of client language
- **Intent Analysis**: AI-powered user intent analysis using Gemini 1.5 Flash
- **Session Management**: User session tracking and management
- **Agent registration and discovery**
- **Health monitoring and alerting**
- **Resource management**
- **System configuration**

### 7. 📚 Indexing Worker (`cogo-indexing-worker`)

**Purpose**: Knowledge indexing and search
**Responsibilities**:
- Code and document indexing
- Vector embedding generation
- Search optimization
- Knowledge graph maintenance

**Key Features**:
- Multi-format document processing
- Vector similarity search
- Knowledge graph updates
- Real-time indexing

### 8. 🔬 Research Worker (`cogo-research-worker`)

**Purpose**: Technology research and analysis
**Responsibilities**:
- Technology trend analysis
- Best practice research
- Solution comparison
- Documentation gathering

**Key Features**:
- Web search integration
- Technology comparison
- Documentation analysis
- Trend identification

## Worker Agent Architecture

### Base Worker Agent

All worker agents inherit from the `BaseWorkerAgent` class, which provides common worker functionality:

```typescript
abstract class BaseWorkerAgent extends BaseAgent {
  protected roleId: string;
  protected capabilities: RoleCapability[];
  protected status: WorkerAgentStatus;
  
  abstract executeRole(instruction: OrchestratorInstruction): Promise<RoleExecutionResult>;
  abstract getCapabilities(): RoleCapability[];
  abstract updateStatus(status: WorkerAgentStatus): Promise<void>;
}
```

### Worker Agent Types

#### 1. Task Execution Worker Agent
- **Purpose**: Execute complex tasks and manage subtasks
- **Capabilities**: MCP integration, task decomposition, result aggregation
- **Integration**: Figma context, browser actions, screenshots, DOM snapshots

#### 2. Code Generation Worker Agent
- **Purpose**: AI-powered code generation and analysis
- **Capabilities**: Multi-language code generation, code review, optimization
- **Integration**: Claude, Gemini, OpenAI models

#### 3. Sandbox Worker Agent
- **Purpose**: Secure code execution and compilation
- **Capabilities**: Docker container management, multi-language runtime
- **Integration**: OpenHands CLI, security isolation

#### 4. Indexing Worker Agent
- **Purpose**: Knowledge indexing and search optimization
- **Capabilities**: Vector embeddings, knowledge graph updates
- **Integration**: Hybrid knowledge management, Git event processing

#### 5. Research Worker Agent
- **Purpose**: Technology research and analysis
- **Capabilities**: Web search, documentation analysis, trend identification
- **Integration**: Context7Client, ResearchTaskProcessor

## Communication System

### Multilingual Communication Architecture

The system implements a sophisticated multilingual communication system:

#### Client Communication Flow
```
Client (Multiple Languages) 
    ↓
cogo-system-gateway (Language Detection & Translation)
    ↓
cogo-orchestrator-agent (English Only)
    ↓
Worker Agents (English Only)
```

#### Supported Languages
- **Korean (ko)**: 한국어 지원
- **English (en)**: 영어 지원  
- **Japanese (ja)**: 日本語サポート
- **Chinese (zh)**: 中文支持
- **Russian (ru)**: Русская поддержка
- **Thai (th)**: การสนับสนุนภาษาไทย

#### Language Processing Features
- **Automatic Language Detection**: Detects client language from message content
- **Intent Analysis**: Analyzes user intent in their native language using Gemini 1.5 Flash
- **Translation Services**: Translates between client language and English
- **Session Management**: Maintains language preferences across sessions

### Real-time Communication

The system uses Supabase Real-time for inter-agent communication:

```typescript
// Message structure
interface AgentMessage {
  id: string;
  sender: string;
  receiver: string;
  type: MessageType;
  payload: any;
  timestamp: Date;
  priority: Priority;
}

// Channel structure
const CHANNELS = {
  AGENT_MANAGER: 'agent-manager',
  TASK_MANAGER: 'task-manager',
  COGO_RESPONSES: 'cogo-responses',
  COGO_SUBTASKS: 'cogo-subtasks',
  INDEXING_REQUESTS: 'indexing-requests',
  WORKFLOW_EVENTS: 'workflow-events'
};
```

### Message Types

1. **Task Assignment**: Task distribution to agents
2. **Status Update**: Agent status and progress updates
3. **Result Notification**: Task completion and results
4. **Error Reporting**: Error handling and recovery
5. **System Events**: System-wide notifications

### Communication Patterns

1. **Request-Response**: Synchronous communication for immediate responses
2. **Publish-Subscribe**: Asynchronous communication for events
3. **Broadcast**: System-wide notifications
4. **Direct Messaging**: Point-to-point communication

## Workflow Management

### LangGraph Integration

The system uses LangGraph for workflow orchestration:

```typescript
interface WorkflowDefinition {
  id: string;
  name: string;
  description: string;
  nodes: WorkflowNode[];
  edges: WorkflowEdge[];
  entryPoint: string;
  exitPoints: string[];
  config: WorkflowConfig;
}

interface WorkflowNode {
  id: string;
  name: string;
  type: NodeType;
  agentId?: string;
  inputs: string[];
  outputs: string[];
  config: any;
}
```

#### Health Endpoints

- All distributed agents: `GET /health` on their bound port (container 3000; mapped to host 6001/6002/6003/6005).
- Metrics service: `GET /health`, `GET /api/metrics/health` (host 3100).

Typical `GET /health` payload (agent):

```json
{
  "status": "running",
  "agent": "orchestrator",
  "agentId": "orchestrator-<ts>",
  "uptime": 12.34,
  "timestamp": "<iso>"
}
```

### Workflow Types

1. **Code Generation Workflow**: End-to-end code generation process
2. **Bug Fix Workflow**: Automated bug detection and fixing
3. **Refactoring Workflow**: Code refactoring and optimization
4. **Testing Workflow**: Automated testing and validation

### Workflow Execution

1. **Workflow Registration**: Register workflow definitions
2. **Task Creation**: Create tasks from workflow templates
3. **Execution Monitoring**: Real-time workflow progress tracking
4. **Result Collection**: Aggregate and process results

## Knowledge Management

### Hybrid Knowledge System

The system implements a hybrid knowledge management approach:

```typescript
interface KnowledgeManager {
  // Vector search
  vectorSearch(query: string, options: SearchOptions): Promise<SearchResult[]>;
  
  // Graph search
  graphSearch(query: string, options: GraphSearchOptions): Promise<GraphResult[]>;
  
  // Semantic search
  semanticSearch(query: string, options: SemanticOptions): Promise<SemanticResult[]>;
  
  // Knowledge addition
  addKnowledge(content: string, metadata: KnowledgeMetadata): Promise<void>;
}
```

### Knowledge Sources

1. **Vector Database (Supabase pgvector)**: Document embeddings and similarity search
2. **Graph Database (Neo4j)**: Knowledge relationships and patterns
3. **Semantic Memory**: Context-aware knowledge retrieval
4. **External APIs**: Real-time information gathering

### Knowledge Types

1. **Code Knowledge**: Source code patterns and best practices
2. **Technology Knowledge**: Framework and library information
3. **Domain Knowledge**: Business logic and requirements
4. **Process Knowledge**: Workflow and methodology information

## Development Guidelines

### Agent Development

#### Agent File Naming Convention
All agent files must follow the `cogo-` prefix naming convention:
- `cogo-orchestrator-agent.ts`
- `cogo-system-gateway.ts`
- `cogo-executor-agent.ts`
- `cogo-research-worker.ts`
- `cogo-indexing-worker.ts`
- `cogo-sandbox-worker.ts`
- `cogo-codegen-service.ts`
- `cogo-graphrag-agent.ts`
- `cogo-intelligent-openhands-agent.ts`
- `cogo-langgraph-orchestrator-agent.ts`
- `cogo-manager-agent.ts`
- `cogo-openhands-agent.ts`

#### Creating a New Agent

```typescript
import { BaseAgent } from './BaseAgent';
import { Task, AgentStatus } from '../types';

export class CustomAgent extends BaseAgent {
  constructor() {
    super('custom-agent-01', 'Custom Agent', 'custom');
  }

  async initialize(): Promise<void> {
    // Initialize agent-specific resources
    this.status = 'ready';
  }

  async executeTask(task: Task): Promise<boolean> {
    try {
      // Implement task execution logic
      const result = await this.processTask(task);
      
      // Update task with results
      task.result = {
        output: result,
        status: 'completed',
        timestamp: new Date().toISOString()
      };
      
      return true;
    } catch (error) {
      task.result = {
        error: error.message,
        status: 'failed',
        timestamp: new Date().toISOString()
      };
      return false;
    }
  }

  async getStatus(): Promise<AgentStatus> {
    return {
      id: this.id,
      name: this.name,
      type: this.type,
      status: this.status,
      lastActivity: this.lastActivity,
      tasksCompleted: this.tasksCompleted,
      averageTime: this.averageTime,
      successRate: this.successRate,
      metadata: this.metadata
    };
  }

  async shutdown(): Promise<void> {
    // Cleanup resources
    this.status = 'shutdown';
  }
}
```

#### Best Practices

1. **Error Handling**: Implement comprehensive error handling
2. **Resource Management**: Proper resource allocation and cleanup
3. **Status Updates**: Regular status updates for monitoring
4. **Logging**: Detailed logging for debugging and monitoring
5. **Testing**: Unit and integration tests for all agents

### Configuration Management

#### Centralized Configuration Management
The system uses `ConfigurationManagementService` for centralized configuration management:

```typescript
// Database Configuration
supabase.url
supabase.anonKey
supabase.serviceRoleKey
neo4j.uri
neo4j.username
neo4j.password
neo4j.database

// AI Service Configuration
ai.anthropic.key
ai.openai.key
ai.google.key
ai.fireworks.key

// System Configuration
server.orchestratorUrl
sandbox.openhandsPath
sandbox.workspaceBase
research.enableContext7Integration
indexing.projectPath
```

#### Environment Configuration

```typescript
interface AgentConfig {
  id: string;
  name: string;
  type: string;
  maxConcurrentTasks: number;
  timeout: number;
  retryAttempts: number;
  resources: ResourceLimits;
}
```

#### Required Environment Variables (Distributed Agents)

- `SUPABASE_URL` (required): Supabase project base URL.
- `SUPABASE_ANON_KEY` (required): for Realtime and Edge ingress.
- `SUPABASE_SERVICE_ROLE_KEY` (required by AuthMiddleware): for protected server operations.
- Optional per-role flags (feature flags, shards) are read via process.env.

If any of the required Supabase variables are missing, agents will fail to start with an explicit error (see Troubleshooting).

#### Configuration Sources

1. **Environment Variables**: Runtime configuration
2. **Configuration Files**: Static configuration
3. **Database**: Dynamic configuration
4. **API**: Remote configuration

## API Reference

### Multilingual Communication API

#### Chat Endpoint
```http
POST /api/multilingual/chat
Content-Type: application/json

{
  "message": "Create a React component",
  "language": "ko",
  "sessionId": "session-001",
  "userId": "user-001"
}
```

Response:
```json
{
  "success": true,
  "response": "안녕하세요! React 컴포넌트를 만들어드릴게요...",
  "intent": "task_request",
  "confidence": 0.95,
  "detectedLanguage": "ko",
  "orchestratorResponse": {
    "message": "Task forwarded to orchestrator for processing",
    "taskId": "task-1234567890",
    "status": "processing"
  },
  "timestamp": "2025-08-03T12:15:01.049Z"
}
```

#### Supported Languages
- `ko`: Korean (한국어)
- `en`: English
- `ja`: Japanese (日本語)
- `zh`: Chinese (中文)
- `ru`: Russian (Русский)
- `th`: Thai (ไทย)

### Agent Management API

#### Get All Agents
```http
GET /api/agents
```

Response:
```json
{
  "agents": [
    {
      "id": "cogo-orchestrator-01",
      "name": "🧠 cogo-orchestrator-agent",
      "type": "orchestrator",
      "status": "idle",
      "lastActivity": "2025-07-31T15:17:41.157Z",
      "tasksCompleted": 0,
      "averageTime": 0,
      "successRate": 0
    }
  ],
  "total": 7,
  "stats": {
    "agents": 7
  }
}
```

#### Get Agent Status
```http
GET /api/agents/{agentId}
```

#### Create Task
```http
POST /api/tasks
Content-Type: application/json

{
  "title": "Task Title",
  "description": "Task Description",
  "priority": "medium",
  "type": "development"
}
```

### Health Monitoring API

#### System Health
```http
GET /health
```

Response:
```json
{
  "status": "healthy",
  "mode": "production",
  "message": "Server running in production mode with real AI models",
  "timestamp": "2025-07-31T15:17:41.157Z",
  "uptime": 19.522029167,
  "memory": {
    "rss": 522240000,
    "heapTotal": 490258432,
    "heapUsed": 468121040
  },
  "agents": {
    "total": 7,
    "active": 0,
    "idle": 0
  }
}
```

Agent Health (distributed containers)
- Orchestrator: `http://localhost:6001/health`
- Indexing: `http://localhost:6002/health`
- Research: `http://localhost:6003/health`
- Executor: `http://localhost:6005/health`
- Metrics service (local only): `http://localhost:3100/health`, `http://localhost:3100/api/metrics/health`

### Workflow API

#### Get Workflow Templates
```http
GET /api/workflows/templates
```

#### Execute Workflow
```http
POST /api/workflows/execute
Content-Type: application/json

{
  "workflowId": "code-generation",
  "parameters": {
    "projectDescription": "Create a React todo app",
    "language": "typescript"
  }
}
```

## Troubleshooting

### JSON Parsing Issues

#### Problem
AI responses may contain malformed JSON that causes parsing failures.

#### Solution
The system implements a robust 5-stage JSON parsing system:
1. **Direct Parsing**: Attempt to parse the response directly
2. **Content Extraction**: Extract JSON content using pattern matching
3. **Cleaned Parsing**: Parse after basic cleaning operations
4. **Aggressive Fixing**: Apply comprehensive JSON repair techniques
5. **Structure Reconstruction**: Reconstruct JSON from content analysis

#### Example
```typescript
// The system automatically handles malformed JSON like:
{
  "components": [
    "Component1",
    "Component2",  // trailing comma
  ],
  "fileStructure": [
    "file1.ts",
    "file2.ts"
  ]
}
```

### Common Issues

#### Agent Initialization Failures

**Symptoms**: Agent fails to start or initialize
**Causes**: Missing dependencies, configuration errors, resource constraints
**Solutions**:
1. Check agent logs for specific error messages
2. Verify all required dependencies are installed
3. Validate configuration settings
4. Check resource availability

Common fatal error (env missing)
- Symptom: Containers restart repeatedly; logs show `Missing required Supabase environment variables` from `AuthMiddleware` or `RealDistributedAgentServer`.
- Fix: Ensure `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are provided to containers. When using compose, pass an env file: `docker compose --env-file env.development -f infra/compose/docker-compose.pipeline.yml up -d`.

#### Communication Issues

**Symptoms**: Agents not receiving messages or tasks
**Causes**: Network issues, Supabase connection problems, channel configuration
**Solutions**:
1. Verify Supabase connection status
2. Check channel subscriptions
3. Validate message format
4. Monitor network connectivity

#### Health Endpoint Timeouts
- Ensure containers are listening on container port 3000 and host ports are not blocked or conflicting.
- Check that the server has started: `docker compose -f infra/compose/docker-compose.pipeline.yml logs --tail=200`.

#### Performance Issues

**Symptoms**: Slow task execution, high memory usage
**Causes**: Resource constraints, inefficient algorithms, memory leaks
**Solutions**:
1. Monitor resource usage
2. Optimize algorithms and data structures
3. Implement proper resource cleanup
4. Scale resources as needed

### Debugging Tools

#### Logging

The system provides comprehensive logging:

```typescript
import { logger } from '../utils/logger';

logger.info('Agent initialized successfully');
logger.error('Task execution failed', { error, taskId });
logger.debug('Processing task', { task, agentId });
```

#### Monitoring

Real-time monitoring is available through:

1. **Health Endpoints**: System and agent health status
2. **Metrics Collection**: Performance and usage metrics
3. **Alert System**: Automated alerts for issues
4. **Dashboard**: Web-based monitoring interface

### Performance Optimization

#### Agent Optimization

1. **Concurrent Processing**: Implement parallel task processing
2. **Resource Pooling**: Share resources between agents
3. **Caching**: Cache frequently accessed data
4. **Lazy Loading**: Load resources on demand

#### System Optimization

1. **Load Balancing**: Distribute tasks evenly across agents
2. **Resource Management**: Efficient resource allocation
3. **Connection Pooling**: Reuse database connections
4. **Compression**: Compress data in transit

## Conclusion

The COGO Agent Core provides a robust and scalable foundation for AI-powered software development. The multi-agent architecture enables complex task execution while maintaining system reliability and performance.

### Key Benefits

1. **Scalability**: Horizontal scaling through agent distribution
2. **Reliability**: Fault tolerance and error recovery
3. **Flexibility**: Dynamic role assignment and workflow execution
4. **Extensibility**: Easy addition of new agents and capabilities
5. **Monitoring**: Comprehensive health and performance monitoring

### Future Enhancements

1. **Advanced AI Integration**: Enhanced AI model support with improved JSON parsing
2. **Distributed Processing**: Multi-node agent distribution
3. **Advanced Workflows**: Complex workflow orchestration
4. **Enhanced Security**: Advanced security and access control
5. **Performance Optimization**: Advanced performance tuning
6. **Extended Multilingual Support**: Additional languages and dialects
7. **Advanced Configuration Management**: Dynamic configuration updates
8. **Enhanced Monitoring**: Advanced system monitoring and alerting

For more information, refer to the individual agent documentation and API reference guides. 

## Deployment Note (cogo0-agent)

- New distributed stack name: `cogo0-agent`
- Local ports: 6101/6102/6103/6105 (agents), 3200 (metrics)
- Edge-first: LLM/RAG/Embedding via Supabase Edge + Realtime; agents consume services
- Neo4j: Aura `001b3e63` (bolt + HTTP Query API via Edge) 

## Edge Graph – Env-only

- The `graph` Edge function no longer queries DB (`secure_keys` removed)
- It uses env-only configuration in this order:
  1) `GRAPH_BRIDGE_URL` proxy if set
  2) Aura HTTP Query API v2 via `NEO4J_HTTP_URL`, `NEO4J_USER`, `NEO4J_PASSWORD`, `NEO4J_DB` (fallback to `/tx/commit`)
  3) Otherwise returns `{ ok:false, stats.message: 'neo4j_not_configured' }`
- Distributed agents call Edge with `SUPABASE_EDGE`/`SUPABASE_ANON_KEY`. 