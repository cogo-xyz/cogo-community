# Fireworks.ai Model Integration Development Plan

## Overview

This document outlines the comprehensive plan for integrating Fireworks.ai's powerful `qwen3-coder-480b-a35b-instruct` model into the COGO Agent Core system. The integration will enable dynamic LLM selection through real-time messaging from the CIO (Chief Intelligence Officer) agent, allowing the system to choose the most appropriate model for specific code generation and analysis tasks.

## Current State Analysis

### Existing LLM Configuration
- **Primary Model**: Claude 3.5 Sonnet (currently hardcoded)
- **Secondary Models**: Gemini, OpenAI (available but not dynamically selectable)
- **API Key**: `T3x39SNew5S@y27` (Fireworks.ai)

### System Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CIO Agent     │    │  Task Manager   │    │ CodeGen Service │
│ (Orchestrator)  │───►│ (Executor)      │───►│ (CCGA)          │
│                 │    │                 │    │                 │
│ • Model Select  │    │ • Process Tasks │    │ • Generate Code │
│ • Real-time     │    │ • Route to LLM  │    │ • API Calls     │
│ • Dynamic       │    │ • Handle Results│    │ • Model Routing │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Supabase Real-time Queue                     │
│                    (Central Event Bus)                          │
│  • cogo-subtasks: Task requests with model_id                  │
│  • cogo-results: Task results and generated code               │
│  • model-selection: Dynamic LLM routing                        │
└─────────────────────────────────────────────────────────────────┘
```

## Integration Objectives

### Primary Goals
1. **Dynamic Model Selection**: Enable CIO to select appropriate LLM based on task requirements
2. **Real-time Model Routing**: Implement real-time messaging for model selection
3. **Fireworks.ai Integration**: Add qwen3-coder-480b-a35b-instruct model support
4. **Backward Compatibility**: Maintain existing Claude 3.5 functionality
5. **Scalable Architecture**: Design for easy addition of future models

### Success Metrics
- CIO can dynamically select models via real-time messages
- Fireworks.ai model successfully generates code
- Response time < 30 seconds for code generation
- 99% uptime for model availability
- Zero breaking changes to existing functionality

## Technical Implementation Plan

### Phase 1: Environment Configuration

#### 1.1 API Key Management
```bash
# Environment Variables Setup
export FIREWORKS_API_KEY="T3x39SNew5S@y27"
export FIREWORKS_API_URL="https://api.fireworks.ai/inference/v1/chat/completions"
export DEFAULT_MODEL="claude-3.5-sonnet"
export FIREWORKS_MODEL="qwen3-coder-480b-a35b-instruct"
```

#### 1.2 Configuration Files
```typescript
// config/ai-models.ts
export interface AIModelConfig {
  id: string;
  name: string;
  provider: 'openai' | 'anthropic' | 'google' | 'fireworks';
  apiKey: string;
  apiUrl: string;
  maxTokens: number;
  temperature: number;
  capabilities: string[];
}

export const AI_MODELS: Record<string, AIModelConfig> = {
  'claude-3.5-sonnet': {
    id: 'claude-3.5-sonnet',
    name: 'Claude 3.5 Sonnet',
    provider: 'anthropic',
    apiKey: process.env.ANTHROPIC_API_KEY,
    apiUrl: 'https://api.anthropic.com/v1/messages',
    maxTokens: 4096,
    temperature: 0.7,
    capabilities: ['code-generation', 'code-analysis', 'general']
  },
  'fireworks/qwen3-coder-480b-a35b-instruct': {
    id: 'fireworks/qwen3-coder-480b-a35b-instruct',
    name: 'Qwen3 Coder 480B',
    provider: 'fireworks',
    apiKey: process.env.FIREWORKS_API_KEY,
    apiUrl: process.env.FIREWORKS_API_URL,
    maxTokens: 8192,
    temperature: 0.2,
    capabilities: ['code-generation', 'code-analysis', 'specialized-coding']
  }
};
```

### Phase 2: Fireworks.ai Client Implementation

#### 2.1 FireworksClient Class
```typescript
// src/services/FireworksClient.ts
import { AIModelConfig } from '../config/ai-models';

export interface FireworksChatCompletionRequest {
  model: string;
  messages: Array<{ role: 'user' | 'system'; content: string }>;
  max_tokens?: number;
  temperature?: number;
  top_p?: number;
  stream?: boolean;
}

export interface FireworksChatCompletionResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: Array<{
    index: number;
    message: {
      role: string;
      content: string;
    };
    finish_reason: string;
  }>;
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

