# Targeted Repomix Snapshots Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the single Repomix snapshot with three targeted variants (code, docs, full) so each QA audit agent receives only the files it needs, reducing token waste from documentation bloat.

**Architecture:** `/pack` runs `repomix` three times with variant-specific `--include`/`--ignore` flags. The state file `.pipeline/repomix-pack.json` stores a `snapshots` map keyed by variant name. `/qa` reads this map and passes each agent its specific snapshot path. Audit skills use a three-step fallback: variant → full → native Glob/Read/Grep.

**Tech Stack:** Repomix CLI (`--compress`, `--include`, `--ignore`, `--remove-empty-lines`, `--no-file-summary`, `--no-directory-structure`, `--include-diffs`), Bash (hooks), Markdown (skills)

---

### Task 1: Update `/pack` skill to generate three snapshot variants

**Files:**
- Modify: `skills/pack/SKILL.md`

**Step 1: Replace SKILL.md content**

Replace the entire file with:

```markdown
---
name: pack
description: Pack the local codebase using Repomix CLI into three targeted snapshots (code, docs, full) stored in .pipeline/ for sharing across /qa audit agents. Run before /qa for maximum token efficiency. Usage: /pack [path] (defaults to cwd).
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
```

**Step 2: Commit**

```bash
git add skills/pack/SKILL.md
git commit -m "feat(pack): generate three targeted Repomix snapshots (code, docs, full)"
```

---

### Task 2: Update `/qa` preamble to use snapshot variants

**Files:**
- Modify: `skills/qa/SKILL.md`

**Step 1: Replace Repomix Preamble section**

In `skills/qa/SKILL.md`, replace the existing "## Repomix Preamble" section (lines 14–24) with:

```markdown
## Repomix Preamble

Before dispatching any agents, ensure Repomix snapshots are available:

1. Check if `.pipeline/repomix-pack.json` exists
2. If it exists, read `packedAt` — if less than 1 hour old, read the `snapshots` map
3. If missing or stale, invoke the `/pack` skill — it generates three snapshots (code, docs, full) and writes `.pipeline/repomix-pack.json`
4. After `/pack` completes, read the `snapshots` map from `.pipeline/repomix-pack.json`
5. If `/pack` fails or Repomix is unavailable, proceed without snapshots — agents fall back to native Glob/Read/Grep

Hold the snapshot map in context. Each agent gets its mapped variant:

| Agent | Snapshot variant |
|-------|-----------------|
| Dead Code Removal (`/cleanup`) | `snapshots.code.filePath` |
| Frontend Audit | `snapshots.code.filePath` |
| Backend Audit | `snapshots.code.filePath` |
| Security Review | `snapshots.code.filePath` |
| Documentation Freshness (`/doc-audit`) | `snapshots.docs.filePath` |
```

**Step 2: Update Parallel Mode section**

In the Parallel Mode section, replace the `<snapshot-path>` substitution instruction (line 54) with:

```markdown
Read `references/agent-prompts.md` from this skill's base directory. Dispatch all five agents simultaneously via the Task tool, substituting `<code-snapshot-path>` and `<docs-snapshot-path>` with the appropriate paths from the snapshot map (or omitting the Repomix instruction if unavailable).
```

**Step 3: Update Sequential Mode section**

Replace the sequential mode Repomix context line (line 60):

Old:
```
Run in order, presenting each result before proceeding. When invoking each skill, prepend the Repomix context: "Repomix snapshot available at .pipeline/repomix-output.xml — use Grep/Read on it for file discovery." If no snapshot was acquired, omit this.
```

New:
```
Run in order, presenting each result before proceeding. When invoking each skill, prepend the Repomix context with the agent's mapped snapshot variant path (code or docs). Example: "Repomix code snapshot available at .pipeline/repomix-code.xml — use Grep/Read on it for file discovery." For /doc-audit, use the docs snapshot path instead. If no snapshot was acquired, omit this.
```

**Step 4: Commit**

