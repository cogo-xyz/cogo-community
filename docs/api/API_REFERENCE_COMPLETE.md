# COGO Agent Core API Reference

## Overview

The COGO Agent Core provides a comprehensive REST API for interacting with the multi-agent system. All endpoints are available at `http://localhost:3000` and support JSON request/response formats.

## Base URL
```
http://localhost:3000
```

## Authentication
Currently, the API operates without authentication in development mode. For production deployment, API key authentication will be implemented.

## Response Format
All API responses follow this standard format:
```json
{
  "id": "response-id",
  "requestId": "original-request-id",
  "status": "completed|failed|pending",
  "result": { /* response data */ },
  "metadata": {
    "processingTime": 1234,
    "agentId": "agent-id",
    "timestamp": "2025-08-01T06:00:00.000Z"
  }
}
```

## Central Gateway API

### 1. Generic Request Endpoint

**POST** `/api/central/request`

Generic endpoint for routing requests to appropriate agents.

**Request Body:**
```json
{
  "type": "research|code_generation|task_execution|development|system_status",
  "priority": "low|medium|high|urgent",
  "payload": {
    // Request-specific data
  },
  "metadata": {
    "source": "client-id",
    "timestamp": "2025-08-01T06:00:00.000Z"
  }
}
```

**Response:**
```json
{
  "id": "response-1234567890",
  "requestId": "request-1234567890",
  "status": "completed",
  "result": {
    // Agent-specific response
  },
  "metadata": {
    "processingTime": 1500,
    "agentId": "cogo-research-worker",
    "timestamp": "2025-08-01T06:00:01.500Z"
  }
}
```

### 2. Research Endpoint

**POST** `/api/central/research`

Submit research requests to the research worker agent.

**Request Body:**
```json
{
  "query": "TypeScript best practices for React development",
  "context": "Building a modern web application",
  "options": {
    "depth": "comprehensive",
    "sources": ["documentation", "examples", "tutorials"]
  }
}
```

**Response:**
```json
{
  "id": "response-1234567890",
  "requestId": "research-1234567890",
  "status": "completed",
  "result": {
    "status": "research_request_sent",
    "requestId": "research-1234567890"
  },
  "metadata": {
    "processingTime": 130,
    "agentId": "cogo-research-worker",
    "timestamp": "2025-08-01T06:00:00.130Z"
  }
}
```

### 3. Code Generation Endpoint

**POST** `/api/central/code-generation`

Request AI-powered code generation.

**Request Body:**
```json
{
  "description": "Create a React component for user authentication",
  "language": "typescript",
  "framework": "react",
  "requirements": [
    "Form validation",
    "Error handling",
    "Responsive design"
  ],
  "context": "Existing authentication system"
}
```

**Response:**
```json
{
  "id": "response-1234567890",
  "requestId": "codegen-1234567890",
  "status": "completed",
  "result": {
    "generatedCode": "// Generated TypeScript React component...",
    "explanation": "This component provides...",
    "confidence": 0.95,
    "dependencies": ["react", "typescript"]
  },
  "metadata": {
    "processingTime": 7459,
    "agentId": "cogo-codegen-service",
    "timestamp": "2025-08-01T06:00:07.459Z"
  }
}
```

### 4. Task Execution Endpoint

**POST** `/api/central/task-execution`

Submit complex tasks for execution planning and coordination.

**Request Body:**
```json
{
  "task": "Implement a complete user management system",
  "priority": "medium",
  "parameters": {
    "scope": "full-stack",
    "database": "postgresql",
    "framework": "express"
  },
  "environment": {
    "nodeVersion": "18.x",
    "packageManager": "npm"
  }
}
```

**Response:**
```json
{
  "id": "response-1234567890",
  "requestId": "task-1234567890",
  "status": "completed",
  "result": {
    "planId": "req_1234567890",
    "status": "planning",
    "message": "Task plan created and execution started"
  },
  "metadata": {
    "processingTime": 146,
    "agentId": "cogo-executor-agent",
    "timestamp": "2025-08-01T06:00:00.146Z"
  }
}
```

### 5. System Status Endpoint

**GET** `/api/central/status`

Get comprehensive system status and agent information.

