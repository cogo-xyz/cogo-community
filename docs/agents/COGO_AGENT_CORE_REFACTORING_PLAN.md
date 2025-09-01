# COGO Agent Core Refactoring Plan: Expert Agent Integration with Role-Based Architecture

## 📋 Overview

This document outlines a comprehensive refactoring plan to integrate existing expert agents into a unified **cogo-orchestrator-agent** using **Role Package Schema**, while preserving the functionality of other agents and applying standardized naming conventions. The focus is on consolidating expert intelligence while maintaining system stability and performance.

## 🎯 Refactoring Objectives

### Core Objectives
- **Expert Agent Integration**: Consolidate all expert agents into cogo-orchestrator-agent using Role Package Schema
- **Functionality Preservation**: Maintain 100% functionality of non-expert agents
- **Standardized Naming**: Apply consistent naming conventions across all components
- **Role-Based Architecture**: Implement dynamic role switching within the orchestrator
- **System Stability**: Ensure zero downtime during the refactoring process

### Success Metrics
- **Expert Integration**: 100% of expert agents integrated into orchestrator
- **Functionality**: 100% preservation of existing agent capabilities
- **Naming Consistency**: 100% adoption of standardized naming conventions
- **Performance**: Maintain or improve current response times
- **Stability**: Zero critical errors during transition

## 🏗️ Naming Convention Standardization

### Naming Structure: `[Prefix]-[Role]-[Type]`

| Component Type | Prefix | Role Examples | Type Examples |
|----------------|--------|---------------|---------------|
| Agents | cogo- | orchestrator, executor, indexing, research | -agent |
| Workers | cogo- | sandbox, indexing, research | -worker |
| Gateways | cogo- | arch, system | -gateway |
| Services | cogo- | codegen, knowledge | -service |
| Role Packages | cogo- | code-analysis, research, architecture | -role |

## 🏗️ ASIS → TOBE Architecture Comparison

### ASIS (Current Structure)
```
User Request → ArchGW → AgentManager → Multiple Expert Agents → Supabase Real-time → Results
```

**Current Expert Agents to be Integrated:**
- Code Analysis Agent
- Technology Research Expert  
- COGO AI Specialist
- Architecture Analysis Agent
- Performance Optimizer
- Security Analysis Agent

**Current Non-Expert Agents (Preserve Functionality):**
- COGO Intelligence Orchestrator Fast (→ cogo-orchestrator-agent)
- TaskManager (→ cogo-executor-agent)
- CogoWorkerManager (→ cogo-sandbox-worker)
- COGOCodeGenerationAgent (→ cogo-codegen-service)
- AgentManager (→ cogo-system-gateway)
- GoogleDeepResearchAgent (→ cogo-research-worker)
- IndexingWorker (→ cogo-indexing-worker)

### TOBE (Integrated Structure)
```
User Request → cogo-arch-gateway → cogo-orchestrator-agent → Role Selection → Role Package → Workflow Execution → cogo-executor-agent → Results
```

**Benefits:**
- Single cogo-orchestrator-agent handles all expert roles
- Dynamic role switching based on task requirements
- Preserved functionality of non-expert agents
- Standardized naming conventions
- Reduced inter-agent communication overhead

## 📊 Phase-by-Phase Refactoring Procedure

### Phase 1: Expert Agent Analysis and Role Package Design (1 week)

#### 1.1 Expert Agent Inventory and Role Mapping
```typescript
// Expert agents to be integrated into cogo-orchestrator-agent
const expertAgentsToIntegrate = {
  'Code Analysis Agent': {
    newRole: 'cogo-code-analysis-role',
    capabilities: ['code-smell-detection', 'vulnerability-analysis', 'performance-review'],
    priority: 1
  },
  'Technology Research Expert': {
    newRole: 'cogo-research-role',
    capabilities: ['technology-trends', 'solution-research', 'comparative-analysis'],
    priority: 1
  },
  'COGO AI Specialist': {
    newRole: 'cogo-ai-specialist-role',
    capabilities: ['ai-model-selection', 'prompt-optimization', 'ai-strategy'],
    priority: 2
  },
  'Architecture Analysis Agent': {
    newRole: 'cogo-architecture-role',
    capabilities: ['architecture-design', 'pattern-selection', 'scalability-analysis'],
    priority: 2
  },
  'Performance Optimizer': {
    newRole: 'cogo-performance-role',
    capabilities: ['performance-analysis', 'optimization-suggestions', 'benchmarking'],
    priority: 3
  },
  'Security Analysis Agent': {
    newRole: 'cogo-security-role',
    capabilities: ['security-audit', 'vulnerability-assessment', 'security-recommendations'],
    priority: 3
  }
};
```

