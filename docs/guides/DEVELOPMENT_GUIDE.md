# COGO Agent Core Development Guide

## Overview

This guide provides comprehensive information for developers working with the COGO Agent Core system. It covers setup, development practices, testing, and deployment procedures.

## Table of Contents

1. [Getting Started](#getting-started)
2. [System Architecture](#system-architecture)
3. [Development Environment](#development-environment)
4. [Agent Development](#agent-development)
5. [Testing](#testing)
6. [Deployment](#deployment)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

## Getting Started

### Prerequisites

- **Node.js**: 18.0.0 or higher
- **TypeScript**: 5.0.0 or higher
- **Git**: Latest version
- **Database**: Supabase account and Neo4j instance
- **AI Models**: API keys for Claude, Gemini, and OpenAI

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/cogo-xyz/cogo-agent-core.git
   cd cogo-agent-core
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment setup**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Database setup**
   ```bash
   # Run Supabase schema setup
   npm run setup:supabase
   
   # Run Neo4j schema setup
   npm run setup:neo4j
   ```

5. **Start development server**
   ```bash
   npm run dev
   ```

## System Architecture

### Core Components

```
COGO Agent Core
├── Central Gateway (cogo-system-gateway)
├── Orchestrator (cogo-orchestrator-agent)
├── Specialized Agents
│   ├── Research Worker (cogo-research-worker)
│   ├── Code Generation (cogo-codegen-service)
│   ├── Task Executor (cogo-executor-agent)
│   ├── Sandbox Worker (cogo-sandbox-worker)
│   ├── Architecture Gateway (cogo-arch-gateway)
│   └── Indexing Worker (cogo-indexing-worker)
├── Real-time Communication
├── Knowledge Management
└── Development Workflow
```

### Data Flow

```
Client Request → Central Gateway → Agent Selection → Task Execution → Response
```

### Communication Patterns

1. **Synchronous**: Direct API calls for simple requests
2. **Asynchronous**: Real-time queue for complex workflows
3. **WebSocket**: Real-time monitoring and updates

## Development Environment

### Project Structure

```
src/
├── agents/           # Agent implementations
├── core/            # Core system components
├── services/        # Shared services
├── routes/          # API routes
├── types/           # TypeScript type definitions
├── tests/           # Test files
├── workflow/        # Workflow engines
├── knowledge/       # Knowledge management
└── roles/           # Role package definitions
```

### Key Configuration Files

- `package.json`: Dependencies and scripts
- `tsconfig.json`: TypeScript configuration
- `.env`: Environment variables
- `src/index.ts`: Main server entry point

### Development Scripts

```bash
# Development
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server

# Testing
npm run test         # Run all tests
npm run test:watch   # Run tests in watch mode
npm run test:coverage # Run tests with coverage

# Database
npm run setup:supabase # Setup Supabase schema
npm run setup:neo4j   # Setup Neo4j schema
npm run verify:db     # Verify database schemas

# Utilities
npm run lint          # Run ESLint
npm run format        # Format code with Prettier
npm run docs          # Generate documentation
```

## Agent Development

### Creating a New Agent

1. **Create agent file**
   ```typescript
   // src/agents/my-new-agent.ts
   import { BaseAgent } from './BaseAgent';
   import { AgentStatus } from '../types';

   export class MyNewAgent extends BaseAgent {
     constructor() {
       super('my-new-agent', 'My New Agent', 'specialized');
     }

     async initialize(): Promise<void> {
       // Initialize agent-specific components
       console.log('✅ My New Agent initialized');
     }

     async executeTask(task: any): Promise<any> {
       // Implement task execution logic
       return { success: true, result: 'Task completed' };
     }

     getStatus(): AgentStatus {
       return {
         id: this.getId(),
         name: this.getName(),
         type: this.getType(),
         status: 'idle',
         lastActivity: new Date().toISOString()
       };
     }
   }
   ```

2. **Register agent in system**
   ```typescript
   // src/agents/cogo-system-gateway.ts
   import { MyNewAgent } from './my-new-agent';

   // In initializeAgents method
   this.agents.set('my-new-agent', new MyNewAgent());
   ```

3. **Add routing configuration**
   ```typescript
   // In setupRequestRouting method
   {
     type: 'my_task_type',
     targetAgent: 'my-new-agent',
     priority: 'medium',
     timeout: 30000
   }
   ```

### Agent Best Practices

1. **Inherit from BaseAgent**
   ```typescript
   export class MyAgent extends BaseAgent {
     // Always call super constructor
     constructor() {
       super('agent-id', 'Agent Name', 'agent-type');
     }
   }
   ```

2. **Implement required methods**
   ```typescript
   async initialize(): Promise<void> {
     // Initialize agent
   }

   async executeTask(task: any): Promise<any> {
     // Execute task
   }

   getStatus(): AgentStatus {
     // Return status
   }
   ```

3. **Handle errors gracefully**
   ```typescript
   async executeTask(task: any): Promise<any> {
     try {
       // Task execution logic
       return result;
     } catch (error) {
       console.error('Task execution failed:', error);
       throw error;
     }
   }
   ```

4. **Use real-time communication**
   ```typescript
   private async setupRealtimeSubscriptions(): Promise<void> {
     await this.realtimeQueue.subscribe('my-agent-channel', (message) => {
       this.handleRealtimeMessage(message);
     });
   }
   ```

## Testing

### Test Structure

```
src/tests/
├── unit/           # Unit tests
├── integration/    # Integration tests
├── e2e/           # End-to-end tests
└── fixtures/      # Test data
```

### Writing Tests

1. **Unit Tests**
   ```typescript
   // src/tests/unit/my-agent.test.ts
   import { MyAgent } from '../../agents/my-agent';

   describe('MyAgent', () => {
     let agent: MyAgent;

     beforeEach(() => {
       agent = new MyAgent();
     });

     it('should initialize correctly', async () => {
       await agent.initialize();
       expect(agent.getStatus().status).toBe('idle');
     });

     it('should execute tasks', async () => {
       const result = await agent.executeTask({ test: true });
       expect(result.success).toBe(true);
     });
   });
   ```

2. **Integration Tests**
   ```typescript
   // src/tests/integration/agent-communication.test.ts
   import { CogoSystemGateway } from '../../agents/cogo-system-gateway';

   describe('Agent Communication', () => {
     it('should route requests correctly', async () => {
       const gateway = CogoSystemGateway.getInstance();
       await gateway.initialize();

       const response = await gateway.processCentralRequest({
         type: 'research',
         priority: 'medium',
         payload: { query: 'test' }
       });

       expect(response.status).toBe('completed');
     });
   });
   ```

3. **API Tests**
   ```typescript
   // src/tests/e2e/api.test.ts
   import request from 'supertest';
   import app from '../../index';

   describe('API Endpoints', () => {
     it('should return agent list', async () => {
       const response = await request(app)
         .get('/api/agents')
         .expect(200);

       expect(response.body.agents).toBeDefined();
       expect(response.body.total).toBeGreaterThan(0);
     });
   });
   ```

### Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test -- src/tests/unit/my-agent.test.ts

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode
npm run test:watch
```

## Deployment

### Production Setup

1. **Environment Configuration**
   ```bash
   # Production environment variables
   NODE_ENV=production
   PORT=3000
   SUPABASE_URL=your-supabase-url
   SUPABASE_KEY=your-supabase-key
   NEO4J_URI=your-neo4j-uri
   NEO4J_PASSWORD=your-neo4j-password
   ```

2. **Build Application**
   ```bash
   npm run build
   ```

3. **Start Production Server**
   ```bash
   npm start
   ```

### Docker Deployment

1. **Dockerfile**
   ```dockerfile
   FROM node:18-alpine

   WORKDIR /app

   COPY package*.json ./
   RUN npm ci --only=production

   COPY dist ./dist
   COPY .env ./

   EXPOSE 3000

   CMD ["npm", "start"]
   ```

2. **Docker Compose**
   ```yaml
   version: '3.8'
   services:
     cogo-agent-core:
       build: .
       ports:
         - "3000:3000"
       environment:
         - NODE_ENV=production
       depends_on:
         - redis
     
     redis:
       image: redis:alpine
       ports:
         - "6379:6379"
   ```

### Monitoring

1. **Health Checks**
   ```bash
   curl http://localhost:3000/health
   curl http://localhost:3000/api/central/health
   ```

2. **System Metrics**
   ```bash
   curl http://localhost:3000/api/central/status
   ```

3. **Agent Status**
   ```bash
   curl http://localhost:3000/api/agents
   ```

## Troubleshooting

### Common Issues

1. **Agent Not Found**
   ```
   Error: Agent not found: agent-id
   ```
   **Solution**: Check agent registration in `cogo-system-gateway.ts`

2. **Database Connection Issues**
   ```
   Error: Failed to connect to database
   ```
   **Solution**: Verify database credentials and network connectivity

3. **Real-time Communication Errors**
   ```
   Error: Supabase real-time connection failed
   ```
   **Solution**: Check Supabase configuration and API keys

4. **Type Errors**
   ```
   Error: Type 'X' is not assignable to type 'Y'
   ```
   **Solution**: Update TypeScript types or fix type mismatches

### Debug Mode

Enable debug logging:
```bash
DEBUG=* npm run dev
```

### Log Analysis

```bash
# View application logs
tail -f logs/app.log

# View error logs
tail -f logs/error.log

# View real-time logs
tail -f logs/realtime.log
```

## Best Practices

### Code Organization

1. **Follow TypeScript conventions**
   ```typescript
   // Use interfaces for type definitions
   interface TaskRequest {
     id: string;
     type: string;
     payload: any;
   }

   // Use enums for constants
   enum AgentStatus {
     IDLE = 'idle',
     WORKING = 'working',
     ERROR = 'error'
   }
   ```

2. **Implement proper error handling**
   ```typescript
   async executeTask(task: any): Promise<any> {
     try {
       // Task execution
       return result;
     } catch (error) {
       console.error('Task execution failed:', error);
       throw new Error(`Task failed: ${error.message}`);
     }
   }
   ```

3. **Use async/await consistently**
   ```typescript
   // Good
   async function processData() {
     const data = await fetchData();
     const result = await processData(data);
     return result;
   }

   // Avoid
   function processData() {
     return fetchData().then(data => {
       return processData(data);
     });
   }
   ```

### Performance Optimization

1. **Implement caching**
   ```typescript
   private cache = new Map<string, any>();

   async getCachedData(key: string): Promise<any> {
     if (this.cache.has(key)) {
       return this.cache.get(key);
     }
     
     const data = await fetchData(key);
     this.cache.set(key, data);
     return data;
   }
   ```

2. **Use connection pooling**
   ```typescript
   // Database connections
   const pool = new Pool({
     max: 20,
     idleTimeoutMillis: 30000,
     connectionTimeoutMillis: 2000,
   });
   ```

3. **Implement request batching**
   ```typescript
   async batchProcess(requests: any[]): Promise<any[]> {
     const batchSize = 10;
     const results = [];
     
     for (let i = 0; i < requests.length; i += batchSize) {
       const batch = requests.slice(i, i + batchSize);
       const batchResults = await Promise.all(
         batch.map(req => this.processRequest(req))
       );
       results.push(...batchResults);
     }
     
     return results;
   }
   ```

### Security

1. **Validate all inputs**
   ```typescript
   function validateRequest(request: any): boolean {
     if (!request.id || typeof request.id !== 'string') {
       throw new Error('Invalid request ID');
     }
     
     if (!request.type || !['research', 'code_generation'].includes(request.type)) {
       throw new Error('Invalid request type');
     }
     
     return true;
   }
   ```

2. **Sanitize data**
   ```typescript
   function sanitizeInput(input: string): string {
     return input.replace(/[<>]/g, '');
   }
   ```

3. **Implement rate limiting**
   ```typescript
   const rateLimit = require('express-rate-limit');

   const limiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 100 // limit each IP to 100 requests per windowMs
   });

   app.use('/api/', limiter);
   ```

## Contributing

### Development Workflow

1. **Create feature branch**
   ```bash
   git checkout -b feature/new-agent
   ```

2. **Make changes**
   - Follow coding standards
   - Add tests for new functionality
   - Update documentation

3. **Run tests**
   ```bash
   npm test
   npm run lint
   ```

4. **Submit pull request**
   - Provide clear description
   - Include test results
   - Update relevant documentation

### Code Review Checklist

- [ ] Code follows TypeScript conventions
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] Error handling is implemented
- [ ] Performance considerations are addressed
- [ ] Security measures are in place

---

**Document Version**: 1.0.0  
**Last Updated**: 2025-08-01  
**Status**: ✅ Complete 