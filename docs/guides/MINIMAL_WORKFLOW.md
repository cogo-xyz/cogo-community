## Minimal Development Workflow (Private Repo, Free Plan)

This document defines the minimal internal rules we follow while using a private repository on the Free plan (where branch protections/rulesets may not be enforced by GitHub). These rules are organizational policy and must be followed by all contributors.

### 1) Roles and Access
- **Owners**: `cogo-0`, `CreateGo-James` (backup). May perform emergency actions if necessary.
- **Member**: `JamesLee77` via team `fixers` with Maintain access to `cogo-agent-core`.
- Organization base permissions: Read (recommended). Contributors work via forks if Write is not granted.

### 2) Branch Policy
- Default branch: `main`.
- No direct pushes to `main` (policy). Use pull requests.
- Work feature branches off `main` with the pattern: `feature/<short-topic>`.
- Hotfix branches only for critical production issues: `hotfix/<short-topic>`.

### 3) Minimal PR Workflow
1. Create a branch: `feature/<short-topic>`.
2. Commit changes (see Commit Style below).
3. Open a Pull Request targeting `main`.
4. Request at least one review from the `fixers` team (not the author).
5. Resolve all review comments/conversations.
6. Ensure CI (if configured) is green. Even if not enforced by GitHub, we treat red checks as “do not merge”.
7. Merge using **Squash merge**.

### 4) Merge Rules
- Merge method: **Squash** only (keep a linear history and clean commit messages on `main`).
- Do not merge your own PR without at least one approval (policy).
- If new commits are pushed to the PR, a fresh review is required (policy).

### 5) Commit Style (Lightweight)
- Prefer clear, imperative messages, e.g. `Add minimal workflow guide`.
- Optional Conventional Commits for larger changes:
  - `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- Keep the first line ≤ 72 chars when possible; add details in the body if needed.

### 6) Hotfix Procedure (Owners Only)
- For urgent production issues, an Owner may:
  1) Create `hotfix/<short-topic>`.
  2) Open a PR and self-merge only if absolutely necessary.
  3) Retroactively request review post-merge and document the rationale in the PR description.
- Direct pushes to `main` are discouraged even for hotfixes; PRs improve traceability.

### 7) CI (Optional but Recommended)
- If a simple CI exists (lint/build/test), the PR must be green before merge (policy).
- When CI is added later, we will enumerate required checks in this document.

### 8) Access Management
- Direct access: keep minimal. Only Owners have Admin. `fixers` has Maintain on this repo.
- For external contributions or stricter control, use fork-based PRs.

### 9) Policy Violations
- PRs merged without review or with failing checks may be reverted.
- Repeated violations will lead to access level review.

### 10) PR Checklist (Copy into PR description)
- [ ] Feature branch named `feature/<short-topic>` (or `hotfix/<short-topic>`)
- [ ] At least one reviewer requested (`fixers`)
- [ ] All conversations resolved
- [ ] CI green (if present)
- [ ] Squash merge selected

---
Owner sign-off: `cogo-0` / Backup: `CreateGo-James`