**Response:**
```json
{
  "success": true,
  "data": {
    "timestamp": "2025-08-01T06:00:00.000Z",
    "agents": {
      "total": 7,
      "active": 0,
      "statuses": [
        {
          "id": "cogo-orchestrator-agent",
          "name": "COGO Intelligence Orchestrator Fast",
          "type": "orchestrator",
          "status": "idle",
          "lastActivity": "2025-08-01T06:00:00.000Z",
          "tasksCompleted": 0,
          "averageTime": 0,
          "successRate": 100,
          "performance": {
            "tasksCompleted": 0,
            "averageTime": 0,
            "successRate": 100
          }
        }
      ]
    },
    "requests": {
      "pending": 0,
      "history": 3,
      "recent": [
        {
          "id": "research-1234567890",
          "type": "research",
          "priority": "medium",
          "payload": {
            "query": "TypeScript best practices",
            "context": "",
            "options": {}
          },
          "metadata": {
            "timestamp": "2025-08-01T06:00:00.000Z",
            "source": "research-api"
          }
        }
      ]
    },
    "system": {
      "uptime": 77.7,
      "memory": {
        "rss": 98369536,
        "heapTotal": 587087872,
        "heapUsed": 550975608,
        "external": 9202249,
        "arrayBuffers": 5289629
      },
      "cpu": {
        "user": 13232354,
        "system": 1414295
      }
    }
  },
  "timestamp": "2025-08-01T06:00:00.000Z"
}
```

### 6. Health Check Endpoint

**GET** `/api/central/health`

Quick health check for the central gateway.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-08-01T06:00:00.000Z",
  "uptime": 165.14,
  "agents": {
    "total": 7,
    "active": 0
  },
  "requests": {
    "pending": 0
  }
}
```

## Agent Management API

### 1. List All Agents

**GET** `/api/agents`

Get detailed information about all registered agents.

**Response:**
```json
{
  "agents": [
    {
      "id": "cogo-orchestrator-agent",
      "name": "COGO Intelligence Orchestrator Fast",
      "type": "orchestrator",
      "status": "idle",
      "lastActivity": "2025-08-01T06:00:00.000Z",
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

### 2. Get Agent Status

**GET** `/api/agents/{agentId}`

Get detailed status of a specific agent.

**Response:**
```json
{
  "id": "cogo-research-worker",
  "name": "🔬 cogo-research-worker",
  "type": "research",
  "status": "idle",
  "currentTask": null,
  "lastActivity": "2025-08-01T06:00:00.000Z",
  "tasksCompleted": 0,
  "averageTime": 0,
  "successRate": 1,
  "performance": {
    "tasksCompleted": 0,
    "averageTime": 0,
    "successRate": 1
  },
  "metadata": {
    "created": "2025-08-01T06:00:00.000Z",
    "lastUpdate": "2025-08-01T06:00:00.000Z",
    "realtimeQueueConnected": true,
    "context7Integration": true,
    "researchHistory": 1,
    "capabilitiesValidated": true
  }
}
```

## Development Workflow API

### 1. Development Status

**GET** `/api/development/status`

Get development workflow status and capabilities.

**Response:**
```json
{
  "status": "ready",
  "capabilities": {
    "codeGeneration": true,
    "codeAnalysis": true,
    "testing": true,
    "deployment": false
  },
  "workflows": {
    "active": 0,
    "completed": 0,
    "failed": 0
  },
  "blueprints": {
    "total": 0,
    "templates": 5
  }
}
```

### 2. Execute Development Request

**POST** `/api/development/execute`

Execute a development workflow.

**Request Body:**
```json
{
  "title": "Create a REST API",
  "description": "Build a complete REST API with authentication",
  "requirements": [
    "User authentication",
    "CRUD operations",
    "Data validation"
  ],
  "priority": "medium",
  "metadata": {
    "framework": "express",
    "database": "postgresql"
  }
}
```

## Real-time Monitoring API

### 1. WebSocket Connection

**WebSocket** `/api/realtime/ws`

Real-time monitoring via WebSocket connection.

**Connection:**
```javascript
const socket = io('http://localhost:3000/api/realtime/ws');

socket.on('connect', () => {
  console.log('Connected to real-time monitoring');
});

socket.on('system_update', (data) => {
  console.log('System update:', data);
});
```

### 2. Real-time Status

**GET** `/api/realtime/status`

Get real-time system status.

**Response:**
```json
{
  "connections": 2,
  "events": {
    "total": 150,
    "recent": [
      {
        "type": "agent_status_update",
        "agentId": "cogo-research-worker",
        "timestamp": "2025-08-01T06:00:00.000Z",
        "data": {
          "status": "working",
          "currentTask": "research-1234567890"
        }
      }
    ]
  },
  "system": {
    "cpu": 15.2,
    "memory": 45.8,
    "uptime": 3600
  }
}
```

## Research API

### 1. Research Health

**GET** `/api/research/health`

Check research system health.

**Response:**
```json
{
  "status": "healthy",
  "capabilities": {
    "aiModels": ["claude", "gemini"],
    "context7Integration": true,
    "realTimeSearch": true
  },
  "stats": {
    "totalQueries": 25,
    "averageResponseTime": 2.3,
    "successRate": 0.96
  }
}
```

### 2. Direct Research Request

**POST** `/api/research`

Submit research request directly to research worker.

**Request Body:**
```json
{
  "query": "React hooks best practices",
  "context": "Modern React development",
  "options": {
    "depth": "comprehensive",
    "includeExamples": true
  }
}
```

## Error Handling

### Error Response Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": {
      "field": "query",
      "issue": "Query cannot be empty"
    }
  },
  "timestamp": "2025-08-01T06:00:00.000Z",
  "requestId": "request-1234567890"
}
```

### Common Error Codes
- `VALIDATION_ERROR`: Invalid request parameters
- `AGENT_NOT_FOUND`: Requested agent not available
- `TASK_FAILED`: Task execution failed
- `TIMEOUT_ERROR`: Request timed out
- `SYSTEM_ERROR`: Internal system error

## Rate Limiting

Currently, no rate limiting is implemented in development mode. For production deployment, rate limiting will be configured based on:
- Requests per minute per client
- Concurrent requests per client
- Priority-based rate limits

## WebSocket Events

### System Events
- `system_update`: System status updates
- `agent_status_update`: Agent status changes
- `task_progress`: Task execution progress
- `error_alert`: System error alerts

### Agent Events
- `agent_ready`: Agent becomes available
- `agent_busy`: Agent becomes busy
- `task_completed`: Task completion notification
- `task_failed`: Task failure notification

## SDK Examples

### JavaScript/TypeScript
```typescript
class COGOClient {
  private baseUrl: string;