export class FireworksClient {
  private readonly apiKey: string;
  private readonly apiUrl: string;
  private readonly defaultModel: string;

  constructor(config: AIModelConfig) {
    this.apiKey = config.apiKey;
    this.apiUrl = config.apiUrl;
    this.defaultModel = config.id;
    
    if (!this.apiKey) {
      throw new Error('FIREWORKS_API_KEY is not set in environment variables.');
    }
  }

  async generateCode(
    prompt: string, 
    model: string = this.defaultModel,
    options: Partial<FireworksChatCompletionRequest> = {}
  ): Promise<string> {
    const requestBody: FireworksChatCompletionRequest = {
      model: `accounts/fireworks/models/${model.replace('fireworks/', '')}`,
      messages: [
        {
          role: 'system',
          content: 'You are an expert software developer. Generate clean, efficient, and well-documented code.'
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      max_tokens: options.max_tokens || 8192,
      temperature: options.temperature || 0.2,
      top_p: options.top_p || 0.9,
      stream: false,
      ...options
    };

    try {
      const response = await fetch(this.apiUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(`Fireworks API error: ${response.status} ${errorBody}`);
      }

      const data: FireworksChatCompletionResponse = await response.json();
      return data.choices[0]?.message?.content || '';
    } catch (error) {
      console.error('Failed to generate code with Fireworks AI:', error);
      throw error;
    }
  }

  async analyzeCode(
    code: string,
    analysisType: 'review' | 'optimize' | 'debug' | 'document'
  ): Promise<string> {
    const prompts = {
      review: `Please review the following code for best practices, potential issues, and improvements:\n\n${code}`,
      optimize: `Please analyze and optimize the following code for performance and efficiency:\n\n${code}`,
      debug: `Please analyze the following code for potential bugs and issues:\n\n${code}`,
      document: `Please generate comprehensive documentation for the following code:\n\n${code}`
    };

    return this.generateCode(prompts[analysisType]);
  }
}
```

#### 2.2 Enhanced AIClients Integration
```typescript
// src/services/AIClients.ts
import { FireworksClient } from './FireworksClient';
import { AI_MODELS, AIModelConfig } from '../config/ai-models';

export class AIClientManager {
  private clients: Map<string, any> = new Map();
  private modelConfigs: Record<string, AIModelConfig>;

  constructor() {
    this.modelConfigs = AI_MODELS;
    this.initializeClients();
  }

  private initializeClients(): void {
    // Initialize Fireworks client
    const fireworksConfig = this.modelConfigs['fireworks/qwen3-coder-480b-a35b-instruct'];
    if (fireworksConfig) {
      this.clients.set('fireworks', new FireworksClient(fireworksConfig));
    }

    // Initialize existing clients (Claude, Gemini, OpenAI)
    // ... existing client initialization
  }

  async generateCode(
    prompt: string,
    modelId: string = 'claude-3.5-sonnet'
  ): Promise<string> {
    const client = this.getClientForModel(modelId);
    
    if (modelId.startsWith('fireworks/')) {
      const fireworksClient = this.clients.get('fireworks') as FireworksClient;
      return fireworksClient.generateCode(prompt, modelId);
    }
    
    // Fallback to existing clients
    return client.generateCode(prompt);
  }

  private getClientForModel(modelId: string): any {
    if (modelId.startsWith('fireworks/')) {
      return this.clients.get('fireworks');
    }
    
    // Return appropriate existing client
    return this.clients.get('claude') || this.clients.get('gemini');
  }

  getAvailableModels(): string[] {
    return Object.keys(this.modelConfigs);
  }

  getModelCapabilities(modelId: string): string[] {
    return this.modelConfigs[modelId]?.capabilities || [];
  }
}
```

### Phase 3: Real-time Model Selection Protocol

#### 3.1 Enhanced Message Types
```typescript
// src/types/ModelSelectionTypes.ts
export interface ModelSelectionMessage {
  type: 'MODEL_SELECTION_REQUEST' | 'MODEL_SELECTION_RESPONSE';
  payload: {
    task_id: string;
    subtask_id: string;
    requested_model: string;
    available_models: string[];
    model_capabilities: Record<string, string[]>;
    selection_reason?: string;
    timestamp: string;
  };
  source: string;
  target: 'cogo-model-selection';
}

export interface CodeGenerationSubtask {
  subtask_id: string;
  task_id: string;
  type: 'GENERATE_CODE' | 'ANALYZE_CODE' | 'OPTIMIZE_CODE';
  params: {
    git_branch: string;
    target_file: string;
    model_id: string; // New field for model selection
    generation_prompt: string;
    code_context?: string;
    language?: string;
    framework?: string;
  };
  metadata: {
    priority: 'low' | 'medium' | 'high';
    estimated_duration: number;
    model_preferences?: string[];
  };
}
```

#### 3.2 CIO Agent Model Selection Logic
```typescript
// src/agents/cogo-orchestrator-agent.ts
export class CogoOrchestratorAgent extends BaseAgent {
  private aiClientManager: AIClientManager;
  private modelSelectionStrategy: ModelSelectionStrategy;

  constructor() {
    super('cogo-orchestrator-agent');
    this.aiClientManager = new AIClientManager();
    this.modelSelectionStrategy = new ModelSelectionStrategy();
  }

  private async selectOptimalModel(task: any): Promise<string> {
    const availableModels = this.aiClientManager.getAvailableModels();
    
    // Analyze task requirements
    const taskRequirements = this.analyzeTaskRequirements(task);
    
    // Select model based on strategy
    const selectedModel = this.modelSelectionStrategy.selectModel(
      taskRequirements,
      availableModels
    );

    // Log model selection decision
    console.log(`[CIO] Selected model '${selectedModel}' for task: ${task.task_id}`);
    
    return selectedModel;
  }

  private analyzeTaskRequirements(task: any): TaskRequirements {
    const requirements: TaskRequirements = {
      complexity: 'medium',
      language: 'typescript',
      framework: 'nodejs',
      taskType: 'code-generation',
      performanceNeeded: false,
      accuracyNeeded: true
    };

    // Analyze task description and context
    if (task.description?.includes('complex') || task.description?.includes('advanced')) {
      requirements.complexity = 'high';
    }

    if (task.description?.includes('performance') || task.description?.includes('optimize')) {
      requirements.performanceNeeded = true;
    }

    return requirements;
  }

  async processTask(task: any): Promise<void> {
    // Select optimal model for the task
    const selectedModel = await this.selectOptimalModel(task);
    
    // Create subtask with model selection
    const subtask: CodeGenerationSubtask = {
      subtask_id: generateUUID(),
      task_id: task.task_id,
      type: 'GENERATE_CODE',
      params: {
        git_branch: task.git_branch,
        target_file: task.target_file,
        model_id: selectedModel, // Include selected model
        generation_prompt: task.prompt,
        code_context: task.context,
        language: task.language,
        framework: task.framework
      },
      metadata: {
        priority: task.priority || 'medium',
        estimated_duration: 30000,
        model_preferences: [selectedModel]
      }
    };

    // Broadcast subtask with model selection
    await this.realtimeQueue.broadcastMessage({
      type: 'MCP_SUBTASK',
      payload: subtask,
      source: this.getId(),
      target: 'cogo-subtasks'
    });
  }
}
```

#### 3.3 Model Selection Strategy
```typescript
// src/services/ModelSelectionStrategy.ts
export interface TaskRequirements {
  complexity: 'low' | 'medium' | 'high';
  language: string;
  framework: string;
  taskType: string;
  performanceNeeded: boolean;
  accuracyNeeded: boolean;
}

export class ModelSelectionStrategy {
  private modelCapabilities: Record<string, string[]> = {
    'claude-3.5-sonnet': ['code-generation', 'code-analysis', 'general', 'reasoning'],
    'fireworks/qwen3-coder-480b-a35b-instruct': ['code-generation', 'code-analysis', 'specialized-coding', 'performance']
  };

  selectModel(requirements: TaskRequirements, availableModels: string[]): string {
    // Priority 1: Specialized coding tasks
    if (requirements.taskType === 'specialized-coding' && 
        availableModels.includes('fireworks/qwen3-coder-480b-a35b-instruct')) {
      return 'fireworks/qwen3-coder-480b-a35b-instruct';
    }

    // Priority 2: Performance-critical tasks
    if (requirements.performanceNeeded && 
        availableModels.includes('fireworks/qwen3-coder-480b-a35b-instruct')) {
      return 'fireworks/qwen3-coder-480b-a35b-instruct';
    }

    // Priority 3: Complex reasoning tasks
    if (requirements.complexity === 'high' && requirements.accuracyNeeded) {
      return 'claude-3.5-sonnet';
    }

    // Default: Claude 3.5 Sonnet
    return 'claude-3.5-sonnet';
  }

  getModelRecommendations(requirements: TaskRequirements): string[] {
    const recommendations: string[] = [];
    
    if (requirements.taskType === 'specialized-coding') {
      recommendations.push('fireworks/qwen3-coder-480b-a35b-instruct');
    }
    
    if (requirements.performanceNeeded) {
      recommendations.push('fireworks/qwen3-coder-480b-a35b-instruct');
    }
    
    if (requirements.accuracyNeeded) {
      recommendations.push('claude-3.5-sonnet');
    }
    
    return recommendations;
  }
}
```

### Phase 4: Task Manager Integration

#### 4.1 Enhanced Task Processing
```typescript
// src/agents/cogo-executor-agent.ts
export class CogoExecutorAgent extends BaseAgent {
  private aiClientManager: AIClientManager;

  constructor() {
    super('cogo-executor-agent');
    this.aiClientManager = new AIClientManager();
  }

  private async handleCodeGenerationSubtask(message: any): Promise<void> {
    try {
      const subtask: CodeGenerationSubtask = message.payload;
      console.log(`[TaskManager] Processing code generation with model: ${subtask.params.model_id}`);

      // Generate code using selected model
      const generatedCode = await this.aiClientManager.generateCode(
        subtask.params.generation_prompt,
        subtask.params.model_id
      );

      // Create result
      const result: MCPSubtaskResult = {
        subtask_id: subtask.subtask_id,
        task_id: subtask.task_id,
        status: 'completed',
        output: {
          generated_code: generatedCode,
          model_used: subtask.params.model_id,
          generation_time: Date.now(),
          file_path: subtask.params.target_file
        },
        execution_time: Date.now() - new Date(subtask.metadata?.timestamp || Date.now()).getTime(),
        metadata: {
          source: this.getId(),
          timestamp: new Date().toISOString(),
          model_performance: {
            model_id: subtask.params.model_id,
            response_time: Date.now(),
            tokens_used: 0 // Will be updated from API response
          }
        }
      };

      // Broadcast result
      await this.realtimeQueue.broadcastMessage({
        type: 'SUBTASK_RESULT',
        payload: result,
        source: this.getId(),
        target: 'cogo-results'
      });

    } catch (error) {
      console.error('[TaskManager] Error in code generation:', error);
      
      // Broadcast error result
      const errorResult: MCPSubtaskResult = {
        subtask_id: message.payload?.subtask_id || 'unknown',
        task_id: message.payload?.task_id || 'unknown',
        status: 'failed',
        error: error instanceof Error ? error.message : 'Unknown error',
        execution_time: 0,
        metadata: {
          source: this.getId(),
          timestamp: new Date().toISOString(),
          model_id: message.payload?.params?.model_id || 'unknown'
        }
      };

      await this.realtimeQueue.broadcastMessage({
        type: 'SUBTASK_RESULT',
        payload: errorResult,
        source: this.getId(),
        target: 'cogo-results'
      });
    }
  }
}
```

### Phase 5: API Endpoints Enhancement

#### 5.1 Model Management API
```typescript
// src/routes/model-management.ts
import { Router } from 'express';
import { AIClientManager } from '../services/AIClients';
import { ModelSelectionStrategy } from '../services/ModelSelectionStrategy';

const router = Router();
const aiClientManager = new AIClientManager();
const modelStrategy = new ModelSelectionStrategy();

// GET /api/models - List available models
router.get('/models', async (req, res) => {
  try {
    const models = aiClientManager.getAvailableModels();
    const modelDetails = models.map(modelId => ({
      id: modelId,
      capabilities: aiClientManager.getModelCapabilities(modelId),
      status: 'available'
    }));

    res.json({
      success: true,
      data: {
        models: modelDetails,
        total: models.length
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// POST /api/models/select - Get model recommendation
router.post('/models/select', async (req, res) => {
  try {
    const { task_requirements } = req.body;
    const recommendations = modelStrategy.getModelRecommendations(task_requirements);
    
    res.json({
      success: true,
      data: {
        recommendations,
        reasoning: `Selected based on: ${task_requirements.taskType}, complexity: ${task_requirements.complexity}`
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// POST /api/models/test - Test model connectivity
router.post('/models/test', async (req, res) => {
  try {
    const { model_id } = req.body;
    const testPrompt = 'console.log("Hello, World!");';
    
    const result = await aiClientManager.generateCode(testPrompt, model_id);
    
    res.json({
      success: true,
      data: {
        model_id,
        test_result: result,
        status: 'connected'
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      model_id: req.body.model_id
    });
  }
});

export default router;
```

#### 5.2 Enhanced Code Generation API
```typescript
// src/routes/code-generation.ts
import { Router } from 'express';
import { AIClientManager } from '../services/AIClients';

const router = Router();
const aiClientManager = new AIClientManager();

// POST /api/code-generation/generate - Generate code with model selection
router.post('/generate', async (req, res) => {
  try {
    const { 
      prompt, 
      model_id = 'claude-3.5-sonnet',
      language = 'typescript',
      framework = 'nodejs',
      context = ''
    } = req.body;

    // Validate model availability
    const availableModels = aiClientManager.getAvailableModels();
    if (!availableModels.includes(model_id)) {
      return res.status(400).json({
        success: false,
        error: `Model '${model_id}' is not available. Available models: ${availableModels.join(', ')}`
      });
    }

    // Generate code
    const startTime = Date.now();
    const generatedCode = await aiClientManager.generateCode(prompt, model_id);
    const generationTime = Date.now() - startTime;

    res.json({
      success: true,
      data: {
        generated_code: generatedCode,
        model_used: model_id,
        generation_time: generationTime,
        language,
        framework,
        context
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

export default router;
```

## Implementation Timeline

### Week 1: Foundation Setup
- [ ] Environment configuration
- [ ] API key management
- [ ] Basic FireworksClient implementation
- [ ] Model configuration system

### Week 2: Core Integration
- [ ] AIClientManager enhancement
- [ ] Model selection strategy
- [ ] Real-time message protocol updates
- [ ] Basic API endpoints

### Week 3: Agent Integration
- [ ] CIO agent model selection logic
- [ ] Task manager integration
- [ ] Real-time communication testing
- [ ] Error handling and fallbacks

### Week 4: Testing & Optimization
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] Documentation updates
- [ ] Production deployment

## Testing Strategy

### Unit Tests
```typescript
// tests/FireworksClient.test.ts
describe('FireworksClient', () => {
  test('should generate code successfully', async () => {
    const client = new FireworksClient(mockConfig);
    const result = await client.generateCode('Create a React component');
    expect(result).toBeTruthy();
    expect(typeof result).toBe('string');
  });

  test('should handle API errors gracefully', async () => {
    const client = new FireworksClient(invalidConfig);
    await expect(client.generateCode('test')).rejects.toThrow();
  });
});
```

### Integration Tests
```typescript
// tests/ModelSelection.test.ts
describe('Model Selection Integration', () => {
  test('CIO should select Fireworks model for coding tasks', async () => {
    const cio = new CogoOrchestratorAgent();
    const task = { description: 'Generate optimized sorting algorithm' };
    const selectedModel = await cio.selectOptimalModel(task);
    expect(selectedModel).toBe('fireworks/qwen3-coder-480b-a35b-instruct');
  });
});
```

### Performance Tests
- Response time < 30 seconds
- Memory usage < 512MB per request
- Concurrent request handling
- Error recovery time < 5 seconds

## Security Considerations

### API Key Security
- Environment variable storage only
- No hardcoded keys in source code
- Key rotation procedures
- Access logging and monitoring

### Request Validation
- Input sanitization
- Rate limiting
- Request size limits
- Model access controls

### Error Handling
- No sensitive data in error messages
- Graceful degradation
- Fallback to default model
- Comprehensive logging

## Monitoring & Observability

### Metrics to Track
- Model selection frequency
- Response times per model
- Error rates per model
- Token usage and costs
- User satisfaction scores

### Logging Strategy
```typescript
// Structured logging for model operations
logger.info('Model selection', {
  task_id: task.task_id,
  selected_model: selectedModel,
  reasoning: selectionReason,
  available_models: availableModels,
  timestamp: new Date().toISOString()
});
```

## Future Enhancements

### Planned Features
1. **Model Performance Analytics**: Track and compare model performance
2. **Automatic Model Switching**: Switch models based on performance
3. **Cost Optimization**: Select models based on cost constraints
4. **Custom Model Training**: Support for fine-tuned models
5. **Multi-Model Ensemble**: Combine multiple models for complex tasks

### Scalability Considerations
- Horizontal scaling of model clients
- Load balancing across model providers
- Caching strategies for repeated requests
- Queue management for high-volume requests

## Conclusion

This integration plan provides a comprehensive approach to adding Fireworks.ai's qwen3-coder-480b-a35b-instruct model to the COGO system while maintaining backward compatibility and enabling dynamic model selection. The implementation follows best practices for security, performance, and maintainability, ensuring a robust and scalable solution.

The key benefits of this integration include:
- **Enhanced Code Generation**: Access to specialized coding models
- **Dynamic Model Selection**: Intelligent model routing based on task requirements
- **Improved Performance**: Faster response times for coding tasks
- **Cost Optimization**: Better resource utilization
- **Future-Proof Architecture**: Easy addition of new models

This plan serves as a blueprint for implementing the integration and can be adapted as requirements evolve. 