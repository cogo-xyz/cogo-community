## Distributed Agents – Public API Signatures

This document indexes the public APIs of the distributed agents implemented in this repository.

### Orchestrator – DistributedOrchestratorAgent
File: `src/agents/DistributedOrchestratorAgent.ts`

- constructor(communication?: DistributedCommunicationInterface)
- initialize(): Promise<void>
- cleanup(): Promise<void>
- executeTask(task: Task): Promise<boolean>
- getSystemStatus(): Promise<any>
- getMetrics(): Promise<any>
- getSupportedLanguages(): Record<string, string>
- generateMultilingualResponse(message: string, language?: string): string
- processMultilingualTask(task: DistributedTask, preferredLanguage?: string): Promise<any>
- getEnhancedSystemStatus(): any
- getChildAgents(): DistributedAgentInfo[]
- getActiveTaskCount(): number
- getCurrentLoad(): number
- getVersion(): string

### Indexing – DistributedIndexingAgent
File: `src/agents/DistributedIndexingAgent.ts`

- constructor(communication?, vectorDB?, embeddingService?, knowledgeGraph?)
- initialize(): Promise<void>
- cleanup(): Promise<void>
- executeTask(task: Task): Promise<boolean>
- performExternalIndexing(request: IndexingRequest): Promise<IndexingResult>
- performExternalSearch(request: SearchRequest): Promise<SearchResult[]>
- analyzeCode(request: CodeAnalysisRequest): Promise<CodeAnalysisResult>
- indexCodeFiles(files: CodeFileInfo[], options?): Promise<{ indexingResult?, analysisResult? }>
- getSystemStatus(): Promise<any>
- getMetrics(): Promise<any>
- getActiveIndexingCount(): number
- getQueueLength(): number
- getIndexingHistory(): IndexingResult[]
- getCodeAnalysisResult(requestId: string): CodeAnalysisResult | undefined
- getCodeAnalysisHistory(): Map<string, CodeAnalysisResult>

### Research – DistributedResearchAgent
File: `src/agents/DistributedResearchAgent.ts`

- constructor(communication?, multiAI?, indexingAgent?, knowledgeBase?, webSearch?)
- initialize(): Promise<void>
- cleanup(): Promise<void>
- executeTask(task: Task): Promise<boolean>
- performExternalResearch(request: ResearchRequest): Promise<ResearchResult>
- conductResearch(request: ResearchRequest): Promise<ResearchResult>
- getCapabilities(): string[]
- getSystemStatus(): Promise<any>
- getMetrics(): Promise<any>
- getActiveRequestCount(): number
- getQueueLength(): number
- getResearchHistory(): ResearchResult[]
- addResearchToQueue(request: ResearchRequest): void

### GraphRAG – DistributedGraphRAGAgent
File: `src/agents/DistributedGraphRAGAgent.ts`

- constructor(communication?, graphDB?, reasoningEngine?, patternAnalysis?)
- initialize(): Promise<void>
- cleanup(): Promise<void>
- executeTask(task: Task): Promise<boolean>
- performExternalQuery(query: GraphRAGQuery): Promise<GraphRAGResult>
- performEnhancedGraphRAG(query: string, options?): Promise<any>
- integrateResearchResults(researchResult: any): Promise<void>
- integrateIndexingResults(indexingResult: any): Promise<void>
- getEnhancedCapabilities(): string[]
- getSystemStatus(): Promise<any>
- getMetrics(): Promise<any>
- getActiveQueryCount(): number
- getQueryHistory(): GraphRAGResult[]

### Executor – DistributedExecutorAgent
File: `src/agents/DistributedExecutorAgent.ts`

- constructor(communication: DistributedCommunicationInterface, workerInterface: WebSocketWorkerInterface)
- initialize(): Promise<void>
- cleanup(): Promise<void>
- executeTask(task: Task): Promise<boolean>
- getSystemStatus(): Promise<any>
- getMetrics(): Promise<any>
- getConnectedWorkers(): WorkerInfo[]
- getActiveTaskCount(): number
- getQueueLength(): number
- addTaskToQueue(task: WorkerTask): void