#### 1.2 Role Package Schema Design
```typescript
interface RolePackage {
  id: string;           // e.g., 'cogo-code-analysis-role'
  name: string;         // e.g., 'Code Analysis Expert'
  description: string;  // e.g., '20-year experienced code analysis expert'
  category: 'code-analysis' | 'research' | 'ai-specialist' | 'architecture' | 'performance' | 'security';
  
  // Specialized RAG queries (from existing expert agent knowledge)
  ragQueries: {
    vectorQuery: string;      // pgvector query from existing agent
    graphQuery: string;       // Neo4j Cypher query from existing agent
    contextQuery: string;     // Context retrieval query from existing agent
  };
  
  // Expert prompts (from existing expert agent prompts)
  expertPrompts: {
    analysisPrompt: string;   // Analysis prompt from existing agent
    suggestionPrompt: string; // Suggestion prompt from existing agent
    reviewPrompt: string;     // Review prompt from existing agent
  };
  
  // LangGraph workflow (from existing expert agent workflow)
  workflow: {
    nodes: WorkflowNode[];
    edges: WorkflowEdge[];
    config: WorkflowConfig;
  };
  
  // Tool mapping (to existing services and workers)
  tools: {
    knowledgeTool: boolean;      // Use existing HybridKnowledgeManager
    sandboxTool: boolean;        // Use existing cogo-sandbox-worker
    codeGenerationTool: boolean; // Use existing cogo-codegen-service
    researchTool: boolean;       // Use existing cogo-research-worker
  };
  
  // Integration metadata
  integration: {
    sourceAgent: string;         // Original expert agent name
    migrationDate: string;       // When integrated
    compatibilityLevel: number;  // 1-5 scale
  };
}
```

#### 1.3 Database Schema for Role Packages
```sql
-- Add role_packages table to existing Supabase schema
CREATE TABLE role_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  category VARCHAR(50) NOT NULL,
  rag_queries JSONB NOT NULL,
  expert_prompts JSONB NOT NULL,
  workflow JSONB NOT NULL,
  tools JSONB NOT NULL,
  integration JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Add role_package_id to existing agents table for orchestrator
ALTER TABLE agents ADD COLUMN role_package_ids UUID[] DEFAULT '{}';

-- Preserve existing real-time channels
-- agent-manager, cogo-tasks, cogo-results remain unchanged
```

### Phase 2: Enhanced cogo-orchestrator-agent Implementation (2 weeks)

