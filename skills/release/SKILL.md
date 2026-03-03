---
name: release
description: Use to cut a new release. Bumps version in config files, renames [Unreleased] to [X.Y.Z] in CHANGELOG.md, creates a release commit, and creates a git tag. Git operations only — no registry publishing. Run after /qa passes.
---

# RELEASE — Cut a Release

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`).

You are acting as a release coordinator. Read the current version, check preconditions, preview all changes, wait for confirmation, then apply them locally.

## Hard Rules

1. **Block if `[Unreleased]` is empty.** If the `## [Unreleased]` section in CHANGELOG.md has no entries, stop immediately: "RELEASE BLOCKED — no entries under `## [Unreleased]`. Add changelog entries first."
2. **Warn if build.complete is absent.** If `.pipeline/build.complete` does not exist, warn: "⚠ `.pipeline/build.complete` not found — QA may not have run. Proceeding anyway." Do not block.
3. **Always show preview before writing.** Show the full version bump + CHANGELOG diff before making any changes. Never write silently.
4. **Never push.** Stop after local tag. Always remind: "To publish: `git push && git push --tags`".

## Process

### Step 1: Detect version source

Check for version in this order:
- `package.json` → `version` field
- `.claude-plugin/plugin.json` → `version` field
- `pyproject.toml` → `version` field
- `go.mod` → first `// vX.Y.Z` comment

If none found: use AskUserQuestion with:
  question: "No version field found in config files. What is the current version?"
  header: "Current version"
  options:
    - label: "0.1.0"
      description: "Start from 0.1.0"
    - label: "1.0.0"
      description: "Start from 1.0.0"

### Step 2: Check preconditions

- Check `.pipeline/build.complete` — warn if absent (Hard Rule #2)
- Read `CHANGELOG.md` — check that `## [Unreleased]` has at least one entry (Hard Rule #1)

### Step 3: Choose release type

Use AskUserQuestion with:
  question: "What kind of release? (current: vX.Y.Z)"
  header: "Release type"
  options:
    - label: "Patch (vX.Y.Z+1)"
      description: "Bug fixes, no new features"
    - label: "Minor (vX.Y+1.0)"
      description: "New features, backwards compatible"
    - label: "Major (vX+1.0.0)"
      description: "Breaking changes"

Compute the new version from the selection.

### Step 4: Show preview

Output the full preview before writing anything:

```
New version:    X.Y.Z
CHANGELOG:      ## [Unreleased] → ## [X.Y.Z] - YYYY-MM-DD
                (fresh ## [Unreleased] added above)
Config file:    [filename]: [old version] → X.Y.Z
Git commit:     chore: release vX.Y.Z
Git tag:        vX.Y.Z
```

### Step 5: Confirm

Use AskUserQuestion with:
  question: "Apply these changes?"
  header: "Confirm release"
  options:
    - label: "Confirm"
      description: "Write files, create commit and tag"
    - label: "Cancel"
      description: "Abort — make no changes"

If "Cancel": stop with "Release cancelled."

### Step 6: Apply

If confirmed:
1. Write new version to the config file
2. Update `CHANGELOG.md`: rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD`; prepend a fresh `## [Unreleased]\n` above it
3. Run: `git add [config-file] CHANGELOG.md`
4. Run: `git commit -m "chore: release vX.Y.Z"`
5. Run: `git tag vX.Y.Z`

### Step 7: Report

Output:
```
Released vX.Y.Z
  ✓ [config-file] bumped to X.Y.Z
  ✓ CHANGELOG.md updated
  ✓ Commit: chore: release vX.Y.Z
  ✓ Tag: vX.Y.Z

To publish: git push && git push --tags
```

## Output

Config file and `CHANGELOG.md` updated locally. Commit and tag created locally. Nothing pushed.
