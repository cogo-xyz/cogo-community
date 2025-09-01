# COGO Agent Core - API Reference

## Table of Contents
1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Base URL](#base-url)
4. [Response Format](#response-format)
5. [Error Handling](#error-handling)
6. [Core APIs](#core-apis)
7. [Agent APIs](#agent-apis)
8. [Workflow APIs](#workflow-apis)
9. [Knowledge APIs](#knowledge-apis)
10. [Monitoring APIs](#monitoring-apis)

## Overview

The COGO Agent Core provides a comprehensive REST API for interacting with the multi-agent system. All APIs return JSON responses and use standard HTTP status codes.

### API Versioning
- Current Version: `v2.0.0`
- Base Path: `/api/v2`
- All endpoints are prefixed with `/api/v2`

## Authentication

Currently, the API uses a simple API key authentication system:

```http
Authorization: Bearer YOUR_API_KEY
```

### API Key Management
```http
GET /api/v2/auth/keys
POST /api/v2/auth/keys
DELETE /api/v2/auth/keys/{keyId}
```

## Base URL

- **Development**: `http://localhost:3000`
- **Production**: `https://your-domain.com`

## Response Format

All API responses follow a standard format:

### Success Response
```json
{
  "success": true,
  "data": {
    // Response data
  },
  "timestamp": "2025-07-31T15:17:41.157Z",
  "duration": "45ms"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": {
      "field": "title",
      "issue": "Title is required"
    }
  },
  "timestamp": "2025-07-31T15:17:41.157Z"
}
```

## Error Handling

### HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Validation Error
- `500` - Internal Server Error
- `503` - Service Unavailable

### Error Codes
- `VALIDATION_ERROR` - Request validation failed
- `AUTHENTICATION_ERROR` - Authentication failed
- `AUTHORIZATION_ERROR` - Insufficient permissions
- `RESOURCE_NOT_FOUND` - Requested resource not found
- `AGENT_UNAVAILABLE` - Agent is not available
- `WORKFLOW_ERROR` - Workflow execution error
- `SYSTEM_ERROR` - Internal system error

## Core APIs

### Health Check

#### Get System Health
```http
GET /health
```

**Response:**
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
    "heapUsed": 468121040,
    "external": 8686603,
    "arrayBuffers": 4776071
  },
  "agents": {
    "total": 7,
    "active": 0,
    "idle": 0
  },
  "system": {
    "agents": 7
  },
  "duration": "1ms"
}
```

#### Get Environment Status
```http
GET /api/environment/status
```

**Response:**
```json
{
  "environment": "development",
  "isProduction": false,
  "isDevelopment": true,
  "isValid": true,
  "errors": [],
  "warnings": [],
  "config": {
    "NODE_ENV": "development",
    "ENVIRONMENT_LOCK": "development",
    "PREVENT_PRODUCTION_DEPLOY": true,
    "PREVENT_DEVELOPMENT_MODE": false,
    "SAFE_MODE": true,
    "PRODUCTION_MODE": false
  }
}
```

### System Information

#### Get System Overview
```http
GET /
```

**Response:**
```json
{
  "message": "COGO Agent Core Server",
  "version": "2.0.0",
  "status": "running",
  "timestamp": "2025-07-31T15:17:50.307Z",
  "endpoints": {
    "health": "/health",
    "agents": "/api/agents",
    "environment": "/api/environment/status",
    "cogo": "/api/cogo/health",
    "ai": "/api/ai/status",
    "workflows": "/api/workflows/templates",
    "rag": "/api/rag/stats",
    "research": "/api/research/health",
    "phase4": "/api/phase4/overview"
  }
}
```

## Agent APIs

### Agent Management

#### Get All Agents
```http
GET /api/agents
```

**Response:**
```json
{
  "agents": [
    {
      "id": "cogo-intelligence-01",
      "name": "COGO Intelligence Orchestrator Fast",
      "type": "orchestrator",
      "status": "idle",
      "lastActivity": "2025-07-31T14:34:10.510Z",
      "tasksCompleted": 0,
      "averageTime": 0,
      "successRate": 0,
      "performance": {
        "tasksCompleted": 0,
        "averageTime": 0,
        "successRate": 0
      },
      "metadata": {
        "aiStats": {
          "totalResponses": 0,
          "modelUsage": {},
          "taskTypeStats": {},
          "averageResponseLength": 0
        },
        "decisionStats": {
          "totalDecisions": 0,
          "ragBasedDecisions": 0,
          "llmBasedDecisions": 0,
          "averageConfidence": 0
        }
      }
    }
  ],
  "total": 7,
  "stats": {
    "agents": 7
  }
}
```

#### Get Agent by ID
```http
GET /api/agents/{agentId}
```

#### Restart Agent
```http
POST /api/agents/{agentId}/restart
Content-Type: application/json

{
  "reason": "performance_optimization"
}
```

#### Get Agent Status
```http
GET /api/agents/{agentId}/status
```

### Task Management

#### Create Task
```http
POST /api/tasks
Content-Type: application/json

{
  "title": "Create a React todo application",
  "description": "Build a full-stack todo app with React, Node.js, and PostgreSQL",
  "priority": "high",
  "type": "development",
  "requirements": {
    "frontend": "React with TypeScript",
    "backend": "Node.js with Express",
    "database": "PostgreSQL",
    "features": ["CRUD operations", "user authentication", "real-time updates"]
  }
}
```

**Response:**
```json
{
  "success": true,
  "taskPlan": {
    "planId": "req_1753972483115",
    "status": "planning",
    "message": "Task plan created and execution started"
  },
  "message": "Task plan created successfully"
}
```

#### Get Task Status
```http
GET /api/tasks/{taskId}
```

#### Get All Tasks
```http
GET /api/tasks
```

**Query Parameters:**
- `status` - Filter by task status
- `priority` - Filter by priority
- `type` - Filter by task type
- `limit` - Number of tasks to return
- `offset` - Number of tasks to skip

#### Cancel Task
```http
POST /api/tasks/{taskId}/cancel
```

## Workflow APIs

### Workflow Templates

#### Get Workflow Templates
```http
GET /api/workflows/templates
```

**Response:**
```json
{
  "success": true,
  "templates": {
    "codeGeneration": {
      "name": "Code Generation Workflow",
      "description": "OpenHands를 활용한 코드 생성 워크플로우",
      "nodes": [
        {
          "id": "analyze-requirements",
          "name": "Requirements Analysis",
          "type": "agent",
          "agentId": "cogo-ai-01",
          "inputs": ["project_description"],
          "outputs": ["requirements"]
        }
      ],
      "edges": [
        {
          "id": "edge1",
          "from": "analyze-requirements",
          "to": "generate-code"
        }
      ],
      "entryPoint": "analyze-requirements",
      "exitPoints": ["compile-test"]
    }
  }
}
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

### Orchestrator APIs

#### Plan
```http
POST /api/orchestrator/plan
Content-Type: application/json

{
  "intent": "code",
  "payload": { "q": "Add logging" },
  "tenant": "default"
}
```

#### Execute (dispatcher/direct)
```http
POST /api/orchestrator/execute?mode=dispatcher
Content-Type: application/json

{
  "intent": "code",
  "payload": { "task_id": "task-123" },
  "tenant": "default"
}
```

#### State
```http
GET /api/orchestrator/state
```

### Metrics APIs (Observability)

#### Bus Latency
```http
GET /api/metrics/bus/latency?service=&role=&shard=&since_min=60
```

#### Bus Events
```http
GET /api/metrics/bus/events?limit=100
```

#### Workflows Summary
```http
GET /api/metrics/workflows/codeBuildTest
GET /api/metrics/workflows/indexing
```

#### Decision Quality (Orchestrator)
```http
GET /api/metrics/orchestrator/decision-quality?since_min=120
```

### Gate APIs

#### Decide Gate
```http
POST /api/gate/decide
Content-Type: application/json

{
  "stepId": "gate-1",
  "policy": "all_required_critics_pass",
  "critiques": [
    { "step_id": "c1", "critic": "compile_check_tsc", "verdict": "pass", "score": 1.0 }
  ]
}
```

#### Get Workflow Status
```http
GET /api/workflows/{workflowId}/status
```

#### Cancel Workflow
```http
POST /api/workflows/{workflowId}/cancel
```

### Workflow Management

#### Register Workflow
```http
POST /api/workflows/register
Content-Type: application/json

{
  "workflowId": "custom-workflow",
  "workflow": {
    "name": "Custom Workflow",
    "description": "A custom workflow",
    "nodes": [],
    "edges": [],
    "entryPoint": "start",
    "exitPoints": ["end"]
  }
}
```

#### Get Workflow Statistics
```http
GET /api/workflows/stats
```

## Knowledge APIs

### RAG System

#### Get RAG Statistics
```http
GET /api/rag/stats
```

**Response:**
```json
{
  "success": true,
  "data": {
    "vectorDocuments": 8,
    "graphNodes": 144,
    "graphRelationships": 58,
    "cacheSize": 0,
    "lastSearchTime": 1753972466800
  },
  "message": "System statistics retrieved successfully"
}
```

#### Vector Search
```http
POST /api/rag/vector-search
Content-Type: application/json

{
  "query": "React component patterns",
  "limit": 10,
  "filters": {
    "language": "typescript",
    "framework": "react"
  }
}
```

#### Graph Search
```http
POST /api/rag/graph-search
Content-Type: application/json

{
  "query": "microservices architecture",
  "depth": 3,
  "relationships": ["USES", "DEPENDS_ON"]
}
```

#### Hybrid Search
```http
POST /api/rag/hybrid-search
Content-Type: application/json

{
  "query": "authentication implementation",
  "vectorWeight": 0.6,
  "semanticWeight": 0.3,
  "graphWeight": 0.1,
  "limit": 15
}
```

### Knowledge Management

#### Add Knowledge
```http
POST /api/knowledge/add
Content-Type: application/json

{
  "content": "React Hooks provide a way to use state and other React features in functional components.",
  "metadata": {
    "type": "documentation",
    "language": "typescript",
    "framework": "react",
    "tags": ["hooks", "state", "functional-components"]
  }
}
```

#### Search Knowledge
```http
POST /api/knowledge/search
Content-Type: application/json

{
  "query": "React hooks state management",
  "type": "hybrid",
  "filters": {
    "type": "documentation",
    "framework": "react"
  }
}
```

## AI APIs

### AI Status

#### Get AI Status
```http
GET /api/ai/status
```

**Response:**
```json
{
  "success": true,
  "models": {
    "claude": {
      "available": true,
      "status": "ready"
    },
    "gemini": {
      "available": true,
      "status": "ready"
    }
  },
  "timestamp": "2025-07-31T14:34:20.237Z"
}
```

### AI Chat

#### Chat with AI
```http
POST /api/ai/chat
Content-Type: application/json

{
  "prompt": "Explain React hooks in detail",
  "model": "claude",
  "temperature": 0.7,
  "maxTokens": 1000
}
```

**Response:**
```json
{
  "success": true,
  "response": "React Hooks are functions that allow you to use state and other React features in functional components...",
  "model": "claude-3-5-sonnet-20241022",
  "usage": {
    "prompt_tokens": 58,
    "completion_tokens": 58,
    "total_tokens": 58
  },
  "metadata": {
    "provider": "real",
    "model_version": "claude-3-5-sonnet-20241022",
    "temperature": 0.7
  },
  "timestamp": "2025-07-31T14:35:08.730Z"
}
```

### Code Generation

#### Generate Code
```http
POST /api/ai/code-generation
Content-Type: application/json

{
  "language": "typescript",
  "framework": "react",
  "requirements": "Create a todo list component with add, edit, and delete functionality",
  "context": "Existing React application with TypeScript",
  "style": {
    "indentation": 2,
    "quotes": "single",
    "semicolons": true
  }
}
```

#### Analyze Code
```http
POST /api/ai/code-analysis
Content-Type: application/json

{
  "filePath": "src/components/TodoList.tsx",
  "analysisType": "quality-assessment",
  "includeMetrics": true
}
```

## Research APIs

### Technology Research

#### Research Technology
```http
POST /api/research/technology
Content-Type: application/json

{
  "query": "React vs Vue performance comparison 2024",
  "scope": "comprehensive",
  "sources": ["web", "documentation", "social"],
  "timeRange": "1 year"
}
```

#### Analyze Trends
```http
POST /api/research/trends
Content-Type: application/json

{
  "technology": "TypeScript",
  "timeRange": "2 years",
  "metrics": ["adoption", "performance", "community"]
}
```

### Research Health

#### Get Research Status
```http
GET /api/research/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-07-31T14:34:31.580Z",
  "version": "2.0.0",
  "service": "Google Deep Research API"
}
```

## Monitoring APIs

### System Monitoring

#### Get System Metrics
```http
GET /api/monitoring/metrics
```

#### Get Performance Statistics
```http
GET /api/monitoring/performance
```

#### Get Resource Usage
```http
GET /api/monitoring/resources
```

### Agent Monitoring

#### Get Agent Metrics
```http
GET /api/monitoring/agents/{agentId}/metrics
```

#### Get Agent Performance
```http
GET /api/monitoring/agents/{agentId}/performance
```

### Real-time Monitoring

#### Get Real-time Queue Status
```http
GET /api/realtime-queue/health
```

**Response:**
```json
{
  "success": true,
  "status": "healthy",
  "timestamp": "2025-07-31T14:34:39.014Z",
  "queue_status": {
    "totalJobs": 31,
    "pendingJobs": 7,
    "inProgressJobs": 0,
    "completedJobs": 24,
    "failedJobs": 0
  }
}
```

## Phase 4 APIs

### Collaboration System

#### Get Phase 4 Overview
```http
GET /api/phase4/overview
```

**Response:**
```json
{
  "success": true,
  "data": {
    "phase": 4,
    "name": "Advanced Agent Collaboration System",
    "description": "High-level multi-agent collaboration with mentoring and real-time communication",
    "features": [
      "Mentoring Pool Management",
      "Collaboration Session Management",
      "Real-time Communication",
      "Decision Making Framework"
    ],
    "stats": {
      "mentoring": {
        "mentors": {
          "total": 3,
          "available": 3,
          "busy": 0,
          "averageExperience": 9
        },
        "mentees": {
          "total": 2,
          "active": 2,
          "withMentor": 0,
          "averageProgress": 0.5166666666666666
        }
      }
    },
    "status": "active"
  }
}
```

### Mentoring System

#### Get Available Mentors
```http
GET /api/phase4/mentors
```

#### Create Mentoring Session
```http
POST /api/phase4/mentoring/sessions
Content-Type: application/json

{
  "mentorId": "mentor_code_review_01",
  "menteeId": "mentee_junior_dev_01",
  "topic": "Code Review Best Practices",
  "duration": 60
}
```

#### Get Mentoring Statistics
```http
GET /api/phase4/mentoring/stats
```

### Collaboration Sessions

#### Create Collaboration Session
```http
POST /api/phase4/collaboration/sessions
Content-Type: application/json

{
  "participants": ["agent1", "agent2", "agent3"],
  "topic": "System Architecture Design",
  "duration": 120
}
```

#### Get Active Sessions
```http
GET /api/phase4/collaboration/sessions/active
```

## Indexing APIs

### Indexing Management

#### Get Indexing Status
```http
GET /api/indexing/status
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "indexing-worker",
    "name": "Indexing Worker",
    "type": "indexer",
    "status": "idle",
    "lastActivity": "2025-07-31T14:35:11.676Z",
    "totalTasks": 0,
    "averageTime": 0,
    "successRate": 0,
    "metadata": {
      "config": {
        "projectPath": "./workspace",
        "includePatterns": ["**/*.ts", "**/*.js", "**/*.tsx"],
        "excludePatterns": ["**/node_modules/**", "**/dist/**"]
      },
      "isIndexing": false,
      "embeddingService": {
        "initialized": true,
        "model": "text-embedding-3-small",
        "hasOpenAI": true
      }
    }
  },
  "message": "Indexing status retrieved successfully"
}
```

#### Index File
```http
POST /api/indexing/index
Content-Type: application/json

{
  "filePath": "src/components/TodoList.tsx",
  "content": "export const TodoList = () => { ... }",
  "metadata": {
    "language": "typescript",
    "framework": "react",
    "type": "component"
  }
}
```

#### Search Indexed Content
```http
POST /api/indexing/search
Content-Type: application/json

{
  "query": "todo list component",
  "type": "hybrid",
  "filters": {
    "language": "typescript",
    "framework": "react"
  },
  "limit": 10
}
```

## Sandbox APIs

### Container Management

#### Create Container
```http
POST /api/sandbox/create
Content-Type: application/json

{
  "language": "typescript",
  "version": "20",
  "resources": {
    "cpu": "1",
    "memory": "512m",
    "disk": "1g"
  }
}
```

#### Execute Code
```http
POST /api/sandbox/execute
Content-Type: application/json

{
  "containerId": "container-123",
  "code": "console.log('Hello, World!');",
  "timeout": 30000
}
```

#### Get Container Status
```http
GET /api/sandbox/containers/{containerId}
```

#### Stop Container
```http
POST /api/sandbox/containers/{containerId}/stop
```

## Architecture APIs

### Architecture Analysis

#### Analyze Architecture
```http
POST /api/arch/analyze
Content-Type: application/json

{
  "codebase": "path/to/codebase",
  "analysisType": "comprehensive",
  "focusAreas": ["scalability", "performance", "security"]
}
```

#### Get Technology Recommendations
```http
POST /api/arch/recommend
Content-Type: application/json

{
  "requirements": {
    "scale": "high",
    "performance": "critical",
    "security": "enterprise"
  },
  "constraints": {
    "budget": "medium",
    "teamSize": "small",
    "timeline": "aggressive"
  }
}
```

## Rate Limiting

The API implements rate limiting to ensure fair usage:

- **Standard Rate Limit**: 100 requests per minute per API key
- **Burst Rate Limit**: 10 requests per second per API key
- **Rate Limit Headers**: Included in all responses

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## Pagination

List endpoints support pagination:

```http
GET /api/tasks?limit=20&offset=40
```

**Response Headers:**
```http
X-Total-Count: 150
X-Page-Size: 20
X-Current-Page: 3
X-Total-Pages: 8
```

## WebSocket Events

The system provides real-time updates via WebSocket:

### Connection
```javascript
const socket = io('http://localhost:3000');

socket.on('connect', () => {
  console.log('Connected to COGO Agent Core');
});

socket.on('disconnect', () => {
  console.log('Disconnected from COGO Agent Core');
});
```

### Event Types

#### Task Events
```javascript
socket.on('task_created', (data) => {
  console.log('New task created:', data);
});

socket.on('task_updated', (data) => {
  console.log('Task updated:', data);
});

socket.on('task_completed', (data) => {
  console.log('Task completed:', data);
});
```

#### Agent Events
```javascript
socket.on('agent_status_changed', (data) => {
  console.log('Agent status changed:', data);
});

socket.on('agent_error', (data) => {
  console.log('Agent error:', data);
});
```

#### System Events
```javascript
socket.on('system_alert', (data) => {
  console.log('System alert:', data);
});

socket.on('resource_warning', (data) => {
  console.log('Resource warning:', data);
});
```

## SDK Examples

### JavaScript/TypeScript SDK

```typescript
import { COGOClient } from '@cogo/client';

const client = new COGOClient({
  baseUrl: 'http://localhost:3000',
  apiKey: 'your-api-key'
});

// Create a task
const task = await client.tasks.create({
  title: 'Create React App',
  description: 'Build a React todo application',
  priority: 'high',
  type: 'development'
});

// Monitor task progress
const status = await client.tasks.getStatus(task.id);

// Get all agents
const agents = await client.agents.list();

// Execute workflow
const workflow = await client.workflows.execute({
  workflowId: 'code-generation',
  parameters: {
    projectDescription: 'Create a React todo app',
    language: 'typescript'
  }
});
```

### Python SDK

```python
from cogo_client import COGOClient

client = COGOClient(
    base_url="http://localhost:3000",
    api_key="your-api-key"
)

# Create a task
task = client.tasks.create({
    "title": "Create React App",
    "description": "Build a React todo application",
    "priority": "high",
    "type": "development"
})

# Monitor task progress
status = client.tasks.get_status(task.id)

# Get all agents
agents = client.agents.list()

# Execute workflow
workflow = client.workflows.execute({
    "workflowId": "code-generation",
    "parameters": {
        "projectDescription": "Create a React todo app",
        "language": "typescript"
    }
})
```

## Conclusion

This API reference provides comprehensive documentation for all endpoints in the COGO Agent Core system. The API is designed to be RESTful, consistent, and easy to use.

### Key Features

1. **RESTful Design**: Consistent HTTP methods and status codes
2. **JSON Responses**: All responses in JSON format
3. **Error Handling**: Comprehensive error codes and messages
4. **Rate Limiting**: Fair usage policies
5. **Real-time Updates**: WebSocket support for live updates
6. **SDK Support**: Official SDKs for popular languages

### Getting Started

1. **Get API Key**: Contact the system administrator
2. **Test Connection**: Use the health check endpoint
3. **Create Tasks**: Start with simple task creation
4. **Monitor Progress**: Use real-time updates
5. **Scale Up**: Implement advanced workflows

For more information, refer to the individual agent documentation and implementation guides. 