# Session Persistence Design

**Date:** 2026-03-02

## Problem

Claude Code has no memory between sessions. Each conversation starts from scratch with no awareness of what was worked on, what decisions were made, or what state a feature is in.

## Rejected Approach: `/end-session` skill

An explicit end-of-session skill that writes to MEMORY.md was considered and rejected:
- Most of what it would capture (commits, decisions, pipeline state) is already persisted elsewhere
- End-of-session rituals fail — people close their laptop, get interrupted
- The `episodic-memory` plugin already auto-indexes conversations at session end, making explicit capture redundant

## Chosen Approach: Episodic Memory Integration

The `episodic-memory` plugin (already installed) indexes all Claude Code conversations automatically. The gap is purely on the *retrieval* side — nothing currently surfaces past context at session start or at the beginning of key workflows.

Three lightweight integrations close this gap with zero user discipline required at session end.

## Goals

- Always-injected context at session start (no action needed)
- Proactive context surfacing at the start of `/brief` and `/init` workflows
- Visible to the user (not silent background enrichment)
- Search across all projects, not just the current one

## Architecture

### 1. SessionStart Hook — auto-inject recent context into MEMORY.md

**Where:** extend `hooks/session_start_check.sh`

**What it does:**

1. Runs `episodic-memory sync` — ensures the last session's conversations are indexed
2. Runs `episodic-memory search "recent work" --limit 3 --after <7-days-ago>` — fetches recent cross-project activity
3. Writes a formatted block to `~/.claude/projects/<encoded-cwd>/memory/MEMORY.md`

**MEMORY.md block format:**

```markdown
<!-- session-context-start -->
## Recent Activity (auto-updated at session start — 2026-03-02)

1. [2026-03-01 · claude-agents-custom] "session persistence design, /end-session skill..."
2. [2026-03-01 · claude-agents-custom] "plugin audit, skill rename, codex MCP migration..."
3. [2026-02-28 · dotnet-test] "authentication middleware, JWT validation..."
<!-- session-context-end -->
```

Claude reads these injected excerpts naturally as part of session context — no skill invocation needed.

**MEMORY.md update logic:**
- If sentinels exist: replace content between them
- If no sentinels: append block at end
- If MEMORY.md doesn't exist: create it with only this block

**Path computation:**
```bash
ENCODED=$(echo "$PWD" | sed 's|^/||; s|/|-|g')
MEMORY_FILE="$HOME/.claude/projects/-${ENCODED}/memory/MEMORY.md"
```

**Episodic-memory binary:** invoked via `node` since it is not on `$PATH`:
```bash
EPISODIC_BIN="$HOME/.claude/plugins/cache/superpowers-marketplace/episodic-memory/1.0.15/cli/episodic-memory.js"
node "$EPISODIC_BIN" sync
node "$EPISODIC_BIN" search "recent work" --limit 3 --after "$(date -d '7 days ago' +%Y-%m-%d)"
```

### 2. `/brief` Step 0 — surface past decisions before requirements Q&A

**Where:** `skills/brief/SKILL.md` — add as first step, before existing Step 1

**What it does:**

Before asking any questions, call `mcp__plugin_episodic-memory_episodic-memory__search` with the user's stated feature/topic and display results visibly:

```
Checking past conversations for context on "[topic]"...

Found 2 relevant conversations:
  · [2026-02-15] Discussed rate limiting approach — chose token bucket over sliding window
  · [2026-01-30] Auth middleware design — JWT with refresh tokens, no session storage

Carrying these forward. Starting requirements Q&A...
```

If no relevant results: proceed silently.

### 3. `/init` Step 0 — surface past project context before scaffolding

**Where:** `skills/init/SKILL.md` — add as first step, before existing Step 1

**What it does:**

Before reading config files, call `mcp__plugin_episodic-memory_episodic-memory__search` with the project name and show results visibly:

```
Checking past conversations for context on this project...

Found 1 relevant conversation:
  · [2026-02-20] Chose Go modules over workspace; gRPC for internal services

Carrying this forward. Detecting project context...
```

If no relevant results: proceed silently.

## What This Does Not Change

- No `/end-session` skill — episodic-memory auto-indexes at session end
- No CLAUDE.md modifications — MEMORY.md is the right channel for injected context
- No new plugin config — episodic-memory is already installed and MCP-connected
- No changes to pipeline artifacts or `docs/plans/` — those persist decisions at the feature level

## Files Changed

| File | Change |
|------|--------|
| `hooks/session_start_check.sh` | Add sync + search + MEMORY.md write |
| `skills/brief/SKILL.md` | Add Step 0: episodic memory search |
| `skills/init/SKILL.md` | Add Step 0: episodic memory search |
| `docs/skills/brief.md` | Document new Step 0 |
| `docs/skills/init.md` | Document new Step 0 |
