**Code Path (Trunk-Based)**
- Branch: `<prefix>/<short-description>` — prefixes: feat/feature/fix/bugfix/hotfix/chore/release; lowercase, hyphens only, max ~50 chars
- Commit: `<type>[scope][!]: <description>` — types: feat/fix/docs/refactor/test/chore/ci/build/perf; `!` for breaking changes
- Merge: squash-merge to main; short-lived branches (under 2 days)
- PR: title conveys intent; description must include verification evidence

*(Spec sources: https://www.conventionalcommits.org/en/v1.0.0/ and https://conventional-branch.github.io/)*
