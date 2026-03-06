---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git tag:*), Bash(git push:*), Bash(git log:*), Bash(gh release create:*), Read, Edit, Glob
description: "Cut a release: version bump, changelog, commit, tag, push, GitHub release. Usage: /release patch|minor|major"
argument-hint: "patch|minor|major"
---

## Context

- Current branch: !`git branch --show-current`
- Latest tag: !`git describe --tags --abbrev=0 2>/dev/null || echo "No tags found"`
- Unreleased changelog: !`sed -n '/^## \[Unreleased\]/,/^## \[/p' CHANGELOG.md 2>/dev/null | head -30 || echo "No CHANGELOG.md found"`
- Working tree status: !`git status --short`

## Your task

Cut a full release end-to-end. The release type (patch, minor, or major) is provided in the command arguments: `$ARGUMENTS`.

Steps:

1. **Detect current version.** Check in order: `package.json`, `.claude-plugin/plugin.json`, `pyproject.toml`. If multiple version files exist, bump all of them.

2. **Validate.** If the `## [Unreleased]` section in CHANGELOG.md has no entries, stop: "RELEASE BLOCKED — no entries under `## [Unreleased]`. Add changelog entries first." If there are uncommitted changes, stop: "RELEASE BLOCKED — commit or stash changes first."

3. **Compute new version** from the release type argument:
   - `patch`: X.Y.Z → X.Y.(Z+1)
   - `minor`: X.Y.Z → X.(Y+1).0
   - `major`: X.Y.Z → (X+1).0.0
   If no argument provided, ask which type.

4. **Show preview** before writing anything:
   ```
   Release preview:
     Current: vX.Y.Z → New: vA.B.C
     Config files: [list files to bump]
     CHANGELOG: [Unreleased] → [A.B.C] - YYYY-MM-DD
     Commit: chore: release vA.B.C
     Tag: vA.B.C
     Push: main + tag
     GitHub release: vA.B.C
   ```
   Ask for confirmation before proceeding.

5. **Execute** (all in sequence):
   - Bump version in all config files
   - Update CHANGELOG.md: rename `## [Unreleased]` to `## [A.B.C] - YYYY-MM-DD`, prepend fresh `## [Unreleased]`
   - `git add` the changed files
   - `git commit -m "chore: release vA.B.C"` (use HEREDOC)
   - `git tag vA.B.C`
   - `git push origin main && git push origin vA.B.C`
   - `gh release create vA.B.C --title "vA.B.C" --notes-from-tag` or with changelog excerpt

6. **Report:**
   ```
   Released vA.B.C
     ✓ Version bumped in [files]
     ✓ CHANGELOG.md updated
     ✓ Commit: chore: release vA.B.C
     ✓ Tag: vA.B.C
     ✓ Pushed to origin
     ✓ GitHub release: [URL]
   ```
