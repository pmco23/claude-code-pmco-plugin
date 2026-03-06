# Repomix Guide

Repomix is used by `/pack`, `/qa`, and the session-end hook for token-efficient codebase snapshots. It runs as a CLI tool — no MCP server required.

## Install

```bash
npm install -g repomix
```

## Verify

```bash
repomix --version
```

The plugin checks for `repomix` on PATH at session start and warns if missing. `/pack` will block with an explicit error if repomix is not installed.

---

## How Snapshots Work

`/pack` generates three targeted snapshots, each optimized for a different audience:

| Variant | File | Used by | What's included |
|---------|------|---------|-----------------|
| **code** | `.pipeline/repomix-code.xml` | `/cleanup`, `/frontend-audit`, `/backend-audit`, `/security-review` | Source code only — excludes docs, config, assets, lock files |
| **docs** | `.pipeline/repomix-docs.xml` | `/doc-audit` | Documentation only — markdown, RST, text, README, CHANGELOG |
| **full** | `.pipeline/repomix-full.xml` | Fallback, ad-hoc use | Entire codebase |

### Why three snapshots?

`--compress` uses Tree-sitter to extract code structure (~70% token reduction on code), but documentation files pass through nearly verbatim. In projects with extensive docs, a single snapshot can be heavily bloated with markdown that only `/doc-audit` needs. Splitting means each audit agent gets exactly what it needs — nothing more.

### Flags per variant

| Flag | code | docs | full | Purpose |
|------|:----:|:----:|:----:|---------|
| `--compress` | ✓ | | ✓ | Tree-sitter code extraction |
| `--remove-empty-lines` | ✓ | ✓ | ✓ | Token savings |
| `--no-file-summary` | ✓ | ✓ | | Skip redundant file metadata |
| `--no-directory-structure` | | ✓ | | Doc-audit reads files directly |
| `--include-diffs` | ✓ | | | Audit agents see what changed in the build |
| `--include` | | ✓ | | Docs-only file patterns |
| `--ignore` | ✓ | | | Exclude docs/config/assets |

### State file

Metadata is stored at `.pipeline/repomix-pack.json`:

```json
{
  "packedAt": "2026-03-05T14:30:00Z",
  "source": "/path/to/project",
  "snapshots": {
    "code": { "filePath": "...", "fileSize": 45200 },
    "docs": { "filePath": "...", "fileSize": 12800 },
    "full": { "filePath": "...", "fileSize": 98400 }
  }
}
```

`/qa` reads `packedAt` to check freshness (< 1 hour = fresh). If stale or missing, it invokes `/pack` automatically.

### Fallback chain

When an audit skill runs standalone (outside `/qa`), it checks for snapshots in order:

1. Its mapped variant (code or docs) from `repomix-pack.json`
2. `repomix-full.xml` if the variant is missing
3. Native Glob/Read/Grep if no snapshots exist

### Automatic refresh

The `session-end-pack.sh` hook regenerates all three snapshots at the end of every session (unless `session-end-pack: disabled` is set in CLAUDE.md). This ensures the next session starts with fresh snapshots.

---

## Manual CLI Usage

You can run Repomix directly for ad-hoc analysis outside the plugin pipeline.

### Reproduce what `/pack` does

```bash
mkdir -p .pipeline

# Code snapshot
repomix --compress --remove-empty-lines --no-file-summary --include-diffs \
  --ignore "**/*.md,**/*.mdx,**/*.rst,**/*.txt,docs/**,doc/**,*.config.*,*.json,*.yaml,*.yml,*.toml,*.lock,*.svg,*.png,*.jpg,*.gif,*.ico" \
  --output .pipeline/repomix-code.xml .

# Docs snapshot
repomix --remove-empty-lines --no-file-summary --no-directory-structure \
  --include "**/*.md,**/*.mdx,**/*.rst,**/*.txt,docs/**,doc/**,README*,CHANGELOG*,CONTRIBUTING*,LICENSE*" \
  --output .pipeline/repomix-docs.xml .

# Full snapshot
repomix --compress --remove-empty-lines \
  --output .pipeline/repomix-full.xml .
```

### Pack a specific directory

```bash
repomix --compress --remove-empty-lines --output snapshot.xml src/
```

### Pack only specific file types

```bash
repomix --compress --include "**/*.ts,**/*.tsx" --output typescript-only.xml .
```

### Check token distribution

```bash
# Show which files consume the most tokens
repomix --token-count-tree 100
```

This displays a file tree with token counts, filtering to files with 100+ tokens. Useful for identifying bloated files before packing.

### Output formats

```bash
# XML (default, recommended for AI tools)
repomix --compress --output snapshot.xml .

# Markdown (human-readable)
repomix --compress --style markdown --output snapshot.md .

# Plain text (minimal)
repomix --compress --style plain --output snapshot.txt .
```

### Strip comments for maximum compression

```bash
repomix --compress --remove-comments --remove-empty-lines --output lean.xml .
```

`--remove-comments` strips code comments (supports 18+ languages). Combined with `--compress`, this produces the leanest possible snapshot.

### Pipe file lists

```bash
# Pack only files matching a grep pattern
grep -rl "TODO" src/ | repomix --stdin --output todos.xml

# Pack files selected interactively with fzf
find . -name "*.ts" -type f | fzf -m | repomix --stdin --output selected.xml
```

---

## Troubleshooting

### repomix not found

If Repomix was installed via nvm, the `repomix` binary may not be on PATH in non-interactive shells. Fix by linking it globally:

```bash
# Find the path
which repomix

# Option 1: Add nvm's bin to your PATH in ~/.zshrc or ~/.bashrc
# Option 2: Create a symlink
sudo ln -s $(which repomix) /usr/local/bin/repomix
```

### Snapshot too large

If a snapshot exceeds useful size, narrow the scope:

```bash
# Check what's consuming tokens
repomix --token-count-tree 500

# Exclude heavy directories
repomix --compress --ignore "vendor/**,node_modules/**,dist/**" --output snapshot.xml .
```

### Snapshot missing expected files

Repomix respects `.gitignore` by default. To include ignored files:

```bash
repomix --no-gitignore --output snapshot.xml .
```