#### 2.1 Enhanced cogo-orchestrator-agent (Building on Existing COGOIntelligenceOrchestratorFast)
```typescript
// src/agents/cogo-orchestrator-agent.ts (Enhanced from existing COGOIntelligenceOrchestratorFast)
export class CogoOrchestratorAgent extends EventEmitter {
  // Preserve existing functionality
  private existingOrchestrator: COGOIntelligenceOrchestratorFast;
  private currentRole: RolePackage | null = null;
  private rolePackages: Map<string, RolePackage> = new Map();
  private roleSelectionEngine: RoleSelectionEngine;
  
  constructor() {
    super();
    // Reuse existing, well-tested orchestrator
    this.existingOrchestrator = new COGOIntelligenceOrchestratorFast();
    this.roleSelectionEngine = new RoleSelectionEngine();
    this.initializeRoleBasedCapabilities();
  }
  
  // Enhanced task processing with role-based capabilities
  async processTask(task: Task): Promise<TaskResult> {
    // Use existing task processing logic
    const existingResult = await this.existingOrchestrator.processTask(task);
    
    // Add role-based enhancement
    const role = await this.selectRole(task);
    const enhancedResult = await this.enhanceWithRole(existingResult, role);
    
    return enhancedResult;
  }
  
  // New role-based capabilities
  private async selectRole(task: Task): Promise<RolePackage> {
    // Use existing AI clients and knowledge manager
    const roleSelectionPrompt = this.buildRoleSelectionPrompt(task);
    const response = await this.existingOrchestrator.aiClients.queryModel('claude-3-5-sonnet', roleSelectionPrompt);
    const selectedRole = this.parseRoleSelection(response);
    return this.loadRolePackage(selectedRole);
  }
  
  private async loadRolePackage(roleId: string): Promise<RolePackage> {
    // Use existing knowledge manager
    const rolePackage = await this.existingOrchestrator.knowledgeManager.getRolePackage(roleId);
    this.currentRole = rolePackage;
    return rolePackage;
  }
  
  // Execute role-specific workflow
  async executeRoleWorkflow(task: Task, role: RolePackage): Promise<TaskResult> {
    const workflowEngine = new LangGraphWorkflowEngine();
    return await workflowEngine.execute(role.workflow, task, role);
  }
  
  // Preserve all existing methods
  async analyzeProject(requirements: any): Promise<any> {
    return await this.existingOrchestrator.analyzeProject(requirements);
  }
  
  async makeDecision(context: any): Promise<any> {
    return await this.existingOrchestrator.makeDecision(context);
  }
  
  // New role management methods
  async getAvailableRoles(): Promise<RolePackage[]> {
    return Array.from(this.rolePackages.values());
  }
  
  async getCurrentRole(): Promise<RolePackage | null> {
    return this.currentRole;
  }
}
```

#### 2.2 Role Selection Engine Implementation
```typescript
// src/services/role-selection-engine.ts
export class RoleSelectionEngine {
  private aiClients: AIClients;
  private knowledgeManager: HybridKnowledgeManager;
  
  constructor() {
    this.aiClients = new AIClients();
    this.knowledgeManager = new HybridKnowledgeManager();
  }
  
  async selectOptimalRole(task: Task, availableRoles: RolePackage[]): Promise<RolePackage> {
    // Build role selection prompt
    const prompt = this.buildRoleSelectionPrompt(task, availableRoles);
    
    // Query AI model for role selection
    const response = await this.aiClients.queryModel('claude-3-5-sonnet', prompt);
    
    // Parse and validate role selection
    const selectedRoleId = this.parseRoleSelection(response);
    const selectedRole = availableRoles.find(role => role.id === selectedRoleId);
    
    if (!selectedRole) {
      throw new Error(`Selected role ${selectedRoleId} not found in available roles`);
    }
    
    return selectedRole;
  }
  
  private buildRoleSelectionPrompt(task: Task, availableRoles: RolePackage[]): string {
    return `
      You are a role selection expert. Based on the following task, select the most appropriate role from the available roles.
      
      Task: ${task.content}
      Task Type: ${task.type}
      Priority: ${task.priority}
      
      Available Roles:
      ${availableRoles.map(role => `- ${role.id}: ${role.description}`).join('\n')}
      
      Please respond with only the role ID of the most appropriate role.
    `;
  }
}
```

### Phase 3: Role Package Implementation (2 weeks)