  constructor(baseUrl: string = 'http://localhost:3000') {
    this.baseUrl = baseUrl;
  }

  async research(query: string, context?: string) {
    const response = await fetch(`${this.baseUrl}/api/central/research`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query, context }),
    });
    return response.json();
  }

  async generateCode(description: string, language: string) {
    const response = await fetch(`${this.baseUrl}/api/central/code-generation`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ description, language }),
    });
    return response.json();
  }

  async executeTask(task: string, priority: string = 'medium') {
    const response = await fetch(`${this.baseUrl}/api/central/task-execution`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ task, priority }),
    });
    return response.json();
  }
}
```

### Python
```python
import requests
import json

class COGOClient:
    def __init__(self, base_url="http://localhost:3000"):
        self.base_url = base_url

    def research(self, query, context=None):
        payload = {"query": query}
        if context:
            payload["context"] = context
        
        response = requests.post(
            f"{self.base_url}/api/central/research",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        return response.json()

    def generate_code(self, description, language):
        payload = {
            "description": description,
            "language": language
        }
        
        response = requests.post(
            f"{self.base_url}/api/central/code-generation",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        return response.json()

    def execute_task(self, task, priority="medium"):
        payload = {
            "task": task,
            "priority": priority
        }
        
        response = requests.post(
            f"{self.base_url}/api/central/task-execution",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        return response.json()
```

## Testing

### Health Check
```bash
curl http://localhost:3000/health
```

### Agent List
```bash
curl http://localhost:3000/api/agents
```

### Research Request
```bash
curl -X POST http://localhost:3000/api/central/research \
  -H "Content-Type: application/json" \
  -d '{"query": "TypeScript best practices"}'
```

### Code Generation
```bash
curl -X POST http://localhost:3000/api/central/code-generation \
  -H "Content-Type: application/json" \
  -d '{"description": "Create a simple React component", "language": "typescript"}'
```

---

**API Version**: 1.0.0  
**Last Updated**: 2025-08-01  
**Status**: ✅ Production Ready 