```bash
git add skills/qa/SKILL.md
git commit -m "feat(qa): map audit agents to targeted snapshot variants"
```

---

### Task 3: Update QA agent prompts with variant-specific paths

**Files:**
- Modify: `skills/qa/references/agent-prompts.md`

**Step 1: Replace entire file**

Replace the entire content of `skills/qa/references/agent-prompts.md` with:

```markdown
# QA Agent Prompts

Use the Task tool to launch all 5 agents. Substitute `<code-snapshot-path>` and `<docs-snapshot-path>` with the paths from the snapshot map in the preamble. If no snapshot was acquired for a variant, omit the Repomix instruction from that agent's prompt.

---

## Agent 1 — Dead Code Removal

```
Follow the cleanup skill process: find dead code (unused symbols, unused imports, unreachable branches, commented-out code). .pipeline/build.complete exists. Repomix code snapshot available at <code-snapshot-path> — use Grep/Read on it for file discovery. Report all findings with file:line references.
```

## Agent 2 — Frontend Audit

```
Follow the frontend-audit skill process: audit frontend TypeScript/JavaScript/CSS/HTML against the project's own style guide (infer from existing code if no explicit guide). .pipeline/build.complete exists. Repomix code snapshot available at <code-snapshot-path> — use Grep/Read on it for file discovery. Report all findings with file:line references.
```

## Agent 3 — Backend Audit

```
Follow the backend-audit skill process: audit backend code (Go/Python/TypeScript/C#) against the project's own style guide. Check error handling, logging, naming, public API surface. .pipeline/build.complete exists. Repomix code snapshot available at <code-snapshot-path> — use Grep/Read on it for file discovery. Report all findings with file:line references.
```

## Agent 4 — Documentation Freshness

```
Follow the doc-audit skill process: check CHANGELOG.md for Keep a Changelog format compliance, presence of an [Unreleased] section, and coverage of the feature built in this pipeline. .pipeline/build.complete exists. Repomix docs snapshot available at <docs-snapshot-path> — use Grep/Read on it for file discovery. Report all findings.
```

## Agent 5 — Security Review

```
Follow the security-review skill process: scan for OWASP Top 10 vulnerabilities relevant to this application type. .pipeline/build.complete exists. Repomix code snapshot available at <code-snapshot-path> — use Grep/Read on it for file discovery. Report all findings with severity, location, and remediation.
```
```

**Step 2: Commit**

```bash
git add skills/qa/references/agent-prompts.md
git commit -m "feat(qa): update agent prompts with variant-specific snapshot paths"
```

---

### Task 4: Update four code-audit skills with fallback chain (code variant)

These four skills all use the same Repomix line pattern pointing to `repomix-output.xml`. Update each to use the code variant with fallback.

**Files:**
- Modify: `skills/cleanup/SKILL.md` (line 14)
- Modify: `skills/frontend-audit/SKILL.md` (line 14)
- Modify: `skills/backend-audit/SKILL.md` (line 14)
- Modify: `skills/security-review/SKILL.md` (line 14)

**Step 1: In each of the four files, find and replace the Repomix line**

Find this line (exact wording varies slightly but pattern is the same):
```
**Repomix snapshot:** if `.pipeline/repomix-output.xml` exists, use Grep/Read on it for discovery; else native Glob/Read/Grep on source files.
```

Replace with:
```
**Repomix snapshot:** Check `.pipeline/repomix-pack.json` for `snapshots.code.filePath`; if present, use Grep/Read on the code snapshot for discovery. If code variant missing but `.pipeline/repomix-full.xml` exists, use that. Else native Glob/Read/Grep on source files. Modifications (if any) use native Edit/Write only.
```

For `cleanup/SKILL.md` specifically, the existing line ends with "Modifications (Step 4) use native Edit/Write only." — preserve that distinction:
```
**Repomix snapshot:** Check `.pipeline/repomix-pack.json` for `snapshots.code.filePath`; if present, use Grep/Read on the code snapshot for discovery. If code variant missing but `.pipeline/repomix-full.xml` exists, use that. Else native Glob/Read/Grep on source files. Modifications (Step 4) use native Edit/Write only.
```

For the other three (`frontend-audit`, `backend-audit`, `security-review`), the line doesn't mention modifications, so use:
```
**Repomix snapshot:** Check `.pipeline/repomix-pack.json` for `snapshots.code.filePath`; if present, use Grep/Read on the code snapshot for discovery. If code variant missing but `.pipeline/repomix-full.xml` exists, use that. Else native Glob/Read/Grep on source files.
```

**Step 2: Commit all four**

```bash
git add skills/cleanup/SKILL.md skills/frontend-audit/SKILL.md skills/backend-audit/SKILL.md skills/security-review/SKILL.md
git commit -m "feat(audits): update 4 code-audit skills to use code snapshot variant with fallback"
```

---

### Task 5: Update doc-audit skill with fallback chain (docs variant)

**Files:**
- Modify: `skills/doc-audit/SKILL.md` (line 14)

**Step 1: Find and replace the Repomix line**

Find:
```
**Repomix snapshot:** if `.pipeline/repomix-output.xml` exists, use Grep/Read on it for discovery; else native Glob/Read/Grep on source files.
```

Replace with:
```
**Repomix snapshot:** Check `.pipeline/repomix-pack.json` for `snapshots.docs.filePath`; if present, use Grep/Read on the docs snapshot for discovery. If docs variant missing but `.pipeline/repomix-full.xml` exists, use that. Else native Glob/Read/Grep on source files.
```

**Step 2: Commit**

```bash
git add skills/doc-audit/SKILL.md
git commit -m "feat(doc-audit): use docs snapshot variant with fallback"
```

---

### Task 6: Update `session_end_pack.sh` to generate three variants

**Files:**
- Modify: `hooks/session_end_pack.sh`

**Step 1: Replace the single repomix call and state file logic**

Replace lines 45–87 (from the `repomix --compress` line through the `jq` fallback block) with:

```bash
# Generate three snapshot variants
# Code snapshot — source code only
repomix --compress --remove-empty-lines --no-file-summary --include-diffs \
  --ignore "**/*.md,**/*.mdx,**/*.rst,**/*.txt,docs/**,doc/**,*.config.*,*.json,*.yaml,*.yml,*.toml,*.lock,*.svg,*.png,*.jpg,*.gif,*.ico" \
  --output "$PIPELINE_DIR/repomix-code.xml" "$PROJECT_ROOT" 2>/dev/null

# Docs snapshot — documentation files only
repomix --remove-empty-lines --no-file-summary --no-directory-structure \
  --include "**/*.md,**/*.mdx,**/*.rst,**/*.txt,docs/**,doc/**,README*,CHANGELOG*,CONTRIBUTING*,LICENSE*" \
  --output "$PIPELINE_DIR/repomix-docs.xml" "$PROJECT_ROOT" 2>/dev/null

# Full snapshot — entire codebase
repomix --compress --remove-empty-lines \
  --output "$PIPELINE_DIR/repomix-full.xml" "$PROJECT_ROOT" 2>/dev/null

# At least one snapshot must succeed
if [ ! -f "$PIPELINE_DIR/repomix-code.xml" ] && [ ! -f "$PIPELINE_DIR/repomix-docs.xml" ] && [ ! -f "$PIPELINE_DIR/repomix-full.xml" ]; then
  exit 0
fi

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if command -v python3 >/dev/null 2>&1; then
  python3 - "$PIPELINE_DIR" "$PROJECT_ROOT" <<'PYEOF'
import json, os, sys

pipeline_dir = sys.argv[1]
project_root = sys.argv[2]
pack_file = os.path.join(pipeline_dir, "repomix-pack.json")

from datetime import datetime, timezone
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

snapshots = {}
for variant in ("code", "docs", "full"):
    fpath = os.path.join(pipeline_dir, f"repomix-{variant}.xml")
    if os.path.isfile(fpath):
        entry = {"filePath": fpath}
        try:
            entry["fileSize"] = os.path.getsize(fpath)
        except Exception:
            pass
        snapshots[variant] = entry

data = {
    "packedAt": now,
    "source": project_root,
    "snapshots": snapshots
}

with open(pack_file, "w") as f:
    json.dump(data, f, indent=2)
PYEOF

elif command -v jq >/dev/null 2>&1; then
  # Build snapshots JSON with jq
  SNAPSHOTS="{}"
  for variant in code docs full; do
    fpath="$PIPELINE_DIR/repomix-${variant}.xml"
    if [ -f "$fpath" ]; then
      fsize=$(wc -c < "$fpath" 2>/dev/null | tr -d ' ')
      SNAPSHOTS=$(echo "$SNAPSHOTS" | jq --arg v "$variant" --arg fp "$fpath" --argjson fs "${fsize:-0}" \
        '. + {($v): {"filePath": $fp, "fileSize": $fs}}')
    fi
  done
  jq -n --arg t "$NOW" --arg src "$PROJECT_ROOT" --argjson snaps "$SNAPSHOTS" \
    '{"packedAt": $t, "source": $src, "snapshots": $snaps}' \
    > "$PIPELINE_DIR/repomix-pack.json" 2>/dev/null || true
fi
```

**Step 2: Update the file header comment**

Replace lines 2–6:

Old:
```bash
# session_end_pack.sh
# SessionEnd hook: packs the codebase with repomix CLI so the next session's /qa
# has a fresh snapshot at .pipeline/repomix-output.xml and a refreshed packedAt
# timestamp. The stored outputId (from any in-session /pack run) is left untouched —
# if the MCP server is still alive when the next session opens, /qa can reuse it.
```

New:
```bash
# session_end_pack.sh
# SessionEnd hook: packs the codebase into three targeted Repomix snapshots
# (code, docs, full) so the next session's /qa has fresh snapshots with a
# refreshed packedAt timestamp.
```

**Step 3: Run gate tests**

```bash
bash hooks/test_gate.sh
```

Expected: `Results: 51 passed, 0 failed` (session_end_pack is not covered by gate tests — they test pipeline_gate.sh only)

**Step 4: Commit**

```bash
git add hooks/session_end_pack.sh
git commit -m "feat(hooks): generate three Repomix snapshot variants on session end"
```

---

### Task 7: Update `compact-prep.sh` to report snapshot variants

**Files:**
- Modify: `hooks/compact-prep.sh`

**Step 1: Replace the Repomix snapshot section**

Replace lines 42–44:

Old:
```bash
# Repomix snapshot
if [ -f "$PIPELINE_DIR/repomix-output.xml" ]; then
  echo "Repomix snapshot: $PIPELINE_DIR/repomix-output.xml (verify age before reuse)"
fi
```

New:
```bash
# Repomix snapshots
snap_info=""
for variant in code docs full; do
  fpath="$PIPELINE_DIR/repomix-${variant}.xml"
  if [ -f "$fpath" ]; then
    fsize=$(wc -c < "$fpath" 2>/dev/null | tr -d ' ')
    fsize_kb=$(( (fsize + 512) / 1024 ))
    snap_info="${snap_info:+$snap_info, }${variant} (${fsize_kb}KB)"
  fi
done
if [ -n "$snap_info" ]; then
  echo "Repomix snapshots: $snap_info (verify age before reuse)"
fi
```

**Step 2: Run gate tests**

```bash
bash hooks/test_gate.sh
```

Expected: `Results: 51 passed, 0 failed`

**Step 3: Commit**

```bash
git add hooks/compact-prep.sh
git commit -m "feat(hooks): report snapshot variant sizes in compact-prep"
```

---

### Task 8: Update `/status` report format

**Files:**
- Modify: `skills/status/references/report-formats.md`

**Step 1: Replace the repomix-pack row in the Pipeline Report**

In the Pipeline Report section, replace line 41:
```
  repomix-pack     [✓ <age> | ⚠ <age> (stale) | ✗ missing]
```
With:
```
  repomix-pack     [✓ <age> — code: <size>KB, docs: <size>KB, full: <size>KB | ⚠ <age> (stale) | ✗ missing]
```

**Step 2: Update the repomix-pack Row Rules section**

Replace lines 46–51:

Old:
```markdown
### repomix-pack Row Rules

- Age < 1 hour: `✓ <age>`
- Age ≥ 1 hour: `⚠ <age> (stale — run /pack to refresh)`
- File absent: `✗ missing`
- If `packedAt` is absent or not a valid ISO timestamp: treat as stale and display `⚠ age unknown — run /pack to refresh`
```

New:
```markdown
### repomix-pack Row Rules

- Age < 1 hour: `✓ <age> — code: <size>KB, docs: <size>KB, full: <size>KB` (read sizes from `snapshots.<variant>.fileSize` in `repomix-pack.json`, convert to KB)
- Age ≥ 1 hour: `⚠ <age> (stale — run /pack to refresh)`
- File absent (no `repomix-pack.json`): `✗ missing`
- If `packedAt` is absent or not a valid ISO timestamp: treat as stale and display `⚠ age unknown — run /pack to refresh`
- If a variant is missing from the `snapshots` map, omit it from the size list
```

**Step 3: Commit**

```bash
git add skills/status/references/report-formats.md
git commit -m "feat(status): show snapshot variant sizes in pipeline report"
```

---

### Task 9: Update CHANGELOG and push

**Files:**
- Modify: `CHANGELOG.md`

**Step 1: Add entries under `## [Unreleased]`**

Under the existing `### Changed` section, add:

```markdown
- `/pack` now generates three targeted Repomix snapshots: `repomix-code.xml` (source code, `--compress --include-diffs`), `repomix-docs.xml` (documentation only), `repomix-full.xml` (full codebase) — each audit agent receives only the files it needs
- All snapshots use `--remove-empty-lines` for additional token savings; code and docs variants use `--no-file-summary` to reduce overhead
- `/qa` maps each audit agent to its optimal snapshot variant: code for cleanup/frontend/backend/security, docs for doc-audit
- 5 audit skills updated with three-step fallback chain: targeted variant → full snapshot → native Glob/Read/Grep
- `session_end_pack.sh` generates all three snapshot variants on session end
- `compact-prep.sh` reports snapshot variant sizes
- `/status` report shows per-variant sizes (code/docs/full KB)
- `.pipeline/repomix-pack.json` format expanded with `snapshots` map containing per-variant `filePath` and `fileSize`
```

**Step 2: Commit and push**

```bash
git add CHANGELOG.md
git commit -m "docs: update changelog with targeted Repomix snapshots"
git push
```

---

## Summary

| Task | What | Files |
|------|------|-------|
| 1 | `/pack` generates 3 snapshots | `skills/pack/SKILL.md` |
| 2 | `/qa` preamble uses snapshot map | `skills/qa/SKILL.md` |
| 3 | Agent prompts use variant paths | `skills/qa/references/agent-prompts.md` |
| 4 | 4 code-audit skills → code variant | `skills/cleanup/SKILL.md`, `skills/frontend-audit/SKILL.md`, `skills/backend-audit/SKILL.md`, `skills/security-review/SKILL.md` |
| 5 | doc-audit → docs variant | `skills/doc-audit/SKILL.md` |
| 6 | session_end_pack generates 3 variants | `hooks/session_end_pack.sh` |
| 7 | compact-prep reports variant sizes | `hooks/compact-prep.sh` |
| 8 | `/status` shows variant sizes | `skills/status/references/report-formats.md` |
| 9 | CHANGELOG + push | `CHANGELOG.md` |