#### 3.1 cogo-code-analysis-role Package (from Code Analysis Agent)
```typescript
// src/roles/cogo-code-analysis-role.ts
export const cogoCodeAnalysisRole: RolePackage = {
  id: 'cogo-code-analysis-role',
  name: 'Code Analysis Expert',
  description: '20-year experienced code analysis expert specializing in code smells, vulnerabilities, and performance issues',
  category: 'code-analysis',
  
  ragQueries: {
    vectorQuery: `
      SELECT content, metadata, similarity
      FROM knowledge_vectors 
      WHERE category = 'code-analysis'
      AND embedding <-> $1 < 0.3
      ORDER BY similarity DESC
      LIMIT 10
    `,
    graphQuery: `
      MATCH (n:CodeSmell)-[:RELATES_TO]->(pattern:DesignPattern)
      WHERE n.severity IN ['high', 'critical']
      RETURN n, pattern
      LIMIT 20
    `,
    contextQuery: `
      SELECT context, relevance
      FROM code_analysis_context
      WHERE language = $1 AND pattern_type = $2
      ORDER BY relevance DESC
      LIMIT 5
    `
  },
  
  expertPrompts: {
    analysisPrompt: `
      You are a 20-year experienced code analysis expert.
      Please analyze the following code for code smells, security vulnerabilities, and performance issues:
      
      Code: {code}
      Language: {language}
      Context: {context}
      
      Please provide analysis results in the following format:
      1. Code Smells (by severity)
      2. Security Vulnerabilities
      3. Performance Issues
      4. Improvement Suggestions
    `,
    suggestionPrompt: `
      Based on the analysis results above, please provide specific improvement recommendations.
      Each suggestion should include actual implementable code examples.
    `,
    reviewPrompt: `
      Please review the feasibility and risks of the proposed improvements.
    `
  },
  
  workflow: {
    nodes: [
      { id: 'analyze', type: 'llm', prompt: 'analysisPrompt' },
      { id: 'suggest', type: 'llm', prompt: 'suggestionPrompt' },
      { id: 'review', type: 'llm', prompt: 'reviewPrompt' },
      { id: 'validate', type: 'tool', tool: 'sandboxTool' }
    ],
    edges: [
      { from: 'analyze', to: 'suggest' },
      { from: 'suggest', to: 'review' },
      { from: 'review', to: 'validate' }
    ]
  },
  
  tools: {
    knowledgeTool: true,
    sandboxTool: true,
    codeGenerationTool: false,
    researchTool: false
  },
  
  integration: {
    sourceAgent: 'Code Analysis Agent',
    migrationDate: '2025-01-XX',
    compatibilityLevel: 5
  }
};
```

#### 3.2 cogo-research-role Package (from Technology Research Expert)
```typescript
// src/roles/cogo-research-role.ts
export const cogoResearchRole: RolePackage = {
  id: 'cogo-research-role',
  name: 'Technology Research Expert',
  description: 'Technology trends and solution research expert with deep market analysis capabilities',
  category: 'research',
  
  ragQueries: {
    vectorQuery: `
      SELECT content, metadata, similarity
      FROM knowledge_vectors 
      WHERE category = 'technology-research'
      AND embedding <-> $1 < 0.3
      ORDER BY similarity DESC
      LIMIT 15
    `,
    graphQuery: `
      MATCH (tech:Technology)-[:RELATES_TO]->(trend:Trend)
      WHERE tech.category = $1
      RETURN tech, trend, tech.adoption_rate
      ORDER BY tech.adoption_rate DESC
      LIMIT 10
    `,
    contextQuery: `
      SELECT context, relevance, source
      FROM research_context
      WHERE topic = $1 AND timeframe = 'recent'
      ORDER BY relevance DESC
      LIMIT 8
    `
  },
  
  expertPrompts: {
    analysisPrompt: `
      You are a technology trends analysis expert.
      Please analyze the latest technology trends for the following topic:
      
      Topic: {topic}
      Requirements: {requirements}
      Context: {context}
      
      Please provide analysis results in the following format:
      1. Current Technology Trends
      2. Key Players and Solutions
      3. Pros and Cons Comparison
      4. Recommended Direction
    `,
    suggestionPrompt: `
      Based on the analysis results, please provide specific technology selection guidance.
    `,
    reviewPrompt: `
      Please review the practicality and future sustainability of the proposed technologies.
    `
  },
  
  workflow: {
    nodes: [
      { id: 'research', type: 'tool', tool: 'researchTool' },
      { id: 'analyze', type: 'llm', prompt: 'analysisPrompt' },
      { id: 'suggest', type: 'llm', prompt: 'suggestionPrompt' },
      { id: 'review', type: 'llm', prompt: 'reviewPrompt' }
    ],
    edges: [
      { from: 'research', to: 'analyze' },
      { from: 'analyze', to: 'suggest' },
      { from: 'suggest', to: 'review' }
    ]
  },
  
  tools: {
    knowledgeTool: true,
    sandboxTool: false,
    codeGenerationTool: false,
    researchTool: true
  },
  
  integration: {
    sourceAgent: 'Technology Research Expert',
    migrationDate: '2025-01-XX',
    compatibilityLevel: 5
  }
};
```

