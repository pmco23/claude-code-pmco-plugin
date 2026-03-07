---
name: pack
description: Pack the local codebase using Repomix CLI into three targeted snapshots (code, docs, full) stored in .pipeline/ for sharing across /qa audit agents. Run before /qa for maximum token efficiency. Usage: /pack [path] (defaults to cwd).
argument-hint: [path]
---

# PACK — Codebase Snapshot

## Role

> **Model:** Haiku (`claude-haiku-4-5`). Haiku is sufficient for this task. Sonnet or Opus will also work.

Pack the current project into three targeted Repomix snapshots via CLI:

| Variant | File | Purpose |
|---------|------|---------|
| **code** | `repomix-code.xml` | Source code only — used by `/cleanup`, `/frontend-audit`, `/backend-audit`, `/security-review` |
| **docs** | `repomix-docs.xml` | Documentation only — used by `/doc-audit` |
| **full** | `repomix-full.xml` | Full codebase — fallback and ad-hoc use |

Metadata stored at `.pipeline/repomix-pack.json`. All `/qa` audit agents read from their mapped snapshot variant instead of independently discovering files.

## Hard Rules

1. **Repomix must be installed.** If `repomix` is not found on PATH, stop: "PACK BLOCKED — repomix is not installed. Run `npm install -g repomix` first."
2. **Never modify source files.** This skill only reads the codebase and writes to `.pipeline/`.

## Process

### Step 1: Resolve path

If an argument is provided, use it as the target directory. Otherwise use the current working directory.

### Step 2: Check repomix is available

Run: `command -v repomix`

If not found, stop with the message from Hard Rule #1.

### Step 3: Generate three snapshots

Run all three sequentially:

```bash
mkdir -p .pipeline

# Code snapshot — source code only, excludes docs/config/assets
repomix --compress --remove-empty-lines --no-file-summary --include-diffs \
  --ignore "**/*.md,**/*.mdx,**/*.rst,**/*.txt,docs/**,doc/**,*.config.*,*.json,*.yaml,*.yml,*.toml,*.lock,*.svg,*.png,*.jpg,*.gif,*.ico" \
  --output .pipeline/repomix-code.xml <resolved-path>

# Docs snapshot — documentation files only
repomix --remove-empty-lines --no-file-summary --no-directory-structure \
  --include "**/*.md,**/*.mdx,**/*.rst,**/*.txt,docs/**,doc/**,README*,CHANGELOG*,CONTRIBUTING*,LICENSE*" \
  --output .pipeline/repomix-docs.xml <resolved-path>

# Full snapshot — entire codebase
repomix --compress --remove-empty-lines \
  --output .pipeline/repomix-full.xml <resolved-path>
```

### Step 4: Write state file

Write `.pipeline/repomix-pack.json`:

```json
{
  "packedAt": "<current ISO timestamp>",
  "source": "<absolute path to packed directory>",
  "snapshots": {
    "code": {
      "filePath": "<absolute path to .pipeline/repomix-code.xml>",
      "fileSize": <bytes>
    },
    "docs": {
      "filePath": "<absolute path to .pipeline/repomix-docs.xml>",
      "fileSize": <bytes>
    },
    "full": {
      "filePath": "<absolute path to .pipeline/repomix-full.xml>",
      "fileSize": <bytes>
    }
  }
}
```

Get file sizes via Bash (`wc -c < file` or `stat`).

### Step 5: Report

Report to user:

```
Pack complete.
  code:  .pipeline/repomix-code.xml  (<size>KB)
  docs:  .pipeline/repomix-docs.xml  (<size>KB)
  full:  .pipeline/repomix-full.xml  (<size>KB)
  Source: <path>

QA agents will use their mapped snapshot variant.
Run /qa to use these packs across all audits.
```

## Output

Three snapshots written to `.pipeline/`. `.pipeline/repomix-pack.json` updated with paths, sizes, and timestamp. Run `/qa` to use these packs across all five audit agents.
