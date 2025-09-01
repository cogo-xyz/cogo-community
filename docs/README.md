# COGO Agent Core Documentation

This repository contains comprehensive documentation for the COGO Agent Core system, a distributed AI agent framework built on Supabase Edge Functions and real-time communication channels.

## 📚 Quick Start

- **[architecture/AGENT_ARCHITECTURE_OVERVIEW.md](architecture/AGENT_ARCHITECTURE_OVERVIEW.md)** - System architecture overview
- **[api/](api/)** - API references and Edge functions
- **[agents/COGO_AGENT_CHAT_MESSAGE_SPEC.md](agents/COGO_AGENT_CHAT_MESSAGE_SPEC.md)** - Chat message protocol specification (includes request `editor_context`, SSE `aborted`, attachments)
- **[guides/](guides/)** - User guides and setup instructions
  - **[guides/IDE_Chat_Integration.md](guides/IDE_Chat_Integration.md)** - IDE chat integration (editor_context, SSE, attachments)
  - **[operations/Capabilities_Operations_Guide.md](operations/Capabilities_Operations_Guide.md)** - Capabilities ops (registry/fallback, DEV flags)
  - **[operations/RELEASE_CHECKLIST.md](operations/RELEASE_CHECKLIST.md)** - Release checklist (chat protocol & edges)

## 📁 Documentation Categories

### 🏗️ Architecture & Design
Core system architecture and design documents.
- **[architecture/](architecture/)** - System architecture documents
- **[design/](design/)** - UI/UX design and client architecture
- **[specs/](specs/)** - Technical specifications

### 🤖 Agent Development
Agent development, specifications, and implementation details.
- **[agents/](agents/)** - Agent specifications and development
- **[development/](development/)** - Development processes and implementation

### 🔌 API & Integration
API references, integration guides, and external system connections.
- **[api/](api/)** - API references and Edge functions
- **[integration/](integration/)** - Third-party integrations (LLM, MCP, etc.)
- **[supabase/](supabase/)** - Supabase-specific documentation

### 🗄️ Database & Schema
Database schemas, Neo4j integration, and data modeling.
- **[schemas/](schemas/)** - Database schemas and data models
- **[parsing/](parsing/)** - JSON parsing and data processing

### 🚀 Deployment & Operations
Deployment guides, operations runbooks, and infrastructure management.
- **[deployment/](deployment/)** - Deployment guides and environment setup
- **[ops/](ops/)** - Operations documentation
- **[runbook/](runbook/)** - Operations runbooks

### 📋 Development Plans
Development roadmaps, implementation plans, and project milestones.
- **[plans/](plans/)** - Development plans and roadmaps
- **[plans/COGO_CLI_DESIGN.md](plans/COGO_CLI_DESIGN.md)** - COGO CLI design (plan/apply, SSE, artifacts)
- **[plans/COGO_CLI_IMPLEMENTATION_PLAN.md](plans/COGO_CLI_IMPLEMENTATION_PLAN.md)** - COGO CLI implementation plan (architecture, modules, milestones)
- **[project/](project/)** - Project management documentation

### 🧪 Testing & CI/CD
Testing frameworks, CI/CD pipelines, and quality assurance.
- **[tests/](tests/)** - Testing documentation and guides
  - **[tests/CI_GUIDE.md](../tests/CI_GUIDE.md)** - CI guide for edge-all workflow

### 🔒 Security & Governance
Security hardening, governance policies, and compliance.
- **[security/](security/)** - Security documentation and policies
- **[management/policies/](management/policies/)** - Project policies and governance

### 📊 Monitoring & Observability
Monitoring setup, alerting, metrics, and observability.
- **[observability/](observability/)** - Observability setup, dashboards, and monitoring

### 🔄 Migration & Legacy
Migration guides, legacy system cleanup, and transition plans.
- **[migration/](migration/)** - Migration guides and legacy cleanup
- **[methodology/](methodology/)** - Development methodologies

### 📖 User Guides & Documentation
User guides, development guides, and reference materials.
- **[guides/](guides/)** - User guides, manuals, and reference materials

### 🔬 Research & Special Topics
Research documentation and specialized topics.
- **[research/](research/)** - Research documentation
- **[technical/](technical/)** - Technical implementations (parsing, performance, tree-sitter)
- **[ecosystem/](ecosystem/)** - Self-upgrading agent ecosystem
- **[multilingual/](multilingual/)** - Multi-language support
- **[sandbox/](sandbox/)** - Sandbox system documentation

### 📈 Reports & Analysis
Status reports, analysis, and historical documentation.
- **[reports/](reports/)** - Status reports, analysis, and ADR

### 🔧 Tools & Utilities
Development tools, utilities, and supporting documentation.
- **[examples/](examples/)** - Examples, OpenAPI specs, and Postman collections
  - Run SSE example: `npm run sse:example` (requires SUPABASE_EDGE/ANON)
- **[system/](system/)** - System components (events, realtime, scenarios)
- **[management/](management/)** - Management tools (artifacts, rollout)

## 📂 Directory Structure

```
docs/
├── README.md                           # Main documentation index (this file)
├── index.md                           # Detailed documentation index
├── agents/                            # Agent specifications and development
├── api/                               # API references and Edge functions
├── architecture/                      # System architecture documents
├── design/                            # UI/UX design and client architecture
├── development/                       # Development processes and implementation
├── ecosystem/                         # Self-upgrading agent ecosystem
├── examples/                          # Examples, OpenAPI specs, and collections
├── guides/                            # User guides, manuals, and references
├── integration/                       # Third-party integrations (LLM, MCP, etc.)
├── management/                        # Management tools (artifacts, rollout, policies)
├── methodology/                       # Development methodologies
├── migration/                         # Migration guides and legacy cleanup
├── multilingual/                      # Multi-language support
├── observability/                     # Observability, monitoring, and dashboards
├── operations/                        # Deployment, operations, and runbooks
├── plans/                             # Development plans and roadmaps
├── project/                           # Project management documentation
├── reports/                           # Status reports, analysis, and ADR
├── research/                          # Research documentation
├── sandbox/                          # Sandbox system documentation
├── schemas/                          # Database schemas and data models
├── security/                         # Security documentation and policies
├── specs/                            # Technical specifications
├── supabase/                         # Supabase-specific documentation
├── system/                           # System components (events, realtime, scenarios)
├── technical/                        # Technical implementations (parsing, performance)
├── tests/                            # Testing documentation and guides
└── uui/                              # UUI system documentation
```

---

*Last updated: 2025-01-30*
*Maintained by: COGO Development Team*