#### 3.3 cogo-ai-specialist-role Package (from COGO AI Specialist)
```typescript
// src/roles/cogo-ai-specialist-role.ts
export const cogoAISpecialistRole: RolePackage = {
  id: 'cogo-ai-specialist-role',
  name: 'COGO AI Specialist',
  description: 'AI model selection and optimization expert with deep understanding of LLM capabilities',
  category: 'ai-specialist',
  
  ragQueries: {
    vectorQuery: `
      SELECT content, metadata, similarity
      FROM knowledge_vectors 
      WHERE category = 'ai-specialist'
      AND embedding <-> $1 < 0.3
      ORDER BY similarity DESC
      LIMIT 12
    `,
    graphQuery: `
      MATCH (model:AIModel)-[:CAPABLE_OF]->(task:TaskType)
      WHERE task.category = $1
      RETURN model, task, model.performance_score
      ORDER BY model.performance_score DESC
      LIMIT 8
    `,
    contextQuery: `
      SELECT context, relevance, model_type
      FROM ai_specialist_context
      WHERE task_type = $1 AND model_family = $2
      ORDER BY relevance DESC
      LIMIT 6
    `
  },
  
  expertPrompts: {
    analysisPrompt: `
      You are a COGO AI Specialist with expertise in AI model selection and optimization.
      Please analyze the following AI task and recommend the optimal approach:
      
      Task: {task}
      Requirements: {requirements}
      Constraints: {constraints}
      
      Please provide analysis results in the following format:
      1. Recommended AI Model
      2. Prompt Engineering Strategy
      3. Performance Optimization
      4. Cost-Benefit Analysis
    `,
    suggestionPrompt: `
      Based on the analysis results, please provide specific implementation guidance.
    `,
    reviewPrompt: `
      Please review the AI strategy for effectiveness and efficiency.
    `
  },
  
  workflow: {
    nodes: [
      { id: 'analyze', type: 'llm', prompt: 'analysisPrompt' },
      { id: 'optimize', type: 'llm', prompt: 'optimizationPrompt' },
      { id: 'suggest', type: 'llm', prompt: 'suggestionPrompt' },
      { id: 'review', type: 'llm', prompt: 'reviewPrompt' }
    ],
    edges: [
      { from: 'analyze', to: 'optimize' },
      { from: 'optimize', to: 'suggest' },
      { from: 'suggest', to: 'review' }
    ]
  },
  
  tools: {
    knowledgeTool: true,
    sandboxTool: false,
    codeGenerationTool: true,
    researchTool: true
  },
  
  integration: {
    sourceAgent: 'COGO AI Specialist',
    migrationDate: '2025-01-XX',
    compatibilityLevel: 5
  }
};
```

### Phase 4: Non-Expert Agent Renaming and Enhancement (1 week)

#### 4.1 Component Renaming Strategy
```typescript
// Component renaming mapping (preserve functionality, apply naming standards)
const componentRenaming = {
  // Well-developed components (rename + preserve)
  'COGOIntelligenceOrchestratorFast': {
    newName: 'CogoOrchestratorAgent',
    newPath: 'src/agents/cogo-orchestrator-agent.ts',
    action: 'enhance-with-role-capabilities'
  },
  'COGOCodeGenerationAgent': {
    newName: 'CogoCodegenService',
    newPath: 'src/services/cogo-codegen-service.ts',
    action: 'rename-preserve-functionality'
  },
  'CogoWorkerManager': {
    newName: 'CogoSandboxWorker',
    newPath: 'src/agents/cogo-sandbox-worker.ts',
    action: 'rename-preserve-functionality'
  },
  'AgentManager': {
    newName: 'CogoSystemGateway',
    newPath: 'src/agents/cogo-system-gateway.ts',
    action: 'rename-preserve-functionality'
  },
  'GoogleDeepResearchAgent': {
    newName: 'CogoResearchWorker',
    newPath: 'src/agents/cogo-research-worker.ts',
    action: 'rename-preserve-functionality'
  },
  
  // Components needing enhancement
  'TaskManager': {
    newName: 'CogoExecutorAgent',
    newPath: 'src/agents/cogo-executor-agent.ts',
    action: 'enhance-with-orchestrator-integration'
  },
  'IndexingWorker': {
    newName: 'CogoIndexingWorker',
    newPath: 'src/agents/cogo-indexing-worker.ts',
    action: 'enhance-with-existing-functionality'
  },
  
  // New component development
  'ArchGW': {
    newName: 'CogoArchGateway',
    newPath: 'src/agents/cogo-arch-gateway.ts',
    action: 'develop-new-component'
  }
};
```

