# MCP Integration: Cursor ↔ Figma (TalkToFigma)

This document describes how to integrate and use the Figma MCP with Cursor for design-aware development workflows. We use the public TalkToFigma MCP implementation instead of the in-repo `mcp-servers/figma-context`.

Reference: [grab/cursor-talk-to-figma-mcp](https://github.com/grab/cursor-talk-to-figma-mcp?tab=readme-ov-file)

## Why
- Keep COGO agents Realtime-first and system-focused, while design manipulation is handled via MCP tools when needed.
- Avoid maintaining a parallel in-repo Figma MCP implementation.

## What we use
- External MCP server: TalkToFigma (MCP) and its WebSocket bridge
- Figma plugin: TalkToFigma plugin (community or local dev plugin)

## Prerequisites
- Cursor installed
- Bun installed (used by TalkToFigma):
  - macOS/Linux: `curl -fsSL https://bun.sh/install | bash`
  - Windows (PowerShell): `powershell -c "irm bun.sh/install.ps1|iex"`

## Setup
1) Register MCP server in Cursor (on your workstation)
- File: `~/.cursor/mcp.json`
```json
{
  "mcpServers": {
    "TalkToFigma": {
      "command": "bunx",
      "args": ["cursor-talk-to-figma-mcp@latest"]
    }
  }
}
```
- Restart Cursor after saving.

2) Start the WebSocket server (local shell)
```bash
bun socket
```
- If using WSL/Windows, follow the repo note to set `hostname: "0.0.0.0"` in `src/socket.ts` and then run `bun socket`.

3) Install/Link the Figma plugin
- Open Figma → Plugins → Development → New Plugin → Link existing plugin
- Pick the plugin from the TalkToFigma repo (see README) or install the community-provided plugin

## Usage Flow (Local)
1) Run WebSocket server: `bun socket`
2) Open Cursor in your project; ensure MCP server is loaded
3) Open Figma file → run the TalkToFigma plugin
4) In plugin UI, connect to the socket and `join_channel`
5) Use MCP tools from Cursor:
   - `get_document_info`, `get_selection`, `scan_text_nodes`
   - `set_text_content`, `set_multiple_text_contents`
   - `create_frame`, `create_text`, etc.

## Minimal Smoke (Manual)
- With Figma plugin connected:
  - Get document info: `get_document_info`
  - Scan selection: `get_selection`
  - Update a small text node: `set_text_content`
- Verify in Figma that the node changed.

## Notes & Policies
- MCP is for local/dev ergonomics. Production data flows remain Realtime-first via Supabase (no MCP coupling between COGO agents).
- Figma MCP runs independently from the orchestrator; it should not block or slow down bus processing.
- Keep secrets in Cursor or OS keychain; do not commit credentials.

## Migrating from in-repo `mcp-servers/figma-context`
- The directory remains for archival, but is not used.
- Use TalkToFigma going forward for all Figma MCP tasks.

## Troubleshooting
- If MCP tools do not appear in Cursor: check `~/.cursor/mcp.json` and restart Cursor
- If the plugin cannot connect: ensure `bun socket` is running and firewall allows localhost connections
- For large documents, prefer batch/text scan tools and watch WS logs for progress
