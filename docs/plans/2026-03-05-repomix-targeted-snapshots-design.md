# Design: Targeted Repomix Snapshots

**Date:** 2026-03-05
**Status:** Approved

## Problem

The current `/pack` generates a single `repomix-output.xml` snapshot of the entire codebase. In projects with extensive documentation, markdown and text files pass through nearly verbatim (Tree-sitter `--compress` only reduces code), bloating the snapshot and wasting tokens when audit agents read it.

## Solution

`/pack` generates three targeted snapshots with variant-specific Repomix flags. Each `/qa` audit agent receives only the snapshot variant it needs.

## Snapshot Variants

| Variant | File | Used by |
|---------|------|---------|
| **code** | `repomix-code.xml` | `/cleanup`, `/frontend-audit`, `/backend-audit`, `/security-review` |
| **docs** | `repomix-docs.xml` | `/doc-audit` |
| **full** | `repomix-full.xml` | Fallback, ad-hoc use, `/quick --deep` |

### Repomix Flags Per Variant

**code:**
```
repomix --compress --remove-empty-lines --no-file-summary --include-diffs \
  --ignore "**/*.md,**/*.mdx,**/*.rst,**/*.txt,docs/**,doc/**,*.config.*,*.json,*.yaml,*.yml,*.toml,*.lock,*.svg,*.png,*.jpg,*.gif,*.ico" \
  --output .pipeline/repomix-code.xml <path>
```

**docs:**
```
repomix --remove-empty-lines --no-file-summary --no-directory-structure \
  --include "**/*.md,**/*.mdx,**/*.rst,**/*.txt,docs/**,doc/**,README*,CHANGELOG*,CONTRIBUTING*,LICENSE*" \
  --output .pipeline/repomix-docs.xml <path>
```

**full:**
```
repomix --compress --remove-empty-lines \
  --output .pipeline/repomix-full.xml <path>
```

### Flag Rationale

| Flag | Applied to | Reason |
|------|-----------|--------|
| `--compress` | code, full | Tree-sitter extraction ~70% token reduction on code |
| `--remove-empty-lines` | all | Free token savings, no downside |
| `--no-file-summary` | code, docs | File metadata redundant for targeted sets |
| `--no-directory-structure` | docs | Doc-audit reads files directly, doesn't need tree |
| `--include-diffs` | code | Audit agents see what actually changed in the build |

## State File

`.pipeline/repomix-pack.json` expands to track all three:

```json
{
  "packedAt": "2026-03-05T14:30:00Z",
  "source": "/path/to/project",
  "snapshots": {
    "code": {
      "filePath": "/path/to/.pipeline/repomix-code.xml",
      "fileSize": 45200
    },
    "docs": {
      "filePath": "/path/to/.pipeline/repomix-docs.xml",
      "fileSize": 12800
    },
    "full": {
      "filePath": "/path/to/.pipeline/repomix-full.xml",
      "fileSize": 98400
    }
  }
}
```

## Agent-to-Snapshot Mapping

| Agent | Snapshot variant | Rationale |
|-------|-----------------|-----------|
| Dead Code Removal (`/cleanup`) | code | Only needs source code |
| Frontend Audit | code | Only needs frontend source |
| Backend Audit | code | Only needs backend source |
| Security Review | code | Vulnerabilities in code, not docs |
| Documentation Freshness (`/doc-audit`) | docs | Only needs markdown/text |

## Fallback Chain (per audit skill)

When run standalone (outside `/qa`):

1. Check `repomix-pack.json` → use the mapped snapshot variant
2. If variant missing but `repomix-full.xml` exists → use full
3. If no snapshots → native Glob/Read/Grep

## `/qa` Preamble Changes

1. Check `.pipeline/repomix-pack.json` exists
2. Read `packedAt` — if < 1 hour old, use snapshot paths from `snapshots` map
3. If missing or stale, invoke `/pack` (generates all three)
4. Map each agent to its snapshot variant before dispatch

## `/status` Report

Repomix row expands to show variant sizes:

```
  repomix-pack     [✓ 2m ago — code: 45KB, docs: 13KB, full: 98KB | ✗ missing]
```

## `compact-prep.sh` Changes

Reports which snapshots exist:

```
Repomix snapshots: code (45KB), docs (13KB), full (98KB) — packed 2m ago
```

## `session_end_pack.sh` Changes

Generates all three variants instead of one. Updates expanded state file format.

## Files Touched

| File | Change |
|------|--------|
| `skills/pack/SKILL.md` | Three repomix runs with variant-specific flags |
| `skills/qa/SKILL.md` | Preamble reads snapshot map, passes variant paths |
| `skills/qa/references/agent-prompts.md` | Each agent gets its specific snapshot path |
| `skills/cleanup/SKILL.md` | Repomix line → code variant, fallback chain |
| `skills/frontend-audit/SKILL.md` | Same |
| `skills/backend-audit/SKILL.md` | Same |
| `skills/security-review/SKILL.md` | Same |
| `skills/doc-audit/SKILL.md` | Repomix line → docs variant, fallback chain |
| `skills/status/references/report-formats.md` | Expanded repomix row |
| `hooks/compact-prep.sh` | Check for all three snapshots |
| `hooks/session_end_pack.sh` | Generate all three variants |
