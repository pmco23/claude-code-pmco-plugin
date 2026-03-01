---
name: pack
description: Pack the local codebase using Repomix MCP and store the outputId in .pipeline/repomix-pack.json for sharing across /qa audit agents. Run before /qa for maximum token efficiency. Usage: /pack [path] (defaults to cwd).
---

# PACK — Codebase Snapshot

## Role

Pack the current project into a compressed Repomix snapshot. The outputId is stored in `.pipeline/repomix-pack.json` and shared with `/qa` agents so all five audits read from one pack instead of independently discovering files (~70% token reduction via Tree-sitter compression).

## Process

### Step 1: Resolve path

If an argument is provided, use it as the target directory. Otherwise use the current working directory.

### Step 2: Pack the codebase

Call `mcp__repomix__pack_codebase` with:
- `directory`: resolved path from Step 1
- `compress`: `true`

### Step 3: Write state file

Ensure `.pipeline/` exists (create it if not). Then write `.pipeline/repomix-pack.json`:

```json
{
  "outputId": "<outputId from pack response>",
  "source": "<absolute path>",
  "packedAt": "<current ISO timestamp>",
  "fileCount": "<fileCount from pack response>",
  "tokensBefore": "<tokensBefore from pack response>",
  "tokensAfter": "<tokensAfter from pack response>"
}
```

### Step 4: Report

Report to user:

```
Pack complete.
  outputId:  <id>
  Files:     <count>
  Tokens:    <before> → <after> (<N>% reduction)
  Top files: [top 5 from pack response topFiles list, or "not available" if absent]

Run /qa to use this pack across all audits.
```

## Output

`.pipeline/repomix-pack.json` written with outputId, file count, and token stats. Run `/qa` to use this pack across all five audit agents.
