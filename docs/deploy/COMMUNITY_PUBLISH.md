## Community Publish – Public-safe Artifacts

This guide explains how to publish SDK/CLI/Plugin and docs from `cogo-agent-core` to the public `cogo-community` repository without leaking secrets.

### What gets published
- SDK/CLI/Plugin packages:
  - `packages/cogo-chat-sdk-ts`
  - `packages/cogo-chat-sdk-flutter`
  - `packages/cogo-cli-flutter`
  - `packages/cogo-figma-plugin`
- Docs: `docs/` (public-safe only)

### Excludes (always)
- `node_modules`, `dist`, `build`, `.dart_tool`
- `.env*`, any file containing `key` or `secret` in the name
- Logs and temporary artifacts

### Usage
```bash
export COGO_COMMUNITY_DIR=/Users/<you>/Desktop/Dev/cogo-project/cogo-community
bash scripts/publish-community.sh
```

Optional preview (backup only, no copy):
```bash
export COGO_COMMUNITY_DIR=/Users/<you>/Desktop/Dev/cogo-project/cogo-community
PREVIEW=1 bash scripts/publish-community.sh
```

### Safety
- The script creates a timestamped backup of existing community contents into `backups/community-publish-<ts>/` before copying.
- Never pushes automatically. Review and commit/push manually in `cogo-community`.


