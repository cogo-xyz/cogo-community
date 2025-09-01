## MCP Environment Standards

This document standardizes environment for external MCP servers (Figma, Browser).

### TypeScript Strictness
- Figma MCP (`mcp-servers/figma-context/tsconfig.json`): `strict: false`, `allowJs: true`, relaxed options to accommodate upstream JS-first codebases.
- Browser MCP (`mcp-servers/browser-use/tsconfig.json`): same relaxed settings to reduce friction with external libs.

### Docker Build Environment
- Base image: `node:18-alpine`
- System tools: `python3`, `py3-setuptools`, `make`, `g++`, `git`, `curl`, `ca-certificates` for native deps and healthchecks.
- Registry override: pass `NPM_CONFIG_REGISTRY` via compose to support private registries/mirrors.

### Runtime Services
- Figma HTTP server on `3001`, WS server on `3002` (separate containers).
- Redis provided via `redis:7-alpine` for caching.

### Client Defaults
- `configs/mcp.json` sets default WS endpoints: `figma.ws=ws://localhost:3002`.
- Env overrides: `MCP_FIGMA_WS_URL`, `MCP_BROWSER_WS_URL`.

### CI/Gates
- Add `npm run -s mcp:ping` as a pre-gate step. Skip with `MCP_SKIP=true` when secrets absent.

### Security
- Never commit tokens. Use env/secret manager for `FIGMA_API_KEY`, `MCP_AUTH_TOKEN`.


