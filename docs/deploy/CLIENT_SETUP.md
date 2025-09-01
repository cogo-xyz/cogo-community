## cogo-client Setup (3-Repository Model)

This guide bootstraps `cogo-client` to consume SDKs from `cogo-agent-core` via submodule and path dependencies.

### Steps
1) Run bootstrap script
```bash
CLIENT_DIR=/Users/<you>/Desktop/Dev/cogo-project/cogo-client \
bash scripts/bootstrap-client.sh
```

2) Install dependencies
```bash
cd /Users/<you>/Desktop/Dev/cogo-project/cogo-client
npm install
# If using Flutter:
flutter pub get
```

3) Use SDKs in your apps
- TypeScript: import from `@cogo/chat-sdk`
- Flutter: add dependency to `cogo_chat_sdk_flutter` (already in pubspec)

4) Update submodule on upgrades
```bash
cd external/cogo-agent-core
git fetch --tags origin
git checkout <new-tag-or-commit>
cd ../..
git add external/cogo-agent-core
git commit -m "chore: bump agent-core submodule"
```

### Notes
- Supabase assets (SQL/Edge/secrets) live only in `cogo-agent-core`.
- Public distribution goes through `cogo-community` using `npm run publish:community`.
- Keep TS↔Flutter SDK structures aligned to avoid drift.