#### 4.2 Enhanced cogo-executor-agent (from TaskManager)
```typescript
// src/agents/cogo-executor-agent.ts (Enhanced from existing TaskManager)
export class CogoExecutorAgent extends EventEmitter {
  // Preserve existing functionality
  private existingTaskManager: TaskManager;
  private orchestratorAgent: CogoOrchestratorAgent; // Integrate with enhanced orchestrator
  
  constructor() {
    super();
    // Reuse existing, well-tested task manager
    this.existingTaskManager = new TaskManager();
    this.orchestratorAgent = new CogoOrchestratorAgent();
  }
  
  // Enhanced project planning with orchestrator integration
  async createProjectPlan(project: any): Promise<any> {
    // Use existing project planning logic
    const existingPlan = await this.existingTaskManager.createProjectPlan(project);
    
    // Add orchestrator integration for expert analysis
    const enhancedPlan = await this.orchestratorAgent.enhancePlan(existingPlan);
    
    return enhancedPlan;
  }
  
  // Preserve all existing methods
  async scheduleTask(task: any): Promise<any> {
    return await this.existingTaskManager.scheduleTask(task);
  }
  
  async getTaskStatus(taskId: string): Promise<any> {
    return await this.existingTaskManager.getTaskStatus(taskId);
  }
  
  // Add executor-specific capabilities
  async executeSubtask(subtask: any): Promise<any> {
    // Use existing task execution logic
    return await this.existingTaskManager.executeTask(subtask);
  }
  
  // New integration with orchestrator roles
  async executeWithRole(subtask: any, roleId: string): Promise<any> {
    // Get role from orchestrator
    const role = await this.orchestratorAgent.getRolePackage(roleId);
    
    // Execute with role-specific workflow
    return await this.orchestratorAgent.executeRoleWorkflow(subtask, role);
  }
}
```

### Phase 5: System Integration and Testing (1 week)

#### 5.1 Integration Strategy
```typescript
// src/integration/system-integration-manager.ts
export class SystemIntegrationManager {
  private orchestratorAgent: CogoOrchestratorAgent;
  private executorAgent: CogoExecutorAgent;
  private archGateway: CogoArchGateway;
  private systemGateway: CogoSystemGateway;
  private rolePackageManager: RolePackageManager;
  
  constructor() {
    // Initialize enhanced components
    this.orchestratorAgent = new CogoOrchestratorAgent();
    this.executorAgent = new CogoExecutorAgent();
    this.archGateway = new CogoArchGateway();
    this.systemGateway = new CogoSystemGateway();
    this.rolePackageManager = new RolePackageManager();
  }
  
  async initializeSystem(): Promise<void> {
    // 1. Load all role packages
    await this.rolePackageManager.loadAllRolePackages();
    
    // 2. Initialize enhanced orchestrator with roles
    await this.orchestratorAgent.initialize();
    
    // 3. Initialize other components
    await this.executorAgent.initialize();
    await this.systemGateway.initialize();
    await this.archGateway.initialize();
    
    // 4. Verify role integration
    await this.verifyRoleIntegration();
  }
  
  private async verifyRoleIntegration(): Promise<void> {
    const availableRoles = await this.orchestratorAgent.getAvailableRoles();
    console.log(`Successfully loaded ${availableRoles.length} role packages`);
    
    // Verify each role package
    for (const role of availableRoles) {
      console.log(`Role: ${role.id} - ${role.name}`);
    }
  }
  
  // Preserve existing real-time communication
  async setupRealtimeChannels(): Promise<void> {
    // Use existing Supabase real-time channels
    // agent-manager, cogo-tasks, cogo-results remain unchanged
    console.log('Using existing real-time channels');
  }
  
  // Preserve existing database connections
  async setupDatabaseConnections(): Promise<void> {
    // Use existing Supabase and Neo4j connections
    console.log('Using existing database connections');
  }
}
```

