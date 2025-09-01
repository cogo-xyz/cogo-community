






# COGO Agent Core Documentation Index

This comprehensive index provides detailed categorization and quick access to all documentation in the COGO Agent Core project.

## 📋 Table of Contents

- [Quick Reference](#-quick-reference)
- [Architecture & Design](#-architecture--design)
- [Agent Development](#-agent-development)
- [API & Integration](#-api--integration)
- [Database & Schema](#-database--schema)
- [Deployment & Operations](#-deployment--operations)
- [Development Plans](#-development-plans)
- [Testing & CI/CD](#-testing--cicd)
- [Security & Governance](#-security--governance)
- [Monitoring & Observability](#-monitoring--observability)
- [Migration & Legacy](#-migration--legacy)
- [User Guides & Documentation](#-user-guides--documentation)
- [Directory Structure](#-directory-structure)

---

## 🔍 Quick Reference

### Essential Documents
| Document | Description | Status |
|----------|-------------|--------|
| [agents/COGO_AGENT_CHAT_MESSAGE_SPEC.md](agents/COGO_AGENT_CHAT_MESSAGE_SPEC.md) | Chat message protocol specification (editor_context, SSE aborted, attachments) | ✅ Current |
| [architecture/AGENT_ARCHITECTURE_OVERVIEW.md](architecture/AGENT_ARCHITECTURE_OVERVIEW.md) | System architecture overview | ✅ Current |
| [api/](api/) | API references and Edge functions | ✅ Current |
| [guides/](guides/) | User guides and setup instructions | ✅ Current |
| [guides/IDE_Chat_Integration.md](guides/IDE_Chat_Integration.md) | IDE chat integration (editor_context, SSE, attachments) | ✅ Current |
| [operations/Capabilities_Operations_Guide.md](operations/Capabilities_Operations_Guide.md) | Capabilities ops guide (registry/fallback, DEV flags) | ✅ Current |

### Development Workflow
| Document | Description | Status |
|----------|-------------|--------|
| [development/](development/) | Development guides and processes | ✅ Current |
| [tests/](tests/) | Testing documentation and guides | ✅ Current |
| [deployment/](deployment/) | Deployment guides and environment setup | ✅ Current |
| [guides/](guides/) | User guides and setup instructions | ✅ Current |

---

## 🏗️ Architecture & Design

### Core Architecture
| Document | Description | Status |
|----------|-------------|--------|
| [architecture/AGENT_ARCHITECTURE_OVERVIEW.md](architecture/AGENT_ARCHITECTURE_OVERVIEW.md) | System architecture overview | ✅ Current |
| [architecture/SYSTEM_ARCHITECTURE.md](architecture/SYSTEM_ARCHITECTURE.md) | Detailed system architecture | ✅ Current |
| [architecture/ARCHITECTURE_INDEX.md](architecture/ARCHITECTURE_INDEX.md) | Architecture documentation index | ✅ Current |
| [architecture/DISTRIBUTED_AGENT_SYSTEM.md](architecture/DISTRIBUTED_AGENT_SYSTEM.md) | Distributed agent architecture | ✅ Current |
| [architecture/AGENT_SYSTEM_ARCHITECTURE.md](architecture/AGENT_SYSTEM_ARCHITECTURE.md) | Agent system architecture | ✅ Current |

### Design Documents
| Document | Description | Status |
|----------|-------------|--------|
| [COGO_CLIENT_ARCHITECTURE_PLAN.md](COGO_CLIENT_ARCHITECTURE_PLAN.md) | Client architecture plan | 📅 Review |
| [BETA_SYSTEM_DESIGN.md](BETA_SYSTEM_DESIGN.md) | Beta system design | 📅 Review |
| [CORRECTED_COGO_ARCHITECTURE.md](CORRECTED_COGO_ARCHITECTURE.md) | Corrected COGO architecture | 📅 Review |
| [design/](design/) | Design documents directory | - |

### ADR (Architecture Decision Records)
| Document | Description | Status |
|----------|-------------|--------|
| [ADR/ADR-rag-utilization.md](ADR/ADR-rag-utilization.md) | RAG utilization ADR | ✅ Current |

---

## 🤖 Agent Development

### Agent Specifications
| Document | Description | Status |
|----------|-------------|--------|
| [agents/COGO_AGENT_OVERVIEW.md](agents/COGO_AGENT_OVERVIEW.md) | Agent system overview | ✅ Current |
| [agents/AGENT_DETAILED_SPECIFICATIONS.md](agents/AGENT_DETAILED_SPECIFICATIONS.md) | Agent specifications | ✅ Current |
| [agents/COGO_AGENT_DETAILED_SPECIFICATIONS.md](agents/COGO_AGENT_DETAILED_SPECIFICATIONS.md) | COGO agent specifications | ✅ Current |
| [agents/AGENT_SPECIFICATIONS_PART1.md](agents/AGENT_SPECIFICATIONS_PART1.md) | Agent specs part 1 | 📅 Review |
| [agents/AGENT_SPECIFICATIONS_PART2.md](agents/AGENT_SPECIFICATIONS_PART2.md) | Agent specs part 2 | 📅 Review |

### Agent Implementation
| Document | Description | Status |
|----------|-------------|--------|
| [AGENT_IMPLEMENTATION_DETAILS.md](AGENT_IMPLEMENTATION_DETAILS.md) | Implementation details | ✅ Current |
| [AGENT_SYSTEM_IMPLEMENTATION_STATUS.md](AGENT_SYSTEM_IMPLEMENTATION_STATUS.md) | Implementation status | ✅ Current |
| [AGENT_SYSTEM_COMPLETION_REPORT.md](AGENT_SYSTEM_COMPLETION_REPORT.md) | Completion report | ✅ Current |
| [ACTUAL_AGENT_ANALYSIS_AND_DEVELOPMENT_PLAN.md](ACTUAL_AGENT_ANALYSIS_AND_DEVELOPMENT_PLAN.md) | Analysis and development plan | 📅 Review |

### Agent Analysis
| Document | Description | Status |
|----------|-------------|--------|
| [AGENT_SOURCE_ANALYSIS.md](AGENT_SOURCE_ANALYSIS.md) | Source analysis | 📅 Review |
| [AGENT_SOURCE_ANALYSIS_REVISED.md](AGENT_SOURCE_ANALYSIS_REVISED.md) | Revised source analysis | 📅 Review |
| [AGENT_SOURCE_RELATIONSHIP_DIAGRAM.md](AGENT_SOURCE_RELATIONSHIP_DIAGRAM.md) | Source relationship diagram | 📅 Review |
| [AGENT_SOURCE_STRUCTURE.md](AGENT_SOURCE_STRUCTURE.md) | Source structure | 📅 Review |

### Agent-specific Documentation
| Document | Description | Status |
|----------|-------------|--------|
| [agents/AGENTS_API_INDEX.md](agents/AGENTS_API_INDEX.md) | Agents API index | ✅ Current |

---

## 🔌 API & Integration

### API References
| Document | Description | Status |
|----------|-------------|--------|
| [api/API_REFERENCE_COMPLETE.md](api/API_REFERENCE_COMPLETE.md) | Complete API reference | ✅ Current |
| [api/API_REFERENCE.md](api/API_REFERENCE.md) | API reference | ✅ Current |
| [api/COLLAB_API_FLOW_GUIDE.md](api/COLLAB_API_FLOW_GUIDE.md) | Collaboration API flow | ✅ Current |

### Edge Functions
| Document | Description | Status |
|----------|-------------|--------|
| [api/EDGE_FUNCTIONS_OVERVIEW.md](api/EDGE_FUNCTIONS_OVERVIEW.md) | Edge functions overview | ✅ Current |
| [api/EDGE_FIGMA_PLUGIN_PROTOCOL.md](api/EDGE_FIGMA_PLUGIN_PROTOCOL.md) | Figma plugin protocol | ✅ Current |
| [api/EDGE_TEST_GUIDE.md](api/EDGE_TEST_GUIDE.md) | Edge function testing | ✅ Current |

### Integration Systems
| Document | Description | Status |
|----------|-------------|--------|
| [MCP_INTEGRATION.md](MCP_INTEGRATION.md) | MCP server integration | ✅ Current |
| [MCP_SERVER_INTEGRATION_GUIDE.md](MCP_SERVER_INTEGRATION_GUIDE.md) | MCP integration guide | ✅ Current |
| [MCP_ENDPOINTS.md](MCP_ENDPOINTS.md) | MCP endpoints | ✅ Current |
| [SUPABASE_INTEGRATION.md](SUPABASE_INTEGRATION.md) | Supabase integration | ✅ Current |
| [SUPABASE_CHAT_ARCHITECTURE.md](SUPABASE_CHAT_ARCHITECTURE.md) | Supabase chat architecture | ✅ Current |

---

## 🗄️ Database & Schema

### Database Design
| Document | Description | Status |
|----------|-------------|--------|
| [schemas/DATABASE_SCHEMAS_FOR_COGO_SOURCE.md](schemas/DATABASE_SCHEMAS_FOR_COGO_SOURCE.md) | Database schemas for COGO | ✅ Current |
| [schemas/SCHEMA_OWNERSHIP_MATRIX.md](schemas/SCHEMA_OWNERSHIP_MATRIX.md) | Schema ownership matrix | ✅ Current |
| [schemas/database-design-and-namespace.md](schemas/database-design-and-namespace.md) | Database design and namespace | ✅ Current |

### Schema Analysis
| Document | Description | Status |
|----------|-------------|--------|
| [schemas/current-schema-analysis.md](schemas/current-schema-analysis.md) | Current schema analysis | ✅ Current |
| [schemas/neo4j-current-schema-analysis.md](schemas/neo4j-current-schema-analysis.md) | Neo4j schema analysis | ✅ Current |
| [schemas/neo4j-schema-extension-plan.md](schemas/neo4j-schema-extension-plan.md) | Neo4j schema extension | 📅 Review |
| [schemas/schema-extension-plan.md](schemas/schema-extension-plan.md) | Schema extension plan | 📅 Review |
| [schemas/FINAL_SCHEMA_VALIDATION.md](schemas/FINAL_SCHEMA_VALIDATION.md) | Schema validation | ✅ Current |

### Supabase Database
| Document | Description | Status |
|----------|-------------|--------|
| [supabase/](supabase/) | Supabase documentation directory | - |
| [supabase/sql/](supabase/sql/) | SQL schema files | - |

---

## 🚀 Deployment & Operations

### Deployment Guides
| Document | Description | Status |
|----------|-------------|--------|
| [deployment/DEPLOYMENT_AND_OPERATIONS.md](deployment/DEPLOYMENT_AND_OPERATIONS.md) | Deployment and operations | ✅ Current |
| [deployment/DOCKER_LOCAL_PLAYBOOK.md](deployment/DOCKER_LOCAL_PLAYBOOK.md) | Docker local setup | ✅ Current |
| [deployment/LAUNCH_CHECKLIST.md](deployment/LAUNCH_CHECKLIST.md) | Launch checklist | ✅ Current |
| [deployment/README_BETA_ENV.md](deployment/README_BETA_ENV.md) | Beta environment templates | ✅ Current |

### Operations
| Document | Description | Status |
|----------|-------------|--------|
| [runbook/OPERATIONS_RUNBOOK.md](runbook/OPERATIONS_RUNBOOK.md) | Operations runbook | ✅ Current |
| [deployment/PORTS_AND_NETWORKING.md](deployment/PORTS_AND_NETWORKING.md) | Ports and networking | ✅ Current |
| [ops/README_BETA_OPS.md](ops/README_BETA_OPS.md) | Beta operations quickstart | ✅ Current |
| [runbook/](runbook/) | Operations runbooks directory | - |

---

## 📋 Development Plans

### Development Roadmaps
| Document | Description | Status |
|----------|-------------|--------|
| [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) | Main development plan | 📅 Review |
| [DEVELOPMENT_PLAN_RECOMMENDED.md](DEVELOPMENT_PLAN_RECOMMENDED.md) | Recommended development plan | 📅 Review |
| [FUTURE_DEVELOPMENT_PLAN.md](FUTURE_DEVELOPMENT_PLAN.md) | Future development plan | 📅 Review |
| [FUTURE_DEVELOPMENT_ROADMAP.md](FUTURE_DEVELOPMENT_ROADMAP.md) | Future development roadmap | 📅 Review |
| [plans/COGO_CLI_DESIGN.md](plans/COGO_CLI_DESIGN.md) | COGO CLI design (plan/apply, SSE, artifacts) | ✅ Current |
| [plans/COGO_CLI_IMPLEMENTATION_PLAN.md](plans/COGO_CLI_IMPLEMENTATION_PLAN.md) | COGO CLI implementation plan (architecture, modules, milestones) | ✅ Current |

### Detailed Plans Directory
| Document | Description | Status |
|----------|-------------|--------|
| [plans/DEVELOPMENT_PLAN_EDGE.md](plans/DEVELOPMENT_PLAN_EDGE.md) | Edge function development plan | ✅ Current |
| [plans/BATCH_ROLLOUT_PLAN.md](plans/BATCH_ROLLOUT_PLAN.md) | Batch rollout plan | ✅ Current |
| [plans/INTENT_KEYWORD_REGISTRY.md](plans/INTENT_KEYWORD_REGISTRY.md) | Intent keyword registry | ✅ Current |
| [plans/IDEMPOTENCY_STORE_DDL.md](plans/IDEMPOTENCY_STORE_DDL.md) | Idempotency store DDL | ✅ Current |

---

## 🧪 Testing & CI/CD

### CI/CD Systems
| Document | Description | Status |
|----------|-------------|--------|
| [tests/CI_GUIDE.md](tests/CI_GUIDE.md) | CI/CD guide | ✅ Current |
| [tests/CI_GATE_PLAYBOOK.md](tests/CI_GATE_PLAYBOOK.md) | CI gate playbook | ✅ Current |
| [tests/CI_SECRETS_AND_BRANCH_PROTECTION.md](tests/CI_SECRETS_AND_BRANCH_PROTECTION.md) | CI secrets and branch protection | ✅ Current |
| [tests/CI_SMOKE_SETUP.md](tests/CI_SMOKE_SETUP.md) | CI smoke setup | ✅ Current |

### Testing Frameworks
| Document | Description | Status |
|----------|-------------|--------|
| [tests/COMPREHENSIVE_TEST_SYSTEM.md](tests/COMPREHENSIVE_TEST_SYSTEM.md) | Comprehensive test system | ✅ Current |
| [tests/EDGE_TEST_GUIDE.md](tests/EDGE_TEST_GUIDE.md) | Edge function testing | ✅ Current |
| [tests/INTERFACE_PRESERVING_TEST_SYSTEM.md](tests/INTERFACE_PRESERVING_TEST_SYSTEM.md) | Interface-preserving tests | ✅ Current |
| [sandbox/SANDBOX_TEST_SCENARIOS.md](sandbox/SANDBOX_TEST_SCENARIOS.md) | Sandbox test scenarios | ✅ Current |

---

## 🔒 Security & Governance

### Security Hardening
| Document | Description | Status |
|----------|-------------|--------|
| [security/SECURITY_HARDENING.md](security/SECURITY_HARDENING.md) | Security hardening guide | ✅ Current |
| [security/SECURITY_AND_GOVERNANCE.md](security/SECURITY_AND_GOVERNANCE.md) | Security and governance | ✅ Current |
| [security/RLS_HARDENING_SQL_TEMPLATE.sql](security/RLS_HARDENING_SQL_TEMPLATE.sql) | RLS hardening SQL template | ✅ Current |
| [security/DISTRIBUTED_KEY_MANAGEMENT_DESIGN.md](security/DISTRIBUTED_KEY_MANAGEMENT_DESIGN.md) | Distributed key management | ✅ Current |

### Governance
| Document | Description | Status |
|----------|-------------|--------|
| [security/CENTRAL_CONFIGURATION_MANAGEMENT.md](security/CENTRAL_CONFIGURATION_MANAGEMENT.md) | Configuration management | ✅ Current |
| [security/AUTHENTICATION_SYSTEM_IMPLEMENTATION.md](security/AUTHENTICATION_SYSTEM_IMPLEMENTATION.md) | Authentication system | ✅ Current |
| [policies/](policies/) | Project policies directory | - |

---

## 📊 Monitoring & Observability

### Observability Setup
| Document | Description | Status |
|----------|-------------|--------|
| [observability/OBSERVABILITY_SETUP.md](observability/OBSERVABILITY_SETUP.md) | Observability setup | ✅ Current |
| [observability/ALERTS_AND_TRACES.md](observability/ALERTS_AND_TRACES.md) | Alerts and traces | ✅ Current |
| [observability/API_METRICS_AND_NOTIFY.md](observability/API_METRICS_AND_NOTIFY.md) | API metrics and notifications | ✅ Current |

### Monitoring Tools
| Document | Description | Status |
|----------|-------------|--------|
| [grafana/GRAFANA_DASHBOARD_NOTES.md](grafana/GRAFANA_DASHBOARD_NOTES.md) | Grafana dashboard notes | ✅ Current |
| [monitoring/INTENT_RESOLVE_METRICS.md](monitoring/INTENT_RESOLVE_METRICS.md) | Intent resolve metrics | ✅ Current |
| [observability/](observability/) | Observability documentation | - |

---

## 🔄 Migration & Legacy

### Migration Guides
| Document | Description | Status |
|----------|-------------|--------|
| [COGO_MIGRATION_CREATEGO.md](COGO_MIGRATION_CREATEGO.md) | CreateGo migration | ✅ Current |
| [SCHEMA_MIGRATION_ANALYSIS.md](SCHEMA_MIGRATION_ANALYSIS.md) | Schema migration analysis | ✅ Current |
| [CHANNEL_ARCHITECTURE_MIGRATION.md](CHANNEL_ARCHITECTURE_MIGRATION.md) | Channel architecture migration | ✅ Current |

### Legacy Systems
| Document | Description | Status |
|----------|-------------|--------|
| [LEGACY_CODE_CLEANUP_PLAN.md](LEGACY_CODE_CLEANUP_PLAN.md) | Legacy code cleanup | ✅ Current |
| [TYPESCRIPT_LEGACY_CODE_CLEANUP_PLAN.md](TYPESCRIPT_LEGACY_CODE_CLEANUP_PLAN.md) | TypeScript legacy cleanup | ✅ Current |
| [migration/](migration/) | Migration guides directory | - |

---

## 📖 User Guides & Documentation

### User Guides
| Document | Description | Status |
|----------|-------------|--------|
| [guides/COGO_SYSTEM_USER_GUIDE.md](guides/COGO_SYSTEM_USER_GUIDE.md) | System user guide | ✅ Current |
| [guides/DEVELOPMENT_GUIDE.md](guides/DEVELOPMENT_GUIDE.md) | Development guide | ✅ Current |
| [guides/QUICKSTART_TESTING.md](guides/QUICKSTART_TESTING.md) | Quickstart testing | ✅ Current |
| [guides/ENV_SETUP.md](guides/ENV_SETUP.md) | Environment setup | ✅ Current |
| [guides/API_KEY_SETUP_GUIDE.md](guides/API_KEY_SETUP_GUIDE.md) | API key setup guide | ✅ Current |
| [guides/VERIFICATION_CHECKLIST_API.md](guides/VERIFICATION_CHECKLIST_API.md) | API verification checklist | ✅ Current |

### Manuals and References
| Document | Description | Status |
|----------|-------------|--------|
| [manuals/](manuals/) | User manuals directory | - |
| [references/](references/) | Reference materials | - |
| [references/DOCUMENTATION_INDEX.md](references/DOCUMENTATION_INDEX.md) | Documentation index | 📅 Review |

---

## 📂 Directory Structure

```
docs/
├── README.md                           # Main documentation index
├── index.md                           # This detailed index
├── ADR/                               # Architecture Decision Records
│   └── ADR-rag-utilization.md
├── agents/                            # Agent-specific documentation
│   └── AGENTS_API_INDEX.md
├── design/                            # Design documents
├── events/                            # Event system documentation
├── examples/                          # Example implementations
├── grafana/                           # Grafana dashboard documentation
│   └── GRAFANA_DASHBOARD_NOTES.md
├── integration/                       # Integration guides
├── manuals/                           # User manuals
├── methodology/                       # Development methodology
├── migration/                         # Migration guides
├── observability/                     # Observability documentation
├── openapi/                           # OpenAPI specifications
├── ops/                               # Operations documentation
├── plans/                             # Development plans and roadmaps
├── policies/                          # Project policies
├── postman/                           # Postman collections
├── realtime/                          # Real-time system documentation
├── references/                        # Reference materials
├── reports/                           # Status reports and analysis
├── research/                          # Research documentation
├── runbook/                           # Operations runbooks
├── scenarios/                         # Usage scenarios
├── schemas/                           # Schema documentation
├── specs/                             # Technical specifications
├── supabase/                          # Supabase-specific documentation
├── tests/                             # Testing documentation
└── uui/                               # UUI system documentation
```

## 📋 Document Status Legend

- ✅ **Current** - Actively maintained and up-to-date
- 🔄 **In Progress** - Currently being updated or revised
- 📅 **Review Needed** - Needs review for accuracy
- 🏗️ **Draft** - Preliminary version, subject to change
- 📚 **Reference** - Historical or reference documentation

---

*Last updated: 2025-01-30*
*Maintained by: COGO Development Team*