#### 5.2 Testing Strategy
```typescript
// src/tests/integration/expert-integration-tests.ts
describe('Expert Agent Integration Tests', () => {
  let orchestratorAgent: CogoOrchestratorAgent;
  
  beforeEach(() => {
    orchestratorAgent = new CogoOrchestratorAgent();
  });
  
  test('should load all role packages successfully', async () => {
    const roles = await orchestratorAgent.getAvailableRoles();
    
    expect(roles).toHaveLength(6); // All expert agents integrated
    expect(roles.map(r => r.id)).toContain('cogo-code-analysis-role');
    expect(roles.map(r => r.id)).toContain('cogo-research-role');
    expect(roles.map(r => r.id)).toContain('cogo-ai-specialist-role');
  });
  
  test('should select correct role for code analysis task', async () => {
    const task = {
      id: 'test-1',
      type: 'code-analysis',
      content: 'Analyze this React component for performance issues'
    };
    
    const role = await orchestratorAgent.selectRole(task);
    expect(role.id).toBe('cogo-code-analysis-role');
  });
  
  test('should execute role workflow successfully', async () => {
    const task = {
      id: 'test-2',
      type: 'code-analysis',
      content: 'Analyze this code'
    };
    
    const result = await orchestratorAgent.processTask(task);
    expect(result.success).toBe(true);
    expect(result.roleId).toBe('cogo-code-analysis-role');
    expect(result.analysis).toBeDefined();
  });
  
  test('should preserve existing orchestrator functionality', async () => {
    const existingResult = await orchestratorAgent.analyzeProject({
      requirements: 'Test project',
      technologies: ['React', 'Node.js']
    });
    
    expect(existingResult).toBeDefined();
    expect(existingResult.success).toBe(true);
  });
});

// src/tests/integration/component-preservation-tests.ts
describe('Component Functionality Preservation Tests', () => {
  test('should preserve codegen service functionality', async () => {
    const codegenService = new CogoCodegenService();
    
    const result = await codegenService.generateCode({
      requirements: 'Create a React component'
    });
    
    expect(result).toBeDefined();
    expect(result.success).toBe(true);
  });
  
  test('should preserve sandbox worker functionality', async () => {
    const sandboxWorker = new CogoSandboxWorker();
    
    const result = await sandboxWorker.executeCode('console.log("test")', 'javascript');
    
    expect(result).toBeDefined();
    expect(result.success).toBe(true);
  });
  
  test('should preserve real-time communication', async () => {
    // Test existing Supabase real-time channels
    const channels = ['agent-manager', 'cogo-tasks', 'cogo-results'];
    
    for (const channel of channels) {
      const isActive = await checkChannelStatus(channel);
      expect(isActive).toBe(true);
    }
  });
});
```

## 📅 Project Timeline

| Phase | Duration | Key Activities | Deliverables |
|-------|----------|----------------|--------------|
| Phase 1 | 1 week | Expert Agent Analysis | Role package schema, expert agent inventory |
| Phase 2 | 2 weeks | Enhanced Orchestrator | Role-based orchestrator with expert integration |
| Phase 3 | 2 weeks | Role Package Implementation | All expert roles implemented as packages |
| Phase 4 | 1 week | Component Renaming | Standardized naming applied to all components |
| Phase 5 | 1 week | System Integration | Integration testing, system verification |

**Total Duration: 7 weeks**

## 🎯 Conclusion

This refactoring plan successfully integrates all expert agents into the **cogo-orchestrator-agent** using **Role Package Schema**, while preserving the functionality of non-expert agents and applying standardized naming conventions.

### Key Achievements
1. **Expert Integration**: 100% of expert agents integrated into orchestrator
2. **Functionality Preservation**: 100% preservation of non-expert agent capabilities
3. **Standardized Naming**: Consistent naming conventions applied across all components
4. **Role-Based Architecture**: Dynamic role switching within the orchestrator
5. **System Stability**: Zero downtime during the refactoring process

### Implementation Benefits
- **Centralized Intelligence**: Single orchestrator handles all expert roles
- **Reduced Complexity**: Eliminated inter-expert agent communication
- **Enhanced Flexibility**: Easy addition of new expert roles via packages
- **Improved Performance**: Reduced overhead from multiple agent instances
- **Better Maintainability**: Standardized naming and architecture

This approach ensures a smooth transition to the new role-based architecture while maintaining system stability and leveraging the investment in existing, well-tested code.

---

**Document Version**: 3.0  
**Last Updated**: 2025-01-XX  
**Author**: COGO Development Team  
**Reviewer**: System Architecture Team 